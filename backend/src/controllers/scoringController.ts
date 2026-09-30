import { Request, Response } from 'express';
import { prisma } from '../config/db';
import { invalidateCachedMatch, getCachedMatch, setCachedMatch } from '../config/redis';
import { broadcastMatchUpdate, broadcastNotification } from '../sockets/socketHandler';

// Helper to fetch and rebuild match data to broadcast/return
async function getFullMatchData(matchId: string) {
  const raw = await prisma.match.findUnique({
    where: { id: matchId },
    include: {
      teamA: {
        include: {
          players: {
            include: { player: true },
          },
        },
      },
      teamB: {
        include: {
          players: {
            include: { player: true },
          },
        },
      },
      playingXIs: {
        include: { player: true },
      },
      ballRecords: {
        orderBy: { timestamp: 'asc' },
      },
    },
  });

  if (!raw) return null;

  const formatPlayer = (p: any) => ({
    id: p.id,
    name: p.name,
    role: p.role,
    nationality: p.nationality,
    runsScored: p.runsScored,
    ballsFaced: p.ballsFaced,
    wicketsTaken: p.wicketsTaken,
    runsConceded: p.runsConceded,
    oversBowled: Number(p.oversBowled),
    matchesPlayed: p.matchesPlayed,
  });

  const teamAObj = {
    id: raw.teamA.id,
    name: raw.teamA.name,
    shortName: raw.teamA.shortName,
    logoColorHex: raw.teamA.logoColorHex,
    players: raw.teamA.players.map((tp) => formatPlayer(tp.player)),
  };

  const teamBObj = {
    id: raw.teamB.id,
    name: raw.teamB.name,
    shortName: raw.teamB.shortName,
    logoColorHex: raw.teamB.logoColorHex,
    players: raw.teamB.players.map((tp) => formatPlayer(tp.player)),
  };

  const xiAPlayers = raw.playingXIs.filter((xi) => xi.teamId === raw.teamAId).map((xi) => formatPlayer(xi.player));
  const xiBPlayers = raw.playingXIs.filter((xi) => xi.teamId === raw.teamBId).map((xi) => formatPlayer(xi.player));

  const ballsList = raw.ballRecords.map((b) => ({
    run: b.run,
    extraRun: b.extraRun,
    extraType: b.extraType,
    isWicket: b.isWicket,
    wicketType: b.wicketType,
    batsmanName: b.batsmanName,
    bowlerName: b.bowlerName,
    commentary: b.commentary,
    timestamp: b.timestamp.toISOString(),
    strikerId: b.strikerId,
    nonStrikerId: b.nonStrikerId,
    bowlerId: b.bowlerId,
  }));

  return {
    id: raw.id,
    teamA: teamAObj,
    teamB: teamBObj,
    matchType: raw.matchType,
    venue: raw.venue,
    date: raw.date,
    time: raw.time,
    status: raw.status,
    tossWinner: raw.tossWinner,
    tossDecision: raw.tossDecision,
    battingTeamId: raw.battingTeamId,
    playingXI_A: xiAPlayers,
    playingXI_B: xiBPlayers,
    runsA: raw.runsA,
    wicketsA: raw.wicketsA,
    oversA: Number(raw.oversA),
    runsB: raw.runsB,
    wicketsB: raw.wicketsB,
    oversB: Number(raw.oversB),
    target: raw.target,
    scorerUsername: raw.scorerUsername,
    scorerPassword: raw.scorerPassword,
    currentStrikerId: raw.currentStrikerId,
    currentNonStrikerId: raw.currentNonStrikerId,
    currentBowlerId: raw.currentBowlerId,
    balls: ballsList,
    isFirstInnings: raw.isFirstInnings,
  };
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
  return parseFloat((oversInt + (ballsInt / 10.0)).toFixed(1));
}

function decrementOvers(currentOvers: number, ballsRemoved: number): number {
  if (ballsRemoved === 0) return currentOvers;
  let oversInt = Math.floor(currentOvers);
  let ballsInt = Math.round((currentOvers - oversInt) * 10);
  
  ballsInt -= ballsRemoved;
  if (ballsInt < 0) {
    const oversNeeded = Math.ceil(Math.abs(ballsInt) / 6);
    oversInt -= oversNeeded;
    ballsInt = (ballsInt + (oversNeeded * 6)) % 6;
    if (oversInt < 0) {
      oversInt = 0;
      ballsInt = 0;
    }
  }
  return parseFloat((oversInt + (ballsInt / 10.0)).toFixed(1));
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
  const scoreText = (totalRuns !== undefined && totalWickets !== undefined) ? ` Score: ${totalRuns}/${totalWickets}.` : '';
  const overStr = overs !== undefined ? ` (Over ${overs.toFixed(1)})` : '';

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
    const wicketTpls = [
      `OUT! ${bowler} strikes! ${batsman} tries to smash it but is dismissed! Brilliant delivery!${scoreText}`,
      `WICKET! ${bowler} breaks through! Crucial wicket of ${batsman} falls.${scoreText}`,
    ];
    return selectRandom(wicketTpls);
  }

  if (extraType === 'Wide') {
    return `Wide ball! ${bowler} strays down the leg side, ${batsman} lets it go. Extra run to the total.`;
  }
  if (extraType === 'No Ball') {
    return `No Ball! ${bowler} oversteps the crease. That's an extra run and a Free Hit for ${batsman}!`;
  }

  if (runs === 6) {
    const sixTpls = [
      `SIX! MASSIVE HIT! ${batsman} steps out and launches ${bowler} 95 meters into the top tier!${scoreText}`,
      `MAXIMUM! Incredibly struck by ${batsman}! Picked up off the pads and dispatched into the crowd!${scoreText}`,
      `SIX MORE! ${batsman} displays pure class, a sweet pull shot that sails comfortably over deep square leg.${scoreText}`,
      `BOOM! Pure timing and muscle from ${batsman}! Dispatches ${bowler} straight over the bowler's head for SIX!${scoreText}`,
    ];
    return selectRandom(sixTpls);
  }
  if (runs === 4) {
    const fourTpls = [
      `FOUR! GLORIOUS COVER DRIVE! ${batsman} leans into the half-volley from ${bowler} and pierces the boundary gap!${scoreText}`,
      `CRACKING BOUNDARY! Short and wide from ${bowler}, ${batsman} punishes it with a blistering cut for four.${scoreText}`,
      `FOUR RUNS! Short and wide from ${bowler}, cut away elegantly by ${batsman} to the fence.${scoreText}`,
      `DELICIOUS WRIST-WORK! ${batsman} flicks ${bowler} past mid-wicket and it races away to the rope!${scoreText}`,
    ];
    return selectRandom(fourTpls);
  }
  if (runs === 0) {
    const dotTpls = [
      `Dot ball. Good length delivery from ${bowler}, played defensively back to the bowler.`,
      `Dot ball. ${batsman} swings and misses a slower off-cutter from ${bowler}.`,
      `Well bowled! ${bowler} beats ${batsman} outside the off stump with a beautiful outswinger.`,
      `Fierce 142 km/h bouncer from ${bowler}! ${batsman} ducks under it just in time.`,
    ];
    return selectRandom(dotTpls);
  }

  if (runs === 1) {
    const runTpls = [
      `Single taken. ${batsman} drives ${bowler} down to long-off to rotate the strike.${scoreText}`,
      `Quick single! Tapped to mid-on by ${batsman}, sharp call and they scramble home.${scoreText}`,
      `Worked away off the hips by ${batsman} into deep square leg for a single.${scoreText}`,
    ];
    return selectRandom(runTpls);
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
    const match = await prisma.match.findUnique({ where: { id: matchId } });
    if (!match) {
      return res.status(404).json({ error: 'Match not found.' });
    }

    const isTeamAFirst = firstBattingTeamId === match.teamAId;
    const batTeamId = isTeamAFirst ? match.teamAId : match.teamBId;
    const bowlTeamId = isTeamAFirst ? match.teamBId : match.teamAId;

    const batPlayers = await prisma.teamPlayer.findMany({
      where: { teamId: batTeamId },
      orderBy: { playerId: 'asc' },
      take: 2,
    });
    const strikerId = batPlayers.length > 0 ? batPlayers[0].playerId : '';
    const nonStrikerId = batPlayers.length > 1 ? batPlayers[1].playerId : '';

    const bowlPlayers = await prisma.teamPlayer.findMany({
      where: { teamId: bowlTeamId },
      orderBy: { playerId: 'desc' },
      take: 1,
    });
    const bowlerId = bowlPlayers.length > 0 ? bowlPlayers[0].playerId : '';

    await prisma.match.update({
      where: { id: matchId },
      data: {
        status: 'Live',
        tossWinner,
        tossDecision,
        battingTeamId: batTeamId,
        currentStrikerId: strikerId,
        currentNonStrikerId: nonStrikerId,
        currentBowlerId: bowlerId,
      },
    });

    await invalidateCachedMatch(matchId);
    const updatedMatch = await getFullMatchData(matchId);
    if (updatedMatch) {
      await setCachedMatch(matchId, updatedMatch);
      broadcastMatchUpdate(matchId, 'match_update', updatedMatch);

      try {
        const tossDecisionText = updatedMatch.tossDecision === 'Bat' ? 'batting' : 'bowling';
        broadcastNotification({
          title: 'Match Started! 🏏',
          message: `${updatedMatch.tossWinner} won the toss and chose to ${tossDecisionText}. ${updatedMatch.teamA.name} vs ${updatedMatch.teamB.name} is now LIVE!`,
          timestamp: new Date().toISOString()
        });
      } catch (broadcastErr) {
        console.error('Error broadcasting start match notification:', broadcastErr);
      }
    }

    return res.status(200).json(updatedMatch);
  } catch (err) {
    console.error('Error starting match setup:', err);
    return res.status(500).json({ error: 'Internal server error.' });
  }
}

export async function updateScore(req: Request, res: Response) {
  const { matchId } = req.params;
  const { runs, extraType, extraRuns, isWicket, wicketType, dismissedPlayerId, newBatsmanId, newBatsmanPosition } = req.body;

  try {
    const updatedMatchData = await prisma.$transaction(async (tx) => {
      const match = await tx.match.findUnique({ where: { id: matchId } });
      if (!match) return null;

      const currentStrikerIdBefore = match.currentStrikerId;
      const currentNonStrikerIdBefore = match.currentNonStrikerId;
      const currentBowlerIdBefore = match.currentBowlerId;

      const striker = await tx.player.findUnique({ where: { id: currentStrikerIdBefore } });
      const bowler = await tx.player.findUnique({ where: { id: currentBowlerIdBefore } });
      if (!striker || !bowler) return null;

      let ballVal = 1;
      if (extraType === 'Wide' || extraType === 'No Ball') {
        ballVal = 0;
      }

      const totalRunsThisBall = runs + extraRuns;
      let runsA = match.runsA;
      let wicketsA = match.wicketsA;
      let oversA = Number(match.oversA);
      let runsB = match.runsB;
      let wicketsB = match.wicketsB;
      let oversB = Number(match.oversB);

      if (match.isFirstInnings) {
        runsA += totalRunsThisBall;
        if (isWicket && wicketType !== 'Retired Hurt') wicketsA += 1;
        oversA = incrementOvers(oversA, ballVal);
      } else {
        runsB += totalRunsThisBall;
        if (isWicket && wicketType !== 'Retired Hurt') wicketsB += 1;
        oversB = incrementOvers(oversB, ballVal);
      }

      // Update Player Batting Stats
      if (extraType === 'None' || extraType === 'Leg Bye') {
        await tx.player.update({
          where: { id: currentStrikerIdBefore },
          data: {
            runsScored: striker.runsScored + runs,
            ballsFaced: striker.ballsFaced + ballVal,
          },
        });
      }

      // Update Bowler Stats
      const newConceded = bowler.runsConceded + totalRunsThisBall;
      let newWickets = bowler.wicketsTaken;
      if (isWicket && wicketType !== 'Run Out' && wicketType !== 'Retired Out' && wicketType !== 'Retired Hurt') {
        newWickets += 1;
      }
      let newOversBowled = Number(bowler.oversBowled);
      if (ballVal > 0) {
        newOversBowled = incrementOvers(newOversBowled, 1);
      }
      await tx.player.update({
        where: { id: currentBowlerIdBefore },
        data: {
          runsConceded: newConceded,
          wicketsTaken: newWickets,
          oversBowled: newOversBowled,
        },
      });

      const currentOvers = match.isFirstInnings ? oversA : oversB;
      const totalRuns = match.isFirstInnings ? runsA : runsB;
      const totalWickets = match.isFirstInnings ? wicketsA : wicketsB;
      const commentary = generateAICommentary(
        striker.name,
        bowler.name,
        runs,
        extraType,
        isWicket,
        wicketType,
        currentOvers,
        totalRuns,
        totalWickets
      );

      await tx.ballRecord.create({
        data: {
          matchId,
          run: runs,
          extraRun: extraRuns,
          extraType,
          isWicket,
          wicketType,
          batsmanName: striker.name,
          bowlerName: bowler.name,
          commentary,
          strikerId: currentStrikerIdBefore,
          nonStrikerId: currentNonStrikerIdBefore,
          bowlerId: currentBowlerIdBefore,
        },
      });

      let finalStrikerId = currentStrikerIdBefore;
      let finalNonStrikerId = currentNonStrikerIdBefore;
      if (runs % 2 !== 0 && (extraType === 'None' || extraType === 'Leg Bye')) {
        finalStrikerId = currentNonStrikerIdBefore;
        finalNonStrikerId = currentStrikerIdBefore;
      }

      if (isWicket) {
        const partnerId = (dismissedPlayerId === currentStrikerIdBefore) ? currentNonStrikerIdBefore : currentStrikerIdBefore;

        if (newBatsmanId) {
          if (newBatsmanPosition === 'Striker') {
            finalStrikerId = newBatsmanId;
            finalNonStrikerId = partnerId;
          } else {
            finalStrikerId = partnerId;
            finalNonStrikerId = newBatsmanId;
          }
        } else {
          const usedStrikers = await tx.ballRecord.findMany({
            where: { matchId },
            select: { strikerId: true, nonStrikerId: true },
          });
          const usedIds = new Set<string>();
          usedStrikers.forEach((b) => {
            if (b.strikerId) usedIds.add(b.strikerId);
            if (b.nonStrikerId) usedIds.add(b.nonStrikerId);
          });

          const availablePlayers = await tx.teamPlayer.findMany({
            where: {
              teamId: match.battingTeamId,
              playerId: { notIn: Array.from(usedIds) },
            },
            take: 1,
          });

          if (availablePlayers.length > 0) {
            const nextPlayerId = availablePlayers[0].playerId;
            if (dismissedPlayerId === currentNonStrikerIdBefore) {
              finalNonStrikerId = nextPlayerId;
            } else {
              finalStrikerId = nextPlayerId;
            }
          }
        }
      }

      await tx.match.update({
        where: { id: matchId },
        data: {
          runsA,
          wicketsA,
          oversA,
          runsB,
          wicketsB,
          oversB,
          currentStrikerId: finalStrikerId,
          currentNonStrikerId: finalNonStrikerId,
        },
      });

      const finalWickets = match.isFirstInnings ? wicketsA : wicketsB;
      if (finalWickets >= 10) {
        if (match.isFirstInnings) {
          const nextBatTeamId = match.battingTeamId === match.teamAId ? match.teamBId : match.teamAId;
          const nextBatPlayers = await tx.teamPlayer.findMany({
            where: { teamId: nextBatTeamId },
            orderBy: { playerId: 'asc' },
            take: 2,
          });
          const nextBowlPlayers = await tx.teamPlayer.findMany({
            where: { teamId: match.battingTeamId },
            orderBy: { playerId: 'desc' },
            take: 1,
          });

          const nextStriker = nextBatPlayers.length > 0 ? nextBatPlayers[0].playerId : '';
          const nextNonStriker = nextBatPlayers.length > 1 ? nextBatPlayers[1].playerId : '';
          const nextBowler = nextBowlPlayers.length > 0 ? nextBowlPlayers[0].playerId : '';

          await tx.match.update({
            where: { id: matchId },
            data: {
              isFirstInnings: false,
              battingTeamId: nextBatTeamId,
              target: runsA + 1,
              currentStrikerId: nextStriker,
              currentNonStrikerId: nextNonStriker,
              currentBowlerId: nextBowler,
            },
          });
        } else {
          await tx.match.update({
            where: { id: matchId },
            data: { status: 'Completed' },
          });
        }
      }
      return true;
    });

    if (!updatedMatchData) {
      return res.status(404).json({ error: 'Match or player not found.' });
    }

    await invalidateCachedMatch(matchId);
    const updatedMatch = await getFullMatchData(matchId);
    if (updatedMatch) {
      await setCachedMatch(matchId, updatedMatch);
      broadcastMatchUpdate(matchId, 'match_update', updatedMatch);
    }

    return res.status(200).json(updatedMatch);
  } catch (err) {
    console.error('Error updating score:', err);
    return res.status(500).json({ error: 'Internal server error.' });
  }
}

export async function undoLastBall(req: Request, res: Response) {
  const { matchId } = req.params;
  try {
    const success = await prisma.$transaction(async (tx) => {
      const match = await tx.match.findUnique({ where: { id: matchId } });
      if (!match) return null;

      const lastBall = await tx.ballRecord.findFirst({
        where: { matchId },
        orderBy: { id: 'desc' },
      });

      if (!lastBall) return false;

      const strikerId = lastBall.strikerId || '';
      const nonStrikerId = lastBall.nonStrikerId || '';
      const bowlerId = lastBall.bowlerId || '';

      const striker = await tx.player.findUnique({ where: { id: strikerId } });
      const bowler = await tx.player.findUnique({ where: { id: bowlerId } });
      if (!striker || !bowler) return false;

      const ballVal = (lastBall.extraType === 'Wide' || lastBall.extraType === 'No Ball') ? 0 : 1;
      const totalRunsThisBall = lastBall.run + lastBall.extraRun;

      let runsA = match.runsA;
      let wicketsA = match.wicketsA;
      let oversA = Number(match.oversA);
      let runsB = match.runsB;
      let wicketsB = match.wicketsB;
      let oversB = Number(match.oversB);
      let status = match.status;

      if (match.isFirstInnings) {
        runsA = Math.max(0, runsA - totalRunsThisBall);
        if (lastBall.isWicket && lastBall.wicketType !== 'Retired Hurt') {
          wicketsA = Math.max(0, wicketsA - 1);
        }
        oversA = decrementOvers(oversA, ballVal);
      } else {
        runsB = Math.max(0, runsB - totalRunsThisBall);
        if (lastBall.isWicket && lastBall.wicketType !== 'Retired Hurt') {
          wicketsB = Math.max(0, wicketsB - 1);
        }
        oversB = decrementOvers(oversB, ballVal);
      }

      if (status === 'Completed') {
        status = 'Live';
      }

      // Revert Player Batting Stats
      if (lastBall.extraType === 'None' || lastBall.extraType === 'Leg Bye') {
        const newRuns = Math.max(0, striker.runsScored - lastBall.run);
        const newBalls = Math.max(0, striker.ballsFaced - ballVal);
        await tx.player.update({
          where: { id: strikerId },
          data: { runsScored: newRuns, ballsFaced: newBalls },
        });
      }

      // Revert Bowler Stats
      const newConceded = Math.max(0, bowler.runsConceded - totalRunsThisBall);
      let newWickets = bowler.wicketsTaken;
      if (lastBall.isWicket && lastBall.wicketType !== 'Run Out' && lastBall.wicketType !== 'Retired Out' && lastBall.wicketType !== 'Retired Hurt') {
        newWickets = Math.max(0, newWickets - 1);
      }
      let newOversBowled = Number(bowler.oversBowled);
      if (ballVal > 0) {
        newOversBowled = decrementOvers(newOversBowled, 1);
      }
      await tx.player.update({
        where: { id: bowlerId },
        data: { runsConceded: newConceded, wicketsTaken: newWickets, oversBowled: newOversBowled },
      });

      await tx.ballRecord.delete({ where: { id: lastBall.id } });

      await tx.match.update({
        where: { id: matchId },
        data: {
          runsA, wicketsA, oversA,
          runsB, wicketsB, oversB,
          currentStrikerId: strikerId,
          currentNonStrikerId: nonStrikerId,
          currentBowlerId: bowlerId,
          status,
        },
      });

      return true;
    });

    if (success === false) {
      return res.status(400).json({ error: 'No balls recorded or player not found.' });
    }
    if (success === null) {
      return res.status(404).json({ error: 'Match not found.' });
    }

    await invalidateCachedMatch(matchId);
    const updatedMatch = await getFullMatchData(matchId);
    if (updatedMatch) {
      await setCachedMatch(matchId, updatedMatch);
      broadcastMatchUpdate(matchId, 'match_update', updatedMatch);
    }

    return res.status(200).json(updatedMatch);
  } catch (err) {
    console.error('Error in undo last ball:', err);
    return res.status(500).json({ error: 'Internal server error.' });
  }
}

export async function swapStrikers(req: Request, res: Response) {
  const { matchId } = req.params;
  try {
    const match = await prisma.match.findUnique({ where: { id: matchId } });
    if (!match) {
      return res.status(404).json({ error: 'Match not found.' });
    }

    await prisma.match.update({
      where: { id: matchId },
      data: {
        currentStrikerId: match.currentNonStrikerId,
        currentNonStrikerId: match.currentStrikerId,
      },
    });

    await invalidateCachedMatch(matchId);
    const updatedMatch = await getFullMatchData(matchId);
    if (updatedMatch) {
      await setCachedMatch(matchId, updatedMatch);
      broadcastMatchUpdate(matchId, 'match_update', updatedMatch);
    }

    return res.status(200).json(updatedMatch);
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
    await prisma.match.update({
      where: { id: matchId },
      data: { currentBowlerId: bowlerId },
    });

    await invalidateCachedMatch(matchId);
    const updatedMatch = await getFullMatchData(matchId);
    if (updatedMatch) {
      await setCachedMatch(matchId, updatedMatch);
      broadcastMatchUpdate(matchId, 'match_update', updatedMatch);
    }

    return res.status(200).json(updatedMatch);
  } catch (err) {
    console.error('Error switching bowler:', err);
    return res.status(500).json({ error: 'Internal server error.' });
  }
}

export async function endInningsOrMatch(req: Request, res: Response) {
  const { matchId } = req.params;
  try {
    const match = await prisma.match.findUnique({ where: { id: matchId } });
    if (!match) {
      return res.status(404).json({ error: 'Match not found.' });
    }

    if (match.isFirstInnings) {
      const nextBatTeamId = match.battingTeamId === match.teamAId ? match.teamBId : match.teamAId;

      const nextBatPlayers = await prisma.teamPlayer.findMany({
        where: { teamId: nextBatTeamId },
        orderBy: { playerId: 'asc' },
        take: 2,
      });
      const nextBowlPlayers = await prisma.teamPlayer.findMany({
        where: { teamId: match.battingTeamId },
        orderBy: { playerId: 'desc' },
        take: 1,
      });

      const nextStriker = nextBatPlayers.length > 0 ? nextBatPlayers[0].playerId : '';
      const nextNonStriker = nextBatPlayers.length > 1 ? nextBatPlayers[1].playerId : '';
      const nextBowler = nextBowlPlayers.length > 0 ? nextBowlPlayers[0].playerId : '';

      await prisma.match.update({
        where: { id: matchId },
        data: {
          isFirstInnings: false,
          battingTeamId: nextBatTeamId,
          target: match.runsA + 1,
          currentStrikerId: nextStriker,
          currentNonStrikerId: nextNonStriker,
          currentBowlerId: nextBowler,
        },
      });
    } else {
      await prisma.match.update({
        where: { id: matchId },
        data: { status: 'Completed' },
      });
    }

    await invalidateCachedMatch(matchId);
    const updatedMatch = await getFullMatchData(matchId);
    if (updatedMatch) {
      await setCachedMatch(matchId, updatedMatch);
      broadcastMatchUpdate(matchId, 'match_update', updatedMatch);
    }

    return res.status(200).json(updatedMatch);
  } catch (err) {
    console.error('Error ending innings/match:', err);
    return res.status(500).json({ error: 'Internal server error.' });
  }
}

export async function endMatchForce(req: Request, res: Response) {
  const { matchId } = req.params;
  try {
    await prisma.match.update({
      where: { id: matchId },
      data: { status: 'Completed' },
    });
    await invalidateCachedMatch(matchId);

    const updatedMatch = await getFullMatchData(matchId);
    if (updatedMatch) {
      await setCachedMatch(matchId, updatedMatch);
      broadcastMatchUpdate(matchId, 'match_update', updatedMatch);
    }

    return res.status(200).json(updatedMatch);
  } catch (err) {
    console.error('Error forcing end match:', err);
    return res.status(500).json({ error: 'Internal server error.' });
  }
}
