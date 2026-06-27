import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sila_app/features/notifications/data/models/notification_settings.dart';
import 'package:sila_app/features/notifications/presentation/controllers/notification_providers.dart';

final notificationSettingsProvider = StateNotifierProvider.family<
    NotificationSettingsController,
    AsyncValue<NotificationSettings>,
    String>((ref, featureKey) {
  return NotificationSettingsController(ref, featureKey);
});

class NotificationSettingsController
    extends StateNotifier<AsyncValue<NotificationSettings>> {
  NotificationSettingsController(this._ref, this._featureKey)
      : super(const AsyncValue.loading()) {
    _load();
  }
  final Ref _ref;
  final String _featureKey;

  Future<void> _load() async {
    Object? lastError;
    StackTrace? lastStack;

    for (var i = 0; i < 3; i++) {
      try {
        final repo = await _ref.read(notificationRepositoryProvider.future);
        final settings = await repo.getSettings(_featureKey);
        state = AsyncValue.data(settings);
        return;
      } catch (e, st) {
        lastError = e;
        lastStack = st;
        await Future<void>.delayed(Duration(milliseconds: 150 * (i + 1)));
      }
    }

    debugPrint(
        'Notification settings load failed for $_featureKey: $lastError');

    try {
      final fallback = NotificationSettings()..featureKey = _featureKey;
      switch (_featureKey) {
        case 'azkar':
          fallback.fixedHour = 6;
          break;
        case 'wird':
          fallback.fixedHour = 8;
          break;
        case 'hifz':
          fallback.fixedHour = 10;
          break;
        case 'tasbih':
          fallback.fixedHour = 16;
          break;
        case 'scholars':
          fallback.fixedHour = 18;
          break;
        case 'salah':
        case 'prayer':
          fallback.fixedHour = 7;
          break;
      }
      state = AsyncValue.data(fallback);
    } catch (_) {
      state = AsyncValue.error(lastError ?? Exception('Settings load failed'),
          lastStack ?? StackTrace.current);
    }
  }

  Future<void> toggleEnabled(bool value) => _update((s) => s.isEnabled = value);
  Future<void> setFrequency(String value) =>
      _update((s) => s.frequency = value);
  Future<void> setFixedTime(int hour, int minute) => _update((s) {
        s.timingType = 'fixed';
        s.fixedHour = hour;
        s.fixedMinute = minute;
      });

  Future<void> setRelativeToPrayer(String prayerName, int minutesAfter) =>
      _update((s) {
        s.timingType = 'relative_to_prayer';
        s.prayerName = prayerName;
        s.minutesAfterPrayer = minutesAfter;
      });

  Future<void> togglePreferredType(String type) => _update((s) {
        if (s.preferredTypes.contains(type)) {
          s.preferredTypes = s.preferredTypes.where((e) => e != type).toList();
        } else {
          s.preferredTypes = [...s.preferredTypes, type];
        }
      });

  Future<void> toggleEndTimeReminder(bool value) =>
      _update((s) => s.endTimeReminderEnabled = value);

  Future<void> _update(
      void Function(NotificationSettings settings) change) async {
    final current = state.value;
    if (current == null) return;
    final next = NotificationSettings()
      ..id = current.id
      ..featureKey = current.featureKey
      ..isEnabled = current.isEnabled
      ..timingType = current.timingType
      ..fixedHour = current.fixedHour
      ..fixedMinute = current.fixedMinute
      ..prayerName = current.prayerName
      ..minutesAfterPrayer = current.minutesAfterPrayer
      ..frequency = current.frequency
      ..weekDays = List<int>.from(current.weekDays)
      ..preferredTypes = List<String>.from(current.preferredTypes)
      ..endTimeReminderEnabled = current.endTimeReminderEnabled;
    change(next);
    state = AsyncValue.data(next);
    final repo = await _ref.read(notificationRepositoryProvider.future);
    await repo.saveSettings(next);
  }
}
