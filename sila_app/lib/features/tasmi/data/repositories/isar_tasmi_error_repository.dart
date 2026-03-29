import 'package:isar/isar.dart';
import 'package:sila_app/features/tasmi/data/models/tasmi_word_error.dart';
import 'package:sila_app/features/tasmi/data/repositories/i_tasmi_error_repository.dart';

class IsarTasmiErrorRepository implements ITasmiErrorRepository {
  IsarTasmiErrorRepository(this._isar);
  final Isar _isar;

  @override
  Future<void> saveError(TasmiWordError error) async {
    await _isar.writeTxn(() async {
      await _isar.tasmiWordErrors.put(error);
    });
  }

  @override
  Future<List<TasmiWordError>> getAll() async {
    return await _isar.tasmiWordErrors.where().limit(500).findAll();
  }

  @override
  Future<List<TasmiWordError>> getBySurah(int surahIndex) async {
    return await _isar.tasmiWordErrors
        .filter()
        .surahIndexEqualTo(surahIndex)
        .findAll();
  }

  @override
  Future<void> clearAll() async {
    await _isar.writeTxn(() async {
      await _isar.tasmiWordErrors.clear();
    });
  }

  // TODO[phase-2: ReportEngine]:
  //   Add getGroupedBySurah() for weekly error report

  // TODO[phase-2: SmartReview]:
  //   Add getMostFrequentErrors(int limit) for
  //   targeted re-memorization sessions
}
