import 'package:flutter/foundation.dart';

/// Exception عند محاولة تشغيل ملف لم يتم تحميله
class AudioFileNotDownloadedException implements Exception {
  AudioFileNotDownloadedException({
    required this.surahNumber,
    required this.surahName,
    required this.locale,
  });

  final int surahNumber;
  final String surahName;
  final String locale;

  String get message {
    switch (locale) {
      case 'ar':
        return 'الملف الصوتي لسورة $surahName لم يتم تحميله. يرجى تحميله أولاً من قائمة التحميلات.';
      case 'en':
        return 'Audio file for Surah $surahName has not been downloaded. Please download it first.';
      case 'fr':
        return 'Le fichier audio de la Sourate $surahName n\'a pas été téléchargé. Veuillez le télécharger d\'abord.';
      case 'tr':
        return '$surahName Suresinin ses dosyası indirilmemiştir. Lütfen önce indirin.';
      default:
        return 'Audio file for Surah $surahName has not been downloaded.';
    }
  }

  @override
  String toString() => message;
}

/// Exception عند محاولة تشغيل ملف تالف
class AudioFileCorruptedException implements Exception {
  AudioFileCorruptedException({
    required this.surahNumber,
    required this.ayahNumber,
    required this.fileSize,
    required this.locale,
  });

  final int surahNumber;
  final int ayahNumber;
  final int fileSize;
  final String locale;

  String get message {
    switch (locale) {
      case 'ar':
        return 'الملف الصوتي تالف أو ناقص (حجمه $fileSize بايت فقط). سيتم حذفه وإعادة تحميله تلقائياً.';
      case 'en':
        return 'Audio file is corrupted or incomplete ($fileSize bytes). It will be re-downloaded.';
      case 'fr':
        return 'Le fichier audio est corrompu ou incomplet ($fileSize octets). Il sera retéléchargé.';
      case 'tr':
        return 'Ses dosyası bozuk veya eksiktir ($fileSize bayt). Yeniden indirilecektir.';
      default:
        return 'Audio file is corrupted or incomplete ($fileSize bytes).';
    }
  }

  @override
  String toString() => message;
}

/// Exception عند فشل التحميل
class AudioDownloadFailedException implements Exception {
  AudioDownloadFailedException({
    required this.surahNumber,
    required this.surahName,
    required this.reason,
    required this.locale,
  });

  final int surahNumber;
  final String surahName;
  final String reason;
  final String locale;

  String get message {
    switch (locale) {
      case 'ar':
        return 'فشل تحميل سورة $surahName: $reason. يرجى التحقق من الإنترنت والمحاولة مرة أخرى.';
      case 'en':
        return 'Failed to download Surah $surahName: $reason. Please check your internet and try again.';
      case 'fr':
        return 'Échec du téléchargement de la Sourate $surahName: $reason. Veuillez vérifier votre connexion Internet.';
      case 'tr':
        return '$surahName Suresinin indirilmesi başarısız: $reason. Lütfen internet bağlantınızı kontrol edin.';
      default:
        return 'Failed to download Surah $surahName: $reason.';
    }
  }

  @override
  String toString() => message;
}
