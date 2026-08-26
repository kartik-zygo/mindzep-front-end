import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mindzep/features/shared/walkthrough/data/walkthrough_prefs.dart';
import 'package:mindzep/features/shared/walkthrough/domain/walkthrough_step.dart';
import 'package:mindzep/features/shared/walkthrough/presentation/walkthrough_coach.dart';
import 'package:mindzep/features/shared/walkthrough/presentation/widgets/walkthrough_overlay.dart';
import 'package:mindzep/injection/injection_container.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    if (sl.isRegistered<SharedPreferences>()) {
      await sl.unregister<SharedPreferences>();
    }
    sl.registerSingleton<SharedPreferences>(
      await SharedPreferences.getInstance(),
    );
  });

  group('WalkthroughPrefs', () {
    test('a tour that has never run is not marked as seen', () {
      expect(WalkthroughPrefs.hasSeen('tour_a'), isFalse);
    });

    test('markSeen and reset flip the flag', () async {
      await WalkthroughPrefs.markSeen('tour_a');
      expect(WalkthroughPrefs.hasSeen('tour_a'), isTrue);
      // Other tours are unaffected.
      expect(WalkthroughPrefs.hasSeen('tour_b'), isFalse);

      await WalkthroughPrefs.reset('tour_a');
      expect(WalkthroughPrefs.hasSeen('tour_a'), isFalse);
    });
  });

  group('WalkthroughOverlay', () {
    final steps = <WalkthroughStep>[
      const WalkthroughStep(
        title: 'First stop',
        description: 'Description one.',
        icon: Icons.spa_rounded,
      ),
      const WalkthroughStep(
        title: 'Second stop',
        description: 'Description two.',
      ),
      const WalkthroughStep(
        title: 'Last stop',
        description: 'Description three.',
      ),
    ];

    Widget harness(List<WalkthroughStep> steps) =>
        MaterialApp(home: Scaffold(body: WalkthroughOverlay(steps: steps)));

    testWidgets('shows the first step with a step counter', (tester) async {
      await tester.pumpWidget(harness(steps));
      await tester.pumpAndSettle();

      expect(find.text('First stop'), findsOneWidget);
      expect(find.text('Description one.'), findsOneWidget);
      expect(find.text('1/3'), findsOneWidget);
      // No Back button on the opening step.
      expect(find.text('Back'), findsNothing);
    });

    testWidgets('Next advances and Back returns', (tester) async {
      await tester.pumpWidget(harness(steps));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      expect(find.text('Second stop'), findsOneWidget);
      expect(find.text('2/3'), findsOneWidget);

      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();
      expect(find.text('First stop'), findsOneWidget);
      expect(find.text('1/3'), findsOneWidget);
    });

    testWidgets('the final step swaps Next for Got it and drops Skip tour', (
      tester,
    ) async {
      await tester.pumpWidget(harness(steps));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next'));
      await tester.pumpAndSettle();

      expect(find.text('Last stop'), findsOneWidget);
      expect(find.text('Got it'), findsOneWidget);
      expect(find.text('Next'), findsNothing);
      expect(find.text('Skip tour'), findsNothing);
    });

    testWidgets('tapping the backdrop advances the tour', (tester) async {
      await tester.pumpWidget(harness(steps));
      await tester.pumpAndSettle();

      // Tap near the left edge, away from the card and the Skip pill.
      await tester.tapAt(const Offset(8, 300));
      await tester.pumpAndSettle();

      expect(find.text('Second stop'), findsOneWidget);
    });
  });

  group('WalkthroughCoach', () {
    final steps = <WalkthroughStep>[
      const WalkthroughStep(title: 'Only stop', description: 'Just one.'),
    ];

    /// Builds a host page and hands back a context that can push the overlay.
    Future<BuildContext> pumpHost(WidgetTester tester) async {
      late BuildContext hostContext;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              hostContext = context;
              return const Scaffold(body: Text('Home'));
            },
          ),
        ),
      );
      return hostContext;
    }

    testWidgets('startIfFirstTime runs once, then never again', (tester) async {
      final hostContext = await pumpHost(tester);

      // Not awaited: the future only completes once the tour is dismissed,
      // and only the tester can drive it there.
      unawaited(
        WalkthroughCoach.startIfFirstTime(
          hostContext,
          tourId: 'first_run_tour',
          steps: steps,
          delay: Duration.zero,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Only stop'), findsOneWidget);

      await tester.tap(find.text('Got it'));
      await tester.pumpAndSettle();
      expect(find.text('Only stop'), findsNothing);
      expect(WalkthroughPrefs.hasSeen('first_run_tour'), isTrue);

      // Second visit: nothing happens.
      unawaited(
        WalkthroughCoach.startIfFirstTime(
          hostContext,
          tourId: 'first_run_tour',
          steps: steps,
          delay: Duration.zero,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Only stop'), findsNothing);
    });

    testWidgets('replay shows a tour that was already seen', (tester) async {
      await WalkthroughPrefs.markSeen('replayable_tour');
      final hostContext = await pumpHost(tester);

      unawaited(
        WalkthroughCoach.replay(
          hostContext,
          tourId: 'replayable_tour',
          steps: steps,
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Only stop'), findsOneWidget);
      await tester.tap(find.text('Got it'));
      await tester.pumpAndSettle();
    });

    testWidgets('a second tour cannot start while one is on screen', (
      tester,
    ) async {
      final hostContext = await pumpHost(tester);

      unawaited(
        WalkthroughCoach.start(
          hostContext,
          tourId: 'tour_one',
          steps: steps,
        ),
      );
      await tester.pumpAndSettle();
      expect(WalkthroughCoach.isRunning, isTrue);

      unawaited(
        WalkthroughCoach.start(
          hostContext,
          tourId: 'tour_two',
          steps: const [
            WalkthroughStep(title: 'Intruder', description: 'Should not show.'),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Intruder'), findsNothing);
      expect(find.text('Only stop'), findsOneWidget);

      await tester.tap(find.text('Got it'));
      await tester.pumpAndSettle();
      expect(WalkthroughCoach.isRunning, isFalse);
    });
  });
}
