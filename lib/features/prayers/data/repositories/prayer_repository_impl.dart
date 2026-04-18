import 'package:adhan/adhan.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:geolocator/geolocator.dart';
import 'package:sila_app/core/services/location_service.dart';
import 'package:sila_app/core/services/prefs_service.dart';
import 'package:sila_app/features/prayers/domain/entities/prayer_times_entity.dart';
import 'package:sila_app/features/prayers/domain/repositories/prayer_repository.dart';

class PrayerRepositoryImpl extends PrayerRepository {
  // Default Location: Istanbul, Turkey (fallback)
  static const double _defaultLat = 41.0082;
  static const double _defaultLong = 28.9784;
  static String get _defaultCity => 'unknown_location'.tr();

  // Warm-start cache and fetch discipline
  static const Duration _prayerTimesTtl = Duration(minutes: 20);
  static const Duration _autoLocationDebounce = Duration(minutes: 2);
  static const double _significantLocationChangeMeters = 750;

  static PrayerTimesEntity? _cachedPrayerTimes;
  static DateTime? _cachedPrayerTimesAt;
  static String? _cachedPrayerTimesKey;

  /// Public getter for the cached prayer times (for use by providers)
  static PrayerTimesEntity? get cachedPrayerTimes {
  if (_cachedPrayerTimes == null || _cachedPrayerTimesAt == null) return null;
  // أعد نسخة مع lastUpdated: وقت آخر تحديث من الكاش
  return PrayerTimesEntity(
    fajr: _cachedPrayerTimes!.fajr,
    sunrise: _cachedPrayerTimes!.sunrise,
    dhuhr: _cachedPrayerTimes!.dhuhr,
    asr: _cachedPrayerTimes!.asr,
    maghrib: _cachedPrayerTimes!.maghrib,
    isha: _cachedPrayerTimes!.isha,
    locationName: _cachedPrayerTimes!.locationName,
    latitude: _cachedPrayerTimes!.latitude,
    longitude: _cachedPrayerTimes!.longitude,
    countryCode: _cachedPrayerTimes!.countryCode,
    calculationMethod: _cachedPrayerTimes!.calculationMethod,
    lastUpdated: _cachedPrayerTimesAt!,
  );
}

  static Prayer? _cachedNextPrayer;
  static DateTime? _cachedNextPrayerAt;

  static DateTime? _lastAutoLocationFetchAt;
  static double? _lastResolvedLat;
  static double? _lastResolvedLong;
  static String? _lastResolvedCity;
  static String? _lastResolvedCountryCode;

  Duration get prayerTimesCacheTtl => _prayerTimesTtl;

  bool _isFresh(DateTime? value, Duration ttl) {
    if (value == null) return false;
    return DateTime.now().difference(value) <= ttl;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _dayKey(DateTime date) => '${date.year}-${date.month}-${date.day}';

  String _buildCacheKey({
    required DateTime date,
    required String method,
    required bool isAuto,
    required double lat,
    required double long,
  }) {
    return '${_dayKey(date)}|$method|$isAuto|${lat.toStringAsFixed(3)}|${long.toStringAsFixed(3)}';
  }

  bool isPrayerCacheStale() {
    if (_cachedPrayerTimes == null) return true;
    if (!_isFresh(_cachedPrayerTimesAt, _prayerTimesTtl)) return true;
    return !_isSameDay(DateTime.now(), _cachedPrayerTimes!.fajr);
  }

  void clearCache() {
    _cachedPrayerTimes = null;
    _cachedPrayerTimesAt = null;
    _cachedPrayerTimesKey = null;
    _cachedNextPrayer = null;
    _cachedNextPrayerAt = null;
    _lastAutoLocationFetchAt = null;
    _lastResolvedLat = null;
    _lastResolvedLong = null;
    _lastResolvedCity = null;
    _lastResolvedCountryCode = null;
  }

  Prayer _resolveNextPrayer(PrayerTimesEntity entity) {
    final now = DateTime.now();
    if (entity.fajr.isAfter(now)) return Prayer.fajr;
    if (entity.sunrise.isAfter(now)) return Prayer.sunrise;
    if (entity.dhuhr.isAfter(now)) return Prayer.dhuhr;
    if (entity.asr.isAfter(now)) return Prayer.asr;
    if (entity.maghrib.isAfter(now)) return Prayer.maghrib;
    if (entity.isha.isAfter(now)) return Prayer.isha;
    return Prayer.fajr;
  }

  @override
  Future<PrayerTimesEntity> getPrayerTimes() async {
    final locService = LocationService();
    final prefs = PrefsService();

    final now = DateTime.now();
    var methodString = await prefs.getCalculationMethod();
    final isAuto = await prefs.isAutoLocation();

    var lat = _defaultLat;
    var long = _defaultLong;
    var city = _defaultCity;
    var countryCode = 'TR';

    try {
      final oldCountryCode = await prefs.getCountryCode();

      if (isAuto) {
        final canReuseRecentAutoLocation =
            _lastResolvedLat != null &&
            _lastResolvedLong != null &&
            _lastAutoLocationFetchAt != null &&
            now.difference(_lastAutoLocationFetchAt!) <= _autoLocationDebounce;

        if (canReuseRecentAutoLocation) {
          lat = _lastResolvedLat!;
          long = _lastResolvedLong!;
          city = _lastResolvedCity ?? _defaultCity;
          countryCode = _lastResolvedCountryCode ?? oldCountryCode;
        } else {
           Position? position;
           try {
             position = await locService.determinePosition().timeout(const Duration(seconds: 1));
           } catch (_) {
             position = null;
           }
           final newLat = position?.latitude ?? _defaultLat;
           final newLong = position?.longitude ?? _defaultLong;

          if (_lastResolvedLat != null && _lastResolvedLong != null) {
            final movedMeters = Geolocator.distanceBetween(
              _lastResolvedLat!,
              _lastResolvedLong!,
              newLat,
              newLong,
            );

            if (movedMeters < _significantLocationChangeMeters &&
                _lastResolvedCity != null &&
                _lastResolvedCountryCode != null) {
              lat = _lastResolvedLat!;
              long = _lastResolvedLong!;
              city = _lastResolvedCity!;
              countryCode = _lastResolvedCountryCode!;
            } else {
              lat = newLat;
              long = newLong;
               Map<String, dynamic> locationInfo = {};
               try {
                 locationInfo = await locService.getLocationInfo(lat, long).timeout(const Duration(seconds: 1));
               } catch (_) {
                 locationInfo = {};
               }
               city = locationInfo['city'] ?? _defaultCity;
               countryCode = locationInfo['countryCode'] ?? 'TR';
            }
          } else {
            lat = newLat;
            long = newLong;
            final locationInfo = await locService.getLocationInfo(lat, long);
            city = locationInfo['city'] ?? _defaultCity;
            countryCode = locationInfo['countryCode'] ?? 'TR';
          }

          _lastResolvedLat = lat;
          _lastResolvedLong = long;
          _lastResolvedCity = city;
          _lastResolvedCountryCode = countryCode;
          _lastAutoLocationFetchAt = now;
        }

        if (oldCountryCode != countryCode) {
          final autoMethod = _getMethodForCountry(countryCode);
          await prefs.setCalculationMethod(autoMethod);
          await prefs.saveCountryCode(countryCode);
          methodString = autoMethod;
        }
      } else {
        final stored = await prefs.getStoredLocation();
        if (stored != null) {
          lat = stored['lat'] as double;
          long = stored['long'] as double;
          city = stored['city'] as String;
          countryCode = stored['countryCode'] as String? ?? 'TR';

          if (oldCountryCode != countryCode) {
            final autoMethod = _getMethodForCountry(countryCode);
            await prefs.setCalculationMethod(autoMethod);
            await prefs.saveCountryCode(countryCode);
            methodString = autoMethod;
          }
        }
      }
    } catch (e) {
      print('Location Error: $e');
    }

    final resolvedCacheKey = _buildCacheKey(
      date: now,
      method: methodString,
      isAuto: isAuto,
      lat: lat,
      long: long,
    );

    // INSTANT CACHE FIRST RETURN (even if stale, as long as same day/location/method)
    if (_cachedPrayerTimes != null &&
        _cachedPrayerTimesKey == resolvedCacheKey &&
        _isSameDay(now, _cachedPrayerTimes!.fajr)) {
      // Schedule background update if cache is stale (older than TTL)
      if (!_isFresh(_cachedPrayerTimesAt, _prayerTimesTtl)) {
        // ignore: unawaited_futures
        _backgroundRefresh(
          lat: lat,
          long: long,
          city: city,
          countryCode: countryCode,
          methodString: methodString,
          resolvedCacheKey: resolvedCacheKey,
        );
      }
      return _cachedPrayerTimes!;
    }

    // No cache: do blocking calculation
    final params = _getCalculationParams(methodString);
    final myCoordinates = Coordinates(lat, long);
    final date = DateComponents.from(DateTime.now());
    final utcOffset = DateTime.now().timeZoneOffset;

    final prayerTimes = PrayerTimes(
      myCoordinates,
      date,
      params,
      utcOffset: utcOffset,
    );

    DateTime toLocal(DateTime dt) {
      return DateTime(dt.year, dt.month, dt.day, dt.hour, dt.minute, dt.second);
    }

    final result = PrayerTimesEntity(
      fajr: toLocal(prayerTimes.fajr),
      sunrise: toLocal(prayerTimes.sunrise),
      dhuhr: toLocal(prayerTimes.dhuhr),
      asr: toLocal(prayerTimes.asr),
      maghrib: toLocal(prayerTimes.maghrib),
      isha: toLocal(prayerTimes.isha),
      locationName: city,
      latitude: lat,
      longitude: long,
      countryCode: countryCode,
      calculationMethod: methodString,
      lastUpdated: DateTime.now(),
    );

    _cachedPrayerTimes = result;
    _cachedPrayerTimesAt = DateTime.now();
    _cachedPrayerTimesKey = resolvedCacheKey;

    return result;
  }

  /// Performs background refresh (async, does NOT block UI)
  Future<void> _backgroundRefresh({
    required double lat,
    required double long,
    required String city,
    required String countryCode,
    required String methodString,
    required String resolvedCacheKey,
  }) async {
    try {
      final params = _getCalculationParams(methodString);
      final myCoordinates = Coordinates(lat, long);
      final date = DateComponents.from(DateTime.now());
      final utcOffset = DateTime.now().timeZoneOffset;
      final prayerTimes = PrayerTimes(
        myCoordinates,
        date,
        params,
        utcOffset: utcOffset,
      );
      DateTime toLocal(DateTime dt) {
        return DateTime(dt.year, dt.month, dt.day, dt.hour, dt.minute, dt.second);
      }
      final result = PrayerTimesEntity(
        fajr: toLocal(prayerTimes.fajr),
        sunrise: toLocal(prayerTimes.sunrise),
        dhuhr: toLocal(prayerTimes.dhuhr),
        asr: toLocal(prayerTimes.asr),
        maghrib: toLocal(prayerTimes.maghrib),
        isha: toLocal(prayerTimes.isha),
        locationName: city,
        latitude: lat,
        longitude: long,
        countryCode: countryCode,
        calculationMethod: methodString,
        lastUpdated: DateTime.now(),
      );
      _cachedPrayerTimes = result;
      _cachedPrayerTimesAt = DateTime.now();
      _cachedPrayerTimesKey = resolvedCacheKey;
      // Optional: notify listeners/UI here if you want
      print('Prayer times background-refreshed at [32m[1m"+DateTime.now().toString()+"\u001b[0m');
    } catch (e) {
      print('Background refresh error: $e');
    }
  }

  @override
  Future<Prayer> getNextPrayer() async {
    if (_cachedPrayerTimes != null &&
        _isFresh(_cachedPrayerTimesAt, _prayerTimesTtl) &&
        _isSameDay(DateTime.now(), _cachedPrayerTimes!.fajr)) {
      return _resolveNextPrayer(_cachedPrayerTimes!);
    }

    if (_cachedNextPrayer != null && _isFresh(_cachedNextPrayerAt, const Duration(minutes: 1))) {
      return _cachedNextPrayer!;
    }

    final entity = await getPrayerTimes();
    final next = _resolveNextPrayer(entity);
    _cachedNextPrayer = next;
    _cachedNextPrayerAt = DateTime.now();
    return next;
  }

  /// Automatically pick the correct calculation method for a given country.
  String _getMethodForCountry(String countryCode) {
    switch (countryCode.toUpperCase()) {
      case 'TR': // Turkey
        return 'turkey';
      case 'EG': // Egypt
        return 'egyptian';
      case 'SA': // Saudi Arabia
        return 'umm_al_qura';
      case 'MA': // Morocco
        return 'morocco';
      case 'ID': // Indonesia
        return 'indonesia';
      case 'IN': // India
        return 'north_america'; // ISNA is widely used in India too
      case 'US': // USA
      case 'CA': // Canada
        return 'north_america';
      case 'PK': // Pakistan
        return 'karachi';
      case 'MY': // Malaysia
      case 'SG': // Singapore
        return 'singapore';
      case 'AE': // UAE
        return 'dubai';
      case 'QA': // Qatar
        return 'qatar';
      case 'KW': // Kuwait
        return 'kuwait';
      default:
        return 'muslim_world_league';
    }
  }

  /// Map method string to CalculationParameters
  CalculationParameters _getCalculationParams(String method) {
    CalculationParameters params;

    switch (method.toLowerCase()) {
      case 'muslim_world_league':
        params = CalculationMethod.muslim_world_league.getParameters();
        break;
      case 'egyptian':
        params = CalculationMethod.egyptian.getParameters();
        break;
      case 'karachi':
        params = CalculationMethod.karachi.getParameters();
        break;
      case 'umm_al_qura':
        params = CalculationMethod.umm_al_qura.getParameters();
        break;
      case 'dubai':
        params = CalculationMethod.dubai.getParameters();
        break;
      case 'qatar':
        params = CalculationMethod.qatar.getParameters();
        break;
      case 'kuwait':
        params = CalculationMethod.kuwait.getParameters();
        break;
      case 'singapore':
        params = CalculationMethod.singapore.getParameters();
        break;
      case 'north_america':
        params = CalculationMethod.north_america.getParameters();
        break;
      case 'morocco':
        // Morocco: Fajr angle 19°, Isha angle 17° (Moroccan Ministry)
        params = CalculationParameters(fajrAngle: 19.0, ishaAngle: 17.0);
        break;
      case 'indonesia':
        // Indonesia KEMENAG: Fajr angle 20°, Isha angle 18°
        params = CalculationParameters(fajrAngle: 20.0, ishaAngle: 18.0);
        params.madhab = Madhab.shafi;
        break;
      case 'turkey':
      default:
        params = CalculationMethod.turkey.getParameters();
    }

    return params;
  }
}
