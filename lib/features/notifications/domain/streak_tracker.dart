import 'package:sila_app/core/services/notification_service.dart';
import 'package:sila_app/core/utils/language_utils.dart';
import 'package:sila_app/features/notifications/data/notification_ids.dart';
import 'package:sila_app/features/notifications/data/repositories/i_notification_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StreakTracker {
  StreakTracker({
    required this.repository,
    required this.notificationService,
  });
  final INotificationRepository repository;
  final NotificationService notificationService;

  Future<void> logActivity(String featureKey) async {
    final log = await repository.getActivityLog(featureKey);
    final now = DateTime.now();
    final lastOpenedDate = DateTime(
      log.lastOpened.year,
      log.lastOpened.month,
      log.lastOpened.day,
    );
    final today = DateTime(now.year, now.month, now.day);
    final daysDiff = today.difference(lastOpenedDate).inDays;
    var streakAdvanced = false;

    if (daysDiff == 1) {
      log.streakDays++;
      streakAdvanced = true;
    } else if (daysDiff > 1) {
      log.streakDays = 1;
      log.streakStartDate = now;
      streakAdvanced = true;
    } else if (log.streakDays == 0) {
      log.streakDays = 1;
      log.streakStartDate = now;
      streakAdvanced = true;
    }

    log.lastOpened = now;
    log.totalSessions++;
    await repository.saveActivityLog(log);
    if (streakAdvanced) {
      await _checkStreakMilestone(featureKey, log.streakDays);
    }
  }

  Future<int> getStreak(String featureKey) async {
    final log = await repository.getActivityLog(featureKey);
    return log.streakDays;
  }

  Future<void> _checkStreakMilestone(String featureKey, int days) async {
    const milestones = [3, 7, 14, 30, 60, 100];
    if (!milestones.contains(days)) return;
    final lang = await _currentLanguage();
    final feature = _featureName(featureKey, lang);
    final featureHash = featureKey
        .toLowerCase()
        .codeUnits
        .fold<int>(0, (acc, unit) => (acc * 31 + unit) % 800);
    final notificationId =
        NotificationIds.streakMilestone + (days * 10) + featureHash;

    await notificationService.showInstantNotification(
      id: notificationId,
      title: _streakTitle(days, lang),
      body: _streakBody(feature, lang),
      payload: featureKey,
    );
  }

  Future<String> _currentLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('user_language') ?? 'ar';
    return normalizeLanguageCode(raw);
  }

  String _streakTitle(int days, String lang) {
    return switch (lang) {
      'en' => 'Masha Allah! ✦ $days day streak',
      'tr' => 'Maşallah! ✦ $days günlük seri',
      'fr' => 'Maşallah! ✦ série de $days jours',
      _ => 'ما شاء الله! ✦ $days يوم متواصل',
    };
  }

  String _streakBody(String featureName, String lang) {
    return switch (lang) {
      'en' => 'Keep your $featureName streak going!',
      'tr' => '$featureName serini bozma, devam et!',
      'fr' => 'Ne cassez pas votre série de $featureName, continuez!',
      _ => 'لا تكسر سلسلة $featureName - استمر!',
    };
  }

  String _featureName(String key, String lang) {
    const ar = {
      'azkar': 'الأذكار',
      'wird': 'الورد',
      'hifz': 'الحفظ',
      'tasmi': 'التسميع',
      'tasbih': 'التسبيح',
      'salah': 'الصلاة',
    };
    const en = {
      'azkar': 'Azkar',
      'wird': 'Wird',
      'hifz': 'Hifz',
      'tasmi': 'Tasmi',
      'tasbih': 'Tasbih',
      'salah': 'Salah',
    };
    const tr = {
      'azkar': 'Zikir',
      'wird': 'Vird',
      'hifz': 'Ezber',
      'tasmi': 'Tekrar',
      'tasbih': 'Tesbih',
      'salah': 'Namaz',
    };
    const fr = {
      'azkar': 'Invocations',
      'wird': 'Wird',
      'hifz': 'Memorisation',
      'tasmi': 'Revision',
      'tasbih': 'Tasbih',
      'salah': 'Priere',
    };

    final normalizedKey = key.toLowerCase();
    final effectiveLang = switch (lang) {
      'en' || 'tr' || 'fr' => lang,
      _ => 'ar',
    };

    return switch (effectiveLang) {
      'en' => en[normalizedKey] ?? key,
      'tr' => tr[normalizedKey] ?? key,
      'fr' => fr[normalizedKey] ?? key,
      _ => ar[normalizedKey] ?? key,
    };
  }
}
