import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

void main() {
  group('Audio Playback Button - Widget Tests', () {
    testWidgets('Play button displays correctly when audio is stopped',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: IconButton(
                icon: Icon(Icons.play_arrow),
                onPressed: null,
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
      expect(find.byIcon(Icons.pause), findsNothing);
    });

    testWidgets('Play button changes to pause icon when audio is playing',
        (WidgetTester tester) async {
      bool isPlaying = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return Center(
                  child: IconButton(
                    icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                    onPressed: () {
                      setState(() {
                        isPlaying = !isPlaying;
                      });
                    },
                  ),
                );
              },
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.play_arrow), findsOneWidget);

      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pump();

      expect(find.byIcon(Icons.pause), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsNothing);
    });

    testWidgets('Play button toggles between play and pause',
        (WidgetTester tester) async {
      bool isPlaying = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return Center(
                  child: IconButton(
                    icon: Icon(isPlaying ? Icons.pause : Icons.play_arrow),
                    onPressed: () {
                      setState(() {
                        isPlaying = !isPlaying;
                      });
                    },
                  ),
                );
              },
            ),
          ),
        ),
      );

      // Initial state: play button
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);

      // Toggle to pause
      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pump();
      expect(find.byIcon(Icons.pause), findsOneWidget);

      // Toggle back to play
      await tester.tap(find.byIcon(Icons.pause));
      await tester.pump();
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);

      // Toggle to pause again
      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pump();
      expect(find.byIcon(Icons.pause), findsOneWidget);
    });

    testWidgets('Play button with loading state', (WidgetTester tester) async {
      bool isLoading = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return Center(
                  child: isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(),
                        )
                      : IconButton(
                          icon: const Icon(Icons.play_arrow),
                          onPressed: () {
                            setState(() {
                              isLoading = true;
                            });
                          },
                        ),
                );
              },
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.play_arrow), findsOneWidget);

      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('Play button displays correct icon based on state',
        (WidgetTester tester) async {
      final states = [false, true, false, true];
      int currentStateIndex = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return Center(
                  child: Column(
                    children: [
                      IconButton(
                        icon: Icon(
                          states[currentStateIndex]
                              ? Icons.pause
                              : Icons.play_arrow,
                        ),
                        onPressed: () {
                          setState(() {
                            currentStateIndex =
                                (currentStateIndex + 1) % states.length;
                          });
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );

      // Initial pump to ensure icon is rendered
      await tester.pump();

      // Start with play_arrow (false)
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);

      // Change to pause
      await tester.tap(find.byType(IconButton));
      await tester.pump();
      expect(find.byIcon(Icons.pause), findsOneWidget);

      // Change to play_arrow
      await tester.tap(find.byType(IconButton));
      await tester.pump();
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    });
  });

  group('Download Progress Widget - Widget Tests', () {
    testWidgets('Progress bar displays correctly', (WidgetTester tester) async {
      double progress = 0.5;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return Center(
                  child: Column(
                    children: [
                      LinearProgressIndicator(value: progress),
                      Text('${(progress * 100).toStringAsFixed(0)}%'),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );

      expect(find.byType(LinearProgressIndicator), findsOneWidget);
      expect(find.text('50%'), findsOneWidget);
    });

    testWidgets('Progress bar updates with new values',
        (WidgetTester tester) async {
      double progress = 0.0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return Center(
                  child: Column(
                    children: [
                      LinearProgressIndicator(value: progress),
                      Text('${(progress * 100).toStringAsFixed(0)}%'),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            progress += 0.25;
                          });
                        },
                        child: const Text('Increase'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('0%'), findsOneWidget);

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      expect(find.text('25%'), findsOneWidget);

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      expect(find.text('50%'), findsOneWidget);

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      expect(find.text('75%'), findsOneWidget);

      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();
      expect(find.text('100%'), findsOneWidget);
    });

    testWidgets('Progress bar handles edge cases', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                LinearProgressIndicator(value: 0.0),
                LinearProgressIndicator(value: 1.0),
                LinearProgressIndicator(value: 0.5),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(LinearProgressIndicator), findsWidgets);
    });
  });
}
