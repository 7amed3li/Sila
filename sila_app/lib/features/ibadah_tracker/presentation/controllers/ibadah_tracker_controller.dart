import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sila_app/features/ibadah_tracker/data/models/ibadah_record.dart';
import 'package:sila_app/features/ibadah_tracker/data/models/user_gender_prefs.dart';
import 'package:sila_app/features/ibadah_tracker/data/repositories/i_ibadah_repository.dart';
import 'package:sila_app/features/ibadah_tracker/data/repositories/isar_ibadah_repository.dart';
import 'package:sila_app/features/ibadah_tracker/domain/daily_status_calculator.dart';
import 'package:sila_app/features/vefa/presentation/riverpod/vefa_providers.dart';
import 'package:sila_app/features/hifz/presentation/controllers/hifz_home_controller.dart';
import 'package:sila_app/features/notifications/presentation/controllers/notification_providers.dart';
import 'package:sila_app/features/wird/presentation/riverpod/wird_controller.dart';

class IbadahTrackerState {

  const IbadahTrackerState({
    required this.today,
    required this.yesterday,
    required this.gender,
    required this.onboardingNeeded,
    required this.completionRatio,
    required this.completedCount,
    required this.totalCount,
  });
  final IbadahRecord today;
  final IbadahRecord? yesterday;
  final UserGenderPrefs? gender;
  final bool onboardingNeeded;
  final double completionRatio;
  final int completedCount;
  final int totalCount;

  bool get isMale => gender?.isMale == true;
}

final ibadahRepositoryProvider = FutureProvider<IIbadahRepository>((ref) async {
  final isar = await ref.watch(isarInstanceProvider.future);
  return IsarIbadahRepository(isar);
});

class IbadahTrackerController extends StateNotifier<AsyncValue<IbadahTrackerState>> {
  IbadahTrackerController({
    required Future<IIbadahRepository> repositoryFuture,
    required Ref ref,
  })  : _repositoryFuture = repositoryFuture,
        _ref = ref,
        super(const AsyncValue.loading()) {
    load();
  }

  final Future<IIbadahRepository> _repositoryFuture;
  final Ref _ref;

  DateTime _normalize(DateTime date) => DateTime(date.year, date.month, date.day);

  bool _hasMeaningfulData(IbadahRecord record, {required bool isMale}) {
    final hasPrayer =
        record.fajrStatus > 0 ||
        record.dhuhrStatus > 0 ||
        record.asrStatus > 0 ||
        record.maghribStatus > 0 ||
        record.ishaStatus > 0;

    final hasOther =
        record.readWird ||
        record.readAzkarSabah ||
        record.readAzkarMasa ||
        record.didTasbih ||
        record.didHifz ||
        record.didTasmi ||
        record.rememberedAllah;

    final hasNote = (record.personalNote ?? '').trim().isNotEmpty;

    final hasMasjid =
        isMale &&
        (record.fajrInMasjid != null ||
            record.dhuhrInMasjid != null ||
            record.asrInMasjid != null ||
            record.maghribInMasjid != null ||
            record.ishaInMasjid != null);

    return hasPrayer || hasOther || hasNote || hasMasjid;
  }

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final repository = await _repositoryFuture;
      final now = _normalize(DateTime.now());
      final yesterdayDate = now.subtract(const Duration(days: 1));

      final today = await repository.getOrCreateRecord(now);
      final yesterdayRaw = await repository.getRecord(yesterdayDate);
      final gender = await repository.getGenderPrefs();

      final isMale = gender?.isMale == true;
      final yesterday =
          (yesterdayRaw != null && _hasMeaningfulData(yesterdayRaw, isMale: isMale))
          ? yesterdayRaw
          : null;
      final ratio = DailyStatusCalculator.completionRatio(today, isMale: isMale);
      final done = DailyStatusCalculator.completedCount(today, isMale: isMale);
      final total = DailyStatusCalculator.totalCount(isMale: isMale);

      state = AsyncValue.data(
        IbadahTrackerState(
          today: today,
          yesterday: yesterday,
          gender: gender,
          onboardingNeeded: gender == null || !gender.onboardingDone,
          completionRatio: ratio,
          completedCount: done,
          totalCount: total,
        ),
      );
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> setGender({required bool isMale}) async {
    final repository = await _repositoryFuture;
    await repository.setGenderPrefs(isMale: isMale);
    await load();
    _refreshGlobalDashboards();
  }

  Future<void> updatePrayerStatus({required String prayer, required int status}) async {
    final current = state.valueOrNull;
    if (current == null) return;
    final repository = await _repositoryFuture;
    await repository.updatePrayerStatus(date: current.today.date, prayer: prayer, status: status);
    await load();
    _refreshGlobalDashboards();
  }

  Future<void> updateMasjidStatus({required String prayer, required bool inMasjid}) async {
    final current = state.valueOrNull;
    if (current == null) return;
    final repository = await _repositoryFuture;
    await repository.updateMasjidStatus(
      date: current.today.date,
      prayer: prayer,
      inMasjid: inMasjid,
    );
    await load();
    _refreshGlobalDashboards();
  }

  Future<void> updateBoolStatus({required String key, required bool value}) async {
    final current = state.valueOrNull;
    if (current == null) return;
    final repository = await _repositoryFuture;
    await repository.updateBoolStatus(date: current.today.date, key: key, value: value);
    await load();
    _refreshGlobalDashboards();
  }

  Future<void> updatePersonalNote(String note) async {
    final current = state.valueOrNull;
    if (current == null) return;
    final repository = await _repositoryFuture;
    await repository.updatePersonalNote(date: current.today.date, note: note);
    await load();
    _refreshGlobalDashboards();
  }

  void _refreshGlobalDashboards() {
    _ref.invalidate(streakTrackerProvider);
    _ref.invalidate(hifzHomeControllerProvider);
    _ref.invalidate(wirdControllerProvider);
  }
}

final ibadahTrackerControllerProvider = StateNotifierProvider<
  IbadahTrackerController,
  AsyncValue<IbadahTrackerState>
>((ref) {
  final repoFuture = ref.watch(ibadahRepositoryProvider.future);
  return IbadahTrackerController(repositoryFuture: repoFuture, ref: ref);
});
