import 'package:equatable/equatable.dart';

class PrayerTimesEntity extends Equatable { // e.g. "turkey", "egyptian"

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
  final String countryCode;        // e.g. "TR", "EG", "SA"
  final String calculationMethod;

  factory PrayerTimesEntity.fromJson(Map<String, dynamic> json) {
    return PrayerTimesEntity(
      fajr: DateTime.parse(json['fajr']),
      sunrise: DateTime.parse(json['sunrise']),
      dhuhr: DateTime.parse(json['dhuhr']),
      asr: DateTime.parse(json['asr']),
      maghrib: DateTime.parse(json['maghrib']),
      isha: DateTime.parse(json['isha']),
      locationName: json['locationName'],
      latitude: json['latitude'],
      longitude: json['longitude'],
      countryCode: json['countryCode'] ?? 'TR',
      calculationMethod: json['calculationMethod'] ?? 'turkey',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fajr': fajr.toIso8601String(),
      'sunrise': sunrise.toIso8601String(),
      'dhuhr': dhuhr.toIso8601String(),
      'asr': asr.toIso8601String(),
      'maghrib': maghrib.toIso8601String(),
      'isha': isha.toIso8601String(),
      'locationName': locationName,
      'latitude': latitude,
      'longitude': longitude,
      'countryCode': countryCode,
      'calculationMethod': calculationMethod,
    };
  }

  @override
  List<Object?> get props => [
    fajr, sunrise, dhuhr, asr, maghrib, isha,
    locationName, latitude, longitude, countryCode, calculationMethod,
  ];
}
