import 'package:flutter_test/flutter_test.dart';
import 'package:cricketverse_ai/services/ai_commentary_generator.dart';

void main() {
  const forbiddenTerms = [
    'mid-off',
    'mid-on',
    'leg side',
    'off side',
    'cover',
    'covers',
    'extra cover',
    'fine leg',
    'square leg',
    'third man',
    'point',
    'deep mid-wicket',
    'mid-wicket',
    'long-on',
    'long-off',
  ];

  const forbiddenShots = [
    'drive',
    'drives',
    'driven',
    'driving',
    'cover drive',
    'straight drive',
    'pull',
    'pulls',
    'pulled',
    'pulling',
    'hook',
    'hooks',
    'hooked',
    'hooking',
    'cut',
    'cuts',
    'cutting',
    'late cut',
    'square cut',
    'upper cut',
    'flick',
    'flicks',
    'flicked',
    'flicking',
    'sweep',
    'sweeps',
    'swept',
    'sweeping',
    'reverse sweep',
    'paddle sweep',
    'slog sweep',
    'ramp',
    'ramps',
    'ramped',
    'ramp stroke',
    'ramp shot',
    'scoop',
    'scoops',
    'scooped',
    'dilscoop',
    'glance',
    'glances',
    'glanced',
    'leg glance',
    'clip',
    'clips',
    'clipped',
    'punch',
    'punches',
    'punched',
    'push',
    'pushes',
    'pushed',
    'glide',
    'glides',
    'glided',
    'dab',
    'dabs',
    'dabbed',
    'slash',
    'slashes',
    'slashed',
    'slog',
    'slogs',
    'slogged',
    'steer',
    'steers',
    'steered',
    'loft',
    'lofts',
    'lofted',
    'defend',
    'defends',
    'defended',
    'defensive',
    'defense',
    'block',
    'blocks',
    'blocked',
    'outside edge',
    'inside edge',
    'half-volley',
  ];

  String? findForbiddenShot(String text) {
    final lower = text.toLowerCase();
    for (final term in forbiddenShots) {
      final reg = RegExp(r'\b' + term.replaceAll('-', r'[- ]') + r'\b', caseSensitive: false);
      if (reg.hasMatch(lower)) return term;
    }
    return null;
  }

  bool containsForbidden(String text) {
    final lower = text.toLowerCase();
    for (final term in forbiddenTerms) {
      final reg = RegExp(r'\b' + term.replaceAll('-', r'[- ]') + r'\b', caseSensitive: false);
      if (reg.hasMatch(lower)) return true;
    }
    return false;
  }

  group('AI Commentary System Tests - All 8 Scenarios', () {
    test('Scenario 1 & 2: Wicket commentary mentions BOTH dismissed and incoming batsman', () {
      final comm = AiCommentaryGenerator.generate(
        const AiCommentaryContext(
          batsman: 'Rohit Sharma',
          bowler: 'Arshdeep Singh',
          isWicket: true,
          wicketType: 'Bowled',
          dismissedBatsman: 'Virat Kohli',
          incomingBatsman: 'Shubman Gill',
          totalRuns: 191,
          totalWickets: 8,
        ),
      );

      expect(comm.contains('Virat Kohli'), isTrue, reason: 'Must mention dismissed batsman');
      expect(comm.contains('Shubman Gill'), isTrue, reason: 'Must mention incoming batsman');
      expect(containsForbidden(comm), isFalse, reason: 'Must not contain forbidden field positions');
    });

    test('Scenario 3: Team wins by runs -> announcements include margin, scores, and teams', () {
      final result = AiCommentaryGenerator.generateMatchResultCommentary(
        winnerName: 'India',
        loserName: 'New Zealand',
        winnerRuns: 191,
        winnerWickets: 8,
        loserRuns: 168,
        loserWickets: 9,
        isWinByWickets: false,
        margin: 23,
      );

      expect(result.contains('INDIA WIN!'), isTrue);
      expect(result.contains('23 runs'), isTrue);
      expect(result.contains('191/8'), isTrue);
      expect(result.contains('168/9'), isTrue);
      expect(containsForbidden(result), isFalse);
    });

    test('Scenario 4: Team wins by wickets -> accurate remaining wickets (7 wickets, NOT 11)', () {
      final result = AiCommentaryGenerator.generateMatchResultCommentary(
        winnerName: 'New Zealand',
        loserName: 'India',
        winnerRuns: 192,
        winnerWickets: 3,
        loserRuns: 191,
        loserWickets: 8,
        isWinByWickets: true,
        margin: 10 - 3, // 7 wickets
        target: 192,
      );

      expect(result.contains('NEW ZEALAND WIN!'), isTrue);
      expect(result.contains('7 wickets'), isTrue);
      expect(result.contains('11 wickets'), isFalse, reason: 'Must never say 11 wickets!');
      expect(result.contains('192/3'), isTrue);
      expect(result.contains('191/8'), isTrue);
      expect(containsForbidden(result), isFalse);
    });

    test('Scenario 5: Match is tied', () {
      final result = AiCommentaryGenerator.generateMatchResultCommentary(
        winnerName: 'India',
        loserName: 'New Zealand',
        winnerRuns: 180,
        winnerWickets: 6,
        loserRuns: 180,
        loserWickets: 7,
        isWinByWickets: false,
        margin: 0,
        isTied: true,
      );

      expect(result.contains('ends in a tie'), isTrue);
      expect(result.contains('180/6'), isTrue);
      expect(result.contains('180/7'), isTrue);
    });

    test('Scenario 6: Match is abandoned -> no false winner', () {
      final result = AiCommentaryGenerator.generateMatchResultCommentary(
        winnerName: '',
        loserName: '',
        winnerRuns: 0,
        winnerWickets: 0,
        loserRuns: 0,
        loserWickets: 0,
        isWinByWickets: false,
        margin: 0,
        isAbandoned: true,
      );

      expect(result, equals('The match has been abandoned. No result.'));
    });

    test('Scenario 7: Normal shots have ZERO field-position or shot-direction descriptions', () {
      final runs = [0, 1, 2, 3, 4, 6];
      for (final r in runs) {
        for (int i = 0; i < 20; i++) {
          final comm = AiCommentaryGenerator.generate(
            AiCommentaryContext(
              batsman: 'Glenn Phillips',
              bowler: 'Arshdeep Singh',
              runs: r,
              totalRuns: 192,
              totalWickets: 3,
            ),
          );
          expect(containsForbidden(comm), isFalse, reason: 'Forbidden term found in "$comm" for run $r');
        }
      }
    });

    test('Scenario 8: Sanitizer correctly removes any forbidden words from dirty commentary', () {
      const dirty1 = 'The batsman plays it towards mid-off.';
      const dirty2 = 'A beautiful shot through the covers.';
      const dirty3 = 'The ball travels towards deep mid-wicket.';
      const dirty4 = 'He drives it through the off side.';

      expect(containsForbidden(AiCommentaryGenerator.sanitize(dirty1)), isFalse);
      expect(containsForbidden(AiCommentaryGenerator.sanitize(dirty2)), isFalse);
      expect(containsForbidden(AiCommentaryGenerator.sanitize(dirty3)), isFalse);
      expect(containsForbidden(AiCommentaryGenerator.sanitize(dirty4)), isFalse);
    });

    test('Scenario 9: AI commentary does NOT speak or generate ANY batsman shot types', () {
      final runs = [0, 1, 2, 3, 4, 6];
      final styles = ['Hype / Energetic', 'Technical', 'Casual'];

      for (final r in runs) {
        for (final st in styles) {
          for (int i = 0; i < 20; i++) {
            final comm = AiCommentaryGenerator.generate(
              AiCommentaryContext(
                batsman: 'Rohit Sharma',
                bowler: 'Jasprit Bumrah',
                runs: r,
                totalRuns: 120,
                totalWickets: 2,
                style: st,
                currentOvers: 14.2,
              ),
            );
            final forbiddenShot = findForbiddenShot(comm);
            expect(forbiddenShot, isNull, reason: 'Forbidden shot type "$forbiddenShot" found in "$comm" for run $r style $st');
          }
        }
      }

      // Wickets
      final wicketTypes = ['Bowled', 'Caught', 'LBW', 'Run Out', 'Stumped'];
      for (final wt in wicketTypes) {
        for (int i = 0; i < 15; i++) {
          final comm = AiCommentaryGenerator.generate(
            AiCommentaryContext(
              batsman: 'Virat Kohli',
              bowler: 'Mitchell Starc',
              runs: 0,
              isWicket: true,
              wicketType: wt,
              dismissedBatsman: 'Virat Kohli',
              incomingBatsman: 'KL Rahul',
              totalRuns: 145,
              totalWickets: 3,
            ),
          );
          final forbiddenShot = findForbiddenShot(comm);
          expect(forbiddenShot, isNull, reason: 'Forbidden shot type "$forbiddenShot" found in wicket "$comm"');
        }
      }
    });

    test('Scenario 10: Sanitizer cleanly removes shot types from dirty commentary', () {
      const dirty1 = 'FOUR! Rohit Sharma leans into the cover drive and pierces the boundary gap!';
      const dirty2 = 'SIX! Virat Kohli plays a blistering pull shot over the boundary rope!';
      const dirty3 = 'Short delivery, batsman plays a late cut past the fielder.';
      const dirty4 = 'Defended solidly off the front foot back to the bowler.';
      const dirty5 = 'Audacious ramp stroke! Batter outfoxes the bowler.';

      final clean1 = AiCommentaryGenerator.sanitize(dirty1);
      final clean2 = AiCommentaryGenerator.sanitize(dirty2);
      final clean3 = AiCommentaryGenerator.sanitize(dirty3);
      final clean4 = AiCommentaryGenerator.sanitize(dirty4);
      final clean5 = AiCommentaryGenerator.sanitize(dirty5);

      expect(findForbiddenShot(clean1), isNull, reason: 'Cleaned: $clean1');
      expect(findForbiddenShot(clean2), isNull, reason: 'Cleaned: $clean2');
      expect(findForbiddenShot(clean3), isNull, reason: 'Cleaned: $clean3');
      expect(findForbiddenShot(clean4), isNull, reason: 'Cleaned: $clean4');
      expect(findForbiddenShot(clean5), isNull, reason: 'Cleaned: $clean5');
    });
  });
}
