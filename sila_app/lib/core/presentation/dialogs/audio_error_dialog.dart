import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:sila_app/core/services/audio_exceptions.dart';

/// Helper class لعرض رسائل الخطأ المترجمة للمستخدم
class AudioErrorDialog {
  /// عرض رسالة خطأ عند عدم تحميل الملف
  static Future<void> showFileNotDownloaded(
    BuildContext context, {
    required String surahName,
    required VoidCallback onDownloadPressed,
  }) async {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('download_required'.tr()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'audio_playback_errors.file_not_downloaded'.tr(args: [surahName]),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            SizedBox(height: 16),
            Text(
              '💡 نصيحة: جميع الملفات محفوظة على جهازك وتعمل بدون إنترنت بعد التحميل',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.blue[700],
                  ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onDownloadPressed();
            },
            child: Text('audio_playback_errors.tap_download'.tr()),
          ),
        ],
      ),
    );
  }

  /// عرض رسالة تحذير عند فشل التحميل الجزئي
  static Future<void> showPartialDownload(
    BuildContext context, {
    required String surahName,
    required int downloadedCount,
    required int totalCount,
    required VoidCallback onRetryPressed,
  }) async {
    final percentage = ((downloadedCount / totalCount) * 100).toInt();

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('⚠️ تحذير'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'audio_playback_errors.partial_download'.tr(),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            SizedBox(height: 12),
            LinearProgressIndicator(
              value: downloadedCount / totalCount,
              minHeight: 8,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                percentage >= 80 ? Colors.orange : Colors.red,
              ),
            ),
            SizedBox(height: 12),
            Text(
              '${downloadedCount}/${totalCount} آية ($percentage%)',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onRetryPressed();
            },
            child: Text('retry'.tr()),
          ),
        ],
      ),
    );
  }

  /// عرض رسالة خطأ عند فشل التشغيل
  static Future<void> showPlaybackError(
    BuildContext context, {
    required Exception exception,
    required String surahName,
    required VoidCallback onRetryPressed,
  }) async {
    String errorMessage = 'playback_failed'.tr();

    if (exception is AudioFileNotDownloadedException) {
      errorMessage = exception.message;
    } else if (exception is AudioFileCorruptedException) {
      errorMessage = exception.message;
    } else if (exception is AudioDownloadFailedException) {
      errorMessage = exception.message;
    }

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('❌ خطأ في التشغيل'),
        content: Text(errorMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('close'.tr()),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onRetryPressed();
            },
            child: Text('retry'.tr()),
          ),
        ],
      ),
    );
  }

  /// عرض snackbar عند بدء إعادة محاولة التحميل
  static void showRetryingSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('audio_playback_errors.retrying_download'.tr()),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// عرض snackbar عند نجاح التحميل
  static void showSuccessSnackBar(
    BuildContext context, {
    required String surahName,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '✅ $surahName تم تحميلها بنجاح',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
