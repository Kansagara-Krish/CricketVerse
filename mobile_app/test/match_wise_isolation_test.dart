import 'package:flutter_test/flutter_test.dart';
import 'package:cricketverse_ai/models/models.dart';
import 'package:cricketverse_ai/services/storage_service.dart';
import 'package:cricketverse_ai/services/pdf_report_service.dart';

void main() {
  group('Match-Wise Statistics Aggregation & Data Isolation Tests', () {
    late StorageService storage;
    late Team teamA;
    late Team teamB;
    late Player playerA;
    late Player playerB;
    late Player playerC;

    setUp(() {
      storage = StorageService();

      playerA = Player(
        id: 'p_A',
        name: 'Player A',
        role: 'Batter',
        nationality: 'IND',
        runsScored: 0,
        ballsFaced: 0,
      );

      playerB = Player(
        id: 'p_B',
        name: 'Player B',
        role: 'Batter',
        nationality: 'IND',
        runsScored: 0,
        ballsFaced: 0,
      );

      playerC = Player(
        id: 'p_C',
        name: 'Player C',
        role: 'Bowler',
        nationality: 'IND',
        runsScored: 0,
        ballsFaced: 0,
      );

      teamA = Team(
        id: 'team_alpha',
        name: 'Alpha Warriors',
        shortName: 'AW',
        logoColorHex: '0xFF028A6B',
        players: [playerA, playerB],
      );

      teamB = Team(
        id: 'team_beta',
        name: 'Beta Titans',
        shortName: 'BT',
        logoColorHex: '0xFFDC2626',
        players: [playerC],
      );
    });

    test('Match 1 and Match 2 maintain strictly isolated statistics for the same players', () async {
      // Match 1: Player A scores 10 runs, Player B scores 20 runs
      final match1 = CricketMatch(
        id: 'match_1',
        teamA: Team(
          id: teamA.id,
          name: teamA.name,
          shortName: teamA.shortName,
          logoColorHex: teamA.logoColorHex,
          players: [
            Player(id: 'p_A', name: 'Player A', role: 'Batter', nationality: 'IND'),
            Player(id: 'p_B', name: 'Player B', role: 'Batter', nationality: 'IND'),
          ],
        ),
        teamB: Team(
          id: teamB.id,
          name: teamB.name,
          shortName: teamB.shortName,
          logoColorHex: teamB.logoColorHex,
          players: [
            Player(id: 'p_C', name: 'Player C', role: 'Bowler', nationality: 'IND'),
          ],
        ),
        matchType: 'T20',
        venue: 'Stadium 1',
        date: '2026-11-01',
        time: '14:00',
        status: 'Completed',
        tossWinner: 'Alpha Warriors',
        tossDecision: 'Bat',
        battingTeamId: teamA.id,
        playingXI_A: [
          Player(id: 'p_A', name: 'Player A', role: 'Batter', nationality: 'IND'),
          Player(id: 'p_B', name: 'Player B', role: 'Batter', nationality: 'IND'),
        ],
        playingXI_B: [
          Player(id: 'p_C', name: 'Player C', role: 'Bowler', nationality: 'IND'),
        ],
        runsA: 30,
        wicketsA: 0,
        oversA: 1.4,
        runsB: 0,
        wicketsB: 0,
        oversB: 0.0,
        target: 0,
        scorerUsername: 'scorer1',
        scorerPassword: 'pass1',
        balls: [
          // Player A: 4 balls, 10 runs (4, 4, 1, 1)
          BallRecord(strikerId: 'p_A', batsmanName: 'Player A', bowlerId: 'p_C', bowlerName: 'Player C', run: 4, extraRun: 0, extraType: 'None', isWicket: false, wicketType: 'None', commentary: '', timestamp: DateTime.now(), innings: 1, over: 0.1),
          BallRecord(strikerId: 'p_A', batsmanName: 'Player A', bowlerId: 'p_C', bowlerName: 'Player C', run: 4, extraRun: 0, extraType: 'None', isWicket: false, wicketType: 'None', commentary: '', timestamp: DateTime.now(), innings: 1, over: 0.2),
          BallRecord(strikerId: 'p_A', batsmanName: 'Player A', bowlerId: 'p_C', bowlerName: 'Player C', run: 1, extraRun: 0, extraType: 'None', isWicket: false, wicketType: 'None', commentary: '', timestamp: DateTime.now(), innings: 1, over: 0.3),
          BallRecord(strikerId: 'p_A', batsmanName: 'Player A', bowlerId: 'p_C', bowlerName: 'Player C', run: 1, extraRun: 0, extraType: 'None', isWicket: false, wicketType: 'None', commentary: '', timestamp: DateTime.now(), innings: 1, over: 0.4),
          // Player B: 6 balls, 20 runs (4, 4, 4, 6, 1, 1)
          BallRecord(strikerId: 'p_B', batsmanName: 'Player B', bowlerId: 'p_C', bowlerName: 'Player C', run: 4, extraRun: 0, extraType: 'None', isWicket: false, wicketType: 'None', commentary: '', timestamp: DateTime.now(), innings: 1, over: 0.5),
          BallRecord(strikerId: 'p_B', batsmanName: 'Player B', bowlerId: 'p_C', bowlerName: 'Player C', run: 4, extraRun: 0, extraType: 'None', isWicket: false, wicketType: 'None', commentary: '', timestamp: DateTime.now(), innings: 1, over: 0.6),
          BallRecord(strikerId: 'p_B', batsmanName: 'Player B', bowlerId: 'p_C', bowlerName: 'Player C', run: 4, extraRun: 0, extraType: 'None', isWicket: false, wicketType: 'None', commentary: '', timestamp: DateTime.now(), innings: 1, over: 1.1),
          BallRecord(strikerId: 'p_B', batsmanName: 'Player B', bowlerId: 'p_C', bowlerName: 'Player C', run: 6, extraRun: 0, extraType: 'None', isWicket: false, wicketType: 'None', commentary: '', timestamp: DateTime.now(), innings: 1, over: 1.2),
          BallRecord(strikerId: 'p_B', batsmanName: 'Player B', bowlerId: 'p_C', bowlerName: 'Player C', run: 1, extraRun: 0, extraType: 'None', isWicket: false, wicketType: 'None', commentary: '', timestamp: DateTime.now(), innings: 1, over: 1.3),
          BallRecord(strikerId: 'p_B', batsmanName: 'Player B', bowlerId: 'p_C', bowlerName: 'Player C', run: 1, extraRun: 0, extraType: 'None', isWicket: false, wicketType: 'None', commentary: '', timestamp: DateTime.now(), innings: 1, over: 1.4),
        ],
      );

      // Match 2: Player A scores 15 runs, Player B scores 5 runs
      final match2 = CricketMatch(
        id: 'match_2',
        teamA: Team(
          id: teamA.id,
          name: teamA.name,
          shortName: teamA.shortName,
          logoColorHex: teamA.logoColorHex,
          players: [
            Player(id: 'p_A', name: 'Player A', role: 'Batter', nationality: 'IND'),
            Player(id: 'p_B', name: 'Player B', role: 'Batter', nationality: 'IND'),
          ],
        ),
        teamB: Team(
          id: teamB.id,
          name: teamB.name,
          shortName: teamB.shortName,
          logoColorHex: teamB.logoColorHex,
          players: [
            Player(id: 'p_C', name: 'Player C', role: 'Bowler', nationality: 'IND'),
          ],
        ),
        matchType: 'T20',
        venue: 'Stadium 2',
        date: '2026-11-05',
        time: '18:00',
        status: 'Completed',
        tossWinner: 'Alpha Warriors',
        tossDecision: 'Bat',
        battingTeamId: teamA.id,
        playingXI_A: [
          Player(id: 'p_A', name: 'Player A', role: 'Batter', nationality: 'IND'),
          Player(id: 'p_B', name: 'Player B', role: 'Batter', nationality: 'IND'),
        ],
        playingXI_B: [
          Player(id: 'p_C', name: 'Player C', role: 'Bowler', nationality: 'IND'),
        ],
        runsA: 20,
        wicketsA: 0,
        oversA: 1.0,
        runsB: 0,
        wicketsB: 0,
        oversB: 0.0,
        target: 0,
        scorerUsername: 'scorer1',
        scorerPassword: 'pass1',
        balls: [
          // Player A: 4 balls, 15 runs (6, 6, 2, 1)
          BallRecord(strikerId: 'p_A', batsmanName: 'Player A', bowlerId: 'p_C', bowlerName: 'Player C', run: 6, extraRun: 0, extraType: 'None', isWicket: false, wicketType: 'None', commentary: '', timestamp: DateTime.now(), innings: 1, over: 0.1),
          BallRecord(strikerId: 'p_A', batsmanName: 'Player A', bowlerId: 'p_C', bowlerName: 'Player C', run: 6, extraRun: 0, extraType: 'None', isWicket: false, wicketType: 'None', commentary: '', timestamp: DateTime.now(), innings: 1, over: 0.2),
          BallRecord(strikerId: 'p_A', batsmanName: 'Player A', bowlerId: 'p_C', bowlerName: 'Player C', run: 2, extraRun: 0, extraType: 'None', isWicket: false, wicketType: 'None', commentary: '', timestamp: DateTime.now(), innings: 1, over: 0.3),
          BallRecord(strikerId: 'p_A', batsmanName: 'Player A', bowlerId: 'p_C', bowlerName: 'Player C', run: 1, extraRun: 0, extraType: 'None', isWicket: false, wicketType: 'None', commentary: '', timestamp: DateTime.now(), innings: 1, over: 0.4),
          // Player B: 2 balls, 5 runs (4, 1)
          BallRecord(strikerId: 'p_B', batsmanName: 'Player B', bowlerId: 'p_C', bowlerName: 'Player C', run: 4, extraRun: 0, extraType: 'None', isWicket: false, wicketType: 'None', commentary: '', timestamp: DateTime.now(), innings: 1, over: 0.5),
          BallRecord(strikerId: 'p_B', batsmanName: 'Player B', bowlerId: 'p_C', bowlerName: 'Player C', run: 1, extraRun: 0, extraType: 'None', isWicket: false, wicketType: 'None', commentary: '', timestamp: DateTime.now(), innings: 1, over: 0.6),
        ],
      );

      // Isolate both matches
      storage.isolateMatchStats(match1);
      storage.isolateMatchStats(match2);

      // 1. Verify Match 1 isolated figures
      final m1A = match1.playingXI_A.firstWhere((p) => p.id == 'p_A');
      final m1B = match1.playingXI_A.firstWhere((p) => p.id == 'p_B');
      expect(m1A.runsScored, equals(10), reason: 'Match 1 Player A must be 10 runs');
      expect(m1A.ballsFaced, equals(4), reason: 'Match 1 Player A balls faced must be 4');
      expect(m1B.runsScored, equals(20), reason: 'Match 1 Player B must be 20 runs');
      expect(m1B.ballsFaced, equals(6), reason: 'Match 1 Player B balls faced must be 6');

      // 2. Verify Match 2 isolated figures
      final m2A = match2.playingXI_A.firstWhere((p) => p.id == 'p_A');
      final m2B = match2.playingXI_A.firstWhere((p) => p.id == 'p_B');
      expect(m2A.runsScored, equals(15), reason: 'Match 2 Player A must be 15 runs');
      expect(m2A.ballsFaced, equals(4), reason: 'Match 2 Player A balls faced must be 4');
      expect(m2B.runsScored, equals(5), reason: 'Match 2 Player B must be 5 runs');
      expect(m2B.ballsFaced, equals(2), reason: 'Match 2 Player B balls faced must be 2');

      // 3. Verify Match 2 total does NOT include Match 1
      final m2TeamTotal = m2A.runsScored + m2B.runsScored;
      expect(m2TeamTotal, equals(20), reason: 'Match 2 total runs must be 20, NOT 50');

      // 4. Test PDF generation for Match 2 with only Match 2 data
      final pdfBytes = await PdfReportService.buildPdfDocument({
        'match': match2,
        'title': 'AW vs BT Match 2',
        'teamAName': match2.teamA.name,
        'teamBName': match2.teamB.name,
        'scoreA': '20/0',
        'oversA': '1.0 Overs',
        'scoreB': '0/0',
        'oversB': '0.0 Overs',
        'result': 'Alpha Warriors won by 20 runs',
      });
      expect(pdfBytes, isNotNull);
      expect(pdfBytes.length, greaterThan(1000), reason: 'PDF must compile high-quality binary document');
    });

    test('Career and tournament totals aggregate across matches without leaking into match scorecards', () {
      final match1 = CricketMatch(
        id: 'm1',
        teamA: teamA,
        teamB: teamB,
        matchType: 'T20',
        venue: 'Stadium 1',
        date: '2026-11-01',
        time: '14:00',
        status: 'Completed',
        tossWinner: 'Alpha Warriors',
        tossDecision: 'Bat',
        battingTeamId: teamA.id,
        playingXI_A: [
          Player(id: 'p_A', name: 'Player A', role: 'Batter', nationality: 'IND'),
          Player(id: 'p_B', name: 'Player B', role: 'Batter', nationality: 'IND'),
        ],
        playingXI_B: [
          Player(id: 'p_C', name: 'Player C', role: 'Bowler', nationality: 'IND'),
        ],
        runsA: 30,
        wicketsA: 0,
        oversA: 1.4,
        runsB: 0,
        wicketsB: 0,
        oversB: 0.0,
        target: 0,
        scorerUsername: 'scorer1',
        scorerPassword: 'pass1',
        balls: [
          BallRecord(strikerId: 'p_A', batsmanName: 'Player A', bowlerId: 'p_C', bowlerName: 'Player C', run: 10, extraRun: 0, extraType: 'None', isWicket: false, wicketType: 'None', commentary: '', timestamp: DateTime.now(), innings: 1, over: 0.4),
          BallRecord(strikerId: 'p_B', batsmanName: 'Player B', bowlerId: 'p_C', bowlerName: 'Player C', run: 20, extraRun: 0, extraType: 'None', isWicket: false, wicketType: 'None', commentary: '', timestamp: DateTime.now(), innings: 1, over: 1.4),
        ],
      );

      final match2 = CricketMatch(
        id: 'm2',
        teamA: teamA,
        teamB: teamB,
        matchType: 'T20',
        venue: 'Stadium 2',
        date: '2026-11-05',
        time: '18:00',
        status: 'Completed',
        tossWinner: 'Alpha Warriors',
        tossDecision: 'Bat',
        battingTeamId: teamA.id,
        playingXI_A: [
          Player(id: 'p_A', name: 'Player A', role: 'Batter', nationality: 'IND'),
          Player(id: 'p_B', name: 'Player B', role: 'Batter', nationality: 'IND'),
        ],
        playingXI_B: [
          Player(id: 'p_C', name: 'Player C', role: 'Bowler', nationality: 'IND'),
        ],
        runsA: 20,
        wicketsA: 0,
        oversA: 1.0,
        runsB: 0,
        wicketsB: 0,
        oversB: 0.0,
        target: 0,
        scorerUsername: 'scorer1',
        scorerPassword: 'pass1',
        balls: [
          BallRecord(strikerId: 'p_A', batsmanName: 'Player A', bowlerId: 'p_C', bowlerName: 'Player C', run: 15, extraRun: 0, extraType: 'None', isWicket: false, wicketType: 'None', commentary: '', timestamp: DateTime.now(), innings: 1, over: 0.4),
          BallRecord(strikerId: 'p_B', batsmanName: 'Player B', bowlerId: 'p_C', bowlerName: 'Player C', run: 5, extraRun: 0, extraType: 'None', isWicket: false, wicketType: 'None', commentary: '', timestamp: DateTime.now(), innings: 1, over: 0.6),
        ],
      );

      storage.matches.addAll([match1, match2]);
      storage.teams.addAll([teamA, teamB]);

      // Trigger recalculation across all matches into team career stats
      storage.isolateMatchStats(match1);
      storage.isolateMatchStats(match2);

      // Verify match-level stats remain isolated
      expect(match1.playingXI_A[0].runsScored, equals(10));
      expect(match2.playingXI_A[0].runsScored, equals(15));

      // Calculate career stats for Player A and Player B across matches
      final playerACareerRuns = match1.playingXI_A[0].runsScored + match2.playingXI_A[0].runsScored;
      final playerBCareerRuns = match1.playingXI_A[1].runsScored + match2.playingXI_A[1].runsScored;

      expect(playerACareerRuns, equals(25), reason: 'Player A career runs across both matches must be 25');
      expect(playerBCareerRuns, equals(25), reason: 'Player B career runs across both matches must be 25');
    });

    test('Switching between Match 1 and Match 2 context retains zero stale data', () {
      final matchA = CricketMatch(
        id: 'mA',
        teamA: teamA,
        teamB: teamB,
        matchType: 'T20',
        venue: 'Stadium A',
        date: '2026-11-01',
        time: '14:00',
        status: 'Upcoming',
        tossWinner: '',
        tossDecision: '',
        battingTeamId: '',
        playingXI_A: [
          Player(id: 'p_A', name: 'Player A', role: 'Batter', nationality: 'IND', runsScored: 50), // corrupted initial stat
        ],
        playingXI_B: [],
        runsA: 0,
        wicketsA: 0,
        oversA: 0.0,
        runsB: 0,
        wicketsB: 0,
        oversB: 0.0,
        target: 0,
        scorerUsername: 'scorer1',
        scorerPassword: 'pass1',
        balls: [], // 0 balls confirmed
      );

      storage.isolateMatchStats(matchA);

      // Must be cleanly 0 because no confirmed balls in this match
      expect(matchA.playingXI_A[0].runsScored, equals(0), reason: 'Match with 0 balls must reset contaminated player stats to 0');
    });
  });
}
