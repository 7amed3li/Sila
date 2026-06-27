import 'package:equatable/equatable.dart';

class PrayerTimesEntity extends Equatable {
  // e.g. "turkey", "egyptian"

  const PrayerTimesEntity({
    required this.fajr,
    required this.sunrise,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
    required this.locationName,
    required this.latitude,
    required this.longitude,
    this.countryCode = 'TR',
    this.calculationMethod = 'turkey',
    required this.lastUpdated,
  });
  final DateTime fajr;
  final DateTime sunrise;
  final DateTime dhuhr;
  final DateTime asr;
  final DateTime maghrib;
  final DateTime isha;
  final String locationName;
  final double latitude;
  final double longitude;
  final String countryCode; // e.g. "TR", "EG", "SA"
  final String calculationMethod;
  final DateTime lastUpdated;

  // محسوبة: تعتبر المواقيت قديمة إذا مضى على آخر تحديث أكثر من 24 ساعة
  bool isStaleAt(DateTime now) => now.difference(lastUpdated).inHours >= 24;

  @override
  List<Object?> get props => [
        fajr,
        sunrise,
        dhuhr,
        asr,
        maghrib,
        isha,
        locationName,
        latitude,
        longitude,
        countryCode,
        calculationMethod,
        lastUpdated,
      ];
}
