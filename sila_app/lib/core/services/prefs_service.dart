import 'package:shared_preferences/shared_preferences.dart';

class PrefsService {
  static const String _keyIsAutoLocation = 'is_auto_location';
  static const String _keyLat = 'latitude';
  static const String _keyLong = 'longitude';
  static const String _keyCity = 'city_name';
  static const String _keyCountryCode = 'country_code';
  static const String _keyCalculationMethod = 'calculation_method';
  static const String _keyAdhanNotificationsEnabled =
      'adhan_notifications_enabled';
  static const String _keyAdhanSound = 'adhan_sound';
  static const String _keyNeverShowNotificationPrompt =
      'never_show_notification_prompt';
  static const String _keyPrayerTimesCache = 'prayer_times_cache';
  static const String _keyPrayerTimesLastFetch = 'prayer_times_last_fetch';

  // PERF FIX 4: Cache SharedPreferences instance to avoid re-fetching on every call
  static SharedPreferences? _prefs;
  Future<SharedPreferences> get _instance async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<bool> getNeverShowNotificationPrompt() async {
    final prefs = await _instance; // PERF FIX 4
    return prefs.getBool(_keyNeverShowNotificationPrompt) ?? false;
  }

  Future<void> setNeverShowNotificationPrompt(bool value) async {
    final prefs = await _instance; // PERF FIX 4
    await prefs.setBool(_keyNeverShowNotificationPrompt, value);
  }

  // ─── Location ────────────────────────────────────────────────────────────

  Future<void> setAutoLocation(bool value) async {
    final prefs = await _instance; // PERF FIX 4
    await prefs.setBool(_keyIsAutoLocation, value);
    await clearPrayerTimesCache();
  }

  Future<bool> isAutoLocation() async {
    final prefs = await _instance; // PERF FIX 4
    return prefs.getBool(_keyIsAutoLocation) ?? true;
  }

  Future<void> saveManualLocation(
    double lat,
    double long,
    String cityName, {
    String countryCode = 'XX',
  }) async {
    final prefs = await _instance; // PERF FIX 4
    await prefs.setDouble(_keyLat, lat);
    await prefs.setDouble(_keyLong, long);
    await prefs.setString(_keyCity, cityName);
    await prefs.setString(_keyCountryCode, countryCode);
    await prefs.setBool(_keyIsAutoLocation, false);
    await clearPrayerTimesCache();
  }

  Future<Map<String, dynamic>?> getStoredLocation() async {
    final prefs = await _instance; // PERF FIX 4
    if (!prefs.containsKey(_keyLat)) return null;
    return {
      'lat': prefs.getDouble(_keyLat),
      'long': prefs.getDouble(_keyLong),
      'city': prefs.getString(_keyCity) ?? 'Manual Location',
      'countryCode': prefs.getString(_keyCountryCode) ?? 'XX',
    };
  }

  Future<void> saveCountryCode(String code) async {
    final prefs = await _instance; // PERF FIX 4
    await prefs.setString(_keyCountryCode, code);
  }

  Future<String> getCountryCode() async {
    final prefs = await _instance; // PERF FIX 4
    return prefs.getString(_keyCountryCode) ?? 'XX';
  }

  // ─── Calculation Method ───────────────────────────────────────────────────

  Future<String> getCalculationMethod() async {
    final prefs = await _instance; // PERF FIX 4
    return prefs.getString(_keyCalculationMethod) ?? 'turkey';
  }

  Future<void> setCalculationMethod(String method) async {
    final prefs = await _instance; // PERF FIX 4
    await prefs.setString(_keyCalculationMethod, method);
    await clearPrayerTimesCache();
  }

  // ─── Adhan Settings ───────────────────────────────────────────────────────

  Future<bool> isAdhanNotificationsEnabled() async {
    final prefs = await _instance; // PERF FIX 4
    return prefs.getBool(_keyAdhanNotificationsEnabled) ?? true;
  }

  Future<void> setAdhanNotificationsEnabled(bool enabled) async {
    final prefs = await _instance; // PERF FIX 4
    await prefs.setBool(_keyAdhanNotificationsEnabled, enabled);
  }

  Future<bool> isAdhanEnabled(String prayerName) async {
    final prefs = await _instance; // PERF FIX 4
    return prefs.getBool('adhan_enabled_${prayerName.toLowerCase()}') ?? true;
  }

  Future<void> setAdhanEnabled(String prayerName, bool enabled) async {
    final prefs = await _instance; // PERF FIX 4
    await prefs.setBool('adhan_enabled_${prayerName.toLowerCase()}', enabled);
  }

  Future<String> getAdhanSound() async {
    final prefs = await _instance; // PERF FIX 4
    return prefs.getString(_keyAdhanSound) ?? 'adhan_egypt.mp3';
  }

  Future<void> setAdhanSound(String soundFile) async {
    final prefs = await _instance; // PERF FIX 4
    await prefs.setString(_keyAdhanSound, soundFile);
  }

  // ─── Planned Notifications Cache ──────────────────────────────────────────

  static const String _keyPlannedNotifications = 'planned_notifications_cache';

  Future<void> savePlannedNotifications(String json) async {
    final prefs = await _instance; // PERF FIX 4
    await prefs.setString(_keyPlannedNotifications, json);
  }

  Future<String?> getPlannedNotifications() async {
    final prefs = await _instance; // PERF FIX 4
    return prefs.getString(_keyPlannedNotifications);
  }

  // ─── Prayer Times Cache ───────────────────────────────────────────────────

  Future<void> savePrayerTimesCache(String json) async {
    final prefs = await _instance;
    await prefs.setString(_keyPrayerTimesCache, json);
    await prefs.setString(_keyPrayerTimesLastFetch, DateTime.now().toIso8601String());
  }

  Future<String?> getPrayerTimesCache() async {
    final prefs = await _instance;
    return prefs.getString(_keyPrayerTimesCache);
  }

  Future<DateTime?> getPrayerTimesLastFetch() async {
    final prefs = await _instance;
    final iso = prefs.getString(_keyPrayerTimesLastFetch);
    return iso != null ? DateTime.parse(iso) : null;
  }

  Future<void> clearPrayerTimesCache() async {
    final prefs = await _instance;
    await prefs.remove(_keyPrayerTimesCache);
    await prefs.remove(_keyPrayerTimesLastFetch);
  }
}
