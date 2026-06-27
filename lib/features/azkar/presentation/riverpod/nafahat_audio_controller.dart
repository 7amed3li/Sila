import 'dart:async';
import 'dart:io';

import 'package:just_audio/just_audio.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sila_app/features/azkar/data/models/ibtihal_model.dart';

part 'nafahat_audio_controller.g.dart';

class NafahatPlayerState {
  NafahatPlayerState({
    required this.fullPlaylist,
    required this.filteredPlaylist,
    this.currentIndex = 0,
    PlayerState? playerState,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.isLoading = false,
    this.sleepTimerDuration,
    this.sleepTimerEnd,
    this.selectedArtist,
  }) : playerState = playerState ?? PlayerState(false, ProcessingState.idle);
  final List<Ibtihal> fullPlaylist;
  final List<Ibtihal> filteredPlaylist;
  final int currentIndex;
  final PlayerState playerState;
  final Duration position;
  final Duration duration;
  final bool isLoading;
  final Duration? sleepTimerDuration;
  final DateTime? sleepTimerEnd;
  final String? selectedArtist;

  Ibtihal? get currentIbtihal =>
      filteredPlaylist.isNotEmpty && currentIndex < filteredPlaylist.length
          ? filteredPlaylist[currentIndex]
          : null;

  NafahatPlayerState copyWith({
    List<Ibtihal>? fullPlaylist,
    List<Ibtihal>? filteredPlaylist,
    int? currentIndex,
    PlayerState? playerState,
    Duration? position,
    Duration? duration,
    bool? isLoading,
    Duration? sleepTimerDuration,
    DateTime? sleepTimerEnd,
    String? selectedArtist,
    bool clearSleepTimer = false,
    bool clearArtist = false,
  }) {
    return NafahatPlayerState(
      fullPlaylist: fullPlaylist ?? this.fullPlaylist,
      filteredPlaylist: filteredPlaylist ?? this.filteredPlaylist,
      currentIndex: currentIndex ?? this.currentIndex,
      playerState: playerState ?? this.playerState,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      isLoading: isLoading ?? this.isLoading,
      sleepTimerDuration: clearSleepTimer
          ? null
          : (sleepTimerDuration ?? this.sleepTimerDuration),
      sleepTimerEnd:
          clearSleepTimer ? null : (sleepTimerEnd ?? this.sleepTimerEnd),
      selectedArtist:
          clearArtist ? null : (selectedArtist ?? this.selectedArtist),
    );
  }
}

@Riverpod(keepAlive: true)
class NafahatAudioController extends _$NafahatAudioController {
  late AudioPlayer _player;
  Timer? _sleepTimer;
  int _currentPlaySessionId = 0;

  static const String _nakshabandiBaseUrl =
      'https://archive.org/download/20240309_20240309_1714/';
  static const String _alToukhyBaseUrl =
      'https://archive.org/download/Mohammed_Al_Tokhi_Ibtihalat/';

  static const String _nakshabandiName = 'الشيخ سيد النقشبندي';
  static const String _alToukhyName = 'الشيخ محمد الطوخي';

  static final _defaultPlaylist = [
    // Nakshabandi
    _createIbtihal(
        'N01',
        'إبتهال قبضة الله',
        '001  إبتهال قبضة الله الشيخ سيد النقشبندي.mp3',
        _nakshabandiBaseUrl,
        _nakshabandiName),
    _createIbtihal(
        'N02',
        'ابتهالات كاملة',
        '002  ابتهالات الشيخ النقشبندى كامله.mp3',
        _nakshabandiBaseUrl,
        _nakshabandiName),
    _createIbtihal(
        'N03',
        'إبتهالات نادرة (١٩٦٤)',
        '003  إبتهالات نادرة جداللشيخ سيد النقشبندي من ساحة مسجد السيدة زينب بالقاهرة عام 1964مبصوت رائع وجميل.mp3',
        _nakshabandiBaseUrl,
        _nakshabandiName),
    _createIbtihal(
        'N04',
        'يا رب إن عظمت ذنوبي',
        '004  الشيخ سيد النقشبندى, يا رب ان عظمت ذنوبى كثرة.mp3',
        _nakshabandiBaseUrl,
        _nakshabandiName),
    _createIbtihal(
        'N05',
        'النفس تشكو',
        '005  النقشبندي - ابتهال النفس تشكو - كامل - جودة عالية.mp3',
        _nakshabandiBaseUrl,
        _nakshabandiName),
    _createIbtihal(
        'N08',
        'مولاي إني ببابك',
        '008  مولاي إني ببابك قد بسطت يدي   للشيخ النقشبندى.mp3',
        _nakshabandiBaseUrl,
        _nakshabandiName),
    _createIbtihal('N12', 'يا رب كرمك علينا', '012  يارب كرمك علينا.mp3',
        _nakshabandiBaseUrl, _nakshabandiName),
    _createIbtihal(
        'N13',
        'يا من له ستر علي',
        '013  يامن له ستر علي جميل  ابتهال الشيخ سيد النقشبندي_.mp3',
        _nakshabandiBaseUrl,
        _nakshabandiName),

    // Al-Toukhy
    const Ibtihal(
      id: 'T1',
      title: 'ابتهال نادر: من لي سواك',
      url:
          'https://archive.org/download/AshSheekhSeedAnNqshbndeeGlshKhastNadrtGdaMnMnzlhFtrtAsSb3eenyat/Ash-Sheekh%20Muhammad%20At-Tukhee%20abthal%20nadr%20mn%20lee%20swak%20mn%20slat%20fgr.mp3',
      artistName: 'محمد الطوخي',
    ),
  ];

  static Ibtihal _createIbtihal(
      String id, String title, String filename, String baseUrl, String artist) {
    return Ibtihal(
      id: id,
      title: title,
      url: '$baseUrl$filename',
      artistName: artist,
    );
  }

  @override
  NafahatPlayerState build() {
    _player = AudioPlayer();

    _player.playerStateStream.listen((ps) {
      if (state.isLoading != (ps.processingState == ProcessingState.loading)) {
        state = state.copyWith(
            playerState: ps,
            isLoading: ps.processingState == ProcessingState.loading);
      } else {
        state = state.copyWith(playerState: ps);
      }

      if (ps.processingState == ProcessingState.completed) {
        next();
      }
    });

    _player.positionStream.listen((pos) {
      state = state.copyWith(position: pos);
    });

    _player.durationStream.listen((dur) {
      if (dur != null) {
        state = state.copyWith(duration: dur);
      }
    });

    ref.onDispose(() {
      _sleepTimer?.cancel();
      _player.dispose();
    });

    return NafahatPlayerState(
      fullPlaylist: _defaultPlaylist,
      filteredPlaylist: _defaultPlaylist,
    );
  }

  void setArtistFilter(String? artist) {
    final filtered = artist == null
        ? _defaultPlaylist
        : _defaultPlaylist.where((i) => i.artistName == artist).toList();

    state = state.copyWith(
      selectedArtist: artist,
      filteredPlaylist: filtered,
      currentIndex: 0,
      clearArtist: artist == null,
    );

    // Ensure player is stopped before switching contexts
    _player.stop();
  }

  Future<void> playIbtihal(int index) async {
    if (index >= state.filteredPlaylist.length) return;

    // Increment session ID to cancel previous pending requests
    final sessionId = ++_currentPlaySessionId;

    try {
      state = state.copyWith(
        currentIndex: index,
        isLoading: true,
        position: Duration.zero,
        duration: Duration.zero,
      );

      final ibtihal = state.filteredPlaylist[index];
      final cacheDir = await getApplicationDocumentsDirectory();
      if (sessionId != _currentPlaySessionId) return; // Obsolete request

      final nafahatCacheDir = Directory(p.join(cacheDir.path, 'nafahat_cache'));
      if (!await nafahatCacheDir.exists()) {
        if (sessionId != _currentPlaySessionId) return;
        await nafahatCacheDir.create(recursive: true);
      }

      final fileName = '${ibtihal.id}.mp3';
      final cachePath = p.join(nafahatCacheDir.path, fileName);

      final source = AudioSource.uri(Uri.parse(ibtihal.url));

      if (sessionId != _currentPlaySessionId) return;
      await _player.setAudioSource(source);

      if (sessionId != _currentPlaySessionId) return;
      _player.play();
    } catch (e) {
      if (sessionId == _currentPlaySessionId) {
        state = state.copyWith(isLoading: false);
      }
      print('Error playing ibtihal: $e');
    }
  }

  Future<void> togglePlay() async {
    if (_player.processingState == ProcessingState.idle) {
      await playIbtihal(state.currentIndex);
    } else if (_player.playing) {
      _player.pause();
    } else {
      _player.play();
    }
  }

  void next() {
    if (state.filteredPlaylist.isEmpty) return;
    final nextIndex = (state.currentIndex + 1) % state.filteredPlaylist.length;
    playIbtihal(nextIndex);
  }

  void previous() {
    if (state.filteredPlaylist.isEmpty) return;
    final prevIndex = (state.currentIndex - 1 + state.filteredPlaylist.length) %
        state.filteredPlaylist.length;
    playIbtihal(prevIndex);
  }

  void seek(Duration position) {
    _player.seek(position);
  }

  void setSleepTimer(Duration? duration) {
    _sleepTimer?.cancel();
    _sleepTimer = null;

    if (duration == null) {
      state = state.copyWith(clearSleepTimer: true);
      return;
    }

    state = state.copyWith(
      sleepTimerDuration: duration,
      sleepTimerEnd: DateTime.now().add(duration),
    );

    _sleepTimer = Timer(duration, () {
      _player.pause();
      state = state.copyWith(clearSleepTimer: true);
    });
  }

  List<String> getAvailableArtists() {
    return _defaultPlaylist.map((i) => i.artistName).toSet().toList();
  }
}
