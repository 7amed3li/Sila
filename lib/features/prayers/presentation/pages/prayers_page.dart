import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sila_app/core/services/analytics_service.dart';
import 'package:sila_app/core/services/notification_service.dart';
import 'package:sila_app/core/services/prefs_service.dart'; // ADDED: per-prayer adhan toggle
import 'package:sila_app/core/utils/time_utils.dart';
import 'package:sila_app/features/ibadah_tracker/presentation/pages/ibadah_tracker_tab.dart';
import 'package:sila_app/features/notifications/presentation/controllers/notification_providers.dart';
import 'package:sila_app/features/notifications/presentation/pages/settings/salah_notification_settings.dart';
import 'package:sila_app/features/notifications/presentation/widgets/streak_badge.dart';
import 'package:sila_app/features/prayers/presentation/pages/prayer_settings_page.dart';
import 'package:sila_app/features/prayers/presentation/pages/qiblah_page.dart';
import 'package:sila_app/features/prayers/presentation/riverpod/prayer_controller.dart';
import 'package:sila_app/features/prayers/domain/entities/prayer_times_entity.dart';

class PrayersPage extends ConsumerStatefulWidget {
  const PrayersPage({super.key, this.initialTabIndex = 0});

  final int initialTabIndex;

  @override
  ConsumerState<PrayersPage> createState() => _PrayersPageState();
}

class _PrayersPageState extends ConsumerState<PrayersPage> {
  Widget _buildStaleIndicator(PrayerTimesEntity entity) {
    // Placeholder = لا بيانات نهائياً (أول تشغيل ـ أو التحميل لم ينجح)
    if (entity.lastUpdated.millisecondsSinceEpoch == 0) {
      return Padding(
        padding: const EdgeInsets.only(top: 6.0),
        child: Row(children:[
          Icon(Icons.sync_rounded, color: Colors.amber, size: 17),
          SizedBox(width: 6),
          Text('جاري تحميل المواقيت...', style: TextStyle(color: Colors.amber, fontSize: 13)),
        ]),
      );
    }
    // قديمة (>24 ساعة)
    if (entity.isStale) {
      final diff = DateTime.now().difference(entity.lastUpdated);
      String ago;
      if (diff.inDays > 0) {
        ago = '${diff.inDays} يوم';
      } else if (diff.inHours > 0) {
        ago = '${diff.inHours} ساعة';
      } else {
        ago = '${diff.inMinutes} دقيقة';
      }
      return Padding(
        padding: const EdgeInsets.only(top: 6.0),
        child: Row(children:[
          Icon(Icons.info_outline_rounded, color: Colors.orange, size: 17),
          SizedBox(width: 6),
          Text('المواقيت قديمة (آخر تحديث منذ $ago)', style: TextStyle(color: Colors.orange, fontSize: 13)),
        ]),
      );
    }
    // جديدة
    return SizedBox.shrink();
  }

  Timer? _timer;
  bool _screenLogged = false;

  // ADDED: per-prayer adhan toggle
  final PrefsService _prefs = PrefsService();
  final NotificationService _notificationService = NotificationService();
  final Map<String, bool> _adhanEnabled = {};
  bool _globalAdhanEnabled = true;
  bool _adhanLoaded = false;

  static const _prayerMeta = [
    {'key': 'fajr', 'icon': Icons.wb_twilight_rounded, 'name': 'fajr'},
    {'key': 'sunrise', 'icon': Icons.wb_sunny_rounded, 'name': 'sunrise'},
    {'key': 'dhuhr', 'icon': Icons.sunny, 'name': 'dhuhr'},
    {'key': 'asr', 'icon': Icons.wb_cloudy_rounded, 'name': 'asr'},
    {'key': 'maghrib', 'icon': Icons.nights_stay_rounded, 'name': 'maghrib'},
    {'key': 'isha', 'icon': Icons.brightness_3_rounded, 'name': 'isha'},
  ];

  // ADDED: per-prayer adhan toggle — prayer keys that support adhan
  static const _adhanPrayerKeys = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];

  @override
  void initState() {
    super.initState();
    _startTimer();
    _loadAdhanStates(); // ADDED: per-prayer adhan toggle
    Future<void>.microtask(() async {
      final tracker = await ref.read(streakTrackerProvider.future);
      await tracker.logActivity('salah');
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _screenLogged) return;
      _screenLogged = true;
      ref.read(analyticsServiceProvider).logScreenPrayers();
    });
  }

  // ADDED: per-prayer adhan toggle
  Future<void> _loadAdhanStates() async {
    final global = await _prefs.isAdhanNotificationsEnabled();
    final map = <String, bool>{};
    for (final key in _adhanPrayerKeys) {
      map[key] = await _prefs.isAdhanEnabled(key);
    }
    if (mounted) {
      setState(() {
        _globalAdhanEnabled = global;
        _adhanEnabled.addAll(map);
        _adhanLoaded = true;
      });
    }
  }

  // ADDED: per-prayer adhan toggle
  Future<void> _toggleAdhan(
      String prayerName, bool value, DateTime prayerTime) async {
    await _prefs.setAdhanEnabled(prayerName, value);
    setState(() => _adhanEnabled[prayerName] = value);

    if (value) {
      final sound = await _prefs.getAdhanSound();
      await _notificationService.scheduleNotification(
        id: NotificationService.getNotificationId(prayerName),
        prayerName: prayerName,
        prayerTime: prayerTime,
        soundFile: sound,
      );
    } else {
      await _notificationService.cancelNotification(
        NotificationService.getNotificationId(prayerName),
      );
    }
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
    final prayerState = ref.watch(prayerTimesControllerProvider);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F172A) : const Color(0xFFFDFBF7);
    final surface = isDark ? const Color(0xFF1E293B) : Colors.white;
    final border = isDark ? Colors.white12 : const Color(0xFFE2E8F0);
    final txtP = isDark ? Colors.white : const Color(0xFF0F172A);
    final txtS = isDark ? Colors.white60 : const Color(0xFF64748B);
    const primaryColor = Color(0xFF064E3B);
    const accentColor = Color(0xFFD97706);

    return DefaultTabController(
      initialIndex: widget.initialTabIndex.clamp(0, 1),
      length: 2,
      child: Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          toolbarHeight: 0,
          bottom: TabBar(
            tabs: [
              Tab(text: 'prayer_times'.tr()),
              Tab(text: 'my_tracking'.tr()),
            ],
            labelStyle:
                GoogleFonts.getFont('Cairo', fontWeight: FontWeight.w700),
            indicatorColor: const Color(0xFFD97706),
            labelColor: const Color(0xFF064E3B),
            unselectedLabelColor: txtS,
          ),
        ),
        body: TabBarView(
          children: [
            prayerState.when(
              skipLoadingOnRefresh: true,
              skipLoadingOnReload: true,
              data: (entity) {
                final now = DateTime.now();

                final prayersList = [
                  (key: 'fajr', time: entity.fajr),
                  (key: 'sunrise', time: entity.sunrise),
                  (key: 'dhuhr', time: entity.dhuhr),
                  (key: 'asr', time: entity.asr),
                  (key: 'maghrib', time: entity.maghrib),
                  (key: 'isha', time: entity.isha),
                ];

                var nextIdx = 0;
                DateTime? nextTime;
                for (var i = 0; i < prayersList.length; i++) {
                  if (prayersList[i].time.isAfter(now)) {
                    nextTime = prayersList[i].time;
                    nextIdx = i;
                    break;
                  }
                }
                nextTime ??= entity.fajr.add(const Duration(days: 1));

                var timeLeft = nextTime.difference(now);
                if (timeLeft.isNegative) timeLeft = Duration.zero;
                if (timeLeft.inHours > 24) timeLeft = Duration.zero;

                final hours = timeLeft.inHours.toString().padLeft(2, '0');
                final mins =
                    timeLeft.inMinutes.remainder(60).toString().padLeft(2, '0');
                final secs =
                    timeLeft.inSeconds.remainder(60).toString().padLeft(2, '0');
                final remainingTime = '$hours:$mins:$secs';

                final nextPrayerName = _prayerMeta[nextIdx]['name'] as String;
                // Get translated prayer name
                final translatedPrayerName = nextPrayerName.tr();

                return CustomScrollView(
                  slivers: [
                    SliverAppBar(
                      expandedHeight: 160,
                      pinned: true,
                      backgroundColor: primaryColor,
                      flexibleSpace: FlexibleSpaceBar(
                        background: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF064E3B),
                                Color(0xFF0a6b52),
                                Color(0xFF1a3a5c)
                              ],
                              stops: [0.0, 0.5, 1.0],
                            ),
                          ),
                          child: SafeArea(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'prayer_times'.tr(),
                                            style: GoogleFonts.getFont(
                                              'Cairo',
                                              fontSize: 20,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.white,
                                            ),
                                          ),
                                          Text(
                                            entity.locationName,
                                            style: GoogleFonts.getFont(
                                              'Cairo',
                                              fontSize: 13,
                                              color: Colors.white60,
                                            ),
                                          ),
                                          _buildStaleIndicator(entity),
                                        ],
                                      ),
                                      // Settings icon
                                      Row(
                                        children: [
                                          const StreakBadge(
                                              featureKey: 'salah'),
                                          const SizedBox(width: 8),
                                          GestureDetector(
                                            onTap: () => Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) =>
                                                    const SalahNotificationSettings(),
                                              ),
                                            ),
                                            child: Container(
                                              width: 38,
                                              height: 38,
                                              decoration: BoxDecoration(
                                                color: Colors.white
                                                    .withValues(alpha: 0.1),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons
                                                    .notifications_active_rounded,
                                                color: Colors.white70,
                                                size: 18,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          GestureDetector(
                                            onLongPress: () async {
                                              final pending =
                                                  await NotificationService()
                                                      .getPendingNotifications();
                                              if (!context.mounted) return;
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                    content: Text(
                                                        'Pending: ${pending.length}')),
                                              );
                                            },
                                            onTap: () => Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (_) =>
                                                      const PrayerSettingsPage()),
                                            ),
                                            child: Container(
                                              width: 38,
                                              height: 38,
                                              decoration: BoxDecoration(
                                                color: Colors.white
                                                    .withValues(alpha: 0.1),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.settings_rounded,
                                                color: Colors.white70,
                                                size: 18,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  // Next Prayer Highlight
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.access_time_rounded,
                                          color: Color(0xFFFCD34D),
                                          size: 16,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          context.locale.languageCode == 'tr'
                                              ? '$translatedPrayerName için $remainingTime'
                                              : '$translatedPrayerName بعد $remainingTime',
                                          style: GoogleFonts.getFont(
                                            'Cairo',
                                            fontSize: 13,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.all(16),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          ...List.generate(_prayerMeta.length, (i) {
                            final meta = _prayerMeta[i];
                            final key = meta['key']
                                as String; // ADANGED: extracted for toggle
                            final name = meta['name'] as String;
                            final iconData = meta['icon'] as IconData;
                            final time = prayersList[i].time;
                            final isNext = i == nextIdx;
                            final isAdhanPrayer = _adhanPrayerKeys.contains(
                                key); // ADDED: per-prayer adhan toggle

                            final formattedTime =
                                TimeUtils.formatPrayerTime(time, context);

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              decoration: BoxDecoration(
                                color: isNext
                                    ? primaryColor.withValues(alpha: 0.08)
                                    : surface,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isNext
                                      ? primaryColor.withValues(alpha: 0.3)
                                      : border,
                                  width: isNext ? 1.5 : 0.5,
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 36,
                                        height: 36,
                                        decoration: BoxDecoration(
                                          color: isNext
                                              ? primaryColor
                                              : primaryColor.withValues(alpha: 0.08),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          iconData,
                                          color: isNext
                                              ? Colors.white
                                              : primaryColor,
                                          size: 16,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        name.tr(),
                                        style: GoogleFonts.getFont(
                                          'Cairo',
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: isNext ? primaryColor : txtP,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        formattedTime,
                                        style: GoogleFonts.getFont(
                                          'Cairo',
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: isNext ? primaryColor : txtP,
                                        ),
                                      ),
                                      if (isNext) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: accentColor,
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            'next_prayer'.tr(),
                                            style: GoogleFonts.getFont(
                                              'Cairo',
                                              fontSize: 9,
                                              color: Colors.white,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ],
                                      // ADDED: per-prayer adhan toggle
                                      if (isAdhanPrayer) ...[
                                        const SizedBox(width: 4),
                                        SizedBox(
                                          height: 28,
                                          child: Transform.scale(
                                            scale: 0.8,
                                            child: Switch(
                                              value: _adhanLoaded &&
                                                  _adhanEnabled[key] == true,
                                              onChanged: _globalAdhanEnabled
                                                  ? (v) =>
                                                      _toggleAdhan(key, v, time)
                                                  : null,
                                              activeColor: primaryColor,
                                              inactiveThumbColor: txtS,
                                              materialTapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            );
                          }),
                          const SizedBox(height: 16),
                          // Qiblah Button
                          GestureDetector(
                            onTap: () {
                              ref
                                  .read(analyticsServiceProvider)
                                  .logQiblahOpen();
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const QiblahPage()),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: surface,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: border, width: 0.5),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: primaryColor.withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.explore_rounded,
                                        color: primaryColor, size: 22),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'qiblah_direction'.tr(),
                                          style: GoogleFonts.getFont(
                                            'Cairo',
                                            fontSize: 15,
                                            fontWeight: FontWeight.w700,
                                            color: txtP,
                                          ),
                                        ),
                                        Text(
                                          'find_qibla_direction'.tr(),
                                          style: GoogleFonts.getFont(
                                            'Cairo',
                                            fontSize: 12,
                                            color: txtS,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.arrow_forward_ios_rounded,
                                      color: txtS, size: 14),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                        ]),
                      ),
                    ),
                  ],
                );
              },
              error: (e, _) => Center(
                  child: Text('Error: $e', style: TextStyle(color: txtP))),
              loading: () => const Center(
                  child: CircularProgressIndicator(color: primaryColor)),
            ),
            const IbadahTrackerTab(),
          ],
        ),
      ),
    );
  }
}
