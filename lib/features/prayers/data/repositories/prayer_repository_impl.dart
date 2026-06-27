import 'dart:async';
import 'package:flutter/foundation.dart';
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
    final prefs = PrefsService();
    final now = DateTime.now();
    var methodString = await prefs.getCalculationMethod();
    final isAuto = await prefs.isAutoLocation();

    // 1. FAST PATH: Check memory cache first
    if (_cachedPrayerTimes != null && _isFresh(_cachedPrayerTimesAt, _prayerTimesTtl)) {
      debugPrint('⏱ [PRAYER-CACHE] Using IN-MEMORY cache (0ms)');
      if (isAuto) {
        unawaited(_refreshLocationInBackground(prefs, methodString));
      }
      return _cachedPrayerTimes!;
    }

    // 2. FAST PATH: Use stored location for instant calculation
    final stored = await prefs.getStoredLocation();
    if (stored != null) {
      debugPrint('⏱ [PRAYER-CACHE] Using STORED LOCATION cache');
      final lat = stored['lat'] as double;
      final long = stored['long'] as double;
      final city = stored['city'] as String;
      final countryCode = stored['countryCode'] as String? ?? 'TR';
      
      final result = _calculatePrayerTimesLocally(
        lat: lat, 
        long: long, 
        city: city, 
        countryCode: countryCode, 
        method: methodString,
        isAuto: isAuto,
      );

      // Trigger background refresh if auto location is enabled
      if (isAuto) {
        unawaited(_refreshLocationInBackground(prefs, methodString));
      }

      return result;
    }

    // 3. FRESH INSTALL PATH (No stored location yet)
    debugPrint('⏱ [PRAYER-CACHE] NO CACHE FOUND. Awaiting actual GPS location (Fresh Install)...');
    
    // We await the background refresh so the UI shows a loading spinner
    // instead of showing wrong default data.
    await _refreshLocationInBackground(prefs, methodString);

    if (_cachedPrayerTimes != null) {
      return _cachedPrayerTimes!;
    }

    // If we reach here, GPS failed (e.g. permission denied or timeout)
    debugPrint('⏱ [PRAYER-CACHE] GPS failed. Using fallback (Mecca).');
    return _calculatePrayerTimesLocally(
      lat: 21.4225, // Mecca
      long: 39.8262,
      city: '⚠️ يرجى تفعيل الموقع', // "Please enable location" with warning
      countryCode: 'SA',
      method: 'mekka',
      isAuto: isAuto,
    );
  }

  Future<void> _refreshLocationInBackground(PrefsService prefs, String methodString) async {
    try {
      final locService = LocationService();
      final now = DateTime.now();

      if (_lastAutoLocationFetchAt != null &&
          now.difference(_lastAutoLocationFetchAt!) <= _autoLocationDebounce) {
        return;
      }

      // Add a 10-second timeout to prevent infinite hanging
      final position = await locService.determinePosition().timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw TimeoutException('GPS request timed out after 10s'),
      );
      final newLat = position.latitude;
      final newLong = position.longitude;

      bool locationChanged = true;
      if (_lastResolvedLat != null && _lastResolvedLong != null) {
        final movedMeters = Geolocator.distanceBetween(
          _lastResolvedLat!,
          _lastResolvedLong!,
          newLat,
          newLong,
        );
        locationChanged = movedMeters >= _significantLocationChangeMeters;
      }

      if (locationChanged || _lastResolvedCity == null) {
        final locationInfo = await locService.getLocationInfo(newLat, newLong);
        final city = locationInfo['city'] ?? 'موقع غير معروف';
        final countryCode = locationInfo['countryCode'] ?? 'SA';

        _lastResolvedLat = newLat;
        _lastResolvedLong = newLong;
        _lastResolvedCity = city;
        _lastResolvedCountryCode = countryCode;

        final oldCountryCode = await prefs.getCountryCode();
        if (oldCountryCode != countryCode) {
          final autoMethod = _getMethodForCountry(countryCode);
          await prefs.setCalculationMethod(autoMethod);
          await prefs.saveCountryCode(countryCode);
          methodString = autoMethod;
        }

        await prefs.saveManualLocation(newLat, newLong, city, countryCode: countryCode);
        await prefs.setAutoLocation(true);
        
        _calculatePrayerTimesLocally(
          lat: newLat,
          long: newLong,
          city: city,
          countryCode: countryCode,
          method: methodString,
          isAuto: true,
        );
      }
      
      _lastAutoLocationFetchAt = now;

    } catch (e) {
      debugPrint('Background Location Error: $e');
      // If there's an error (like permission denied) and we have absolutely no cache,
      // the caller will handle the fallback. We just catch and log it.
    }
  }

  PrayerTimesEntity _calculatePrayerTimesLocally({
    required double lat,
    required double long,
    required String city,
    required String countryCode,
    required String method,
    required bool isAuto,
  }) {
    final params = _getCalculationParams(method);
    final myCoordinates = Coordinates(lat, long);
    final now = DateTime.now();
    final date = DateComponents.from(now);
    final utcOffset = now.timeZoneOffset;

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
      calculationMethod: method,
      lastUpdated: now,
    );

    final resolvedCacheKey = _buildCacheKey(
      date: now,
      method: method,
      isAuto: isAuto,
      lat: lat,
      long: long,
    );

    _cachedPrayerTimes = result;
    _cachedPrayerTimesAt = now;
    _cachedPrayerTimesKey = resolvedCacheKey;

    return result;
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
