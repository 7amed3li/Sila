import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sila_app/features/notifications/presentation/controllers/notification_providers.dart';

class StreakSummaryCard extends ConsumerWidget {
  const StreakSummaryCard({super.key});

  static const _keys = ['azkar', 'wird', 'hifz', 'tasmi', 'tasbih'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(streakSummaryProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = isDark ? const Color(0xFF111827) : Colors.white;
    final border = isDark ? const Color(0xFF243041) : const Color(0xFFE2E8F0);
    final titleColor =
        isDark ? const Color(0xFFE2E8F0) : const Color(0xFF0F172A);
    final data = summaryAsync.valueOrNull ?? <String, int>{};
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E3A5F), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.35),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
          // Subtle outer glow
          BoxShadow(
            color: const Color(0xFFD97706).withValues(alpha: 0.04),
            blurRadius: 40,
            spreadRadius: 2,
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
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.flash_on_rounded,
                        color: Color(0xFFD97706), size: 16),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'worship_tracking'.tr(),
                    style: GoogleFonts.cairo(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Text(
                'weekly_activity'.tr(),
                style: GoogleFonts.cairo(
                  fontSize: 11,
                  color: Colors.white.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _keys.map((k) {
              final count = data[k] ?? 0;
              final hasStreak = count > 0;

              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: hasStreak
                        ? const Color(0xFFD97706).withValues(alpha: 0.2)
                        : Colors.white.withValues(alpha: 0.05),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _icon(k),
                      color:
                          hasStreak ? const Color(0xFFD97706) : Colors.white24,
                      size: 16,
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _name(k).tr(),
                          style: GoogleFonts.cairo(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                        Text(
                          '$count ${'streak_days'.tr()}',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: hasStreak
                                ? const Color(0xFF10B981)
                                : Colors.white30,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            }).toList(),
          )
        ],
      ),
    );
  }

  IconData _icon(String key) {
    switch (key) {
      case 'azkar':
        return Icons.wb_sunny_rounded;
      case 'wird':
        return Icons.menu_book_rounded;
      case 'hifz':
        return Icons.auto_stories_rounded;
      case 'tasmi':
        return Icons.mic_rounded;
      case 'tasbih':
        return Icons.flare_rounded;
      default:
        return Icons.star_rounded;
    }
  }

  static String _name(String key) {
    switch (key) {
      case 'azkar':
        return 'azkar_label';
      case 'wird':
        return 'wird_label';
      case 'hifz':
        return 'hifz_label';
      case 'tasmi':
        return 'tasmi_label';
      case 'tasbih':
        return 'tasbih_label';
      default:
        return key;
    }
  }
}
