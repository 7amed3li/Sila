import 'package:isar/isar.dart';

part 'hifz_session.g.dart';

@collection
class HifzSession {
  Id id = Isar.autoIncrement;

  late int surahIndex;
  late int fromVerse;
  late int toVerse;
  late String method;
  late DateTime date;
  late int correctWords;
  late int wrongWords;
  late int durationSeconds;
  int hasanat = 0;
}
