import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sila_app/core/utils/time_utils.dart';
import 'package:sila_app/features/home/presentation/widgets/home_shimmer.dart';
import 'package:sila_app/features/prayers/presentation/riverpod/prayer_controller.dart';

class NextPrayerCard extends ConsumerStatefulWidget {
  const NextPrayerCard({super.key});

  @override
  ConsumerState<NextPrayerCard> createState() => _NextPrayerCardState();
}

class _NextPrayerCardState extends ConsumerState<NextPrayerCard> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final timesAsync = ref.watch(prayerTimesControllerProvider);

    return timesAsync.when(
      data: (entity) {
        // ── Find next prayer ──────────────────────────────────────────────
        final now = DateTime.now();
        final prayers = [
          (key: 'fajr', time: entity.fajr),
          (key: 'sunrise', time: entity.sunrise),
          (key: 'dhuhr', time: entity.dhuhr),
          (key: 'asr', time: entity.asr),
          (key: 'maghrib', time: entity.maghrib),
          (key: 'isha', time: entity.isha),
        ];

        var nextKey = 'fajr';
        DateTime? nextTime;
        for (final p in prayers) {
          if (p.time.isAfter(now)) {
            nextTime = p.time;
            nextKey = p.key;
            break;
          }
        }
        nextTime ??= entity.fajr.add(const Duration(days: 1));

        var timeLeft = nextTime.difference(now);
        if (timeLeft.isNegative) timeLeft = Duration.zero;
        if (timeLeft.inHours > 24) timeLeft = Duration.zero;

        final hours = timeLeft.inHours.toString().padLeft(2, '0');
        final mins = timeLeft.inMinutes.remainder(60).toString().padLeft(2, '0');
        final secs = timeLeft.inSeconds.remainder(60).toString().padLeft(2, '0');
        final remainingTime = '$hours:$mins:$secs';

        final nextPrayerName = nextKey.tr();
        
        final formattedNextTime = TimeUtils.formatPrayerTime(nextTime, context);

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF064E3B), Color(0xFF0a6b52)],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Text('next_prayer'.tr(),
                    style: GoogleFonts.getFont('Cairo',
                      fontSize: 12, color: Colors.white60)),
                   Text(nextPrayerName,
                    style: GoogleFonts.getFont('Cairo',
                      fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
                   Text(formattedNextTime,
                    style: GoogleFonts.getFont('Cairo',
                      fontSize: 14, color: Colors.white70)),
                 ],
               ),
               Column(
                 crossAxisAlignment: CrossAxisAlignment.end,
                 children: [
                   Text('remaining_time'.tr(),
                    style: GoogleFonts.getFont('Cairo',
                      fontSize: 11, color: Colors.white60)),
                   Text(remainingTime,
                    style: GoogleFonts.getFont('Cairo',
                      fontSize: 18, fontWeight: FontWeight.w700,
                      color: const Color(0xFFFCD34D))),
                 ],
               ),
            ],
          ),
        );
      },
      loading: () => HomeShimmer.prayer(),
      error: (e, _) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.red.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.red),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'error_loading_prayers'.tr(),
                style: const TextStyle(color: Colors.red, fontSize: 13),
              ),
            ),
            IconButton(
              onPressed: () => ref.invalidate(prayerTimesControllerProvider),
              icon: const Icon(Icons.refresh, color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }
}
