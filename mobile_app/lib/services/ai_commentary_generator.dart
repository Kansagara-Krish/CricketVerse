import 'dart:math';

class AiCommentaryContext {
  final String batsman;
  final String bowler;
  final int runs;
  final String extraType;
  final int extraRuns;
  final bool isWicket;
  final String wicketType;
  final double currentOvers;
  final int totalRuns;
  final int totalWickets;
  final int? target;
  final String style; // 'Hype / Energetic', 'Professional', 'Technical', 'Casual'
  final bool isOverEnd;
  final int? overRuns;

  const AiCommentaryContext({
    required this.batsman,
    required this.bowler,
    this.runs = 0,
    this.extraType = 'None',
    this.extraRuns = 0,
    this.isWicket = false,
    this.wicketType = 'None',
    this.currentOvers = 0.0,
    this.totalRuns = 0,
    this.totalWickets = 0,
    this.target,
    this.style = 'Hype / Energetic',
    this.isOverEnd = false,
    this.overRuns,
  });
}

class AiCommentaryGenerator {
  static final Random _rng = Random();

  static String _pick(List<String> list) => list[_rng.nextInt(list.length)];

  /// Generate smart contextual commentary for a ball event or over finish
  static String generate(AiCommentaryContext ctx) {
    final style = ctx.style.toLowerCase();
    final isHype = style.contains('hype') || style.contains('excited');
    final isTechnical = style.contains('tech');
    final isCasual = style.contains('casual');

    final oversInt = ctx.currentOvers.toInt();
    final ballsInOver = ((ctx.currentOvers - oversInt) * 10).round();
    final ballNumberStr = ballsInOver > 0 ? 'ball $ballsInOver' : 'over finish';
    final scoreStr = '${ctx.totalRuns}/${ctx.totalWickets}';

    // 1. Over Ending Commentary
    if (ctx.isOverEnd) {
      return _generateOverEndCommentary(ctx, isHype, isTechnical, scoreStr);
    }

    // 2. Wicket Commentary
    if (ctx.isWicket) {
      return _generateWicketCommentary(ctx, isHype, isTechnical, isCasual, ballNumberStr, scoreStr);
    }

    // 3. Extras Commentary
    if (ctx.extraType == 'Wide') {
      return _generateWideCommentary(ctx, isHype, isTechnical);
    }
    if (ctx.extraType == 'No Ball') {
      return _generateNoBallCommentary(ctx, isHype, isTechnical);
    }

    // 4. Six Commentary
    if (ctx.runs == 6) {
      return _generateSixCommentary(ctx, isHype, isTechnical, isCasual, ballNumberStr, scoreStr);
    }

    // 5. Four Commentary
    if (ctx.runs == 4) {
      return _generateFourCommentary(ctx, isHype, isTechnical, isCasual, ballNumberStr, scoreStr);
    }

    // 6. Dot Ball Commentary
    if (ctx.runs == 0) {
      return _generateDotCommentary(ctx, isHype, isTechnical, ballNumberStr);
    }

    // 7. Running between wickets (1, 2, 3 runs)
    return _generateRunCommentary(ctx, isHype, isTechnical, ballNumberStr, scoreStr);
  }

  static String _generateOverEndCommentary(AiCommentaryContext ctx, bool isHype, bool isTech, String scoreStr) {
    final overNum = ctx.currentOvers.toInt();
    final overRunsText = ctx.overRuns != null ? '${ctx.overRuns} runs off it' : 'a tidy over';
    
    if (isHype) {
      final tpls = [
        "End of Over $overNum! Score is $scoreStr. $overRunsText from ${ctx.bowler}. The atmosphere in the stadium is electric!",
        "Over $overNum finished on $scoreStr! Great contest between ${ctx.bowler} and the batters. Total moves along briskly.",
        "That wraps up Over $overNum! $scoreStr on the board with $overRunsText. We are set for a nail-biting finish!",
      ];
      return _pick(tpls);
    } else if (isTech) {
      final tpls = [
        "Over $overNum complete. Score stands at $scoreStr ($overRunsText). ${ctx.bowler} varied their pace well to maintain fielding discipline.",
        "End of the ${overNum}th over. $scoreStr on the scoreboard. The bowling side rotating lengths to restrict boundary options.",
      ];
      return _pick(tpls);
    } else {
      final tpls = [
        "Over $overNum concludes. Score advances to $scoreStr. $overRunsText conceded by ${ctx.bowler}.",
        "Over finished on $scoreStr after $overNum overs. A solid spell underway from ${ctx.bowler}.",
      ];
      return _pick(tpls);
    }
  }

  static String _generateWicketCommentary(AiCommentaryContext ctx, bool isHype, bool isTech, bool isCasual, String ballStr, String scoreStr) {
    final wType = ctx.wicketType;

    if (wType == 'Bowled') {
      if (isHype) {
        return _pick([
          "BOWLED HIM! Clean through the gate! ${ctx.bowler} knocks back middle stump on $ballStr! ${ctx.batsman} is gone and score is $scoreStr!",
          "TIMBERRR! Absolute jaffa from ${ctx.bowler}! Shatters the stumps, sending the bails flying into orbit!",
          "WHAT A DELIVERY! ${ctx.bowler} uproots the off-stump! ${ctx.batsman} had no answer to that 145 clicks thunderbolt!",
        ]);
      }
      return "OUT! Bowled! ${ctx.bowler} penetrates ${ctx.batsman}'s defense with a sharp in-swinger, crashing into the stumps. Score $scoreStr.";
    }

    if (wType == 'Caught') {
      if (isHype) {
        return _pick([
          "CAUGHT! In the air... and taken safely! ${ctx.batsman} miscues the pull shot off ${ctx.bowler} on $ballStr! Huge breakthrough!",
          "WHAT A CATCH! Fielder dives full length at backward point to grab a stunner off ${ctx.bowler}! ${ctx.batsman} has to walk back at $scoreStr!",
          "GONE! Top edge flies high into the night sky... settled underneath and caught calmly by the fielder at deep square leg!",
        ]);
      }
      return "WICKET! Caught! ${ctx.batsman} tries to go over mid-off against ${ctx.bowler} but finds the fielder directly. Score drops to $scoreStr.";
    }

    if (wType == 'LBW') {
      if (isHype) {
        return _pick([
          "HUGE SHOUT FOR LBW! The finger goes straight up! ${ctx.bowler} traps ${ctx.batsman} plumb in front on $ballStr! Score is $scoreStr!",
          "DEAD PLUMB! ${ctx.bowler} hits the front pad on the knee roll! Umpire raises the finger without hesitation!",
        ]);
      }
      return "OUT! LBW! Rapid yorker from ${ctx.bowler} beats the inside edge and strikes ${ctx.batsman} on the pads. Score $scoreStr.";
    }

    if (wType == 'Run Out') {
      return _pick([
        "RUN OUT! DIRECT HIT! Fielder fires at the striker's end and catches ${ctx.batsman} inches short of the crease! Total $scoreStr!",
        "DISASTER RUN OUT! Hesitation between the wickets, throw comes in flat and the bails are whipped off! ${ctx.batsman} is out!",
      ]);
    }

    // Default wicket
    if (isHype) {
      return "OUT! Massive breakthrough for ${ctx.bowler}! ${ctx.batsman} departs on $ballStr as score reads $scoreStr!";
    }
    return "WICKET! ${ctx.bowler} strikes to remove ${ctx.batsman}. Crucial blow to the batting team, score is $scoreStr.";
  }

  static String _generateSixCommentary(AiCommentaryContext ctx, bool isHype, bool isTech, bool isCasual, String ballStr, String scoreStr) {
    if (isHype) {
      final tpls = [
        "SIX! MASSIVE HIT! ${ctx.batsman} steps out on $ballStr and launches ${ctx.bowler} 95 meters into the top tier! Score moves to $scoreStr!",
        "THAT IS MONSTROUS! ${ctx.batsman} reads the slower ball and deposits ${ctx.bowler} over long-on for a huge maximum!",
        "INTO THE CROWD! Pure timing and muscle from ${ctx.batsman}! Dispatches ${ctx.bowler} straight back over bowler's head for SIX!",
        "BOOM! What a sensational stroke on $ballStr! ${ctx.batsman} pulls ${ctx.bowler} effortlessly over deep square leg for SIX! Score $scoreStr!",
      ];
      return _pick(tpls);
    } else if (isTech) {
      final tpls = [
        "SIX! Picked up beautifully from length. ${ctx.batsman} transfers weight quickly onto backfoot and lofts ${ctx.bowler} over deep mid-wicket.",
        "MAXIMUM! Superb bat speed from ${ctx.batsman}. Meets the ball on the rise, clearing the long-off boundary with perfection.",
      ];
      return _pick(tpls);
    } else {
      final tpls = [
        "SIX! High, handsome and into the grandstand! ${ctx.batsman} clears the ropes with ease against ${ctx.bowler}. Score is $scoreStr.",
        "Huge six on $ballStr! ${ctx.batsman} unleashes a towering hit off ${ctx.bowler} to lift the total to $scoreStr.",
      ];
      return _pick(tpls);
    }
  }

  static String _generateFourCommentary(AiCommentaryContext ctx, bool isHype, bool isTech, bool isCasual, String ballStr, String scoreStr) {
    if (isHype) {
      final tpls = [
        "FOUR! GLORIOUS COVER DRIVE! ${ctx.batsman} leans into the half-volley from ${ctx.bowler} and pierces the gap for four! Score $scoreStr!",
        "CRACKING SHOT! Short and wide from ${ctx.bowler}, ${ctx.batsman} punishes it with a blistering cut to the point boundary!",
        "FOUR RUNS! Delicious wrist-work on $ballStr! ${ctx.batsman} flicks ${ctx.bowler} past mid-wicket and it races to the rope!",
        "BOUNDARY! Audacious ramp shot over short third man! ${ctx.batsman} outfoxes ${ctx.bowler} for four valuable runs!",
      ];
      return _pick(tpls);
    } else if (isTech) {
      final tpls = [
        "FOUR! Text-book cover drive. Head over the ball, high elbow, and ${ctx.batsman} finds the gap between cover and mid-off with precision.",
        "BOUNDARY! ${ctx.batsman} rides the bounce effectively off ${ctx.bowler}, opening the face of the bat to beat backward point.",
      ];
      return _pick(tpls);
    } else {
      final tpls = [
        "FOUR! Nicely timed by ${ctx.batsman}. Beats the chasing fielder and trickles into the boundary fence. Score $scoreStr.",
        "Four runs on $ballStr. ${ctx.batsman} drives ${ctx.bowler} smoothly through the covers.",
      ];
      return _pick(tpls);
    }
  }

  static String _generateDotCommentary(AiCommentaryContext ctx, bool isHype, bool isTech, String ballStr) {
    if (isHype) {
      final tpls = [
        "Dot ball! Fierce 142 km/h bouncer from ${ctx.bowler}! ${ctx.batsman} ducks under it just in time on $ballStr!",
        "Beaten all ends up! Sharp away swing from ${ctx.bowler} whizzes past ${ctx.batsman}'s outside edge! Brilliant bowling!",
        "No run! Pushed straight to extra cover. Fielder attacks the ball with great agility to prevent the single.",
      ];
      return _pick(tpls);
    } else if (isTech) {
      final tpls = [
        "Dot ball. Good length delivery on the corridor of uncertainty. ${ctx.batsman} defends solidly off the front foot to ${ctx.bowler}.",
        "No run. ${ctx.bowler} hits the seam on a good length, generating steep bounce to cramp ${ctx.batsman}.",
      ];
      return _pick(tpls);
    } else {
      final tpls = [
        "Dot ball on $ballStr. Defended gently back down the pitch to ${ctx.bowler}.",
        "No run conceded. ${ctx.bowler} keeps it tight outside off stump.",
      ];
      return _pick(tpls);
    }
  }

  static String _generateRunCommentary(AiCommentaryContext ctx, bool isHype, bool isTech, String ballStr, String scoreStr) {
    final r = ctx.runs;
    if (r == 1) {
      final tpls = [
        "Single taken on $ballStr. ${ctx.batsman} pushes ${ctx.bowler} towards long-off to rotate the strike. Score $scoreStr.",
        "One run. Worked away gently towards deep square leg by ${ctx.batsman}. Good running between the wickets.",
        "Quick single! Tapped to mid-on, sharp call from ${ctx.batsman} and they scramble home comfortably. Total $scoreStr.",
      ];
      return _pick(tpls);
    }
    if (r == 2) {
      final tpls = [
        "Two runs! Driven into the deep extra cover pocket, swift turn by ${ctx.batsman} to steal a second run! Score $scoreStr.",
        "Couple of runs on $ballStr. Clipped off the pads into the deep mid-wicket vacant area.",
      ];
      return _pick(tpls);
    }
    return "$r runs scored on $ballStr. Excellent athletic running between wickets by ${ctx.batsman}. Score reaches $scoreStr.";
  }

  static String _generateWideCommentary(AiCommentaryContext ctx, bool isHype, bool isTech) {
    return _pick([
      "Wide ball! ${ctx.bowler} sprays it down the leg side beyond the tramline. Extra run added to the scoreboard.",
      "Wide called by the umpire! ${ctx.bowler} loses radar outside off stump. Free run to the batting team.",
    ]);
  }

  static String _generateNoBallCommentary(AiCommentaryContext ctx, bool isHype, bool isTech) {
    if (isHype) {
      return "NO BALL! ${ctx.bowler} oversteps the crease! That's an extra run and a FREE HIT for ${ctx.batsman} on the next delivery!";
    }
    return "No ball signaled! Overstepping from ${ctx.bowler}. Penalty run awarded and Free Hit coming up!";
  }

  /// Helper to convert simple natural language prompt or match state into rich broadcast commentary
  static String formatCustomCommentary(String rawText, {String style = 'Hype / Energetic'}) {
    final clean = rawText.trim();
    if (clean.isEmpty) return "Welcome to CricketVerse live commentary!";
    
    // If it's already well-formatted commentary, return it
    if (clean.length > 50 && (clean.contains('!') || clean.contains('.'))) {
      return clean;
    }

    // Enhance short inputs
    if (clean.toLowerCase().contains('six') || clean.toLowerCase().contains('6')) {
      return "SIX! $clean! What an extraordinary blow into the stands!";
    }
    if (clean.toLowerCase().contains('four') || clean.toLowerCase().contains('boundary') || clean.toLowerCase().contains('4')) {
      return "FOUR! $clean! Timed to perfection, racing across the outfield!";
    }
    if (clean.toLowerCase().contains('wicket') || clean.toLowerCase().contains('out') || clean.toLowerCase().contains('bowled')) {
      return "OUT! $clean! A huge moment in the match that changes the complexion of the game!";
    }
    if (clean.toLowerCase().contains('over finish') || clean.toLowerCase().contains('over complete')) {
      return "End of the over! $clean. The game is poised on a knife-edge!";
    }

    return "Live update: $clean. An engaging contest between bat and ball!";
  }
}
