import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
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
import 'package:sila_app/features/tasmi/services/tasmi_tts_service.dart';
import 'package:sila_app/features/tasmi/services/tasmi_speech_service.dart';
import 'package:sila_app/core/services/sherpa_speech_service.dart';
import 'package:sila_app/core/utils/dialog_utils.dart';
import 'package:flutter/material.dart';
import 'package:sila_app/features/ibadah_tracker/presentation/controllers/ibadah_tracker_controller.dart';
import 'package:sila_app/features/notifications/presentation/controllers/notification_providers.dart';
import 'package:sila_app/features/vefa/presentation/riverpod/vefa_providers.dart';
import 'package:sila_app/features/wird/presentation/riverpod/wird_controller.dart';

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
  late final SherpaSpeechService _sherpaService;
  StreamSubscription<String>? _speechSubscription;
  int? _surahNumber;
  bool _isProcessingWord = false;
  final List<TasmiWordError> _sessionErrors = [];

  @override
  TasmiState build() {
    _speechService = TasmiSpeechService();
    _sherpaService = SherpaSpeechService();
    
    _speechService.setActive(true);
    _speechService.setAudioPlayingCheck(() {
      try {
        return ref.read(audioControllerProvider).playing;
      } catch (_) {
        return false;
      }
    });

    _speechService.initialize().then((available) {
      if (!available) {
        _checkSherpaAvailability();
      }
    });

    ref.onDispose(() {
      _speechSubscription?.cancel();
      _speechService.setActive(false);
      _speechService.dispose();
      _sherpaService.dispose();
    });

    return TasmiState.initial();
  }

  Future<void> startSession({
    required int surahNumber,
    required int fromAya,
    required int toAya,
    BuildContext? context,
  }) async {
    _surahNumber = surahNumber;
    final useSherpa = await _sherpaService.isModelAvailable();
    
    final surahName = quran.getSurahNameArabic(surahNumber);
    await ref.read(analyticsServiceProvider).logTasmiSessionStart(
          surahName: surahName,
        );

    await _stopServicesOnly();
    _isProcessingWord = false;
    _sessionErrors.clear();

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

    final tts = ref.read(tasmiTtsServiceProvider);
    await tts.initialize();

    await _speechSubscription?.cancel();
    
    if (useSherpa) {
      await _sherpaService.init();
      _speechSubscription = _sherpaService.resultStream.listen(
        _onSherpaResult,
        onError: _handleSTTError,
      );
      await _sherpaService.startListening();
      state = state.copyWith(isMicListening: true);
    } else {
      _speechSubscription = _speechService.wordStream.listen(
        _onWordSpoken,
        onError: _handleSTTError,
      );
      final startedListening = await _speechService.startListening();
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
      }
    }
  }

  void _handleSTTError(dynamic error) async {
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
  }

  void _onSherpaResult(String text) {
    if (text.isEmpty) return;
    final lastWord = text.trim().split(' ').last;
    _onWordSpoken(lastWord);
  }

  void _checkSherpaAvailability() async {
    final available = await _sherpaService.isModelAvailable();
    if (!available) {
      state = state.copyWith(
        status: TasmiStatus.error,
        errorMessage: 'خدمة الصوت غير متاحة. يرجى التحقق من الأذونات.',
      );
    }
  }

  Future<void> _onWordSpoken(String spokenWord) async {
    if (_isProcessingWord) return;
    if (state.currentIndex >= state.words.length) return;

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
        HapticFeedback.lightImpact();
        _handleCorrect();
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
          final useSherpa = await _sherpaService.isModelAvailable();
          if (useSherpa) {
            await _sherpaService.stopListening();
          } else {
            await _speechService.pauseForTts();
          }
          
          state = state.copyWith(isMicListening: false);
          await ref.read(tasmiTtsServiceProvider).speakWord(currentEntry.word);
          
          if (useSherpa) {
            await _sherpaService.startListening();
          } else {
            await _speechService.resumeAfterTts();
          }
          state = state.copyWith(isMicListening: true);
        }
        return;
      }

      await _handleError(spokenWord, currentEntry, result, prefs);
    } finally {
      _isProcessingWord = false;
    }
  }

  void _handleCorrect() {
    final updatedWords = List<TasmiWordEntry>.from(state.words);
    updatedWords[state.currentIndex].status = WordEntryStatus.correct;
    state = state.copyWith(
      words: updatedWords,
      currentIndex: state.currentIndex + 1,
      currentWordAttempts: 0,
      clearCorrectionWord: true,
    );

    if (state.currentIndex >= state.words.length) {
      _finish();
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

    final useSherpa = await _sherpaService.isModelAvailable();

    switch (prefs.onErrorBehavior) {
      case OnErrorBehavior.speakAndContinue:
        if (prefs.ttsEnabled) {
          if (useSherpa) await _sherpaService.stopListening();
          else await _speechService.pauseForTts();
          
          state = state.copyWith(isMicListening: false);
          await ref.read(tasmiTtsServiceProvider).speakWord(entry.word);
          
          if (useSherpa) await _sherpaService.startListening();
          else await _speechService.resumeAfterTts();
          
          state = state.copyWith(isMicListening: true);
        }
        await Future.delayed(const Duration(seconds: 1));
        state = state.copyWith(clearCorrectionWord: true);
        break;
        
      case OnErrorBehavior.waitForUser:
        if (useSherpa) await _sherpaService.stopListening();
        else await _speechService.pauseForTts();
        
        if (prefs.ttsEnabled) {
          await ref.read(tasmiTtsServiceProvider).speakWord(entry.word);
        }
        state = state.copyWith(
          status: TasmiStatus.waitingForUser,
          isMicListening: false,
        );
        break;
        
      case OnErrorBehavior.continueOnly:
        await Future.delayed(const Duration(milliseconds: 800));
        state = state.copyWith(clearCorrectionWord: true);
        break;
    }

    if (state.currentIndex >= state.words.length) {
      _finish();
    }
  }

  Future<void> resumeAfterUserPrompt() async {
    if (state.status != TasmiStatus.waitingForUser) return;
    state = state.copyWith(
        status: TasmiStatus.listening, clearCorrectionWord: true);
    
    final useSherpa = await _sherpaService.isModelAvailable();
    if (useSherpa) {
      await _sherpaService.startListening();
    } else {
      await _speechService.resumeAfterTts();
    }
    
    state = state.copyWith(isMicListening: true);

    if (state.currentIndex >= state.words.length) {
      _finish();
    }
  }

  void _saveError(
      String spokenWord, TasmiWordEntry entry, WordMatchResult result) {
    if (_surahNumber == null) return;
    
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

  void stopSession() {
    if (state.status == TasmiStatus.listening || state.status == TasmiStatus.waitingForUser) {
      _finish();
      return;
    }
    unawaited(_stopServicesOnly());
  }

  Future<void> resumeSession() async {
    if (state.status == TasmiStatus.listening) return;

    _isProcessingWord = false;
    final useSherpa = await _sherpaService.isModelAvailable();

    await _speechSubscription?.cancel();
    if (useSherpa) {
      await _sherpaService.init();
      _speechSubscription = _sherpaService.resultStream.listen(
        _onSherpaResult,
        onError: _handleSTTError,
      );
      await _sherpaService.startListening();
    } else {
      _speechSubscription = _speechService.wordStream.listen(
        _onWordSpoken,
        onError: _handleSTTError,
      );
      await _speechService.startListening();
    }

    state = state.copyWith(
      status: TasmiStatus.listening,
      clearCorrectionWord: true,
      clearErrorMessage: true,
      isMicListening: true,
      sessionStartTime: state.sessionStartTime ?? DateTime.now(),
    );
  }

  void _finish() async {
    _isProcessingWord = false;
    
    final useSherpa = await _sherpaService.isModelAvailable();
    if (useSherpa) {
      await _sherpaService.stopListening();
    } else {
      await _speechService.stopListening();
    }
    
    await _speechSubscription?.cancel();
    ref.read(tasmiTtsServiceProvider).stop();

    var correct = 0;
    var close = 0;
    var wrong = 0;
    var skipped = 0;
    var correctTextBuffer = StringBuffer();

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

    try {
      final repository = await ref.read(hifzRepositoryProvider.future);
      if (state.currentIndex <= 0 || state.words.isEmpty) return;

      final hasFinishedNormally = state.currentIndex >= state.words.length;
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
        ..hasanat = hasanat
        ..durationSeconds = duration;

      await repository.saveSession(session);
      _refreshGlobalDashboards();
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
    final useSherpa = await _sherpaService.isModelAvailable();
    if (useSherpa) {
      await _sherpaService.stopListening();
    } else {
      await _speechService.stopListening();
    }
    
    await _speechSubscription?.cancel();
    _speechSubscription = null;
    ref.read(tasmiTtsServiceProvider).stop();
    state = state.copyWith(isMicListening: false);
  }

  void _refreshGlobalDashboards() {
    ref.invalidate(hifzHomeControllerProvider);
    ref.invalidate(ibadahTrackerControllerProvider);
    ref.invalidate(wirdControllerProvider);
    ref.invalidate(streakTrackerProvider);
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
