import 'dart:async';

import 'package:audio_session/audio_session.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

enum MicHealthStatus { active, reconnecting, stalled }

class TasmiSpeechService {
  factory TasmiSpeechService() => _instance ??= TasmiSpeechService._internal();
  TasmiSpeechService._internal();
  static TasmiSpeechService? _instance;

  final stt.SpeechToText _speech = stt.SpeechToText();
  final _wordController = StreamController<String>.broadcast();
  final _textController = StreamController<String>.broadcast();
  final _micHealthController = StreamController<MicHealthStatus>.broadcast();

  String _lastRecognizedWords = '';
  bool _isManuallyStopped = false;
  bool _isRestarting = false;
  bool _isPausedForTts = false;
  bool _autoRestartEnabled = true;
  Timer? _restartTimer;
  Timer? _watchdogTimer;
  DateTime? _lastWordReceivedAt;
  bool _isWatchdogHealing = false;
  bool _engineOpInFlight = false;
  Future<bool>? _engineOpFuture;
  Completer<void>? _ttsReleaseCompleter;
  Timer? _ttsResumeTimer;
  bool _isTtsExoPlayerActive = false;
  bool _audioFocusGranted = false;
  StreamSubscription<dynamic>? _audioFocusSubscription;
  DateTime? _lastFocusInterruptionAt;
  bool _focusRecoveryInProgress = false;
  bool _disposed = false;

  // ─── FIX 1+3: Audio focus conflict prevention ──────────────────────
  bool _isActive = false;
  bool Function()? _isAudioPlayingCheck;

  /// Set this to true only when a Tasmi/Hifz page is active.
  /// When false, watchdog and auto-restart are fully disabled.
  void setActive(bool active) {
    if (_isActive == active) {
      return;
    }

    _isActive = active;
    debugPrint('STT setActive: $active');
    if (!active) {
      _isManuallyStopped = true;
      // Page left — stop watchdog and restart timers immediately
      _restartTimer?.cancel();
      _watchdogTimer?.cancel();
      _watchdogTimer = null;
      _ttsResumeTimer?.cancel();
      _isRestarting = false;
      unawaited(_speech.cancel().catchError((_) {}));
      _audioFocusGranted = false;
      final subscription = _audioFocusSubscription;
      _audioFocusSubscription = null;
      if (subscription != null) {
        unawaited(subscription.cancel());
      }
      unawaited(
        AudioSession.instance
            .then((session) => session.setActive(false))
            .catchError((_) {}),
      );
    } else {
      _isManuallyStopped = false;
    }
  }

  /// Provide a callback that returns true if audio is currently playing.
  /// When audio is playing, STT will not auto-restart (avoids Audio Focus conflict).
  void setAudioPlayingCheck(bool Function() check) {
    _isAudioPlayingCheck = check;
  }

  Future<bool> _requestAudioFocusPermanent() async {
    try {
      final session = await AudioSession.instance;
      await session.configure(
        const AudioSessionConfiguration(
          androidAudioAttributes: AndroidAudioAttributes(
            contentType: AndroidAudioContentType.speech,
            usage: AndroidAudioUsage.voiceCommunication,
            flags: AndroidAudioFlags.none,
          ),
          androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
          androidWillPauseWhenDucked: false,
        ),
      );
      _audioFocusGranted = await session.setActive(true);
      return _audioFocusGranted;
    } catch (e) {
      debugPrint('Audio focus request failed: $e');
      _audioFocusGranted = false;
      return false;
    }
  }

  Future<void> _listenToAudioFocus() async {
    if (_disposed || !_isActive) {
      return;
    }

    final session = await AudioSession.instance;
    await _audioFocusSubscription?.cancel();
    _audioFocusSubscription = session.interruptionEventStream.listen((event) {
      if (!event.begin) {
        return;
      }

      // Duck interruptions are transient by design and should not force reset.
      if (event.type == AudioInterruptionType.duck) {
        return;
      }

      final now = DateTime.now();
      final last = _lastFocusInterruptionAt;
      if (last != null && now.difference(last) < const Duration(seconds: 2)) {
        return;
      }
      _lastFocusInterruptionAt = now;

      if (_focusRecoveryInProgress) {
        return;
      }

      _focusRecoveryInProgress = true;

      Future<void>.delayed(const Duration(milliseconds: 700), () async {
        try {
          if (!_isActive ||
              _isPausedForTts ||
              _isManuallyStopped ||
              _wordController.isClosed ||
              _disposed) {
            return;
          }

          // If recognition recovered naturally, skip forced recovery.
          if (_speech.isListening) {
            return;
          }

          if (_isAudioPlayingCheck?.call() == true) {
            return;
          }

          _audioFocusGranted = false;
          await _requestAudioFocusPermanent();
          await _hardReset();
        } finally {
          _focusRecoveryInProgress = false;
        }
      });
    });
  }

  /// Returns true if STT should be allowed to auto-restart right now.
  bool _canAutoRestart() {
    if (!_isActive) return false;
    if (_isAudioPlayingCheck?.call() == true) return false;
    return _autoRestartEnabled;
  }
  // ───────────────────────────────────────────────────────────────────

  static const _watchdogInterval = Duration(seconds: 8);
  static const _silenceThreshold = Duration(seconds: 8);

  Stream<String> get wordStream => _wordController.stream;
  Stream<String> get textStream => _textController.stream;
  Stream<MicHealthStatus> get micHealthStream => _micHealthController.stream;

  bool get isListening => _speech.isListening;

  Future<bool> initialize() async {
    if (_disposed) {
      debugPrint('TasmiSpeechService: Cannot initialize after disposal');
      return false;
    }

    try {
      final status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        debugPrint('Microphone permission denied');
        return false;
      }

      final available = await _speech.initialize(
        onStatus: _onStatus,
        onError: _onError,
      );
      return available;
    } catch (e) {
      debugPrint('Speech initialization error: $e');
      return false;
    }
  }

  Future<bool> startListening({bool autoRestart = true}) async {
    if (_disposed) {
      debugPrint('TasmiSpeechService: Cannot start listening after disposal');
      return false;
    }

    if (!_isActive) {
      debugPrint('TasmiSpeechService: startListening ignored while inactive');
      return false;
    }

    if (!_speech.isAvailable) {
      final available = await initialize();
      if (!available) {
        _wordController.addError('خدمة التعرف على الصوت غير متاحة');
        return false;
      }
    }

    _isManuallyStopped = false;
    _isRestarting = false;
    _autoRestartEnabled = autoRestart;
    _restartTimer?.cancel();

    var focusGranted = await _requestAudioFocusPermanent();
    if (!focusGranted) {
      await Future<void>.delayed(const Duration(seconds: 1));
      focusGranted = await _requestAudioFocusPermanent();
    }
    if (!focusGranted) {
      debugPrint('TasmiSpeechService: audio focus not granted');
    }

    await _listenToAudioFocus();
    _startWatchdog();
    final started = await _startInternal();
    if (started && !_micHealthController.isClosed) {
      _micHealthController.add(MicHealthStatus.active);
    } else if (!started && !_micHealthController.isClosed) {
      _micHealthController.add(MicHealthStatus.stalled);
    }
    return started;
  }

  Future<bool> _startInternal() async {
    final inFlight = _engineOpFuture;
    if (inFlight != null) {
      debugPrint('⚠️ startInternal joined — engine op in flight');
      return await inFlight;
    }

    final op = _doStartInternal();
    _engineOpFuture = op;
    try {
      return await op;
    } finally {
      if (identical(_engineOpFuture, op)) {
        _engineOpFuture = null;
      }
    }
  }

  Future<bool> _doStartInternal() async {
    if (!_isActive) {
      return false;
    }

    if (_engineOpInFlight) {
      return false;
    }

    _engineOpInFlight = true;
    try {
      if (_isManuallyStopped || _wordController.isClosed) return false;
      if (_speech.isListening) return true;

      if (!_audioFocusGranted) {
        await _requestAudioFocusPermanent();
      }

      _lastRecognizedWords = '';
      _lastWordReceivedAt = DateTime.now();

      try {
        await _speech.listen(
          onResult: _onResult,
          localeId: 'ar-SA',
          listenMode: stt.ListenMode.dictation,
          listenFor: const Duration(seconds: 20),
          pauseFor: const Duration(seconds: 3),
          cancelOnError: false,
          partialResults: true,
        );
        return true;
      } catch (e) {
        debugPrint('Speech listen error: $e');
        _wordController.addError('تعذر بدء الاستماع. حاول مرة أخرى.');
        return false;
      }
    } finally {
      _engineOpInFlight = false;
    }
  }

  Future<void> stopListening() async {
    _isManuallyStopped = true;
    _isRestarting = false;
    _restartTimer?.cancel();
    _ttsResumeTimer?.cancel();
    _watchdogTimer?.cancel();
    _watchdogTimer = null;
    _focusRecoveryInProgress = false;
    await _speech.stop();
  }

  void notifyTtsCompleted() {
    _isTtsExoPlayerActive = false;
    final completer = _ttsReleaseCompleter ?? Completer<void>();
    _ttsReleaseCompleter = completer;

    unawaited(Future<void>.delayed(const Duration(milliseconds: 600), () {
      if (!_isTtsExoPlayerActive && !completer.isCompleted) {
        completer.complete();
      }
    }));
  }

  Future<void> pauseForTts() async {
    _ttsResumeTimer?.cancel();
    _restartTimer?.cancel();
    _watchdogTimer?.cancel();
    _watchdogTimer = null;
    _isRestarting = false;
    _isPausedForTts = true;
    _isTtsExoPlayerActive = true;
    _ttsReleaseCompleter = Completer<void>();

    if (_speech.isListening) {
      await _speech.stop();
    }

    // Explicitly abandon focus before TTS/next player activity starts.
    try {
      final session = await AudioSession.instance;
      await session.setActive(false);
    } catch (e) {
      debugPrint('AudioSession release before TTS failed: $e');
    }

    debugPrint('STT paused for TTS');
  }

  Future<void> resumeAfterTts() async {
    if (_isManuallyStopped || _wordController.isClosed) return;

    final releaseFuture = _ttsReleaseCompleter?.future;
    if (releaseFuture != null) {
      try {
        await releaseFuture.timeout(const Duration(milliseconds: 1200));
      } catch (_) {
        // Fallback timeout keeps resume path from being stuck forever.
      }
    }
    _ttsReleaseCompleter = null;

    // Final settle window for codec/audio-focus teardown.
    await Future<void>.delayed(const Duration(milliseconds: 800));

    if (_isManuallyStopped || _wordController.isClosed) return;

    var checks = 0;
    while (_isAudioPlayingCheck?.call() == true && checks < 8) {
      await Future<void>.delayed(const Duration(milliseconds: 120));
      if (_isManuallyStopped || _wordController.isClosed) return;
      checks++;
    }

    if (_isAudioPlayingCheck?.call() == true) {
      debugPrint('STT resume deferred — audio player still active');
      _ttsResumeTimer?.cancel();
      _ttsResumeTimer = Timer(const Duration(milliseconds: 700), () {
        if (!_isTtsExoPlayerActive && !_disposed) {
          unawaited(resumeAfterTts());
        }
      });
      return;
    }

    _isPausedForTts = false;
    _lastWordReceivedAt = DateTime.now();

    if (_speech.isListening) {
      _startWatchdog();
      if (!_micHealthController.isClosed) {
        _micHealthController.add(MicHealthStatus.active);
      }
      debugPrint('STT resumed after TTS (already listening)');
      return;
    }

    await _requestAudioFocusPermanent();
    final started = await _startInternal();
    if (started) {
      _startWatchdog();
      if (!_micHealthController.isClosed) {
        _micHealthController.add(MicHealthStatus.active);
      }
    } else if (!_micHealthController.isClosed) {
      _micHealthController.add(MicHealthStatus.stalled);
    }
    debugPrint('STT resumed after TTS');
  }

  void _onResult(SpeechRecognitionResult result) {
    if (_isPausedForTts) {
      return;
    }

    if (_wordController.isClosed) return;

    _lastWordReceivedAt = DateTime.now();

    final currentWords = result.recognizedWords.trim();
    if (currentWords.isEmpty) return;

    if (!_micHealthController.isClosed) {
      _micHealthController.add(MicHealthStatus.active);
    }

    if (!_textController.isClosed) {
      _textController.add(currentWords);
    }

    final firstTrackedToken = _lastRecognizedWords.isNotEmpty
        ? _lastRecognizedWords.split(' ').first
        : '';

    if (currentWords.length < _lastRecognizedWords.length ||
        !currentWords.startsWith(firstTrackedToken)) {
      _lastRecognizedWords = '';
    }

    if (currentWords.length > _lastRecognizedWords.length) {
      final newPart =
          currentWords.substring(_lastRecognizedWords.length).trim();

      if (newPart.isNotEmpty) {
        final newWords =
            newPart.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();

        for (final word in newWords) {
          _wordController.add(word);
        }
      }

      _lastRecognizedWords = currentWords;
    }
  }

  void _onStatus(String status) {
    if (_isPausedForTts) {
      debugPrint('STT Status (suppressed during TTS): $status');
      return;
    }

    debugPrint('STT Status: $status');
    // Only restart on done to avoid duplicate scheduling with notListening.
    if (_canAutoRestart() && status == 'done') {
      if (!_isRestarting && !_isWatchdogHealing) {
        _scheduleRestart();
      }
    }
  }

  void _onError(SpeechRecognitionError error) {
    if (_isPausedForTts) {
      debugPrint('STT Error (suppressed during TTS): ${error.errorMsg}');
      return;
    }

    final errorMsg = error.errorMsg.toLowerCase();
    final isBusy = errorMsg.contains('busy');
    final isNetwork = errorMsg.contains('network');
    if (isBusy || isNetwork) {
      if (!_canAutoRestart()) {
        return;
      }

      _restartTimer?.cancel();
      _isRestarting = true;
      _restartTimer = Timer(
        isBusy ? const Duration(seconds: 3) : const Duration(seconds: 5),
        () async {
          _restartTimer = null;
          if (_isManuallyStopped ||
              _isPausedForTts ||
              _isWatchdogHealing ||
              !_canAutoRestart() ||
              _wordController.isClosed) {
            _isRestarting = false;
            return;
          }

          try {
            await _hardReset();
          } finally {
            _isRestarting = false;
          }
        },
      );
      return;
    }

    if (error.errorMsg != 'error_client' &&
        error.errorMsg != 'error_speech_timeout' &&
        error.errorMsg != 'error_no_match') {
      debugPrint('STT Error: ${error.errorMsg}, permanent: ${error.permanent}');
    }

    if (!_autoRestartEnabled &&
        error.errorMsg == 'error_network' &&
        !_wordController.isClosed) {
      _wordController.addError('يرجى التحقق من الاتصال بالإنترنت');
    }

    if (error.errorMsg == 'error_no_match' && !_wordController.isClosed) {
      _wordController.addError('error_mic_final');
    }

    // FIX 1+3: Check _canAutoRestart() before scheduling restart on errors
    if (!_canAutoRestart()) {
      if (error.permanent &&
          error.errorMsg == 'error_permission' &&
          !_wordController.isClosed) {
        _wordController.addError('يرجى السماح بصلاحية الميكروفون');
      }
      return;
    }

    if (error.errorMsg == 'error_client') {
      _scheduleRestart(delay: const Duration(milliseconds: 1500));
      return;
    }

    if (error.permanent && error.errorMsg == 'error_permission') {
      if (!_wordController.isClosed) {
        _wordController.addError('يرجى السماح بصلاحية الميكروفون');
      }
      return;
    }

    switch (error.errorMsg) {
      case 'error_speech_timeout':
      case 'error_no_match':
        _scheduleRestart(delay: const Duration(milliseconds: 300));
        break;
      case 'error_busy':
        _scheduleRestart(delay: const Duration(milliseconds: 1200));
        break;
      case 'error_network':
        if (!_wordController.isClosed) {
          _wordController.addError('يرجى التحقق من الاتصال بالإنترنت');
        }
        break;
      default:
        _scheduleRestart(delay: const Duration(milliseconds: 1000));
    }
  }

  void _scheduleRestart({Duration delay = const Duration(milliseconds: 800)}) {
    // FIX 1+3: Check all conditions before scheduling restart
    if (_isManuallyStopped ||
        _isPausedForTts ||
        _isRestarting ||
        !_canAutoRestart() ||
        _wordController.isClosed) {
      return;
    }

    _isRestarting = true;
    _restartTimer?.cancel();
    _restartTimer = Timer(delay, () async {
      _isRestarting = false;
      // FIX: Re-evaluate all conditions before calling _startInternal
      if (_isManuallyStopped ||
          _isPausedForTts ||
          !_canAutoRestart() ||
          _wordController.isClosed ||
          _speech.isListening) {
        return;
      }

      if (!_audioFocusGranted) {
        await _requestAudioFocusPermanent();
      }

      await _startInternal();
    });
  }

  void _startWatchdog() {
    _watchdogTimer?.cancel();
    _lastWordReceivedAt = DateTime.now();
    _watchdogTimer = Timer.periodic(
      _watchdogInterval,
      (_) async {
        // Don't await here to prevent blocking the timer, but check guard before starting
        if (!_isWatchdogHealing) {
          unawaited(_checkAndHeal());
        }
      },
    );
  }

  Future<void> _checkAndHeal() async {
    if (_isWatchdogHealing) {
      return;
    }

    // FIX 1+3: Skip watchdog entirely if page is not active or audio is playing
    if (!_isActive) {
      _watchdogTimer?.cancel();
      _watchdogTimer = null;
      return;
    }
    if (_isAudioPlayingCheck?.call() == true) return;
    if (_isManuallyStopped || _isPausedForTts || _wordController.isClosed) {
      return;
    }
    if (!_autoRestartEnabled) return;
    if (_isRestarting) return;

    _isWatchdogHealing = true;

    try {
      final sinceLastWord = _lastWordReceivedAt == null
          ? _silenceThreshold
          : DateTime.now().difference(_lastWordReceivedAt!);

      final isActuallyListening = _speech.isListening;
      final silenceTooLong = sinceLastWord >= _silenceThreshold;

      if (!isActuallyListening || silenceTooLong) {
        debugPrint(
          '🔧 Watchdog: healing STT — '
          'isListening=$isActuallyListening '
          'silence=${sinceLastWord.inSeconds}s',
        );

        if (!_micHealthController.isClosed) {
          _micHealthController.add(MicHealthStatus.reconnecting);
        }

        final healed = await _hardReset();
        if (!_micHealthController.isClosed) {
          _micHealthController.add(
            healed ? MicHealthStatus.active : MicHealthStatus.stalled,
          );
        }
      }
    } finally {
      _isWatchdogHealing = false;
    }
  }

  Future<bool> _hardReset() async {
    _restartTimer?.cancel();
    _restartTimer = null;
    _isRestarting = false;
    _focusRecoveryInProgress = false;
    _engineOpInFlight = false;
    _engineOpFuture = null;

    try {
      // Use cancel() to discard any in-progress recognition results
      // since we're doing a hard reset and don't need to finalize anything
      await _speech.cancel();
      await Future.delayed(const Duration(milliseconds: 1200));
    } catch (e, st) {
      debugPrint('_hardReset cancel error: $e\n$st');
    }

    if (_isActive &&
      !_isManuallyStopped &&
      !_isPausedForTts &&
      !_wordController.isClosed) {
      await _requestAudioFocusPermanent();
      _lastRecognizedWords = '';
      _lastWordReceivedAt = DateTime.now();
      final restarted = await _startInternal();
      if (restarted) {
        debugPrint('🔧 Watchdog: STT restarted');
      }
      return restarted;
    }

    return false;
  }

  Future<void> forceRestart() async {
    debugPrint('🔧 Manual restart requested');
    _lastWordReceivedAt = null;
    if (!_micHealthController.isClosed) {
      _micHealthController.add(MicHealthStatus.reconnecting);
    }
    final restarted = await _hardReset();
    if (!_micHealthController.isClosed) {
      _micHealthController.add(
        restarted ? MicHealthStatus.active : MicHealthStatus.stalled,
      );
    }
  }

  Future<void> dispose() async {
    if (_disposed) {
      return;
    }

    _isActive = false;
    _isManuallyStopped = true;

    _restartTimer?.cancel();
    _ttsResumeTimer?.cancel();
    _watchdogTimer?.cancel();
    _watchdogTimer = null;
    _isWatchdogHealing = false;
    _focusRecoveryInProgress = false;

    await _audioFocusSubscription?.cancel();
    _audioFocusSubscription = null;
    _audioFocusGranted = false;

    try {
      await _speech.cancel();
    } catch (_) {}

    try {
      final session = await AudioSession.instance;
      await session.setActive(false);
    } catch (_) {}

    if (!_wordController.isClosed) {
      _wordController.close();
    }
    if (!_textController.isClosed) {
      _textController.close();
    }
    if (!_micHealthController.isClosed) {
      _micHealthController.close();
    }

    _disposed = true;
    _instance = null;
  }
}
