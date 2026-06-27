import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sila_app/core/theme/app_theme.dart';
import 'package:sila_app/core/services/notification_service.dart';
import 'package:sila_app/features/azkar/presentation/widgets/post_prayer_quick_card.dart';
import 'package:sila_app/features/hifz/presentation/pages/hifz_home_page.dart';
import 'package:sila_app/features/hifz/presentation/pages/hifz_onboarding_page.dart';
import 'package:sila_app/features/home/presentation/pages/feedback_sheet.dart';
import 'package:sila_app/features/home/presentation/providers/last_notification_provider.dart';
import 'package:sila_app/features/home/presentation/widgets/daily_content_card.dart';
import 'package:sila_app/features/home/presentation/widgets/home_header.dart';
import 'package:sila_app/features/home/presentation/widgets/next_prayer_card.dart';
import 'package:sila_app/features/notifications/presentation/pages/notification_detail_page.dart';
import 'package:sila_app/features/notifications/presentation/pages/notification_hub_page.dart';
import 'package:sila_app/features/notifications/presentation/widgets/streak_summary_card.dart';
import 'package:sila_app/features/tasmi/presentation/pages/tasmi_surah_selection_page.dart';
import 'package:sila_app/features/wird/presentation/widgets/wird_card.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  static const _onboardingDoneKey = 'hifz_onboarding_done';

  Future<void> _openHifz(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final done = prefs.getBool(_onboardingDoneKey) ?? false;

    if (!context.mounted) {
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            done ? const HifzHomePage() : const HifzOnboardingPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F172A) : const Color(0xFFFDFBF7);

    return Scaffold(
      backgroundColor: bg,
      body: CustomScrollView(
        slivers: [
          // ── SliverAppBar — Header ──
          SliverAppBar(
            expandedHeight: 180,
            floating: false,
            pinned: true,
            elevation: 0,
            backgroundColor: AppTheme.primaryColor,
            flexibleSpace: FlexibleSpaceBar(
              background: HomeHeader(
                onNotificationTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const NotificationHubPage()),
                  );
                },
                onFeedbackTap: () {
                  FeedbackSheet.show(context);
                },
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── Post Prayer Quick Access ──
                const PostPrayerQuickCard(),
                const SizedBox(height: 12),
                // ── Next Prayer Card ──
                const NextPrayerCard(),
                const SizedBox(height: 24),

                // ── Streak Summary ──
                const StreakSummaryCard(),
                const SizedBox(height: 32),

                // ── Wird Card ──
                const WirdCard(),

                const SizedBox(height: 24),

                // ── Tools Row (Hifz & Tasmi) ──
                Row(
                  children: [
                    Expanded(
                      child: _buildToolCard(
                        title: 'nav_hifz'.tr(),
                        subtitle: 'hifz_continue'.tr(),
                        icon: Icons.auto_stories,
                        color: const Color(0xFF064E3B),
                        onTap: () => _openHifz(context),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildToolCard(
                        title: 'continue_tasmi'.tr(),
                        subtitle: 'test_hifz'.tr(),
                        icon: Icons.mic_rounded,
                        color: const Color(0xFF1E3A5F),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const TasmiSurahSelectionPage(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ── Notification Inbox Card ──
                const _NotificationInboxCard(),

                const SizedBox(height: 24),

                // ── Daily Content Card ──
                const DailyContentCard(),

                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 160,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.amiri(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.cairo(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationInboxCard extends ConsumerWidget {
  const _NotificationInboxCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lastNotifAsync = ref.watch(lastNotificationProvider);

    return lastNotifAsync.when(
      data: (notif) {
        if (notif == null) return const SizedBox.shrink();

        return GestureDetector(
          onTap: () async {
            if (notif.category != null && notif.contentId != null) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => NotificationDetailPage(
                    category: notif.category!,
                    contentId: notif.contentId!,
                  ),
                ),
              );
              return;
            }

            if (notif.payload != null && notif.payload!.trim().isNotEmpty) {
              await NotificationService().handleNotificationPayload(notif.payload);
              if (!context.mounted) return;
              return;
            }

            if (!context.mounted) return;
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const NotificationHubPage()),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.accentColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppTheme.accentColor.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.notifications_active_outlined,
                    color: AppTheme.accentColor,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              notif.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.notoKufiArabic(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatTime(notif.time),
                            style: GoogleFonts.notoKufiArabic(
                              fontSize: 11,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notif.body,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.notoKufiArabic(
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: AppTheme.accentColor,
                ),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    if (time.year == now.year &&
        time.month == now.month &&
        time.day == now.day) {
      final hour = time.hour.toString().padLeft(2, '0');
      final minute = time.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    }
    return '${time.day}/${time.month}';
  }
}
