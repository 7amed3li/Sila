import 'dart:math';

import 'package:sila_app/features/ibadah_tracker/data/models/ibadah_record.dart';
import 'package:sila_app/features/ibadah_tracker/domain/daily_status_quotes_ar.dart';
import 'package:sila_app/features/ibadah_tracker/domain/daily_status_quotes_en.dart';
import 'package:sila_app/features/ibadah_tracker/domain/daily_status_quotes_fr.dart';
import 'package:sila_app/features/ibadah_tracker/domain/daily_status_quotes_tr.dart';

class DailyStatusCalculator {
  static final Random _random = Random();
  static final Map<String, String> _dailyTextCache = {};

  static int completedCount(IbadahRecord record, {required bool isMale}) {
    int count = 0;
    if (record.fajrStatus > 0) count++;
    if (record.dhuhrStatus > 0) count++;
    if (record.asrStatus > 0) count++;
    if (record.maghribStatus > 0) count++;
    if (record.ishaStatus > 0) count++;
    
    if (isMale) {
      if (record.fajrInMasjid == true) count++;
      if (record.dhuhrInMasjid == true) count++;
      if (record.asrInMasjid == true) count++;
      if (record.maghribInMasjid == true) count++;
      if (record.ishaInMasjid == true) count++;
    }
    
    if (record.readWird) count++;
    if (record.readAzkarSabah) count++;
    if (record.readAzkarMasa) count++;
    if (record.didTasbih) count++;
    if (record.didHifz || record.didTasmi) count++;
    if (record.rememberedAllah) count++;
    return count;
  }

  static int totalCount({required bool isMale}) {
    return isMale ? 16 : 11; // 5 prayers + 5 masjid + 6 others VS 5 prayers + 6 others
  }

  static double completionRatio(IbadahRecord record, {required bool isMale}) {
    final total = totalCount(isMale: isMale);
    if (total == 0) return 0.0;
    return completedCount(record, isMale: isMale) / total;
  }

  static String getDailyStatusText(IbadahRecord record, {required bool isMale, required String languageCode}) {
    var texts = <String>[];
    final double ratio = completionRatio(record, isMale: isMale);

    if (languageCode == 'ar') {
      if (ratio >= 0.8) {
        texts = DailyStatusQuotesAr.excellent;
      } else if (ratio >= 0.4) {
        texts = DailyStatusQuotesAr.average;
      } else {
        texts = DailyStatusQuotesAr.poor;
      }
    } else if (languageCode == 'fr') {
      if (ratio >= 0.8) {
        texts = DailyStatusQuotesFr.excellent;
      } else if (ratio >= 0.4) {
        texts = DailyStatusQuotesFr.average;
      } else {
        texts = DailyStatusQuotesFr.poor;
      }
    } else if (languageCode == 'tr') {
      if (ratio >= 0.8) {
        texts = DailyStatusQuotesTr.excellent;
      } else if (ratio >= 0.4) {
        texts = DailyStatusQuotesTr.average;
      } else {
        texts = DailyStatusQuotesTr.poor;
      }
    } else {
      if (ratio >= 0.8) {
        texts = DailyStatusQuotesEn.excellent;
      } else if (ratio >= 0.4) {
        texts = DailyStatusQuotesEn.average;
      } else {
        texts = DailyStatusQuotesEn.poor;
      }
    }

    if (texts.isEmpty) return '';

    final dayKey = record.date.year * 10000 + record.date.month * 100 + record.date.day;
    final cacheKey = '${dayKey}_${languageCode}_${completedCount(record, isMale: isMale)}';
    final cached = _dailyTextCache[cacheKey];
    if (cached != null && texts.contains(cached)) return cached;

    final baseSeed = (record.date.millisecondsSinceEpoch ~/ Duration.millisecondsPerDay) + completedCount(record, isMale: isMale);
    final idx = (baseSeed + (baseSeed % 13) + _random.nextInt(texts.length)) % texts.length;
    final selected = texts[idx];
    _dailyTextCache[cacheKey] = selected;
    return selected;
  }

  // Backward compatibility or alternative name
  static String getDailyQuote(IbadahRecord record, String languageCode) {
    return getDailyStatusText(record, isMale: true, languageCode: languageCode);
  }
}
