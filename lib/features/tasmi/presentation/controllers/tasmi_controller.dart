import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:quran/quran.dart' as quran;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:sila_app/core/services/analytics_service.dart';
import 'package:sila_app/features/hifz/data/models/hifz_session.dart';
import 'package:sila_app/features/hifz/data/repositories/hifz_repository_provider.dart';
import 'package:sila_app/features/hifz/domain/hasanat_calculator.dart';
import 'package:sila_app/features/hifz/presentation/controllers/hifz_home_controller.dart';
import 'package:sila_app/features/quran/presentation/riverpod/audio_controller.dart';
import 'package:sila_app/features/tasmi/data/models/tasmi_preferences.dart';
import 'package:sila_app/features/tasmi/data/models/tasmi_session_stats.dart';
import 'package:sila_app/features/tasmi/data/models/tasmi_word_entry.dart';
import 'package:sila_app/features/tasmi/data/models/tasmi_word_error.dart';
import 'package:sila_app/features/tasmi/data/repositories/i_tasmi_error_repository.dart';
import 'package:sila_app/features/tasmi/data/repositories/isar_tasmi_error_repository.dart';
import 'package:sila_app/features/tasmi/domain/tajweed_normalizer.dart';
import 'package:sila_app/features/tasmi/presentation/riverpod/tasmi_preferences_provider.dart';
import 'package:sila_app/features/tasmi/services/tasmi_speech_service.dart';
import 'package:sila_app/features/tasmi/services/tasmi_tts_service.dart';
import 'package:sila_app/features/vefa/presentation/riverpod/vefa_providers.dart';

part 'tasmi_controller.g.dart';

enum TasmiStatus { idle, listening, waitingForUser, finished, error }

class TasmiState extends Equatable {
  const TasmiState({
    required this.status,
    required this.words,
    required this.currentIndex,
    this.correctionWord,
    required this.stats,
    this.errorMessage,
    this.warningMessage,
    required this.isMicListening,
    required this.currentWordAttempts,
    this.sessionStartTime,
  });

  factory TasmiState.initial() {
    return TasmiState(
      status: TasmiStatus.idle,
      words: const [],
      currentIndex: 0,
      stats: TasmiSessionStats.initial(),
      isMicListening: false,
      currentWordAttempts: 0,
      sessionStartTime: null,
    );
  }
  final TasmiStatus status;
  final List<TasmiWordEntry> words;
  final int currentIndex;
  final String? correctionWord;
  final TasmiSessionStats stats;
  final String? errorMessage;
  final String? warningMessage;
  final bool isMicListening;
  final int currentWordAttempts;
  final DateTime? sessionStartTime;

  TasmiState copyWith({
    TasmiStatus? status,
    List<TasmiWordEntry>? words,
    int? currentIndex,
    String? correctionWord,
    bool clearCorrectionWord = false,
    TasmiSessionStats? stats,
    String? errorMessage,
    bool clearErrorMessage = false,
    String? warningMessage,
    bool clearWarningMessage = false,
    bool? isMicListening,
    int? currentWordAttempts,
    DateTime? sessionStartTime,
  }) {
    return TasmiState(
      status: status ?? this.status,
      words: words ?? this.words,
      currentIndex: currentIndex ?? this.currentIndex,
      correctionWord:
          clearCorrectionWord ? null : correctionWord ?? this.correctionWord,
      stats: stats ?? this.stats,
      errorMessage:
          clearErrorMessage ? null : errorMessage ?? this.errorMessage,
      warningMessage:
          clearWarningMessage ? null : warningMessage ?? this.warningMessage,
      isMicListening: isMicListening ?? this.isMicListening,
      currentWordAttempts: currentWordAttempts ?? this.currentWordAttempts,
      sessionStartTime: sessionStartTime ?? this.sessionStartTime,
    );
  }

  @override
  List<Object?> get props => [
        status,
        words,
        currentIndex,
        correctionWord,
        stats,
        errorMessage,
        warningMessage,
        isMicListening,
        currentWordAttempts,
        sessionStartTime,
      ];
}

@riverpod
class TasmiController extends _$TasmiController {
  static const String _errorMicFinal = 'error_mic_final';

  late final TasmiSpeechService _speechService;
  StreamSubscription<String>? _speechSubscription;
  int? _surahNumber;
  bool _isProcessingWord = false;
  bool _isStartingListening = false;
  Future<bool>? _startListeningFuture;
  final List<TasmiWordError> _sessionErrors = [];

  @override
  TasmiState build() {
    _speechService = TasmiSpeechService();
    _speechService
        .setActive(true); // FIX 3: Page is active — enable STT watchdog/restart
    // FIX 1: Wire audio playing check — if audio is playing, STT won't auto-restart
    _speechService.setAudioPlayingCheck(() {
      try {
        return ref.read(audioControllerProvider).playing;
      } catch (_) {
        return false;
      }
    });
    _speechService.initialize().then((available) {
      if (!available) {
        state = state.copyWith(
          status: TasmiStatus.error,
          errorMessage: 'خدمة الصوت غير متاحة. يرجى التحقق من الأذونات.',
        );
      }
    });

    ref.onDispose(() {
      unawaited(_speechService.stopListening());
      unawaited(_speechSubscription?.cancel() ?? Future<void>.value());
      _speechSubscription = null;
      _speechService
          .setActive(false); // FIX 3: Page left — disable STT watchdog/restart
    });

    return TasmiState.initial();
  }

  Future<void> startSession({
    required int surahNumber,
    required int fromAya,
    required int toAya,
  }) async {
    _surahNumber = surahNumber;
    final surahName = quran.getSurahNameArabic(surahNumber);
    await ref.read(analyticsServiceProvider).logTasmiSessionStart(
          surahName: surahName,
        );

    await _stopServicesOnly();
    _isProcessingWord = false;
    _sessionErrors.clear();

    // 1. Load verses
    final allWords = <TasmiWordEntry>[];
    for (var i = fromAya; i <= toAya; i++) {
      final verseText = quran.getVerse(surahNumber, i, verseEndSymbol: false);
      final wordsInVerse = verseText.split(' ');
      for (var word in wordsInVerse) {
        if (word.isNotEmpty) {
          allWords.add(TasmiWordEntry(verseNumber: i, word: word));
        }
      }
    }

    if (allWords.isEmpty) {
      state = state.copyWith(
        status: TasmiStatus.error,
        errorMessage: 'تعذر تحميل الآيات المحددة. يرجى المحاولة مرة أخرى.',
      );
      return;
    }

    state = state.copyWith(
      words: allWords,
      status: TasmiStatus.listening,
      currentIndex: 0,
      clearCorrectionWord: true,
      clearErrorMessage: true,
      stats: TasmiSessionStats.initial(),
      isMicListening: false,
      currentWordAttempts: 0,
      sessionStartTime: DateTime.now(),
    );

    // 4. Start support services
    final tts = ref.read(tasmiTtsServiceProvider);
    await tts.initialize();

    // 5. Listen to wordStream
    await _speechSubscription?.cancel(); // Cancel any previous subscription
    _speechSubscription = _speechService.wordStream.listen(
      _onWordSpoken,
      onError: (error) async {
        final errorString = error.toString();

        if (errorString.contains(_errorMicFinal)) {
          state = state.copyWith(warningMessage: _errorMicFinal);
          return;
        }

        state = state.copyWith(
          status: TasmiStatus.error,
          errorMessage: errorString,
          isMicListening: false,
        );
        await _stopServicesOnly();
      },
    );

    final startedListening = await _safeStartListening();
    if (!startedListening) {
      await _stopServicesOnly();
      state = state.copyWith(
        words: const [],
        status: TasmiStatus.error,
        currentIndex: 0,
        clearCorrectionWord: true,
        errorMessage: 'mic_error'.tr(),
        isMicListening: false,
        currentWordAttempts: 0,
      );
      return;
    }

    state = state.copyWith(isMicListening: true);
  }

  Future<void> _onWordSpoken(String spokenWord) async {
    if (_isProcessingWord) return;
    if (state.currentIndex >= state.words.length) return; // Session finished

    _isProcessingWord = true;
    try {
      final prefs = ref.read(tasmiPreferencesNotifierProvider);

      final currentEntry = state.words[state.currentIndex];
      final result = TajweedNormalizer.compareWord(
        spoken: spokenWord,
        expected: currentEntry.word,
        strictness: prefs.strictness,
      );

      if (result == WordMatchResult.correct) {
        await _handleCorrect();
        return;
      }

      final maxAttempts = switch (prefs.attemptsMode) {
        AttemptsMode.one => 1,
        AttemptsMode.two => 2,
        AttemptsMode.three => 3,
      };

      final newAttempts = state.currentWordAttempts + 1;
      if (newAttempts < maxAttempts) {
        state = state.copyWith(currentWordAttempts: newAttempts);

        if (prefs.ttsEnabled) {
          await _speechService.pauseForTts();
          state = state.copyWith(isMicListening: false);
          await ref.read(tasmiTtsServiceProvider).speakWord(currentEntry.word);
          _speechService.notifyTtsCompleted();
          await _speechService.resumeAfterTts();
          state = state.copyWith(isMicListening: true);
        }
        return;
      }

      await _handleError(spokenWord, currentEntry, result, prefs);
    } finally {
      _isProcessingWord = false;
    }
  }

  Future<void> _handleCorrect() async {
    final updatedWords = List<TasmiWordEntry>.from(state.words);
    updatedWords[state.currentIndex].status = WordEntryStatus.correct;
    state = state.copyWith(
      words: updatedWords,
      currentIndex: state.currentIndex + 1,
      currentWordAttempts: 0,
      clearCorrectionWord: true,
    );

    if (state.currentIndex >= state.words.length) {
      await _finish();
    }
  }

  Future<void> _handleError(
    String spokenWord,
    TasmiWordEntry entry,
    WordMatchResult result,
    TasmiPreferences prefs,
  ) async {
    final updatedWords = List<TasmiWordEntry>.from(state.words);
    updatedWords[state.currentIndex].status =
        result == WordMatchResult.closeError
            ? WordEntryStatus.closeError
            : WordEntryStatus.wrongWord;

    _saveError(spokenWord, entry, result);

    state = state.copyWith(
      words: updatedWords,
      currentIndex: state.currentIndex + 1,
      currentWordAttempts: 0,
      correctionWord: entry.word,
    );

    switch (prefs.onErrorBehavior) {
      case OnErrorBehavior.speakAndContinue:
        if (prefs.ttsEnabled) {
          await _speechService.pauseForTts();
          state = state.copyWith(isMicListening: false);
          await ref.read(tasmiTtsServiceProvider).speakWord(entry.word);
          _speechService.notifyTtsCompleted();
          await _speechService.resumeAfterTts();
          state = state.copyWith(isMicListening: true);
        }
        await Future.delayed(const Duration(seconds: 1));
        state = state.copyWith(clearCorrectionWord: true);
        break;
      case OnErrorBehavior.waitForUser:
        if (prefs.ttsEnabled) {
          await _speechService.pauseForTts();
          state = state.copyWith(isMicListening: false);
          await ref.read(tasmiTtsServiceProvider).speakWord(entry.word);
          _speechService.notifyTtsCompleted();
        } else {
          await _speechService.pauseForTts();
          _speechService.notifyTtsCompleted();
          state = state.copyWith(isMicListening: false);
        }
        state = state.copyWith(status: TasmiStatus.waitingForUser);
        break;
      case OnErrorBehavior.continueOnly:
        await Future.delayed(const Duration(milliseconds: 800));
        state = state.copyWith(clearCorrectionWord: true);
        break;
    }

    if (state.currentIndex >= state.words.length) {
      await _finish();
    }
  }

  Future<void> resumeAfterUserPrompt() async {
    if (state.status != TasmiStatus.waitingForUser) return;
    state = state.copyWith(
        status: TasmiStatus.listening, clearCorrectionWord: true);
    await _speechService.resumeAfterTts();
    state = state.copyWith(isMicListening: true);

    if (state.currentIndex >= state.words.length) {
      await _finish();
    }
  }

  void _saveError(
      String spokenWord, TasmiWordEntry entry, WordMatchResult result) {
    final errorModel = TasmiWordError()
      ..surahIndex = _surahNumber!
      ..verseNumber = entry.verseNumber
      ..correctWord = entry.word
      ..spokenWord = spokenWord
      ..errorTypeIndex = result.index
      ..timestamp = DateTime.now();

    _sessionErrors.add(errorModel);

    final repoAsync = ref.read(tasmiErrorRepositoryProvider);
    repoAsync.whenData((repo) {
      repo.saveError(errorModel);
    });
  }

  Future<void> stopSession() async {
    if (state.status == TasmiStatus.listening) {
      await _finish(); // Also calculate stats if stopped manually
      return;
    }

    await _stopServicesOnly();
  }

  Future<void> resumeSession() async {
    if (state.status == TasmiStatus.listening) return;

    _isProcessingWord = false;

    // Re-establish subscription because it's cancelled in _finish/_stop
    await _speechSubscription?.cancel();
    _speechSubscription = _speechService.wordStream.listen(
      _onWordSpoken,
      onError: (error) async {
        final errorString = error.toString();
        if (errorString.contains(_errorMicFinal)) {
          state = state.copyWith(warningMessage: _errorMicFinal);
          return;
        }
        state = state.copyWith(
          status: TasmiStatus.error,
          errorMessage: errorString,
          isMicListening: false,
        );
        await _stopServicesOnly();
      },
    );

    state = state.copyWith(
      status: TasmiStatus.listening,
      clearCorrectionWord: true,
      clearErrorMessage: true,
      isMicListening: false,
      sessionStartTime: state.sessionStartTime ?? DateTime.now(),
    );

    final startedListening = await _safeStartListening();
    if (!startedListening) {
      state = state.copyWith(
        status: TasmiStatus.error,
        errorMessage: 'mic_error'.tr(),
      );
      return;
    }
    state = state.copyWith(isMicListening: true);
  }

  Future<void> _finish() async {
    _isProcessingWord = false;
    await _speechService.stopListening();
    await _speechSubscription?.cancel();
    await ref.read(tasmiTtsServiceProvider).stop();

    var correct = 0;
    var close = 0;
    var wrong = 0;
    var skipped = 0;
    final correctTextBuffer = StringBuffer();

    for (final entry in state.words) {
      switch (entry.status) {
        case WordEntryStatus.correct:
          correct++;
          correctTextBuffer.write(entry.word);
          correctTextBuffer.write(' ');
          break;
        case WordEntryStatus.closeError:
          close++;
          break;
        case WordEntryStatus.wrongWord:
          wrong++;
          break;
        case WordEntryStatus.skipped:
          skipped++;
          break;
        case WordEntryStatus.hidden:
          break;
      }
    }

    final hasanat = HasanatCalculator.calculate(correctTextBuffer.toString());
    final duration = state.sessionStartTime != null
        ? DateTime.now().difference(state.sessionStartTime!).inSeconds
        : 0;

    state = state.copyWith(
      status: TasmiStatus.finished,
      isMicListening: false,
      stats: TasmiSessionStats(
        correctCount: correct,
        closeErrorCount: close,
        wrongCount: wrong,
        skippedCount: skipped,
        errorList: List<TasmiWordError>.from(_sessionErrors),
        hasanatEarned: hasanat,
      ),
    );

    // Save to Hifz history
    try {
      final repository = await ref.read(hifzRepositoryProvider.future);

      // FIX: Skip saving if nothing was attempted
      if (state.currentIndex <= 0 || state.words.isEmpty) return;

      final hasFinishedNormally = state.currentIndex >= state.words.length;

      // FIX: Use actual last processed verse, not always the range end
      final actualToVerse = hasFinishedNormally
          ? state.words.last.verseNumber
          : state.words[state.currentIndex - 1].verseNumber;

      final session = HifzSession()
        ..surahIndex = _surahNumber ?? 1
        ..fromVerse = state.words.first.verseNumber
        ..toVerse = actualToVerse
        ..method = 'listening'
        ..date = DateTime.now()
        ..correctWords = correct
        ..wrongWords = wrong + close
        ..durationSeconds = duration;

      await repository.saveSession(session);

      // Refresh Hifz dashboard
      ref.invalidate(hifzHomeControllerProvider);
    } catch (e) {
      debugPrint('❌ Error saving tasmi session: $e');
    }

    final total = correct + close + wrong + skipped;
    final accuracy = total == 0 ? 0.0 : correct / total;
    ref.read(analyticsServiceProvider).logTasmiSessionComplete(
          accuracy: accuracy,
          errorsCount: _sessionErrors.length,
        );
  }

  void clearWarning() {
    state = state.copyWith(clearWarningMessage: true);
  }

  Future<void> _stopServicesOnly() async {
    await _speechService.stopListening();
    await _speechSubscription?.cancel();
    _speechSubscription = null;
    await ref.read(tasmiTtsServiceProvider).stop();
    state = state.copyWith(isMicListening: false);
  }

  Future<bool> _safeStartListening() async {
    if (_isStartingListening) {
      final inFlight = _startListeningFuture;
      if (inFlight != null) {
        return await inFlight;
      }
      return false;
    }

    final inFlight = _startListeningFuture;
    if (inFlight != null) {
      debugPrint('⚠️ startListening joined — already in progress');
      return await inFlight;
    }

    _isStartingListening = true;
    final startFuture = _speechService.startListening();
    _startListeningFuture = startFuture;
    try {
      return await startFuture;
    } finally {
      _isStartingListening = false;
      if (identical(_startListeningFuture, startFuture)) {
        _startListeningFuture = null;
      }
    }
  }
}

final tasmiErrorRepositoryProvider =
    FutureProvider<ITasmiErrorRepository>((ref) async {
  try {
    final isar = await ref.watch(isarInstanceProvider.future);
    return IsarTasmiErrorRepository(isar);
  } catch (_) {
    return _NoOpTasmiErrorRepository();
  }
});

// Fallback no-op repository used while Isar is loading
class _NoOpTasmiErrorRepository implements ITasmiErrorRepository {
  @override
  Future<void> saveError(TasmiWordError error) async {}
  @override
  Future<List<TasmiWordError>> getAll() async => [];
  @override
  Future<List<TasmiWordError>> getBySurah(int surahIndex) async => [];
  @override
  Future<void> clearAll() async {}
}
