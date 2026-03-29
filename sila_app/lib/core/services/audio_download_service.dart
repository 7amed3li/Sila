import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:quran/quran.dart' as quran;
import 'package:sila_app/core/services/reciter_service.dart';

class AudioDownloadProgress {
  const AudioDownloadProgress({
    required this.completed,
    required this.total,
    required this.surah,
    required this.ayah,
  });
  final int completed;
  final int total;
  final int surah;
  final int ayah;
}

class AudioDownloadService {
  static const String _cacheRoot = 'audio_cache';

  static Future<Directory> _reciterDirectory(ReciterModel reciter) async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory(
        '${appDir.path}${Platform.pathSeparator}$_cacheRoot${Platform.pathSeparator}${reciter.folderName}');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  static Future<String> localAyahPath(
    ReciterModel reciter,
    int surahNumber,
    int ayahNumber,
  ) async {
    final surah = surahNumber.toString().padLeft(3, '0');
    final ayah = ayahNumber.toString().padLeft(3, '0');
    final dir = await _reciterDirectory(reciter);
    return '${dir.path}${Platform.pathSeparator}$surah$ayah.mp3';
  }

  static Future<int> totalAyahCount() async {
    var total = 0;
    for (var s = 1; s <= 114; s++) {
      total += quran.getVerseCount(s);
    }
    return total;
  }

  static Future<int> downloadedAyahCount(ReciterModel reciter) async {
    final dir = await _reciterDirectory(reciter);
    if (!await dir.exists()) return 0;

    var count = 0;
    await for (final entity in dir.list()) {
      if (entity is File && entity.path.toLowerCase().endsWith('.mp3')) {
        count++;
      }
    }
    return count;
  }

  static Future<void> downloadAllForReciter(
    ReciterModel reciter, {
    required void Function(AudioDownloadProgress progress) onProgress,
    CancelToken? cancelToken,
  }) async {
    final dio = Dio();
    final total = await totalAyahCount();
    var completed = 0;
    var failed = 0;

    for (var surah = 1; surah <= 114; surah++) {
      final ayahCount = quran.getVerseCount(surah);
      for (var ayah = 1; ayah <= ayahCount; ayah++) {
        final localPath = await localAyahPath(reciter, surah, ayah);
        final localFile = File(localPath);

        try {
          if (!await localFile.exists()) {
            final url = reciter.buildAyahUrl(surah, ayah);

            // ✅ تحميل مع معالجة الأخطاء
            await dio.download(
              url,
              localPath,
              cancelToken: cancelToken,
            );

            // ✅ التحقق من أن الملف لم يكن فارغاً (غالباً يعني 404 أو خطأ آخر)
            final fileSize = await localFile.length();
            if (fileSize < 10000) {
              // ملف صوتي قصير جداً = فاسد (أقل من 10KB)
              debugPrint('⚠️ ملف فاسد/ناقص: $surah:$ayah (${fileSize}B) - حذف');
              await localFile.delete();
              failed++;
              completed++;
              onProgress(
                AudioDownloadProgress(
                  completed: completed,
                  total: total,
                  surah: surah,
                  ayah: ayah,
                ),
              );
              continue;
            }
          }

          completed++;
        } on DioException catch (e) {
          debugPrint(
              '❌ فشل تحميل $surah:$ayah - ${e.response?.statusCode}: ${e.message}');
          failed++;

          // ✅ إذا كان 404 أو 401، لا تحاول مرة أخرى (الملف غير موجود)
          if (e.response?.statusCode == 404 ||
              e.response?.statusCode == 401 ||
              e.response?.statusCode == 403) {
            completed++;
            onProgress(
              AudioDownloadProgress(
                completed: completed,
                total: total,
                surah: surah,
                ayah: ayah,
              ),
            );
            continue;
          }

          // ✅ لأخطاء الشبكة، أعد المحاولة مرة واحدة فقط
          if (e.type == DioExceptionType.connectionTimeout ||
              e.type == DioExceptionType.receiveTimeout ||
              e.type == DioExceptionType.unknown) {
            debugPrint('🔄 إعادة محاولة $surah:$ayah بعد 2 ثانية...');
            await Future.delayed(const Duration(seconds: 2));

            try {
              final url = reciter.buildAyahUrl(surah, ayah);
              await dio.download(url, localPath, cancelToken: cancelToken);

              // ✅ تحقق من الحجم مرة أخرى
              final fileSize = await localFile.length();
              if (fileSize < 10000) {
                await localFile.delete();
                failed++;
              } else {
                completed++;
              }
            } catch (retryError) {
              debugPrint('❌ فشل إعادة المحاولة: $retryError');
              failed++;
              completed++;
            }
          } else {
            completed++;
          }
        } catch (e) {
          debugPrint('❌ خطأ غير متوقع أثناء تحميل $surah:$ayah: $e');
          failed++;
          completed++;
        }

        onProgress(
          AudioDownloadProgress(
            completed: completed,
            total: total,
            surah: surah,
            ayah: ayah,
          ),
        );
      }
    }

    debugPrint(
        '✅ انتهى تحميل جميع الملفات: نجح=${completed - failed}, فشل=$failed من $total');
  }

  static Future<bool> isAnyAudioDownloaded(ReciterModel reciter) async {
    final dir = await _reciterDirectory(reciter);
    if (!await dir.exists()) return false;

    await for (final entity in dir.list()) {
      if (entity is File && entity.path.toLowerCase().endsWith('.mp3')) {
        return true;
      }
    }
    return false;
  }

  /// ✅ التحقق من أن ملف معين محمّل بشكل صحيح
  static Future<bool> verifyAyahDownloaded(
    ReciterModel reciter,
    int surahNumber,
    int ayahNumber,
  ) async {
    try {
      final localPath = await localAyahPath(reciter, surahNumber, ayahNumber);
      final file = File(localPath);

      if (!await file.exists()) return false;

      // ✅ التحقق من الحجم (يجب أن يكون أكثر من 10KB)
      final size = await file.length();
      if (size < 10000) {
        debugPrint('⚠️ ملف ناقص/فاسد: $surahNumber:$ayahNumber ($size بايت)');
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('❌ خطأ في التحقق من الملف: $e');
      return false;
    }
  }

  /// ✅ التحقق من أن جميع ملفات السورة محمّلة بنجاح
  ///
  /// يتحقق من أن جميع ملفات السورة موجودة وليست فاسدة
  /// إذا فقدت أكثر من 20% من الملفات، تُعتبر السورة غير محمّلة
  static Future<bool> verifySurahDownloaded(
    ReciterModel reciter,
    int surahNumber,
  ) async {
    try {
      final verseCount = quran.getVerseCount(surahNumber);
      var missingCount = 0;
      var corruptCount = 0;

      debugPrint('📁 التحقق من السورة $surahNumber (عدد الآيات: $verseCount)');

      for (var ayah = 1; ayah <= verseCount; ayah++) {
        final verified = await verifyAyahDownloaded(reciter, surahNumber, ayah);
        if (!verified) {
          final localPath = await localAyahPath(reciter, surahNumber, ayah);
          final file = File(localPath);

          if (!await file.exists()) {
            missingCount++;
            if (missingCount <= 5) {
              debugPrint(
                  '⚠️ ملف مفقود: $surahNumber:$ayah (المسار: $localPath)');
            }
          } else {
            corruptCount++;
            if (corruptCount <= 5) {
              final size = await file.length();
              debugPrint('⚠️ ملف فاسد: $surahNumber:$ayah (الحجم: $size بايت)');
            }
          }
        }
      }

      // إذا كانت نسبة الملفات المفقودة/الفاسدة أقل من 20%، تُقبل السورة
      final totalMissing = missingCount + corruptCount;
      final acceptableThreshold = (verseCount * 0.2).ceil(); // 20%

      if (totalMissing == 0) {
        debugPrint('✅ السورة $surahNumber محمّلة بالكامل بدون مشاكل');
        return true;
      } else if (totalMissing <= acceptableThreshold) {
        debugPrint(
            '⚠️ السورة $surahNumber محمّلة جزئياً: $missingCount مفقود، $corruptCount فاسد من $verseCount (يقل عن الحد المقبول)');
        // يمكن تشغيل السورة لكن مع تحذير
        return true;
      } else {
        debugPrint(
            '❌ السورة $surahNumber لم تُحمّل بشكل كافٍ: $missingCount مفقود، $corruptCount فاسد من $verseCount (أكثر من الحد المقبول)');
        return false;
      }
    } catch (e) {
      debugPrint('❌ خطأ في التحقق من السورة: $e');
      return false;
    }
  }

  /// ✅ حذف جميع ملفات مقيت (Corrupt files) من المجلد
  static Future<int> removeCorruptFiles(ReciterModel reciter) async {
    try {
      final dir = await _reciterDirectory(reciter);
      var deletedCount = 0;

      await for (final entity in dir.list()) {
        if (entity is File && entity.path.toLowerCase().endsWith('.mp3')) {
          try {
            final size = await entity.length();
            if (size < 10000) {
              debugPrint('🗑️ حذف ملف مقيت: ${entity.path} ($size بايت)');
              await entity.delete();
              deletedCount++;
            }
          } catch (_) {
            // تجاهل الأخطاء
          }
        }
      }

      if (deletedCount > 0) {
        debugPrint('✅ تم حذف $deletedCount ملف مقيت');
      }

      return deletedCount;
    } catch (e) {
      debugPrint('❌ خطأ في حذف الملفات المقيتة: $e');
      return 0;
    }
  }
}
