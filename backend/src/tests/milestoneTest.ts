import assert from 'assert';

console.log('🏏 RUNNING PREMIUM MILESTONE CELEBRATION LOGIC TESTS 🏏');

interface TestBatsman {
  id: string;
  name: string;
  runsScored: number;
  ballsFaced: number;
}

interface TestMatch {
  id: string;
  isFirstInnings: boolean;
  celebratedMilestones: string[];
}

function processBallScore({
  match,
  striker,
  runs,
  extraType,
  batTeam,
}: {
  match: TestMatch;
  striker: TestBatsman;
  runs: number;
  extraType: string;
  batTeam: { name: string; shortName: string; logoColorHex: string };
}) {
  const prevStrikerRuns = Number(striker.runsScored || 0);
  const runsNum = Number(runs) || 0;

  if (extraType === 'None' || extraType === 'No Ball') {
    striker.runsScored = (striker.runsScored || 0) + runsNum;
  }
  if (extraType !== 'Wide') {
    striker.ballsFaced = (striker.ballsFaced || 0) + 1;
  }
  const newStrikerRuns = Number(striker.runsScored || 0);

  const currentInnings = match.isFirstInnings ? 1 : 2;
  match.celebratedMilestones = match.celebratedMilestones || [];
  let detectedMilestone: any = null;

  if ((extraType === 'None' || extraType === 'No Ball') && runsNum > 0) {
    const m100Key = `${currentInnings}_${striker.id}_100`;
    const m50Key = `${currentInnings}_${striker.id}_50`;

    if (prevStrikerRuns < 100 && newStrikerRuns >= 100 && !match.celebratedMilestones.includes(m100Key)) {
      match.celebratedMilestones.push(m100Key);
      detectedMilestone = {
        eventId: `ms_${match.id}_${currentInnings}_${striker.id}_100_${Date.now()}`,
        matchId: match.id,
        type: '100',
        batsmanId: striker.id,
        batsmanName: striker.name,
        runs: newStrikerRuns,
        ballsFaced: striker.ballsFaced || 0,
        teamName: batTeam.name,
        teamShortName: batTeam.shortName,
        teamColorHex: batTeam.logoColorHex,
        innings: currentInnings,
      };
    } else if (prevStrikerRuns < 50 && newStrikerRuns >= 50 && !match.celebratedMilestones.includes(m50Key)) {
      match.celebratedMilestones.push(m50Key);
      detectedMilestone = {
        eventId: `ms_${match.id}_${currentInnings}_${striker.id}_50_${Date.now()}`,
        matchId: match.id,
        type: '50',
        batsmanId: striker.id,
        batsmanName: striker.name,
        runs: newStrikerRuns,
        ballsFaced: striker.ballsFaced || 0,
        teamName: batTeam.name,
        teamShortName: batTeam.shortName,
        teamColorHex: batTeam.logoColorHex,
        innings: currentInnings,
      };
    }
  }

  return detectedMilestone;
}

function processUndo({
  match,
  striker,
  runsUndone,
  extraType,
}: {
  match: TestMatch;
  striker: TestBatsman;
  runsUndone: number;
  extraType: string;
}) {
  if (extraType === 'None' || extraType === 'No Ball') {
    striker.runsScored = Math.max(0, (striker.runsScored || 0) - runsUndone);
  }
  if (extraType !== 'Wide') {
    striker.ballsFaced = Math.max(0, (striker.ballsFaced || 0) - 1);
  }

  const currentInnings = match.isFirstInnings ? 1 : 2;
  match.celebratedMilestones = match.celebratedMilestones || [];
  if (striker.runsScored < 100) {
    const m100Key = `${currentInnings}_${striker.id}_100`;
    match.celebratedMilestones = match.celebratedMilestones.filter((k) => k !== m100Key);
  }
  if (striker.runsScored < 50) {
    const m50Key = `${currentInnings}_${striker.id}_50`;
    match.celebratedMilestones = match.celebratedMilestones.filter((k) => k !== m50Key);
  }
}

// ─── TEST 1: Exact 49 -> 50 ───
console.log('\n[Test 1] 49 -> 50 single run milestone trigger');
{
  const match: TestMatch = { id: 'm1', isFirstInnings: true, celebratedMilestones: [] };
  const striker: TestBatsman = { id: 'p1', name: 'Virat Kohli', runsScored: 49, ballsFaced: 32 };
  const batTeam = { name: 'Royal Challengers', shortName: 'RCB', logoColorHex: '0xFF078B70' };

  const event = processBallScore({ match, striker, runs: 1, extraType: 'None', batTeam });
  assert(event !== null, 'Milestone should trigger for 49 -> 50');
  assert.strictEqual(event.type, '50');
  assert.strictEqual(event.runs, 50);
  assert.strictEqual(event.batsmanName, 'Virat Kohli');
  assert(match.celebratedMilestones.includes('1_p1_50'), 'Milestone key must be tracked');
  console.log('✅ Passed: 49 -> 50 triggered Half Century successfully.');
}

// ─── TEST 2: Crossing Milestone 49 -> 51 (via 2 runs) and 49 -> 53 (via 4) ───
console.log('\n[Test 2] Crossing milestone 49 -> 51 / 49 -> 53');
{
  const match: TestMatch = { id: 'm1', isFirstInnings: true, celebratedMilestones: [] };
  const striker: TestBatsman = { id: 'p2', name: 'Rohit Sharma', runsScored: 49, ballsFaced: 28 };
  const batTeam = { name: 'Mumbai Indians', shortName: 'MI', logoColorHex: '0xFF064E3B' };

  const event = processBallScore({ match, striker, runs: 2, extraType: 'None', batTeam });
  assert(event !== null, 'Milestone should trigger for 49 -> 51');
  assert.strictEqual(event.type, '50');
  assert.strictEqual(event.runs, 51);
  console.log('✅ Passed: 49 -> 51 triggered Half Century correctly.');
}

// ─── TEST 3: Exact 99 -> 100 ───
console.log('\n[Test 3] 99 -> 100 Century trigger');
{
  const match: TestMatch = { id: 'm1', isFirstInnings: true, celebratedMilestones: ['1_p1_50'] };
  const striker: TestBatsman = { id: 'p1', name: 'Virat Kohli', runsScored: 99, ballsFaced: 58 };
  const batTeam = { name: 'Royal Challengers', shortName: 'RCB', logoColorHex: '0xFF078B70' };

  const event = processBallScore({ match, striker, runs: 1, extraType: 'None', batTeam });
  assert(event !== null, 'Milestone should trigger for 99 -> 100');
  assert.strictEqual(event.type, '100');
  assert.strictEqual(event.runs, 100);
  assert(match.celebratedMilestones.includes('1_p1_100'), 'Century milestone key must be tracked');
  console.log('✅ Passed: 99 -> 100 triggered Century Completed successfully.');
}

// ─── TEST 4: Crossing Century 99 -> 101 / 99 -> 103 (via boundary) ───
console.log('\n[Test 4] 99 -> 103 via boundary');
{
  const match: TestMatch = { id: 'm1', isFirstInnings: true, celebratedMilestones: ['1_p2_50'] };
  const striker: TestBatsman = { id: 'p2', name: 'Rohit Sharma', runsScored: 99, ballsFaced: 55 };
  const batTeam = { name: 'Mumbai Indians', shortName: 'MI', logoColorHex: '0xFF064E3B' };

  const event = processBallScore({ match, striker, runs: 4, extraType: 'None', batTeam });
  assert(event !== null, 'Milestone should trigger for 99 -> 103');
  assert.strictEqual(event.type, '100');
  assert.strictEqual(event.runs, 103);
  console.log('✅ Passed: 99 -> 103 triggered Century Completed correctly.');
}

// ─── TEST 5: Duplicate Prevention (Trigger once per batsman per innings) ───
console.log('\n[Test 5] Duplicate prevention on subsequent balls');
{
  const match: TestMatch = { id: 'm1', isFirstInnings: true, celebratedMilestones: ['1_p1_50'] };
  const striker: TestBatsman = { id: 'p1', name: 'Virat Kohli', runsScored: 50, ballsFaced: 33 };
  const batTeam = { name: 'Royal Challengers', shortName: 'RCB', logoColorHex: '0xFF078B70' };

  // Next ball batsman scores 1 run to reach 51
  const event1 = processBallScore({ match, striker, runs: 1, extraType: 'None', batTeam });
  assert.strictEqual(event1, null, 'Should NOT trigger milestone on 50 -> 51 (already celebrated 50)');

  // Next ball batsman scores 4 to reach 55
  const event2 = processBallScore({ match, striker, runs: 4, extraType: 'None', batTeam });
  assert.strictEqual(event2, null, 'Should NOT trigger milestone on 51 -> 55');
  console.log('✅ Passed: Subsequent balls do not trigger duplicate celebrations.');
}

// ─── TEST 6: Extras do NOT trigger batsman milestones ───
console.log('\n[Test 6] Extras (Wides, Byes, Leg Byes) do NOT count as batsman runs');
{
  const match: TestMatch = { id: 'm1', isFirstInnings: true, celebratedMilestones: [] };
  const striker: TestBatsman = { id: 'p1', name: 'Virat Kohli', runsScored: 49, ballsFaced: 32 };
  const batTeam = { name: 'Royal Challengers', shortName: 'RCB', logoColorHex: '0xFF078B70' };

  // Wide ball: runsNum is 0 (or extra), extraType is 'Wide'
  const eventWide = processBallScore({ match, striker, runs: 0, extraType: 'Wide', batTeam });
  assert.strictEqual(eventWide, null, 'Wide ball should not trigger milestone');
  assert.strictEqual(striker.runsScored, 49, 'Batsman runs must remain 49 on wide');

  // Bye: runsNum is 0 for batsman, extraType is 'Bye'
  const eventBye = processBallScore({ match, striker, runs: 0, extraType: 'Bye', batTeam });
  assert.strictEqual(eventBye, null, 'Bye should not trigger milestone');
  assert.strictEqual(striker.runsScored, 49, 'Batsman runs must remain 49 on bye');
  console.log('✅ Passed: Extras do not trigger batsman milestones.');
}

// ─── TEST 7: Undo and Re-trigger Safety ───
console.log('\n[Test 7] Score correction and undo safely resets milestone');
{
  const match: TestMatch = { id: 'm1', isFirstInnings: true, celebratedMilestones: [] };
  const striker: TestBatsman = { id: 'p1', name: 'Virat Kohli', runsScored: 49, ballsFaced: 32 };
  const batTeam = { name: 'Royal Challengers', shortName: 'RCB', logoColorHex: '0xFF078B70' };

  // Scorer mistakenly entered 1 run
  const event = processBallScore({ match, striker, runs: 1, extraType: 'None', batTeam });
  assert(event !== null && event.type === '50');
  assert(match.celebratedMilestones.includes('1_p1_50'));

  // Scorer hits UNDO
  processUndo({ match, striker, runsUndone: 1, extraType: 'None' });
  assert.strictEqual(striker.runsScored, 49, 'Runs must revert to 49');
  assert(!match.celebratedMilestones.includes('1_p1_50'), 'Milestone tracking key must be removed upon undo');

  // Next genuine ball, batsman scores 2 runs -> 49 to 51
  const reEvent = processBallScore({ match, striker, runs: 2, extraType: 'None', batTeam });
  assert(reEvent !== null, 'Milestone must be allowed to trigger again after undo');
  assert.strictEqual(reEvent.type, '50');
  assert.strictEqual(reEvent.runs, 51);
  console.log('✅ Passed: Undo safely removes milestone key and allows legitimate re-triggering.');
}

// ─── TEST 8: Innings Independence ───
console.log('\n[Test 8] Innings 1 and Innings 2 are tracked independently');
{
  const match: TestMatch = { id: 'm1', isFirstInnings: false, celebratedMilestones: ['1_p1_50'] };
  const striker: TestBatsman = { id: 'p1', name: 'Virat Kohli', runsScored: 49, ballsFaced: 30 };
  const batTeam = { name: 'Royal Challengers', shortName: 'RCB', logoColorHex: '0xFF078B70' };

  // Even if p1 scored 50 in innings 1, in innings 2 he can score 50 again
  const eventInnings2 = processBallScore({ match, striker, runs: 1, extraType: 'None', batTeam });
  assert(eventInnings2 !== null, 'Innings 2 must trigger milestone independently');
  assert.strictEqual(eventInnings2.type, '50');
  assert(match.celebratedMilestones.includes('2_p1_50'), 'Innings 2 milestone key must be tracked with prefix 2_');
  console.log('✅ Passed: Both innings track milestones independently.');
}

console.log('\n========================================');
console.log('🎉 ALL MILESTONE LOGIC TESTS PASSED (8/8) 🎉');
console.log('========================================\n');

