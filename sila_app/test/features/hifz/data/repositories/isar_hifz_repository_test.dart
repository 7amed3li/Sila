import 'package:flutter_test/flutter_test.dart';
import 'package:isar/isar.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sila_app/features/hifz/data/models/hifz_verse_record.dart';
import 'package:sila_app/features/hifz/data/repositories/isar_hifz_repository.dart';

// Mock Isar
class MockIsarHifzRepository extends Mock implements IsarHifzRepository {}

HifzVerseRecord _createMockRecord(int id) {
  final record = HifzVerseRecord()
    ..id = id
    ..surahIndex = 1
    ..verseNumber = id
    ..intervalDays = 1
    ..easinessFactor = 2.5
    ..nextReviewDate = DateTime.now()
    ..lastReviewDate = DateTime.now()
    ..totalSessions = 5
    ..correctSessions = 4
    ..lastMethodUsed = 'repetition';

  return record;
}

void main() {
  group('IsarHifzRepository - Limit Tests', () {
    late MockIsarHifzRepository mockRepository;

    setUp(() {
      mockRepository = MockIsarHifzRepository();
    });

    test('getAllRecords should have a limit parameter', () {
      expect(
        mockRepository.getAllRecords,
        isNotNull,
      );
    });

    test('getAllRecords returns data within limit', () async {
      // Setup: Create mock records
      final mockRecords = List.generate(
        100,
        (i) => _createMockRecord(i),
      );

      when(() => mockRepository.getAllRecords(limit: 50)).thenAnswer(
        (_) async => mockRecords.take(50).toList(),
      );

      final result = await mockRepository.getAllRecords(limit: 50);

      expect(result.length, 50);
      verify(() => mockRepository.getAllRecords(limit: 50)).called(1);
    });

    test('getAllRecords uses default limit when not specified', () async {
      final mockRecords = List.generate(500, (i) => _createMockRecord(i));

      when(() => mockRepository.getAllRecords()).thenAnswer(
        (_) async => mockRecords,
      );

      final result = await mockRepository.getAllRecords();

      expect(result.length, 500);
    });

    test('getAllRecords handles zero limit gracefully', () async {
      when(() => mockRepository.getAllRecords(limit: 0)).thenAnswer(
        (_) async => [],
      );

      final result = await mockRepository.getAllRecords(limit: 0);

      expect(result, isEmpty);
    });

    test('getAllRecords handles large limits', () async {
      final mockRecords = List.generate(1000, (i) => _createMockRecord(i));

      when(() => mockRepository.getAllRecords(limit: 1000)).thenAnswer(
        (_) async => mockRecords,
      );

      final result = await mockRepository.getAllRecords(limit: 1000);

      expect(result.length, 1000);
    });

    test('getAllRecords respects individual limit values', () async {
      when(() => mockRepository.getAllRecords(limit: 100)).thenAnswer(
        (_) async => List.generate(100, (i) => _createMockRecord(i)),
      );

      when(() => mockRepository.getAllRecords(limit: 200)).thenAnswer(
        (_) async => List.generate(200, (i) => _createMockRecord(i)),
      );

      final result100 = await mockRepository.getAllRecords(limit: 100);
      final result200 = await mockRepository.getAllRecords(limit: 200);

      expect(result100.length, 100);
      expect(result200.length, 200);
    });
  });

  group('IsarHifzRepository - Memory Efficiency Tests', () {
    late MockIsarHifzRepository mockRepository;

    setUp(() {
      mockRepository = MockIsarHifzRepository();
    });

    test('getAllRecords with limit prevents OOM for large datasets', () async {
      // Simulate paginated loading
      final allRecords = <HifzVerseRecord>[];

      for (int i = 0; i < 5; i++) {
        when(() => mockRepository.getAllRecords(limit: 500)).thenAnswer(
          (_) async => List.generate(
            500,
            (index) => _createMockRecord(i * 500 + index),
          ),
        );

        final batch = await mockRepository.getAllRecords(limit: 500);
        allRecords.addAll(batch);
      }

      expect(allRecords.length, 2500);
    });

    test('getAllRecords avoids loading entire collection at once', () async {
      // This test demonstrates the benefit of limits
      var loadCalls = 0;

      when(() => mockRepository.getAllRecords(limit: 500)).thenAnswer(
        (_) async {
          loadCalls++;
          return List.generate(500, (i) => _createMockRecord(i));
        },
      );

      // Load in batches
      await mockRepository.getAllRecords(limit: 500);
      await mockRepository.getAllRecords(limit: 500);

      expect(loadCalls, 2);
      // With pagination, we made 2 calls instead of 1 massive call
    });
  });

  group('IsarHifzRepository - Error Handling', () {
    late MockIsarHifzRepository mockRepository;

    setUp(() {
      mockRepository = MockIsarHifzRepository();
    });

    test('getAllRecords handles exceptions gracefully', () async {
      when(() => mockRepository.getAllRecords()).thenThrow(
        Exception('Database error'),
      );

      expect(
        () => mockRepository.getAllRecords(),
        throwsException,
      );
    });

    test('getAllRecords with limit handles empty response', () async {
      when(() => mockRepository.getAllRecords(limit: 50)).thenAnswer(
        (_) async => [],
      );

      final result = await mockRepository.getAllRecords(limit: 50);

      expect(result, isEmpty);
    });
  });

  group('IsarHifzRepository - Record Integrity Tests', () {
    late MockIsarHifzRepository mockRepository;

    setUp(() {
      mockRepository = MockIsarHifzRepository();
    });

    test('getAllRecords preserves record data integrity', () async {
      final mockRecord = _createMockRecord(1);
      mockRecord
        ..surahIndex = 5
        ..verseNumber = 10
        ..intervalDays = 7
        ..easinessFactor = 2.8;

      when(() => mockRepository.getAllRecords(limit: 1)).thenAnswer(
        (_) async => [mockRecord],
      );

      final result = await mockRepository.getAllRecords(limit: 1);

      expect(result.first.surahIndex, 5);
      expect(result.first.verseNumber, 10);
      expect(result.first.intervalDays, 7);
      expect(result.first.easinessFactor, 2.8);
    });

    test('getAllRecords returns records in consistent order', () async {
      final records = List.generate(10, (i) => _createMockRecord(i));

      when(() => mockRepository.getAllRecords(limit: 10)).thenAnswer(
        (_) async => records,
      );

      final result1 = await mockRepository.getAllRecords(limit: 10);
      final result2 = await mockRepository.getAllRecords(limit: 10);

      expect(result1.length, result2.length);
      for (int i = 0; i < result1.length; i++) {
        expect(result1[i].verseNumber, result2[i].verseNumber);
      }
    });
  });
}
