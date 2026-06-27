import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sila_app/core/models/reciter_settings.dart';
import 'package:sila_app/features/hifz/data/models/hifz_moment.dart';
import 'package:sila_app/features/hifz/data/models/hifz_session.dart';
import 'package:sila_app/features/hifz/data/models/hifz_settings.dart';
import 'package:sila_app/features/hifz/data/models/hifz_user_profile.dart';
import 'package:sila_app/features/hifz/data/models/hifz_verse_record.dart';
import 'package:sila_app/features/ibadah_tracker/data/models/ibadah_record.dart';
import 'package:sila_app/features/ibadah_tracker/data/models/mujahadah_record.dart';
import 'package:sila_app/features/ibadah_tracker/data/models/user_gender_prefs.dart';
import 'package:sila_app/features/notifications/data/models/notification_content.dart';
import 'package:sila_app/features/notifications/data/models/notification_settings.dart';
import 'package:sila_app/features/notifications/data/models/user_activity_log.dart';
import 'package:sila_app/features/tasmi/data/models/tasmi_word_error.dart';
import 'package:sila_app/features/vefa/data/models/vefa_person_model.dart';
import 'package:sila_app/features/wird/data/models/wird_history.dart';
import 'package:sila_app/features/wird/data/models/wird_settings.dart';

class IsarService {
  factory IsarService() => _instance ??= IsarService._internal();
  IsarService._internal();
  static IsarService? _instance;

  static Future<Isar>? _dbFuture;

  Future<Isar> get db {
    _dbFuture ??= _openWithRetry().catchError((Object e, StackTrace st) {
      _dbFuture = null;
      Error.throwWithStackTrace(e, st);
    });
    return _dbFuture!;
  }

  Future<Isar> _openWithRetry() async {
    for (var attempt = 0; attempt < 20; attempt++) {
      try {
        final existing = Isar.getInstance();
        if (existing != null) return existing;

        final dir = await getApplicationDocumentsDirectory();
        return await Isar.open(
          [
            VefaPersonModelSchema,
            WirdSettingsSchema,
            WirdHistorySchema,
            TasmiWordErrorSchema,
            HifzUserProfileSchema,
            HifzVerseRecordSchema,
            HifzSessionSchema,
            HifzMomentSchema,
            HifzSettingsSchema,
            IbadahRecordSchema,
            MujahadahRecordSchema,
            UserGenderPrefsSchema,
            NotificationContentSchema,
            NotificationSettingsSchema,
            UserActivityLogSchema,
            ReciterSettingsSchema,
          ],
          directory: dir.path,
          inspector: kDebugMode,
        );
      } catch (e) {
        final msg = e.toString();
        if (msg.contains('MdbxError (11)')) {
          await Future<void>.delayed(
              Duration(milliseconds: 150 * (attempt + 1)));
          continue;
        }
        rethrow;
      }
    }

    throw StateError('Isar initialization retry limit reached');
  }

  Future<void> closeDB() async {
    if (_dbFuture != null) {
      try {
        await _dbFuture;
      } catch (e, st) {
        Zone.current.handleUncaughtError(e, st);
      }
    }

    final db = Isar.getInstance();
    if (db != null) {
      await db.close();
    }
    _dbFuture = null;
  }
}
