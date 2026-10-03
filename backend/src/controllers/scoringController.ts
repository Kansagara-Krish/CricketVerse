import { Request, Response } from 'express';
import { MatchModel } from '../models/Match';
import { TeamModel } from '../models/Team';
import { invalidateCachedMatch, setCachedMatch } from '../config/redis';
import { broadcastMatchUpdate, broadcastNotification } from '../sockets/socketHandler';

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

    const strikerId = batTeamPlayers.length > 0 ? batTeamPlayers[0].id : '';
    const nonStrikerId = batTeamPlayers.length > 1 ? batTeamPlayers[1].id : '';
    const bowlerId = bowlTeamPlayers.length > 0 ? bowlTeamPlayers[bowlTeamPlayers.length - 1].id : '';

    match.status = 'Live';
    match.tossWinner = tossWinner;
    match.tossDecision = tossDecision;
    match.battingTeamId = firstBattingTeamId;
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

    const currentStrikerId = match.currentStrikerId;
    const currentNonStrikerId = match.currentNonStrikerId;
    const currentBowlerId = match.currentBowlerId;

    const batTeamPlayers = match.battingTeamId === match.teamAId ? match.playingXI_A : match.playingXI_B;
    const bowlTeamPlayers = match.battingTeamId === match.teamAId ? match.playingXI_B : match.playingXI_A;

    const striker = batTeamPlayers.find((p: any) => p.id === currentStrikerId);
    const bowler = bowlTeamPlayers.find((p: any) => p.id === currentBowlerId);

    const batsmanName = striker ? striker.name : 'Striker';
    const bowlerName = bowler ? bowler.name : 'Bowler';

    const runsNum = Number(runs) || 0;
    const extraRunsNum = Number(extraRuns) || 0;
    const totalRunsThisBall = runsNum + extraRunsNum;

    // Legal ball determination:
    // Wide and No Ball are NOT legal balls for over count (ballVal = 0)
    // None, Bye, Leg Bye ARE legal deliveries (ballVal = 1)
    const isLegalBall = extraType !== 'Wide' && extraType !== 'No Ball';
    const ballVal = isLegalBall ? 1 : 0;

    // 1. Team Score & Over Increment
    if (match.isFirstInnings) {
      match.runsA += totalRunsThisBall;
      if (isWicket && wicketType !== 'Retired Hurt') match.wicketsA += 1;
      match.oversA = incrementOvers(match.oversA, ballVal);
    } else {
      match.runsB += totalRunsThisBall;
      if (isWicket && wicketType !== 'Retired Hurt') match.wicketsB += 1;
      match.oversB = incrementOvers(match.oversB, ballVal);
    }

    // 2. Batsman Stats Update (MCC / ICC Rules):
    // - Striker gets runs scored off the bat ('None' and 'No Ball' with bat runs).
    // - Striker does NOT get runs on 'Wide', 'Bye', or 'Leg Bye'.
    // - Striker balls faced increments on legal balls ('None', 'Bye', 'Leg Bye') and 'No Ball'.
    // - Striker balls faced does NOT increment on 'Wide'.
    if (striker) {
      if (extraType === 'None' || extraType === 'No Ball') {
        striker.runsScored = (striker.runsScored || 0) + runsNum;
      }
      if (extraType !== 'Wide') {
        striker.ballsFaced = (striker.ballsFaced || 0) + 1;
      }
    }

    // 3. Bowler Stats Update (MCC / ICC Rules):
    // - Concedes runs scored off bat ('None'), wide penalty + runs ('Wide'), and no-ball penalty + runs ('No Ball').
    // - Byes and Leg Byes are NOT charged to the bowler's runs conceded!
    // - Wickets credited to bowler except Run Out, Retired Out, Retired Hurt, Timed Out, Obstructing Field.
    // - Overs bowled increments by 1 legal ball on legal deliveries.
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

    // Sync stats into teamA and teamB subdocuments
    if (match.teamA && Array.isArray(match.teamA.players)) {
      if (striker) {
        const idx = match.teamA.players.findIndex((p: any) => p.id === striker.id);
        if (idx !== -1) match.teamA.players[idx] = { ...match.teamA.players[idx], ...striker };
      }
      if (bowler) {
        const bIdx = match.teamA.players.findIndex((p: any) => p.id === bowler.id);
        if (bIdx !== -1) match.teamA.players[bIdx] = { ...match.teamA.players[bIdx], ...bowler };
      }
    }
    if (match.teamB && Array.isArray(match.teamB.players)) {
      if (striker) {
        const idx = match.teamB.players.findIndex((p: any) => p.id === striker.id);
        if (idx !== -1) match.teamB.players[idx] = { ...match.teamB.players[idx], ...striker };
      }
      if (bowler) {
        const bIdx = match.teamB.players.findIndex((p: any) => p.id === bowler.id);
        if (bIdx !== -1) match.teamB.players[bIdx] = { ...match.teamB.players[bIdx], ...bowler };
      }
    }

    const currentOvers = match.isFirstInnings ? match.oversA : match.oversB;
    const totalRuns = match.isFirstInnings ? match.runsA : match.runsB;
    const totalWickets = match.isFirstInnings ? match.wicketsA : match.wicketsB;

    const commentary = generateAICommentary(
      batsmanName,
      bowlerName,
      runsNum,
      extraType || 'None',
      isWicket || false,
      wicketType || 'None',
      currentOvers,
      totalRuns,
      totalWickets
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
    });

    // 4. Strike Rotation Logic:
    // Physical runs run between wickets:
    // - On normal hit: runsNum odd -> swap
    // - On Bye/Leg Bye: totalRunsThisBall odd -> swap
    // - On No Ball: runsNum odd -> swap
    // - On Wide: runsNum odd -> swap
    let shouldSwapStrike = false;
    if (extraType === 'None' && runsNum % 2 !== 0) shouldSwapStrike = true;
    else if ((extraType === 'Bye' || extraType === 'Leg Bye') && totalRunsThisBall % 2 !== 0) shouldSwapStrike = true;
    else if (extraType === 'No Ball' && runsNum % 2 !== 0) shouldSwapStrike = true;
    else if (extraType === 'Wide' && runsNum % 2 !== 0) shouldSwapStrike = true;

    // Check if over ended on this ball (legal delivery and ball counter reaches 0 in .X notation)
    const overBalls = Math.round((currentOvers - Math.floor(currentOvers)) * 10);
    const overCompleted = isLegalBall && overBalls === 0 && currentOvers > 0;
    if (overCompleted) {
      // Over change swaps strike ends
      shouldSwapStrike = !shouldSwapStrike;
    }

    let finalStrikerId = currentStrikerId;
    let finalNonStrikerId = currentNonStrikerId;

    if (shouldSwapStrike) {
      finalStrikerId = currentNonStrikerId;
      finalNonStrikerId = currentStrikerId;
    }

    // 5. Wicket handling and incoming batsman
    if (isWicket) {
      const partnerId = dismissedPlayerId === currentStrikerId ? currentNonStrikerId : currentStrikerId;

      if (newBatsmanId) {
        if (newBatsmanPosition === 'Striker') {
          finalStrikerId = newBatsmanId;
          finalNonStrikerId = partnerId;
        } else {
          finalStrikerId = partnerId;
          finalNonStrikerId = newBatsmanId;
        }
      } else {
        const usedIds = new Set<string>();
        match.balls.forEach((b: any) => {
          if (b.strikerId) usedIds.add(b.strikerId);
          if (b.nonStrikerId) usedIds.add(b.nonStrikerId);
        });

        const available = batTeamPlayers.filter((p: any) => !usedIds.has(p.id));
        if (available.length > 0) {
          const nextPlayerId = available[0].id;
          if (dismissedPlayerId === currentNonStrikerId) {
            finalNonStrikerId = nextPlayerId;
          } else {
            finalStrikerId = nextPlayerId;
          }
        }
      }
    }

    match.currentStrikerId = finalStrikerId;
    match.currentNonStrikerId = finalNonStrikerId;

    // Check for Innings & Match completion
    const finalWickets = match.isFirstInnings ? match.wicketsA : match.wicketsB;
    if (finalWickets >= 10 || (!match.isFirstInnings && match.runsB >= match.target && match.target > 0)) {
      if (match.isFirstInnings) {
        const nextBatTeamId = match.battingTeamId === match.teamAId ? match.teamBId : match.teamAId;
        const nextBatPlayers = nextBatTeamId === match.teamAId ? match.playingXI_A : match.playingXI_B;
        const nextBowlPlayers = nextBatTeamId === match.teamAId ? match.playingXI_B : match.playingXI_A;

        match.isFirstInnings = false;
        match.battingTeamId = nextBatTeamId;
        match.target = match.runsA + 1;
        match.currentStrikerId = nextBatPlayers.length > 0 ? nextBatPlayers[0].id : '';
        match.currentNonStrikerId = nextBatPlayers.length > 1 ? nextBatPlayers[1].id : '';
        match.currentBowlerId = nextBowlPlayers.length > 0 ? nextBowlPlayers[nextBowlPlayers.length - 1].id : '';
      } else {
        match.status = 'Completed';
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
    const isLegalBall = lastBall.extraType !== 'Wide' && lastBall.extraType !== 'No Ball';
    const ballVal = isLegalBall ? 1 : 0;
    const totalRunsThisBall = (lastBall.run || 0) + (lastBall.extraRun || 0);

    if (match.isFirstInnings) {
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
    }

    // Revert player batting & bowling stats
    const batTeamPlayers = match.battingTeamId === match.teamAId ? match.playingXI_A : match.playingXI_B;
    const bowlTeamPlayers = match.battingTeamId === match.teamAId ? match.playingXI_B : match.playingXI_A;

    const striker = batTeamPlayers.find((p: any) => p.id === lastBall.strikerId);
    const bowler = bowlTeamPlayers.find((p: any) => p.id === lastBall.bowlerId);

    if (striker) {
      if (lastBall.extraType === 'None' || lastBall.extraType === 'No Ball') {
        striker.runsScored = Math.max(0, (striker.runsScored || 0) - lastBall.run);
      }
      if (lastBall.extraType !== 'Wide') {
        striker.ballsFaced = Math.max(0, (striker.ballsFaced || 0) - 1);
      }
    }

    if (bowler) {
      if (lastBall.extraType === 'None' || lastBall.extraType === 'Wide' || lastBall.extraType === 'No Ball') {
        bowler.runsConceded = Math.max(0, (bowler.runsConceded || 0) - totalRunsThisBall);
      }
      if (lastBall.isWicket && !['Run Out', 'Retired Out', 'Retired Hurt', 'Timed Out', 'Obstructing Field'].includes(lastBall.wicketType)) {
        bowler.wicketsTaken = Math.max(0, (bowler.wicketsTaken || 0) - 1);
      }
      if (isLegalBall) {
        bowler.oversBowled = decrementOvers(Number(bowler.oversBowled || 0), 1);
      }
    }

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
      const nextBatTeamId = match.battingTeamId === match.teamAId ? match.teamBId : match.teamAId;
      const nextBatPlayers = nextBatTeamId === match.teamAId ? match.playingXI_A : match.playingXI_B;
      const nextBowlPlayers = nextBatTeamId === match.teamAId ? match.playingXI_B : match.playingXI_A;

      match.isFirstInnings = false;
      match.battingTeamId = nextBatTeamId;
      match.target = match.runsA + 1;
      match.currentStrikerId = nextBatPlayers.length > 0 ? nextBatPlayers[0].id : '';
      match.currentNonStrikerId = nextBatPlayers.length > 1 ? nextBatPlayers[1].id : '';
      match.currentBowlerId = nextBowlPlayers.length > 0 ? nextBowlPlayers[nextBowlPlayers.length - 1].id : '';
    } else {
      match.status = 'Completed';
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
