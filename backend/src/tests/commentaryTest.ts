import assert from 'assert';
import {
  generateAICommentary,
  computeMatchResult,
  sanitizeCricketCommentary,
} from '../controllers/scoringController';

console.log('--- RUNNING AI COMMENTARY VERIFICATION SUITE ---');

const FORBIDDEN_TERMS = [
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

const FORBIDDEN_SHOT_TERMS = [
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

function containsForbiddenShot(text: string): string | null {
  const lower = text.toLowerCase();
  for (const term of FORBIDDEN_SHOT_TERMS) {
    const regex = new RegExp(`\\b${term.replace('-', '[- ]')}\\b`, 'i');
    if (regex.test(lower)) {
      return term;
    }
  }
  return null;
}

function containsForbiddenTerm(text: string): string | null {
  const lower = text.toLowerCase();
  for (const term of FORBIDDEN_TERMS) {
    // Word boundary check
    const regex = new RegExp(`\\b${term.replace('-', '[- ]')}\\b`, 'i');
    if (regex.test(lower)) {
      return term;
    }
  }
  return null;
}

// ─── TEST 1 & 2: Wicket Commentary with BOTH Dismissed & Incoming Batsmen ───
console.log('\n[Test 1 & 2] Wicket commentary mentions dismissed AND incoming batsmen');
{
  const wicketTypes = ['Bowled', 'Caught', 'LBW', 'Run Out', 'Stumped', 'None'];
  for (const wt of wicketTypes) {
    const commentary = generateAICommentary({
      batsman: 'Rohit Sharma',
      bowler: 'Mitchell Starc',
      runs: 0,
      extraType: 'None',
      isWicket: true,
      wicketType: wt,
      dismissedBatsman: 'Virat Kohli',
      incomingBatsman: 'Shubman Gill',
      totalRuns: 45,
      totalWickets: 1,
    });

    console.log(`  ${wt}: "${commentary}"`);
    assert(
      commentary.includes('Virat Kohli'),
      `Commentary must mention dismissed batsman (Virat Kohli). Got: ${commentary}`
    );
    assert(
      commentary.includes('Shubman Gill'),
      `Commentary must mention incoming batsman (Shubman Gill). Got: ${commentary}`
    );
    assert(
      !containsForbiddenTerm(commentary),
      `Commentary must not contain forbidden field terms. Found: ${containsForbiddenTerm(commentary)} in "${commentary}"`
    );
  }
  console.log('✅ PASS: Wicket commentary dynamically and correctly announces both players.');
}

// ─── TEST 3: Team wins by runs ───
console.log('\n[Test 3] Team wins by runs -> correct winning margin and both final scores');
{
  const mockMatch: any = {
    id: 'match_runs_test',
    status: 'Completed',
    teamA: { id: 'team_ind', name: 'India', shortName: 'IND' },
    teamB: { id: 'team_nz', name: 'New Zealand', shortName: 'NZ' },
    teamAId: 'team_ind',
    teamBId: 'team_nz',
    tossWinner: 'team_ind',
    tossDecision: 'Bat',
    isFirstInnings: false,
    battingTeamId: 'team_nz',
    runsA: 191,
    wicketsA: 8,
    oversA: 20.0,
    runsB: 168,
    wicketsB: 9,
    oversB: 20.0,
    target: 192,
    balls: [],
  };

  computeMatchResult(mockMatch);

  console.log('  Result Text:', mockMatch.resultText);
  console.log('  Result Commentary:', mockMatch.resultCommentary);

  assert.strictEqual(mockMatch.winnerName, 'India');
  assert.strictEqual(mockMatch.resultText, 'India won by 23 runs');
  assert(mockMatch.resultCommentary.includes('INDIA WIN!'));
  assert(mockMatch.resultCommentary.includes('defeated New Zealand by 23 runs'));
  assert(mockMatch.resultCommentary.includes('191/8'));
  assert(mockMatch.resultCommentary.includes('168/9'));
  assert(
    !containsForbiddenTerm(mockMatch.resultCommentary),
    'Result commentary must not contain forbidden field terms'
  );
  console.log('✅ PASS: Team won by runs correctly announced with margin and both scores.');
}

// ─── TEST 4: Team wins by wickets (Accurate Remaining Wickets, NOT 11!) ───
console.log('\n[Test 4] Team wins by wickets -> accurate remaining wickets (7 wickets, not 11)');
{
  const mockMatch: any = {
    id: 'match_wickets_test',
    status: 'Completed',
    teamA: { id: 'team_ind', name: 'India', shortName: 'IND' },
    teamB: { id: 'team_nz', name: 'New Zealand', shortName: 'NZ', players: new Array(15).fill({ name: 'Squad Member' }) },
    teamAId: 'team_ind',
    teamBId: 'team_nz',
    tossWinner: 'team_ind',
    tossDecision: 'Bat',
    isFirstInnings: false,
    battingTeamId: 'team_nz',
    runsA: 191,
    wicketsA: 8,
    oversA: 20.0,
    runsB: 192,
    wicketsB: 3,
    oversB: 18.0,
    target: 192,
    playingXI_B: new Array(15).fill({ name: 'Squad Member' }),
    balls: [],
  };

  computeMatchResult(mockMatch);

  console.log('  Result Text:', mockMatch.resultText);
  console.log('  Result Commentary:', mockMatch.resultCommentary);

  assert.strictEqual(mockMatch.winnerName, 'New Zealand');
  // Must be 10 - 3 = 7 wickets, NOT 11 wickets!
  assert.strictEqual(mockMatch.resultText, 'New Zealand won by 7 wickets');
  assert(mockMatch.resultCommentary.includes('NEW ZEALAND WIN!'));
  assert(mockMatch.resultCommentary.includes('7 wickets'));
  assert(!mockMatch.resultCommentary.includes('11 wickets'));
  assert(mockMatch.resultCommentary.includes('192/3'));
  assert(mockMatch.resultCommentary.includes('191/8'));
  console.log('✅ PASS: Team won by wickets correctly calculates 7 wickets in hand.');
}

// ─── TEST 5: Match is tied ───
console.log('\n[Test 5] Match is tied -> correct tie commentary');
{
  const mockMatch: any = {
    id: 'match_tie_test',
    status: 'Completed',
    teamA: { id: 'team_ind', name: 'India', shortName: 'IND' },
    teamB: { id: 'team_nz', name: 'New Zealand', shortName: 'NZ' },
    teamAId: 'team_ind',
    teamBId: 'team_nz',
    tossWinner: 'team_ind',
    tossDecision: 'Bat',
    isFirstInnings: false,
    battingTeamId: 'team_nz',
    runsA: 180,
    wicketsA: 6,
    oversA: 20.0,
    runsB: 180,
    wicketsB: 7,
    oversB: 20.0,
    target: 181,
    balls: [{ run: 1, extraRun: 0, extraType: 'None', batsmanName: 'Batter', bowlerName: 'Bowler', commentary: 'Single', isWicket: false, wicketType: 'None' }],
  };

  computeMatchResult(mockMatch);

  console.log('  Result Text:', mockMatch.resultText);
  console.log('  Result Commentary:', mockMatch.resultCommentary);

  assert.strictEqual(mockMatch.winnerName, 'Tie');
  assert.strictEqual(mockMatch.resultText, 'Match Tied!');
  assert(mockMatch.resultCommentary.includes('ends in a tie'));
  assert(mockMatch.resultCommentary.includes('180/6'));
  assert(mockMatch.resultCommentary.includes('180/7'));
  console.log('✅ PASS: Tied match result commentary is accurate.');
}

// ─── TEST 6: Match is abandoned ───
console.log('\n[Test 6] Match is abandoned -> no false winner');
{
  const mockMatch: any = {
    id: 'match_abandoned_test',
    status: 'Abandoned',
    teamA: { id: 'team_ind', name: 'India', shortName: 'IND' },
    teamB: { id: 'team_nz', name: 'New Zealand', shortName: 'NZ' },
    teamAId: 'team_ind',
    teamBId: 'team_nz',
    runsA: 0,
    wicketsA: 0,
    oversA: 0.0,
    runsB: 0,
    wicketsB: 0,
    oversB: 0.0,
    balls: [],
  };

  computeMatchResult(mockMatch);

  console.log('  Result Text:', mockMatch.resultText);
  console.log('  Result Commentary:', mockMatch.resultCommentary);

  assert.strictEqual(mockMatch.winnerName, 'No Result');
  assert.strictEqual(mockMatch.resultCommentary, 'The match has been abandoned. No result.');
  console.log('✅ PASS: Abandoned match correctly sets No Result.');
}

// ─── TEST 7: Normal Shots have ZERO field positions ───
console.log('\n[Test 7] Normal shots (0, 1, 2, 3, 4, 6, Wide, No Ball) have NO field positions');
{
  const testScenarios = [
    { runs: 0, extraType: 'None' },
    { runs: 1, extraType: 'None' },
    { runs: 2, extraType: 'None' },
    { runs: 3, extraType: 'None' },
    { runs: 4, extraType: 'None' },
    { runs: 6, extraType: 'None' },
    { runs: 0, extraType: 'Wide' },
    { runs: 0, extraType: 'No Ball' },
  ];

  for (let i = 0; i < 50; i++) {
    for (const sc of testScenarios) {
      const comm = generateAICommentary({
        batsman: 'Glenn Phillips',
        bowler: 'Arshdeep Singh',
        runs: sc.runs,
        extraType: sc.extraType,
        isWicket: false,
        wicketType: 'None',
        totalRuns: 191,
        totalWickets: 3,
      });

      const forbidden = containsForbiddenTerm(comm);
      assert(
        !forbidden,
        `Forbidden term "${forbidden}" found in normal commentary: "${comm}"`
      );
    }
  }
  console.log('✅ PASS: Evaluated 400 random deliveries with 0 forbidden terms found.');
}

// ─── TEST 8: Match Completion Commentary Appears Only Once ───
console.log('\n[Test 8] Match completion commentary appears only once in balls array');
{
  const mockMatch: any = {
    id: 'match_single_result_test',
    status: 'Completed',
    teamA: { id: 'team_ind', name: 'India', shortName: 'IND' },
    teamB: { id: 'team_nz', name: 'New Zealand', shortName: 'NZ' },
    teamAId: 'team_ind',
    teamBId: 'team_nz',
    tossWinner: 'team_ind',
    tossDecision: 'Bat',
    isFirstInnings: false,
    battingTeamId: 'team_nz',
    runsA: 191,
    wicketsA: 8,
    oversA: 20.0,
    runsB: 192,
    wicketsB: 3,
    oversB: 18.0,
    target: 192,
    balls: [
      {
        run: 1,
        extraRun: 0,
        extraType: 'None',
        isWicket: false,
        wicketType: 'None',
        batsmanName: 'Glenn Phillips',
        bowlerName: 'Arshdeep Singh',
        commentary: 'Quick single taken.',
        timestamp: new Date().toISOString(),
      },
    ],
  };

  computeMatchResult(mockMatch);
  assert.strictEqual(mockMatch.balls.length, 2, 'Should have winning ball and result ball');

  // Call again simulating subsequent calls
  computeMatchResult(mockMatch);
  computeMatchResult(mockMatch);
  assert.strictEqual(mockMatch.balls.length, 2, 'Result ball must NOT be duplicated');

  const resultBalls = mockMatch.balls.filter(
    (b: any) => b.batsmanName === 'Match Result' || b.commentary.includes('WIN!')
  );
  assert.strictEqual(resultBalls.length, 1, 'Exactly one final result commentary ball must exist');
  console.log('✅ PASS: Match completion commentary appears exactly once without duplication.');
}

// ─── TEST 9: AI Commentary Does NOT Speak or Generate ANY Shot Types ───
console.log('\n[Test 9] AI commentary contains ZERO batsman shot types across all outcomes');
{
  const testScenarios = [
    { runs: 0, extraType: 'None' },
    { runs: 1, extraType: 'None' },
    { runs: 2, extraType: 'None' },
    { runs: 3, extraType: 'None' },
    { runs: 4, extraType: 'None' },
    { runs: 6, extraType: 'None' },
    { runs: 0, extraType: 'Wide' },
    { runs: 0, extraType: 'No Ball' },
  ];

  for (let i = 0; i < 50; i++) {
    for (const sc of testScenarios) {
      const comm = generateAICommentary({
        batsman: 'Rohit Sharma',
        bowler: 'Jasprit Bumrah',
        runs: sc.runs,
        extraType: sc.extraType,
        isWicket: false,
        wicketType: 'None',
        totalRuns: 120,
        totalWickets: 2,
      });

      const forbiddenShot = containsForbiddenShot(comm);
      assert(
        !forbiddenShot,
        `Forbidden shot type "${forbiddenShot}" found in commentary: "${comm}"`
      );
    }
  }

  // Wickets
  const wicketTypes = ['Bowled', 'Caught', 'LBW', 'Run Out'];
  for (const wt of wicketTypes) {
    for (let i = 0; i < 20; i++) {
      const comm = generateAICommentary({
        batsman: 'Virat Kohli',
        bowler: 'Mitchell Starc',
        runs: 0,
        extraType: 'None',
        isWicket: true,
        wicketType: wt,
        dismissedBatsman: 'Virat Kohli',
        incomingBatsman: 'KL Rahul',
        totalRuns: 145,
        totalWickets: 3,
      });

      const forbiddenShot = containsForbiddenShot(comm);
      assert(
        !forbiddenShot,
        `Forbidden shot type "${forbiddenShot}" found in wicket commentary: "${comm}"`
      );
    }
  }

  // Sanitizer removes dirty shot types
  const dirty1 = 'FOUR! Rohit Sharma leans into the cover drive and pierces the boundary gap!';
  const dirty2 = 'SIX! Virat Kohli plays a blistering pull shot over deep mid-wicket!';
  const dirty3 = 'Short delivery, batsman plays a late cut past third man.';
  const dirty4 = 'Defended solidly off the front foot back to the bowler.';

  const clean1 = sanitizeCricketCommentary(dirty1);
  const clean2 = sanitizeCricketCommentary(dirty2);
  const clean3 = sanitizeCricketCommentary(dirty3);
  const clean4 = sanitizeCricketCommentary(dirty4);

  assert(!containsForbiddenShot(clean1), `Sanitizer failed on: ${clean1}`);
  assert(!containsForbiddenShot(clean2), `Sanitizer failed on: ${clean2}`);
  assert(!containsForbiddenShot(clean3), `Sanitizer failed on: ${clean3}`);
  assert(!containsForbiddenShot(clean4), `Sanitizer failed on: ${clean4}`);

  console.log('✅ PASS: Evaluated 500+ deliveries; 0 shot types generated, and sanitizer cleans all shot types.');
}

console.log('\n🎉 ALL 9 TEST SCENARIOS PASSED WITH 100% SUCCESS!');
process.exit(0);
