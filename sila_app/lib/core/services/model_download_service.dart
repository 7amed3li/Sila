import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sila_app/core/utils/storage_utils.dart';

class ModelDownloadService {
  final Dio _dio = Dio(BaseOptions(
    headers: {
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
    },
    followRedirects: true,
    maxRedirects: 10,
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(minutes: 5),
  ));
  CancelToken? _cancelToken;

  Future<bool> isFilePresent(String path) async {
    return File(path).exists();
  }

  Future<void> downloadFile({
    required String url,
    required String savePath,
    required void Function(double) onProgress,
  }) async {
    _cancelToken = CancelToken();
    try {
      final file = File(savePath);
      if (!await file.parent.exists()) {
        await file.parent.create(recursive: true);
      }

      await _dio.download(
        url,
        savePath,
        cancelToken: _cancelToken,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            onProgress(received / total);
          }
        },
      );
    } catch (e) {
      if (e is DioException && CancelToken.isCancel(e)) {
        debugPrint('🛑 ModelDownloadService: Download cancelled');
      } else if (e is DioException) {
        debugPrint('❌ ModelDownloadService Error: ${e.type}');
        debugPrint('❌ Status: ${e.response?.statusCode}');
        debugPrint('❌ URL: ${e.requestOptions.uri}');
        debugPrint('❌ Message: ${e.message}');

        // ✅ رسائل خطأ واضحة
        String errorMessage;
        switch (e.type) {
          case DioExceptionType.connectionTimeout:
            errorMessage = 'انتهت مهلة الاتصال. تحقق من الإنترنت';
          case DioExceptionType.receiveTimeout:
            errorMessage = 'تم تجاوز وقت الاستقبال. الرجاء المحاولة مرة أخرى';
          case DioExceptionType.badResponse:
            switch (e.response?.statusCode) {
              case 403:
                errorMessage = 'تم رفض الطلب (403). قد لا يكون لديك صلاحيات';
              case 404:
                errorMessage = 'الملف غير موجود (404). قد يكون الرابط قديماً';
              case 500:
                errorMessage = 'خطأ في الخادم (500). يرجى المحاولة لاحقاً';
              default:
                errorMessage = 'خطأ من الخادم: ${e.response?.statusCode}';
            }
          case DioExceptionType.cancel:
            errorMessage = 'تم إيقاف التحميل من قبل المستخدم';
          default:
            errorMessage = 'فشل التحميل: ${e.message ?? 'خطأ غير معروف'}';
        }

        throw Exception(errorMessage);
      } else {
        debugPrint('❌ Unexpected Error: $e');
        rethrow;
      }
    }
  }

  void cancelDownload() {
    _cancelToken?.cancel('User cancelled');
  }

  Future<void> deleteFile(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<void> decompressModel(String zipPath, String destDir) async {
    debugPrint('📦 ModelDownloadService: Starting decompression of ${zipPath}');
    final bytes = await File(zipPath).readAsBytes();
    debugPrint('📦 ModelDownloadService: Read ${bytes.length} bytes');

    // Decode BZip2 then Tar (for .tar.bz2)
    final bzip2 = BZip2Decoder().decodeBytes(bytes);
    debugPrint(
        '📦 ModelDownloadService: BZip2 decoded (${bzip2.length} bytes)');
    final archive = TarDecoder().decodeBytes(bzip2);
    debugPrint(
        '📦 ModelDownloadService: Tar decoded (${archive.length} files)');

    int count = 0;
    for (final file in archive) {
      final filename = file.name;
      if (file.isFile) {
        final data = file.content as List<int>;
        final outFile = File('$destDir/$filename');
        await outFile.parent.create(recursive: true);
        await outFile.writeAsBytes(data);
      } else {
        await Directory('$destDir/$filename').create(recursive: true);
      }
      count++;
      if (count % 10 == 0)
        debugPrint('📦 ModelDownloadService: Extracted $count files...');
    }
    debugPrint(
        '📦 ModelDownloadService: Extraction complete ($count files total)');
  }

  Future<bool> isModelDownloaded() async {
    final docDir = await StorageUtils.getNoBackupDirectory();
    final modelFolder = Directory(
        '${docDir.path}/models/sherpa-onnx-asr-ar-arabic-zipformer-2023-11-21');
    return await modelFolder.exists() &&
        await File('${modelFolder.path}/encoder.onnx').exists();
  }
}
