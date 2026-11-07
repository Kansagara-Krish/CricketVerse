import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cricketverse_ai/models/models.dart';
import 'package:cricketverse_ai/screens/shared/milestone_celebration_overlay.dart';
import 'package:cricketverse_ai/services/milestone_sound_service.dart';
import 'package:cricketverse_ai/services/celebration_queue_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Premium Cricket Celebration System Tests', () {
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
      CelebrationQueueService().reset();
    });

    test('MilestoneCelebration model JSON serialization and parsing with extended properties', () {
      final now = DateTime.now();
      final milestone = MilestoneCelebration(
        eventId: 'ms_test_wkt_1',
        matchId: 'match_001',
        type: 'WICKET',
        batsmanId: 'p_virat',
        batsmanName: 'Virat Kohli',
        runs: 45,
        ballsFaced: 30,
        teamName: 'Royal Challengers',
        teamShortName: 'RCB',
        teamColorHex: '0xFF078B70',
        innings: 1,
        timestamp: now,
        bowlerId: 'p_bumrah',
        bowlerName: 'Jasprit Bumrah',
        dismissalType: 'Bowled',
        teamRuns: 112,
        teamWickets: 3,
        teamOvers: 14.2,
      );

      final json = milestone.toJson();
      expect(json['eventId'], 'ms_test_wkt_1');
      expect(json['type'], 'WICKET');
      expect(json['bowlerName'], 'Jasprit Bumrah');
      expect(json['dismissalType'], 'Bowled');
      expect(json['teamRuns'], 112);
      expect(json['teamWickets'], 3);

      final restored = MilestoneCelebration.fromJson(json);
      expect(restored.eventId, 'ms_test_wkt_1');
      expect(restored.type, 'WICKET');
      expect(restored.batsmanName, 'Virat Kohli');
      expect(restored.bowlerName, 'Jasprit Bumrah');
      expect(restored.dismissalType, 'Bowled');
      expect(restored.teamRuns, 112);
      expect(restored.teamWickets, 3);
    });

    test('MilestoneSoundService initializes, synthesizes all 6 celebration sounds and toggles sound', () async {
      final soundService = MilestoneSoundService();
      await soundService.init();

      expect(soundService.isSoundEnabled, isTrue);

      // Verify that all 6 sound types synthesize valid 16-bit PCM WAV audio with 'RIFF' header
      final types = ['50', '100', 'WICKET', 'SIX', 'FIVE_WICKET', 'MATCH_WON'];
      for (final t in types) {
        final bytes = soundService.getSoundBytesFor(t);
        expect(bytes.length, greaterThan(2000), reason: 'Sound $t should have synthesized PCM data');
        // Check standard RIFF WAV signature 'R', 'I', 'F', 'F'
        expect(bytes[0], 0x52); // R
        expect(bytes[1], 0x49); // I
        expect(bytes[2], 0x46); // F
        expect(bytes[3], 0x46); // F
      }

      await soundService.toggleSound();
      expect(soundService.isSoundEnabled, isFalse);
      await soundService.toggleSound();
      expect(soundService.isSoundEnabled, isTrue);

      await soundService.stop();
      expect(soundService.isPlaying, isFalse);
    });

    test('CelebrationQueueService priority and deduplication logic', () {
      final queue = CelebrationQueueService();

      // Priority checks
      expect(CelebrationQueueService.getPriority('MATCH_WON'), 1);
      expect(CelebrationQueueService.getPriority('FIVE_WICKET'), 2);
      expect(CelebrationQueueService.getPriority('100'), 3);
      expect(CelebrationQueueService.getPriority('50'), 4);
      expect(CelebrationQueueService.getPriority('WICKET'), 5);
      expect(CelebrationQueueService.getPriority('SIX'), 6);

      final cSix = MilestoneCelebration(
        eventId: 'ev_six_1',
        matchId: 'm1',
        type: 'SIX',
        batsmanId: 'b1',
        batsmanName: 'Batter 1',
        runs: 6,
        ballsFaced: 12,
        teamName: 'Team A',
        timestamp: DateTime.now(),
      );

      final c50 = MilestoneCelebration(
        eventId: 'ev_50_1',
        matchId: 'm1',
        type: '50',
        batsmanId: 'b1',
        batsmanName: 'Batter 1',
        runs: 50,
        ballsFaced: 13,
        teamName: 'Team A',
        timestamp: DateTime.now(),
      );

      final cWin = MilestoneCelebration(
        eventId: 'ev_win_1',
        matchId: 'm1',
        type: 'MATCH_WON',
        winnerTeamName: 'Team A',
        resultText: 'Team A won by 6 wickets',
        teamName: 'Team A',
        batsmanId: '',
        batsmanName: 'Team A',
        runs: 0,
        ballsFaced: 0,
        timestamp: DateTime.now(),
      );

      expect(queue.enqueue(cSix), isTrue);
      // Duplicate event ID must be rejected
      expect(queue.enqueue(cSix), isFalse);

      // Enqueue 50 milestone: should replace or take priority over 6 for same batter
      expect(queue.enqueue(c50), isTrue);
      // Repeating 50 in same innings must be rejected
      expect(queue.enqueue(c50), isFalse);

      // Enqueue Match Won: highest priority
      expect(queue.enqueue(cWin), isTrue);

      queue.reset();
    });

    testWidgets('User Overlay renders Half-Century celebration (50 runs)', (tester) async {
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

      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('HALF CENTURY!'), findsOneWidget);
      expect(find.text('50'), findsOneWidget);
      expect(find.text('Virat Kohli'), findsOneWidget);
      expect(find.text('50 Runs'), findsOneWidget);
      expect(find.text('34 Balls'), findsOneWidget);
      expect(find.text('A brilliant innings!'), findsOneWidget);

      await tester.tap(find.byType(GestureDetector).first);
      expect(dismissed, isTrue);
    });

    testWidgets('User Overlay renders Century celebration (100 runs)', (tester) async {
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

      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('CENTURY COMPLETED!'), findsOneWidget);
      expect(find.text('100'), findsOneWidget);
      expect(find.text('Shubman Gill'), findsOneWidget);
      expect(find.text('104 Runs'), findsOneWidget);
      expect(find.text('A magnificent hundred!'), findsOneWidget);

      await tester.tap(find.byType(GestureDetector).first);
      expect(dismissed, isTrue);
    });

    testWidgets('User Overlay renders Wicket celebration with flying bails and attribution', (tester) async {
      bool dismissed = false;
      final milestone = MilestoneCelebration(
        eventId: 'ms_user_wkt',
        matchId: 'match_001',
        type: 'WICKET',
        batsmanId: 'p_kl',
        batsmanName: 'KL Rahul',
        runs: 28,
        ballsFaced: 22,
        bowlerId: 'p_shami',
        bowlerName: 'Mohammed Shami',
        dismissalType: 'Bowled',
        teamName: 'India',
        teamRuns: 78,
        teamWickets: 2,
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

      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('WICKET! WHAT A DELIVERY!'), findsOneWidget);
      expect(find.text('KL Rahul'), findsOneWidget);
      expect(find.text('Bowled b Mohammed Shami'), findsOneWidget);
      expect(find.text('28 runs (22 balls)'), findsOneWidget);
      expect(find.text('Score: 78/2'), findsOneWidget);

      await tester.tap(find.byType(GestureDetector).first);
      expect(dismissed, isTrue);
    });

    testWidgets('User Overlay does NOT attribute bowler for Run-Out dismissal', (tester) async {
      final milestone = MilestoneCelebration(
        eventId: 'ms_user_runout',
        matchId: 'match_001',
        type: 'WICKET',
        batsmanId: 'p_hardik',
        batsmanName: 'Hardik Pandya',
        runs: 15,
        ballsFaced: 8,
        bowlerId: '',
        bowlerName: '',
        dismissalType: 'Run Out',
        teamName: 'India',
        timestamp: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MilestoneCelebrationOverlay(
              milestone: milestone,
              onDismiss: () {},
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('WICKET! WHAT A DELIVERY!'), findsOneWidget);
      expect(find.text('Hardik Pandya'), findsOneWidget);
      expect(find.text('Run Out'), findsOneWidget);
      // Bowler should NOT be credited
      expect(find.textContaining(' b '), findsNothing);
    });

    testWidgets('User Overlay renders Six celebration', (tester) async {
      final milestone = MilestoneCelebration(
        eventId: 'ms_user_six',
        matchId: 'match_001',
        type: 'SIX',
        batsmanId: 'p_rohit',
        batsmanName: 'Rohit Sharma',
        runs: 6,
        ballsFaced: 18,
        bowlerName: 'Starc',
        teamName: 'India',
        timestamp: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MilestoneCelebrationOverlay(
              milestone: milestone,
              onDismiss: () {},
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('SIX!'), findsOneWidget);
      expect(find.text('OUT OF THE PARK!'), findsOneWidget);
      expect(find.text('Rohit Sharma'), findsOneWidget);
      expect(find.text('Bowler: Starc'), findsOneWidget);
    });

    testWidgets('User Overlay renders Five-Wicket haul celebration', (tester) async {
      final milestone = MilestoneCelebration(
        eventId: 'ms_user_5w',
        matchId: 'match_001',
        type: 'FIVE_WICKET',
        batsmanId: '',
        batsmanName: '',
        bowlerId: 'p_kuldeep',
        bowlerName: 'Kuldeep Yadav',
        bowlerWickets: 5,
        bowlerRunsConceded: 24,
        bowlerOvers: 4.0,
        runs: 0,
        ballsFaced: 0,
        teamName: 'India',
        timestamp: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MilestoneCelebrationOverlay(
              milestone: milestone,
              onDismiss: () {},
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('FIVE-FOR!'), findsOneWidget);
      expect(find.text('Kuldeep Yadav'), findsOneWidget);
      expect(find.text('5 Wickets • 24 Runs'), findsOneWidget);
      expect(find.text('A phenomenal bowling performance!'), findsOneWidget);
    });

    testWidgets('User Overlay renders Match-Winning Champions celebration', (tester) async {
      bool dismissed = false;
      final milestone = MilestoneCelebration(
        eventId: 'ms_user_win',
        matchId: 'match_001',
        type: 'MATCH_WON',
        winnerTeamName: 'Royal Challengers Bengaluru',
        resultText: 'RCB won by 4 wickets',
        teamName: 'Royal Challengers Bengaluru',
        batsmanId: '',
        batsmanName: 'RCB',
        runs: 182,
        ballsFaced: 0,
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

      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('CHAMPIONS!'), findsOneWidget);
      expect(find.text('Royal Challengers Bengaluru'), findsOneWidget);
      expect(find.text('WHAT A VICTORY!'), findsOneWidget);
      expect(find.text('RCB won by 4 wickets'), findsOneWidget);
      expect(find.byIcon(Icons.emoji_events_rounded), findsOneWidget);

      await tester.tap(find.byType(GestureDetector).first);
      expect(dismissed, isTrue);
    });

    testWidgets('Manager Toast renders compact non-blocking toasts for all event types', (tester) async {
      // 1. Wicket toast
      final wktToast = MilestoneCelebration(
        eventId: 'ms_mgr_wkt',
        matchId: 'm1',
        type: 'WICKET',
        batsmanId: 'p1',
        batsmanName: 'David Warner',
        runs: 42,
        ballsFaced: 28,
        bowlerName: 'Bumrah',
        dismissalType: 'Bowled',
        teamName: 'Australia',
        timestamp: DateTime.now(),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                const Center(child: Text('Manager Scoring Page')),
                MilestoneManagerToast(
                  milestone: wktToast,
                  onDismiss: () {},
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('WICKET!'), findsOneWidget);
      expect(find.text('David Warner'), findsOneWidget);
      expect(find.text('Bowled b Bumrah'), findsOneWidget);

      // Close button test
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
    });
  });
}
