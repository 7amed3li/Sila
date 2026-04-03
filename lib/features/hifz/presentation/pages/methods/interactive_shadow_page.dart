import 'dart:async';
import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import 'package:quran/quran.dart' as quran;
import 'package:sila_app/core/presentation/widgets/reciter_picker_sheet.dart';
import 'package:sila_app/core/providers/reciter_provider.dart';
import 'package:sila_app/core/services/device_permission_service.dart';
import 'package:sila_app/core/theme/app_theme.dart';
import 'package:sila_app/core/utils/surah_utils.dart';
import 'package:sila_app/features/hifz/data/models/hifz_user_profile.dart';
import 'package:sila_app/features/hifz/data/repositories/hifz_repository_provider.dart';
import 'package:sila_app/features/hifz/presentation/controllers/interactive_shadow_controller.dart';
import 'package:sila_app/features/hifz/presentation/services/hifz_onboarding_check.dart';
import 'package:sila_app/features/quran/domain/entities/quran_settings.dart';
import 'package:sila_app/features/quran/presentation/riverpod/quran_settings_controller.dart';
import 'package:sila_app/features/quran/presentation/utils/quran_ui_utils.dart';
import 'package:sila_app/features/tasmi/domain/tajweed_normalizer.dart';
import 'package:sila_app/features/tasmi/services/tasmi_speech_service.dart';

const Color _successColor = AppTheme.successGreen;
const Color _hasanatGold = AppTheme.goldLight;
const Color _errorColor = Color(0xFFF87171);

class InteractiveShadowPage extends ConsumerStatefulWidget {
  const InteractiveShadowPage({
    super.key,
    required this.surahNumber,
    required this.fromVerse,
    required this.toVerse,
  });
  final int surahNumber;
  final int fromVerse;
  final int toVerse;

  @override
  ConsumerState<InteractiveShadowPage> createState() =>
      _InteractiveShadowPageState();
}

class _InteractiveShadowPageState extends ConsumerState<InteractiveShadowPage>
    with TickerProviderStateMixin {
  final TextEditingController _reflectionController = TextEditingController();
  final Map<int, TextEditingController> _inlineControllers = {};
  final Map<int, FocusNode> _inlineFocusNodes = {};
  late final AnimationController _flashController;
  late final AnimationController _waveController;
  late Future<bool> _showMiuiBatteryBannerFuture;
  bool _isNextBusy = false;
  int _lastInputsStateHash = 0;
  bool _sessionBootstrapped = false;

  @override
  void initState() {
    super.initState();
    _flashController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 200));
    _waveController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1100));
    _waveController.repeat(reverse: true);
    _showMiuiBatteryBannerFuture = _shouldShowMiuiBatteryBanner();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _bootstrapSession();
    });
  }

  Future<void> _bootstrapSession() async {
    if (_sessionBootstrapped || !mounted) {
      return;
    }

    _sessionBootstrapped = true;

    try {
      await HifzOnboardingCheck.checkAndRequest(context);
    } catch (e) {
      debugPrint('HifzOnboardingCheck failed: $e');
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _showMiuiBatteryBannerFuture = _shouldShowMiuiBatteryBanner();
    });

    await _startSessionWithMode();
  }

  Future<bool> _shouldShowMiuiBatteryBanner() async {
    final isMiui = await DevicePermissionService.isMiuiDevice();
    if (!isMiui) {
      return false;
    }
    return !(await DevicePermissionService.isBatteryExempted());
  }

  Widget _buildMiuiBatteryBanner() {
    return FutureBuilder<bool>(
      future: _showMiuiBatteryBannerFuture,
      builder: (context, snapshot) {
        if (snapshot.data != true) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Row(
            children: [
              const Icon(Icons.mic_off, color: Colors.orange, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'الميكروفون يحتاج إذنا إضافيا',
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.orange.shade900,
                  ),
                ),
              ),
              TextButton(
                onPressed: () async {
                  await DevicePermissionService.requestBatteryExemption();
                  if (!mounted) {
                    return;
                  }
                  setState(() {
                    _showMiuiBatteryBannerFuture = _shouldShowMiuiBatteryBanner();
                  });
                },
                child: Text(
                  'تفعيل',
                  style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _startSessionWithMode() async {
    final controller = ref.read(interactiveShadowControllerProvider.notifier);
    RecitationCompletionMode selectedMode = RecitationCompletionMode.fullVerse;
    try {
      selectedMode =
          await _showCompletionModeDialog(context) ?? RecitationCompletionMode.fullVerse;
    } catch (e) {
      debugPrint('Recitation mode dialog failed: $e');
    }

    controller.setRecitationCompletionMode(selectedMode);
    await controller.startSession(
      surahNumber: widget.surahNumber,
      fromVerse: widget.fromVerse,
      toVerse: widget.toVerse,
    );
  }

  Future<RecitationCompletionMode?> _showCompletionModeDialog(
      BuildContext context) {
    return showDialog<RecitationCompletionMode>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        title: Text(
          'recitation_mode_title'.tr(),
          style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.mic_rounded),
              title: Text(
                'recitation_mode_full_verse_title'.tr(),
                style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                'recitation_mode_full_verse_subtitle'.tr(),
                style: GoogleFonts.cairo(fontSize: 12),
              ),
              onTap: () =>
                  Navigator.pop(ctx, RecitationCompletionMode.fullVerse),
            ),
            ListTile(
              leading: const Icon(Icons.edit_note_rounded),
              title: Text(
                'recitation_mode_missing_only_title'.tr(),
                style: GoogleFonts.cairo(fontWeight: FontWeight.w700),
              ),
              subtitle: Text(
                'recitation_mode_missing_only_subtitle'.tr(),
                style: GoogleFonts.cairo(fontSize: 12),
              ),
              onTap: () =>
                  Navigator.pop(ctx, RecitationCompletionMode.missingOnly),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _reflectionController.dispose();
    for (final c in _inlineControllers.values) {
      c.dispose();
    }
    for (final f in _inlineFocusNodes.values) {
      f.dispose();
    }
    _flashController.dispose();
    _waveController.dispose();
    super.dispose();
  }

  void _syncInlineInputs(List<ShadowWordEntry> words) {
    final currentHash = Object.hashAll(
      words.asMap().entries.map(
            (entry) => Object.hash(entry.key, entry.value.word),
          ),
    );
    final verseChanged = currentHash != _lastInputsStateHash;
    _lastInputsStateHash = currentHash;

    final validIndexes = <int>{};
    for (var i = 0; i < words.length; i++) {
      final w = words[i];
      if (!w.isHidden || w.isAyahMarker) {
        continue;
      }
      validIndexes.add(i);
      if (!_inlineControllers.containsKey(i) || verseChanged) {
        _inlineControllers.remove(i)?.dispose();
        _inlineControllers[i] = TextEditingController();
      }
      _inlineFocusNodes.putIfAbsent(i, FocusNode.new);
    }

    final stale = _inlineControllers.keys
        .where((k) => !validIndexes.contains(k))
        .toList();
    for (final key in stale) {
      _inlineControllers.remove(key)?.dispose();
      _inlineFocusNodes.remove(key)?.dispose();
    }
  }

  int? _findNextHiddenIndex(List<ShadowWordEntry> words, int fromIndex) {
    for (var i = fromIndex + 1; i < words.length; i++) {
      final w = words[i];
      if (w.isHidden && !w.isAyahMarker && !w.revealedCorrectly) {
        return i;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(interactiveShadowControllerProvider);
    final controller = ref.read(interactiveShadowControllerProvider.notifier);
    final reciter = ref.watch(reciterControllerProvider).valueOrNull;
    _syncInlineInputs(state.words);

    final settings = ref.watch(quranSettingsControllerProvider).valueOrNull ??
        const QuranSettings(
            fontSize: 26,
            fontFamily: 'Scheherazade New',
            themeMode: QuranThemeMode.sepia);
    final bgColor = QuranUIUtils.getBackgroundColor(settings.themeMode);
    final isDark = settings.themeMode == QuranThemeMode.dark;
    final textColor = QuranUIUtils.getTextColor(settings.themeMode);

    return Directionality(
      textDirection: context.locale.languageCode == 'ar'
          ? ui.TextDirection.rtl
          : ui.TextDirection.ltr,
      child: Scaffold(
        backgroundColor: bgColor,
        body: SafeArea(
          child: Stack(
            children: [
              state.finished
                  ? _SessionResultsView(
                      state: state,
                      onHome: () =>
                          Navigator.popUntil(context, (r) => r.isFirst),
                      onDedicate: () =>
                          controller.openThawaabDedication(context),
                      onRestart: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(
                            builder: (_) => InteractiveShadowPage(
                              surahNumber: state.surahNumber,
                              fromVerse: state.fromVerse,
                              toVerse: state.toVerse,
                            ),
                          ),
                        );
                      },
                      onContinue: () {
                        final resumeVerse =
                            state.fromVerse + state.currentVerseIndex;
                        if (resumeVerse <= state.toVerse) {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (_) => InteractiveShadowPage(
                                surahNumber: state.surahNumber,
                                fromVerse: resumeVerse,
                                toVerse: state.toVerse,
                              ),
                            ),
                          );
                        } else {
                          Navigator.of(context).pop();
                        }
                      },
                    )
                  : Column(
                      children: [
                        _TopHeader(
                          surahName: SurahUtils.getLocalizedSurahName(
                              context, state.surahNumber),
                          stage: state.currentStage,
                          reciterLabel: reciter?.nameArabic.split(' ').last ??
                              'default_reciter_name'.tr(),
                          onReciterTap: () => showReciterPickerSheet(context),
                          onMomentTap: () {
                            final verseIndex =
                                state.fromVerse + state.currentVerseIndex;
                            _showMomentCapture(
                              context,
                              quran.getVerse(
                                state.surahNumber,
                                verseIndex,
                                verseEndSymbol: false,
                              ),
                              SurahUtils.getLocalizedSurahName(
                                  context, state.surahNumber),
                            );
                          },
                        ),
                        _buildMiuiBatteryBanner(),
                        _StageBanner(stage: state.currentStage),
                        Expanded(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 350),
                            transitionBuilder: (child, animation) {
                              return FadeTransition(
                                opacity: animation,
                                child: SlideTransition(
                                  position: Tween<Offset>(
                                    begin: const Offset(0, 0.05),
                                    end: Offset.zero,
                                  ).animate(CurvedAnimation(
                                      parent: animation,
                                      curve: Curves.easeOut)),
                                  child: child,
                                ),
                              );
                            },
                            child: _StageContent(
                              key: ValueKey(state.currentStage * 100 +
                                  state.currentVerseIndex),
                              state: state,
                              flashController: _flashController,
                            ),
                          ),
                        ),
                        if (state.currentStage <= 2)
                          _AudioBar(
                            isPlaying: state.isPlaying,
                            waveController: _waveController,
                            onToggle: controller.toggleAudio,
                            reciterLabel: reciter?.nameArabic.split(' ').last ??
                                'default_reciter_name'.tr(),
                          ),
                        const SizedBox(height: 8),
                        _MicBar(
                          isListening: state.isMicListening,
                          onToggle: controller.toggleMic,
                        ),
                        if (state.errorMessage != null) ...[
                          const SizedBox(height: 8),
                          _InlineStatusMessage(message: state.errorMessage!),
                        ],
                        if (state.currentStage >= 3) ...[
                          const SizedBox(height: 8),
                          const _WritingModeBar(),
                        ],
                        const SizedBox(height: 10),
                        _StatsRow(
                          correct: state.correctWords,
                          wrong: state.wrongWords,
                          hasanat: state.sessionHashanat,
                        ),
                        const SizedBox(height: 10),
                        _InstructionCard(stage: state.currentStage),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _isNextBusy
                                    ? null
                                    : () async {
                                        setState(() => _isNextBusy = true);
                                        try {
                                          await controller.nextStage();
                                        } finally {
                                          if (mounted) {
                                            setState(() => _isNextBusy = false);
                                          }
                                        }
                                      },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                ),
                                child: _isNextBusy
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : Text(
                                        'next'.tr(),
                                        style: GoogleFonts.cairo(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700),
                                      ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () async {
                                  final confirmed = await showDialog<bool>(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      backgroundColor: bgColor,
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                          side: BorderSide(
                                              color:
                                                  textColor.withOpacity(0.1))),
                                      title: Text(
                                        'finish_session_title'.tr(),
                                        style: GoogleFonts.cairo(
                                            color: textColor,
                                            fontWeight: FontWeight.w700),
                                        textAlign: TextAlign.center,
                                      ),
                                      content: Text(
                                        'finish_session_desc'.tr(),
                                        style: GoogleFonts.cairo(
                                            color: textColor.withOpacity(0.7),
                                            fontSize: 13),
                                        textAlign: TextAlign.center,
                                      ),
                                      actionsAlignment:
                                          MainAxisAlignment.center,
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, false),
                                          child: Text('cancel'.tr(),
                                              style: GoogleFonts.cairo(
                                                  color: textColor
                                                      .withOpacity(0.5))),
                                        ),
                                        ElevatedButton(
                                          onPressed: () =>
                                              Navigator.pop(ctx, true),
                                          style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  const Color(0xFFEF4444),
                                              foregroundColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          8))),
                                          child: Text('finish_session_btn'.tr(),
                                              style: GoogleFonts.cairo(
                                                  fontWeight: FontWeight.w700)),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirmed == true && context.mounted) {
                                    await controller.finishEarly();
                                  }
                                },
                                style: OutlinedButton.styleFrom(
                                  side: BorderSide(
                                      color: Colors.red
                                          .withOpacity(isDark ? 0.3 : 0.5),
                                      width: 1.5),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10)),
                                ),
                                child: Text(
                                  'finish_session'.tr(),
                                  style: GoogleFonts.cairo(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.red
                                        .withOpacity(isDark ? 0.7 : 0.8),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const SizedBox(height: 8),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMomentCapture(
    BuildContext context,
    String verseText,
    String surahName,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: _MomentCaptureSheet(
          surahName: surahName,
          verseText: verseText,
          onSave: (feeling, note) async {
            await ref
                .read(interactiveShadowControllerProvider.notifier)
                .saveMoment(reflection: note, feeling: feeling);
            if (ctx.mounted) {
              Navigator.pop(ctx);
            }
          },
        ),
      ),
    );
  }
}

class _TopHeader extends ConsumerWidget {
  const _TopHeader({
    required this.surahName,
    required this.stage,
    required this.reciterLabel,
    required this.onReciterTap,
    required this.onMomentTap,
  });
  final String surahName;
  final int stage;
  final String reciterLabel;
  final VoidCallback onReciterTap;
  final VoidCallback onMomentTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(quranSettingsControllerProvider).valueOrNull ??
        const QuranSettings(
            fontSize: 26,
            fontFamily: 'Scheherazade New',
            themeMode: QuranThemeMode.sepia);

    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        gradient: AppTheme.headerGradient,
        boxShadow: [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'سورة $surahName',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  fontFamily: settings.fontFamily,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  ...List.generate(5, (index) {
                    final current = index + 1;
                    final color = current < stage
                        ? Colors.white
                        : current == stage
                            ? Colors.white.withOpacity(0.6)
                            : Colors.white.withOpacity(0.2);
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      width: 20,
                      height: 4,
                      decoration: BoxDecoration(
                          color: color, borderRadius: BorderRadius.circular(2)),
                    );
                  }),
                ],
              ),
            ],
          ),
          Row(
            children: [
              GestureDetector(
                onTap: onReciterTap,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.mic_rounded,
                          color: Colors.white.withOpacity(0.9), size: 13),
                      const SizedBox(width: 3),
                      Text(
                        reciterLabel,
                        style: GoogleFonts.cairo(
                            fontSize: 10, color: Colors.white.withOpacity(0.9)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: onMomentTap,
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: const Center(
                    child: Text('💎', style: TextStyle(fontSize: 14)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StageBanner extends ConsumerWidget {
  const _StageBanner({required this.stage});
  final int stage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(quranSettingsControllerProvider).valueOrNull ??
        const QuranSettings(
            fontSize: 26,
            fontFamily: 'Scheherazade New',
            themeMode: QuranThemeMode.sepia);
    final isDark = settings.themeMode == QuranThemeMode.dark;
    final accentColor = QuranUIUtils.getAccentColor(settings.themeMode);
    final bgColor =
        isDark ? const Color(0xFF1E293B) : accentColor.withOpacity(0.12);
    final textColor = isDark ? accentColor : accentColor;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accentColor.withOpacity(0.2), width: 0.5),
      ),
      child: Center(
        child: Text(
          _stageName(stage),
          style: GoogleFonts.cairo(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: textColor,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  String _stageName(int stage) {
    return switch (stage) {
      1 => 'stage_1_title'.tr(),
      2 => 'stage_2_title'.tr(),
      3 => 'stage_3_title'.tr(),
      4 => 'stage_4_title'.tr(),
      5 => 'stage_5_title'.tr(),
      _ => 'stage_generic'.tr(),
    };
  }
}

class _StageContent extends ConsumerWidget {
  const _StageContent(
      {super.key, required this.state, required this.flashController});
  final InteractiveShadowState state;
  final AnimationController flashController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageState =
        context.findAncestorStateOfType<_InteractiveShadowPageState>();
    final controller = ref.read(interactiveShadowControllerProvider.notifier);
    final settings = ref.watch(quranSettingsControllerProvider).valueOrNull ??
        const QuranSettings(
            fontSize: 26,
            fontFamily: 'Scheherazade New',
            themeMode: QuranThemeMode.sepia);
    final textColor = QuranUIUtils.getTextColor(settings.themeMode);

    final fallbackAyah = state.fromVerse + state.currentVerseIndex;
    final fallbackVerse = quran.getVerse(
      state.surahNumber,
      fallbackAyah,
      verseEndSymbol: false,
    );

    final color = ColorTween(
      begin: Colors.transparent,
      end: _errorColor.withValues(alpha: 0.2),
    ).animate(flashController);

    return AnimatedBuilder(
      animation: flashController,
      builder: (_, __) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: color.value,
          child: state.words.isEmpty
              ? Directionality(
                  textDirection: ui.TextDirection.rtl,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: textColor.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      fallbackVerse,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        color: textColor,
                        height: 1.6,
                        fontFamily: settings.fontFamily,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                )
              : Directionality(
                  textDirection: ui.TextDirection.rtl,
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: state.words.asMap().entries.map((entry) {
                final index = entry.key;
                final word = entry.value;

                if (!word.isHidden ||
                    word.isAyahMarker ||
                    pageState == null) {
                  return _WordChip(entry: word);
                }

                final textController = pageState._inlineControllers[index]!;
                final focusNode = pageState._inlineFocusNodes[index]!;
                final validation = controller.inlineWordValidation(index);

                return _InlineWordInput(
                  index: index,
                  hiddenWord: word.word,
                  controller: textController,
                  focusNode: focusNode,
                  isCorrect: word.revealedCorrectly ? true : validation,
                  onChanged: (value) async {
                    await controller.onWordTyped(index, value);
                    final updated =
                        pageState.ref.read(interactiveShadowControllerProvider);
                    final nextIndex =
                        pageState._findNextHiddenIndex(updated.words, index);
                    if (nextIndex != null &&
                        controller.inlineWordValidation(index) == true &&
                        pageState._inlineFocusNodes[nextIndex] != null) {
                      pageState._inlineFocusNodes[nextIndex]!.requestFocus();
                    }
                  },
                );
              }).toList(),
            ),
                ),
        );
      },
    );
  }
}

class _WordChip extends ConsumerWidget {
  const _WordChip({required this.entry});
  final ShadowWordEntry entry;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(quranSettingsControllerProvider).valueOrNull ??
        const QuranSettings(
            fontSize: 26,
            fontFamily: 'Scheherazade New',
            themeMode: QuranThemeMode.sepia);
    final accentColor = QuranUIUtils.getAccentColor(settings.themeMode);
    final textColor = QuranUIUtils.getTextColor(settings.themeMode);

    if (entry.isAyahMarker) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: accentColor.withOpacity(0.12),
          shape: BoxShape.circle,
        ),
        child: Text(
          entry.word,
          style: TextStyle(
              fontSize: 16,
              color: accentColor,
              fontFamily: settings.fontFamily,
              fontWeight: FontWeight.bold),
        ),
      );
    }

    if (!entry.isHidden) {
      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: textColor.withOpacity(0.04),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          entry.word,
          style: TextStyle(
              fontSize: 22,
              color: textColor,
              height: 1.4,
              fontFamily: settings.fontFamily,
              fontWeight: FontWeight.w500),
        ),
      );
    }

    if (entry.revealedCorrectly) {
      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xFF10B981).withOpacity(0.15),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: const Color(0xFF10B981).withOpacity(0.4), width: 0.5),
        ),
        child: Text(
          entry.word,
          style: TextStyle(
              fontSize: 22,
              color: const Color(0xFF10B981),
              height: 1.4,
              fontFamily: settings.fontFamily,
              fontWeight: FontWeight.bold),
        ),
      );
    }

    final dashCount = (entry.word.length / 2).ceil().clamp(2, 6);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: textColor.withOpacity(0.03),
        borderRadius: BorderRadius.circular(8),
        border: Border(
            bottom: BorderSide(color: textColor.withOpacity(0.2), width: 1.5)),
      ),
      child: Text(
        '—' * dashCount,
        style: TextStyle(
            fontSize: 16, color: textColor.withOpacity(0.2), letterSpacing: 4),
      ),
    );
  }
}

class _AudioBar extends ConsumerWidget {
  const _AudioBar({
    required this.isPlaying,
    required this.waveController,
    required this.onToggle,
    required this.reciterLabel,
  });
  final bool isPlaying;
  final AnimationController waveController;
  final Future<void> Function() onToggle;
  final String reciterLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(quranSettingsControllerProvider).valueOrNull ??
        const QuranSettings(
            fontSize: 26,
            fontFamily: 'Scheherazade New',
            themeMode: QuranThemeMode.sepia);
    final isDark = settings.themeMode == QuranThemeMode.dark;
    final accentColor = QuranUIUtils.getAccentColor(settings.themeMode);
    final textColor = QuranUIUtils.getTextColor(settings.themeMode);
    final containerColor =
        isDark ? const Color(0xFF1E293B) : textColor.withOpacity(0.05);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accentColor.withOpacity(0.1), width: 0.5),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onToggle,
            child: Container(
              width: 40,
              height: 40,
              decoration:
                  BoxDecoration(color: accentColor, shape: BoxShape.circle),
              child: Icon(
                isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: _AudioWaveform(
                  isPlaying: isPlaying, controller: waveController)),
          const SizedBox(width: 8),
          Text(reciterLabel,
              style: GoogleFonts.cairo(
                  fontSize: 10,
                  color: textColor.withOpacity(0.6),
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _InlineWordInput extends ConsumerWidget {
  const _InlineWordInput({
    required this.index,
    required this.hiddenWord,
    required this.controller,
    required this.focusNode,
    required this.isCorrect,
    required this.onChanged,
  });

  final int index;
  final String hiddenWord;
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool? isCorrect;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(quranSettingsControllerProvider).valueOrNull ??
        const QuranSettings(
            fontSize: 26,
            fontFamily: 'Scheherazade New',
            themeMode: QuranThemeMode.sepia);
    final isDark = settings.themeMode == QuranThemeMode.dark;
    final textColor = QuranUIUtils.getTextColor(settings.themeMode);

    final wordLength = TajweedNormalizer.stripDiacritics(hiddenWord).length;
    final boxWidth = (wordLength * 20.0).clamp(70.0, 200.0);

    Color borderColor;
    Color bgColor;

    if (isCorrect == null) {
      borderColor = textColor.withOpacity(0.2);
      bgColor = textColor.withOpacity(0.04);
    } else if (isCorrect == true) {
      borderColor = const Color(0xFF10B981);
      bgColor = const Color(0xFF10B981).withOpacity(0.12);
    } else {
      borderColor = const Color(0xFFEF4444);
      bgColor = const Color(0xFFEF4444).withOpacity(0.12);
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: boxWidth,
      height: 48,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: isCorrect == true
          ? Center(
              child: Text(
                hiddenWord,
                style: TextStyle(
                  fontSize: 22,
                  color: const Color(0xFF10B981),
                  fontWeight: FontWeight.bold,
                  fontFamily: settings.fontFamily,
                ),
              ),
            )
          : TextField(
              controller: controller,
              focusNode: focusNode,
              textDirection: ui.TextDirection.rtl,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 22,
                  color: textColor,
                  fontFamily: settings.fontFamily,
                  fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                hintText: '...',
                hintStyle:
                    TextStyle(color: textColor.withOpacity(0.2), fontSize: 18),
              ),
              onChanged: onChanged,
              textInputAction: TextInputAction.next,
            ),
    );
  }
}

class _AudioWaveform extends ConsumerWidget {
  const _AudioWaveform({required this.isPlaying, required this.controller});
  final bool isPlaying;
  final AnimationController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(quranSettingsControllerProvider).valueOrNull ??
        const QuranSettings(
            fontSize: 26,
            fontFamily: 'Scheherazade New',
            themeMode: QuranThemeMode.sepia);
    final textColor = QuranUIUtils.getTextColor(settings.themeMode);
    const heights = [4, 8, 14, 10, 18, 12, 20, 16, 22, 14, 10, 18, 12, 8, 6];

    return AnimatedBuilder(
      animation: controller,
      builder: (_, __) {
        return Row(
          children: List.generate(heights.length, (i) {
            final base = heights[i].toDouble();
            final amp = isPlaying
                ? (0.4 + (0.6 * ((controller.value + (i * 0.06)) % 1.0)))
                : 0.4;
            final h = base * amp;
            final active = i >= 3 && i <= 10;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 1.2),
              child: Container(
                width: 2.8,
                height: h,
                decoration: BoxDecoration(
                  color: active
                      ? AppTheme.accentColor
                      : textColor.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

class _WritingModeBar extends ConsumerWidget {
  const _WritingModeBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(quranSettingsControllerProvider).valueOrNull ??
        const QuranSettings(
            fontSize: 26,
            fontFamily: 'Scheherazade New',
            themeMode: QuranThemeMode.sepia);
    final textColor = QuranUIUtils.getTextColor(settings.themeMode);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: textColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: textColor.withValues(alpha: 0.08), width: 0.5),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: textColor.withValues(alpha: 0.07),
              shape: BoxShape.circle,
              border: Border.all(color: textColor.withOpacity(0.2), width: 1.5),
            ),
            child: Icon(Icons.edit_note_rounded,
                color: textColor.withOpacity(0.7), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'writing_mode_active'.tr(),
                  style: GoogleFonts.cairo(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF6EE7B7),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'writing_mode_hint'.tr(),
                  style: GoogleFonts.cairo(
                      fontSize: 10, color: textColor.withOpacity(0.5)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineStatusMessage extends ConsumerWidget {
  const _InlineStatusMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(quranSettingsControllerProvider).valueOrNull ??
        const QuranSettings(
            fontSize: 26,
            fontFamily: 'Scheherazade New',
            themeMode: QuranThemeMode.sepia);
    final isDark = settings.themeMode == QuranThemeMode.dark;

    final isError = message.contains('تعذر') ||
        message.contains('لم يتم') ||
        message.contains('غير صحيحة') ||
        message.contains('حاول');

    final bgColor = isError
        ? const Color(0xFF7F1D1D).withValues(alpha: isDark ? 0.4 : 0.2)
        : QuranUIUtils.getAccentColor(settings.themeMode)
            .withOpacity(isDark ? 0.3 : 0.1);
    final borderColor = isError
        ? const Color(0xFFEF4444).withValues(alpha: 0.45)
        : QuranUIUtils.getAccentColor(settings.themeMode).withOpacity(0.4);
    final textColor = isError
        ? (isDark ? const Color(0xFFFECACA) : const Color(0xFFB91C1C))
        : QuranUIUtils.getAccentColor(settings.themeMode);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor, width: 0.6),
        ),
        child: Text(
          message,
          style: GoogleFonts.cairo(
              fontSize: 11, color: textColor, fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _MicBar extends ConsumerWidget {
  const _MicBar({required this.isListening, required this.onToggle});
  final bool isListening;
  final Future<void> Function() onToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(quranSettingsControllerProvider).valueOrNull ??
        const QuranSettings(
            fontSize: 26,
            fontFamily: 'Scheherazade New',
            themeMode: QuranThemeMode.sepia);
    final isDark = settings.themeMode == QuranThemeMode.dark;
    final accentColor = QuranUIUtils.getAccentColor(settings.themeMode);

    final containerColor = isDark
        ? const Color(0xFF1E293B)
        : QuranUIUtils.getTextColor(settings.themeMode).withOpacity(0.05);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: accentColor.withValues(alpha: 0.15), width: 0.6),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: onToggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: isListening
                    ? const Color(0xFF10B981).withValues(alpha: 0.2)
                    : accentColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(
                    color: isListening
                        ? const Color(0xFF10B981)
                        : accentColor.withOpacity(0.3),
                    width: 1.5),
              ),
              child: Icon(
                  isListening ? Icons.graphic_eq_rounded : Icons.mic_rounded,
                  color: isListening ? const Color(0xFF10B981) : accentColor,
                  size: 20),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: StreamBuilder<MicHealthStatus>(
              stream: TasmiSpeechService().micHealthStream,
              initialData: MicHealthStatus.active,
              builder: (context, snapshot) {
                final textColor = QuranUIUtils.getTextColor(settings.themeMode);
                final status = isListening
                    ? (snapshot.data ?? MicHealthStatus.active)
                    : null;
                final statusColor = switch (status) {
                  null => textColor.withOpacity(0.6),
                  MicHealthStatus.active => const Color(0xFF1D9E75),
                  MicHealthStatus.reconnecting => Colors.orange,
                  MicHealthStatus.stalled => Colors.red,
                };
                final statusText = switch (status) {
                  null => 'mic_test_hint'.tr(),
                  MicHealthStatus.active => 'listening_status'.tr(),
                  MicHealthStatus.reconnecting => 'reconnecting_status'.tr(),
                  MicHealthStatus.stalled => 'stalled_status'.tr(),
                };

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: statusColor,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          statusText,
                          style: GoogleFonts.cairo(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: statusColor,
                          ),
                        ),
                        if (status == MicHealthStatus.stalled)
                          IconButton(
                            icon: const Icon(Icons.refresh, size: 16),
                            onPressed: () =>
                                TasmiSpeechService().forceRestart(),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isListening
                          ? 'speak_clearly'.tr()
                          : 'tap_to_start_mic'.tr(),
                      style: GoogleFonts.cairo(
                          fontSize: 9.5, color: textColor.withOpacity(0.4)),
                    ),
                    const SizedBox(height: 5),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: isListening ? null : 0,
                        backgroundColor: textColor.withValues(alpha: 0.1),
                        valueColor: AlwaysStoppedAnimation(
                          isListening
                              ? const Color(0xFF6EE7B7)
                              : textColor.withValues(alpha: 0.25),
                        ),
                        minHeight: 3,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow(
      {required this.correct, required this.wrong, required this.hasanat});
  final int correct;
  final int wrong;
  final int hasanat;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          _StatChip(
              value: _toArabicIndic(context, correct),
              label: 'correct_label'.tr(),
              valueColor: _successColor),
          const SizedBox(width: 8),
          _StatChip(
              value: _toArabicIndic(context, wrong),
              label: 'wrong_label'.tr(),
              valueColor: _errorColor),
          const SizedBox(width: 8),
          _StatChip(
              value: _toArabicIndic(context, hasanat),
              label: 'hasanah_label'.tr(),
              valueColor: _hasanatGold),
        ],
      ),
    );
  }
}

class _StatChip extends ConsumerWidget {
  const _StatChip(
      {required this.value, required this.label, required this.valueColor});
  final String value;
  final String label;
  final Color valueColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(quranSettingsControllerProvider).valueOrNull ??
        const QuranSettings(
            fontSize: 26,
            fontFamily: 'Scheherazade New',
            themeMode: QuranThemeMode.sepia);
    final textColor = QuranUIUtils.getTextColor(settings.themeMode);

    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: textColor.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(value,
                style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: valueColor)),
            Text(label,
                style: GoogleFonts.cairo(
                    fontSize: 10, color: textColor.withOpacity(0.5))),
          ],
        ),
      ),
    );
  }
}

class _InstructionCard extends ConsumerWidget {
  const _InstructionCard({required this.stage});
  final int stage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(quranSettingsControllerProvider).valueOrNull ??
        const QuranSettings(
            fontSize: 26,
            fontFamily: 'Scheherazade New',
            themeMode: QuranThemeMode.sepia);
    final accentColor = QuranUIUtils.getAccentColor(settings.themeMode);

    final pair = _instruction(stage);
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accentColor.withOpacity(0.08),
        border: Border.all(color: accentColor.withOpacity(0.25), width: 0.5),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(pair.$1,
              style: GoogleFonts.cairo(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: accentColor)),
          const SizedBox(height: 4),
          Text(pair.$2,
              style: GoogleFonts.cairo(
                  fontSize: 11,
                  color: QuranUIUtils.getTextColor(settings.themeMode)
                      .withOpacity(0.6),
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  (String, String) _instruction(int stage) {
    return switch (stage) {
      1 => ('stage_1_instr_title'.tr(), 'stage_1_instr_sub'.tr()),
      2 => ('stage_2_instr_title'.tr(), 'stage_2_instr_sub'.tr()),
      3 => ('stage_3_instr_title'.tr(), 'stage_3_instr_sub'.tr()),
      4 => ('stage_4_instr_title'.tr(), 'stage_4_instr_sub'.tr()),
      5 => ('stage_5_instr_title'.tr(), 'stage_5_instr_sub'.tr()),
      _ => ('stage_generic'.tr(), ''),
    };
  }
}

class _SessionResultsView extends ConsumerStatefulWidget {
  const _SessionResultsView({
    required this.state,
    required this.onHome,
    required this.onDedicate,
    required this.onRestart,
    required this.onContinue,
  });
  final InteractiveShadowState state;
  final VoidCallback onHome;
  final VoidCallback onDedicate;
  final VoidCallback onRestart;
  final VoidCallback onContinue;

  @override
  ConsumerState<_SessionResultsView> createState() =>
      _SessionResultsViewState();
}

class _SessionResultsViewState extends ConsumerState<_SessionResultsView> {
  late final Future<HifzUserProfile?> _profileFuture;
  late final Future<List<_ReviewAyahItem>> _reviewItemsFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = _loadProfile();
    _reviewItemsFuture = _loadReviewItems();
  }

  Future<HifzUserProfile?> _loadProfile() async {
    final repo = await ref.read(hifzRepositoryProvider.future);
    return repo.getProfile();
  }

  Future<List<_ReviewAyahItem>> _loadReviewItems() async {
    if (widget.state.wrongWords <= 0) {
      return const [];
    }

    final repo = await ref.read(hifzRepositoryProvider.future);
    final surah = widget.state.surahNumber;
    final from = widget.state.fromVerse;
    final to = widget.state.toVerse;

    final items = <_ReviewAyahItem>[];

    // Fetch all verse records in parallel for better performance
    final futures = [
      for (var ayah = from; ayah <= to; ayah++)
        repo
            .getVerseRecord(surah, ayah)
            .then((record) => (ayah: ayah, record: record))
    ];

    final results = await Future.wait(futures);

    for (final result in results) {
      final ayah = result.ayah;
      final record = result.record;

      final needsReview = record != null &&
          (record.intervalDays <= 1 ||
              record.correctSessions < record.totalSessions);
      if (!needsReview) {
        continue;
      }

      final verse = quran.getVerse(surah, ayah, verseEndSymbol: false);
      final snippet = verse.split(' ').take(3).join(' ');
      items.add(
        _ReviewAyahItem(
          ayahNumber: ayah,
          displayText: snippet,
          severe: record.correctSessions < record.totalSessions,
        ),
      );
    }

    if (items.isNotEmpty) {
      return items;
    }

    // Fallback: session has errors but no per-ayah error metadata persisted.
    final fallback = <_ReviewAyahItem>[];
    final totalAyahs = (to - from + 1).clamp(1, 10);
    for (var i = 0; i < totalAyahs; i++) {
      final ayah = from + i;
      final verse = quran.getVerse(surah, ayah, verseEndSymbol: false);
      fallback.add(
        _ReviewAyahItem(
          ayahNumber: ayah,
          displayText: verse.split(' ').take(3).join(' '),
          severe: true,
        ),
      );
    }
    return fallback;
  }

  String _ageMessage(int? ageGroup) {
    return switch (ageGroup) {
      0 => 'age_msg_0'.tr(),
      1 => 'age_msg_1'.tr(),
      2 => 'age_msg_2'.tr(),
      3 => 'age_msg_3'.tr(),
      _ => 'age_msg_2'.tr(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final onSurfaceMuted = colors.onSurface.withValues(alpha: 0.65);
    final totalWords = widget.state.correctWords + widget.state.wrongWords;
    final accuracyValue =
        totalWords == 0 ? 0.0 : widget.state.correctWords / totalWords;
    final accuracyPercent = (accuracyValue * 100).round();

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
          16, 16, 16, 20 + MediaQuery.of(context).padding.bottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppTheme.primaryColor.withValues(
                      alpha: theme.brightness == Brightness.dark ? 0.24 : 0.08),
                  Colors.transparent,
                ],
              ),
            ),
            child: Center(
              child: CircularPercentIndicator(
                radius: 60,
                lineWidth: 10,
                percent: accuracyValue.clamp(0.0, 1.0),
                animation: true,
                animateFromLastPercent: true,
                circularStrokeCap: CircularStrokeCap.round,
                progressColor: QuranUIUtils.getAccentColor(ref
                        .watch(quranSettingsControllerProvider)
                        .valueOrNull
                        ?.themeMode ??
                    QuranThemeMode.sepia),
                backgroundColor: colors.onSurface.withValues(alpha: 0.15),
                center: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${_toArabicIndic(context, accuracyPercent)}٪',
                      style: GoogleFonts.cairo(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: colors.onSurface,
                      ),
                    ),
                    Text(
                      'memorization_accuracy'.tr(),
                      style: GoogleFonts.cairo(
                        fontSize: 11,
                        color: onSurfaceMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _ResultsStatCard(
                  value: _toArabicIndic(context, widget.state.correctWords),
                  label: 'correct_long'.tr(),
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ResultsStatCard(
                  value: _toArabicIndic(context, widget.state.wrongWords),
                  label: 'wrong_long'.tr(),
                  color: colors.error,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          FutureBuilder<HifzUserProfile?>(
            future: _profileFuture,
            builder: (context, snapshot) {
              final message = _ageMessage(snapshot.data?.ageGroup);
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: const Border(
                    left: BorderSide(color: AppTheme.accentColor, width: 4),
                  ),
                ),
                child: Text(
                  message,
                  style: GoogleFonts.cairo(
                    fontSize: 15,
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
            },
          ),
          if (widget.state.wrongWords > 0) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                const Icon(Icons.bookmark_added_rounded,
                    color: AppTheme.primaryColor, size: 18),
                const SizedBox(width: 6),
                Text(
                  'words_needing_review'.tr(),
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            FutureBuilder<List<_ReviewAyahItem>>(
              future: _reviewItemsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 18),
                    child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2)),
                  );
                }

                final items = snapshot.data ?? const <_ReviewAyahItem>[];
                final shown = items.take(10).toList();
                final hiddenCount = (items.length - shown.length).clamp(0, 999);

                if (shown.isEmpty) {
                  return Text(
                    'no_review_items'.tr(),
                    style:
                        GoogleFonts.cairo(fontSize: 12, color: onSurfaceMuted),
                  );
                }

                return Column(
                  children: [
                    ...shown.asMap().entries.map((entry) {
                      final index = entry.key;
                      final item = entry.value;
                      return Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colors.surface,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(
                                  item.severe
                                      ? Icons.cancel_rounded
                                      : Icons.warning_amber_rounded,
                                  color:
                                      item.severe ? colors.error : Colors.amber,
                                  size: 18,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    item.displayText,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.amiri(
                                      fontSize: 20,
                                      color: item.severe
                                          ? colors.error
                                          : colors.onSurface,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  '${'surah_label'.tr()} ${SurahUtils.getLocalizedSurahName(context, widget.state.surahNumber)} • ${'ayah_label'.tr()} ${_toArabicIndic(context, item.ayahNumber)}',
                                  style: GoogleFonts.cairo(
                                      fontSize: 11, color: onSurfaceMuted),
                                ),
                              ],
                            ),
                            if (index != shown.length - 1)
                              Padding(
                                padding: const EdgeInsets.only(top: 10),
                                child: Divider(
                                    height: 1,
                                    color: colors.onSurface
                                        .withValues(alpha: 0.08)),
                              ),
                          ],
                        ),
                      );
                    }),
                    if (hiddenCount > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          'and_x_more_ayahs'
                              .tr(args: [_toArabicIndic(context, hiddenCount)]),
                          style: GoogleFonts.cairo(
                              fontSize: 11, color: onSurfaceMuted),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.accentColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome_rounded,
                    color: AppTheme.accentColor, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'hasanat_earned_title'.tr(),
                        style: GoogleFonts.cairo(
                            fontSize: 12, color: onSurfaceMuted),
                      ),
                      Text(
                        _toArabicIndic(context, widget.state.sessionHashanat),
                        style: GoogleFonts.cairo(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.accentColor,
                        ),
                      ),
                      Text(
                        'inshaallah'.tr(),
                        style: GoogleFonts.cairo(
                            fontSize: 11, color: onSurfaceMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: widget.onDedicate,
              icon: const Text('💛', style: TextStyle(fontSize: 16)),
              label: Text(
                'gift_thawab'.tr(),
                style: GoogleFonts.cairo(
                    fontSize: 15, fontWeight: FontWeight.w700),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentColor,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (widget.state.finishedEarly) ...[
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: widget.onContinue,
                icon: const Icon(Icons.play_arrow_rounded,
                    color: Colors.white, size: 22),
                label: Text(
                  'continue_from_verse'.tr(args: [
                    _toArabicIndic(
                        context,
                        widget.state.fromVerse +
                            widget.state.currentVerseIndex +
                            1)
                  ]),
                  style: GoogleFonts.cairo(
                      fontSize: 15, fontWeight: FontWeight.w700),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: widget.onRestart,
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.primaryColor),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      'restart_button'.tr(),
                      style: GoogleFonts.cairo(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: widget.onHome,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      'home_button'.tr(),
                      style: GoogleFonts.cairo(
                          fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReviewAyahItem {
  const _ReviewAyahItem({
    required this.ayahNumber,
    required this.displayText,
    required this.severe,
  });
  final int ayahNumber;
  final String displayText;
  final bool severe;
}

class _ResultsStatCard extends StatelessWidget {
  const _ResultsStatCard({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: GoogleFonts.cairo(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.cairo(
              fontSize: 12,
              color: colors.onSurface.withValues(alpha: 0.65),
            ),
          ),
        ],
      ),
    );
  }
}

class _MomentCaptureSheet extends ConsumerStatefulWidget {
  const _MomentCaptureSheet({
    required this.surahName,
    required this.verseText,
    required this.onSave,
  });
  final String surahName;
  final String verseText;
  final Future<void> Function(String feeling, String note) onSave;

  @override
  ConsumerState<_MomentCaptureSheet> createState() =>
      _MomentCaptureSheetState();
}

class _MomentCaptureSheetState extends ConsumerState<_MomentCaptureSheet> {
  String _selectedFeeling = 'feeling_touched';
  String _note = '';

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(quranSettingsControllerProvider).valueOrNull ??
        const QuranSettings(
            fontSize: 26,
            fontFamily: 'Scheherazade New',
            themeMode: QuranThemeMode.sepia);
    final isDark = settings.themeMode == QuranThemeMode.dark;
    final bgColor = QuranUIUtils.getBackgroundColor(settings.themeMode);
    final textColor = QuranUIUtils.getTextColor(settings.themeMode);
    final accentColor = QuranUIUtils.getAccentColor(settings.themeMode);

    Widget feelingChip(String emoji, String label) {
      final selected = _selectedFeeling == label;
      return ChoiceChip(
        label: Text('$emoji ${label.tr()}',
            style: GoogleFonts.cairo(fontSize: 11)),
        selected: selected,
        showCheckmark: false,
        onSelected: (_) => setState(() => _selectedFeeling = label),
        selectedColor: AppTheme.accentColor.withValues(alpha: 0.2),
        backgroundColor: textColor.withValues(alpha: 0.05),
        labelStyle: TextStyle(
          color: selected
              ? AppTheme.accentColor
              : textColor.withValues(alpha: 0.6),
          fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        border: Border(
            top: BorderSide(
                color: textColor.withValues(alpha: 0.1), width: 0.5)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: textColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            widget.surahName,
            style: GoogleFonts.cairo(
                fontSize: 10, color: textColor.withOpacity(0.4)),
          ),
          const SizedBox(height: 6),
          Directionality(
            textDirection: ui.TextDirection.rtl,
            child: Text(
              widget.verseText,
              style: GoogleFonts.amiri(
                  fontSize: 14, color: textColor.withOpacity(0.8), height: 2.0),
              textAlign: TextAlign.center,
            ),
          ),
          Divider(color: textColor.withValues(alpha: 0.1), height: 24),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'moment_prompt'.tr(),
              style: GoogleFonts.cairo(
                  fontSize: 14, fontWeight: FontWeight.w700, color: textColor),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              feelingChip('🥺', 'feeling_touched'),
              feelingChip('😢', 'feeling_cried'),
              feelingChip('😌', 'feeling_comforted'),
              feelingChip('🤔', 'feeling_reflected'),
              feelingChip('🙏', 'feeling_thankful'),
            ],
          ),
          const SizedBox(height: 10),
          TextField(
            style: GoogleFonts.cairo(
                fontSize: 13, color: textColor.withOpacity(0.9)),
            textDirection: ui.TextDirection.rtl,
            maxLines: 2,
            onChanged: (v) => _note = v,
            decoration: InputDecoration(
              hintText: 'moment_note_hint'.tr(),
              hintStyle: GoogleFonts.cairo(
                  fontSize: 12, color: textColor.withOpacity(0.3)),
              filled: true,
              fillColor: textColor.withValues(alpha: 0.04),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                    color: textColor.withValues(alpha: 0.1), width: 0.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                    color: textColor.withValues(alpha: 0.1), width: 0.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: accentColor, width: 1),
              ),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: textColor.withValues(alpha: 0.1)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text('skip'.tr(),
                      style: GoogleFonts.cairo(
                          fontSize: 12, color: textColor.withOpacity(0.5))),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: () async =>
                      widget.onSave(_selectedFeeling, _note.trim()),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                  child: Text(
                    'save_moment_button'.tr(),
                    style: GoogleFonts.cairo(
                        fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _toArabicIndic(BuildContext context, int value) {
  // Always use Arabic numerals for this Islamic memorization app
  final western = value.toString();
  const digits = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
  final buffer = StringBuffer();
  for (final unit in western.codeUnits) {
    final digit = unit - 48;
    if (digit >= 0 && digit <= 9) {
      buffer.write(digits[digit]);
    }
  }
  return buffer.toString();
}
