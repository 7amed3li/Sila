import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:isar/isar.dart';
import 'package:sila_app/features/notifications/data/models/notification_content.dart';
import 'package:sila_app/features/notifications/data/models/notification_settings.dart';
import 'package:sila_app/features/notifications/data/models/user_activity_log.dart';
import 'package:sila_app/features/notifications/data/repositories/i_notification_repository.dart';

extension IsarNotificationRepositoryTracking on IsarNotificationRepository {
  /// Track notification shown and check for ignored/dismissed
  Future<void> markAsShownAndCheckIgnored(String featureKey) async {
    final settings = await _isar.notificationSettings
        .filter()
        .featureKeyEqualTo(featureKey)
        .findFirst();
    if (settings == null) return;
    final wasShownYesterday = settings.lastShownAt != null &&
        DateTime.now().difference(settings.lastShownAt!).inHours < 30;
    await _isar.writeTxn(() async {
      // إذا أُرسل بالأمس ولم يُفتح → تجاهل
      if (wasShownYesterday &&
          (settings.lastTappedAt == null ||
              settings.lastTappedAt!.isBefore(settings.lastShownAt!))) {
        settings.dismissCount += 1;
        settings.consecutiveIgnored += 1;
      }
      settings.lastShownAt = DateTime.now();
      settings.shownCount += 1;
      await _isar.notificationSettings.put(settings);
    });
  }
}

class IsarNotificationRepository implements INotificationRepository {
  IsarNotificationRepository(this._isar);

  /// Returns a list of DateTime objects representing recent completion times for a feature.
  Future<List<DateTime>> getRecentCompletionTimes(String featureKey,
      {int days = 7}) async {
    // TODO: Implement actual logic based on user activity logs
    return [];
  }

  /// Returns a random congratulatory message in the user's language.
  Future<String?> getRandomCongrats({required String userLang}) async {
    // TODO: Implement actual logic to fetch a random congrats message
    return null;
  }

  /// Returns the last time the app was opened by the user.
  Future<DateTime?> getLastAppOpen() async {
    final lastLog =
        await _isar.userActivityLogs.where().sortByLastOpenedDesc().findFirst();
    return lastLog?.lastOpened;
  }

  final Isar _isar;

  @override
  Future<void> seedInitialContentIfNeeded() async {
    final count = await _isar.notificationContents.count();
    if (count > 0) return;

    final allBanks = <Map<String, dynamic>>[
      ...await _loadBankAsset('assets/banks/salah_bank.json'),
      ...await _loadBankAsset('assets/banks/quran_bank.json'),
      ...await _loadBankAsset('assets/banks/azkar_bank.json'),
      ...await _loadBankAsset('assets/banks/tasbih_bank.json'),
      ...await _loadBankAsset('assets/banks/hifz_bank.json'),
      ...await _loadBankAsset('assets/banks/scholars_bank.json'),
      ...await _loadBankAsset('assets/banks/seasons_bank.json'),
    ];

    final trMap = <String, Map<String, dynamic>>{};
    final trFiles = [
      'assets/banks/salah_bank_tr.json',
      'assets/banks/quran_bank_tr.json',
      'assets/banks/azkar_bank_tr.json',
      'assets/banks/tasbih_bank_tr.json',
      'assets/banks/hifz_bank_tr.json',
      'assets/banks/scholars_bank_tr.json',
      'assets/banks/seasons_bank_tr.json',
    ];

    for (final p in trFiles) {
      try {
        final items = await _loadBankAsset(p);
        for (final i in items) {
          final id = i['id'] as String?;
          if (id != null) trMap[id] = i;
        }
      } catch (e) {
        // Ignore missing Turkish files or errors
        print('Error loading Turkish bank $p: $e');
      }
    }

    final contents = allBanks.map((m) => _mapToContent(m, trMap)).toList();
    await _isar.writeTxn(() async {
      await _isar.notificationContents.putAll(contents);
    });
  }

  Future<List<Map<String, dynamic>>> _loadBankAsset(String path) async {
    final raw = await rootBundle.loadString(path);
    final decoded = jsonDecode(raw);
    if (decoded is! List) return <Map<String, dynamic>>[];
    return decoded
        .whereType<Map>()
        .map((e) => e.map((k, v) => MapEntry(k.toString(), v)))
        .toList();
  }

  NotificationContent _mapToContent(
      Map<String, dynamic> map, Map<String, Map<String, dynamic>> trMap) {
    final content = NotificationContent();
    content.contentId = map['id'] as String;
    content.category = (map['category'] as String?) ?? 'general';
    content.type = (map['type'] as String?) ?? 'hadith';
    content.arabicText = (map['arabic_text'] as String?) ?? '';
    content.source = (map['source'] as String?) ?? '';
    content.grade = (map['grade'] as String?) ?? '';
    content.shortExplanation = (map['short_explanation'] as String?) ?? '';
    content.triggerTags =
        ((map['trigger_tags'] as List?) ?? const []).cast<String>();
    content.seasonTags =
        ((map['season_tags'] as List?) ?? const ['عام']).cast<String>();
    content.surahNumber = (map['surah_number'] as int?) ?? 0;
    content.ayahNumber = (map['ayah_number'] as int?) ?? 0;
    content.shownCount = 0;
    content.lastShown = null;
    content.isFavorited = false;

    final tr = trMap[content.contentId];
    if (tr != null) {
      content.sourceTr = tr['source'] as String?;
      content.gradeTr = tr['grade'] as String?;
      content.shortExplanationTr = tr['short_explanation'] as String?;
    }

    return content;
  }

  @override
  Future<List<NotificationContent>> getContentByCategory(
      String category) async {
    final direct = await _isar.notificationContents
        .filter()
        .categoryEqualTo(category)
        .findAll();
    if (category == 'scholars') return direct;
    final scholars = await _isar.notificationContents
        .filter()
        .categoryEqualTo('scholars')
        .findAll();
    if (scholars.isEmpty) return direct;
    return [...direct, ...scholars];
  }

  @override
  Future<NotificationContent?> getContentByContentId(String contentId) {
    return _isar.notificationContents
        .filter()
        .contentIdEqualTo(contentId)
        .findFirst();
  }

  @override
  Future<void> saveContent(NotificationContent content) async {
    await _isar.writeTxn(() async {
      await _isar.notificationContents.put(content);
    });
  }

  @override
  Future<NotificationSettings> getSettings(String featureKey) async {
    final found = await _isar.notificationSettings
        .filter()
        .featureKeyEqualTo(featureKey)
        .findFirst();
    if (found != null) return found;

    final settings = NotificationSettings()..featureKey = featureKey;
    await saveSettings(settings);
    return settings;
  }

  @override
  Future<List<NotificationSettings>> getAllSettings() {
    return _isar.notificationSettings.where().findAll();
  }

  @override
  Future<void> saveSettings(NotificationSettings settings) async {
    await _isar.writeTxn(() async {
      await _isar.notificationSettings.put(settings);
    });
  }

  @override
  Future<UserActivityLog> getActivityLog(String featureKey) async {
    final found = await _isar.userActivityLogs
        .filter()
        .featureKeyEqualTo(featureKey)
        .findFirst();
    if (found != null) return found;

    final now = DateTime.now();
    final log = UserActivityLog()
      ..featureKey = featureKey
      ..lastOpened = now
      ..lastCompleted = now
      ..streakDays = 0
      ..streakStartDate = now
      ..totalSessions = 0;
    await saveActivityLog(log);
    return log;
  }

  @override
  Future<void> saveActivityLog(UserActivityLog log) async {
    await _isar.writeTxn(() async {
      await _isar.userActivityLogs.put(log);
    });
  }
}
