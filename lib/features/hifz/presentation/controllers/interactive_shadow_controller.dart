import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:quran/quran.dart' as quran;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sila_app/core/providers/reciter_provider.dart';
import 'package:sila_app/core/services/analytics_service.dart';
import 'package:sila_app/features/hifz/data/models/hifz_moment.dart';
import 'package:sila_app/features/hifz/data/models/hifz_session.dart';
import 'package:sila_app/features/hifz/data/models/hifz_settings.dart';
import 'package:sila_app/features/hifz/data/models/hifz_verse_record.dart';
import 'package:sila_app/features/hifz/data/repositories/hifz_repository_provider.dart';
import 'package:sila_app/features/hifz/domain/hasanat_calculator.dart';
import 'package:sila_app/features/hifz/domain/smart_word_matcher.dart';
import 'package:sila_app/features/hifz/domain/spaced_repetition_engine.dart';
import 'package:sila_app/features/hifz/presentation/controllers/hifz_settings_controller.dart';
import 'package:sila_app/features/hifz/services/hifz_audio_session_manager.dart';
import 'package:sila_app/features/quran/presentation/riverpod/audio_controller.dart';
import 'package:sila_app/features/tasmi/domain/tajweed_normalizer.dart';
import 'package:sila_app/features/tasmi/services/tasmi_speech_service.dart';
import 'package:sila_app/features/vefa/presentation/pages/vefa_page.dart';

part 'interactive_shadow_controller.g.dart';

class ShadowWordEntry {
  const ShadowWordEntry({
    required this.word,
    required this.isAyahMarker,
    required this.isHidden,
    required this.revealedCorrectly,
  });
  final String word;
  final bool isAyahMarker;
  final bool isHidden;
  final bool revealedCorrectly;

  ShadowWordEntry copyWith({
    String? word,
    bool? isAyahMarker,
    bool? isHidden,
    bool? revealedCorrectly,
  }) {
    return ShadowWordEntry(
      word: word ?? this.word,
      isAyahMarker: isAyahMarker ?? this.isAyahMarker,
      isHidden: isHidden ?? this.isHidden,
      revealedCorrectly: revealedCorrectly ?? this.revealedCorrectly,
    );
  }
}

class StageResult {
  const StageResult({
    required this.totalWords,
    required this.correctWords,
    required this.wrongWords,
  });
  final int totalWords;
  final int correctWords;
  final int wrongWords;
}

enum RecitationCompletionMode {
  fullVerse,
  missingOnly,
}

class InteractiveShadowState {
  const InteractiveShadowState({
    required this.surahNumber,
    required this.fromVerse,
    required this.toVerse,
    required this.currentVerseIndex,
    required this.currentStage,
    required this.words,
    required this.isPlaying,
    required this.isMicListening,
    required this.sessionHashanat,
    required this.stageResults,
    required this.correctWords,
    required this.wrongWords,
    required this.showMomentPrompt,
    required this.finished,
    required this.accuracy,
    required this.errorMessage,
    required this.reflectionText,
    required this.sessionMoments,
    required this.finishedEarly,
  });

  factory InteractiveShadowState.initial() {
    return const InteractiveShadowState(
      surahNumber: 1,
      fromVerse: 1,
      toVerse: 5,
      currentVerseIndex: 0,
      currentStage: 1,
      words: [],
      isPlaying: false,
      isMicListening: false,
      sessionHashanat: 0,
      stageResults: {},
      correctWords: 0,
      wrongWords: 0,
      showMomentPrompt: false,
      finished: false,
      accuracy: 0,
      errorMessage: null,
      reflectionText: '',
      sessionMoments: [],
      finishedEarly: false,
    );
  }
  final int surahNumber;
  final int fromVerse;
  final int toVerse;
  final int currentVerseIndex;
  final int currentStage;
  final List<ShadowWordEntry> words;
  final bool isPlaying;
  final bool isMicListening;
  final int sessionHashanat;
  final Map<int, StageResult> stageResults;
  final int correctWords;
  final int wrongWords;
  final bool showMomentPrompt;
  final bool finished;
  final double accuracy;
  final String? errorMessage;
  final String reflectionText;
  final List<HifzMoment> sessionMoments;
  final bool finishedEarly;

  InteractiveShadowState copyWith({
    int? surahNumber,
    int? fromVerse,
    int? toVerse,
    int? currentVerseIndex,
    int? currentStage,
    List<ShadowWordEntry>? words,
    bool? isPlaying,
    bool? isMicListening,
    int? sessionHashanat,
    Map<int, StageResult>? stageResults,
    int? correctWords,
    int? wrongWords,
    bool? showMomentPrompt,
    bool? finished,
    double? accuracy,
    String? errorMessage,
    bool clearErrorMessage = false,
    String? reflectionText,
    List<HifzMoment>? sessionMoments,
    bool? finishedEarly,
  }) {
    return InteractiveShadowState(
      surahNumber: surahNumber ?? this.surahNumber,
      fromVerse: fromVerse ?? this.fromVerse,
      toVerse: toVerse ?? this.toVerse,
      currentVerseIndex: currentVerseIndex ?? this.currentVerseIndex,
      currentStage: currentStage ?? this.currentStage,
      words: words ?? this.words,
      isPlaying: isPlaying ?? this.isPlaying,
      isMicListening: isMicListening ?? this.isMicListening,
      sessionHashanat: sessionHashanat ?? this.sessionHashanat,
      stageResults: stageResults ?? this.stageResults,
      correctWords: correctWords ?? this.correctWords,
      wrongWords: wrongWords ?? this.wrongWords,
      showMomentPrompt: showMomentPrompt ?? this.showMomentPrompt,
      finished: finished ?? this.finished,
      accuracy: accuracy ?? this.accuracy,
      errorMessage:
          clearErrorMessage ? null : errorMessage ?? this.errorMessage,
      reflectionText: reflectionText ?? this.reflectionText,
      sessionMoments: sessionMoments ?? this.sessionMoments,
      finishedEarly: finishedEarly ?? this.finishedEarly,
    );
  }
}

@riverpod
class InteractiveShadowController extends _$InteractiveShadowController {
  static const int _maxStages = 5;
  static const Map<int, double> _stageHideRatio = {
    1: 0.0,
    2: 0.0,
    3: 0.20,
    4: 0.60,
    5: 1.00,
  };

  TasmiSpeechService? _speechService;
  StreamSubscription<String>? _speechSubscription;
  HifzAudioSessionManager? _audioSessionManager;
  final List<HifzSession> _sessionRows = [];
  final List<int> _alreadyHidden = [];
  HifzSettings _settings = HifzSettings.defaults();
  int _stageCorrect = 0;
  int _stageWrong = 0;
  DateTime? _stageStartedAt;
  bool _isAdvancing = false;
  bool _isEvaluatingRecitation = false;
  RecitationCompletionMode _completionMode = RecitationCompletionMode.fullVerse;
  final Map<int, bool?> _inlineValidation = {};
  final Map<int, int> _wordAttempts = {};

  void setRecitationCompletionMode(RecitationCompletionMode mode) {
    _completionMode = mode;
  }

  @override
  InteractiveShadowState build() {
    ref.onDispose(() async {
      await _speechSubscription?.cancel();
      await _audioSessionManager?.dispose();
      _speechService?.setActive(false); // FIX 3: Hifz shadow page left
      _speechService?.dispose();
    });
    return InteractiveShadowState.initial();
  }

  Future<void> startSession({
    required int surahNumber,
    required int fromVerse,
    required int toVerse,
  }) async {
    final maxVerse = quran.getVerseCount(surahNumber);
    final safeFrom = fromVerse.clamp(1, maxVerse);
    final safeTo = toVerse.clamp(safeFrom, maxVerse);

    unawaited(
      ref
          .read(analyticsServiceProvider)
          .logHifzSessionStart(
            surahName: quran.getSurahNameArabic(surahNumber),
            method: 'interactive_shadow',
          )
          .catchError((_) {}),
    );

    state = state.copyWith(
      surahNumber: surahNumber,
      fromVerse: safeFrom,
      toVerse: safeTo,
      currentVerseIndex: 0,
      currentStage: 1,
      sessionHashanat: 0,
      stageResults: {},
      correctWords: 0,
      wrongWords: 0,
      showMomentPrompt: false,
      finished: false,
      finishedEarly: false,
      accuracy: 0,
      clearErrorMessage: true,
      sessionMoments: const [],
    );
    debugPrint(
      'InteractiveShadow startSession surah=$surahNumber from=$safeFrom to=$safeTo',
    );

    _sessionRows.clear();
    _alreadyHidden.clear();
    _inlineValidation.clear();
    _wordAttempts.clear();

    final repository = await ref.read(hifzRepositoryProvider.future);
    _settings = await repository.getSettings();
    _settings =
        ref.read(hifzSettingsControllerProvider).valueOrNull ?? _settings;

    await _loadCurrentVerseWords();
    await _runCurrentStage();
  }

  Future<void> nextStageOrVerse() async {
    if (_isAdvancing) return;
    _isAdvancing = true;
    try {
      _captureStageStats();
      if (state.currentStage < _maxStages) {
        state = state.copyWith(currentStage: state.currentStage + 1);
        debugPrint('InteractiveShadow move to stage=${state.currentStage}');
        await _applyHidingForStage();
        await _runCurrentStage();
        return;
      }

      final lastVerseIndex = state.toVerse - state.fromVerse;
      if (state.currentVerseIndex >= lastVerseIndex) {
        await _finishSession();
        return;
      }

      state = state.copyWith(
        currentVerseIndex: state.currentVerseIndex + 1,
        currentStage: 1,
        showMomentPrompt: false,
        reflectionText: '',
        isMicListening: false,
        isPlaying: false,
      );
      _alreadyHidden.clear();
      await _loadCurrentVerseWords();
      await _runCurrentStage();
    } finally {
      _isAdvancing = false;
    }
  }

  Future<void> saveMoment({String? reflection, String? feeling}) async {
    final effectiveReflection = (reflection ?? state.reflectionText).trim();
    final effectiveFeeling = (feeling ?? '').trim();
    final didSave =
        effectiveReflection.isNotEmpty || effectiveFeeling.isNotEmpty;
    if (effectiveReflection.isNotEmpty || effectiveFeeling.isNotEmpty) {
      final repository = await ref.read(hifzRepositoryProvider.future);
      final moment = HifzMoment()
        ..surahIndex = state.surahNumber
        ..verseNumber = state.fromVerse + state.currentVerseIndex
        ..reflection = effectiveReflection
        ..feeling = effectiveFeeling
        ..createdAt = DateTime.now();
      await repository.saveMoment(moment);
      state = state.copyWith(sessionMoments: [...state.sessionMoments, moment]);
    }

    state = state.copyWith(showMomentPrompt: !didSave, reflectionText: '');
  }

  void setReflectionText(String text) {
    state = state.copyWith(reflectionText: text);
  }

  Future<void> skipMoment() async {
    await saveMoment();
  }

  Future<void> saveMomentFromState() async {
    await saveMoment(reflection: state.reflectionText);
    state = state.copyWith(reflectionText: '');
  }

  Future<void> toggleAudio() async {
    if (state.isPlaying) {
      await _ensureAudioSessionManager();
      await _audioSessionManager!.stopAudio();
      state = state.copyWith(isPlaying: false);
      return;
    }
    await _playVerseAudio();
  }

  Future<void> toggleMic() async {
    await _ensureAudioSessionManager();

    if (state.isMicListening) {
      await _stopMic();
      return;
    }
    await _startMicDetailed();
  }

  Future<void> nextStage() async {
    await nextStageOrVerse();
  }

  Future<void> finishEarly() async {
    if (state.finished) return;
    state = state.copyWith(finishedEarly: true);
    await _finishSession();
  }

  void openThawaabDedication(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const VefaPage(isSelectionMode: true)),
    );
  }

  Future<void> onUserRecited(String recitedText) async {
    if (recitedText.trim().isEmpty) {
      state = state.copyWith(errorMessage: 'error_capture_failed'.tr());
      return;
    }

    if (_isEvaluatingRecitation) return;
    _isEvaluatingRecitation = true;
    try {
      final words = List<ShadowWordEntry>.from(state.words);
      final hiddenIndexes = <int>[];
      final hiddenWords = <String>[];

      for (var i = 0; i < words.length; i++) {
        if (!words[i].isHidden || words[i].isAyahMarker) {
          continue;
        }
        hiddenIndexes.add(i);
        hiddenWords.add(words[i].word);
      }

      final match = SmartWordMatcher.matchHiddenWords(
        spokenText: recitedText,
        hiddenWords: hiddenWords,
        mode: _settings.readVerificationMode(),
        ignoreDiacritics: _settings.hideVisibleDiacritics,
        orderedMatch: _completionMode == RecitationCompletionMode.missingOnly,
      );

      var correct = 0;
      var wrong = 0;

      for (var i = 0; i < hiddenIndexes.length; i++) {
        final result = match.wordResults[i];
        final isCorrect = result != HifzWordMatchResult.incorrect;
        if (isCorrect) {
          final idx = hiddenIndexes[i];
          words[idx] =
              words[idx].copyWith(isHidden: false, revealedCorrectly: true);
          correct++;
        } else {
          final wasAbsent = _isWordAbsentFromSpoken(hiddenWords[i], recitedText);
          if (!wasAbsent) {
            // The user spoke it but incorrectly.
            wrong++;
          }
          if (wasAbsent &&
              _completionMode == RecitationCompletionMode.missingOnly) {
            // In missing-only mode, absent hidden words are counted as wrong.
            wrong++;
          }
        }
      }

      _stageCorrect += correct;
      _stageWrong += wrong;
      final verseText = _verseText;
      final hasanat = HasanatCalculator.calculate(verseText);
      state = state.copyWith(
        words: words,
        sessionHashanat: state.sessionHashanat + hasanat,
        correctWords: state.correctWords + correct,
        wrongWords: state.wrongWords + wrong,
        clearErrorMessage: true,
      );

      if (_settings.playCorrectOnError && wrong > 0) {
        await _playVerseAudio();
      }

      await nextStageOrVerse();
    } finally {
      _isEvaluatingRecitation = false;
    }
  }

  bool? inlineWordValidation(int index) => _inlineValidation[index];

  Future<void> onWordTyped(int wordIndex, String typedText) async {
    if (wordIndex < 0 || wordIndex >= state.words.length) {
      return;
    }

    final entry = state.words[wordIndex];
    if (!entry.isHidden || entry.isAyahMarker || entry.revealedCorrectly) {
      return;
    }

    final value = typedText.trim();
    if (value.isEmpty) {
      _inlineValidation[wordIndex] = null;
      _wordAttempts.remove(wordIndex);
      state = state.copyWith(
        words: List<ShadowWordEntry>.from(state.words),
        clearErrorMessage: true,
      );
      return;
    }

    final targetWord = entry.word;
    final isCorrect =
        TajweedNormalizer.compareIgnoringDiacritics(value, targetWord);

    if (isCorrect) {
      final updatedWords = List<ShadowWordEntry>.from(state.words);
      updatedWords[wordIndex] = updatedWords[wordIndex].copyWith(
        isHidden: false,
        revealedCorrectly: true,
      );
      _inlineValidation[wordIndex] = true;
      _wordAttempts.remove(wordIndex);

      // FIX: Add hasanat for each correct typed word
      final wordHasanat = HasanatCalculator.calculate(targetWord);

      state = state.copyWith(
        words: updatedWords,
        correctWords: state.correctWords + 1,
        sessionHashanat: state.sessionHashanat + wordHasanat,
        clearErrorMessage: true,
      );

      _stageCorrect += 1;
      await Future<void>.delayed(const Duration(milliseconds: 300));

      if (state.currentStage >= 3 && !_hasPendingHiddenWords()) {
        await nextStageOrVerse();
      }
      return;
    }

    final targetLength = TajweedNormalizer.stripDiacritics(targetWord).length;
    final typedLength = TajweedNormalizer.stripDiacritics(value).length;

    if (_inlineValidation[wordIndex] == false && typedLength >= targetLength) {
      return;
    }

    if (typedLength >= targetLength) {
      final currentAttempts = (_wordAttempts[wordIndex] ?? 0) + 1;
      _wordAttempts[wordIndex] = currentAttempts;

      final attemptsBeforeHint = _settings.attemptsBeforeHint.clamp(1, 4);
      if (currentAttempts >= attemptsBeforeHint) {
        _inlineValidation[wordIndex] = false;
        _stageWrong += 1;
        final normalizedTarget = TajweedNormalizer.stripDiacritics(targetWord);
        final hint = normalizedTarget.length >= 2
            ? '${normalizedTarget[0]}...${normalizedTarget[normalizedTarget.length - 1]}'
            : normalizedTarget;

        state = state.copyWith(
          wrongWords: state.wrongWords + 1,
          errorMessage: 'error_wrong_hint'.tr(args: [hint]),
        );
        if (_settings.playCorrectOnError) {
          await _playVerseAudio();
        }
      } else {
        final left = attemptsBeforeHint - currentAttempts;
        state = state.copyWith(
            errorMessage:
                'error_try_again_attempts'.tr(args: [left.toString()]));
      }
      return;
    }

    _inlineValidation[wordIndex] = null;
    state = state.copyWith(words: List<ShadowWordEntry>.from(state.words));
  }

  bool _hasPendingHiddenWords() {
    for (final word in state.words) {
      if (word.isAyahMarker) continue;
      if (word.isHidden && !word.revealedCorrectly) {
        return true;
      }
    }
    return false;
  }

  List<int> selectWordsToHide(
    List<String> words,
    double percentage,
    List<int> alreadyHidden,
  ) {
    final target = (words.length * percentage).ceil().clamp(0, words.length);
    final hidden = <int>{...alreadyHidden};
    final particle = <int>[];
    final suffix = <int>[];
    final root = <int>[];

    for (var i = 0; i < words.length; i++) {
      final w = TajweedNormalizer.normalize(words[i]);
      if (w.isEmpty) {
        continue;
      }
      if (_isParticle(w)) {
        particle.add(i);
      } else if (_looksLikeSuffixWord(w)) {
        suffix.add(i);
      } else {
        root.add(i);
      }
    }

    void take(List<int> source) {
      for (final idx in source) {
        if (hidden.length >= target) {
          break;
        }
        hidden.add(idx);
      }
    }

    take(particle);
    take(suffix);
    take(root);

    return hidden.toList()..sort();
  }

  Future<void> _runCurrentStage() async {
    _stageCorrect = 0;
    _stageWrong = 0;
    _stageStartedAt = DateTime.now();

    if (state.currentStage <= 2) {
      final repeats = _settings.listenRepeats.clamp(1, 3);
      for (var i = 0; i < repeats; i++) {
        await _playVerseAudio();
      }
      if (state.currentStage == 2) {
        state = state.copyWith(
          isMicListening: false,
          errorMessage: 'mic_prompt_stage_2'.tr(),
        );
      } else {
        await nextStageOrVerse();
      }
      return;
    }

    // Stages 3-5 are progressive hidden-word stages.
    await _applyHidingForStage();
    state = state.copyWith(
      isMicListening: false,
      isPlaying: false,
      clearErrorMessage: true,
    );
  }

  Future<void> _startMicDetailed() async {
    await _ensureAudioSessionManager();
    state = state.copyWith(clearErrorMessage: true);

    final available = await _speechService!.initialize();
    if (!available) {
      state = state.copyWith(
        isMicListening: false,
        errorMessage: 'error_mic_init'.tr(),
      );
      return;
    }

    await _speechSubscription?.cancel();
    var latestText = '';
    _speechSubscription = _speechService!.textStream.listen((text) {
      if (text.trim().isNotEmpty) {
        latestText = text.trim();
        state = state.copyWith(clearErrorMessage: true);
      }
    });

    final attempts = state.currentStage <= 2 ? 2 : 3;
    final listenPerAttempt = (_settings.hintDelaySeconds + 4).clamp(5, 12);

    for (var attempt = 1; attempt <= attempts; attempt++) {
      final started = await _audioSessionManager!.startMic(autoRestart: true);
      state = state.copyWith(isMicListening: started);
      if (!started) {
        state = state.copyWith(errorMessage: 'تعذر تشغيل الميكروفون الآن');
        return;
      }

      final startedAt = DateTime.now();
      while (
          DateTime.now().difference(startedAt).inSeconds < listenPerAttempt) {
        await Future<void>.delayed(const Duration(milliseconds: 250));
        if (!_speechService!.isListening) {
          break;
        }
      }

      await _stopMic();

      if (latestText.isNotEmpty) {
        await onUserRecited(latestText);
        return;
      }

      if (attempt < attempts) {
        state = state.copyWith(errorMessage: 'error_mic_retry'.tr());
        await Future<void>.delayed(const Duration(milliseconds: 500));
      }
    }

    state = state.copyWith(errorMessage: 'error_mic_final'.tr());
  }

  Future<void> _stopMic() async {
    await _audioSessionManager?.stopMic();
    state = state.copyWith(isMicListening: false);
  }

  Future<void> _playVerseAudio() async {
    await _ensureAudioSessionManager();
    final ayah = state.fromVerse + state.currentVerseIndex;
    final url = ref
        .read(reciterControllerProvider.notifier)
        .buildAyahUrl(state.surahNumber, ayah);
    state = state.copyWith(isPlaying: true);

    try {
      await _audioSessionManager!.playAudioThenWait(
        url: url,
        surahName: quran.getSurahNameArabic(state.surahNumber),
        surahNumber: state.surahNumber,
        ayahNumber: ayah,
      );
    } finally {
      state = state.copyWith(isPlaying: false);
    }
  }

  Future<void> _ensureAudioSessionManager() async {
    _speechService ??= TasmiSpeechService();
    _speechService!.setActive(true); // FIX 3: Hifz shadow page is active
    _audioSessionManager ??= HifzAudioSessionManager(ref, _speechService!);
  }

  Future<void> _loadCurrentVerseWords() async {
    final ayah = state.fromVerse + state.currentVerseIndex;
    String verse;
    try {
      verse = quran.getVerse(state.surahNumber, ayah, verseEndSymbol: false);
    } catch (_) {
      state = state.copyWith(
        words: const [],
        errorMessage: 'تعذر تحميل نص الآية الحالية',
      );
      return;
    }

    final words = verse
        .split(' ')
        .where((w) => w.trim().isNotEmpty)
        .map(
          (w) => ShadowWordEntry(
            word: w,
            isAyahMarker: false,
            isHidden: false,
            revealedCorrectly: false,
          ),
        )
        .toList();

    if (words.isEmpty) {
      state = state.copyWith(
        words: const [],
        errorMessage: 'تعذر تجهيز كلمات الآية الحالية',
      );
      return;
    }

    state = state.copyWith(words: words);
    _inlineValidation.clear();
    _wordAttempts.clear();
    await _applyHidingForStage();
  }

  Future<void> _applyHidingForStage() async {
    final base = List<ShadowWordEntry>.from(state.words);
    final target = _stageHideRatio[state.currentStage] ?? 0.0;

    if (target <= 0) {
      state = state.copyWith(
        words: base
            .map(
              (e) => e.copyWith(
                isHidden: false,
                revealedCorrectly: false,
              ),
            )
            .toList(),
      );
      return;
    }

    final plainWords = base.map((e) => e.word).toList();
    final hidden = selectWordsToHide(plainWords, target, _alreadyHidden);
    if (hidden.isEmpty && base.isNotEmpty) {
      hidden.add(0);
    }

    _alreadyHidden
      ..clear()
      ..addAll(hidden);
    _inlineValidation.clear();
    _wordAttempts.clear();

    final next = <ShadowWordEntry>[];
    for (var i = 0; i < base.length; i++) {
      final prev = base[i];
      next.add(
        prev.copyWith(
          isHidden: hidden.contains(i),
          // Reveal state is per-stage only; reset when advancing stage.
          revealedCorrectly: false,
        ),
      );
    }

    debugPrint(
      'InteractiveShadow stage=${state.currentStage} hidden=${hidden.length}/${base.length} target=${(target * 100).toStringAsFixed(0)}%',
    );

    state = state.copyWith(words: next);
  }

  void _captureStageStats() {
    final updated = Map<int, StageResult>.from(state.stageResults);
    updated[state.currentStage] = StageResult(
      totalWords: state.words.length,
      correctWords: _stageCorrect,
      wrongWords: _stageWrong,
    );
    state = state.copyWith(stageResults: updated);

    final duration =
        DateTime.now().difference(_stageStartedAt ?? DateTime.now());
    if (state.currentStage == 5) {
      final ayah = state.fromVerse + state.currentVerseIndex;
      _sessionRows.add(
        HifzSession()
          ..surahIndex = state.surahNumber
          ..fromVerse = ayah
          ..toVerse = ayah
          ..method = 'interactive_shadow'
          ..date = DateTime.now()
          ..correctWords = _stageCorrect
          ..wrongWords = _stageWrong
          ..durationSeconds = duration.inSeconds,
      );
    }
  }

  Future<void> _finishSession() async {
    final repository = await ref.read(hifzRepositoryProvider.future);
    var totalCorrect = 0;
    var totalWrong = 0;

    for (final session in _sessionRows) {
      totalCorrect += session.correctWords;
      totalWrong += session.wrongWords;
      await repository.saveSession(session);
      final record = await repository.getVerseRecord(
              session.surahIndex, session.fromVerse) ??
          (HifzVerseRecord()
            ..surahIndex = session.surahIndex
            ..verseNumber = session.fromVerse
            ..intervalDays = 1
            ..easinessFactor = 2.5
            ..nextReviewDate = DateTime.now()
            ..lastReviewDate = DateTime.now()
            ..totalSessions = 0
            ..correctSessions = 0
            ..lastMethodUsed = 'interactive_shadow');

      final quality =
          session.wrongWords == 0 ? 5 : (session.wrongWords <= 2 ? 3 : 1);
      final schedule = SpacedRepetitionEngine.calculateNext(
        currentIntervalDays: record.intervalDays,
        easinessFactor: record.easinessFactor,
        quality: quality,
      );

      record
        ..intervalDays = schedule.nextIntervalDays
        ..easinessFactor = schedule.newEasinessFactor
        ..nextReviewDate = schedule.nextReviewDate
        ..lastReviewDate = DateTime.now()
        ..totalSessions = record.totalSessions + 1
        ..correctSessions = record.correctSessions + (quality >= 3 ? 1 : 0)
        ..lastMethodUsed = 'interactive_shadow';

      await repository.saveVerseRecord(record);
    }

    final total = totalCorrect + totalWrong;
    final accuracy = total == 0 ? 0.0 : totalCorrect / total;
    state = state.copyWith(
      finished: true,
      showMomentPrompt: false,
      isMicListening: false,
      isPlaying: false,
      accuracy: accuracy,
    );

    // Save resume point to SharedPreferences
    final lastVerseCompleted = state.fromVerse + state.currentVerseIndex;
    final isAllDone = lastVerseCompleted >= state.toVerse;
    if (!isAllDone) {
      // If finished early, resume from the current verse (it may be incomplete)
      // If finished normally, resume from the next verse
      final resumeVerse =
          state.finishedEarly ? lastVerseCompleted : lastVerseCompleted + 1;
      if (resumeVerse <= state.toVerse) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('hifz_resume_surah', state.surahNumber);
        await prefs.setInt('hifz_resume_from', resumeVerse);
        await prefs.setInt('hifz_resume_to', state.toVerse);
      }
    } else {
      // All verses completed — clear resume point
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('hifz_resume_surah');
      await prefs.remove('hifz_resume_from');
      await prefs.remove('hifz_resume_to');
    }

    unawaited(
      ref
          .read(analyticsServiceProvider)
          .logHifzSessionComplete(
            ayahsCount: _sessionRows.length,
            accuracy: accuracy,
            hasanat: state.sessionHashanat,
          )
          .catchError((_) {}),
    );

    await ref.read(audioControllerProvider.notifier).disposeSession();
  }

  bool _isParticle(String word) {
    const particles = ['ال', 'و', 'ف', 'ب', 'ل', 'من', 'في', 'على'];
    return particles.any((p) => word == p || word.startsWith(p));
  }

  bool _looksLikeSuffixWord(String word) {
    const suffixes = ['ون', 'ين', 'ات', 'ان', 'هم', 'كم', 'نا', 'ه'];
    return suffixes.any(word.endsWith);
  }

  bool _isWordAbsentFromSpoken(String hiddenWord, String spokenText) {
    final normalizedHidden = TajweedNormalizer.normalizeForComparison(
      hiddenWord,
      ignoreDiacritics: _settings.hideVisibleDiacritics,
    );
    final normalizedSpoken = TajweedNormalizer.normalizeForComparison(
      spokenText,
      ignoreDiacritics: _settings.hideVisibleDiacritics,
    );
    return !normalizedSpoken.contains(normalizedHidden);
  }

  String get _verseText {
    final ayah = state.fromVerse + state.currentVerseIndex;
    return quran.getVerse(state.surahNumber, ayah, verseEndSymbol: false);
  }
}
