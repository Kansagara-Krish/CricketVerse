import { Request, Response } from 'express';
import { MatchModel } from '../models/Match';
import { TeamModel } from '../models/Team';
import { redis, invalidateCachedMatch, setCachedMatch } from '../config/redis';
import { broadcastMatchUpdate, broadcastNotification, broadcastMilestoneCelebration } from '../sockets/socketHandler';

export function getMaxOvers(matchType: string): number {
  if (!matchType) return 20;
  const mt = matchType.toUpperCase().trim();
  if (mt.includes('T10') || mt.includes('10 OVER') || mt === '10') return 10;
  if (mt.includes('T20') || mt.includes('20 OVER') || mt === '20') return 20;
  if (mt.includes('ODI') || mt.includes('50 OVER') || mt === '50' || mt.includes('ONE DAY')) return 50;
  if (mt.includes('TEST')) return 90;
  const match = mt.match(/(\d+)\s*(?:OVER|OVERS)?/);
  if (match) return parseInt(match[1], 10);
  return 20;
}

function incrementOvers(currentOvers: number, ballsAdded: number): number {
  if (ballsAdded === 0) return currentOvers;
  let oversInt = Math.floor(currentOvers);
  let ballsInt = Math.round((currentOvers - oversInt) * 10);

  ballsInt += ballsAdded;
  if (ballsInt >= 6) {
    oversInt += Math.floor(ballsInt / 6);
    ballsInt = ballsInt % 6;
  }
  return parseFloat((oversInt + ballsInt / 10.0).toFixed(1));
}

function decrementOvers(currentOvers: number, ballsRemoved: number): number {
  if (ballsRemoved === 0) return currentOvers;
  let oversInt = Math.floor(currentOvers);
  let ballsInt = Math.round((currentOvers - oversInt) * 10);

  ballsInt -= ballsRemoved;
  if (ballsInt < 0) {
    const oversNeeded = Math.ceil(Math.abs(ballsInt) / 6);
    oversInt -= oversNeeded;
    ballsInt = (ballsInt + oversNeeded * 6) % 6;
    if (oversInt < 0) {
      oversInt = 0;
      ballsInt = 0;
    }
  }
  return parseFloat((oversInt + ballsInt / 10.0).toFixed(1));
}

export const FORBIDDEN_FIELD_TERMS = [
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

export function sanitizeCricketCommentary(text: string): string {
  if (!text) return '';
  let sanitized = text;
  for (const term of FORBIDDEN_FIELD_TERMS) {
    const regex = new RegExp(`\\b${term.replace('-', '[- ]')}\\b`, 'gi');
    sanitized = sanitized.replace(regex, 'the boundary');
  }
  return sanitized.replace(/\s+/g, ' ').trim();
}

export function generateAICommentary(
  param1: any,
  bowlerArg?: string,
  runsArg?: number,
  extraTypeArg?: string,
  isWicketArg?: boolean,
  wicketTypeArg?: string,
  oversArg?: number,
  totalRunsArg?: number,
  totalWicketsArg?: number
): string {
  let batsman: string;
  let bowler: string;
  let runs: number;
  let extraType: string;
  let isWicket: boolean;
  let wicketType: string;
  let dismissedBatsman: string | undefined;
  let incomingBatsman: string | undefined;
  let totalRuns: number | undefined;
  let totalWickets: number | undefined;

  if (typeof param1 === 'object' && param1 !== null) {
    batsman = param1.batsman || 'Batsman';
    bowler = param1.bowler || 'Bowler';
    runs = Number(param1.runs) || 0;
    extraType = param1.extraType || 'None';
    isWicket = Boolean(param1.isWicket);
    wicketType = param1.wicketType || 'None';
    dismissedBatsman = param1.dismissedBatsman;
    incomingBatsman = param1.incomingBatsman;
    totalRuns = param1.totalRuns;
    totalWickets = param1.totalWickets;
  } else {
    batsman = String(param1 || 'Batsman');
    bowler = String(bowlerArg || 'Bowler');
    runs = Number(runsArg) || 0;
    extraType = String(extraTypeArg || 'None');
    isWicket = Boolean(isWicketArg);
    wicketType = String(wicketTypeArg || 'None');
    totalRuns = totalRunsArg;
    totalWickets = totalWicketsArg;
  }

  const selectRandom = (arr: string[]) => arr[Math.floor(Math.random() * arr.length)];
  const scoreText = totalRuns !== undefined && totalWickets !== undefined ? ` Score: ${totalRuns}/${totalWickets}.` : '';

  let comm = '';

  if (isWicket) {
    const outPlayer = dismissedBatsman || batsman;
    const inPlayer = incomingBatsman ? ` ${incomingBatsman} walks out to the crease.` : '';

    if (wicketType === 'Bowled') {
      comm = selectRandom([
        `BOWLED HIM! Clean through the defense! ${bowler} knocks back middle stump! ${outPlayer} departs.${inPlayer}${scoreText}`,
        `TIMBERRR! Absolute jaffa from ${bowler}! Shatters the stumps, sending bails flying! ${outPlayer} is out.${inPlayer}${scoreText}`,
      ]);
    } else if (wicketType === 'Caught') {
      comm = selectRandom([
        `CAUGHT! In the air... and safely pouched! ${outPlayer} tries to clear the rope off ${bowler}, but is caught!${inPlayer}${scoreText}`,
        `WHAT A CATCH! A stunning diving grab off ${bowler}! ${outPlayer} has to walk back!${inPlayer}${scoreText}`,
      ]);
    } else if (wicketType === 'LBW') {
      comm = selectRandom([
        `LBW! Huge shout from ${bowler}, and the umpire's finger goes straight up! ${outPlayer} trapped in front!${inPlayer}${scoreText}`,
        `DEAD PLUMB! ${bowler} strikes the front pad directly in line! ${outPlayer} is dismissed LBW!${inPlayer}${scoreText}`,
      ]);
    } else if (wicketType === 'Run Out') {
      comm = selectRandom([
        `RUN OUT! DIRECT HIT! Sharp throw to the stumps and ${outPlayer} is caught well short of the crease!${inPlayer}${scoreText}`,
        `DISASTER RUN OUT! Fatal mix-up between the wickets, bails whipped off and ${outPlayer} is gone!${inPlayer}${scoreText}`,
      ]);
    } else {
      comm = selectRandom([
        `OUT! ${bowler} strikes with a ripper! Crucial wicket of ${outPlayer}!${inPlayer}${scoreText}`,
        `WICKET! Breakthrough delivery from ${bowler}! ${outPlayer} departs!${inPlayer}${scoreText}`,
      ]);
    }
  } else if (extraType === 'Wide') {
    comm = `Wide ball! ${bowler} strays too far, ${batsman} leaves it alone. Extra run added.${scoreText}`;
  } else if (extraType === 'No Ball') {
    comm = `No Ball! ${bowler} oversteps the bowling crease. An extra run and a Free Hit for ${batsman}!${scoreText}`;
  } else if (runs === 6) {
    comm = selectRandom([
      `SIX! MASSIVE HIT! ${batsman} launches ${bowler} deep into the crowd!${scoreText}`,
      `MAXIMUM! Sweet timing from ${batsman}! Dispatched cleanly over the rope for SIX!${scoreText}`,
      `SIX MORE! ${batsman} stands tall and smokes ${bowler} all the way!${scoreText}`,
      `BOOM! Pure power from ${batsman}! High, handsome and into the stands for SIX!${scoreText}`,
    ]);
  } else if (runs === 4) {
    comm = selectRandom([
      `FOUR! Glorious stroke from ${batsman}! Pierces the infield and races to the boundary!${scoreText}`,
      `CRACKING BOUNDARY! Fast hands from ${batsman}, drilling ${bowler} to the fence!${scoreText}`,
      `FOUR RUNS! Pure elegance from ${batsman}, finding the gap with perfection!${scoreText}`,
      `DELICIOUS TIMING! ${batsman} times ${bowler} exquisitely and it flashes away to the boundary!${scoreText}`,
    ]);
  } else if (runs === 0) {
    comm = selectRandom([
      `Dot ball. Good length delivery from ${bowler}, safely defended by ${batsman}.`,
      `Dot ball. ${batsman} plays with soft hands back towards ${bowler}.`,
      `Well bowled! ${bowler} beats the bat of ${batsman} with a beauty!`,
      `Fiery bouncer from ${bowler}! ${batsman} ducks under it cleanly.`,
    ]);
  } else if (runs === 1) {
    comm = selectRandom([
      `Single taken. ${batsman} pushes ${bowler} into the gap to rotate the strike.${scoreText}`,
      `Quick single! Sharp call from ${batsman} and they scamper through safely.${scoreText}`,
      `Worked away neatly by ${batsman} for a comfortable single.${scoreText}`,
    ]);
  } else if (runs === 2) {
    comm = `Two runs! Nicely placed by ${batsman}, great hustling between the wickets to complete two.${scoreText}`;
  } else {
    comm = `${runs} runs scored. Terrific running between the wickets by ${batsman}.${scoreText}`;
  }

  return sanitizeCricketCommentary(comm);
}

export function computeMatchResult(match: any) {
  if (match.status === 'Abandoned') {
    match.winnerTeamId = '';
    match.winnerName = 'No Result';
    match.resultText = 'Match Abandoned';
    match.resultCommentary = 'The match has been abandoned. No result.';
    return;
  }

  const tossWinnerStr = String(match.tossWinner || '').trim().toLowerCase();
  const teamAIdStr = String(match.teamAId || match.teamA?.id || '').trim().toLowerCase();
  const teamANameStr = String(match.teamA?.name || '').trim().toLowerCase();
  const teamAShortStr = String(match.teamA?.shortName || '').trim().toLowerCase();

  const isTossWinnerTeamA =
    tossWinnerStr.length > 0 &&
    (tossWinnerStr === teamAIdStr ||
      tossWinnerStr === teamANameStr ||
      tossWinnerStr === teamAShortStr);

  let isTeamAFirst: boolean;
  if (match.tossWinner && match.tossDecision) {
    const isBattingDecision = String(match.tossDecision).trim().toLowerCase() === 'bat';
    isTeamAFirst = isBattingDecision ? isTossWinnerTeamA : !isTossWinnerTeamA;
  } else {
    isTeamAFirst = match.isFirstInnings
      ? match.battingTeamId === match.teamAId
      : match.battingTeamId !== match.teamAId;
  }

  const firstBatTeamId = isTeamAFirst ? match.teamAId : match.teamBId;
  const secondBatTeamId = isTeamAFirst ? match.teamBId : match.teamAId;

  const firstBatTeamName = isTeamAFirst ? (match.teamA?.name || 'Team A') : (match.teamB?.name || 'Team B');
  const secondBatTeamName = isTeamAFirst ? (match.teamB?.name || 'Team B') : (match.teamA?.name || 'Team A');

  const firstRuns = isTeamAFirst ? Number(match.runsA || 0) : Number(match.runsB || 0);
  const secondRuns = isTeamAFirst ? Number(match.runsB || 0) : Number(match.runsA || 0);

  const firstWickets = isTeamAFirst ? Number(match.wicketsA || 0) : Number(match.wicketsB || 0);
  const secondWickets = isTeamAFirst ? Number(match.wicketsB || 0) : Number(match.wicketsA || 0);

  // In cricket, an innings has at most 10 wickets lost
  const wicketsInHand = Math.max(1, 10 - secondWickets);

  if (secondRuns > firstRuns) {
    match.winnerTeamId = secondBatTeamId;
    match.winnerName = secondBatTeamName;
    match.resultText = `${secondBatTeamName} won by ${wicketsInHand} wicket${wicketsInHand === 1 ? '' : 's'}`;
    match.resultCommentary = `${secondBatTeamName.toUpperCase()} WIN! ${secondBatTeamName} defeated ${firstBatTeamName} by ${wicketsInHand} wicket${wicketsInHand === 1 ? '' : 's'} (${secondRuns}/${secondWickets} vs ${firstRuns}/${firstWickets}). What a thrilling chase!`;
  } else if (firstRuns > secondRuns) {
    const margin = firstRuns - secondRuns;
    match.winnerTeamId = firstBatTeamId;
    match.winnerName = firstBatTeamName;
    match.resultText = `${firstBatTeamName} won by ${margin} run${margin === 1 ? '' : 's'}`;
    match.resultCommentary = `${firstBatTeamName.toUpperCase()} WIN! ${firstBatTeamName} defeated ${secondBatTeamName} by ${margin} run${margin === 1 ? '' : 's'} (${firstRuns}/${firstWickets} vs ${secondRuns}/${secondWickets}). Outstanding victory!`;
  } else {
    match.winnerTeamId = '';
    match.winnerName = 'Tie';
    match.resultText = 'Match Tied!';
    match.resultCommentary = `WHAT A THRILLER! The match ends in a tie! Both sides finished level: ${firstBatTeamName} (${firstRuns}/${firstWickets}) vs ${secondBatTeamName} (${secondRuns}/${secondWickets})!`;
  }

  // Append result ball if not present
  if (match.balls && Array.isArray(match.balls) && match.balls.length > 0) {
    const hasResultBall = match.balls.some(
      (b: any) => b.batsmanName === 'Match Result' || (b.commentary && b.commentary.includes('WIN!'))
    );
    if (!hasResultBall) {
      match.balls.push({
        run: 0,
        extraRun: 0,
        extraType: 'None',
        isWicket: false,
        wicketType: 'None',
        batsmanName: 'Match Result',
        bowlerName: '',
        commentary: match.resultCommentary,
        timestamp: new Date().toISOString(),
      });
    }
  }
}

export async function startMatchSetup(req: Request, res: Response) {
  const { matchId } = req.params;
  const { tossWinner, tossDecision, firstBattingTeamId } = req.body;

  if (!tossWinner || !tossDecision || !firstBattingTeamId) {
    return res.status(400).json({ error: 'Toss winner, decision, and batting team are required.' });
  }

  try {
    const match = await MatchModel.findOne({ id: matchId });
    if (!match) {
      return res.status(404).json({ error: 'Match not found.' });
    }

    const isTeamAFirst = firstBattingTeamId === match.teamAId;
    const batTeamPlayers = isTeamAFirst ? match.playingXI_A : match.playingXI_B;
    const bowlTeamPlayers = isTeamAFirst ? match.playingXI_B : match.playingXI_A;

    // Reset player out flags
    match.playingXI_A.forEach((p: any) => { p.isOut = false; p.dismissalInfo = ''; });
    match.playingXI_B.forEach((p: any) => { p.isOut = false; p.dismissalInfo = ''; });
    if (match.teamA?.players) match.teamA.players.forEach((p: any) => { p.isOut = false; p.dismissalInfo = ''; });
    if (match.teamB?.players) match.teamB.players.forEach((p: any) => { p.isOut = false; p.dismissalInfo = ''; });

    const strikerId = batTeamPlayers.length > 0 ? batTeamPlayers[0].id : '';
    const nonStrikerId = batTeamPlayers.length > 1 ? batTeamPlayers[1].id : '';
    const bowlerId = bowlTeamPlayers.length > 0 ? bowlTeamPlayers[bowlTeamPlayers.length - 1].id : '';

    match.status = 'Live';
    match.tossWinner = tossWinner;
    match.tossDecision = tossDecision;
    match.battingTeamId = firstBattingTeamId;
    match.isFirstInnings = true;
    match.target = 0;
    match.winnerTeamId = '';
    match.winnerName = '';
    match.resultText = '';
    match.currentStrikerId = strikerId;
    match.currentNonStrikerId = nonStrikerId;
    match.currentBowlerId = bowlerId;

    await match.save();
    await invalidateCachedMatch(matchId);

    const updated = match.toJSON();
    broadcastMatchUpdate(matchId, 'match_update', updated);

    try {
      const tossDecisionText = tossDecision === 'Bat' ? 'batting' : 'bowling';
      broadcastNotification({
        title: 'Match Started! 🏏',
        message: `${tossWinner} won the toss and chose ${tossDecisionText}. ${match.teamA?.name} vs ${match.teamB?.name} is now LIVE!`,
        timestamp: new Date().toISOString(),
      });
    } catch (broadcastErr) {
      console.error('Error broadcasting start match notification:', broadcastErr);
    }

    return res.status(200).json(updated);
  } catch (err) {
    console.error('Error starting match setup:', err);
    return res.status(500).json({ error: 'Internal server error.' });
  }
}

// In-memory idempotency store with TTL cleanup
interface IdempotencyRecord {
  status: 'in-flight' | 'completed';
  response?: any;
  timestamp: number;
}

const idempotencyStore = new Map<string, IdempotencyRecord>();

// Periodically clean up idempotency keys older than 10 minutes
setInterval(() => {
  const now = Date.now();
  for (const [key, record] of idempotencyStore.entries()) {
    if (now - record.timestamp > 600000) {
      idempotencyStore.delete(key);
    }
  }
}, 300000);

export async function updateScore(req: Request, res: Response) {
  const { matchId } = req.params;
  const { runs, extraType, extraRuns, isWicket, wicketType, dismissedPlayerId, newBatsmanId, newBatsmanPosition } = req.body;
  const idempotencyKey = ((req.headers['x-idempotency-key'] as string) || req.body?.idempotencyKey || '').trim();

  if (idempotencyKey) {
    const existing = idempotencyStore.get(idempotencyKey);
    if (existing) {
      if (existing.status === 'in-flight') {
        return res.status(409).json({ error: 'Duplicate scoring delivery is currently processing.' });
      }
      if (existing.status === 'completed' && existing.response) {
        return res.status(200).json(existing.response);
      }
    }
    idempotencyStore.set(idempotencyKey, { status: 'in-flight', timestamp: Date.now() });

    if (redis) {
      try {
        const cached = await redis.get(`idempotency:${idempotencyKey}`);
        if (cached) {
          return res.status(200).json(JSON.parse(cached));
        }
      } catch (_) {}
    }
  }

  try {
    const match = await MatchModel.findOne({ id: matchId });
    if (!match) {
      if (idempotencyKey) idempotencyStore.delete(idempotencyKey);
      return res.status(404).json({ error: 'Match not found.' });
    }

    if (match.status === 'Completed') {
      if (idempotencyKey) idempotencyStore.delete(idempotencyKey);
      return res.status(400).json({ error: 'Match is already completed.' });
    }

    const isTeamABatting = match.battingTeamId === match.teamAId;
    const batTeamPlayers = isTeamABatting ? match.playingXI_A : match.playingXI_B;
    const bowlTeamPlayers = isTeamABatting ? match.playingXI_B : match.playingXI_A;
    const batTeam = isTeamABatting ? match.teamA : match.teamB;
    const bowlTeam = isTeamABatting ? match.teamB : match.teamA;

    const currentStrikerId = match.currentStrikerId;
    const currentNonStrikerId = match.currentNonStrikerId;
    const currentBowlerId = match.currentBowlerId;

    const striker = batTeamPlayers.find((p: any) => p.id === currentStrikerId);
    const bowler = bowlTeamPlayers.find((p: any) => p.id === currentBowlerId);

    const batsmanName = striker ? striker.name : 'Striker';
    const bowlerName = bowler ? bowler.name : 'Bowler';

    const runsNum = Number(runs) || 0;
    const extraRunsNum = Number(extraRuns) || 0;
    const totalRunsThisBall = runsNum + extraRunsNum;

    const isLegalBall = extraType !== 'Wide' && extraType !== 'No Ball';
    const ballVal = isLegalBall ? 1 : 0;

    // 1. Team Score & Over Increment
    const isWicketFell = Boolean(isWicket && wicketType !== 'Retired Hurt');

    if (isTeamABatting) {
      match.runsA += totalRunsThisBall;
      if (isWicketFell) match.wicketsA += 1;
      match.oversA = incrementOvers(match.oversA, ballVal);
    } else {
      match.runsB += totalRunsThisBall;
      if (isWicketFell) match.wicketsB += 1;
      match.oversB = incrementOvers(match.oversB, ballVal);
    }

    // 2. Batsman Stats Update
    const prevStrikerRuns = striker ? Number(striker.runsScored || 0) : 0;
    if (striker) {
      if (extraType === 'None' || extraType === 'No Ball') {
        striker.runsScored = (striker.runsScored || 0) + runsNum;
      }
      if (extraType !== 'Wide') {
        striker.ballsFaced = (striker.ballsFaced || 0) + 1;
      }
    }
    const newStrikerRuns = striker ? Number(striker.runsScored || 0) : 0;

    // Milestone Detection (50 runs / 100 runs)
    const currentInnings = match.isFirstInnings ? 1 : 2;
    match.celebratedMilestones = match.celebratedMilestones || [];
    let detectedMilestone: any = null;

    if (striker && (extraType === 'None' || extraType === 'No Ball') && runsNum > 0) {
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
          teamName: batTeam?.name || 'Batting Team',
          teamShortName: batTeam?.shortName || '',
          teamColorHex: batTeam?.logoColorHex || '0xFF078B70',
          innings: currentInnings,
          timestamp: new Date().toISOString(),
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
          teamName: batTeam?.name || 'Batting Team',
          teamShortName: batTeam?.shortName || '',
          teamColorHex: batTeam?.logoColorHex || '0xFF078B70',
          innings: currentInnings,
          timestamp: new Date().toISOString(),
        };
      }
    }

    if (detectedMilestone) {
      console.log(`[MILESTONE_DEBUG] Backend updateScore: milestone detected! Match=${match.id}, Batsman=${striker?.name} (${striker?.id}), Runs=${prevStrikerRuns} -> ${newStrikerRuns}, Type=${detectedMilestone.type}`);
    }

    // 3. Bowler Stats Update
    if (bowler) {
      if (extraType === 'None' || extraType === 'Wide' || extraType === 'No Ball') {
        bowler.runsConceded = (bowler.runsConceded || 0) + totalRunsThisBall;
      }
      if (isWicket && !['Run Out', 'Retired Out', 'Retired Hurt', 'Timed Out', 'Obstructing Field'].includes(wicketType)) {
        bowler.wicketsTaken = (bowler.wicketsTaken || 0) + 1;
      }
      if (isLegalBall) {
        bowler.oversBowled = incrementOvers(Number(bowler.oversBowled || 0), 1);
      }
    }

    // 4. Record dismissal on the dismissed player
    const actualDismissedId = dismissedPlayerId || (isWicket ? currentStrikerId : null);
    if (isWicket && actualDismissedId) {
      const dismissedPlayer = batTeamPlayers.find((p: any) => p.id === actualDismissedId);
      if (dismissedPlayer) {
        dismissedPlayer.isOut = true;
        dismissedPlayer.dismissalInfo = `${wicketType || 'Out'} b ${bowlerName}`;
      }
    }

    // Sync stats into teamA and teamB player arrays
    const syncPlayers = (targetList: any[], sourcePlayer: any) => {
      if (!Array.isArray(targetList) || !sourcePlayer) return;
      const idx = targetList.findIndex((p: any) => p.id === sourcePlayer.id);
      if (idx !== -1) targetList[idx] = { ...targetList[idx], ...sourcePlayer };
    };

    if (striker) {
      syncPlayers(match.teamA?.players, striker);
      syncPlayers(match.teamB?.players, striker);
    }
    if (bowler) {
      syncPlayers(match.teamA?.players, bowler);
      syncPlayers(match.teamB?.players, bowler);
    }
    if (actualDismissedId) {
      const dismissedPlayer = batTeamPlayers.find((p: any) => p.id === actualDismissedId);
      if (dismissedPlayer) {
        syncPlayers(match.teamA?.players, dismissedPlayer);
        syncPlayers(match.teamB?.players, dismissedPlayer);
      }
    }

    const currentBattingOvers = isTeamABatting ? match.oversA : match.oversB;
    const currentBattingRuns = isTeamABatting ? match.runsA : match.runsB;
    const currentBattingWickets = isTeamABatting ? match.wicketsA : match.wicketsB;

    const commentary = generateAICommentary(
      batsmanName,
      bowlerName,
      runsNum,
      extraType || 'None',
      isWicket || false,
      wicketType || 'None',
      currentBattingOvers,
      currentBattingRuns,
      currentBattingWickets
    );

    match.balls.push({
      run: runsNum,
      extraRun: extraRunsNum,
      extraType: extraType || 'None',
      isWicket: Boolean(isWicket),
      wicketType: wicketType || 'None',
      batsmanName,
      bowlerName,
      commentary,
      timestamp: new Date().toISOString(),
      strikerId: currentStrikerId,
      nonStrikerId: currentNonStrikerId,
      bowlerId: currentBowlerId,
      innings: match.isFirstInnings ? 1 : 2,
      battingTeamId: match.battingTeamId,
      over: currentBattingOvers,
    });

    // 5. Strike Rotation Logic
    let shouldSwapStrike = false;
    if (extraType === 'None' && runsNum % 2 !== 0) shouldSwapStrike = true;
    else if ((extraType === 'Bye' || extraType === 'Leg Bye') && totalRunsThisBall % 2 !== 0) shouldSwapStrike = true;
    else if (extraType === 'No Ball' && runsNum % 2 !== 0) shouldSwapStrike = true;
    else if (extraType === 'Wide' && runsNum % 2 !== 0) shouldSwapStrike = true;

    // Check if over ended on this ball
    const overBalls = Math.round((currentBattingOvers - Math.floor(currentBattingOvers)) * 10);
    const overCompleted = isLegalBall && overBalls === 0 && currentBattingOvers > 0;
    if (overCompleted) {
      shouldSwapStrike = !shouldSwapStrike;
    }

    let finalStrikerId = currentStrikerId;
    let finalNonStrikerId = currentNonStrikerId;

    if (shouldSwapStrike) {
      finalStrikerId = currentNonStrikerId;
      finalNonStrikerId = currentStrikerId;
    }

    // 6. Handle Wicket & Incoming Batsman
    const maxWickets = Math.max(1, batTeamPlayers.length - 1);
    const isTeamAllOut = currentBattingWickets >= maxWickets;

    if (isWicket && !isTeamAllOut) {
      const partnerId = actualDismissedId === currentStrikerId ? currentNonStrikerId : currentStrikerId;

      if (newBatsmanId) {
        const candidate = batTeamPlayers.find((p: any) => p.id === newBatsmanId && !p.isOut);
        if (candidate) {
          if (newBatsmanPosition === 'Striker') {
            finalStrikerId = newBatsmanId;
            finalNonStrikerId = partnerId;
          } else {
            finalStrikerId = partnerId;
            finalNonStrikerId = newBatsmanId;
          }
        }
      } else {
        // Find next player who is NOT out and NOT currently partner
        const available = batTeamPlayers.filter((p: any) => !p.isOut && p.id !== partnerId && p.id !== actualDismissedId);
        if (available.length > 0) {
          const nextPlayerId = available[0].id;
          if (actualDismissedId === currentNonStrikerId) {
            finalNonStrikerId = nextPlayerId;
          } else {
            finalStrikerId = nextPlayerId;
          }
        }
      }
    }

    match.currentStrikerId = finalStrikerId;
    match.currentNonStrikerId = finalNonStrikerId;

    // 7. Innings & Match Completion Verification
    const maxOversLimit = getMaxOvers(match.matchType);
    const isOversCompleted = currentBattingOvers >= maxOversLimit;

    if (match.isFirstInnings) {
      // Check if 1st Innings is OVER (All out OR Max Overs reached)
      if (isTeamAllOut || isOversCompleted) {
        const nextBatTeamId = isTeamABatting ? match.teamBId : match.teamAId;
        const nextBatPlayers = isTeamABatting ? match.playingXI_B : match.playingXI_A;
        const nextBowlPlayers = isTeamABatting ? match.playingXI_A : match.playingXI_B;

        match.isFirstInnings = false;
        match.battingTeamId = nextBatTeamId;
        match.target = currentBattingRuns + 1;

        // Reset incoming batsmen and bowler for 2nd innings
        const unbatted = nextBatPlayers.filter((p: any) => !p.isOut);
        match.currentStrikerId = unbatted.length > 0 ? unbatted[0].id : (nextBatPlayers[0]?.id || '');
        match.currentNonStrikerId = unbatted.length > 1 ? unbatted[1].id : (nextBatPlayers[1]?.id || '');
        match.currentBowlerId = nextBowlPlayers.length > 0 ? nextBowlPlayers[nextBowlPlayers.length - 1].id : '';

        try {
          const nextBatTeamName = isTeamABatting ? match.teamB?.name : match.teamA?.name;
          const currentBatTeamName = batTeam?.name || 'Batting Team';
          broadcastNotification({
            title: 'Innings Break! 🏏',
            message: `${currentBatTeamName} finished with ${currentBattingRuns}/${currentBattingWickets} in ${currentBattingOvers} ov. ${nextBatTeamName} needs ${match.target} runs to win!`,
            timestamp: new Date().toISOString(),
          });
        } catch (_) {}
      }
    } else {
      // 2nd Innings Check:
      // A. Target chased down
      // B. All out
      // C. Max overs reached
      const isTargetChased = match.target > 0 && currentBattingRuns >= match.target;

      if (isTargetChased || isTeamAllOut || isOversCompleted) {
        match.status = 'Completed';
        computeMatchResult(match);

        try {
          broadcastNotification({
            title: '🏆 Match Completed!',
            message: `${match.teamA?.name} vs ${match.teamB?.name}: ${match.resultText}`,
            timestamp: new Date().toISOString(),
          });
        } catch (_) {}
      }
    }

    match.markModified('playingXI_A');
    match.markModified('playingXI_B');
    match.markModified('teamA');
    match.teamB && match.markModified('teamB');
    match.markModified('balls');
    match.markModified('celebratedMilestones');
    await match.save();

    await invalidateCachedMatch(matchId);
    const updated = match.toJSON();
    if (detectedMilestone) {
      updated.latestMilestone = detectedMilestone;
    }
    broadcastMatchUpdate(matchId, 'match_update', updated);
    if (detectedMilestone) {
      broadcastMilestoneCelebration(matchId, detectedMilestone);
    }

    if (idempotencyKey) {
      idempotencyStore.set(idempotencyKey, { status: 'completed', response: updated, timestamp: Date.now() });
      if (redis) {
        try {
          await redis.set(`idempotency:${idempotencyKey}`, JSON.stringify(updated), 'EX', 600);
        } catch (_) {}
      }
    }

    return res.status(200).json(updated);
  } catch (err) {
    if (idempotencyKey) {
      idempotencyStore.delete(idempotencyKey);
    }
    console.error('Error updating score:', err);
    return res.status(500).json({ error: 'Internal server error.' });
  }
}

export async function undoLastBall(req: Request, res: Response) {
  const { matchId } = req.params;
  const idempotencyKey = ((req.headers['x-idempotency-key'] as string) || req.body?.idempotencyKey || '').trim();

  if (idempotencyKey) {
    const existing = idempotencyStore.get(idempotencyKey);
    if (existing) {
      if (existing.status === 'in-flight') {
        return res.status(409).json({ error: 'Duplicate undo request is currently processing.' });
      }
      if (existing.status === 'completed' && existing.response) {
        return res.status(200).json(existing.response);
      }
    }
    idempotencyStore.set(idempotencyKey, { status: 'in-flight', timestamp: Date.now() });
  }

  try {
    const match = await MatchModel.findOne({ id: matchId });
    if (!match) {
      if (idempotencyKey) idempotencyStore.delete(idempotencyKey);
      return res.status(404).json({ error: 'Match not found.' });
    }

    if (!match.balls || match.balls.length === 0) {
      if (idempotencyKey) idempotencyStore.delete(idempotencyKey);
      return res.status(400).json({ error: 'No balls to undo.' });
    }

    const lastBall = match.balls.pop()!;
    const runsNum = Number(lastBall.run) || 0;
    const extraRunsNum = Number(lastBall.extraRun) || 0;
    const totalRunsThisBall = runsNum + extraRunsNum;

    const isLegalBall = lastBall.extraType !== 'Wide' && lastBall.extraType !== 'No Ball';
    const ballVal = isLegalBall ? 1 : 0;

    const isTeamABatting = match.battingTeamId === match.teamAId;

    if (isTeamABatting) {
      match.runsA = Math.max(0, match.runsA - totalRunsThisBall);
      if (lastBall.isWicket && lastBall.wicketType !== 'Retired Hurt') {
        match.wicketsA = Math.max(0, match.wicketsA - 1);
      }
      match.oversA = decrementOvers(match.oversA, ballVal);
    } else {
      match.runsB = Math.max(0, match.runsB - totalRunsThisBall);
      if (lastBall.isWicket && lastBall.wicketType !== 'Retired Hurt') {
        match.wicketsB = Math.max(0, match.wicketsB - 1);
      }
      match.oversB = decrementOvers(match.oversB, ballVal);
    }

    if (match.status === 'Completed') {
      match.status = 'Live';
      match.winnerTeamId = '';
      match.winnerName = '';
      match.resultText = '';
    }

    // Helper to revert batsman stats on player arrays
    const revertStrikerStats = (playersArr: any[]) => {
      if (!Array.isArray(playersArr)) return;
      for (const p of playersArr) {
        const isMatch =
          (lastBall.strikerId && (p.id === lastBall.strikerId || (p._id && p._id.toString() === lastBall.strikerId))) ||
          (lastBall.batsmanName && p.name && p.name.trim().toLowerCase() === lastBall.batsmanName.trim().toLowerCase());

        if (isMatch) {
          if (lastBall.extraType === 'None' || lastBall.extraType === 'No Ball') {
            p.runsScored = Math.max(0, (p.runsScored || 0) - runsNum);
          }
          if (lastBall.extraType !== 'Wide') {
            p.ballsFaced = Math.max(0, (p.ballsFaced || 0) - 1);
          }
          if (lastBall.isWicket) {
            p.isOut = false;
            p.dismissalInfo = '';
          }
        }
      }
    };

    // Helper to revert bowler stats on player arrays
    const revertBowlerStats = (playersArr: any[]) => {
      if (!Array.isArray(playersArr)) return;
      for (const p of playersArr) {
        const isMatch =
          (lastBall.bowlerId && (p.id === lastBall.bowlerId || (p._id && p._id.toString() === lastBall.bowlerId))) ||
          (lastBall.bowlerName && p.name && p.name.trim().toLowerCase() === lastBall.bowlerName.trim().toLowerCase());

        if (isMatch) {
          if (lastBall.extraType === 'None' || lastBall.extraType === 'Wide' || lastBall.extraType === 'No Ball') {
            p.runsConceded = Math.max(0, (p.runsConceded || 0) - totalRunsThisBall);
          }
          if (lastBall.isWicket && !['Run Out', 'Retired Out', 'Retired Hurt', 'Timed Out', 'Obstructing Field'].includes(lastBall.wicketType)) {
            p.wicketsTaken = Math.max(0, (p.wicketsTaken || 0) - 1);
          }
          if (isLegalBall) {
            p.oversBowled = decrementOvers(Number(p.oversBowled || 0), 1);
          }
        }
      }
    };

    revertStrikerStats(match.playingXI_A);
    revertStrikerStats(match.playingXI_B);
    if (match.teamA && match.teamA.players) revertStrikerStats(match.teamA.players);
    if (match.teamB && match.teamB.players) revertStrikerStats(match.teamB.players);

    revertBowlerStats(match.playingXI_A);
    revertBowlerStats(match.playingXI_B);
    if (match.teamA && match.teamA.players) revertBowlerStats(match.teamA.players);
    if (match.teamB && match.teamB.players) revertBowlerStats(match.teamB.players);

    // Restore striker, non-striker and bowler to pre-ball snapshot
    if (lastBall.strikerId) match.currentStrikerId = lastBall.strikerId;
    if (lastBall.nonStrikerId) match.currentNonStrikerId = lastBall.nonStrikerId;
    if (lastBall.bowlerId) match.currentBowlerId = lastBall.bowlerId;

    // Milestone rollback on undo if striker's score dropped back below milestone thresholds
    const currentInnings = match.isFirstInnings ? 1 : 2;
    if (match.celebratedMilestones && lastBall.strikerId) {
      const batTeamPlayers = match.battingTeamId === match.teamAId ? match.playingXI_A : match.playingXI_B;
      const revertedStriker = batTeamPlayers?.find((p: any) => p.id === lastBall.strikerId || (p._id && p._id.toString() === lastBall.strikerId));
      if (revertedStriker) {
        const strikerRuns = Number(revertedStriker.runsScored || 0);
        if (strikerRuns < 100) {
          match.celebratedMilestones = match.celebratedMilestones.filter(k => k !== `${currentInnings}_${revertedStriker.id}_100`);
        }
        if (strikerRuns < 50) {
          match.celebratedMilestones = match.celebratedMilestones.filter(k => k !== `${currentInnings}_${revertedStriker.id}_50`);
        }
      }
    }

    match.markModified('playingXI_A');
    match.markModified('playingXI_B');
    match.markModified('teamA');
    match.teamB && match.markModified('teamB');
    match.markModified('balls');
    match.markModified('celebratedMilestones');
    await match.save();

    await invalidateCachedMatch(matchId);
    const updated = match.toJSON();
    broadcastMatchUpdate(matchId, 'match_update', updated);

    if (idempotencyKey) {
      idempotencyStore.set(idempotencyKey, { status: 'completed', response: updated, timestamp: Date.now() });
    }

    return res.status(200).json(updated);
  } catch (err) {
    if (idempotencyKey) {
      idempotencyStore.delete(idempotencyKey);
    }
    console.error('Error undoing last ball:', err);
    return res.status(500).json({ error: 'Internal server error.' });
  }
}

export async function swapStrikers(req: Request, res: Response) {
  const { matchId } = req.params;
  try {
    const match = await MatchModel.findOne({ id: matchId });
    if (!match) {
      return res.status(404).json({ error: 'Match not found.' });
    }

    const temp = match.currentStrikerId;
    match.currentStrikerId = match.currentNonStrikerId;
    match.currentNonStrikerId = temp;

    await match.save();
    await invalidateCachedMatch(matchId);

    const updated = match.toJSON();
    broadcastMatchUpdate(matchId, 'match_update', updated);

    return res.status(200).json(updated);
  } catch (err) {
    console.error('Error swapping strikers:', err);
    return res.status(500).json({ error: 'Internal server error.' });
  }
}

export async function switchBowler(req: Request, res: Response) {
  const { matchId } = req.params;
  const { bowlerId } = req.body;

  if (!bowlerId) {
    return res.status(400).json({ error: 'Bowler ID is required.' });
  }

  try {
    const match = await MatchModel.findOne({ id: matchId });
    if (!match) {
      return res.status(404).json({ error: 'Match not found.' });
    }

    match.currentBowlerId = bowlerId;
    await match.save();
    await invalidateCachedMatch(matchId);

    const updated = match.toJSON();
    broadcastMatchUpdate(matchId, 'match_update', updated);

    return res.status(200).json(updated);
  } catch (err) {
    console.error('Error switching bowler:', err);
    return res.status(500).json({ error: 'Internal server error.' });
  }
}

export async function endInningsOrMatch(req: Request, res: Response) {
  const { matchId } = req.params;
  try {
    const match = await MatchModel.findOne({ id: matchId });
    if (!match) {
      return res.status(404).json({ error: 'Match not found.' });
    }

    if (match.isFirstInnings) {
      const isTeamABatting = match.battingTeamId === match.teamAId;
      const nextBatTeamId = isTeamABatting ? match.teamBId : match.teamAId;
      const nextBatPlayers = isTeamABatting ? match.playingXI_B : match.playingXI_A;
      const nextBowlPlayers = isTeamABatting ? match.playingXI_A : match.playingXI_B;

      const firstInningsRuns = isTeamABatting ? match.runsA : match.runsB;

      match.isFirstInnings = false;
      match.battingTeamId = nextBatTeamId;
      match.target = firstInningsRuns + 1;
      match.currentStrikerId = nextBatPlayers.length > 0 ? nextBatPlayers[0].id : '';
      match.currentNonStrikerId = nextBatPlayers.length > 1 ? nextBatPlayers[1].id : '';
      match.currentBowlerId = nextBowlPlayers.length > 0 ? nextBowlPlayers[nextBowlPlayers.length - 1].id : '';

      try {
        const nextBatTeamName = isTeamABatting ? match.teamB?.name : match.teamA?.name;
        const currentBatTeamName = (isTeamABatting ? match.teamA?.name : match.teamB?.name) || 'Batting Team';
        broadcastNotification({
          title: 'Innings Break! 🏏',
          message: `${currentBatTeamName} finished innings. ${nextBatTeamName} needs ${match.target} runs to win!`,
          timestamp: new Date().toISOString(),
        });
      } catch (_) {}
    } else {
      match.status = 'Completed';
      computeMatchResult(match);

      try {
        broadcastNotification({
          title: '🏆 Match Completed!',
          message: `${match.teamA?.name} vs ${match.teamB?.name}: ${match.resultText}`,
          timestamp: new Date().toISOString(),
        });
      } catch (_) {}
    }

    await match.save();
    await invalidateCachedMatch(matchId);

    const updated = match.toJSON();
    broadcastMatchUpdate(matchId, 'match_update', updated);

    return res.status(200).json(updated);
  } catch (err) {
    console.error('Error ending innings or match:', err);
    return res.status(500).json({ error: 'Internal server error.' });
  }
}

export async function endMatchForce(req: Request, res: Response) {
  const { matchId } = req.params;
  try {
    const match = await MatchModel.findOne({ id: matchId });
    if (!match) {
      return res.status(404).json({ error: 'Match not found.' });
    }

    match.status = 'Completed';
    computeMatchResult(match);

    try {
      broadcastNotification({
        title: '🏆 Match Completed!',
        message: `${match.teamA?.name} vs ${match.teamB?.name}: ${match.resultText}`,
        timestamp: new Date().toISOString(),
      });
    } catch (_) {}

    await match.save();
    await invalidateCachedMatch(matchId);

    const updated = match.toJSON();
    broadcastMatchUpdate(matchId, 'match_update', updated);

    return res.status(200).json(updated);
  } catch (err) {
    console.error('Error ending match force:', err);
    return res.status(500).json({ error: 'Internal server error.' });
  }
}
