import 'dart:convert';
import 'package:adhan/adhan.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:sila_app/core/services/location_service.dart';
import 'package:sila_app/core/services/prefs_service.dart';
import 'package:sila_app/features/prayers/domain/entities/prayer_times_entity.dart';
import 'package:sila_app/features/prayers/domain/repositories/prayer_repository.dart';

class PrayerRepositoryImpl extends PrayerRepository {
  // Default Location: Istanbul, Turkey (fallback)
  static const double _defaultLat = 41.0082;
  static const double _defaultLong = 28.9784;
  static String get _defaultCity => 'unknown_location'.tr();

  @override
  Future<PrayerTimesEntity> getPrayerTimes() async {
    final prefs = PrefsService();
    
    // 1. Try to get from cache first
    try {
      final cachedJson = await prefs.getPrayerTimesCache();
      final lastFetch = await prefs.getPrayerTimesLastFetch();
      final now = DateTime.now();
      
      if (cachedJson != null && lastFetch != null) {
        // Cache is valid if it's the same day AND less than 12 hours old
        final isSameDay = lastFetch.year == now.year && 
                          lastFetch.month == now.month && 
                          lastFetch.day == now.day;
        final isRecent = now.difference(lastFetch).inHours < 12;
        
        if (isSameDay && isRecent) {
          return PrayerTimesEntity.fromJson(jsonDecode(cachedJson));
        }
      }
    } catch (e) {
      print('Cache Read Error: $e');
    }

    // 2. If no valid cache, fetch fresh
    final locService = LocationService();

    var lat = _defaultLat;
    var long = _defaultLong;
    var city = _defaultCity;
    var countryCode = 'TR';

    // Get location
    try {
      final isAuto = await prefs.isAutoLocation();
      final oldCountryCode = await prefs.getCountryCode();

      if (isAuto) {
        final position = await locService.determinePosition();
        lat = position.latitude;
        long = position.longitude;
        final locationInfo = await locService.getLocationInfo(lat, long);
        city = locationInfo['city'] ?? _defaultCity;
        countryCode = locationInfo['countryCode'] ?? 'TR';

        if (oldCountryCode != countryCode) {
          final autoMethod = _getMethodForCountry(countryCode);
          await prefs.setCalculationMethod(autoMethod);
          await prefs.saveCountryCode(countryCode);
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
          }
        }
      }
    } catch (e) {
      print('Location Error: $e');
    }

    final methodString = await prefs.getCalculationMethod();
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

    final entity = PrayerTimesEntity(
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
    );

    // 3. Save to cache
    try {
      await prefs.savePrayerTimesCache(jsonEncode(entity.toJson()));
    } catch (e) {
      print('Cache Save Error: $e');
    }

    return entity;
  }

  @override
  Future<Prayer> getNextPrayer() async {
    final times = await getPrayerTimes();
    final now = DateTime.now();

    final prayers = [
      (prayer: Prayer.fajr, time: times.fajr),
      (prayer: Prayer.sunrise, time: times.sunrise),
      (prayer: Prayer.dhuhr, time: times.dhuhr),
      (prayer: Prayer.asr, time: times.asr),
      (prayer: Prayer.maghrib, time: times.maghrib),
      (prayer: Prayer.isha, time: times.isha),
    ];

    for (final p in prayers) {
      if (p.time.isAfter(now)) {
        return p.prayer;
      }
    }

    return Prayer.fajr; // For tomorrow
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
