import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:sila_app/core/services/adhan_native_service.dart';
import 'package:sila_app/core/services/isar_service.dart';
import 'package:sila_app/core/services/notification_service.dart';
import 'package:sila_app/core/services/prefs_service.dart';
import 'package:sila_app/core/utils/language_utils.dart';
import 'package:sila_app/features/ibadah_tracker/data/repositories/isar_ibadah_repository.dart';
import 'package:sila_app/features/notifications/data/notification_ids.dart';
import 'package:sila_app/features/notifications/data/repositories/isar_notification_repository.dart';
import 'package:sila_app/features/notifications/domain/smart_notification_engine.dart';
import 'package:sila_app/features/prayers/domain/entities/prayer_times_entity.dart';
import 'package:sila_app/features/prayers/domain/repositories/prayer_repository.dart';

// Simple translation function for notification keys
String? t(String key, String lang, [Map<String, String>? params]) {
  // TODO: Replace with your actual localization system or use AppLocalizations
  final translations = <String, Map<String, String>>{
    'ar': {
      'notif_congrats_title': 'تهنئة',
      'notif_congrats_body': 'أحسنت! استمر على طاعتك.',
      'notif_title_azkar_morning': 'أذكار الصباح 🌅',
      'notif_title_azkar_evening': 'أذكار المساء 🌆',
      'notif_title_prayer_masjid': 'صلاة {prayer} في المسجد 🕌',
      'notif_title_azkar_post_prayer': 'أذكار ما بعد الصلاة',
      'notif_body_azkar_post_prayer':
          'اقرأ أذكار ما بعد الصلاة الآن واحتسب الأجر.',
      'notif_title_wird': 'وردك من الكتاب 📖',
      'notif_title_tasbih': 'لحظة تسبيح وذكر 💎',
      'notif_title_missed_user': 'اشتقنا لك!',
      'notif_body_missed_user':
          'لا تنس وردك اليوم. افتح التطبيق وابدأ من جديد.',
      'notif_streak_title': '⭐ {title} (سلسلة {days} يوم)',
      // ... add more keys as needed
    },
    'en': {
      'notif_congrats_title': 'Congrats',
      'notif_congrats_body': 'Great job! Keep it up.',
      'notif_title_azkar_morning': 'Morning Adhkar 🌅',
      'notif_title_azkar_evening': 'Evening Adhkar 🌆',
      'notif_title_prayer_masjid': '{prayer} Prayer at Mosque 🕌',
      'notif_title_azkar_post_prayer': 'Post-Prayer Adhkar',
      'notif_body_azkar_post_prayer':
          'Read your post-prayer adhkar now and earn reward.',
      'notif_title_wird': 'Your Daily Wird 📖',
      'notif_title_tasbih': 'Time for Tasbih & Dhikr 💎',
      'notif_title_missed_user': 'We Miss You!',
      'notif_body_missed_user':
          'Don’t forget your wird today. Open the app and start again.',
      'notif_streak_title': '{title} (Streak {days} days)',
      // ... add more keys as needed
    },
    'tr': {
      'notif_congrats_title': 'Tebrikler',
      'notif_congrats_body': 'Harika! Devam et.',
      'notif_title_azkar_morning': 'Sabah Zikirleri 🌅',
      'notif_title_azkar_evening': 'Akşam Zikirleri 🌆',
      'notif_title_prayer_masjid': '{prayer} Namazı Camiide 🕌',
      'notif_title_azkar_post_prayer': 'Namaz Sonrası Zikirler',
      'notif_body_azkar_post_prayer':
          'Namaz sonrası zikirlerini şimdi oku ve sevap kazan.',
      'notif_title_wird': 'Günlük Wirdin 📖',
      'notif_title_tasbih': 'Tesbih ve Zikir Zamanı 💎',
      'notif_title_missed_user': 'Seni Özledik!',
      'notif_body_missed_user':
          'Bugünkü wirdini unutma. Uygulamayı aç ve tekrar başla.',
      'notif_streak_title': '{title} (Seri {days} gün)',
      // ... add more keys as needed
    },
    'fr': {
      'notif_congrats_title': 'Felicitations',
      'notif_congrats_body': 'Excellent travail, continuez ainsi.',
      'notif_title_azkar_morning': 'Invocations du matin 🌅',
      'notif_title_azkar_evening': 'Invocations du soir 🌆',
      'notif_title_prayer_masjid': 'Priere de {prayer} a la mosquee 🕌',
      'notif_title_azkar_post_prayer': 'Invocations apres la priere',
      'notif_body_azkar_post_prayer':
          'Lisez vos invocations apres la priere et recoltez la recompense.',
      'notif_title_wird': 'Votre wird quotidien 📖',
      'notif_title_tasbih': 'Moment de tasbih et de dhikr 💎',
      'notif_title_missed_user': 'Vous nous manquez',
      'notif_body_missed_user':
          'N oubliez pas votre wird aujourd hui. Ouvrez l application et reprenez.',
      'notif_streak_title': '{title} (Serie de {days} jours)',
    },
  };
  final map = translations[lang] ?? translations['ar'];
  if (map == null) return null;
  var value = map[key];
  if (value != null && params != null) {
    params.forEach((k, v) => value = value!.replaceAll('{$k}', v));
  }
  return value;
}

enum _IbadahSignalType {
  prayer,
  masjid,
  wird,
  azkarSabah,
  azkarMasa,
  hifz,
  tasbih,
  dhikr
}

class _SmartMessage {
  const _SmartMessage({required this.title, required this.body});
  final String title;
  final String body;
}

class AdhanSchedulerService {
  final NotificationService _notificationService = NotificationService();
  final PrefsService _prefsService = PrefsService();

  /// Schedule all daily prayers based on user preferences
  Future<void> scheduleAllPrayers(PrayerTimesEntity prayerTimes) async {
    print('Scheduling all prayers for ${prayerTimes.locationName}');

    // Check if Adhan is enabled globally
    final isAdhanEnabled = await _prefsService.isAdhanNotificationsEnabled();
    if (!isAdhanEnabled) {
      print('Adhan notifications are disabled');
      return;
    }

    // Get selected Adhan sound
    final adhanSound = await _prefsService.getAdhanSound();

    // PERF FIX 5: Schedule all 5 prayers in parallel instead of sequentially
    await Future.wait([
      _scheduleIfEnabled('fajr', prayerTimes.fajr, adhanSound),
      _scheduleIfEnabled('dhuhr', prayerTimes.dhuhr, adhanSound),
      _scheduleIfEnabled('asr', prayerTimes.asr, adhanSound),
      _scheduleIfEnabled('maghrib', prayerTimes.maghrib, adhanSound),
      _scheduleIfEnabled('isha', prayerTimes.isha, adhanSound),
    ]);

    await _scheduleSmartReminders(prayerTimes);

    // Log scheduled notifications
    final pending = await _notificationService.getPendingNotifications();
    print('Total scheduled notifications: ${pending.length}');
    for (final notification in pending) {
      print('  - ID: ${notification.id}, Title: ${notification.title}');
    }
  }

  Future<void> _scheduleSmartReminders(PrayerTimesEntity prayerTimes) async {
    try {
      DateTime normalizeToNext(DateTime dt) {
        final nowLocal = DateTime.now();
        if (dt.isAfter(nowLocal)) return dt;
        return dt.add(const Duration(days: 1));
      }

      final isar = await IsarService().db;
      final repo = IsarNotificationRepository(isar);
      final ibadahRepo = IsarIbadahRepository(isar);
      await repo.seedInitialContentIfNeeded();
      final engine = SmartNotificationEngine(repository: repo);

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final record = await ibadahRepo.getRecord(today);

      final planned = <_PlannedNotification>[];

      // Helper to check if عبادة أنجزت
      bool isCompleted(_IbadahSignalType type) {
        if (record == null) return false;
        switch (type) {
          case _IbadahSignalType.wird:
            return record.readWird;
          case _IbadahSignalType.azkarSabah:
            return record.readAzkarSabah;
          case _IbadahSignalType.azkarMasa:
            return record.readAzkarMasa;
          case _IbadahSignalType.tasbih:
            return record.didTasbih;
          case _IbadahSignalType.hifz:
            return record.didHifz || record.didTasmi;
          case _IbadahSignalType.dhikr:
            return record.rememberedAllah;
          case _IbadahSignalType.prayer:
            return record.fajrStatus != 0 &&
                record.dhuhrStatus != 0 &&
                record.asrStatus != 0 &&
                record.maghribStatus != 0 &&
                record.ishaStatus != 0;
          default:
            return false;
        }
      }

      // Helper: احسب متوسط وقت الإنجاز لعبادة معينة آخر 7 أيام
      Future<TimeOfDay?> getHabitualTime(String featureKey) async {
        final logs = await repo.getRecentCompletionTimes(featureKey, days: 7);
        if (logs.isEmpty) return null;
        final avgMinutes = logs
                .map((dt) => dt.hour * 60 + dt.minute)
                .reduce((a, b) => a + b) ~/
            logs.length;
        return TimeOfDay(hour: avgMinutes ~/ 60, minute: avgMinutes % 60);
      }

      // Helper: أضف تذكير متعدد اللغات مع تنويع المحتوى
      Future<void> addSmartReminder({
        required String featureKey,
        required int slotId,
        required String defaultTitle,
        required _IbadahSignalType signalType,
        DateTime? fixedTime,
        Duration? after,
        DateTime? baseTime,
        bool skipIfDone = true,
        String? customBody,
        String? customCategory, // ex: "hadith", "ayah", "wisdom"
        bool congratIfCommitted = false,
      }) async {
        final settings = await repo.getSettings(featureKey);
        if (!settings.isEnabled) return;
        if (skipIfDone && isCompleted(signalType)) return;

        // تحديث حالة الإشعار السابق (تتبع التجاهل)
        await repo.markAsShownAndCheckIgnored(featureKey);

        // تحديد لغة المستخدم
        final userLang = await _prefsService.getUserLanguage() ?? 'ar';

        // توقيت ذكي فعلي
        DateTime? when;
        // 1. إذا المستخدم تخلى عن الميزة → لا ترسل
        if (settings.isAbandoned) {
          print('⏭ Skipping $featureKey — abandoned');
          return;
        }
        // 2. عنده بيانات استجابة حقيقية → استخدمها
        if (settings.avgResponseMinutes != -1 &&
            settings.lastTappedAt != null) {
          final lastTap = settings.lastTappedAt!;
          final optimalHour = lastTap.hour;
          final optimalMinute = lastTap.minute;
          final candidate = DateTime(
              now.year, now.month, now.day, optimalHour, optimalMinute);
          when = normalizeToNext(candidate);
        } else if (settings.needsReschedule && fixedTime != null) {
          // 3. يحتاج إعادة جدولة لأنه يتجاهل → جرّب وقتاً مختلفاً
          when = normalizeToNext(fixedTime.add(const Duration(hours: 3)));
        } else if (fixedTime != null) {
          when = normalizeToNext(fixedTime);
        } else if (baseTime != null && after != null) {
          when = normalizeToNext(baseTime.add(after));
        } else {
          // fallback: 15:00
          when = normalizeToNext(DateTime(now.year, now.month, now.day, 15, 0));
        }

        final activity = await repo.getActivityLog(featureKey);
        // إذا كان المستخدم ملتزمًا وأردنا تهنئة
        if (congratIfCommitted && isCompleted(signalType)) {
          final congrats = await repo.getRandomCongrats(userLang: userLang);
          planned.add(_PlannedNotification(
            id: slotId,
            when: when,
            title: t('notif_congrats_title', userLang) ?? defaultTitle,
            body: congrats ??
                t('notif_congrats_body', userLang) ??
                'أحسنت! استمر على طاعتك.',
            payload: null,
            priority: 10,
          ));
          return;
        }

        // اختيار محتوى متنوع من البنك المناسب حسب اللغة
        final selected = await engine.selectContent(
          featureKey: featureKey,
          activity: activity,
          settings: settings,
        );
        if (selected == null) return;

        var body = customBody ?? selected.getTextForLang(userLang);
        if (body.length > 100) body = '${body.substring(0, 97)}...';

        final payload = jsonEncode({
          'content_id': selected.contentId,
          'category': selected.category,
          'feature_key': featureKey,
        });

        // Streak-based title personalization
        var personalizedTitle =
            t('notif_title_$featureKey', userLang) ?? defaultTitle;
        if (activity.streakDays >= 3) {
          personalizedTitle = t('notif_streak_title', userLang, {
                'title': personalizedTitle,
                'days': activity.streakDays.toString()
              }) ??
              '$personalizedTitle (سلسلة ${activity.streakDays} يوم)';
        }
        planned.add(_PlannedNotification(
          id: slotId,
          when: when,
          title: personalizedTitle,
          body: body,
          payload: payload,
          priority: 10,
          selectedContentId: selected.contentId,
          category: selected.category,
        ));
      }

      // 1. تذكير أذكار الصباح بعد الفجر بـ 10 دقائق (ضمن الوقت الشرعي)
      final azkarSabahTime = prayerTimes.fajr.add(const Duration(minutes: 10));
      await addSmartReminder(
        featureKey: 'azkar',
        slotId: NotificationIds.dailySlot1,
        defaultTitle: t('notif_title_azkar_morning',
                await _prefsService.getUserLanguage() ?? 'ar') ??
            'أذكار الصباح 🌅',
        signalType: _IbadahSignalType.azkarSabah,
        fixedTime: azkarSabahTime,
      );

      // 2. تذكير أذكار المساء بعد العصر بـ 10 دقائق (ضمن الوقت الشرعي)
      final azkarMasaTime = prayerTimes.asr.add(const Duration(minutes: 10));
      await addSmartReminder(
        featureKey: 'azkar',
        slotId: NotificationIds.dailySlot6,
        defaultTitle: t('notif_title_azkar_evening',
                await _prefsService.getUserLanguage() ?? 'ar') ??
            'أذكار المساء 🌆',
        signalType: _IbadahSignalType.azkarMasa,
        fixedTime: azkarMasaTime,
      );

      // 3. تذكير المسجد لجميع الصلوات (تحفيزي أو تهنئة)
      final prayers = [
        {
          'key': 'fajr',
          'time': prayerTimes.fajr,
          'signal': _IbadahSignalType.prayer,
          'inMasjid': record?.fajrInMasjid
        },
        {
          'key': 'dhuhr',
          'time': prayerTimes.dhuhr,
          'signal': _IbadahSignalType.prayer,
          'inMasjid': record?.dhuhrInMasjid
        },
        {
          'key': 'asr',
          'time': prayerTimes.asr,
          'signal': _IbadahSignalType.prayer,
          'inMasjid': record?.asrInMasjid
        },
        {
          'key': 'maghrib',
          'time': prayerTimes.maghrib,
          'signal': _IbadahSignalType.prayer,
          'inMasjid': record?.maghribInMasjid
        },
        {
          'key': 'isha',
          'time': prayerTimes.isha,
          'signal': _IbadahSignalType.prayer,
          'inMasjid': record?.ishaInMasjid
        },
      ];
      for (var i = 0; i < prayers.length; i++) {
        final p = prayers[i];
        final prayerName = p['key'] as String;
        final prayerTime = p['time'] as DateTime;
        final inMasjid = p['inMasjid'] as bool?;
        final slotId = NotificationIds.smartPrayerActionOffset + i;
        if (inMasjid == false) {
          // تذكير تحفيزي للصلاة في المسجد
          await addSmartReminder(
            featureKey: 'prayer',
            slotId: slotId,
            defaultTitle: t(
                    'notif_title_prayer_masjid',
                    await _prefsService.getUserLanguage() ?? 'ar',
                    {'prayer': prayerName}) ??
                'صلاة $prayerName في المسجد 🕌',
            signalType: _IbadahSignalType.prayer,
            fixedTime: prayerTime.subtract(const Duration(minutes: 30)),
            customCategory: 'hadith',
          );
        } else if (inMasjid == true) {
          // تهنئة أو اقتباس تحفيزي
          await addSmartReminder(
            featureKey: 'prayer',
            slotId: slotId,
            defaultTitle: t(
                    'notif_title_prayer_masjid',
                    await _prefsService.getUserLanguage() ?? 'ar',
                    {'prayer': prayerName}) ??
                'صلاة $prayerName في المسجد 🕌',
            signalType: _IbadahSignalType.prayer,
            fixedTime: prayerTime.subtract(const Duration(minutes: 30)),
            congratIfCommitted: true,
          );
        }
      }

      // 4. تذكير أذكار ما بعد الصلاة (مثلاً بعد الظهر بـ 20 دقيقة)
      final dhuhrAfterTime = prayerTimes.dhuhr.add(const Duration(minutes: 20));
      planned.add(_PlannedNotification(
        id: NotificationIds.postPrayerDhuhrFixedId,
        when: normalizeToNext(dhuhrAfterTime),
        title: t('notif_title_azkar_post_prayer',
                await _prefsService.getUserLanguage() ?? 'ar') ??
            'أذكار ما بعد الصلاة',
        body: t('notif_body_azkar_post_prayer',
                await _prefsService.getUserLanguage() ?? 'ar') ??
            'اقرأ أذكار ما بعد الصلاة الآن واحتسب الأجر.',
        payload: null,
        priority: 15,
      ));

      // 5. تذكير الورد بتوقيت معتاد للمستخدم (أو fallback)
      await addSmartReminder(
        featureKey: 'wird',
        slotId: NotificationIds.dailySlot4,
        defaultTitle: t('notif_title_wird',
                await _prefsService.getUserLanguage() ?? 'ar') ??
            'وردك من الكتاب 📖',
        signalType: _IbadahSignalType.wird,
      );

      // 6. تذكير تسبيح/ذكر بتوقيت معتاد أو fallback
      await addSmartReminder(
        featureKey: 'tasbih',
        slotId: NotificationIds.dailySlot2,
        defaultTitle: t('notif_title_tasbih',
                await _prefsService.getUserLanguage() ?? 'ar') ??
            'لحظة تسبيح وذكر 💎',
        signalType: _IbadahSignalType.tasbih,
      );

      // 7. تذكير عام إذا لم يفتح المستخدم التطبيق ليومين
      final lastOpen = await repo.getLastAppOpen();
      if (lastOpen != null && now.difference(lastOpen).inDays >= 2) {
        final lang = await _prefsService.getUserLanguage() ?? 'ar';
        planned.add(_PlannedNotification(
          id: NotificationIds.reEngagementFixedId,
          when: normalizeToNext(now.add(const Duration(minutes: 5))),
          title: t('notif_title_missed_user', lang) ?? 'اشتقنا لك!',
          body: t('notif_body_missed_user', lang) ??
              'لا تنس وردك اليوم. افتح التطبيق وابدأ من جديد.',
          payload: null,
          priority: 30,
        ));
      }

      // Notification budget logic
      const maxNotificationsPerDay = 5;
      const minGap = Duration(hours: 2);
      planned.sort((a, b) => a.when.compareTo(b.when));
      final filtered = <_PlannedNotification>[];
      DateTime? lastScheduled;
      for (final p in planned) {
        if (filtered.length >= maxNotificationsPerDay) break;
        if (lastScheduled == null ||
            p.when.difference(lastScheduled) >= minGap) {
          filtered.add(p);
          lastScheduled = p.when;
        }
      }

      // Save to cache for Home card
      final cacheData = filtered
          .map((p) => {
                'id': p.id,
                'time': p.when.toIso8601String(),
                'title': p.title,
                'body': p.body,
                'payload': p.payload,
                'category': p.category,
                'contentId': p.selectedContentId,
              })
          .toList();
      await _prefsService.savePlannedNotifications(jsonEncode(cacheData));

      // Actually schedule
      for (final item in filtered) {
        await _notificationService.cancelNotification(item.id);
        await _notificationService.scheduleOneShot(
          id: item.id,
          title: item.title,
          body: item.body,
          dateTime: item.when,
          payload: item.payload,
          channelKey: 'reminder', // ← ADD: يضمن importance صح
        );
      }

      // Add back the Daily Report as a bonus
      final userLang =
          normalizeLanguageCode(await _prefsService.getUserLanguage());
      final reportTime =
          normalizeToNext(prayerTimes.maghrib.add(const Duration(minutes: 30)));
      await _notificationService
          .cancelNotification(NotificationIds.dailyReport);
      await _notificationService.scheduleOneShot(
        id: NotificationIds.dailyReport,
        title: _dailyReportTitle(userLang),
        body: _dailyReportBody(userLang),
        dateTime: reportTime,
        payload: jsonEncode({'route': 'daily_report'}),
        channelKey: 'report', // ← ADD: channel منخفضة للتقرير
      );
    } catch (e) {
      print('Error scheduling smart reminders: $e');
    }
  }

  /// Schedule notification if prayer is enabled
  Future<void> _scheduleIfEnabled(
    String prayerName,
    DateTime prayerTime,
    String soundFile,
  ) async {
    final isEnabled = await _prefsService.isAdhanEnabled(prayerName);
    final adhanMode = await _prefsService
        .getAdhanMode(prayerName); // "adhan" or "notification"
    final reminderMinutes =
        await _prefsService.getPrayerReminderMinutes(prayerName) ?? 0;
    final lang = normalizeLanguageCode(await _prefsService.getUserLanguage());
    final localizedPrayerName = _localizedPrayerName(prayerName, lang);
    final id = NotificationService.getNotificationId(prayerName);
    final reminderId = id + NotificationIds.prayerReminderOffset;

    // Always clear existing main/reminder notifications before recalculation.
    await _notificationService.cancelNotification(id);
    await _notificationService.cancelNotification(reminderId);

    if (!isEnabled) {
      print('Adhan disabled for $prayerName');
      return;
    }

    final now = DateTime.now();
    final nextPrayerTime = prayerTime.isAfter(now)
        ? prayerTime
        : prayerTime.add(const Duration(days: 1));

    // جدولة التذكير قبل الصلاة إذا تم اختياره
    if (reminderMinutes > 0) {
      final reminderTime =
          nextPrayerTime.subtract(Duration(minutes: reminderMinutes));
      if (reminderTime.isAfter(DateTime.now())) {
        await _notificationService.scheduleOneShot(
          id: reminderId,
          title: _prayerReminderTitle(localizedPrayerName, lang),
          body: _prayerReminderBody(localizedPrayerName, reminderMinutes, lang),
          dateTime: reminderTime,
          payload: null,
          channelKey: 'reminder',
        );
      }
    }

    if (adhanMode == 'adhan') {
      // في حالة اختيار الأذان، نستخدم إشعارًا مضبوطًا على وقت الصلاة
      // ثم يدير المستخدم عمل تشغيل الصوت عبر نظام الإشعار.
      await _notificationService.scheduleNotification(
        id: id,
        prayerName: prayerName,
        prayerTime: nextPrayerTime,
        soundFile: soundFile,
      );
    } else {
      // إشعار نصي فقط
      await _notificationService.scheduleNotification(
        id: id,
        prayerName: prayerName,
        prayerTime: nextPrayerTime,
        silent: true,
      );
    }
  }

  /// Reschedule prayers (called daily or when app restarts)
  Future<void> rescheduleDaily(PrayerRepository repository) async {
    print('Rescheduling daily prayers...');

    try {
      final prayerTimes = await repository.getPrayerTimes();
      await scheduleAllPrayers(prayerTimes);
      print('Daily reschedule completed successfully');
    } catch (e, st) {
      print('Error rescheduling prayers: $e');
      Error.throwWithStackTrace(e, st);
    }
  }

  String _localizedPrayerName(String prayerKey, String lang) {
    const names = {
      'ar': {
        'fajr': 'الفجر',
        'dhuhr': 'الظهر',
        'asr': 'العصر',
        'maghrib': 'المغرب',
        'isha': 'العشاء',
      },
      'en': {
        'fajr': 'Fajr',
        'dhuhr': 'Dhuhr',
        'asr': 'Asr',
        'maghrib': 'Maghrib',
        'isha': 'Isha',
      },
      'tr': {
        'fajr': 'İmsak',
        'dhuhr': 'Öğle',
        'asr': 'İkindi',
        'maghrib': 'Akşam',
        'isha': 'Yatsı',
      },
      'fr': {
        'fajr': 'Fajr',
        'dhuhr': 'Dhuhr',
        'asr': 'Asr',
        'maghrib': 'Maghrib',
        'isha': 'Isha',
      },
    };

    final effectiveLang = names.containsKey(lang) ? lang : 'ar';
    return names[effectiveLang]?[prayerKey.toLowerCase()] ?? prayerKey;
  }

  String _dailyReportTitle(String lang) {
    return switch (lang) {
      'en' => 'Your Daily Report Is Ready 📋',
      'tr' => 'Günlük raporun hazır 📋',
      'fr' => 'Votre rapport quotidien est prêt 📋',
      _ => 'تقريرك اليومي جاهز 📋',
    };
  }

  String _dailyReportBody(String lang) {
    return switch (lang) {
      'en' => 'Review your day and take one step toward a better tomorrow.',
      'tr' => 'Gününü değerlendir ve daha iyi bir yarın için bir adım at.',
      'fr' =>
        'Révisez votre journée et faites un pas vers un meilleur lendemain.',
      _ => 'راجع يومك وخذ خطوة لغد أفضل.',
    };
  }

  String _prayerReminderTitle(String prayerName, String lang) {
    return switch (lang) {
      'en' => 'Prayer time is near: $prayerName',
      'tr' => '$prayerName vakti yaklaşıyor',
      'fr' => 'L\'heure de la prière approche: $prayerName',
      _ => 'اقترب وقت $prayerName',
    };
  }

  String _prayerReminderBody(String prayerName, int minutes, String lang) {
    return switch (lang) {
      'en' => '$minutes minutes left until $prayerName',
      'tr' => '$prayerName için $minutes dakika kaldı',
      'fr' => 'Il reste $minutes minutes avant $prayerName',
      _ => 'باقي $minutes دقيقة على $prayerName',
    };
  }

  /// Cancel all scheduled prayers
  Future<void> cancelAllPrayers() async {
    await _notificationService.cancelPrayerNotifications();
    print('Cancelled all prayer notifications');
  }

  /// Cancel specific prayer notification
  Future<void> cancelPrayer(String prayerName) async {
    final id = NotificationService.getNotificationId(prayerName);
    final reminderId = id + NotificationIds.prayerReminderOffset;
    await _notificationService.cancelNotification(id);
    await _notificationService.cancelNotification(reminderId);
    print('Cancelled $prayerName notification');
  }

  /// Test Adhan sound
  Future<void> testAdhan(String soundFile) async {
    await _notificationService.playAdhan(soundFile);
  }

  /// Stop playing Adhan
  Future<void> stopAdhan() async {
    await _notificationService.stopAdhan();
  }
}

class _PlannedNotification {
  _PlannedNotification({
    required this.id,
    required this.when,
    required this.title,
    required this.body,
    required this.payload,
    required this.priority,
    this.selectedContentId,
    this.category,
  });
  final int id;
  final DateTime when;
  final String title;
  final String body;
  final String? payload;
  final int priority;
  final String? selectedContentId;
  final String? category;

  _PlannedNotification copyWith({int? priority}) {
    return _PlannedNotification(
      id: id,
      when: when,
      title: title,
      body: body,
      payload: payload,
      priority: priority ?? this.priority,
      selectedContentId: selectedContentId,
      category: category,
    );
  }
}
