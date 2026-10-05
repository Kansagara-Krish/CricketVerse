import { Request, Response } from 'express';
import { MatchModel } from '../models/Match';
import { TeamModel } from '../models/Team';
import { invalidateCachedMatch, setCachedMatch } from '../config/redis';
import { broadcastMatchUpdate, broadcastNotification } from '../sockets/socketHandler';

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

function generateAICommentary(
  batsman: string,
  bowler: string,
  runs: number,
  extraType: string,
  isWicket: boolean,
  wicketType: string,
  overs?: number,
  totalRuns?: number,
  totalWickets?: number
): string {
  const selectRandom = (arr: string[]) => arr[Math.floor(Math.random() * arr.length)];
  const scoreText = totalRuns !== undefined && totalWickets !== undefined ? ` Score: ${totalRuns}/${totalWickets}.` : '';

  if (isWicket) {
    if (wicketType === 'Bowled') {
      return selectRandom([
        `BOWLED HIM! Clean through the gate! ${bowler} knocks back middle stump! ${batsman} departs.${scoreText}`,
        `TIMBERRR! Absolute jaffa from ${bowler}! Shatters the stumps, sending bails flying!${scoreText}`,
      ]);
    }
    if (wicketType === 'Caught') {
      return selectRandom([
        `CAUGHT! In the air... and taken! ${batsman} goes for the big one off ${bowler}, but finds the fielder at deep mid-wicket.${scoreText}`,
        `WHAT A CATCH! Fielder dives full length at backward point to grab a stunner off ${bowler}! ${batsman} is out.${scoreText}`,
      ]);
    }
    if (wicketType === 'LBW') {
      return selectRandom([
        `LBW! Huge shout from ${bowler}, and the finger goes straight up! ${batsman} is trapped right in front.${scoreText}`,
        `DEAD PLUMB! ${bowler} hits the front pad on the knee roll! Umpire raises the finger without hesitation!${scoreText}`,
      ]);
    }
    if (wicketType === 'Run Out') {
      return selectRandom([
        `RUN OUT! DIRECT HIT! Fielder fires at the striker's end and catches ${batsman} inches short of the crease!${scoreText}`,
        `DISASTER RUN OUT! Mix-up between the wickets, flat throw to the keeper and bails are whipped off!${scoreText}`,
      ]);
    }
    return selectRandom([
      `OUT! ${bowler} strikes! ${batsman} tries to smash it but is dismissed! Brilliant delivery!${scoreText}`,
      `WICKET! ${bowler} breaks through! Crucial wicket of ${batsman} falls.${scoreText}`,
    ]);
  }

  if (extraType === 'Wide') {
    return `Wide ball! ${bowler} strays down the leg side, ${batsman} lets it go. Extra run to the total.`;
  }
  if (extraType === 'No Ball') {
    return `No Ball! ${bowler} oversteps the crease. That's an extra run and a Free Hit for ${batsman}!`;
  }

  if (runs === 6) {
    return selectRandom([
      `SIX! MASSIVE HIT! ${batsman} steps out and launches ${bowler} 95 meters into the top tier!${scoreText}`,
      `MAXIMUM! Incredibly struck by ${batsman}! Picked up off the pads and dispatched into the crowd!${scoreText}`,
      `SIX MORE! ${batsman} displays pure class, a sweet pull shot that sails comfortably over deep square leg.${scoreText}`,
      `BOOM! Pure timing and muscle from ${batsman}! Dispatches ${bowler} straight over the bowler's head for SIX!${scoreText}`,
    ]);
  }
  if (runs === 4) {
    return selectRandom([
      `FOUR! GLORIOUS COVER DRIVE! ${batsman} leans into the half-volley from ${bowler} and pierces the boundary gap!${scoreText}`,
      `CRACKING BOUNDARY! Short and wide from ${bowler}, ${batsman} punishes it with a blistering cut for four.${scoreText}`,
      `FOUR RUNS! Short and wide from ${bowler}, cut away elegantly by ${batsman} to the fence.${scoreText}`,
      `DELICIOUS WRIST-WORK! ${batsman} flicks ${bowler} past mid-wicket and it races away to the rope!${scoreText}`,
    ]);
  }
  if (runs === 0) {
    return selectRandom([
      `Dot ball. Good length delivery from ${bowler}, played defensively back to the bowler.`,
      `Dot ball. ${batsman} swings and misses a slower off-cutter from ${bowler}.`,
      `Well bowled! ${bowler} beats ${batsman} outside the off stump with a beautiful outswinger.`,
      `Fierce 142 km/h bouncer from ${bowler}! ${batsman} ducks under it just in time.`,
    ]);
  }
  if (runs === 1) {
    return selectRandom([
      `Single taken. ${batsman} drives ${bowler} down to long-off to rotate the strike.${scoreText}`,
      `Quick single! Tapped to mid-on by ${batsman}, sharp call and they scramble home.${scoreText}`,
      `Worked away off the hips by ${batsman} into deep square leg for a single.${scoreText}`,
    ]);
  }
  if (runs === 2) {
    return `Two runs! Driven into the deep extra cover pocket, swift turn by ${batsman} to steal a second run.${scoreText}`;
  }

  return `${runs} runs scored. Excellent running between wickets by ${batsman}.${scoreText}`;
}

export function computeMatchResult(match: any) {
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

  const secondWickets = isTeamAFirst ? Number(match.wicketsB || 0) : Number(match.wicketsA || 0);
  const secondTeamPlayers = isTeamAFirst
    ? (match.playingXI_B?.length || match.teamB?.players?.length || 11)
    : (match.playingXI_A?.length || match.teamA?.players?.length || 11);
  const maxWicketsSecond = Math.max(1, secondTeamPlayers - 1);
  const wicketsInHand = Math.max(1, maxWicketsSecond - secondWickets);

  if (secondRuns > firstRuns) {
    match.winnerTeamId = secondBatTeamId;
    match.winnerName = secondBatTeamName;
    match.resultText = `${secondBatTeamName} won by ${wicketsInHand} wicket${wicketsInHand === 1 ? '' : 's'}`;
  } else if (firstRuns > secondRuns) {
    const margin = firstRuns - secondRuns;
    match.winnerTeamId = firstBatTeamId;
    match.winnerName = firstBatTeamName;
    match.resultText = `${firstBatTeamName} won by ${margin} run${margin === 1 ? '' : 's'}`;
  } else {
    match.winnerTeamId = '';
    match.winnerName = 'Tie';
    match.resultText = 'Match Tied!';
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

export async function updateScore(req: Request, res: Response) {
  const { matchId } = req.params;
  const { runs, extraType, extraRuns, isWicket, wicketType, dismissedPlayerId, newBatsmanId, newBatsmanPosition } = req.body;

  try {
    const match = await MatchModel.findOne({ id: matchId });
    if (!match) {
      return res.status(404).json({ error: 'Match not found.' });
    }

    if (match.status === 'Completed') {
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
    if (striker) {
      if (extraType === 'None' || extraType === 'No Ball') {
        striker.runsScored = (striker.runsScored || 0) + runsNum;
      }
      if (extraType !== 'Wide') {
        striker.ballsFaced = (striker.ballsFaced || 0) + 1;
      }
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
    await match.save();

    await invalidateCachedMatch(matchId);
    const updated = match.toJSON();
    broadcastMatchUpdate(matchId, 'match_update', updated);

    return res.status(200).json(updated);
  } catch (err) {
    console.error('Error updating score:', err);
    return res.status(500).json({ error: 'Internal server error.' });
  }
}

export async function undoLastBall(req: Request, res: Response) {
  const { matchId } = req.params;
  try {
    const match = await MatchModel.findOne({ id: matchId });
    if (!match) {
      return res.status(404).json({ error: 'Match not found.' });
    }

    if (!match.balls || match.balls.length === 0) {
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

    match.markModified('playingXI_A');
    match.markModified('playingXI_B');
    match.markModified('teamA');
    match.teamB && match.markModified('teamB');
    match.markModified('balls');
    await match.save();

    await invalidateCachedMatch(matchId);
    const updated = match.toJSON();
    broadcastMatchUpdate(matchId, 'match_update', updated);

    return res.status(200).json(updated);
  } catch (err) {
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
