import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sila_app/core/theme/app_fonts.dart';
import 'package:sila_app/features/azkar/presentation/pages/azkar_detail_page.dart';
import 'package:sila_app/features/azkar/presentation/riverpod/post_prayer_controller.dart';

class PostPrayerQuickCard extends ConsumerWidget {
  const PostPrayerQuickCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isVisible = ref.watch(postPrayerVisibilityProvider);
    final prayerName = ref.watch(currentPostPrayerNameProvider);

    if (!isVisible || prayerName == null) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Different colors based on prayer time could be a nice touch
    final cardColor = _getPrayerColor(prayerName);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [cardColor, cardColor.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: cardColor.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_awesome_rounded,
                      color: Colors.amber, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'post_prayer_window_title'.tr(),
                    style: const TextStyle(
                      fontFamily: 'Cairo',
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '45_min_left'.tr(),
                  style: const TextStyle(
                    fontFamily: 'Cairo',
                    color: Colors.white,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'post_prayer_adhkar_specific'.tr(args: ['prayer_$prayerName'.tr()]),
            style: AppFonts.amiri(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AzkarDetailPage(
                          categoryId: 'post_prayer',
                          title: 'azkar_post_prayer'.tr(),
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        'start_now'.tr(),
                        style: const TextStyle(
                          fontFamily: 'Cairo',
                          color: Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.arrow_forward_ios_rounded,
                    color: Colors.white, size: 18),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getPrayerColor(String prayer) {
    switch (prayer) {
      case 'fajr':
        return const Color(0xFF1E3A8A); // Deep Blue
      case 'dhuhr':
        return const Color(0xFF0369A1); // Sky Blue
      case 'asr':
        return const Color(0xFFB45309); // Amber/Orange
      case 'maghrib':
        return const Color(0xFF701A75); // Purple
      case 'isha':
        return const Color(0xFF1E1B4B); // Dark Navy
      default:
        return const Color(0xFF0F172A);
    }
  }
}
