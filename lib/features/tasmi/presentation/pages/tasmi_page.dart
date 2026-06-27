import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quran/quran.dart' as quran;
import 'package:sila_app/features/notifications/presentation/controllers/notification_providers.dart';
import 'package:sila_app/features/notifications/presentation/widgets/streak_badge.dart';
import 'package:sila_app/features/tasmi/presentation/controllers/tasmi_controller.dart';
import 'package:sila_app/features/tasmi/presentation/pages/tasmi_onboarding_page.dart';
import 'package:sila_app/features/tasmi/presentation/pages/widgets/mushaf_tasmi_view.dart';
import 'package:sila_app/features/tasmi/presentation/pages/widgets/tasmi_action_button.dart';
import 'package:sila_app/features/tasmi/presentation/pages/widgets/tasmi_correction_bubble.dart';
import 'package:sila_app/features/tasmi/presentation/pages/widgets/tasmi_page_header.dart';
import 'package:sila_app/features/tasmi/presentation/pages/widgets/tasmi_stats_row.dart';
import 'package:sila_app/features/tasmi/presentation/riverpod/tasmi_preferences_provider.dart';
import 'package:sila_app/features/tasmi/services/tasmi_speech_service.dart';
import 'package:sila_app/features/vefa/presentation/pages/vefa_page.dart';

class TasmiPage extends ConsumerStatefulWidget {
  const TasmiPage({
    super.key,
    required this.surahNumber,
    required this.fromAya,
    required this.toAya,
  });
  final int surahNumber;
  final int fromAya;
  final int toAya;

  @override
  ConsumerState<TasmiPage> createState() => _TasmiPageState();
}

class _TasmiPageState extends ConsumerState<TasmiPage> {
  final TasmiSpeechService _speechService = TasmiSpeechService();

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(() async {
      final tracker = await ref.read(streakTrackerProvider.future);
      await tracker.logActivity('tasmi');
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<TasmiState>(tasmiControllerProvider, (previous, next) {
      if (next.warningMessage != null &&
          next.warningMessage != previous?.warningMessage) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              next.warningMessage!.tr(),
              style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold),
            ),
            backgroundColor: Colors.orange[800],
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.read(tasmiControllerProvider.notifier).clearWarning();
      }
    });

    final prefs = ref.watch(tasmiPreferencesNotifierProvider);
    if (!prefs.isOnboardingDone) {
      return TasmiOnboardingPage(
        onDone: () {
          ref.read(tasmiControllerProvider.notifier).startSession(
                surahNumber: widget.surahNumber,
                fromAya: widget.fromAya,
                toAya: widget.toAya,
              );
        },
      );
    }

    final state = ref.watch(tasmiControllerProvider);
    final controller = ref.read(tasmiControllerProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const primaryColor = Color(0xFF064E3B);
    const accentColor = Color(0xFFD97706);
    final bgColor = isDark ? const Color(0xFF0F172A) : Colors.grey[50];
    final surfaceColor = isDark ? const Color(0xFF1E293B) : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: TasmiPageHeader(
        surahName:
            '${'surah_label'.tr()} ${quran.getSurahNameArabic(widget.surahNumber)}',
        fromAya: widget.fromAya,
        toAya: widget.toAya,
        isListening: state.status == TasmiStatus.listening,
      ),
      body: Column(
        children: [
          TasmiStatsRow(state: state),
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: StreakBadge(featureKey: 'tasmi'),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (state.status == TasmiStatus.listening)
                  StreamBuilder<MicHealthStatus>(
                    stream: _speechService.micHealthStream,
                    initialData: MicHealthStatus.active,
                    builder: (context, snapshot) {
                      final status = snapshot.data ?? MicHealthStatus.active;
                      final color = switch (status) {
                        MicHealthStatus.active => const Color(0xFF1D9E75),
                        MicHealthStatus.reconnecting => Colors.orange,
                        MicHealthStatus.stalled => Colors.red,
                      };
                      final label = switch (status) {
                        MicHealthStatus.active => 'listening_status'.tr(),
                        MicHealthStatus.reconnecting =>
                          'reconnecting_status'.tr(),
                        MicHealthStatus.stalled => 'stalled_status'.tr(),
                      };

                      return Row(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: color,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            label,
                            style: const TextStyle(
                                fontSize: 12, fontFamily: 'Cairo'),
                          ),
                          if (status == MicHealthStatus.stalled)
                            IconButton(
                              icon: const Icon(Icons.refresh, size: 16),
                              onPressed: _speechService.forceRestart,
                            ),
                        ],
                      );
                    },
                  )
                else
                  const SizedBox.shrink(),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: primaryColor,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    backgroundColor:
                        primaryColor.withOpacity(isDark ? 0.2 : 0.1),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => TasmiOnboardingPage(
                          onDone: () => Navigator.pop(context),
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.tune_rounded, size: 18),
                  label: Text('tasmi_settings'.tr(),
                      style: const TextStyle(
                          fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (state.status == TasmiStatus.idle ||
                      state.status == TasmiStatus.error)
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color:
                                primaryColor.withOpacity(isDark ? 0.2 : 0.05),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.mic_none_rounded,
                              size: 64, color: primaryColor),
                        ),
                        const SizedBox(height: 24),
                        Text('press_start_tasmi'.tr(),
                            style: TextStyle(
                              fontSize: 18,
                              fontFamily: 'Cairo',
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            )),
                        const SizedBox(height: 8),
                        Text('speak_clearly_hint'.tr(),
                            style: TextStyle(
                              fontSize: 14,
                              fontFamily: 'Cairo',
                              color: isDark ? Colors.white60 : Colors.black54,
                            )),
                        if (state.status == TasmiStatus.error &&
                            state.errorMessage != null)
                          Container(
                            margin: const EdgeInsets.only(top: 16),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                  color: Colors.red.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.error_outline_rounded,
                                    color: Colors.red[700], size: 20),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    state.errorMessage!,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        color: Colors.red[700],
                                        fontFamily: 'Cairo',
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (state.currentIndex > 0 &&
                            state.currentIndex < state.words.length &&
                            state.status != TasmiStatus.listening)
                          Padding(
                            padding: const EdgeInsets.only(top: 24),
                            child: SizedBox(
                              width: 180,
                              height: 50,
                              child: ElevatedButton.icon(
                                onPressed: controller.resumeSession,
                                icon: const Icon(Icons.play_arrow_rounded),
                                label: Text('resume'.tr(),
                                    style: const TextStyle(
                                        fontFamily: 'Cairo',
                                        fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: accentColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  if (state.status == TasmiStatus.listening ||
                      state.status == TasmiStatus.waitingForUser ||
                      state.status == TasmiStatus.finished)
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        const MushafTasmiView(),
                        if (state.status == TasmiStatus.finished &&
                            state.currentIndex < state.words.length)
                          Positioned(
                            bottom: 24,
                            child: SizedBox(
                              width: 180,
                              height: 50,
                              child: ElevatedButton.icon(
                                onPressed: controller.resumeSession,
                                icon: const Icon(Icons.play_arrow_rounded),
                                label: Text('resume'.tr(),
                                    style: const TextStyle(
                                        fontFamily: 'Cairo',
                                        fontWeight: FontWeight.bold)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: accentColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                  elevation: 8,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (child, animation) {
              return SlideTransition(
                position:
                    Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
                        .animate(animation),
                child: FadeTransition(opacity: animation, child: child),
              );
            },
            child: state.correctionWord != null
                ? TasmiCorrectionBubble(word: state.correctionWord)
                : const SizedBox.shrink(),
          ),
          if (state.status == TasmiStatus.waitingForUser)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: controller.resumeAfterUserPrompt,
                  icon: const Icon(Icons.play_arrow_rounded, size: 28),
                  label: Text('continue_tasmi'.tr(),
                      style: const TextStyle(
                          fontSize: 18,
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                    shadowColor: primaryColor.withValues(alpha: 0.4),
                  ),
                ),
              ),
            )
          else
            TasmiActionButton(
              state: state,
              onStart: () => controller.startSession(
                  surahNumber: widget.surahNumber,
                  fromAya: widget.fromAya,
                  toAya: widget.toAya),
              onStop: controller.stopSession,
              onRestart: () => controller.startSession(
                  surahNumber: widget.surahNumber,
                  fromAya: widget.fromAya,
                  toAya: widget.toAya),
              onShowResults: () {
                _showResultsBottomSheet(
                    context, state, primaryColor, accentColor, isDark);
              },
            ),
        ],
      ),
    );
  }

  void _showResultsBottomSheet(BuildContext context, TasmiState state,
      Color primaryColor, Color accentColor, bool isDark) {
    try {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) => SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(32)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 48,
                  height: 6,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                Text(
                  'tasmi_results'.tr(),
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                    color: isDark ? Colors.white : primaryColor,
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: 140,
                  height: 140,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: state.stats.accuracyPercent / 100,
                        strokeWidth: 12,
                        backgroundColor:
                            isDark ? Colors.white10 : Colors.grey[200],
                        color: state.stats.accuracyPercent >= 80
                            ? Colors.green
                            : state.stats.accuracyPercent >= 50
                                ? accentColor
                                : Colors.red,
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${state.stats.accuracyPercent.toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Cairo',
                              color: isDark ? Colors.white : primaryColor,
                            ),
                          ),
                          Text(
                            'memorization_accuracy'.tr(),
                            style: TextStyle(
                              fontSize: 14,
                              fontFamily: 'Cairo',
                              color: isDark ? Colors.white70 : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.grey[50],
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: isDark
                            ? Colors.white10
                            : Colors.black.withValues(alpha: 0.05)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _StatChip(
                        label: 'correct_label'.tr(),
                        value: state.stats.correctCount,
                        color: Colors.green,
                        icon: Icons.check_circle_rounded,
                        isDark: isDark,
                      ),
                      Container(
                          width: 1,
                          height: 40,
                          color: isDark ? Colors.white10 : Colors.grey[300]),
                      _StatChip(
                        label: 'close_match_label'.tr(),
                        value: state.stats.closeErrorCount,
                        color: accentColor,
                        icon: Icons.warning_rounded,
                        isDark: isDark,
                      ),
                      Container(
                          width: 1,
                          height: 40,
                          color: isDark ? Colors.white10 : Colors.grey[300]),
                      _StatChip(
                        label: 'wrong_label'.tr(),
                        value: state.stats.wrongCount,
                        color: Colors.red,
                        icon: Icons.cancel_rounded,
                        isDark: isDark,
                      ),
                      Container(
                          width: 1,
                          height: 40,
                          color: isDark ? Colors.white10 : Colors.grey[300]),
                      _StatChip(
                        label: 'hasanat_label'.tr(),
                        value: state.stats.hasanatEarned,
                        color: const Color(0xFFFCD34D),
                        icon: Icons.stars_rounded,
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                if (state.stats.totalErrors > 0) ...[
                  Row(
                    children: [
                      Icon(Icons.history_edu_rounded, color: accentColor),
                      const SizedBox(width: 8),
                      Text(
                        'words_needing_review'.tr(),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Cairo',
                          fontSize: 18,
                          color: isDark ? Colors.white : primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 200),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: isDark
                              ? Colors.white10
                              : Colors.black.withValues(alpha: 0.05)),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: state.stats.errorList.take(10).length,
                      separatorBuilder: (context, index) => Divider(
                          height: 1,
                          color: isDark ? Colors.white10 : Colors.grey[200]),
                      itemBuilder: (context, index) {
                        final e = state.stats.errorList[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              color: Colors.red,
                              size: 16,
                            ),
                          ),
                          title: Text(
                            e.correctWord,
                            style: TextStyle(
                              fontFamily: 'Amiri',
                              fontSize: 22,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                            textDirection: ui.TextDirection.rtl,
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white10 : Colors.grey[200],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${'ayah_label'.tr()} ${e.verseNumber}',
                              style: TextStyle(
                                fontSize: 12,
                                fontFamily: 'Cairo',
                                color: isDark ? Colors.white70 : Colors.black54,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  if (state.stats.errorList.length > 10)
                    TextButton(
                      onPressed: () {},
                      child: Text(
                        'view_all_errors'.tr(
                            args: [state.stats.errorList.length.toString()]),
                        style: TextStyle(
                            fontFamily: 'Cairo',
                            color: primaryColor,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  const SizedBox(height: 24),
                ],
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      side: BorderSide(
                          color: accentColor.withValues(alpha: 0.5), width: 2),
                      backgroundColor: accentColor.withValues(alpha: 0.05),
                    ),
                    onPressed: () {
                      Navigator.pop(sheetContext);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const VefaPage(isSelectionMode: true),
                        ),
                      );
                    },
                    icon: Icon(Icons.favorite_rounded,
                        color: accentColor, size: 24),
                    label: Text(
                      'gift_thawab'.tr(),
                      style: TextStyle(
                        fontSize: 18,
                        fontFamily: 'Cairo',
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : primaryColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: () => Navigator.pop(sheetContext),
                    child: Text('understood'.tr(),
                        style: const TextStyle(
                            fontSize: 18,
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.bold)),
                  ),
                ),
                SizedBox(height: MediaQuery.of(sheetContext).padding.bottom),
              ],
            ),
          ),
        ),
      );
    } catch (e) {
      debugPrint('❌ Error showing bottom sheet: $e');
    }
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
    required this.isDark,
  });
  final String label;
  final int value;
  final Color color;
  final IconData icon;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 8),
        Text(
          '$value',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
            fontFamily: 'Cairo',
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.white70 : Colors.grey[700],
            fontFamily: 'Cairo',
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
