import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sila_app/core/services/analytics_service.dart';
import 'package:sila_app/features/vefa/presentation/riverpod/vefa_providers.dart';
import 'package:sila_app/features/wird/data/datasources/wird_service.dart';
import 'package:sila_app/features/wird/data/models/wird_history.dart';
import 'package:sila_app/features/wird/data/models/wird_settings.dart';
import 'package:sila_app/features/hifz/presentation/controllers/hifz_home_controller.dart';
import 'package:sila_app/features/ibadah_tracker/presentation/controllers/ibadah_tracker_controller.dart';
import 'package:sila_app/features/notifications/presentation/controllers/notification_providers.dart';

// Provider for WirdService
final wirdServiceProvider = FutureProvider<WirdService>((ref) async {
  final isar = await ref.watch(isarInstanceProvider.future);
  return WirdService(isar);
});

// State class for the Wird
class WirdState {
  WirdState({
    required this.currentPage,
    required this.goalType,
    required this.goalValue,
    required this.targetPage,
    required this.isCompletedToday,
    this.khatmaStart,
    required this.daysDifference,
    required this.khatmaProgress,
    required this.dailyProgress,
    required this.history,
    required this.completedWirdsCount,
    required this.remainingWirdsCount,
    this.bookmarkPage,
    required this.hasConfiguredGoal,
  });
  final int currentPage;
  final WirdGoalType goalType;
  final int goalValue;
  final int targetPage;
  final bool isCompletedToday;
  final DateTime? khatmaStart;
  final int daysDifference;
  final double khatmaProgress;
  final double dailyProgress;
  final List<WirdHistory> history;
  final int completedWirdsCount;
  final int remainingWirdsCount;
  final int? bookmarkPage;
  final bool hasConfiguredGoal;

  String get progressText => 'من صفحة $currentPage إلى صفحة $targetPage';
}

// Controller
class WirdController extends StateNotifier<AsyncValue<WirdState>> {
  WirdController(this._service, this._ref) : super(const AsyncValue.loading()) {
    _loadSettings();
  }
  final WirdService _service;
  final Ref _ref;
  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await _service.getSettings();
      final history = await _service.getHistory();
      final now = DateTime.now();

      // Check if completed today
      var completed = false;
      if (settings.lastCompletionDate != null) {
        final last = settings.lastCompletionDate!;
        if (last.year == now.year &&
            last.month == now.month &&
            last.day == now.day) {
          completed = true;
        }
      }

      final targetPage = settings.targetPageForToday;
      const totalQuranPages = WirdSettings.totalQuranPages;

      // Progress calculations
      final progress = settings.currentPage / totalQuranPages;

      // Daily progress
      var dailyProgress = 0.0;
      if (settings.hasConfiguredGoal) {
        if (completed) {
          dailyProgress = 1.0;
        } else {
          // Calculate how many pages were already read towards the goal today
          // Since we don't have 'startPageOfToday', we use the distance to targetPage
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

          final startOfGoal =
              (targetPage - increment).clamp(1, totalQuranPages);
          final currentProgress =
              (settings.currentPage - startOfGoal).clamp(0, increment);
          dailyProgress = (currentProgress / increment).clamp(0.0, 1.0);
        }
      }

      // Calculate Khatma Stats
      var daysDifference = 0;
      final completedWirdsCount = history.length;
      var remainingWirdsCount = 0;

      if (settings.khatmaStartDate != null) {
        // Fix: Use normalized dates for comparison
        final today = DateTime(now.year, now.month, now.day);
        final start = DateTime(settings.khatmaStartDate!.year,
            settings.khatmaStartDate!.month, settings.khatmaStartDate!.day);
        final elapsedDays =
            today.difference(start).inDays; // 0 if started today

        // Calculate increment (pages per day)
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

        if (increment > 0) {
          // How many full daily portions have been completed based strictly on current page
          // e.g., if increment is 20, and currentPage is 1: expectedDaysOfReading = 0
          // if currentPage is 21: expectedDaysOfReading = 1
          final expectedDaysOfReading =
              ((settings.currentPage - 1) / increment).floor();

          // If elapsedDays == 0 (started today), you are expected to have 0 reading done so far to be "on track".
          // If elapsedDays == 1 (started yesterday), you are expected to have 1 reading done.
          daysDifference = expectedDaysOfReading - elapsedDays;

          // Calculate remaining
          remainingWirdsCount =
              ((604 - settings.currentPage) / increment).ceil();
        }
      }

      if (_isDisposed) return;
      state = AsyncValue.data(WirdState(
        currentPage: settings.currentPage,
        goalType: settings.goalType,
        goalValue: settings.goalValue,
        targetPage: targetPage,
        isCompletedToday: completed,
        khatmaStart: settings.khatmaStartDate,
        daysDifference: daysDifference,
        khatmaProgress: progress,
        dailyProgress: dailyProgress,
        history: history,
        completedWirdsCount: completedWirdsCount,
        remainingWirdsCount: remainingWirdsCount,
        bookmarkPage: settings.bookmarkPage,
        hasConfiguredGoal: settings.hasConfiguredGoal,
      ));
    } catch (e, st) {
      if (_isDisposed) return;
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateGoal(WirdGoalType type, int value) async {
    await _service.updateGoal(type, value);
    await _loadSettings();
  }

  Future<void> updateCurrentPage(int page) async {
    if (state.value?.currentPage != page) {
      await _service.updateCurrentPage(page);
      _ref.read(analyticsServiceProvider).logWirdPageRead(pageNumber: page);
      await _loadSettings();
      _refreshGlobalDashboards();
    }
  }

  Future<void> updateBookmark(int page) async {
    await _service.updateBookmark(page);
    await _loadSettings();
  }

  Future<void> completeWird(int startPage, int endPage) async {
    await _service.completeDailyWird(startPage, endPage);
    if (endPage >= 604) {
      _ref.read(analyticsServiceProvider).logWirdKhatmaComplete();
    }
    await _loadSettings();
    _refreshGlobalDashboards();
  }

  Future<void> startNewKhatma() async {
    // Save the last portion if not already saved (assuming it was)
    // Reset reading progress to page 1
    await _service.updateCurrentPage(1);

    // Optionally, we could record a 'Khatma Completed' event in history here.

    await _loadSettings();
    _refreshGlobalDashboards();
  }

  void _refreshGlobalDashboards() {
    _ref.invalidate(ibadahTrackerControllerProvider);
    _ref.invalidate(streakTrackerProvider);
    _ref.invalidate(hifzHomeControllerProvider);
  }
}

// Global Provider
final wirdControllerProvider =
    StateNotifierProvider<WirdController, AsyncValue<WirdState>>((ref) {
  final asyncService = ref.watch(wirdServiceProvider);
  return asyncService.when(
    data: (service) => WirdController(service, ref),
    loading: () => WirdController(_FallbackWirdService(), ref),
    error: (error, stackTrace) => WirdController(_FallbackWirdService(), ref),
  );
});

class _FallbackWirdService implements WirdService {
  @override
  Future<void> completeDailyWird(int startPage, int endPage) async {
    // Silently handle - the real service will be loaded
  }

  @override
  Future<List<WirdHistory>> getHistory({int? limit}) async {
    return [];
  }

  @override
  Future<WirdSettings> getSettings() async {
    return WirdSettings();
  }

  @override
  Future<void> updateBookmark(int page) async {
    // Silently handle
  }

  @override
  Future<void> updateCurrentPage(int page) async {
    // Silently handle
  }

  @override
  Future<void> updateGoal(WirdGoalType type, int value) async {
    // Silently handle
  }

  @override
  Future<void> resetKhatma() async {
    // Silently handle
  }
}
