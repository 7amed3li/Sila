import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sila_app/core/services/reciter_service.dart';

/// Helper class لإدارة مسارات ملفات الصوت بشكل موحد
///
/// يضمن أن جميع العمليات (التحميل، التحقق، الحذف) تستخدم نفس المسار
class AudioPathHelper {
  static const String _cacheRoot = 'audio_cache';

  /// الحصول على مجلد التخزين الجذر
  static Future<Directory> getCacheRootDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    return Directory(
      '${appDir.path}${Platform.pathSeparator}$_cacheRoot',
    );
  }

  /// الحصول على مجلد القارئ
  static Future<Directory> getReciterDirectory(ReciterModel reciter) async {
    final root = await getCacheRootDirectory();
    final dir = Directory(
      '${root.path}${Platform.pathSeparator}${reciter.folderName}',
    );

    // ✅ تأكد من وجود المجلد
    if (!await dir.exists()) {
      await dir.create(recursive: true);
      debugPrint('📁 تم إنشاء مجلد القارئ: ${dir.path}');
    }

    return dir;
  }

  /// الحصول على مسار ملف آية واحدة
  ///
  /// المسار: /storage/.../audio_cache/{reciter}/{001_001}.mp3
  /// (يستخدم underscore بدلاً من colon)
  static Future<String> getAyahFilePath(
    ReciterModel reciter,
    int surahNumber,
    int ayahNumber,
  ) async {
    final dir = await getReciterDirectory(reciter);

    // ✅ استخدم underscore بدلاً من colon لتجنب مشاكل نظام الملفات
    final surah = surahNumber.toString().padLeft(3, '0');
    final ayah = ayahNumber.toString().padLeft(3, '0');
    final fileName = '${surah}_${ayah}.mp3';

    final filePath = '${dir.path}${Platform.pathSeparator}$fileName';

    return filePath;
  }

  /// الحصول على أسماء جميع ملفات الآيات (للتوافقية)
  ///
  /// يرجع قائمة بأسماء ملفات محتملة لنفس الآية
  /// (الشكل القديم بـ colon والشكل الجديد بـ underscore)
  static List<String> getAyahFilePatterns(
    int surahNumber,
    int ayahNumber,
  ) {
    final surah = surahNumber.toString().padLeft(3, '0');
    final ayah = ayahNumber.toString().padLeft(3, '0');

    return [
      '${surah}_${ayah}.mp3', // الشكل الجديد (underscore)
      '${surah}:${ayah}.mp3', // الشكل القديم (colon) - للتوافقية
      '$surah$ayah.mp3', // بدون فاصل - للتوافقية
    ];
  }

  /// البحث عن ملف آية في المجلد (يعمل مع جميع الأشكال)
  static Future<File?> findAyahFile(
    ReciterModel reciter,
    int surahNumber,
    int ayahNumber,
  ) async {
    try {
      final dir = await getReciterDirectory(reciter);
      final patterns = getAyahFilePatterns(surahNumber, ayahNumber);

      // ابحث عن أي ملف يطابق أحد الأنماط
      await for (final entity in dir.list()) {
        if (entity is File) {
          final fileName = entity.path.split(Platform.pathSeparator).last;

          if (patterns.contains(fileName)) {
            debugPrint(
              '✅ وجد ملف الآية: $surahNumber:$ayahNumber → $fileName',
            );
            return entity;
          }
        }
      }

      debugPrint('❌ لم يتم العثور على ملف الآية: $surahNumber:$ayahNumber');
      return null;
    } catch (e) {
      debugPrint('❌ خطأ في البحث عن الملف: $e');
      return null;
    }
  }

  /// تنظيف أسماء الملفات القديمة (التحويل من colon إلى underscore)
  static Future<int> migrateOldFileNamings(ReciterModel reciter) async {
    try {
      final dir = await getReciterDirectory(reciter);
      var migratedCount = 0;

      await for (final entity in dir.list()) {
        if (entity is File) {
          final fileName = entity.path.split(Platform.pathSeparator).last;

          // إذا كان الملف يستخدم colon القديم
          if (fileName.contains(':')) {
            final newFileName = fileName.replaceAll(':', '_');
            final newPath = '${dir.path}${Platform.pathSeparator}$newFileName';

            try {
              await entity.rename(newPath);
              debugPrint('🔄 تم تحويل: $fileName → $newFileName');
              migratedCount++;
            } catch (e) {
              debugPrint('⚠️ فشل تحويل $fileName: $e');
            }
          }
        }
      }

      if (migratedCount > 0) {
        debugPrint('✅ تم ترقية $migratedCount ملف قديم');
      }

      return migratedCount;
    } catch (e) {
      debugPrint('❌ خطأ في ترقية الملفات: $e');
      return 0;
    }
  }

  /// طباعة معلومات تصحيح (للـ debugging)
  static Future<void> debugPrintPaths(ReciterModel reciter) async {
    final root = await getCacheRootDirectory();
    final reciterDir = await getReciterDirectory(reciter);
    final examplePath = await getAyahFilePath(reciter, 1, 1);

    debugPrint('''
═══════════════════════════════════════════════
📁 معلومات المسارات للتصحيح:
═══════════════════════════════════════════════
🔹 المسار الجذر: ${root.path}
🔹 مجلد القارئ: ${reciterDir.path}
🔹 مثال على مسار الملف: $examplePath
🔹 هل مجلد القارئ موجود؟ ${await reciterDir.exists()}
═══════════════════════════════════════════════
    ''');
  }
}
