import assert from 'assert';
import {
  sanitizePlayerForMatch,
  computeMatchIsolatedPlayerStats,
} from '../controllers/matchController';

console.log('=== RUNNING MATCH-WISE STATISTICS ISOLATION SUITE ===\n');

// 1. Setup mock team and player roster
const mockTeamPlayers = [
  { id: 'player_A', name: 'Player A', role: 'Batter', runsScored: 100, ballsFaced: 80, wicketsTaken: 0 },
  { id: 'player_B', name: 'Player B', role: 'All-rounder', runsScored: 200, ballsFaced: 150, wicketsTaken: 10 },
  { id: 'player_C', name: 'Player C', role: 'Bowler', runsScored: 5, ballsFaced: 10, wicketsTaken: 25 },
];

// Test 1: Sanitize players for match creation (must reset all match stats to 0)
console.log('[Test 1] Sanitize players for match instance creation');
{
  const sanitized = mockTeamPlayers.map(sanitizePlayerForMatch);
  assert.strictEqual(sanitized[0].id, 'player_A');
  assert.strictEqual(sanitized[0].runsScored, 0, 'Match runs must start at 0');
  assert.strictEqual(sanitized[0].ballsFaced, 0, 'Match balls must start at 0');
  assert.strictEqual(sanitized[0].wicketsTaken, 0, 'Match wickets must start at 0');
  assert.strictEqual(sanitized[0].oversBowled, 0.0);
  assert.strictEqual(sanitized[0].isOut, false);
  console.log('  ✓ Players cleanly initialized to 0 match stats.');
}

// Test 2: Match 1 and Match 2 with same players have strictly isolated stats
console.log('\n[Test 2] Match 1 (A=10, B=20) vs Match 2 (A=15, B=5) Strict Isolation');
{
  // Match 1 Deliveries:
  // Player A scores 10 runs (two 4s, two 1s = 4 balls)
  // Player B scores 20 runs (three 4s, one 6, two 1s = 6 balls)
  // Bowler Player C bowls
  const match1Balls = [
    { strikerId: 'player_A', batsmanName: 'Player A', bowlerId: 'player_C', bowlerName: 'Player C', run: 4, extraRun: 0, extraType: 'None', isWicket: false, innings: 1, over: 0.1 },
    { strikerId: 'player_A', batsmanName: 'Player A', bowlerId: 'player_C', bowlerName: 'Player C', run: 4, extraRun: 0, extraType: 'None', isWicket: false, innings: 1, over: 0.2 },
    { strikerId: 'player_A', batsmanName: 'Player A', bowlerId: 'player_C', bowlerName: 'Player C', run: 1, extraRun: 0, extraType: 'None', isWicket: false, innings: 1, over: 0.3 },
    { strikerId: 'player_A', batsmanName: 'Player A', bowlerId: 'player_C', bowlerName: 'Player C', run: 1, extraRun: 0, extraType: 'None', isWicket: false, innings: 1, over: 0.4 },
    { strikerId: 'player_B', batsmanName: 'Player B', bowlerId: 'player_C', bowlerName: 'Player C', run: 4, extraRun: 0, extraType: 'None', isWicket: false, innings: 1, over: 0.5 },
    { strikerId: 'player_B', batsmanName: 'Player B', bowlerId: 'player_C', bowlerName: 'Player C', run: 4, extraRun: 0, extraType: 'None', isWicket: false, innings: 1, over: 0.6 },
    { strikerId: 'player_B', batsmanName: 'Player B', bowlerId: 'player_C', bowlerName: 'Player C', run: 4, extraRun: 0, extraType: 'None', isWicket: false, innings: 1, over: 1.1 },
    { strikerId: 'player_B', batsmanName: 'Player B', bowlerId: 'player_C', bowlerName: 'Player C', run: 6, extraRun: 0, extraType: 'None', isWicket: false, innings: 1, over: 1.2 },
    { strikerId: 'player_B', batsmanName: 'Player B', bowlerId: 'player_C', bowlerName: 'Player C', run: 1, extraRun: 0, extraType: 'None', isWicket: false, innings: 1, over: 1.3 },
    { strikerId: 'player_B', batsmanName: 'Player B', bowlerId: 'player_C', bowlerName: 'Player C', run: 1, extraRun: 0, extraType: 'None', isWicket: false, innings: 1, over: 1.4 },
  ];

  // Match 2 Deliveries:
  // Player A scores 15 runs (two 6s, one 2, one 1 = 4 balls)
  // Player B scores 5 runs (one 4, one 1 = 2 balls)
  const match2Balls = [
    { strikerId: 'player_A', batsmanName: 'Player A', bowlerId: 'player_C', bowlerName: 'Player C', run: 6, extraRun: 0, extraType: 'None', isWicket: false, innings: 1, over: 0.1 },
    { strikerId: 'player_A', batsmanName: 'Player A', bowlerId: 'player_C', bowlerName: 'Player C', run: 6, extraRun: 0, extraType: 'None', isWicket: false, innings: 1, over: 0.2 },
    { strikerId: 'player_A', batsmanName: 'Player A', bowlerId: 'player_C', bowlerName: 'Player C', run: 2, extraRun: 0, extraType: 'None', isWicket: false, innings: 1, over: 0.3 },
    { strikerId: 'player_A', batsmanName: 'Player A', bowlerId: 'player_C', bowlerName: 'Player C', run: 1, extraRun: 0, extraType: 'None', isWicket: false, innings: 1, over: 0.4 },
    { strikerId: 'player_B', batsmanName: 'Player B', bowlerId: 'player_C', bowlerName: 'Player C', run: 4, extraRun: 0, extraType: 'None', isWicket: false, innings: 1, over: 0.5 },
    { strikerId: 'player_B', batsmanName: 'Player B', bowlerId: 'player_C', bowlerName: 'Player C', run: 1, extraRun: 0, extraType: 'None', isWicket: false, innings: 1, over: 0.6 },
  ];

  const m1Players = computeMatchIsolatedPlayerStats(match1Balls, mockTeamPlayers);
  const m2Players = computeMatchIsolatedPlayerStats(match2Balls, mockTeamPlayers);

  const m1A = m1Players.find(p => p.id === 'player_A')!;
  const m1B = m1Players.find(p => p.id === 'player_B')!;
  const m2A = m2Players.find(p => p.id === 'player_A')!;
  const m2B = m2Players.find(p => p.id === 'player_B')!;

  console.log(`  Match 1: Player A = ${m1A.runsScored} runs (${m1A.ballsFaced} balls), Player B = ${m1B.runsScored} runs (${m1B.ballsFaced} balls)`);
  console.log(`  Match 2: Player A = ${m2A.runsScored} runs (${m2A.ballsFaced} balls), Player B = ${m2B.runsScored} runs (${m2B.ballsFaced} balls)`);

  assert.strictEqual(m1A.runsScored, 10, 'Match 1: Player A must have 10 runs');
  assert.strictEqual(m1A.ballsFaced, 4, 'Match 1: Player A must have 4 balls faced');
  assert.strictEqual(m1B.runsScored, 20, 'Match 1: Player B must have 20 runs');
  assert.strictEqual(m1B.ballsFaced, 6, 'Match 1: Player B must have 6 balls faced');

  assert.strictEqual(m2A.runsScored, 15, 'Match 2: Player A must have 15 runs');
  assert.strictEqual(m2A.ballsFaced, 4, 'Match 2: Player A must have 4 balls faced');
  assert.strictEqual(m2B.runsScored, 5, 'Match 2: Player B must have 5 runs');
  assert.strictEqual(m2B.ballsFaced, 2, 'Match 2: Player B must have 2 balls faced');

  // Verify Match 2 total does not contain Match 1
  const m2Total = m2A.runsScored + m2B.runsScored;
  assert.strictEqual(m2Total, 20, 'Match 2 total must be 20 runs, NOT 50 runs');
  console.log('  ✓ Match 1 & Match 2 have strictly isolated individual scores and match totals.');

  // Verify tournament / career aggregation correctly sums both
  const careerA = m1A.runsScored + m2A.runsScored;
  const careerB = m1B.runsScored + m2B.runsScored;
  assert.strictEqual(careerA, 25, 'Career total for Player A across both matches must be 25');
  assert.strictEqual(careerB, 25, 'Career total for Player B across both matches must be 25');
  console.log(`  ✓ Career / Tournament aggregation correctly aggregates: Player A = ${careerA}, Player B = ${careerB}`);
}

// Test 3: Switching between Match 1 and Match 2 leaves zero stale residue
console.log('\n[Test 3] Context Switching and Stale State Resistance');
{
  const emptyMatch = computeMatchIsolatedPlayerStats([], mockTeamPlayers);
  const emptyA = emptyMatch.find(p => p.id === 'player_A')!;
  assert.strictEqual(emptyA.runsScored, 0);
  assert.strictEqual(emptyA.ballsFaced, 0);
  assert.strictEqual(emptyA.wicketsTaken, 0);
  console.log('  ✓ An upcoming match with 0 balls shows strictly 0 runs with zero residue.');
}

console.log('\n=== ALL MATCH ISOLATION BACKEND TESTS PASSED SUCCESSFULLY! ===\n');

