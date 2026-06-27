import 'dart:ui' as ui;

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sila_app/core/theme/app_fonts.dart';
import 'package:quran/quran.dart' as quran;
import 'package:sila_app/core/theme/app_theme.dart';
import 'package:sila_app/features/vefa/presentation/pages/vefa_page.dart';
import 'package:sila_app/features/wird/data/models/wird_settings.dart';
import 'package:sila_app/features/wird/presentation/pages/wird_reader_page.dart';
import 'package:sila_app/features/wird/presentation/pages/wird_setup_page.dart';
import 'package:sila_app/features/wird/presentation/riverpod/wird_controller.dart';

class WirdCard extends ConsumerWidget {
  const WirdCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wirdStateAsync = ref.watch(wirdControllerProvider);

    return wirdStateAsync.when(
      data: (state) {
        return !state.hasConfiguredGoal
            ? _buildSetupTeaser(context)
            : Column(
                children: [
                  _buildMainWirdCard(context, ref, state),
                ],
              );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildSetupTeaser(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFD97706).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_stories_rounded,
                color: Color(0xFFD97706), size: 40),
          ),
          const SizedBox(height: 20),
          Text(
            'set_daily_wird'.tr(),
            style: AppFonts.amiri(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'start_blessed_journey'.tr(),
            textAlign: TextAlign.center,
            style: AppFonts.cairo(
              fontSize: 14,
              color: AppTheme.primaryColor.withValues(alpha: 0.6),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const WirdSetupPage()));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD97706),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: Text(
                'start_setup'.tr(),
                style: AppFonts.cairo(
                    fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Main Wird Card ───
  Widget _buildMainWirdCard(
      BuildContext context, WidgetRef ref, WirdState state) {
    final safeStartPage = state.currentPage.clamp(1, 604);

    final pageData = quran.getPageData(safeStartPage);
    final surahNum = pageData.isNotEmpty ? pageData[0]['surah'] : 1;
    final startAyah = pageData.isNotEmpty ? pageData[0]['start'] : 1;
    final firstVerse = quran.getVerse(surahNum, startAyah);
    final juz = quran.getJuzNumber(surahNum, startAyah);

    // Progress calculation derived from state
    var increment = 0;
    if (state.goalType == WirdGoalType.page) {
      increment = state.goalValue;
    } else if (state.goalType == WirdGoalType.juz) {
      increment = state.goalValue * 20;
    } else if (state.goalType == WirdGoalType.hizb) {
      increment = state.goalValue * 10;
    }

    final totalPagesToRead = increment.clamp(1, 604);
    final startOfGoal = (state.targetPage - totalPagesToRead + 1).clamp(1, 604);
    final pagesReadSoFar =
        (state.currentPage - startOfGoal).clamp(0, totalPagesToRead);
    final progress = (pagesReadSoFar / totalPagesToRead).clamp(0.0, 1.0);
    const textColor = Colors.white;
    const subtextColor = Colors.white70;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1E3A5F),
            Color(0xFF0F172A),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const WirdSetupPage()));
                    },
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.settings_rounded,
                          color: Color(0xFFD97706), size: 18),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'daily_wird_label'.tr(),
                    style: AppFonts.cairo(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFD97706).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFFD97706).withValues(alpha: 0.3)),
                ),
                child: Text(
                  'juz_number'.tr(args: ['$juz']),
                  style: AppFonts.cairo(
                    color: const Color(0xFFD97706),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Progress Section
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      'progress_text'.tr(args: ['${(progress * 100).toInt()}']),
                      style: AppFonts.cairo(
                        color: subtextColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'pages_count'
                        .tr(args: ['$pagesReadSoFar', '$totalPagesToRead']),
                    style: AppFonts.outfit(
                      color: const Color(0xFFD97706),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 10,
                  backgroundColor: Colors.white.withValues(alpha: 0.05),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                      Color(0xFF10B981)), // Success Green
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Ayah Preview
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: Column(
              children: [
                Text(
                  'from_quran_saying'.tr(),
                  style: AppFonts.amiri(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  firstVerse,
                  textAlign: TextAlign.center,
                  textDirection: ui.TextDirection.rtl,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppFonts.amiri(
                    fontSize: 24,
                    height: 1.6,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'surah_page'.tr(args: [
                    quran.getSurahNameArabic(surahNum),
                    '$safeStartPage'
                  ]),
                  style: AppFonts.cairo(
                    color: const Color(0xFFD97706).withValues(alpha: 0.8),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Action Buttons integrated inside
          _buildActionButtons(context, ref, state),
        ],
      ),
    );
  }

  // ─── Action Buttons ───
  Widget _buildActionButtons(
      BuildContext context, WidgetRef ref, WirdState state) {
    final isLate = state.daysDifference < 0;
    final lateDays = state.daysDifference.abs();

    return Column(
      children: [
        // Buttons Row (Side-by-side)
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => WirdReaderPage(
                        startPage: state.currentPage,
                        endPage: state.targetPage,
                      ),
                    ),
                  );
                  if (result == true && context.mounted) {
                    _showCompletionDialog(context, ref, state);
                  }
                },
                child: Container(
                  height: 56,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF064E3B), Color(0xFF047857)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      'continue_reading_wird'.tr(),
                      style: AppFonts.cairo(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Done Button (Islamic Gold)
            Expanded(
              child: GestureDetector(
                onTap: () => _showCompletionDialog(context, ref, state),
                child: Container(
                  height: 56,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFD97706), Color(0xFFB45309)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            'completed_reading'.tr(),
                            style: AppFonts.cairo(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(Icons.check_circle_outline,
                            color: Colors.white, size: 18),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),
        Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
        const SizedBox(height: 20),

        // Statistics Section
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    children: [
                      if (isLate)
                        const Icon(Icons.warning_rounded,
                            color: Color(0xFFEF4444), size: 16),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          isLate
                              ? 'behind_schedule'.tr(args: ['$lateDays'])
                              : 'on_track'.tr(),
                          style: AppFonts.cairo(
                            color: isLate
                                ? const Color(0xFFEF4444)
                                : Colors.white.withValues(alpha: 0.7),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'current_khatma'.tr(),
                  style: AppFonts.cairo(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Linear Progress
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: state.khatmaProgress,
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(Color(0xFF4B5563)),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    'upcoming_wirds'.tr(args: ['${state.remainingWirdsCount}']),
                    style: AppFonts.cairo(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 11,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    'completed_wirds'
                        .tr(args: ['${state.completedWirdsCount}']),
                    style: AppFonts.cairo(
                      color: Colors.white.withValues(alpha: 0.6),
                      fontSize: 11,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  // ─── Completion Dialog ───
  void _showCompletionDialog(
      BuildContext context, WidgetRef ref, WirdState state) {
    final isKhatmaComplete = state.targetPage >= 604;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          isKhatmaComplete
              ? 'quran_completion_title'.tr()
              : 'wird_completed_title'.tr(),
          style: AppFonts.outfit(fontWeight: FontWeight.bold),
        ),
        content: Text(
          isKhatmaComplete
              ? 'quran_completion_message'.tr()
              : 'completion_check'.tr(),
          style: AppFonts.outfit(fontSize: 15, height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('cancel'.tr(), style: AppFonts.outfit()),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              if (isKhatmaComplete) {
                ref
                    .read(wirdControllerProvider.notifier)
                    .completeWird(state.currentPage, 604)
                    .then((_) {
                  ref.read(wirdControllerProvider.notifier).startNewKhatma();
                });
              } else {
                ref
                    .read(wirdControllerProvider.notifier)
                    .completeWird(state.currentPage, state.targetPage);
              }
              Navigator.pop(context); // Close completion dialog

              if (context.mounted) {
                _showMubarakCelebration(context);
              }
            },
            child: Text(
              isKhatmaComplete
                  ? 'start_new_khatma'.tr()
                  : 'wird_completed_title'.tr(),
              style: AppFonts.outfit(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _showMubarakCelebration(BuildContext context) {
    OverlayEntry? overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) => _CelebrationWidget(
        onFinished: () {
          overlayEntry?.remove();
          _showDedicateRewardDialog(context);
        },
      ),
    );
    Overlay.of(context).insert(overlayEntry);
  }

  void _showDedicateRewardDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'wird_completed_title'.tr(),
          style: AppFonts.outfit(fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
        content: Text(
          'wird_completed_body'.tr(),
          textAlign: TextAlign.center,
          style: AppFonts.outfit(fontSize: 15),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('later'.tr(),
                style: AppFonts.outfit(color: Colors.grey)),
          ),
          const SizedBox(width: 8),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const VefaPage(isSelectionMode: true),
                ),
              );
            },
            child: Text(
              'yes_definitely'.tr(),
              style: AppFonts.outfit(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _CelebrationWidget extends StatefulWidget {
  const _CelebrationWidget({required this.onFinished});
  final VoidCallback onFinished;

  @override
  State<_CelebrationWidget> createState() => _CelebrationWidgetState();
}

class _CelebrationWidgetState extends State<_CelebrationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
          tween: CurveTween(curve: Curves.easeOutBack), weight: 20),
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 60),
      TweenSequenceItem(
          tween: CurveTween(curve: Curves.easeInBack), weight: 20),
    ]).animate(_controller);

    _opacityAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween<double>(begin: 0.0, end: 1.0), weight: 10),
      TweenSequenceItem(tween: ConstantTween<double>(1.0), weight: 80),
      TweenSequenceItem(tween: Tween<double>(begin: 1.0, end: 0.0), weight: 10),
    ]).animate(_controller);

    _controller.forward().then((_) => widget.onFinished());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withValues(alpha: 0.4),
      child: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return FadeTransition(
              opacity: _opacityAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFD97706).withValues(alpha: 0.4),
                        blurRadius: 40,
                        spreadRadius: 10,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        '🎉',
                        style: TextStyle(fontSize: 60),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'mubarak_text'.tr(),
                        style: AppFonts.amiri(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'completed_wird_daily'.tr(),
                        style: AppFonts.cairo(
                          fontSize: 18,
                          color: AppTheme.primaryColor.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
