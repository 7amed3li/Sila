import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sila_app/core/services/audio_download_service.dart';
import 'package:sila_app/core/services/notification_service.dart';
import 'package:sila_app/core/services/reciter_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:intl/intl.dart' as intl;

class AudioDownloadState {

  const AudioDownloadState({
    required this.isDownloading,
    required this.isCompleted,
    required this.isCancelled,
    required this.errorMessage,
    required this.completed,
    required this.total,
    required this.surah,
    required this.ayah,
    required this.reciterId,
    required this.completedReciters,
    required this.totalReciters,
  });

  factory AudioDownloadState.initial() {
    return const AudioDownloadState(
      isDownloading: false,
      isCompleted: false,
      isCancelled: false,
      errorMessage: null,
      completed: 0,
      total: 0,
      surah: 0,
      ayah: 0,
      reciterId: null,
      completedReciters: 0,
      totalReciters: 0,
    );
  }
  final bool isDownloading;
  final bool isCompleted;
  final bool isCancelled;
  final String? errorMessage;
  final int completed;
  final int total;
  final int surah;
  final int ayah;
  final String? reciterId;
  final int completedReciters;
  final int totalReciters;

  double get progress => total == 0 ? 0 : completed / total;

  AudioDownloadState copyWith({
    bool? isDownloading,
    bool? isCompleted,
    bool? isCancelled,
    String? errorMessage,
    bool clearError = false,
    int? completed,
    int? total,
    int? surah,
    int? ayah,
    String? reciterId,
    int? completedReciters,
    int? totalReciters,
  }) {
    return AudioDownloadState(
      isDownloading: isDownloading ?? this.isDownloading,
      isCompleted: isCompleted ?? this.isCompleted,
      isCancelled: isCancelled ?? this.isCancelled,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      completed: completed ?? this.completed,
      total: total ?? this.total,
      surah: surah ?? this.surah,
      ayah: ayah ?? this.ayah,
      reciterId: reciterId ?? this.reciterId,
      completedReciters: completedReciters ?? this.completedReciters,
      totalReciters: totalReciters ?? this.totalReciters,
    );
  }
}

class AudioDownloadController extends StateNotifier<AudioDownloadState> {
  AudioDownloadController() : super(AudioDownloadState.initial());

  CancelToken? _cancelToken;

  Future<void> downloadForAllReciters() async {
    if (state.isDownloading) return;

    const reciters = ReciterService.availableReciters;
    final totalAyahs = await AudioDownloadService.totalAyahCount();
    final totalGlobal = totalAyahs * reciters.length;

    state = state.copyWith(
      isDownloading: true,
      isCompleted: false,
      isCancelled: false,
      clearError: true,
      completed: 0,
      total: totalGlobal,
      surah: 1,
      ayah: 1,
      reciterId: reciters.first.id,
      completedReciters: 0,
      totalReciters: reciters.length,
    );

    _cancelToken = CancelToken();
    var globalCompleted = 0;
    var completedReciters = 0;

    try {
      for (final reciter in reciters) {
        state = state.copyWith(reciterId: reciter.id, completedReciters: completedReciters);

        await AudioDownloadService.downloadAllForReciter(
          reciter,
          cancelToken: _cancelToken,
          onProgress: (progress) {
            state = state.copyWith(
              completed: globalCompleted + progress.completed,
              total: totalGlobal,
              surah: progress.surah,
              ayah: progress.ayah,
              reciterId: reciter.id,
            );

            // Update system notification
            final currentLocale = intl.Intl.getCurrentLocale().split('_').first;
            final overallPercent = ((state.completed / state.total) * 100).toInt();
            NotificationService().showQuranDownloadProgress(
              id: NotificationService.downloadNotificationId,
              locale: currentLocale,
              percent: overallPercent,
              reciterName: currentLocale == 'ar' ? reciter.nameArabic : reciter.nameEnglish,
            );
          },
        );

        completedReciters++;
        globalCompleted = completedReciters * totalAyahs;
        state = state.copyWith(completedReciters: completedReciters, completed: globalCompleted);
      }

      state = state.copyWith(
        isDownloading: false,
        isCompleted: true,
        isCancelled: false,
        completed: state.total,
      );
      
      // Clear notification on success
      NotificationService().hideModelDownloadNotification(); // Reusing or specific
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        state = state.copyWith(isDownloading: false, isCancelled: true, isCompleted: false);
      } else {
        state = state.copyWith(
          isDownloading: false,
          isCompleted: false,
          errorMessage: e.message ?? 'حدث خطأ أثناء تنزيل كل الأصوات',
        );
      }
    } catch (e) {
      state = state.copyWith(
        isDownloading: false,
        isCompleted: false,
        errorMessage: e.toString(),
      );
    }
  }

  void cancelDownload() {
    _cancelToken?.cancel('user_cancelled');
  }
}

final audioDownloadControllerProvider =
    StateNotifierProvider<AudioDownloadController, AudioDownloadState>(
  (ref) => AudioDownloadController(),
);

final audioAvailabilityProvider = FutureProvider<bool>((ref) async {
  // We can't easily watch the current reciter here without knowing which one is selected globally.
  // For now, we'll check the default reciter or all available reciters.
  const reciters = ReciterService.availableReciters;
  for (final reciter in reciters) {
    if (await AudioDownloadService.isAnyAudioDownloaded(reciter)) {
      return true;
    }
  }
  return false;
});
