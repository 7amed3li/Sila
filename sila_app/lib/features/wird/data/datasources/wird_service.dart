import 'package:isar/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sila_app/features/wird/data/models/wird_history.dart';
import 'package:sila_app/features/wird/data/models/wird_settings.dart';

class WirdService {
  WirdService(this._isar);
  final Isar _isar;

  static const String _goalTypeKey = 'wird_goal_type';
  static const String _goalValueKey = 'wird_goal_value';
  static const String _hasGoalKey = 'wird_has_goal';

  static const String _targetPageKey = r'wird_target_page';
  static const String _lastTargetCalcDateKey = r'wird_last_target_calc_date';

  Future<WirdSettings> getSettings() async {
    final settings =
        await _isar.wirdSettings.where().findFirst() ?? WirdSettings();
    final prefs = await SharedPreferences.getInstance();

    // Load from SharedPreferences
    settings.goalType = WirdGoalType.values[prefs.getInt(_goalTypeKey) ?? 0];
    settings.goalValue = prefs.getInt(_goalValueKey) ?? 2;
    settings.hasConfiguredGoal = prefs.getBool(_hasGoalKey) ?? false;

    if (settings.id == Isar.autoIncrement) {
      settings.currentPage = 1;
      settings.khatmaStartDate = DateTime.now();
      await _isar.writeTxn(() async {
        await _isar.wirdSettings.put(settings);
      });
    }

    // Calculate/Retrieve stable target page for today
    final lastCalcStr = prefs.getString(_lastTargetCalcDateKey);
    final todayStr = DateTime.now().toIso8601String().split('T')[0];

    var stableTarget = prefs.getInt(_targetPageKey);

    if (lastCalcStr != todayStr || stableTarget == null) {
      // It's a new day or no target set yet, calculate new target
      var increment = 0;
      switch (settings.goalType) {
        case WirdGoalType.page:
          increment = settings.goalValue;
          break;
        case WirdGoalType.juz:
          increment = settings.goalValue * 20;
          break;
        case WirdGoalType.hizb:
          increment = settings.goalValue * 10;
          break;
      }

      stableTarget = (settings.currentPage + increment - 1).clamp(1, 604);
      await prefs.setInt(_targetPageKey, stableTarget);
      await prefs.setString(_lastTargetCalcDateKey, todayStr);
    }

    // We override the getter logic by using a field if we had one,
    // but for now, we'll let the controller know the stable target.
    // Actually, I'll store it in the settings object for the controller to read.
    settings.targetPageForToday = stableTarget;

    return settings;
  }

  Future<void> updateGoal(WirdGoalType type, int value) async {
    final settings = await getSettings();
    final prefs = await SharedPreferences.getInstance();

    await prefs.setInt(_goalTypeKey, type.index);
    await prefs.setInt(_goalValueKey, value);
    await prefs.setBool(_hasGoalKey, true);

    // Force recalculation of today's target based on the new goal
    await prefs.remove(_targetPageKey);
    await prefs.remove(_lastTargetCalcDateKey);

    // Reset start date for the new goal journey
    settings.khatmaStartDate = DateTime.now();
    await _isar.writeTxn(() async {
      await _isar.wirdSettings.put(settings);
    });
  }

  Future<List<WirdHistory>> getHistory({int? limit}) async {
    final query = _isar.wirdHistorys.where().sortByDateDesc();
    if (limit != null && limit > 0) {
      return await query.limit(limit).findAll();
    }
    return await query.limit(100).findAll();
  }

  Future<void> updateCurrentPage(int page) async {
    final settings = await getSettings();
    settings.currentPage = page;

    await _isar.writeTxn(() async {
      await _isar.wirdSettings.put(settings);
    });
  }

  Future<void> updateBookmark(int page) async {
    final settings = await getSettings();
    settings.bookmarkPage = page;

    await _isar.writeTxn(() async {
      await _isar.wirdSettings.put(settings);
    });
  }

  Future<void> completeDailyWird(int startPage, int endPage) async {
    final settings = await getSettings();
    final prefs = await SharedPreferences.getInstance();

    settings.lastCompletionDate = DateTime.now();
    settings.currentPage =
        (endPage + 1).clamp(1, 604); // Advance to the next fresh page

    // Increment the stable target for today so the user can continue to the next portion
    var increment = 0;
    switch (settings.goalType) {
      case WirdGoalType.page:
        increment = settings.goalValue;
        break;
      case WirdGoalType.juz:
        increment = settings.goalValue * 20;
        break;
      case WirdGoalType.hizb:
        increment = settings.goalValue * 10;
        break;
    }
    final nextTarget = (settings.currentPage + increment - 1).clamp(1, 604);
    await prefs.setInt(_targetPageKey, nextTarget);

    final history = WirdHistory()
      ..date = DateTime.now()
      ..startPage = startPage
      ..endPage = endPage
      ..isFullCompletion = true;

    await _isar.writeTxn(() async {
      await _isar.wirdSettings.put(settings);
      await _isar.wirdHistorys.put(history);
    });
  }

  Future<void> resetKhatma() async {
    final settings = await getSettings();

    settings.currentPage = 1;
    settings.khatmaStartDate = DateTime.now();
    settings.lastCompletionDate = null;

    await _isar.writeTxn(() async {
      await _isar.wirdSettings.put(settings);
    });
  }
}
