import assert from 'assert';

console.log('🏏 RUNNING PREMIUM CRICKET CELEBRATION SYSTEM UNIT & INTEGRATION TESTS 🏏');

interface TestBatsman {
  id: string;
  name: string;
  runsScored: number;
  ballsFaced: number;
}

interface TestBowler {
  id: string;
  name: string;
  wicketsTaken: number;
  runsConceded: number;
  oversBowled: number;
}

interface TestMatch {
  id: string;
  isFirstInnings: boolean;
  status: string;
  winnerName: string;
  resultText: string;
  celebratedMilestones: string[];
}

function processBallScore({
  match,
  striker,
  bowler,
  runs,
  extraType,
  isWicket,
  wicketType,
  batTeam,
  bowlTeam,
}: {
  match: TestMatch;
  striker: TestBatsman;
  bowler?: TestBowler;
  runs: number;
  extraType: string;
  isWicket?: boolean;
  wicketType?: string;
  batTeam: { name: string; shortName: string; logoColorHex: string };
  bowlTeam?: { name: string; shortName: string; logoColorHex: string };
}) {
  const prevStrikerRuns = Number(striker.runsScored || 0);
  const prevBowlerWickets = Number(bowler?.wicketsTaken || 0);
  const runsNum = Number(runs) || 0;

  if (extraType === 'None' || extraType === 'No Ball') {
    striker.runsScored = (striker.runsScored || 0) + runsNum;
  }
  if (extraType !== 'Wide') {
    striker.ballsFaced = (striker.ballsFaced || 0) + 1;
  }
  const newStrikerRuns = Number(striker.runsScored || 0);

  const isBowlerCredited = Boolean(
    isWicket && !['Run Out', 'Retired Out', 'Retired Hurt', 'Timed Out', 'Obstructing Field'].includes(wicketType || '')
  );

  if (bowler) {
    if (extraType === 'None' || extraType === 'Wide' || extraType === 'No Ball') {
      bowler.runsConceded = (bowler.runsConceded || 0) + runsNum;
    }
    if (isBowlerCredited) {
      bowler.wicketsTaken = (bowler.wicketsTaken || 0) + 1;
    }
  }
  const newBowlerWickets = Number(bowler?.wicketsTaken || 0);

  const currentInnings = match.isFirstInnings ? 1 : 2;
  match.celebratedMilestones = match.celebratedMilestones || [];
  let detectedMilestone: any = null;

  // 1. Batsman Milestones (100 & 50) and SIX
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
    } else if (runsNum === 6 && (extraType === 'None' || extraType === 'No Ball')) {
      detectedMilestone = {
        eventId: `six_${match.id}_${currentInnings}_${Date.now()}`,
        matchId: match.id,
        type: 'SIX',
        batsmanId: striker.id,
        batsmanName: striker.name,
        runs: 6,
        ballsFaced: striker.ballsFaced || 0,
        bowlerId: bowler ? bowler.id : '',
        bowlerName: bowler ? bowler.name : '',
        teamName: batTeam.name,
        innings: currentInnings,
      };
    }
  }

  // 2. Bowler 5-Wicket Haul or Wicket Celebration
  if (isBowlerCredited && bowler && prevBowlerWickets < 5 && newBowlerWickets >= 5) {
    const m5wKey = `${currentInnings}_${bowler.id}_5w`;
    if (!match.celebratedMilestones.includes(m5wKey)) {
      match.celebratedMilestones.push(m5wKey);
      detectedMilestone = {
        eventId: `5w_${match.id}_${currentInnings}_${bowler.id}_${Date.now()}`,
        matchId: match.id,
        type: 'FIVE_WICKET',
        bowlerId: bowler.id,
        bowlerName: bowler.name,
        bowlerWickets: newBowlerWickets,
        bowlerRunsConceded: bowler.runsConceded,
        teamName: bowlTeam ? bowlTeam.name : 'Bowling Team',
        innings: currentInnings,
      };
    }
  } else if (isWicket && !detectedMilestone) {
    detectedMilestone = {
      eventId: `wkt_${match.id}_${currentInnings}_${striker.id}_${Date.now()}`,
      matchId: match.id,
      type: 'WICKET',
      batsmanId: striker.id,
      batsmanName: striker.name,
      bowlerId: isBowlerCredited && bowler ? bowler.id : '',
      bowlerName: isBowlerCredited && bowler ? bowler.name : '',
      dismissalType: wicketType || 'Out',
      teamName: batTeam.name,
      innings: currentInnings,
    };
  }

  // 3. Match Completion (Highest Priority)
  if (match.status === 'Completed' && match.winnerName) {
    const mWinKey = `match_${match.id}_completed`;
    if (!match.celebratedMilestones.includes(mWinKey)) {
      match.celebratedMilestones.push(mWinKey);
      detectedMilestone = {
        eventId: `win_${match.id}_${Date.now()}`,
        matchId: match.id,
        type: 'MATCH_WON',
        winnerTeamName: match.winnerName,
        resultText: match.resultText,
        teamName: match.winnerName,
        runs: 0,
        ballsFaced: 0,
        innings: currentInnings,
      };
    }
  }

  return detectedMilestone;
}

function processUndo({
  match,
  striker,
  bowler,
  runsUndone,
  extraType,
  wasWicket,
  wicketType,
}: {
  match: TestMatch;
  striker: TestBatsman;
  bowler?: TestBowler;
  runsUndone: number;
  extraType: string;
  wasWicket?: boolean;
  wicketType?: string;
}) {
  if (extraType === 'None' || extraType === 'No Ball') {
    striker.runsScored = Math.max(0, (striker.runsScored || 0) - runsUndone);
  }
  if (extraType !== 'Wide') {
    striker.ballsFaced = Math.max(0, (striker.ballsFaced || 0) - 1);
  }

  const isBowlerCredited = Boolean(
    wasWicket && !['Run Out', 'Retired Out', 'Retired Hurt'].includes(wicketType || '')
  );
  if (bowler && isBowlerCredited) {
    bowler.wicketsTaken = Math.max(0, (bowler.wicketsTaken || 0) - 1);
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
  if (bowler && bowler.wicketsTaken < 5) {
    const m5wKey = `${currentInnings}_${bowler.id}_5w`;
    match.celebratedMilestones = match.celebratedMilestones.filter((k) => k !== m5wKey);
  }
  if (match.status !== 'Completed') {
    match.celebratedMilestones = match.celebratedMilestones.filter((k) => k !== `match_${match.id}_completed`);
  }
}

// ─── TEST 1: HALF-CENTURY (49 -> 50) ───
console.log('\n[Test 1] 49 -> 50 single run milestone trigger');
{
  const match: TestMatch = { id: 'm1', isFirstInnings: true, status: 'Live', winnerName: '', resultText: '', celebratedMilestones: [] };
  const striker: TestBatsman = { id: 'p1', name: 'Virat Kohli', runsScored: 49, ballsFaced: 32 };
  const batTeam = { name: 'Royal Challengers', shortName: 'RCB', logoColorHex: '0xFF078B70' };

  const event = processBallScore({ match, striker, runs: 1, extraType: 'None', batTeam });
  assert(event !== null, 'Milestone should trigger for 49 -> 50');
  assert.strictEqual(event.type, '50');
  assert.strictEqual(event.runs, 50);
  assert(match.celebratedMilestones.includes('1_p1_50'));
  console.log('✅ Passed: 49 -> 50 triggered Half Century successfully.');
}

// ─── TEST 2: HALF-CENTURY THRESHOLD CROSSING (48 -> 52 via boundary) ───
console.log('\n[Test 2] Threshold crossing 48 -> 52 via boundary');
{
  const match: TestMatch = { id: 'm1', isFirstInnings: true, status: 'Live', winnerName: '', resultText: '', celebratedMilestones: [] };
  const striker: TestBatsman = { id: 'p2', name: 'Rohit Sharma', runsScored: 48, ballsFaced: 28 };
  const batTeam = { name: 'Mumbai Indians', shortName: 'MI', logoColorHex: '0xFF064E3B' };

  const event = processBallScore({ match, striker, runs: 4, extraType: 'None', batTeam });
  assert(event !== null, 'Milestone should trigger for 48 -> 52');
  assert.strictEqual(event.type, '50');
  assert.strictEqual(event.runs, 52);
  console.log('✅ Passed: 48 -> 52 triggered Half Century successfully.');

  // Verify no duplicate celebration on 53, 54
  const nextEvent = processBallScore({ match, striker, runs: 1, extraType: 'None', batTeam });
  assert(nextEvent === null, 'Subsequent runs (53) should not trigger duplicate 50 milestone');
  console.log('✅ Passed: Subsequent runs (53) did NOT trigger duplicate 50 celebration.');
}

// ─── TEST 3: CENTURY (99 -> 100) ───
console.log('\n[Test 3] 99 -> 100 Century trigger');
{
  const match: TestMatch = { id: 'm1', isFirstInnings: true, status: 'Live', winnerName: '', resultText: '', celebratedMilestones: ['1_p1_50'] };
  const striker: TestBatsman = { id: 'p1', name: 'Virat Kohli', runsScored: 99, ballsFaced: 58 };
  const batTeam = { name: 'Royal Challengers', shortName: 'RCB', logoColorHex: '0xFF078B70' };

  const event = processBallScore({ match, striker, runs: 1, extraType: 'None', batTeam });
  assert(event !== null, 'Century should trigger for 99 -> 100');
  assert.strictEqual(event.type, '100');
  assert.strictEqual(event.runs, 100);
  assert(match.celebratedMilestones.includes('1_p1_100'));
  console.log('✅ Passed: 99 -> 100 triggered Century Completed successfully.');
}

// ─── TEST 4: CENTURY THRESHOLD CROSSING (98 -> 104 via six) ───
console.log('\n[Test 4] Century threshold crossing 98 -> 104 via six');
{
  const match: TestMatch = { id: 'm1', isFirstInnings: true, status: 'Live', winnerName: '', resultText: '', celebratedMilestones: ['1_p1_50'] };
  const striker: TestBatsman = { id: 'p1', name: 'Virat Kohli', runsScored: 98, ballsFaced: 56 };
  const batTeam = { name: 'Royal Challengers', shortName: 'RCB', logoColorHex: '0xFF078B70' };

  const event = processBallScore({ match, striker, runs: 6, extraType: 'None', batTeam });
  assert(event !== null);
  // Century milestone must take precedence over six
  assert.strictEqual(event.type, '100');
  assert.strictEqual(event.runs, 104);
  console.log('✅ Passed: 98 -> 104 via six prioritized Century Completed.');

  const nextEvent = processBallScore({ match, striker, runs: 1, extraType: 'None', batTeam });
  assert(nextEvent === null, 'Subsequent run (105) must not duplicate century');
  console.log('✅ Passed: No duplicate century on subsequent balls.');
}

// ─── TEST 5: GENUINE SIX CELEBRATION ───
console.log('\n[Test 5] Genuine Six celebration trigger');
{
  const match: TestMatch = { id: 'm1', isFirstInnings: true, status: 'Live', winnerName: '', resultText: '', celebratedMilestones: [] };
  const striker: TestBatsman = { id: 'p3', name: 'Glenn Maxwell', runsScored: 12, ballsFaced: 6 };
  const bowler: TestBowler = { id: 'bw1', name: 'Rashid Khan', wicketsTaken: 1, runsConceded: 14, oversBowled: 2.1 };
  const batTeam = { name: 'Australia', shortName: 'AUS', logoColorHex: '0xFFFDE047' };

  const event = processBallScore({ match, striker, bowler, runs: 6, extraType: 'None', batTeam });
  assert(event !== null);
  assert.strictEqual(event.type, 'SIX');
  assert.strictEqual(event.runs, 6);
  assert.strictEqual(event.bowlerName, 'Rashid Khan');
  console.log('✅ Passed: Genuine six triggered SIX celebration with correct bowler.');

  // Confirm extras do NOT trigger six celebration
  const overthrowEvent = processBallScore({ match, striker, bowler, runs: 6, extraType: 'Wide', batTeam });
  assert(overthrowEvent === null, 'Wide + overthrows must NOT trigger SIX celebration');
  console.log('✅ Passed: Extras / non-boundary 6 did NOT trigger SIX celebration.');
}

// ─── TEST 6: WICKET CELEBRATIONS & ATTRIBUTION ───
console.log('\n[Test 6] Wicket celebrations and bowler attribution');
{
  const match: TestMatch = { id: 'm1', isFirstInnings: true, status: 'Live', winnerName: '', resultText: '', celebratedMilestones: [] };
  const striker: TestBatsman = { id: 'p4', name: 'Shreyas Iyer', runsScored: 24, ballsFaced: 18 };
  const bowler: TestBowler = { id: 'bw2', name: 'Jasprit Bumrah', wicketsTaken: 2, runsConceded: 16, oversBowled: 3.0 };
  const batTeam = { name: 'Kolkata', shortName: 'KKR', logoColorHex: '0xFF078B70' };

  // Bowled dismissal -> Bowler credited
  const bowledEvent = processBallScore({
    match,
    striker,
    bowler,
    runs: 0,
    extraType: 'None',
    isWicket: true,
    wicketType: 'Bowled',
    batTeam,
  });
  assert(bowledEvent !== null);
  assert.strictEqual(bowledEvent.type, 'WICKET');
  assert.strictEqual(bowledEvent.bowlerName, 'Jasprit Bumrah');
  assert.strictEqual(bowledEvent.dismissalType, 'Bowled');
  console.log('✅ Passed: Bowled dismissal correctly credited bowler.');

  // Run Out dismissal -> Bowler NOT credited
  const runOutStriker: TestBatsman = { id: 'p5', name: 'Andre Russell', runsScored: 8, ballsFaced: 4 };
  const runOutEvent = processBallScore({
    match,
    striker: runOutStriker,
    bowler,
    runs: 0,
    extraType: 'None',
    isWicket: true,
    wicketType: 'Run Out',
    batTeam,
  });
  assert(runOutEvent !== null);
  assert.strictEqual(runOutEvent.type, 'WICKET');
  assert.strictEqual(runOutEvent.bowlerName, '', 'Run Out must NOT credit bowler');
  assert.strictEqual(runOutEvent.dismissalType, 'Run Out');
  console.log('✅ Passed: Run Out dismissal correctly omitted bowler attribution.');
}

// ─── TEST 7: FIVE-WICKET HAUL CELEBRATION ───
console.log('\n[Test 7] Five-Wicket haul celebration trigger');
{
  const match: TestMatch = { id: 'm1', isFirstInnings: true, status: 'Live', winnerName: '', resultText: '', celebratedMilestones: [] };
  const striker: TestBatsman = { id: 'p6', name: 'Batter Six', runsScored: 10, ballsFaced: 12 };
  const bowler: TestBowler = { id: 'bw3', name: 'Mohammed Shami', wicketsTaken: 4, runsConceded: 22, oversBowled: 3.4 };
  const batTeam = { name: 'Team Bat', shortName: 'TB', logoColorHex: '0xFF078B70' };
  const bowlTeam = { name: 'Team Bowl', shortName: 'TBL', logoColorHex: '0xFF064E3B' };

  // 4th to 5th credited wicket
  const event = processBallScore({
    match,
    striker,
    bowler,
    runs: 0,
    extraType: 'None',
    isWicket: true,
    wicketType: 'Caught',
    batTeam,
    bowlTeam,
  });
  assert(event !== null);
  assert.strictEqual(event.type, 'FIVE_WICKET');
  assert.strictEqual(event.bowlerName, 'Mohammed Shami');
  assert.strictEqual(event.bowlerWickets, 5);
  assert(match.celebratedMilestones.includes('1_bw3_5w'));
  console.log('✅ Passed: Bowler 5th credited wicket triggered FIVE_WICKET haul.');

  // Run out does NOT trigger 5-wicket haul
  const bowler4W: TestBowler = { id: 'bw4', name: 'Bowler 4W', wicketsTaken: 4, runsConceded: 20, oversBowled: 3.0 };
  const runOutEvent = processBallScore({
    match,
    striker,
    bowler: bowler4W,
    runs: 0,
    extraType: 'None',
    isWicket: true,
    wicketType: 'Run Out',
    batTeam,
    bowlTeam,
  });
  assert(runOutEvent !== null);
  assert.strictEqual(runOutEvent.type, 'WICKET'); // Plain wicket, not 5W!
  assert(!match.celebratedMilestones.includes('1_bw4_5w'));
  console.log('✅ Passed: Run Out did NOT count towards 5-wicket haul.');
}

// ─── TEST 8: MATCH-WINNING CELEBRATION ───
console.log('\n[Test 8] Match-Winning celebration trigger');
{
  const match: TestMatch = {
    id: 'm1',
    isFirstInnings: false,
    status: 'Completed',
    winnerName: 'India',
    resultText: 'India won by 6 wickets',
    celebratedMilestones: [],
  };
  const striker: TestBatsman = { id: 'p7', name: 'Winning Batter', runsScored: 34, ballsFaced: 20 };
  const batTeam = { name: 'India', shortName: 'IND', logoColorHex: '0xFF078B70' };

  const event = processBallScore({
    match,
    striker,
    runs: 4,
    extraType: 'None',
    batTeam,
  });
  assert(event !== null);
  assert.strictEqual(event.type, 'MATCH_WON');
  assert.strictEqual(event.winnerTeamName, 'India');
  assert.strictEqual(event.resultText, 'India won by 6 wickets');
  console.log('✅ Passed: Completed match triggered MATCH_WON celebration.');

  // Second check should not duplicate
  const nextEvent = processBallScore({ match, striker, runs: 1, extraType: 'None', batTeam });
  assert(nextEvent === null, 'Match completion must trigger once per client');
  console.log('✅ Passed: Match completion did not duplicate celebration.');
}

// ─── TEST 9: SCORE UNDO AND ROLLBACK ───
console.log('\n[Test 9] Undo safely rolls back milestones and allows legitimate re-triggering');
{
  const match: TestMatch = { id: 'm1', isFirstInnings: true, status: 'Live', winnerName: '', resultText: '', celebratedMilestones: [] };
  const striker: TestBatsman = { id: 'p1', name: 'Virat Kohli', runsScored: 49, ballsFaced: 32 };
  const batTeam = { name: 'Royal Challengers', shortName: 'RCB', logoColorHex: '0xFF078B70' };

  processBallScore({ match, striker, runs: 1, extraType: 'None', batTeam });
  assert(match.celebratedMilestones.includes('1_p1_50'));

  // Undo ball
  processUndo({ match, striker, runsUndone: 1, extraType: 'None' });
  assert.strictEqual(striker.runsScored, 49);
  assert(!match.celebratedMilestones.includes('1_p1_50'), 'Milestone key must be removed on undo');
  console.log('✅ Passed: Undo rolled back milestone key.');

  // Re-scoring 1 run should trigger celebration again
  const reEvent = processBallScore({ match, striker, runs: 1, extraType: 'None', batTeam });
  assert(reEvent !== null);
  assert.strictEqual(reEvent.type, '50');
  console.log('✅ Passed: Re-scoring legitimately re-triggered Half Century celebration.');
}

console.log('\n======================================================');
console.log('🎉 ALL 9 CRICKET CELEBRATION LOGIC TESTS PASSED (9/9) 🎉');
console.log('======================================================\n');
