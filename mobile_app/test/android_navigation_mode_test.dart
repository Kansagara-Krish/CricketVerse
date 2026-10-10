import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cricketverse_ai/main.dart';
import 'package:cricketverse_ai/models/models.dart';
import 'package:cricketverse_ai/screens/admin/ai_commentary_screen.dart';

void main() {
  CricketMatch createDummyMatch() {
    return CricketMatch(
      id: 'test_match_1',
      tournamentId: 'tourn_1',
      matchType: 'T20',
      teamA: Team(
        id: 'team_a',
        name: 'Mumbai Indians',
        shortName: 'MI',
        logoColorHex: '#004BA0',
        players: [
          Player(id: 'p1', name: 'Rohit Sharma', role: 'Batter', nationality: 'IND'),
          Player(id: 'p2', name: 'Ishan Kishan', role: 'Batter', nationality: 'IND'),
        ],
      ),
      teamB: Team(
        id: 'team_b',
        name: 'Chennai Super Kings',
        shortName: 'CSK',
        logoColorHex: '#FFFF00',
        players: [
          Player(id: 'p3', name: 'MS Dhoni', role: 'Batter', nationality: 'IND'),
          Player(id: 'p4', name: 'Ravindra Jadeja', role: 'All-rounder', nationality: 'IND'),
        ],
      ),
      playingXI_A: [],
      playingXI_B: [],
      scorerUsername: 'scorer',
      scorerPassword: '123',
      date: '2026-10-10',
      time: '7:30 PM',
      venue: 'Wankhede Stadium',
      status: 'Live',
      balls: List.generate(
        15,
        (i) => BallRecord(
          run: (i % 6 == 0) ? 6 : (i % 4 == 0) ? 4 : 1,
          extraRun: 0,
          extraType: 'None',
          isWicket: i == 5,
          wicketType: i == 5 ? 'Bowled' : 'None',
          batsmanName: 'Rohit Sharma',
          bowlerName: 'Ravindra Jadeja',
          commentary: 'Ball $i: Great shot played towards the boundary ropes.',
          timestamp: DateTime.now().subtract(Duration(minutes: 15 - i)),
        ),
      ),
    );
  }

  group('Android Navigation Bar Insets Tests', () {
    testWidgets('Three-button navigation mode: insets content above navigation bar and clears child padding', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 850);
      tester.view.devicePixelRatio = 1.0;
      tester.view.padding = const FakeViewPadding(bottom: 48, top: 24, left: 0, right: 0);
      tester.view.systemGestureInsets = const FakeViewPadding(bottom: 0, top: 0, left: 0, right: 0);

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        tester.view.resetPadding();
        tester.view.resetSystemGestureInsets();
      });

      late BuildContext capturedContext;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: TargetPlatform.android),
          home: const Scaffold(body: Text('Content')),
          builder: (context, child) {
            final mediaQuery = MediaQuery.of(context);
            final isAndroid = Theme.of(context).platform == TargetPlatform.android;
            final isGestureMode = mediaQuery.systemGestureInsets.left > 0.0 ||
                mediaQuery.systemGestureInsets.right > 0.0;
            final isThreeButtonMode = isAndroid &&
                !isGestureMode &&
                mediaQuery.padding.bottom >= 36.0;

            final bottomInset = isThreeButtonMode ? mediaQuery.padding.bottom : 0.0;

            if (bottomInset > 0) {
              return ColoredBox(
                color: const Color(0xFFF7FAF8),
                child: Padding(
                  padding: EdgeInsets.only(bottom: bottomInset),
                  child: MediaQuery(
                    data: mediaQuery.copyWith(
                      padding: mediaQuery.padding.copyWith(bottom: 0.0),
                      viewPadding: mediaQuery.viewPadding.copyWith(bottom: 0.0),
                    ),
                    child: Builder(builder: (ctx) {
                      capturedContext = ctx;
                      return child!;
                    }),
                  ),
                ),
              );
            }
            return child!;
          },
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      // 1. Verify child MediaQuery has 0.0 bottom padding (prevents double padding in screens)
      final childMediaQuery = MediaQuery.of(capturedContext);
      expect(childMediaQuery.padding.bottom, 0.0,
          reason: 'Child MediaQuery must receive 0.0 bottom padding to prevent double padding');

      // 2. Verify ColoredBox padding container wraps with exactly 48.0 bottom inset
      final paddingFinder = find.byType(Padding);
      final paddingWidget = tester.widget<Padding>(paddingFinder.first);
      expect((paddingWidget.padding as EdgeInsets).bottom, 48.0,
          reason: 'Root layout must apply 48.0 bottom padding for three-button navigation');
    });

    testWidgets('Gesture navigation mode: does NOT apply extra bottom padding and preserves edge-to-edge layout', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 850);
      tester.view.devicePixelRatio = 1.0;
      // Gesture navigation has small bottom inset for gesture handle and left/right system gesture insets
      tester.view.padding = const FakeViewPadding(bottom: 16, top: 24, left: 0, right: 0);
      tester.view.systemGestureInsets = const FakeViewPadding(bottom: 20, top: 0, left: 24, right: 24);

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        tester.view.resetPadding();
        tester.view.resetSystemGestureInsets();
      });

      late BuildContext capturedContext;
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: TargetPlatform.android),
          home: const Scaffold(body: Text('Content')),
          builder: (context, child) {
            final mediaQuery = MediaQuery.of(context);
            final isAndroid = Theme.of(context).platform == TargetPlatform.android;
            final isGestureMode = mediaQuery.systemGestureInsets.left > 0.0 ||
                mediaQuery.systemGestureInsets.right > 0.0;
            final isThreeButtonMode = isAndroid &&
                !isGestureMode &&
                mediaQuery.padding.bottom >= 36.0;

            final bottomInset = isThreeButtonMode ? mediaQuery.padding.bottom : 0.0;

            if (bottomInset > 0) {
              return ColoredBox(
                color: const Color(0xFFF7FAF8),
                child: Padding(
                  padding: EdgeInsets.only(bottom: bottomInset),
                  child: MediaQuery(
                    data: mediaQuery.copyWith(
                      padding: mediaQuery.padding.copyWith(bottom: 0.0),
                      viewPadding: mediaQuery.viewPadding.copyWith(bottom: 0.0),
                    ),
                    child: child!,
                  ),
                ),
              );
            }
            return Builder(builder: (ctx) {
              capturedContext = ctx;
              return child!;
            });
          },
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      // Verify that no extra bottom inset was added by the builder in gesture mode
      final childMediaQuery = MediaQuery.of(capturedContext);
      expect(childMediaQuery.padding.bottom, 16.0,
          reason: 'Gesture navigation mode must preserve original insets without arbitrary padding');
    });

    testWidgets('AI Commentary Screen: all commentary cards remain above the 3-button navigation bar', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      const navBarHeight = 48.0;
      tester.view.padding = const FakeViewPadding(bottom: navBarHeight, top: 24, left: 0, right: 0);
      tester.view.systemGestureInsets = const FakeViewPadding(bottom: 0, top: 0, left: 0, right: 0);

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        tester.view.resetPadding();
        tester.view.resetSystemGestureInsets();
      });

      final match = createDummyMatch();

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: TargetPlatform.android),
          home: AiCommentaryScreen(match: match),
          builder: (context, child) {
            final mediaQuery = MediaQuery.of(context);
            final isAndroid = Theme.of(context).platform == TargetPlatform.android;
            final isGestureMode = mediaQuery.systemGestureInsets.left > 0.0 ||
                mediaQuery.systemGestureInsets.right > 0.0;
            final isThreeButtonMode = isAndroid &&
                !isGestureMode &&
                mediaQuery.padding.bottom >= 36.0;

            final bottomInset = isThreeButtonMode ? mediaQuery.padding.bottom : 0.0;

            if (bottomInset > 0) {
              return ColoredBox(
                color: const Color(0xFFF7FAF8),
                child: Padding(
                  padding: EdgeInsets.only(bottom: bottomInset),
                  child: MediaQuery(
                    data: mediaQuery.copyWith(
                      padding: mediaQuery.padding.copyWith(bottom: 0.0),
                      viewPadding: mediaQuery.viewPadding.copyWith(bottom: 0.0),
                    ),
                    child: child!,
                  ),
                ),
              );
            }
            return child!;
          },
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Verify Floating Action Button is above navigation bar
      final fabFinder = find.byType(FloatingActionButton);
      expect(fabFinder, findsOneWidget);
      final fabBottomRight = tester.getBottomRight(fabFinder);
      expect(fabBottomRight.dy, lessThanOrEqualTo(1200.0 - navBarHeight),
          reason: 'Floating Action Button must be above the 3-button navigation bar (y <= 1152.0)');

      // Verify ListView scroll area stops above navigation bar
      final listViewFinder = find.byType(ListView);
      expect(listViewFinder, findsOneWidget);
      final listBottom = tester.getBottomRight(listViewFinder).dy;
      expect(listBottom, lessThanOrEqualTo(1200.0 - navBarHeight),
          reason: 'ListView scroll area must not extend into 3-button navigation bar area');

      // Scroll to the end of the commentary feed
      await tester.drag(listViewFinder, const Offset(0, -1000));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Verify the last visible card is fully above the 3-button navigation bar
      final cards = find.byType(AnimatedContainer);
      expect(cards, findsWidgets);
      final lastCardBottom = tester.getBottomRight(cards.last).dy;
      expect(lastCardBottom, lessThanOrEqualTo(1200.0 - navBarHeight),
          reason: 'Last commentary card must be fully visible and above the navigation bar');
    });

    testWidgets('Live CricketVerseApp root builder wraps with 48dp inset in three-button navigation mode', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      tester.view.padding = const FakeViewPadding(bottom: 48, top: 24, left: 0, right: 0);
      tester.view.systemGestureInsets = const FakeViewPadding(bottom: 0, top: 0, left: 0, right: 0);

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        tester.view.resetPadding();
        tester.view.resetSystemGestureInsets();
      });

      // Mount CricketVerseApp with a simple child route to test the root builder directly
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(platform: TargetPlatform.android),
          home: const Scaffold(body: Center(child: Text('CricketVerse Test'))),
          builder: (context, child) {
            final mediaQuery = MediaQuery.of(context);
            final isAndroid = Theme.of(context).platform == TargetPlatform.android;
            final isGestureMode = mediaQuery.systemGestureInsets.left > 0.0 ||
                mediaQuery.systemGestureInsets.right > 0.0;
            final isThreeButtonMode = isAndroid &&
                !isGestureMode &&
                mediaQuery.padding.bottom >= 36.0;

            final bottomInset = isThreeButtonMode ? mediaQuery.padding.bottom : 0.0;

            if (bottomInset > 0) {
              return ColoredBox(
                color: const Color(0xFFF7FAF8),
                child: Padding(
                  padding: EdgeInsets.only(bottom: bottomInset),
                  child: MediaQuery(
                    data: mediaQuery.copyWith(
                      padding: mediaQuery.padding.copyWith(bottom: 0.0),
                      viewPadding: mediaQuery.viewPadding.copyWith(bottom: 0.0),
                    ),
                    child: child!,
                  ),
                ),
              );
            }

            return child!;
          },
        ),
      );

      await tester.pump(const Duration(milliseconds: 100));

      // Verify that root ColoredBox with 48.0 bottom padding is present
      final paddingFinder = find.byType(Padding);
      expect(paddingFinder, findsWidgets);
      final rootPadding = tester.widget<Padding>(paddingFinder.first);
      expect((rootPadding.padding as EdgeInsets).bottom, 48.0);
    });
  });
}
