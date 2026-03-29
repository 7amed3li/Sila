import 'dart:convert';

import 'package:audioplayers/audioplayers.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sila_app/core/presentation/widgets/update_dialog.dart';
import 'package:sila_app/core/services/analytics_service.dart';
import 'package:sila_app/core/services/isar_service.dart';
import 'package:sila_app/core/services/remote_config_service.dart';
import 'package:sila_app/core/services/update_service.dart';
import 'package:sila_app/features/ibadah_tracker/presentation/pages/daily_report_page.dart';
import 'package:sila_app/features/notifications/data/notification_ids.dart';
import 'package:sila_app/features/notifications/data/repositories/isar_notification_repository.dart';
import 'package:sila_app/features/notifications/presentation/pages/notification_detail_page.dart';
import 'package:sila_app/features/prayers/presentation/pages/prayers_page.dart';
import 'package:timezone/timezone.dart' as tz;

@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  final payload = response.payload;
  if (payload == null || payload.trim().isEmpty) return;
  // Persist only; UI navigation is resumed on app foreground.
  NotificationService().saveDeferredPayload(payload.trim());
}

class NotificationService {
  factory NotificationService() => _instance;
  NotificationService._internal();
  static final NotificationService _instance = NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  final AudioPlayer _audioPlayer = AudioPlayer();
  GlobalKey<NavigatorState>? _navigatorKey;
  String? _deferredPayload;

  static const int _adhanPlaybackNotificationId = 9090;
  static const String _stopAdhanActionId = 'stop_adhan';

  // Download notification constants
  static const int downloadNotificationId = 9000;
  static const int modelDownloadNotificationId = 9001;
  static const String _installApkActionId = 'install_apk';
  static const String _retryDownloadActionId = 'retry_download';
  static const String _pauseDownloadActionId = 'pause_download';
  static const String _stopDownloadActionId = 'stop_download';

  // Callbacks
  VoidCallback? onRetryDownload;
  VoidCallback? onPauseDownload;
  VoidCallback? onStopDownload;
  String? _lastDownloadApkPath;
  String? _lastDownloadUrl;

  // Track subscribed topics to avoid duplicate subscription attempts
  final Set<String> _subscribedTopics = {'all_users', 'updates'};

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    try {
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _notifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: _onNotificationTap,
        onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
      );

      await _createNotificationChannel();

      final launchDetails =
          await _notifications.getNotificationAppLaunchDetails();
      final launchPayload = launchDetails?.notificationResponse?.payload;
      if (launchPayload != null && launchPayload.trim().isNotEmpty) {
        handleNotificationPayload(launchPayload);
      }

      try {
        await FirebaseMessaging.instance.requestPermission();

        // Subscribe to topics only after permissions granted - lazy approach
        _subscribeToTopics();

        FirebaseMessaging.onMessage.listen((message) {
          if (message.data['type'] == 'update') {
            _showUpdateNotification(message);
          }
        });

        FirebaseMessaging.onMessageOpenedApp.listen((message) {
          if (message.data['type'] == 'update') {
            _showUpdateNotification(message);
          }
        });
      } catch (e) {
        debugPrint('Firebase Messaging setup failed: $e');
      }

      _initialized = true;
      debugPrint('NotificationService: Initialized');
    } catch (e) {
      debugPrint('NotificationService initialization error: $e');
      _initialized = true;
    }
  }

  void setNavigatorKey(GlobalKey<NavigatorState> navigatorKey) {
    _navigatorKey = navigatorKey;
    if (_deferredPayload != null) {
      final payload = _deferredPayload!;
      _deferredPayload = null;
      Future<void>.microtask(() => handleNotificationPayload(payload));
    }
  }

  void saveDeferredPayload(String payload) {
    _deferredPayload = payload;
  }

  Future<void> _createNotificationChannel() async {
    final android = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    // Adhan channel
    await android?.createNotificationChannel(const AndroidNotificationChannel(
      'adhan_channel',
      'أذان الصلاة',
      description: 'إشعارات أذان الصلاة',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      enableLights: true,
    ));

    // Download channel
    await android?.createNotificationChannel(const AndroidNotificationChannel(
      'download_controls_v1',
      'التحديثات',
      description: 'إشعارات تحميل التحديثات والتحكم بها',
      importance: Importance.max,
      playSound: false,
    ));
  }

  Future<void> _subscribeToTopics() async {
    try {
      // Only subscribe to essential topics - limit to 2 to avoid TOO_MANY_SUBSCRIBERS error
      // Other subscriptions should be done on-demand (lazy loading)
      await Future.delayed(
          const Duration(milliseconds: 500)); // Delay to avoid rate limiting

      await FirebaseMessaging.instance.subscribeToTopic('all_users');
      debugPrint('✅ Subscribed to topic: all_users');

      await Future.delayed(
          const Duration(milliseconds: 200)); // Space out requests

      await FirebaseMessaging.instance.subscribeToTopic('updates');
      debugPrint('✅ Subscribed to topic: updates');
    } catch (e) {
      debugPrint('⚠️ Firebase topic subscription failed: $e');
      // Don't crash if subscriptions fail - app should still work
    }
  }

  /// Subscribe to a topic on-demand (lazy loading)
  /// Use this for optional/dynamic topics to avoid TOO_MANY_SUBSCRIBERS error
  /// Example: subscribe to a specific reciter or surah when user explicitly requests it
  Future<void> subscribeToTopicLazy(String topic) async {
    if (_subscribedTopics.contains(topic)) {
      return; // Already subscribed
    }

    try {
      await Future.delayed(const Duration(milliseconds: 100)); // Rate limit
      await FirebaseMessaging.instance.subscribeToTopic(topic);
      _subscribedTopics.add(topic);
      debugPrint('✅ Subscribed to optional topic: $topic');
    } catch (e) {
      debugPrint('⚠️ Failed to subscribe to topic $topic: $e');
      // Don't crash - this is optional
    }
  }

  /// Unsubscribe from a topic
  /// Use when user no longer needs updates for this topic
  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
      _subscribedTopics.remove(topic);
      debugPrint('✅ Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('⚠️ Failed to unsubscribe from topic $topic: $e');
    }
  }

  Future<bool> requestPermissions() async {
    debugPrint('🔔 Requesting notification permissions...');

    // Step 1: POST_NOTIFICATIONS (Android 13+)
    try {
      final status = await Permission.notification.status;
      debugPrint('Notification permission status: $status');

      if (!status.isGranted) {
        final result = await Permission.notification.request();
        debugPrint('Notification permission result: $result');
      }
    } catch (e) {
      debugPrint('❌ POST_NOTIFICATIONS error: $e');
    }

    // Step 2: SCHEDULE_EXACT_ALARM (Android 12+)
    try {
      final exactStatus = await Permission.scheduleExactAlarm.status;
      debugPrint('Exact alarm status: $exactStatus');

      if (!exactStatus.isGranted) {
        final result = await Permission.scheduleExactAlarm.request();
        debugPrint('Exact alarm result: $result');

        if (!result.isGranted) {
          // Open settings so user can grant manually
          debugPrint('⚠️ User must grant exact alarm in settings');
          await openAppSettings();
        }
      }
    } catch (e) {
      debugPrint('❌ SCHEDULE_EXACT_ALARM error: $e');
    }

    debugPrint('✅ Permission requests complete');
    return await Permission.notification.isGranted;
  }

  Future<bool> scheduleNotification({
    required int id,
    required String prayerName,
    required DateTime prayerTime,
    required String soundFile,
  }) async {
    if (!_initialized) {
      debugPrint('❌ NotificationService not initialized');
      return false;
    }

    final scheduledTime = tz.TZDateTime.from(prayerTime, tz.local);

    if (scheduledTime.isBefore(tz.TZDateTime.now(tz.local))) {
      debugPrint('⚠️ Skipping past notification: $prayerName');
      return false;
    }

    debugPrint('📅 Scheduling: $prayerName at $scheduledTime');

    final soundName = soundFile.split('.').first;

    final androidDetails = AndroidNotificationDetails(
      'adhan_channel',
      'أذان الصلاة',
      channelDescription: 'إشعارات أذان الصلاة',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      playSound: true,
      sound: RawResourceAndroidNotificationSound(soundName),
      enableVibration: true,
      fullScreenIntent: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
        sound: soundFile,
      ),
    );

    // Try exact alarm first
    try {
      final localizedPrayerName = _localizedPrayerName(prayerName);
      await _notifications.zonedSchedule(
        id,
        '🕌 حان وقت $localizedPrayerName',
        'حان وقت الصلاة — $localizedPrayerName',
        scheduledTime,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: prayerName,
      );
      debugPrint('✅ Exact alarm scheduled: $prayerName');
      return true;
    } catch (e) {
      debugPrint('⚠️ Exact alarm failed: $e — trying inexact');
    }

    // Fallback: inexact alarm
    try {
      final localizedPrayerName = _localizedPrayerName(prayerName);
      await _notifications.zonedSchedule(
        id,
        '🕌 حان وقت $localizedPrayerName',
        'حان وقت الصلاة — $localizedPrayerName',
        scheduledTime,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: prayerName,
      );
      debugPrint('✅ Inexact alarm scheduled: $prayerName');
      return true;
    } catch (e) {
      debugPrint('❌ Both alarm modes failed: $e');
      return false;
    }
  }

  Future<void> scheduleDaily({
    required int id,
    required String title,
    required String body,
    required DateTime dateTime,
  }) async {
    if (!_initialized) await initialize();

    final scheduledTime = tz.TZDateTime.from(dateTime, tz.local);

    const androidDetails = AndroidNotificationDetails(
      'adhan_channel',
      'أذان الصلاة',
      channelDescription: 'إشعارات أذان الصلاة',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      icon: '@drawable/ic_notification',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        scheduledTime,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    } catch (e) {
      try {
        await _notifications.zonedSchedule(
          id,
          title,
          body,
          scheduledTime,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      } catch (e2) {
        debugPrint('Error scheduling daily reminder: $e / fallback: $e2');
      }
    }
  }

  Future<void> scheduleOneShot({
    required int id,
    required String title,
    required String body,
    required DateTime dateTime,
    String? payload,
  }) async {
    if (!_initialized) await initialize();
    final scheduledTime = tz.TZDateTime.from(dateTime, tz.local);

    const androidDetails = AndroidNotificationDetails(
      'adhan_channel',
      'أذان الصلاة',
      channelDescription: 'إشعارات أذان الصلاة',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      icon: '@drawable/ic_notification',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        scheduledTime,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
    } catch (e) {
      try {
        await _notifications.zonedSchedule(
          id,
          title,
          body,
          scheduledTime,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: payload,
        );
      } catch (fallbackError) {
        debugPrint(
            'Error scheduling one-shot notification: $e / fallback: $fallbackError');
      }
    }
  }

  Future<void> showInstantNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_initialized) await initialize();

    const androidDetails = AndroidNotificationDetails(
      'adhan_channel',
      'أذان الصلاة',
      channelDescription: 'إشعارات أذان الصلاة',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      enableLights: true,
      icon: '@drawable/ic_notification',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(id, title, body, notificationDetails,
        payload: payload);
  }

  // ─── Download Notification Methods ─────────────────────────────────

  /// Localized download texts map
  static const _dlTexts = {
    'ar': {
      'downloading': 'جاري تحميل التحديث...',
      'downloading_quran': 'تحميل المصحف الصوتي...',
      'resuming_download': 'استئناف التحميل...',
      'pause': 'إيقاف مؤقت',
      'stop': 'إيقاف',
      'body_pct': 'تم تحميل {}%',
      'complete': '✅ التحديث جاهز',
      'install': 'اضغط للتثبيت',
      'error': '❌ فشل التحميل',
      'error_net': 'تحقق من الاتصال بالإنترنت',
      'error_storage': 'مساحة التخزين غير كافية',
      'error_url': 'رابط التحديث غير متاح',
      'waiting': '⏳ بانتظار الاتصال',
      'retrying': 'جاري إعادة المحاولة...',
      'retry': 'إعادة المحاولة',
    },
    'en': {
      'downloading': 'Downloading update...',
      'downloading_quran': 'Downloading Quran...',
      'resuming_download': 'Resuming download...',
      'pause': 'Pause',
      'stop': 'Stop',
      'body_pct': '{}% downloaded',
      'complete': '✅ Update ready',
      'install': 'Tap to install',
      'error': '❌ Download failed',
      'error_net': 'Check your internet connection',
      'error_storage': 'Not enough storage space',
      'error_url': 'Update link unavailable',
      'waiting': '⏳ Waiting for connection',
      'retrying': 'Retrying...',
      'retry': 'Retry',
    },
    'tr': {
      'downloading': 'Güncelleme indiriliyor...',
      'downloading_quran': 'Kuran indiriliyor...',
      'resuming_download': 'İndirme devam ediyor...',
      'pause': 'Duraklat',
      'stop': 'Durdur',
      'body_pct': '%{} indirildi',
      'complete': '✅ Güncelleme hazır',
      'install': 'Yüklemek için dokunun',
      'error': '❌ İndirme başarısız',
      'error_net': 'İnternet bağlantınızı kontrol edin',
      'error_storage': 'Yetersiz depolama alanı',
      'error_url': 'Güncelleme bağlantısı kullanılamıyor',
      'waiting': '⏳ Bağlantı bekleniyor',
      'retrying': 'Yeniden deneniyor...',
      'retry': 'Yeniden dene',
    },
    'fr': {
      'downloading': 'Téléchargement en cours...',
      'downloading_quran': 'Téléchargement du Coran...',
      'resuming_download': 'Reprise...',
      'pause': 'Pause',
      'stop': 'Arrêter',
      'body_pct': '{}% téléchargé',
      'complete': '✅ Mise à jour prête',
      'install': 'Appuyez pour installer',
      'error': '❌ Échec du téléchargement',
      'error_net': 'Vérifiez votre connexion internet',
      'error_storage': 'Espace de stockage insuffisant',
      'error_url': 'Lien de mise à jour indisponible',
      'waiting': '⏳ En attente de connexion',
      'retrying': 'Nouvelle tentative...',
      'retry': 'Réessayer',
    },
  };

  String _dl(String key, String locale) {
    try {
      final lang = _dlTexts[locale] ?? _dlTexts['ar']!;
      return lang[key] ?? _dlTexts['ar']![key] ?? key;
    } catch (_) {
      return key;
    }
  }

  Future<void> showModelDownloadProgress({
    required String locale,
    required int percent,
  }) async {
    if (!_initialized) await initialize();

    final title = locale == 'ar'
        ? 'جاري تحميل محرك صلة الذكي...'
        : 'Downloading Sila Smart Engine...';
    final body = locale == 'ar' ? 'تم تحميل $percent%' : '$percent% downloaded';

    final androidDetails = AndroidNotificationDetails(
      'download_controls_v1',
      'التحديثات',
      channelDescription: 'إشعارات تحميل التحديثات والتحكم بها',
      importance: Importance.max,
      priority: Priority.high,
      playSound: false,
      showProgress: true,
      maxProgress: 100,
      progress: percent,
      ongoing: true,
      autoCancel: false,
      onlyAlertOnce: true,
      icon: '@drawable/ic_notification',
    );

    final details = NotificationDetails(android: androidDetails);
    await _notifications.show(
        modelDownloadNotificationId, title, body, details);
  }

  Future<void> hideModelDownloadNotification() async {
    await _notifications.cancel(modelDownloadNotificationId);
  }

  Future<void> showDownloadProgress({
    required int id,
    required String locale,
    required int percent,
  }) async {
    if (!_initialized) await initialize();
    final title = _dl('downloading', locale);
    final body = _dl('body_pct', locale).replaceFirst('{}', '$percent');
    final androidDetails = AndroidNotificationDetails(
      'download_channel',
      'التحديثات',
      channelDescription: 'إشعارات تحميل التحديثات',
      importance: Importance.low,
      priority: Priority.low,
      playSound: false,
      showProgress: true,
      maxProgress: 100,
      progress: percent,
      ongoing: true,
      autoCancel: false,
      onlyAlertOnce: true,
      icon: '@drawable/ic_notification',
    );
    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: false,
      presentSound: false,
    );
    final details =
        NotificationDetails(android: androidDetails, iOS: iosDetails);
    await _notifications.show(id, title, body, details,
        payload: 'download_progress');
  }

  Future<void> showQuranDownloadProgress({
    required int id,
    required String locale,
    required int percent,
    required String reciterName,
    bool isPaused = false,
  }) async {
    if (!_initialized) await initialize();

    // ✅ تأكد من أن النسبة بين 0 و 100
    final clampedPercent = percent.clamp(0, 100);

    final title =
        _dl(isPaused ? 'resuming_download' : 'downloading_quran', locale);
    final body = '$reciterName: $clampedPercent%';

    final androidDetails = AndroidNotificationDetails(
      'download_controls_v1',
      'التحديثات',
      channelDescription: 'إشعارات تحميل التحديثات والتحكم بها',
      importance: Importance.max,
      priority: Priority.high,
      playSound: false,
      showProgress: true,
      maxProgress: 100,
      progress: clampedPercent, // ✅ استخدم القيمة المصححة
      ongoing: !isPaused,
      autoCancel: false,
      onlyAlertOnce: true,
      icon: '@drawable/ic_notification',
      actions: [
        AndroidNotificationAction(
          'pause_download',
          isPaused
              ? (locale == 'ar' ? 'استكمال' : 'Resume')
              : _dl('pause', locale),
          showsUserInterface: true,
        ),
        AndroidNotificationAction(
          'stop_download',
          _dl('stop', locale),
          showsUserInterface: true,
          cancelNotification: true,
        ),
      ],
    );
    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: false,
      presentSound: false,
    );
    final details =
        NotificationDetails(android: androidDetails, iOS: iosDetails);
    await _notifications.show(id, title, body, details,
        payload: 'quran_download_progress');
  }

  Future<void> showDownloadComplete({
    required int id,
    required String locale,
    required String apkPath,
  }) async {
    if (!_initialized) await initialize();
    _lastDownloadApkPath = apkPath;
    final title = _dl('complete', locale);
    final body = _dl('install', locale);
    final androidDetails = AndroidNotificationDetails(
      'download_channel',
      'التحديثات',
      channelDescription: 'إشعارات تحميل التحديثات',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      icon: '@drawable/ic_notification',
      actions: [
        AndroidNotificationAction(
          _installApkActionId,
          _dl('install', locale),
          cancelNotification: true,
          showsUserInterface: true,
        ),
      ],
    );
    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    final details =
        NotificationDetails(android: androidDetails, iOS: iosDetails);
    await _notifications.show(id, title, body, details,
        payload: 'install_apk:$apkPath');
  }

  Future<void> showDownloadError({
    required int id,
    required String locale,
    required String errorType,
    String? downloadUrl,
    bool withRetry = false,
  }) async {
    if (!_initialized) await initialize();
    _lastDownloadUrl = downloadUrl;
    final title = _dl('error', locale);
    String body;
    switch (errorType) {
      case 'storage':
        body = _dl('error_storage', locale);
        break;
      case 'url':
        body = _dl('error_url', locale);
        break;
      default:
        body = _dl('error_net', locale);
    }
    final androidDetails = AndroidNotificationDetails(
      'download_channel',
      'التحديثات',
      channelDescription: 'إشعارات تحميل التحديثات',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      playSound: true,
      icon: '@drawable/ic_notification',
      actions: withRetry
          ? [
              AndroidNotificationAction(
                _retryDownloadActionId,
                _dl('retry', locale),
                showsUserInterface: true,
              ),
            ]
          : null,
    );
    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: false,
      presentSound: true,
    );
    final details =
        NotificationDetails(android: androidDetails, iOS: iosDetails);
    await _notifications.show(id, title, body, details,
        payload: withRetry ? 'retry_download' : 'download_error');
  }

  Future<void> showDownloadWaiting({
    required int id,
    required String locale,
  }) async {
    if (!_initialized) await initialize();
    final title = _dl('waiting', locale);
    final body = _dl('retrying', locale);
    final androidDetails = AndroidNotificationDetails(
      'download_channel',
      'التحديثات',
      channelDescription: 'إشعارات تحميل التحديثات',
      importance: Importance.low,
      priority: Priority.low,
      playSound: false,
      ongoing: true,
      autoCancel: false,
      showProgress: true,
      indeterminate: true,
      icon: '@drawable/ic_notification',
    );
    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: false,
      presentSound: false,
    );
    final details =
        NotificationDetails(android: androidDetails, iOS: iosDetails);
    await _notifications.show(id, title, body, details,
        payload: 'download_waiting');
  }

  String? get lastDownloadApkPath => _lastDownloadApkPath;
  String? get lastDownloadUrl => _lastDownloadUrl;

  Future<void> rescheduleAllOnBoot() async {
    if (!_initialized) await initialize();
    try {
      final isar = await IsarService().db;
      final repo = IsarNotificationRepository(isar);
      final allSettings = await repo.getAllSettings();
      for (final setting in allSettings) {
        if (!setting.isEnabled || setting.timingType != 'fixed') continue;
        final now = DateTime.now();
        var scheduled = DateTime(
          now.year,
          now.month,
          now.day,
          setting.fixedHour,
          setting.fixedMinute,
        );
        if (!scheduled.isAfter(now)) {
          scheduled = scheduled.add(const Duration(days: 1));
        }
        await scheduleDaily(
          id: 2000 + setting.id,
          title: 'تذكير ${setting.featureKey}',
          body: 'لا تنس وردك اليومي',
          dateTime: scheduled,
        );
      }

      final pending = await getPendingNotifications();
      final hasSmartIds = pending.any((n) => n.id >= 100 && n.id <= 199);
      if (!hasSmartIds) {
        await _ensureFallbackSmartNotifications();
      }
    } catch (e) {
      debugPrint('rescheduleAllOnBoot failed: $e');
    }
  }

  Future<void> _ensureFallbackSmartNotifications() async {
    final now = DateTime.now();

    Future<DateTime> at(int hour, int minute) async {
      var dt = DateTime(now.year, now.month, now.day, hour, minute);
      if (!dt.isAfter(now)) dt = dt.add(const Duration(days: 1));
      return dt;
    }

    await scheduleOneShot(
      id: NotificationIds.wird,
      title: 'وقت وردك القرآني 📖',
      body: 'خصص دقائق لوردك اليومي.',
      dateTime: await at(7, 0),
      payload: 'wird_reminder',
    );
    await scheduleOneShot(
      id: NotificationIds.azkarSabah,
      title: 'أذكار الصباح 🌅',
      body: 'ابدأ يومك بذكر الله.',
      dateTime: await at(6, 0),
      payload: 'azkar_sabah',
    );
    await scheduleOneShot(
      id: NotificationIds.tasbih,
      title: 'لحظة للذكر والتسبيح ✦',
      body: 'اجعل لسانك رطبًا بذكر الله.',
      dateTime: await at(13, 30),
      payload: 'tasbih_reminder',
    );

    await scheduleOneShot(
      id: NotificationIds.dailyReport,
      title: 'تقريرك اليومي جاهز 📋',
      body: 'بعد المغرب: افتح متابعتي وراجع يومك بصدق وطمأنينة.',
      dateTime: await at(18, 30),
      payload: jsonEncode({'route': 'daily_report'}),
    );
  }

  /// Play Adhan sound directly in-app
  Future<void> playAdhan(String soundFile) async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.setReleaseMode(ReleaseMode.stop);
      if (soundFile.startsWith('http://') || soundFile.startsWith('https://')) {
        await _audioPlayer.play(UrlSource(soundFile));
      } else {
        await _audioPlayer.play(AssetSource('audio/$soundFile'));
      }
      await _showAdhanPlaybackNotification();
      print('Playing Adhan: $soundFile');
    } catch (e) {
      print('Error playing $soundFile, trying fallback: $e');
      // Try any available audio file as fallback
      try {
        await _audioPlayer.stop();
        await _audioPlayer.setReleaseMode(ReleaseMode.stop);
        await _audioPlayer.play(AssetSource('audio/adhan_egypt.mp3'));
        await _showAdhanPlaybackNotification();
      } catch (e2) {
        print('Fallback audio also failed: $e2');
      }
    }
  }

  Future<void> stopAdhan() async {
    await _audioPlayer.stop();
    await cancelNotification(_adhanPlaybackNotificationId);
  }

  Future<void> _showAdhanPlaybackNotification() async {
    const androidDetails = AndroidNotificationDetails(
      'adhan_channel',
      'أذان الصلاة',
      channelDescription: 'إشعارات أذان الصلاة',
      importance: Importance.max,
      priority: Priority.high,
      playSound: false,
      ongoing: true,
      autoCancel: false,
      onlyAlertOnce: true,
      icon: '@drawable/ic_notification',
      actions: [
        AndroidNotificationAction(
          _stopAdhanActionId,
          'إيقاف الأذان',
          cancelNotification: true,
          showsUserInterface: true,
        ),
      ],
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: false,
      presentSound: false,
    );

    const details =
        NotificationDetails(android: androidDetails, iOS: iosDetails);
    await _notifications.show(
      _adhanPlaybackNotificationId,
      'الأذان يعمل الآن',
      'اضغط لإيقاف الأذان',
      details,
      payload: _stopAdhanActionId,
    );
  }

  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  Future<void> scheduleDebugNotificationInSeconds({int seconds = 15}) async {
    if (!_initialized) await initialize();
    final now = DateTime.now();
    final at = now.add(Duration(seconds: seconds));
    await showInstantNotification(
      id: 9900,
      title: 'اختبار فوري',
      body: 'إذا ظهر هذا فورًا فالصلاحية الأساسية تعمل.',
      payload: jsonEncode({'route': 'debug_notification_now'}),
    );
    await scheduleOneShot(
      id: 9901,
      title: 'اختبار الإشعارات ✅',
      body: 'إذا ظهر هذا الإشعار فالنظام يعمل بشكل صحيح.',
      dateTime: at,
      payload: jsonEncode({'route': 'debug_notification'}),
    );
  }

  Future<void> showTestNotification() async {
    try {
      await _notifications.show(
        9999,
        'سِلى — اختبار الإشعارات 🕌',
        'إذا وصلك هذا الإشعار فالنظام يعمل بشكل صحيح',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'adhan_channel',
            'أذان الصلاة',
            channelDescription: 'إشعارات أذان الصلاة',
            importance: Importance.max,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
        ),
        payload: 'test',
      );
      debugPrint('✅ Test notification sent');
    } catch (e) {
      debugPrint('❌ Test notification failed: $e');
    }
  }

  Future<bool> scheduleDailyReminder({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    String payload = '',
  }) async {
    if (!_initialized) return false;

    debugPrint('📅 Scheduling daily: $title at $hour:$minute');

    // FIXED: Bug 2 — Build TZDateTime at the correct hour/minute, then use zonedSchedule with matchDateTimeComponents
    final now = tz.TZDateTime.now(tz.local);
    var scheduled =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now) || scheduled.isAtSameMomentAs(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      'adhan_channel',
      'أذان الصلاة',
      channelDescription: 'إشعارات أذان الصلاة',
      importance: Importance.max,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        scheduled,
        notificationDetails,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents
            .time, // FIXED: Bug 2 — Repeats daily at exact hour:minute
        payload: payload,
      );
      debugPrint('✅ Daily reminder scheduled: $title at $hour:$minute');
      return true;
    } catch (e) {
      debugPrint('⚠️ Exact daily reminder failed, trying inexact: $e');
      try {
        await _notifications.zonedSchedule(
          id,
          title,
          body,
          scheduled,
          notificationDetails,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          matchDateTimeComponents: DateTimeComponents.time, // FIXED: Bug 2
          payload: payload,
        );
        debugPrint(
            '✅ Inexact daily reminder scheduled: $title at $hour:$minute');
        return true;
      } catch (e2) {
        debugPrint('❌ Daily reminder failed: $e / fallback: $e2');
        return false;
      }
    }
  }

  void _onNotificationTap(NotificationResponse response) async {
    if (response.actionId == _stopAdhanActionId ||
        response.payload == _stopAdhanActionId) {
      await stopAdhan();
      return;
    }

    if (response.actionId == _pauseDownloadActionId) {
      onPauseDownload?.call();
      return;
    }

    if (response.actionId == _stopDownloadActionId) {
      onStopDownload?.call();
      return;
    }

    // Handle install APK action
    if (response.actionId == _installApkActionId ||
        (response.payload != null &&
            response.payload!.startsWith('install_apk:'))) {
      final path = response.actionId == _installApkActionId
          ? _lastDownloadApkPath
          : response.payload!.replaceFirst('install_apk:', '');
      if (path != null) {
        await OpenFile.open(path);
      }
      return;
    }

    // Handle retry download action — store URL for next launch check
    if (response.actionId == _retryDownloadActionId ||
        response.payload == 'retry_download') {
      // The retry callback will be invoked if set by UpdateService
      if (_onRetryDownload != null && _lastDownloadUrl != null) {
        _onRetryDownload!(_lastDownloadUrl!);
      }
      return;
    }

    handleNotificationPayload(response.payload);
  }

  /// Callback invoked when user taps "Retry" on a failed download notification.
  /// Set by UpdateService.downloadInBackground().
  void Function(String url)? _onRetryDownload;
  void setRetryCallback(void Function(String url) callback) {
    _onRetryDownload = callback;
  }

  Future<void> handleNotificationPayload(String? payload) async {
    if (payload == null || payload.trim().isEmpty) return;

    final normalized = payload.trim();

    // FIXED: Bug 3 — Removed playAdhan() for prayer payloads.
    // The OS already plays the adhan sound natively via RawResourceAndroidNotificationSound on the channel.
    // On tap, we only navigate to the prayers page so the user can see prayer info.
    final adhanPayloads = {'fajr', 'dhuhr', 'asr', 'maghrib', 'isha'};
    if (adhanPayloads.contains(normalized.toLowerCase())) {
      final nav = _navigatorKey?.currentState;
      if (nav == null) {
        _deferredPayload = normalized;
        return;
      }
      nav.push(MaterialPageRoute(builder: (_) => const PrayersPage()));
      return;
    }

    final nav = _navigatorKey?.currentState;
    if (nav == null) {
      _deferredPayload = normalized;
      return;
    }

    try {
      final decoded = jsonDecode(normalized);
      if (decoded is Map<String, dynamic> &&
          decoded.containsKey('content_id') &&
          decoded.containsKey('category')) {
        // FIXED: Bug 4 — Increment shownCount when the user actually taps the notification
        try {
          final isar = await IsarService().db;
          final repo = IsarNotificationRepository(isar);
          final content = await repo
              .getContentByContentId(decoded['content_id'].toString());
          if (content != null) {
            content.shownCount = content.shownCount + 1;
            content.lastShown = DateTime.now();
            await repo.saveContent(content);
          }
        } catch (e) {
          debugPrint('Failed to update shownCount: $e');
        }

        nav.push(
          MaterialPageRoute(
            builder: (_) => NotificationDetailPage(
              contentId: decoded['content_id'].toString(),
              category: decoded['category'].toString(),
            ),
          ),
        );
        return;
      }

      if (decoded is Map<String, dynamic> &&
          decoded['route'] == 'daily_report') {
        nav.push(MaterialPageRoute(builder: (_) => const DailyReportPage()));
        return;
      }

      if (decoded is Map<String, dynamic> &&
          decoded['route'] == 'ibadah_signal') {
        nav.push(MaterialPageRoute(
            builder: (_) => const PrayersPage(initialTabIndex: 1)));
        return;
      }
    } catch (_) {
      // ignore malformed payloads
    }
  }

  /// Get prayer name in current app locale for notifications
  String _localizedPrayerName(String key) {
    final navigatorContext = _navigatorKey?.currentContext;
    final locale = navigatorContext != null
        ? EasyLocalization.of(navigatorContext)?.locale.languageCode ?? 'ar'
        : 'ar';
    final map = _prayerNames[locale] ?? _prayerNames['ar']!;
    return map[key.toLowerCase()] ?? key;
  }

  static const _prayerNames = {
    'ar': {
      'fajr': 'الفجر',
      'dhuhr': 'الظهر',
      'asr': 'العصر',
      'maghrib': 'المغرب',
      'isha': 'العشاء'
    },
    'en': {
      'fajr': 'Fajr',
      'dhuhr': 'Dhuhr',
      'asr': 'Asr',
      'maghrib': 'Maghrib',
      'isha': 'Isha'
    },
    'tr': {
      'fajr': 'İmsak',
      'dhuhr': 'Öğle',
      'asr': 'İkindi',
      'maghrib': 'Akşam',
      'isha': 'Yatsı'
    },
    'fr': {
      'fajr': 'Fajr',
      'dhuhr': 'Dhuhr',
      'asr': 'Asr',
      'maghrib': 'Maghrib',
      'isha': 'Isha'
    },
  };

  String _getPrayerNameArabic(String name) {
    const map = {
      'fajr': 'الفجر',
      'dhuhr': 'الظهر',
      'asr': 'العصر',
      'maghrib': 'المغرب',
      'isha': 'العشاء',
    };
    return map[name.toLowerCase()] ?? name;
  }

  static int getNotificationId(String prayerName) {
    const map = {'fajr': 1, 'dhuhr': 2, 'asr': 3, 'maghrib': 4, 'isha': 5};
    return map[prayerName.toLowerCase()] ?? 0;
  }

  Future<void> _showUpdateNotification(RemoteMessage message) async {
    final context = _navigatorKey?.currentContext;
    if (context == null) return;

    final analytics = AnalyticsService();
    final updateService = UpdateService(analytics: analytics);
    final remoteConfig = RemoteConfigService();
    await remoteConfig.initialize();

    final version =
        int.tryParse(message.data['version']?.toString() ?? '') ?? 0;
    final apkUrl = (message.data['apk_url']?.toString() ?? '').isNotEmpty
        ? message.data['apk_url']!.toString()
        : remoteConfig.apkUrl;

    final result = UpdateCheckResult(
      hasUpdate: true,
      isForced: remoteConfig.forceUpdate,
      latestVersion: version,
      apkUrl: apkUrl,
      releaseNotes: message.data['release_notes']?.toString() ?? '',
    );

    await analytics.logUpdateDialogShown(newVersion: version);

    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => UpdateDialog(
        updateResult: result,
        updateService: updateService,
        analyticsService: analytics,
      ),
    );
  }
}
