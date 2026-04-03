import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sila_app/features/quran/presentation/riverpod/audio_controller.dart';
import 'package:sila_app/features/tasmi/services/tasmi_speech_service.dart';

class HifzAudioSessionManager {
  HifzAudioSessionManager(this._ref, this._speechService) {
    // FIX 1: Wire audio playing check from AudioController
    _speechService.setAudioPlayingCheck(() {
      try {
        return _ref.read(audioControllerProvider).playing;
      } catch (_) {
        return false;
      }
    });
  }

  final Ref _ref;
  final TasmiSpeechService _speechService;

  bool _audioActive = false;
  bool _micActive = false;
  bool _switching = false;

  bool get isAudioActive => _audioActive;
  bool get isMicActive => _micActive;
  bool get isSwitching => _switching;

  Future<void> playAudioThenWait({
    required String url,
    required String surahName,
    required int surahNumber,
    required int ayahNumber,
    Duration timeout = const Duration(seconds: 30),
  }) async {
    _switching = true;
    try {
      await ensureMicStopped();
      _audioActive = true;
      final completer = Completer<void>();
      late final StreamSubscription<void> sub;
      sub = _ref
          .read(audioControllerProvider.notifier)
          .onPlayerComplete
          .listen((_) {
        if (!completer.isCompleted) {
          completer.complete();
        }
      });

      try {
        await _ref.read(audioControllerProvider.notifier).playAudio(
              url,
              surahName: surahName,
              surahNumber: surahNumber,
              ayahNumber: ayahNumber,
              useDuckingFocus: true,
            );
        try {
          await completer.future.timeout(timeout);
        } on TimeoutException {
          await stopAudio();
        }
      } finally {
        await stopAudio();
        await sub.cancel();
      }
    } finally {
      _audioActive = false;
      _switching = false;
    }
  }

  Future<void> stopAudio() async {
    await _ref.read(audioControllerProvider.notifier).stopAudio();
    _audioActive = false;
  }

  Future<bool> startMic({bool autoRestart = false}) async {
    if (_switching) {
      var tries = 0;
      while (_switching && tries < 20) {
        await Future<void>.delayed(const Duration(milliseconds: 100));
        tries++;
      }
      if (_switching) {
        debugPrint('⚠️ startMic aborted — transition did not settle in time');
        return false;
      }
    }

    _switching = true;
    try {
      await stopAudio();
      await _waitForAudioRelease();
      var started = await _speechService.startListening(autoRestart: autoRestart);
      if (!started) {
        await Future<void>.delayed(const Duration(milliseconds: 700));
        await stopAudio();
        await _waitForAudioRelease();
        started = await _speechService.startListening(autoRestart: autoRestart);
      }
      _micActive = started;
      return started;
    } finally {
      _switching = false;
    }
  }

  Future<void> stopMic() async {
    if (_switching && !_micActive && !_speechService.isListening) {
      debugPrint(
        '⚠️ stopMic skipped — switching in progress with no active mic/listening state',
      );
      return;
    }

    await _speechService.stopListening();
    _micActive = false;
  }

  Future<void> ensureAudioStopped() async {
    if (_audioActive) {
      await stopAudio();
      await Future<void>.delayed(const Duration(milliseconds: 120));
      return;
    }
    await _ref.read(audioControllerProvider.notifier).stopAudio();
    await Future<void>.delayed(const Duration(milliseconds: 120));
  }

  Future<void> ensureMicStopped() async {
    if (_micActive || _speechService.isListening) {
      await stopMic();
      await Future<void>.delayed(const Duration(milliseconds: 120));
    }
  }

  Future<void> _waitForAudioRelease() async {
    // Give native codec/focus stack enough time to settle after stopAudio.
    await Future<void>.delayed(const Duration(milliseconds: 800));

    var checks = 0;
    while (checks < 8) {
      try {
        final player = _ref.read(audioControllerProvider);
        if (!player.playing) {
          break;
        }
      } catch (_) {
        break;
      }

      await Future<void>.delayed(const Duration(milliseconds: 100));
      checks++;
    }
  }

  Future<void> dispose() async {
    try {
      await ensureMicStopped();
      await ensureAudioStopped();
    } catch (e) {
      debugPrint('HifzAudioSessionManager dispose error: $e');
    }
  }
}
