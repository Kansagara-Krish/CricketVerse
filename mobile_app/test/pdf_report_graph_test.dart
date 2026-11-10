import 'package:flutter_test/flutter_test.dart';
import 'package:cricketverse_ai/models/models.dart';
import 'package:cricketverse_ai/services/pdf_report_service.dart';

void main() {
  Team makeTeam(String id, String name, String shortName) => Team(
        id: id,
        name: name,
        shortName: shortName,
        logoColorHex: '0xFF059669',
        players: [
          Player(
            id: '${id}_p1',
            name: '$shortName Batter 1',
            role: 'Batter',
            nationality: shortName,
            runsScored: 45,
            ballsFaced: 24,
          ),
          Player(
            id: '${id}_p2',
            name: '$shortName Bowler 1',
            role: 'Bowler',
            nationality: shortName,
            oversBowled: 4.0,
            runsConceded: 32,
            wicketsTaken: 2,
          ),
        ],
      );

  test('PdfReportService generates valid PDF with progression graphs for completed 2-innings match', () async {
    final teamA = makeTeam('team_a', 'India', 'IND');
    final teamB = makeTeam('team_b', 'Australia', 'AUS');

    final match = CricketMatch(
      id: 'match_test_1',
      teamA: teamA,
      teamB: teamB,
      matchType: 'T20',
      venue: 'Wankhede Stadium',
      date: '2026-11-10',
      time: '19:30',
      status: 'Completed',
      tossWinner: 'India',
      tossDecision: 'Bat',
      battingTeamId: 'team_b',
      playingXI_A: teamA.players,
      playingXI_B: teamB.players,
      runsA: 185,
      wicketsA: 4,
      oversA: 20.0,
      runsB: 162,
      wicketsB: 7,
      oversB: 19.3,
      scorerUsername: 'manager1',
      scorerPassword: 'secret',
      resultText: 'India won by 23 runs',
      balls: [
        BallRecord(
          run: 6,
          extraRun: 0,
          extraType: 'None',
          isWicket: false,
          wicketType: 'None',
          batsmanName: 'IND Batter 1',
          bowlerName: 'AUS Bowler 1',
          commentary: 'Six!',
          timestamp: DateTime.now(),
          innings: 1,
          battingTeamId: 'team_a',
          over: 1.0,
        ),
        BallRecord(
          run: 4,
          extraRun: 0,
          extraType: 'None',
          isWicket: false,
          wicketType: 'None',
          batsmanName: 'IND Batter 1',
          bowlerName: 'AUS Bowler 1',
          commentary: 'Four!',
          timestamp: DateTime.now(),
          innings: 1,
          battingTeamId: 'team_a',
          over: 5.0,
        ),
        BallRecord(
          run: 4,
          extraRun: 0,
          extraType: 'None',
          isWicket: false,
          wicketType: 'None',
          batsmanName: 'AUS Batter 1',
          bowlerName: 'IND Bowler 1',
          commentary: 'Boundary!',
          timestamp: DateTime.now(),
          innings: 2,
          battingTeamId: 'team_b',
          over: 2.4,
        ),
      ],
    );

    final bytes = await PdfReportService.buildPdfDocument({
      'title': 'India vs Australia',
      'match': match,
    });

    expect(bytes.isNotEmpty, isTrue);
    final header = String.fromCharCodes(bytes.take(5));
    expect(header, equals('%PDF-'));
  });

  test('PdfReportService handles unfinished innings and zero-score match gracefully', () async {
    final teamA = makeTeam('team_a', 'Team Alpha', 'ALP');
    final teamB = makeTeam('team_b', 'Team Beta', 'BET');

    final emptyMatch = CricketMatch(
      id: 'match_test_zero',
      teamA: teamA,
      teamB: teamB,
      matchType: 'T20',
      venue: 'Test Ground',
      date: '2026-11-10',
      time: '14:00',
      status: 'Upcoming',
      playingXI_A: teamA.players,
      playingXI_B: teamB.players,
      runsA: 0,
      wicketsA: 0,
      oversA: 0.0,
      runsB: 0,
      wicketsB: 0,
      oversB: 0.0,
      scorerUsername: 'manager1',
      scorerPassword: 'secret',
      balls: [],
    );

    final bytes = await PdfReportService.buildPdfDocument({
      'title': 'Team Alpha vs Team Beta',
      'match': emptyMatch,
    });

    expect(bytes.isNotEmpty, isTrue);
    final header = String.fromCharCodes(bytes.take(5));
    expect(header, equals('%PDF-'));
  });
}
