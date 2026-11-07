import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cricketverse_ai/models/models.dart';
import 'package:cricketverse_ai/screens/shared/milestone_celebration_overlay.dart';
import 'package:cricketverse_ai/services/milestone_sound_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Milestone Celebration System Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({'cricketverse_celebration_sound': true});
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('xyz.luan/audioplayers.global'),
        (MethodCall methodCall) async => 1,
      );
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('xyz.luan/audioplayers'),
        (MethodCall methodCall) async => 1,
      );
    });

    test('MilestoneCelebration model JSON serialization and parsing', () {
      final now = DateTime.now();
      final milestone = MilestoneCelebration(
        eventId: 'ms_test_123',
        matchId: 'match_001',
        type: '50',
        batsmanId: 'p_virat',
        batsmanName: 'Virat Kohli',
        runs: 50,
        ballsFaced: 32,
        teamName: 'India',
        teamShortName: 'IND',
        teamColorHex: '0xFF078B70',
        innings: 1,
        timestamp: now,
      );

      final json = milestone.toJson();
      expect(json['eventId'], 'ms_test_123');
      expect(json['type'], '50');
      expect(json['runs'], 50);
      expect(json['batsmanName'], 'Virat Kohli');

      final restored = MilestoneCelebration.fromJson(json);
      expect(restored.eventId, 'ms_test_123');
      expect(restored.type, '50');
      expect(restored.runs, 50);
      expect(restored.batsmanName, 'Virat Kohli');
      expect(restored.innings, 1);
    });

    test('MilestoneSoundService initializes and toggles sound correctly', () async {
      final soundService = MilestoneSoundService();
      await soundService.init();

      final initial = soundService.isSoundEnabled;
      await soundService.toggleSound();
      expect(soundService.isSoundEnabled, !initial);

      await soundService.toggleSound();
      expect(soundService.isSoundEnabled, initial);
    });

    testWidgets('MilestoneManagerToast renders compact non-blocking banner with correct info', (tester) async {
      bool dismissed = false;
      final milestone = MilestoneCelebration(
        eventId: 'ms_mgr_50',
        matchId: 'match_001',
        type: '50',
        batsmanId: 'p_rohit',
        batsmanName: 'Rohit Sharma',
        runs: 52,
        ballsFaced: 30,
        teamName: 'Mumbai Indians',
        teamShortName: 'MI',
        timestamp: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                const Center(child: Text('Scoring Console')),
                MilestoneManagerToast(
                  milestone: milestone,
                  onDismiss: () => dismissed = true,
                ),
              ],
            ),
          ),
        ),
      );

      // Advance animation halfway into the on-screen hold phase (15% of 3500ms = 525ms)
      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('HALF CENTURY!'), findsOneWidget);
      expect(find.text('Rohit Sharma'), findsOneWidget);
      expect(find.text('52 Runs • 30 Balls'), findsOneWidget);
      expect(find.byIcon(Icons.emoji_events_rounded), findsOneWidget);

      // Verify close button triggers dismissal
      await tester.tap(find.byIcon(Icons.close_rounded), warnIfMissed: false);
      expect(dismissed, isTrue);
    });

    testWidgets('User MilestoneCelebrationOverlay renders 50 runs Half Century card', (tester) async {
      bool dismissed = false;
      final milestone = MilestoneCelebration(
        eventId: 'ms_user_50',
        matchId: 'match_001',
        type: '50',
        batsmanId: 'p_virat',
        batsmanName: 'Virat Kohli',
        runs: 50,
        ballsFaced: 34,
        teamName: 'Royal Challengers',
        teamShortName: 'RCB',
        timestamp: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MilestoneCelebrationOverlay(
              milestone: milestone,
              onDismiss: () => dismissed = true,
            ),
          ),
        ),
      );

      // Pump initial frame of entrance animation
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('HALF CENTURY!'), findsOneWidget);
      expect(find.text('50'), findsOneWidget);
      expect(find.text('Virat Kohli'), findsOneWidget);
      expect(find.text('50 Runs'), findsOneWidget);
      expect(find.text('34 Balls'), findsOneWidget);
      expect(find.text('Royal Challengers'), findsOneWidget);

      // Tap to dismiss early
      await tester.tap(find.byType(GestureDetector).first);
      expect(dismissed, isTrue);
    });

    testWidgets('User MilestoneCelebrationOverlay renders 100 runs Century Completed card with trophy', (tester) async {
      bool dismissed = false;
      final milestone = MilestoneCelebration(
        eventId: 'ms_user_100',
        matchId: 'match_001',
        type: '100',
        batsmanId: 'p_shubman',
        batsmanName: 'Shubman Gill',
        runs: 104,
        ballsFaced: 58,
        teamName: 'Gujarat Titans',
        teamShortName: 'GT',
        timestamp: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MilestoneCelebrationOverlay(
              milestone: milestone,
              onDismiss: () => dismissed = true,
            ),
          ),
        ),
      );

      // Pump initial frame
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('CENTURY COMPLETED!'), findsOneWidget);
      expect(find.text('100'), findsOneWidget);
      expect(find.text('Shubman Gill'), findsOneWidget);
      expect(find.text('104 Runs'), findsOneWidget);
      expect(find.text('58 Balls'), findsOneWidget);
      expect(find.text('Gujarat Titans'), findsOneWidget);
      expect(find.byIcon(Icons.emoji_events_rounded), findsOneWidget);

      // Tap to dismiss early
      await tester.tap(find.byType(GestureDetector).first);
      expect(dismissed, isTrue);
    });

    testWidgets('Manager Toast renders exact Aarav Verma 50 runs and 10 balls milestone', (tester) async {
      final milestone = MilestoneCelebration(
        eventId: 'ms_mgr_aarav_50',
        matchId: 'match_001',
        type: '50',
        batsmanId: 'p_aarav',
        batsmanName: 'Aarav Verma',
        runs: 50,
        ballsFaced: 10,
        teamName: 'Team Alpha',
        teamShortName: 'ALP',
        timestamp: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                const Center(child: Text('Scoring Board')),
                MilestoneManagerToast(
                  milestone: milestone,
                  topOffset: 10.0,
                  onDismiss: () {},
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('HALF CENTURY!'), findsOneWidget);
      expect(find.text('Aarav Verma'), findsOneWidget);
      expect(find.text('50 Runs • 10 Balls'), findsOneWidget);
      expect(find.byIcon(Icons.emoji_events_rounded), findsOneWidget);
    });

    testWidgets('Manager Toast renders exact Aarav Verma 100 runs and 60 balls milestone', (tester) async {
      final milestone = MilestoneCelebration(
        eventId: 'ms_mgr_aarav_100',
        matchId: 'match_001',
        type: '100',
        batsmanId: 'p_aarav',
        batsmanName: 'Aarav Verma',
        runs: 100,
        ballsFaced: 60,
        teamName: 'Team Alpha',
        teamShortName: 'ALP',
        timestamp: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                const Center(child: Text('Scoring Board')),
                MilestoneManagerToast(
                  milestone: milestone,
                  topOffset: 10.0,
                  onDismiss: () {},
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 600));

      expect(find.text('CENTURY COMPLETED!'), findsOneWidget);
      expect(find.text('Aarav Verma'), findsOneWidget);
      expect(find.text('100 Runs • 60 Balls'), findsOneWidget);
      expect(find.byIcon(Icons.emoji_events_rounded), findsOneWidget);
    });
  });
}
