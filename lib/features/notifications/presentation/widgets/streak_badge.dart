import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sila_app/core/theme/app_fonts.dart';
import 'package:sila_app/features/notifications/presentation/controllers/notification_providers.dart';

class StreakBadge extends ConsumerWidget {
  const StreakBadge({super.key, required this.featureKey});
  final String featureKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streakAsync = ref.watch(featureStreakProvider(featureKey));
    final days = streakAsync.valueOrNull ?? 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFECFDF3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFA7F3D0)),
      ),
      child: Text(
        '✦ ${'streak_days_count'.tr(args: [days.toString()])}',
        style: AppFonts.getFont(
          'Cairo',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF065F46),
        ),
      ),
    );
  }
}
