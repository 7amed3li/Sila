import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:quran/quran.dart' as quran;
import 'package:sila_app/core/theme/app_theme.dart';
import 'package:sila_app/core/utils/surah_utils.dart';
import 'package:sila_app/features/hifz/domain/hifz_selection.dart';
import 'package:sila_app/features/hifz/presentation/controllers/hifz_home_controller.dart';
import 'package:sila_app/features/hifz/presentation/pages/hifz_settings_page.dart';
import 'package:sila_app/features/hifz/presentation/pages/methods/interactive_shadow_page.dart';
import 'package:sila_app/features/notifications/presentation/controllers/notification_providers.dart';
import 'package:sila_app/features/notifications/presentation/pages/settings/hifz_notification_settings.dart';
import 'package:sila_app/features/notifications/presentation/widgets/streak_badge.dart';
import 'package:sila_app/features/quran/domain/entities/quran_settings.dart';
import 'package:sila_app/features/quran/presentation/riverpod/quran_settings_controller.dart';
import 'package:sila_app/features/quran/presentation/utils/quran_ui_utils.dart';
import 'package:sila_app/features/tasmi/presentation/pages/tasmi_surah_selection_page.dart'
    as import_tasmi;

const Color _hasanatGold = AppTheme.goldLight;
const Color _errorColor = Color(0xFFF87171);

class HifzHomePage extends ConsumerStatefulWidget {
  const HifzHomePage({super.key});

  @override
  ConsumerState<HifzHomePage> createState() => _HifzHomePageState();
}

class _HifzHomePageState extends ConsumerState<HifzHomePage> {
  Future<HifzSelection?> _pickSurahSelectionFlow({
    required bool showAyahRange,
  }) {
    return Navigator.push<HifzSelection>(
      context,
      MaterialPageRoute(
        builder: (_) => import_tasmi.TasmiSurahSelectionPage(
          forHifz: true,
          showAyahRange: showAyahRange,
        ),
      ),
    );
  }

  Future<HifzSelection?> _showHifzSelectionDialog(HifzHomeState state) async {
    final plan = state.plan;
    final mode = await showModalBottomSheet<_HifzSelectionMode>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(color: const Color(0xFFE2E8F0), width: 0.5),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _selectionOption(
                    icon: '🎯',
                    title: 'daily_plan'.tr(),
                    subtitle: plan != null
                        ? '${plan.newAyahsTarget} ${'ayah_label'.tr()}s ${'from_verse'.tr()}'
                        : 'hifz_start'.tr(),
                    recommended: true,
                    onTap: () {
                      Navigator.pop(
                          sheetContext, _HifzSelectionMode.dailyPlan);
                    },
                  ),
                  const SizedBox(height: 10),
                  _selectionOption(
                    icon: '📖',
                    title: 'complete_surah'.tr(),
                    subtitle: 'complete_surah_subtitle'.tr(),
                    onTap: () {
                      Navigator.pop(
                          sheetContext, _HifzSelectionMode.fullSurah);
                    },
                  ),
                  const SizedBox(height: 10),
                  _selectionOption(
                    icon: '✂️',
                    title: 'verse_range'.tr(),
                    subtitle: 'verse_range_subtitle'.tr(args: ['X', 'Y']),
                    onTap: () {
                      Navigator.pop(
                          sheetContext, _HifzSelectionMode.ayahRange);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (mode == null) {
      return null;
    }

    if (mode == _HifzSelectionMode.dailyPlan) {
      const surahNumber = 1;
      final maxAyahs = quran.getVerseCount(surahNumber);
      final target = (plan?.newAyahsTarget ?? 5).clamp(1, maxAyahs);
      return HifzSelection(
        surahNumber: surahNumber,
        fromVerse: 1,
        toVerse: target,
        type: HifzSelectionType.dailyPlan,
      );
    }

    if (mode == _HifzSelectionMode.fullSurah) {
      return _pickSurahSelectionFlow(showAyahRange: false);
    }

    return _pickSurahSelectionFlow(showAyahRange: true);
  }

  void _showComingSoon(String featureName) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.auto_awesome, color: Color(0xFFFCD34D), size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'feature_under_construction'.tr(args: [featureName]),
                style: GoogleFonts.cairo(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF064E3B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Widget _selectionOption({
    required String icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool recommended = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: recommended ? const Color(0xFFF0FDF4) : Colors.grey[50],
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color:
                recommended ? const Color(0xFFBBF7D0) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            if (recommended)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF064E3B).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'recommended'.tr(),
                  style: GoogleFonts.cairo(
                    fontSize: 10,
                    color: const Color(0xFF064E3B),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    Future<void>.microtask(() {
      final c = ref.read(hifzHomeControllerProvider.notifier);
      c.loadTodayStats();
      c.loadRecentMoments();
      c.loadDueReviews();
    });
    Future<void>.microtask(() async {
      final tracker = await ref.read(streakTrackerProvider.future);
      await tracker.logActivity('hifz');
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(hifzHomeControllerProvider);
    final controller = ref.read(hifzHomeControllerProvider.notifier);

    final settings = ref.watch(quranSettingsControllerProvider).valueOrNull ??
        const QuranSettings(
            fontSize: 26,
            fontFamily: 'Scheherazade New',
            themeMode: QuranThemeMode.sepia);
    const isDark =
        false; // Always use light mode layout for this page as requested
    const bgColor = isDark ? Color(0xFF0F172A) : Colors.white;
    final accentColor = QuranUIUtils.getAccentColor(settings.themeMode);

    return Scaffold(
      backgroundColor: bgColor,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: bgColor,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
                background: _Header(state: state, settings: settings)),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (state.errorMessage != null)
                    _ErrorCard(message: state.errorMessage!),
                  if (state.errorMessage != null) const SizedBox(height: 12),
                  _DailyPlanCard(state: state),
                  const SizedBox(height: 16),
                  // ==========================================
                  // TASMI3 MAIN HERO CARD (NEW PROMINENT LOCATION)
                  // ==========================================
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const import_tasmi.TasmiSurahSelectionPage(),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient:
                            AppTheme.headerGradient, // Emerald Deep Gradient
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryColor.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppTheme.goldLight.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    'main_feature'.tr(),
                                    style: GoogleFonts.cairo(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.goldLight,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  'ai_tasmi_title'.tr(),
                                  style: GoogleFonts.cairo(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    height: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'ai_tasmi_desc'.tr(),
                                  style: GoogleFonts.cairo(
                                    fontSize: 12,
                                    color: Colors.white.withOpacity(0.8),
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              gradient: AppTheme.ctaGradient,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.accentColor.withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.mic_rounded,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _HasanatCard(hasanat: state.hasanatToday),
                  const SizedBox(height: 24),
                  Text(
                    'hifz_methods'.tr(),
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 10),
                  _MethodsGrid(
                    dueReviewCount: state.reviewDueCount,
                    onInteractiveShadow: () async {
                      final selection = await _showHifzSelectionDialog(state);
                      if (selection == null || !mounted) return;
                      debugPrint(
                        'Hifz selection -> surah=${selection.surahNumber}, from=${selection.fromVerse}, to=${selection.toVerse}, type=${selection.type}',
                      );
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => InteractiveShadowPage(
                            surahNumber: selection.surahNumber,
                            fromVerse: selection.fromVerse,
                            toVerse: selection.toVerse,
                          ),
                        ),
                      );
                    },
                    onSmartReview: () => _showComingSoon('smart_review'.tr()),
                    onListening: () => _showComingSoon('listening_method'.tr()),
                    onRepetition: () =>
                        _showComingSoon('repetition_method'.tr()),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'my_moments'.tr(),
                    style: GoogleFonts.cairo(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _MomentsSection(moments: state.recentMoments),
                  if (state.hasResumePoint) ...[
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => InteractiveShadowPage(
                                surahNumber: state.resumeSurah,
                                fromVerse: state.resumeFromVerse,
                                toVerse: state.resumeToVerse,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.play_arrow_rounded,
                            color: Colors.white, size: 20),
                        label: Text(
                          'continue_from_verse'.tr(
                              args: [_toArabicIndic(state.resumeFromVerse)]),
                          style: GoogleFonts.cairo(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50)),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

enum _HifzSelectionMode {
  dailyPlan,
  fullSurah,
  ayahRange,
}

class _Header extends StatelessWidget {
  const _Header({required this.state, required this.settings});
  final HifzHomeState state;
  final QuranSettings settings;

  @override
  Widget build(BuildContext context) {
    final isDark = settings.themeMode == QuranThemeMode.dark;
    final accentColor = QuranUIUtils.getAccentColor(settings.themeMode);

    return Container(
      decoration: const BoxDecoration(
        gradient: AppTheme.headerGradient,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'welcome_hifz_user'.tr(),
                        style: GoogleFonts.cairo(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                      Text(
                        'quran_memorizer'.tr(),
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  const StreakBadge(featureKey: 'hifz'),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const HifzNotificationSettings()),
                      );
                    },
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Icon(Icons.notifications_active_rounded,
                          color: Colors.white, size: 16),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                            builder: (_) => const HifzSettingsPage()),
                      );
                    },
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Icon(Icons.tune_rounded,
                          color: Colors.white, size: 16),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              const SizedBox.shrink(),
            ],
          ),
        ),
      ),
    );
  }
}

class _DailyPlanCard extends StatelessWidget {
  const _DailyPlanCard({required this.state});
  final HifzHomeState state;

  @override
  Widget build(BuildContext context) {
    const isDark =
        false; // Always use light mode layout for this page as requested
    final total = state.targetAyahsToday <= 0 ? 1 : state.targetAyahsToday;
    final progress = (state.doneAyahsToday / total).clamp(0.0, 1.0);
    final now = DateTime.now();
    final isArabic = context.locale.languageCode == 'ar';
    final dayStr = isArabic ? _toArabicIndic(now.day) : now.day.toString();
    final monthStr =
        isArabic ? _toArabicIndic(now.month) : now.month.toString();
    final yearStr = isArabic ? _toArabicIndic(now.year) : now.year.toString();
    final todayDate = '$dayStr/$monthStr/$yearStr';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkSurfaceColor : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
            width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'your_plan_today'.tr(),
                style: GoogleFonts.cairo(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
              Text(
                todayDate,
                style: GoogleFonts.cairo(
                  fontSize: 10,
                  color: const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOut,
            builder: (_, value, __) {
              return Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: value,
                        backgroundColor: const Color(0xFFE2E8F0),
                        valueColor:
                            const AlwaysStoppedAnimation(AppTheme.primaryColor),
                        minHeight: 6,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${isArabic ? _toArabicIndic(state.doneAyahsToday) : state.doneAyahsToday} / ${isArabic ? _toArabicIndic(total) : total} ${'ayah_label'.tr()}',
                    style: GoogleFonts.cairo(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'today_verses'.tr(),
                style: GoogleFonts.cairo(
                  fontSize: 10,
                  color: const Color(0xFF94A3B8),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0FDF4),
                  border: Border.all(color: const Color(0xFFBBF7D0)),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'review_label'.tr(args: [
                    isArabic
                        ? _toArabicIndic(state.reviewDueCount)
                        : state.reviewDueCount.toString()
                  ]),
                  style: GoogleFonts.cairo(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.primaryColor,
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

class _HasanatCard extends StatelessWidget {
  const _HasanatCard({required this.hasanat});
  final int hasanat;

  @override
  Widget build(BuildContext context) {
    final isArabic = context.locale.languageCode == 'ar';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppTheme.hasanatGradient,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TweenAnimationBuilder<int>(
            tween: IntTween(begin: 0, end: hasanat),
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeOut,
            builder: (_, value, __) {
              return Text(
                isArabic ? _toArabicIndic(value) : value.toString(),
                style: GoogleFonts.cairo(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: _hasanatGold,
                ),
              );
            },
          ),
          Text(
            'hasanah_earned'.tr(),
            style: GoogleFonts.cairo(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'hasanah_hadith'.tr(),
            style: GoogleFonts.cairo(
              fontSize: 9,
              fontStyle: FontStyle.italic,
              color: Colors.white.withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _MethodsGrid extends StatelessWidget {
  const _MethodsGrid({
    required this.dueReviewCount,
    required this.onInteractiveShadow,
    required this.onSmartReview,
    required this.onListening,
    required this.onRepetition,
  });
  final int dueReviewCount;
  final VoidCallback onInteractiveShadow;
  final VoidCallback onSmartReview;
  final VoidCallback onListening;
  final VoidCallback onRepetition;

  @override
  Widget build(BuildContext context) {
    const isDark =
        false; // Always use light mode layout for this page as requested
    final isArabic = context.locale.languageCode == 'ar';
    final countStr =
        isArabic ? _toArabicIndic(dueReviewCount) : dueReviewCount.toString();

    final cards = [
      (
        title: 'interactive_shadow'.tr(),
        sub: 'interactive_shadow_desc'.tr(),
        icon: '⭐',
        onTap: onInteractiveShadow,
        featured: true,
      ),
      (
        title: 'smart_review'.tr(),
        sub: 'smart_review_desc'.tr(args: [countStr]),
        icon: '🔄',
        onTap: onSmartReview,
        featured: false,
      ),
      (
        title: 'listening_method'.tr(),
        sub: 'listening_method_desc'.tr(),
        icon: '🎧',
        onTap: onListening,
        featured: false,
      ),
      (
        title: 'repetition_method'.tr(),
        sub: 'repetition_method_desc'.tr(),
        icon: '📖',
        onTap: onRepetition,
        featured: false,
      ),
    ];

    return GridView.count(
      crossAxisCount: 2,
      childAspectRatio: 1.1,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: cards.map((c) {
        return GestureDetector(
          onTap: c.onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: c.featured
                  ? (isDark
                      ? AppTheme.darkBackgroundColor
                      : const Color(0xFFFEF8E6))
                  : (isDark ? AppTheme.darkSurfaceColor : Colors.white),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: c.featured
                    ? AppTheme.accentColor.withOpacity(0.5)
                    : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                width: c.featured ? 1.5 : 0.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.03),
                  blurRadius: 6,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (c.featured)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppTheme.accentColor,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'recommended'.tr(),
                      style: GoogleFonts.cairo(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  )
                else
                  Text(c.icon, style: const TextStyle(fontSize: 18)),
                const SizedBox(height: 8),
                Text(
                  c.title,
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  c.sub,
                  style: GoogleFonts.cairo(
                    fontSize: 10,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _MomentsSection extends StatelessWidget {
  const _MomentsSection({required this.moments});
  final List<dynamic> moments;

  @override
  Widget build(BuildContext context) {
    const isDark =
        false; // Always use light mode layout for this page as requested

    if (moments.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppTheme.darkSurfaceColor : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
              width: 0.5),
        ),
        child: Column(
          children: [
            const Text('💎', style: TextStyle(fontSize: 24)),
            const SizedBox(height: 6),
            Text(
              'no_moments_title'.tr(),
              style: GoogleFonts.cairo(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E40AF),
              ),
            ),
            Text(
              'no_moments_desc'.tr(),
              style: GoogleFonts.cairo(
                fontSize: 10,
                color: const Color(0xFF93C5FD),
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 140,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: moments.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (_, index) {
          final moment = moments[index];
          // Use localized helper
          final surahName =
              SurahUtils.getLocalizedSurahName(context, moment.surahIndex);
          final reflection = (moment.reflection ?? '').toString().trim();

          return Container(
            width: 200,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppTheme.darkSurfaceColor : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                  width: 1.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      surahName,
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const Text('💎', style: TextStyle(fontSize: 14)),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  reflection.isEmpty ? 'no_reflection'.tr() : reflection,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cairo(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF1E293B),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _errorColor.withValues(alpha: 0.08),
        border: Border.all(color: _errorColor.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        message,
        style: GoogleFonts.cairo(fontSize: 11, color: _errorColor),
      ),
    );
  }
}

String _toArabicIndic(int value) {
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
