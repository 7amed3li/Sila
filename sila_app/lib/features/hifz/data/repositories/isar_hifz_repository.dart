import 'package:isar/isar.dart';
import 'package:sila_app/features/hifz/data/models/hifz_moment.dart';
import 'package:sila_app/features/hifz/data/models/hifz_session.dart';
import 'package:sila_app/features/hifz/data/models/hifz_settings.dart';
import 'package:sila_app/features/hifz/data/models/hifz_user_profile.dart';
import 'package:sila_app/features/hifz/data/models/hifz_verse_record.dart';
import 'package:sila_app/features/hifz/data/repositories/i_hifz_repository.dart';

class IsarHifzRepository implements IHifzRepository {
  IsarHifzRepository(Isar isar) {
    _isar = isar;
  }
  late final Isar _isar;

  @override
  Future<HifzUserProfile?> getProfile() async {
    return await _isar.hifzUserProfiles
        .where()
        .sortByCreatedAtDesc()
        .findFirst();
  }

  @override
  Future<void> saveProfile(HifzUserProfile profile) async {
    await _isar.writeTxn(() async {
      await _isar.hifzUserProfiles.put(profile);
    });
  }

  @override
  Future<HifzVerseRecord?> getVerseRecord(
      int surahIndex, int verseNumber) async {
    return await _isar.hifzVerseRecords
        .filter()
        .surahIndexEqualTo(surahIndex)
        .verseNumberEqualTo(verseNumber)
        .findFirst();
  }

  @override
  Future<List<HifzVerseRecord>> getAllRecords({int? limit}) async {
    final query = _isar.hifzVerseRecords.where();
    if (limit != null && limit > 0) {
      return await query.limit(limit).findAll();
    }
    return await query.limit(500).findAll();
  }

  @override
  Future<List<HifzVerseRecord>> getDueReviews(DateTime before) async {
    return await _isar.hifzVerseRecords
        .filter()
        .nextReviewDateLessThan(before, include: true)
        .findAll();
  }

  @override
  Future<void> saveVerseRecord(HifzVerseRecord record) async {
    await _isar.writeTxn(() async {
      await _isar.hifzVerseRecords.put(record);
    });
  }

  @override
  Future<void> saveSession(HifzSession session) async {
    await _isar.writeTxn(() async {
      await _isar.hifzSessions.put(session);
    });
  }

  @override
  Future<List<HifzSession>> getRecentSessions(int limit) async {
    return await _isar.hifzSessions
        .where()
        .sortByDateDesc()
        .limit(limit)
        .findAll();
  }

  @override
  Future<void> saveMoment(HifzMoment moment) async {
    await _isar.writeTxn(() async {
      await _isar.hifzMoments.put(moment);
    });
  }

  @override
  Future<List<HifzMoment>> getRecentMoments(int limit) async {
    return await _isar.hifzMoments
        .where()
        .sortByCreatedAtDesc()
        .limit(limit)
        .findAll();
  }

  @override
  Future<HifzSettings> getSettings() async {
    final settings = await _isar.hifzSettings.get(1);
    if (settings != null) {
      return settings;
    }

    final defaults = HifzSettings.defaults();
    await saveSettings(defaults);
    return defaults;
  }

  @override
  Future<void> saveSettings(HifzSettings settings) async {
    await _isar.writeTxn(() async {
      settings.id = 1;
      await _isar.hifzSettings.put(settings);
    });
  }

  // TODO[phase-2: CloudSync]:
  //   Add uploadToCloud(String userId) for
  //   cross-device progress sync
}
