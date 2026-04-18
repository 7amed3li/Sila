import 'dart:async';

import 'package:adhan/adhan.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sila_app/features/prayers/data/repositories/prayer_repository_impl.dart';
import 'package:sila_app/features/prayers/domain/entities/prayer_times_entity.dart';

part 'prayer_controller.g.dart';

@Riverpod(keepAlive: true)
PrayerRepositoryImpl prayerRepository(PrayerRepositoryRef ref) {
  return PrayerRepositoryImpl();
}

@Riverpod(keepAlive: true)
class PrayerTimesController extends _$PrayerTimesController {
  Timer? _staleCheckTimer;

  @override
  FutureOr<PrayerTimesEntity> build() async {
    final repository = ref.watch(prayerRepositoryProvider);
    _scheduleStaleCheck();
    ref.onDispose(() => _staleCheckTimer?.cancel());

    // جلب بيانات cache فوراً (حتى لو قديمة)
    final cached = PrayerRepositoryImpl.cachedPrayerTimes;
    if (cached != null) {
      // في الخلفية: حدث المواقيت، عند نجاح التحديث invalidation ليتم rebuild تلقائي
      unawaited(_refreshInBackground(repository));
      return cached;
    } else {
      // لا بيانات cache إطلاقاً، اعرض placeholder (بيانات افتراضية مكان إسطنبول)
      final now = DateTime.now();
      final placeholder = PrayerTimesEntity(
        fajr: now,
        sunrise: now.add(const Duration(hours: 6)),
        dhuhr: now.add(const Duration(hours: 12)),
        asr: now.add(const Duration(hours: 15)),
        maghrib: now.add(const Duration(hours: 18)),
        isha: now.add(const Duration(hours: 19, minutes: 30)),
        locationName: "…جاري التحميل",
        latitude: 41.0082,
        longitude: 28.9784,
        countryCode: "TR",
        calculationMethod: "turkey",
        lastUpdated: DateTime.fromMillisecondsSinceEpoch(0), // يعتبر أقدم شيء
      );
      unawaited(_refreshInBackground(repository));
      return placeholder;
    }
  }

  Future<void> _refreshInBackground(PrayerRepositoryImpl repository) async {
    await repository.getPrayerTimes();
    ref.invalidateSelf();
  }

  void _scheduleStaleCheck() {
    _staleCheckTimer?.cancel();

    final repository = ref.read(prayerRepositoryProvider);
    final ttl = repository.prayerTimesCacheTtl;
    final midnightDelay = _timeUntilNextLocalMidnight();

    var nextDelay = ttl <= midnightDelay ? ttl : midnightDelay;
    if (nextDelay <= Duration.zero) {
      nextDelay = const Duration(seconds: 1);
    }

    _staleCheckTimer = Timer(nextDelay, () {
      final repository = ref.read(prayerRepositoryProvider);
      if (repository.isPrayerCacheStale()) {
        ref.invalidateSelf();
      } else {
        _scheduleStaleCheck();
      }
    });
  }

  Duration _timeUntilNextLocalMidnight() {
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    return nextMidnight.difference(now);
  }

  Future<void> refreshIfStale() async {
    final repository = ref.read(prayerRepositoryProvider);
    if (repository.isPrayerCacheStale()) {
      ref.invalidateSelf();
      await future;
    }
  }

  Future<void> forceRefresh() async {
    final repository = ref.read(prayerRepositoryProvider);
    repository.clearCache();
    ref.invalidate(nextPrayerControllerProvider);
    ref.invalidateSelf();
    await future;
  }
}

@Riverpod(keepAlive: true)
class NextPrayerController extends _$NextPrayerController {
  Timer? _nextPrayerBoundaryTimer;

  @override
  FutureOr<Prayer> build() async {
    ref.onDispose(() => _nextPrayerBoundaryTimer?.cancel());

    final prayerTimes = await ref.watch(prayerTimesControllerProvider.future);
    final repository = ref.watch(prayerRepositoryProvider);
    final nextPrayer = await repository.getNextPrayer();
    _scheduleBoundaryRefresh(prayerTimes, nextPrayer);
    return nextPrayer;
  }

  Future<void> refreshFromPrayerTimes() async {
    await ref.read(prayerTimesControllerProvider.notifier).refreshIfStale();
    ref.invalidateSelf();
    await future;
  }

  void _scheduleBoundaryRefresh(PrayerTimesEntity entity, Prayer nextPrayer) {
    _nextPrayerBoundaryTimer?.cancel();

    final now = DateTime.now();
    var boundary = _boundaryForPrayer(entity, nextPrayer);
    if (!boundary.isAfter(now)) {
      boundary = boundary.add(const Duration(days: 1));
    }

    var delay = boundary.difference(now) + const Duration(seconds: 1);
    if (delay.isNegative || delay == Duration.zero) {
      delay = const Duration(seconds: 1);
    }

    _nextPrayerBoundaryTimer = Timer(delay, () {
      ref.invalidateSelf();
    });
  }

  DateTime _boundaryForPrayer(PrayerTimesEntity entity, Prayer prayer) {
    return switch (prayer) {
      Prayer.fajr => entity.fajr,
      Prayer.sunrise => entity.sunrise,
      Prayer.dhuhr => entity.dhuhr,
      Prayer.asr => entity.asr,
      Prayer.maghrib => entity.maghrib,
      Prayer.isha => entity.isha,
      _ => entity.fajr.add(const Duration(days: 1)),
    };
  }
}
