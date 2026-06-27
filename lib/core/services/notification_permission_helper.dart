// lib/core/services/notification_permission_helper.dart
// أضف الملف ده جديد في مشروعك

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationPermissionHelper {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  /// Returns true only when required notification permissions are granted.
  static Future<bool> requestAllPermissions() async {
    if (!Platform.isAndroid) {
      return true;
    }

    try {
      await _requestPostNotificationsPermission();
      await _requestExactAlarmPermission();
      await _requestBatteryOptimizationExemption();
      return await areAllPermissionsGranted();
    } catch (e) {
      debugPrint('Permission request flow failed: $e');
      return false;
    }
  }

  static Future<bool> areAllPermissionsGranted() async {
    if (!Platform.isAndroid) {
      return true;
    }

    final notificationsGranted = await Permission.notification.isGranted;
    final exactAlarmGranted = await Permission.scheduleExactAlarm.isGranted;
    return notificationsGranted && exactAlarmGranted;
  }

  // ─── POST_NOTIFICATIONS (Android 13+) ────────────────────────────────────
  static Future<void> _requestPostNotificationsPermission() async {
    final status = await Permission.notification.status;
    if (status.isDenied) {
      await Permission.notification.request();
    }
  }

  // ─── SCHEDULE_EXACT_ALARM (Android 12+) ──────────────────────────────────
  static Future<void> _requestExactAlarmPermission() async {
    // flutter_local_notifications يوفر هذه الطريقة مباشرة
    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      // Android 12+ — يطلب إذن الـ exact alarm
      final bool? exactAlarmGranted =
          await androidPlugin.requestExactAlarmsPermission();

      if (exactAlarmGranted == false) {
        debugPrint(
            '⚠️ Exact alarm permission denied — notifications may not fire at exact times');
      }
    }
  }

  // ─── BATTERY OPTIMIZATION EXEMPTION ──────────────────────────────────────
  static Future<void> _requestBatteryOptimizationExemption() async {
    final status = await Permission.ignoreBatteryOptimizations.status;
    if (status.isDenied) {
      final result = await Permission.ignoreBatteryOptimizations.request();
      if (result.isPermanentlyDenied) {
        // Keep non-blocking; let UI decide if it should open settings.
        debugPrint('⚠️ Battery optimization exemption permanently denied');
      }
    }
  }

  // ─── CHECK & RECREATE NOTIFICATION CHANNEL (if deleted by user) ──────────
  static Future<void> ensureNotificationChannel() async {
    if (!Platform.isAndroid) return;

    const AndroidNotificationChannel adhanChannel = AndroidNotificationChannel(
      'adhan_channel',
      'Adhan Notifications',
      description: 'Prayer time notifications',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
      enableLights: true,
    );

    const AndroidNotificationChannel dhikrChannel = AndroidNotificationChannel(
      'dhikr_channel',
      'Dhikr Reminders',
      description: 'Dhikr reminder notifications',
      importance: Importance.high,
      playSound: true,
    );

    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(adhanChannel);
      await androidPlugin.createNotificationChannel(dhikrChannel);
      debugPrint('✅ Notification channels created/verified');
    }
  }
}
