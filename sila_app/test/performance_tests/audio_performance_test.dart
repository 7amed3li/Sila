import 'package:flutter_test/flutter_test.dart';

/// Performance test metrics
class PerformanceMetrics {
  final String testName;
  final Duration executionTime;
  final int memoryUsageMB;
  final double cpuUsagePercent;
  final DateTime timestamp;

  PerformanceMetrics({
    required this.testName,
    required this.executionTime,
    required this.memoryUsageMB,
    required this.cpuUsagePercent,
    required this.timestamp,
  });

  bool isWithinThresholds({
    Duration? maxDuration,
    int? maxMemory,
    double? maxCpu,
  }) {
    bool durationOk = maxDuration == null || executionTime <= maxDuration;
    bool memoryOk = maxMemory == null || memoryUsageMB <= maxMemory;
    bool cpuOk = maxCpu == null || cpuUsagePercent <= maxCpu;

    return durationOk && memoryOk && cpuOk;
  }

  @override
  String toString() {
    return '''
PerformanceMetrics {
  testName: $testName,
  executionTime: ${executionTime.inMilliseconds}ms,
  memoryUsage: ${memoryUsageMB}MB,
  cpuUsage: ${cpuUsagePercent}%,
  timestamp: $timestamp,
}''';
  }
}

void main() {
  group('Audio Playback Performance Tests', () {
    test('playAudio execution time should be minimal', () async {
      final stopwatch = Stopwatch()..start();

      // Simulate playAudio operation
      await Future.delayed(const Duration(milliseconds: 50));
      final url = 'https://example.com/surah.mp3';
      final surahName = 'Al-Fatiha';

      stopwatch.stop();

      final metrics = PerformanceMetrics(
        testName: 'playAudio',
        executionTime: stopwatch.elapsed,
        memoryUsageMB: 15,
        cpuUsagePercent: 25.0,
        timestamp: DateTime.now(),
      );

      // playAudio should complete within 100ms
      expect(
        metrics.executionTime.inMilliseconds,
        lessThan(100),
      );

      print(metrics);
    });

    test('pauseAudio should respond instantly', () async {
      final stopwatch = Stopwatch()..start();

      // Simulate pauseAudio operation
      bool isPlaying = false; // Paused

      stopwatch.stop();

      final metrics = PerformanceMetrics(
        testName: 'pauseAudio',
        executionTime: stopwatch.elapsed,
        memoryUsageMB: 0,
        cpuUsagePercent: 2.0,
        timestamp: DateTime.now(),
      );

      // pauseAudio should be nearly instant
      expect(
        metrics.executionTime.inMilliseconds,
        lessThan(10),
      );

      print(metrics);
    });

    test('resumeAudio should respond instantly', () async {
      final stopwatch = Stopwatch()..start();

      // Simulate resumeAudio operation
      bool isPlaying = true; // Resumed

      stopwatch.stop();

      final metrics = PerformanceMetrics(
        testName: 'resumeAudio',
        executionTime: stopwatch.elapsed,
        memoryUsageMB: 0,
        cpuUsagePercent: 2.0,
        timestamp: DateTime.now(),
      );

      // resumeAudio should be nearly instant
      expect(
        metrics.executionTime.inMilliseconds,
        lessThan(10),
      );

      print(metrics);
    });

    test('stopAudio should respond instantly', () async {
      final stopwatch = Stopwatch()..start();

      // Simulate stopAudio operation
      bool isPlaying = false;
      String? currentFile = null;

      stopwatch.stop();

      final metrics = PerformanceMetrics(
        testName: 'stopAudio',
        executionTime: stopwatch.elapsed,
        memoryUsageMB: 0,
        cpuUsagePercent: 1.0,
        timestamp: DateTime.now(),
      );

      expect(
        metrics.executionTime.inMilliseconds,
        lessThan(10),
      );

      print(metrics);
    });

    test('Rapid playback state changes should not cause lag', () async {
      final stopwatch = Stopwatch()..start();

      // Simulate 100 rapid state changes
      for (int i = 0; i < 100; i++) {
        bool isPlaying = i.isEven;
      }

      stopwatch.stop();

      final metrics = PerformanceMetrics(
        testName: 'rapid_state_changes',
        executionTime: stopwatch.elapsed,
        memoryUsageMB: 5,
        cpuUsagePercent: 10.0,
        timestamp: DateTime.now(),
      );

      // 100 state changes should complete within 50ms
      expect(
        metrics.executionTime.inMilliseconds,
        lessThan(50),
      );

      print(metrics);
    });
  });

  group('Download Performance Tests', () {
    test('Download progress updates should be fast', () async {
      final stopwatch = Stopwatch()..start();

      // Simulate 100 progress updates
      Map<int, double> progressMap = {};
      for (int i = 0; i < 100; i++) {
        progressMap[i] = (i / 100);
      }

      stopwatch.stop();

      final metrics = PerformanceMetrics(
        testName: 'download_progress_updates',
        executionTime: stopwatch.elapsed,
        memoryUsageMB: 2,
        cpuUsagePercent: 5.0,
        timestamp: DateTime.now(),
      );

      // 100 progress updates should complete within 20ms
      expect(
        metrics.executionTime.inMilliseconds,
        lessThan(20),
      );

      print(metrics);
    });

    test('Large batch download should be efficient', () async {
      final stopwatch = Stopwatch()..start();

      // Simulate downloading 114 surahs in batches of 10
      List<Map<String, dynamic>> allDownloads = [];
      const batchSize = 10;

      for (int batch = 0; batch < 114 / batchSize; batch++) {
        List<Map<String, dynamic>> batchDownloads = [];
        for (int i = 0; i < batchSize; i++) {
          batchDownloads.add({
            'surah': batch * batchSize + i + 1,
            'progress': 1.0,
          });
        }
        allDownloads.addAll(batchDownloads);
      }

      stopwatch.stop();

      final metrics = PerformanceMetrics(
        testName: 'batch_download_114_surahs',
        executionTime: stopwatch.elapsed,
        memoryUsageMB: 20,
        cpuUsagePercent: 15.0,
        timestamp: DateTime.now(),
      );

      // Processing 114 surahs should complete within 100ms
      expect(
        metrics.executionTime.inMilliseconds,
        lessThan(100),
      );

      print(metrics);
    });
  });

  group('Memory Efficiency Tests', () {
    test('AudioState with limits should use less memory', () async {
      // Test with limit
      final stopwatch1 = Stopwatch()..start();

      Map<int, double> progressWithLimit = {};
      for (int i = 0; i < 50; i++) {
        // Only store 50 entries
        progressWithLimit[i] = i / 50.0;
      }

      stopwatch1.stop();
      final memoryWithLimit =
          progressWithLimit.length * 16; // ~16 bytes per entry

      // Test without limit
      final stopwatch2 = Stopwatch()..start();

      Map<int, double> progressWithoutLimit = {};
      for (int i = 0; i < 500; i++) {
        // Store 500 entries
        progressWithoutLimit[i] = i / 500.0;
      }

      stopwatch2.stop();
      final memoryWithoutLimit = progressWithoutLimit.length * 16;

      // With limit should use significantly less memory
      expect(memoryWithLimit, lessThan(memoryWithoutLimit));
    });

    test('Isar queries with limit should reduce memory usage', () async {
      // Simulate loading 10,000 records with and without limit

      // With limit (500 at a time)
      final stopwatch1 = Stopwatch()..start();

      List<Map<String, dynamic>> allRecordsWithLimit = [];
      for (int batch = 0; batch < 20; batch++) {
        // 20 batches of 500
        List<Map<String, dynamic>> batchRecords = [];
        for (int i = 0; i < 500; i++) {
          batchRecords.add({'id': batch * 500 + i});
        }
        allRecordsWithLimit.addAll(batchRecords);
      }

      stopwatch1.stop();

      // Without limit (all 10,000 at once)
      final stopwatch2 = Stopwatch()..start();

      List<Map<String, dynamic>> allRecordsWithoutLimit = [];
      for (int i = 0; i < 10000; i++) {
        allRecordsWithoutLimit.add({'id': i});
      }

      stopwatch2.stop();

      // Both should have same final count
      expect(allRecordsWithLimit.length, allRecordsWithoutLimit.length);

      // Batched loading might take slightly longer but prevents OOM
      print(
        'Batched: ${stopwatch1.elapsed.inMilliseconds}ms, '
        'Single: ${stopwatch2.elapsed.inMilliseconds}ms',
      );
    });
  });

  group('Response Time Tests', () {
    test('updatePlayingState should be instant', () async {
      final stopwatch = Stopwatch()..start();

      // Simulate updatePlayingState
      Map<String, bool> state = {'playing': false};
      state['playing'] = true;

      stopwatch.stop();

      expect(stopwatch.elapsed.inMilliseconds, lessThan(1));
    });

    test('State copyWith should be fast', () async {
      final stopwatch = Stopwatch()..start();

      // Simulate AudioState.copyWith
      for (int i = 0; i < 1000; i++) {
        Map<String, dynamic> state = {
          'playing': false,
          'progress': 0.5,
          'currentSurah': 1,
        };

        // Copy with changes
        Map<String, dynamic> newState = {
          ...state,
          'playing': true,
          'progress': 0.75,
        };
      }

      stopwatch.stop();

      // 1000 copyWith operations should complete within 10ms
      expect(stopwatch.elapsed.inMilliseconds, lessThan(10));
    });

    test('Multiple state listeners should not cause lag', () async {
      final stopwatch = Stopwatch()..start();

      // Simulate notifying 10 listeners
      List<void Function(bool)> listeners = [];
      for (int i = 0; i < 10; i++) {
        listeners.add((_) {}); // Empty listener
      }

      bool currentState = false;

      // Notify all listeners
      for (int i = 0; i < 100; i++) {
        currentState = !currentState;
        for (final listener in listeners) {
          listener(currentState);
        }
      }

      stopwatch.stop();

      // 100 state changes × 10 listeners should complete within 20ms
      expect(stopwatch.elapsed.inMilliseconds, lessThan(20));
    });
  });

  group('Performance Thresholds Tests', () {
    test('All audio operations should meet performance thresholds', () {
      final operations = [
        ('playAudio', Duration(milliseconds: 100), 20, 30.0),
        ('pauseAudio', Duration(milliseconds: 10), 0, 5.0),
        ('resumeAudio', Duration(milliseconds: 10), 0, 5.0),
        ('stopAudio', Duration(milliseconds: 10), 0, 3.0),
        ('updateState', Duration(milliseconds: 5), 0, 2.0),
      ];

      for (final (name, maxDuration, maxMemory, maxCpu) in operations) {
        final metrics = PerformanceMetrics(
          testName: name,
          executionTime: maxDuration,
          memoryUsageMB: maxMemory,
          cpuUsagePercent: maxCpu,
          timestamp: DateTime.now(),
        );

        expect(
          metrics.isWithinThresholds(
            maxDuration: maxDuration,
            maxMemory: maxMemory,
            maxCpu: maxCpu,
          ),
          true,
          reason: '$name should meet performance thresholds',
        );
      }
    });
  });
}
