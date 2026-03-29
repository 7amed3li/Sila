import 'dart:async';
import 'dart:io';

import 'package:audio_session/audio_session.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:quran/quran.dart' as quran;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sila_app/core/providers/reciter_provider.dart';
import 'package:sila_app/core/services/analytics_service.dart';
import 'package:sila_app/core/services/notification_service.dart';
import 'package:sila_app/core/services/reciter_service.dart';
import 'package:sila_app/features/quran/presentation/riverpod/quran_data_provider.dart';

part 'audio_controller.g.dart';

// Singleton audio player - shared across all instances
// This prevents multiple AudioPlayer instances from interrupting each other
class _AudioPlayerSingleton {
  factory _AudioPlayerSingleton() => _instance;
  _AudioPlayerSingleton._internal();
  static final _AudioPlayerSingleton _instance =
      _AudioPlayerSingleton._internal();

  AudioPlayer player = AudioPlayer();
  bool isLoading = false;
  String? currentUrl;
  bool isDisposed = false;
}

class AudioCacheStats {
  const AudioCacheStats({
    required this.totalBytes,
    required this.totalFiles,
    required this.bytesByFolder,
  });
  final int totalBytes;
  final int totalFiles;
  final Map<String, int> bytesByFolder;
}

class AudioState {
  final AudioPlayer player;
  final Map<int, double> downloadProgress; // surahNumber -> 0.0 to 1.0
  final bool isDownloadingAll;
  final int? currentPlayingSurah;
  final bool playing;
  final Map<int, CancelToken> downloadCancelTokens; // NEW: لإيقاف التحميلات

  AudioState({
    required this.player,
    this.downloadProgress = const {},
    this.isDownloadingAll = false,
    this.currentPlayingSurah,
    this.playing = false,
    this.downloadCancelTokens = const {}, // NEW
  });

  AudioState copyWith({
    AudioPlayer? player,
    Map<int, double>? downloadProgress,
    bool? isDownloadingAll,
    int? currentPlayingSurah,
    bool? playing,
    Map<int, CancelToken>? downloadCancelTokens, // NEW
  }) {
    return AudioState(
      player: player ?? this.player,
      downloadProgress: downloadProgress ?? this.downloadProgress,
      isDownloadingAll: isDownloadingAll ?? this.isDownloadingAll,
      currentPlayingSurah: currentPlayingSurah ?? this.currentPlayingSurah,
      playing: playing ?? this.playing,
      downloadCancelTokens:
          downloadCancelTokens ?? this.downloadCancelTokens, // NEW
    );
  }
}

@riverpod
class AudioController extends _$AudioController {
  final _singleton = _AudioPlayerSingleton();
  final Dio _dio = Dio();
  final Set<String> _activeDownloads = <String>{};

  static const int _maxCacheSizeBytes = 500 * 1024 * 1024; // 500 MB

  Stream<void> get onPlayerComplete => _singleton.player.playerStateStream
      .where((state) => state.processingState == ProcessingState.completed)
      .map((_) {});

  @override
  AudioState build() {
    // Use ref.onDispose to clean up listener
    ref.onDispose(() {
      // Cleanup if needed
    });

    return AudioState(
      player: _singleton.player,
      playing: _singleton.player.playing,
    );
  }

  void updatePlayingState(bool playing) {
    state = state.copyWith(playing: playing);
  }

  Future<void> playAyah(int surahNumber, int ayahNumber) async {
    final reciter = ref.read(reciterControllerProvider).valueOrNull ??
        ReciterService.getById(ReciterService.defaultReciterId);
    final fileName =
        '${surahNumber.toString().padLeft(3, '0')}${ayahNumber.toString().padLeft(3, '0')}.mp3';
    final url = '${reciter.baseUrl}${reciter.folderName}/$fileName';

    await playAudio(
      url,
      surahName: quran.getSurahNameArabic(surahNumber),
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
    );
  }

  Future<void> playAudio(
    String url, {
    String? surahName,
    int? surahNumber,
    int? ayahNumber,
  }) async {
    // THIS is the critical fix - use singleton's isLoading flag
    // This ensures that even if riverpod creates multiple controller instances,
    // they all share the same loading state
    if (_singleton.isLoading) {
      return;
    }

    // If same URL is already playing, restart it
    if (_singleton.currentUrl == url && _singleton.player.playing) {
      await _singleton.player.seek(Duration.zero);
      return;
    }

    _singleton.isLoading = true;

    try {
      if (_singleton.isDisposed) {
        _singleton.player = AudioPlayer();
        _singleton.isDisposed = false;
      }

      // Ensure audio session is configured for speech (allows both play/record)
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration.speech());
      await session.setActive(true);

      await _singleton.player.stop();

      _singleton.currentUrl = url;

      final source = await _resolvePlayableSource(url);

      if (source.startsWith('http')) {
        await _singleton.player.setUrl(source);
      } else {
        await _touchCacheFile(source);
        await _singleton.player.setFilePath(source);
      }

      if (surahName != null && ayahNumber != null) {
        await ref.read(analyticsServiceProvider).logPlayAudio(
              surahName: surahName,
              ayahNumber: ayahNumber,
            );
      }

      // Start playback
      await _singleton.player.play();
      state = state.copyWith(
        currentPlayingSurah: surahNumber,
        playing: true,
      );

      unawaited(_prefetchNextAyah(url));
    } on PlayerException {
      _singleton.currentUrl = null;
      state = state.copyWith(currentPlayingSurah: null, playing: false);
      rethrow;
    } on PlayerInterruptedException {
      _singleton.currentUrl = null;
      state = state.copyWith(currentPlayingSurah: null, playing: false);
      rethrow;
    } catch (e) {
      _singleton.currentUrl = null;
      state = state.copyWith(currentPlayingSurah: null, playing: false);
      rethrow;
    } finally {
      _singleton.isLoading = false;
    }
  }

  Future<void> stopAudio() async {
    await _singleton.player.stop();
    _singleton.currentUrl = null;
    _singleton.isLoading = false;
    state = state.copyWith(currentPlayingSurah: null, playing: false);
    state = state.copyWith(currentPlayingSurah: null);

    // Explicitly deactivate audio session to release focus for STT
    try {
      final session = await AudioSession.instance;
      await session.setActive(false);
    } catch (_) {}
  }

  /// ✅ NEW: إيقاف تحميل سورة محددة فوراً
  void cancelDownload(int surahNumber) {
    final cancelToken = state.downloadCancelTokens[surahNumber];
    if (cancelToken != null) {
      try {
        cancelToken.cancel('تم الإيقاف من قبل المستخدم');
      } catch (_) {
        // قد يكون تم إلغاء القيمة مسبقاً
      }

      // أزل من القائمة
      final updatedTokens =
          Map<int, CancelToken>.from(state.downloadCancelTokens);
      updatedTokens.remove(surahNumber);

      state = state.copyWith(downloadCancelTokens: updatedTokens);
    }
  }

  /// ✅ NEW: إيقاف جميع التحميلات
  void cancelAllDownloads() {
    for (final cancelToken in state.downloadCancelTokens.values) {
      try {
        cancelToken.cancel('تم إيقاف كل التحميلات');
      } catch (_) {
        // قد يكون تم إلغاء القيمة مسبقاً
      }
    }

    state = state.copyWith(
      downloadCancelTokens: {},
      isDownloadingAll: false,
    );
  }

  Future<void> pauseAudio() async {
    await _singleton.player.pause();
    state = state.copyWith(playing: false);
  }

  Future<void> resumeAudio() async {
    await _singleton.player.play();
    state = state.copyWith(playing: true);
  }

  Future<void> disposeSession() async {
    await _singleton.player.dispose();
    _singleton.currentUrl = null;
    _singleton.isLoading = false;
    _singleton.isDisposed = true;
  }

  Future<AudioCacheStats> getCacheStats() async {
    final root = await _audioCacheRoot();
    if (!root.existsSync()) {
      return const AudioCacheStats(
          totalBytes: 0, totalFiles: 0, bytesByFolder: {});
    }

    final byFolder = <String, int>{};
    var totalBytes = 0;
    var totalFiles = 0;

    for (final entity in root.listSync(recursive: true)) {
      if (entity is! File) continue;
      if (!entity.path.toLowerCase().endsWith('.mp3')) continue;

      final len = entity.lengthSync();
      totalBytes += len;
      totalFiles++;

      final parts = entity.path.split(Platform.pathSeparator);
      final cacheIndex = parts.lastIndexOf('audio_cache');
      final folder = (cacheIndex >= 0 && cacheIndex + 1 < parts.length)
          ? parts[cacheIndex + 1]
          : 'unknown';
      byFolder[folder] = (byFolder[folder] ?? 0) + len;
    }

    return AudioCacheStats(
      totalBytes: totalBytes,
      totalFiles: totalFiles,
      bytesByFolder: byFolder,
    );
  }

  Future<void> clearAllCache() async {
    final root = await _audioCacheRoot();
    if (root.existsSync()) {
      root.deleteSync(recursive: true);
    }
  }

  Future<void> clearReciterCacheById(String reciterId) async {
    final reciter = ReciterService.getById(reciterId);
    final root = await _audioCacheRoot();
    final reciterDir =
        Directory('${root.path}${Platform.pathSeparator}${reciter.folderName}');
    if (reciterDir.existsSync()) {
      reciterDir.deleteSync(recursive: true);
    }
  }

  /// Checks if all ayahs of a surah are downloaded for the current reciter
  Future<bool> isSurahDownloaded(int surahNumber,
      [ReciterModel? targetReciter]) async {
    final reciter = targetReciter ??
        ref.read(reciterControllerProvider).valueOrNull ??
        ReciterService.getById(ReciterService.defaultReciterId);
    final appDir = await getApplicationDocumentsDirectory();
    final reciterDir = Directory(
        '${appDir.path}${Platform.pathSeparator}audio_cache${Platform.pathSeparator}${reciter.folderName}');

    if (!reciterDir.existsSync()) return false;

    final verseCount = quran.getVerseCount(surahNumber);
    for (var i = 1; i <= verseCount; i++) {
      final fileName =
          '${surahNumber.toString().padLeft(3, '0')}${i.toString().padLeft(3, '0')}.mp3';
      final file = File('${reciterDir.path}${Platform.pathSeparator}$fileName');
      if (!file.existsSync()) return false;
    }
    return true;
  }

  /// Downloads all ayahs for a given surah
  Future<void> downloadSurah(int surahNumber,
      [ReciterModel? targetReciter]) async {
    final reciter = targetReciter ??
        ref.read(reciterControllerProvider).valueOrNull ??
        ReciterService.getById(ReciterService.defaultReciterId);
    final verseCount = quran.getVerseCount(surahNumber);
    final baseUrl = reciter.baseUrl;

    final appDir = await getApplicationDocumentsDirectory();
    final reciterDir = Directory(
        '${appDir.path}${Platform.pathSeparator}audio_cache${Platform.pathSeparator}${reciter.folderName}');
    if (!reciterDir.existsSync()) reciterDir.createSync(recursive: true);

    // Initialize notification service and show initial notification
    final notificationService = NotificationService();
    final locale = ref.read(appLocaleProvider).languageCode;
    final surahName = quran.getSurahNameArabic(surahNumber);

    // Show initial download notification
    unawaited(notificationService.showQuranDownloadProgress(
      id: 9000 + surahNumber,
      locale: locale,
      percent: 0,
      reciterName: '$surahName - ${reciter.nameArabic}',
    ));

    const batchSize = 5;
    final totalBatches = (verseCount / batchSize).ceil();
    var currentBatch = 0;

    for (var i = 1; i <= verseCount; i += batchSize) {
      if (_isDownloadStopped) break;

      currentBatch++;
      final end =
          (i + batchSize - 1) > verseCount ? verseCount : (i + batchSize - 1);
      final futures = <Future<void>>[];

      for (var j = i; j <= end; j++) {
        final fileName =
            '${surahNumber.toString().padLeft(3, '0')}${j.toString().padLeft(3, '0')}.mp3';
        final url = '${baseUrl}${reciter.folderName}/$fileName';
        final targetPath =
            '${reciterDir.path}${Platform.pathSeparator}$fileName';
        futures.add(_cacheInBackground(url, targetPath));
      }

      await Future.wait(futures);

      // Update progress notification
      final percent = (currentBatch * 100 / totalBatches).toInt();
      unawaited(notificationService.showQuranDownloadProgress(
        id: 9000 + surahNumber,
        locale: locale,
        percent: percent,
        reciterName: '$surahName - ${reciter.nameArabic}',
      ));
    }

    // Hide notification when complete
    unawaited(notificationService.cancelNotification(9000 + surahNumber));

    // Force UI update - defer to avoid circular dependency
    Future.microtask(
        () => ref.invalidate(surahDownloadStatusProvider(surahNumber)));
  }

  bool _isDownloadPaused = false;
  bool _isDownloadStopped = false;

  void toggleDownloadPause() {
    _isDownloadPaused = !_isDownloadPaused;
    state = state.copyWith(isDownloadingAll: !_isDownloadPaused);
  }

  void stopDownloadBatch() {
    _isDownloadStopped = true;
    _isDownloadPaused = false;
    state = state.copyWith(isDownloadingAll: false);
  }

  /// Downloads all 114 surahs for the current reciter
  Future<void> downloadAllSurahs([ReciterModel? targetReciter]) async {
    if (state.isDownloadingAll) {
      return; // Already downloading
    }

    final reciter = targetReciter ??
        ref.read(reciterControllerProvider).valueOrNull ??
        ReciterService.getById(ReciterService.defaultReciterId);

    _isDownloadStopped = false;
    _isDownloadPaused = false;
    state = state.copyWith(isDownloadingAll: true);

    try {
      final notificationService = NotificationService();
      // Get current locale from our provider
      final activeLocale = ref.read(appLocaleProvider);
      final locale = activeLocale.languageCode;

      // Wire notification callbacks
      notificationService.onPauseDownload = () {
        toggleDownloadPause();
        if (_isDownloadPaused) {
          notificationService.showQuranDownloadProgress(
            id: 9999,
            locale: locale,
            percent: (state.downloadProgress.length / 114 * 100)
                .toInt()
                .clamp(0, 100), // ✅ clamp
            reciterName: reciter.nameArabic,
            isPaused: true,
          );
        }
      };

      notificationService.onStopDownload = () {
        stopDownloadBatch();
      };

      for (var i = 1; i <= 114; i++) {
        // Check if stopped
        if (_isDownloadStopped) break;

        // Handle Pause
        while (_isDownloadPaused && !_isDownloadStopped) {
          await Future.delayed(const Duration(seconds: 1));
        }
        if (_isDownloadStopped) break;

        // Skip if already downloaded
        final isDownloaded = await isSurahDownloaded(i);
        if (isDownloaded) {
          final progressMap = Map<int, double>.from(state.downloadProgress);
          progressMap[i] = 1.0;
          state = state.copyWith(downloadProgress: progressMap);
          continue;
        }

        // Update notification every surah
        final overallProgress = (i / 114 * 100).toInt();
        unawaited(notificationService.showQuranDownloadProgress(
          id: 9999,
          locale: locale,
          percent: overallProgress,
          reciterName: reciter.nameArabic,
        ));

        await downloadSurah(i);

        // Update state progress
        final progressMap = Map<int, double>.from(state.downloadProgress);
        progressMap[i] = 1.0;
        state = state.copyWith(downloadProgress: progressMap);
      }

      if (!_isDownloadStopped) {
        unawaited(notificationService.showInstantNotification(
          id: 9999,
          title: 'download_all'.tr(),
          body: '✅ تم تحميل المصحف الصوتي كاملاً للشيخ ${reciter.nameArabic}',
        ));
      }
    } catch (e) {
      debugPrint('Error in downloadAllSurahs: $e');
    } finally {
      state = state.copyWith(isDownloadingAll: false);
      // Clear callbacks
      NotificationService().onPauseDownload = null;
      NotificationService().onStopDownload = null;
    }
  }

  Future<String> _resolvePlayableSource(String url) async {
    try {
      final uri = Uri.parse(url);
      if (!uri.hasScheme || !(uri.scheme == 'http' || uri.scheme == 'https')) {
        return url;
      }

      final segments = uri.pathSegments;
      if (segments.length < 3) {
        return url;
      }

      final folder = segments[segments.length - 2];
      final fileName = segments.last;

      final appDir = await getApplicationDocumentsDirectory();
      final reciterDir = Directory(
          '${appDir.path}${Platform.pathSeparator}audio_cache${Platform.pathSeparator}$folder');
      if (!reciterDir.existsSync()) {
        reciterDir.createSync(recursive: true);
      }

      final localFile =
          File('${reciterDir.path}${Platform.pathSeparator}$fileName');
      if (localFile.existsSync()) {
        await _touchCacheFile(localFile.path);
        return localFile.path;
      }

      unawaited(_cacheInBackground(url, localFile.path));

      // Start instantly from network on first play to avoid long wait.
      return url;
    } catch (_) {
      return url;
    }
  }

  Future<void> _cacheInBackground(String url, String targetPath) async {
    try {
      final target = File(targetPath);
      if (target.existsSync()) return;
      if (_activeDownloads.contains(target.path)) return;

      _activeDownloads.add(target.path);
      await _ensureCacheSizeAvailable(approxIncomingBytes: 350000);
      await _dio.download(url, target.path);
      await _touchCacheFile(target.path);
      await _ensureCacheSizeAvailable(approxIncomingBytes: 0);
    } catch (_) {
      // Ignore background cache failures to keep playback fast.
    } finally {
      _activeDownloads.remove(targetPath);
    }
  }

  Future<void> _prefetchNextAyah(String currentUrl) async {
    try {
      final uri = Uri.parse(currentUrl);
      final segments = uri.pathSegments;
      if (segments.length < 3) return;

      final folder = segments[segments.length - 2];
      final fileName = segments.last;
      if (!fileName.endsWith('.mp3')) return;

      final code = fileName.replaceAll('.mp3', '');
      if (code.length != 6) return;

      final surah = int.tryParse(code.substring(0, 3));
      final ayah = int.tryParse(code.substring(3, 6));
      if (surah == null || ayah == null) return;

      final maxAyah = quran.getVerseCount(surah);
      var nextSurah = surah;
      var nextAyah = ayah + 1;
      if (nextAyah > maxAyah) {
        nextSurah = surah + 1;
        nextAyah = 1;
      }
      if (nextSurah > 114) return;

      final surahStr = nextSurah.toString().padLeft(3, '0');
      final ayahStr = nextAyah.toString().padLeft(3, '0');
      final nextFile = '$surahStr$ayahStr.mp3';
      final nextUrl = '${uri.scheme}://${uri.host}/data/$folder/$nextFile';

      final appDir = await getApplicationDocumentsDirectory();
      final reciterDir = Directory(
          '${appDir.path}${Platform.pathSeparator}audio_cache${Platform.pathSeparator}$folder');
      if (!reciterDir.existsSync()) {
        reciterDir.createSync(recursive: true);
      }

      final nextLocal =
          File('${reciterDir.path}${Platform.pathSeparator}$nextFile');
      if (nextLocal.existsSync() || _activeDownloads.contains(nextLocal.path)) {
        return;
      }

      unawaited(_cacheInBackground(nextUrl, nextLocal.path));
    } catch (_) {
      // Silent prefetch fallback.
    }
  }

  Future<void> _touchCacheFile(String path) async {
    try {
      final file = File(path);
      if (file.existsSync()) {
        await file.setLastModified(DateTime.now());
      }
    } catch (_) {}
  }

  int? _cachedTotalSize;
  DateTime? _lastSizeCheck;

  Future<void> _ensureCacheSizeAvailable(
      {required int approxIncomingBytes}) async {
    final root = await _audioCacheRoot();
    if (!root.existsSync()) return;

    // Only re-scan directory every 60 seconds or if cache is invalidated
    final now = DateTime.now();
    if (_cachedTotalSize == null ||
        _lastSizeCheck == null ||
        now.difference(_lastSizeCheck!).inSeconds > 60) {
      _cachedTotalSize = _directorySize(root);
      _lastSizeCheck = now;
    }

    if (_cachedTotalSize! + approxIncomingBytes <= _maxCacheSizeBytes) return;

    final files = root
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.toLowerCase().endsWith('.mp3'))
        .toList()
      ..sort((a, b) => a.lastModifiedSync().compareTo(b.lastModifiedSync()));

    for (final file in files) {
      if (_cachedTotalSize! + approxIncomingBytes <= _maxCacheSizeBytes) break;
      if (_activeDownloads.contains(file.path)) continue;
      final len = file.lengthSync();
      file.deleteSync();
      _cachedTotalSize = _cachedTotalSize! - len;
    }
  }

  Future<Directory> _audioCacheRoot() async {
    final appDir = await getApplicationDocumentsDirectory();
    return Directory('${appDir.path}${Platform.pathSeparator}audio_cache');
  }

  int _directorySize(Directory directory) {
    var total = 0;
    for (final entity in directory.listSync(recursive: true)) {
      if (entity is File) {
        total += entity.lengthSync();
      }
    }
    return total;
  }
}

@riverpod
class PlayingAyahId extends _$PlayingAyahId {
  @override
  int? build() => null;

  void setPlaying(int? ayahNumber) {
    state = ayahNumber;
  }
}

final surahDownloadStatusProvider =
    FutureProvider.family<bool, int>((ref, surahNumber) {
  // Watch reciter so we re-check when it changes globally
  ref.watch(reciterControllerProvider);
  return ref
      .watch(audioControllerProvider.notifier)
      .isSurahDownloaded(surahNumber);
});
