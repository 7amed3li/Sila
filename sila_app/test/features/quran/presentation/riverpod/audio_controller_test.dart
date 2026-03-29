import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sila_app/features/quran/presentation/riverpod/audio_controller.dart';

// Mock classes
class MockAudioPlayer extends Mock implements AudioPlayer {}

void main() {
  // ✅ تهيئة Flutter Binding قبل الاختبارات
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AudioController - Unit Tests', () {
    late ProviderContainer container;
    late MockAudioPlayer mockAudioPlayer;

    setUp(() {
      container = ProviderContainer();
      mockAudioPlayer = MockAudioPlayer();

      // Setup default mocks
      when(() => mockAudioPlayer.playing).thenReturn(false);
      when(() => mockAudioPlayer.dispose()).thenAnswer((_) async {});
    });

    tearDown(() {
      container.dispose();
      addTearDown(container.dispose);
    });

    test('AudioState copyWith preserves values correctly', () {
      final mockPlayer = MockAudioPlayer();
      final initialState = AudioState(
        player: mockPlayer,
        playing: false,
        currentPlayingSurah: 1,
      );

      final updatedState = initialState.copyWith(
        playing: true,
        currentPlayingSurah: 2,
      );

      expect(updatedState.playing, true);
      expect(updatedState.currentPlayingSurah, 2);
      expect(updatedState.player, equals(mockPlayer));
    });

    test('AudioState maintains download progress', () {
      final mockPlayer = MockAudioPlayer();
      final downloadProgress = {1: 0.5, 2: 1.0};

      final state = AudioState(
        player: mockPlayer,
        downloadProgress: downloadProgress,
      );

      expect(state.downloadProgress[1], 0.5);
      expect(state.downloadProgress[2], 1.0);
    });

    test('AudioState tracks playing state changes', () {
      final mockPlayer = MockAudioPlayer();
      final state1 = AudioState(player: mockPlayer, playing: false);
      final state2 = state1.copyWith(playing: true);
      final state3 = state2.copyWith(playing: false);

      expect(state1.playing, false);
      expect(state2.playing, true);
      expect(state3.playing, false);
    });

    test('AudioState handles concurrent download progress updates', () {
      final mockPlayer = MockAudioPlayer();
      var progress = <int, double>{1: 0.0, 2: 0.0, 3: 0.0};

      final state = AudioState(player: mockPlayer, downloadProgress: progress);

      // Simulate concurrent updates
      progress[1] = 0.25;
      progress[2] = 0.50;
      progress[3] = 0.75;

      final updatedState = state.copyWith(downloadProgress: progress);

      expect(updatedState.downloadProgress[1], 0.25);
      expect(updatedState.downloadProgress[2], 0.50);
      expect(updatedState.downloadProgress[3], 0.75);
    });

    test('AudioState initializes with default values', () {
      final mockPlayer = MockAudioPlayer();
      final state = AudioState(player: mockPlayer);

      expect(state.downloadProgress, isEmpty);
      expect(state.isDownloadingAll, false);
      expect(state.currentPlayingSurah, isNull);
      expect(state.playing, false);
    });

    test('AudioState handles null currentPlayingSurah', () {
      final mockPlayer = MockAudioPlayer();
      final state1 = AudioState(player: mockPlayer, currentPlayingSurah: 1);
      final state2 = state1.copyWith(currentPlayingSurah: 2);
      final state3 = state2.copyWith();

      expect(state1.currentPlayingSurah, 1);
      expect(state2.currentPlayingSurah, 2);
      expect(state3.currentPlayingSurah, 2); // Keeps previous value
    });

    test('AudioState download progress is properly updated', () {
      final mockPlayer = MockAudioPlayer();
      final progress1 = {1: 0.5};
      final state1 =
          AudioState(player: mockPlayer, downloadProgress: progress1);

      final progress2 = {1: 1.0};
      final state2 = state1.copyWith(downloadProgress: progress2);

      expect(state2.downloadProgress[1], 1.0);
    });

    test('AudioState isDownloadingAll tracks batch download state', () {
      final mockPlayer = MockAudioPlayer();
      final state1 = AudioState(player: mockPlayer, isDownloadingAll: false);
      final state2 = state1.copyWith(isDownloadingAll: true);
      final state3 = state2.copyWith(isDownloadingAll: false);

      expect(state1.isDownloadingAll, false);
      expect(state2.isDownloadingAll, true);
      expect(state3.isDownloadingAll, false);
    });
  });
}
