import 'dart:async';
import 'dart:io';

import 'package:audio_session/audio_session.dart';
import 'package:dio/dio.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:quran/quran.dart' as quran;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sila_app/core/services/analytics_service.dart';
import 'package:sila_app/core/services/reciter_service.dart';

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
  Raw<AudioPlayer> build() {
    // Dispose is handled by the singleton, not by individual instances
    return _singleton.player;
  }

  Future<void> playAudio(
    String url, {
    String? surahName,
    int? surahNumber,
    int? ayahNumber,
    bool useDuckingFocus = false,
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

      await _configureAudioSession(useDuckingFocus: useDuckingFocus);

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

      unawaited(_prefetchNextAyah(url));
    } on PlayerException {
      _singleton.currentUrl = null;
      rethrow;
    } on PlayerInterruptedException {
      _singleton.currentUrl = null;
      rethrow;
    } catch (e) {
      _singleton.currentUrl = null;
      rethrow;
    } finally {
      _singleton.isLoading = false;
    }
  }

  Future<void> stopAudio() async {
    await _singleton.player.stop();
    try {
      final session = await AudioSession.instance;
      await session.setActive(false);
    } catch (_) {
      // Keep stop resilient even if session release fails.
    }
    _singleton.currentUrl = null;
    _singleton.isLoading = false;
  }

  Future<void> _configureAudioSession({required bool useDuckingFocus}) async {
    final session = await AudioSession.instance;

    if (useDuckingFocus) {
      await session.configure(
        const AudioSessionConfiguration(
          avAudioSessionCategory: AVAudioSessionCategory.playback,
          avAudioSessionMode: AVAudioSessionMode.spokenAudio,
          avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.duckOthers,
          androidAudioAttributes: AndroidAudioAttributes(
            contentType: AndroidAudioContentType.speech,
            usage: AndroidAudioUsage.media,
          ),
          androidAudioFocusGainType:
              AndroidAudioFocusGainType.gainTransientMayDuck,
          androidWillPauseWhenDucked: false,
        ),
      );
      return;
    }

    await session.configure(const AudioSessionConfiguration.music());
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

  Future<void> _ensureCacheSizeAvailable(
      {required int approxIncomingBytes}) async {
    final root = await _audioCacheRoot();
    if (!root.existsSync()) return;

    var total = _directorySize(root);
    if (total + approxIncomingBytes <= _maxCacheSizeBytes) return;

    final files = root
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.toLowerCase().endsWith('.mp3'))
        .toList()
      ..sort((a, b) => a.lastModifiedSync().compareTo(b.lastModifiedSync()));

    for (final file in files) {
      if (total + approxIncomingBytes <= _maxCacheSizeBytes) break;
      if (_activeDownloads.contains(file.path)) continue;
      final len = file.lengthSync();
      file.deleteSync();
      total -= len;
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

// State provider to track currently playing Ayah ID (for highlighting)
@riverpod
class PlayingAyahId extends _$PlayingAyahId {
  @override
  int? build() => null;

  void setPlaying(int? ayahNumber) {
    state = ayahNumber;
  }
}
