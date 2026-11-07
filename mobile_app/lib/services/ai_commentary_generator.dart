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
  final String? dismissedBatsman;
  final String? incomingBatsman;
  final bool isAllOut;
  final int? strikerRuns;
  final int? bowlerWickets;

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
    this.dismissedBatsman,
    this.incomingBatsman,
    this.isAllOut = false,
    this.strikerRuns,
    this.bowlerWickets,
  });
}

class AiCommentaryGenerator {
  static final Random _rng = Random();

  static String _pick(List<String> list) => list[_rng.nextInt(list.length)];

  /// Sanitizer to completely eliminate any unwanted fielding position or batsman shot type descriptions
  static String sanitize(String raw) {
    if (raw.isEmpty) return '';
    String text = raw;

    final replacements = <MapEntry<RegExp, String>>[
      // Specific multi-word shot types
      MapEntry(RegExp(r'\b(cover|straight|square|on|off|lofted)\s+drives?\b', caseSensitive: false), 'clean hit'),
      MapEntry(RegExp(r'\b(pull|hook|cut|sweep|ramp|scoop)\s+shots?\b', caseSensitive: false), 'clean hit'),
      MapEntry(RegExp(r'\b(ramp|paddle)\s+strokes?\b', caseSensitive: false), 'clean hit'),
      MapEntry(RegExp(r'\b(late|square|upper)\s+cuts?\b', caseSensitive: false), 'boundary'),
      MapEntry(RegExp(r'\b(reverse|paddle|slog)\s+sweeps?\b', caseSensitive: false), 'clean hit'),
      MapEntry(RegExp(r'\b(outside|inside)\s+edges?\b', caseSensitive: false), 'delivery'),
      MapEntry(RegExp(r'\bleg\s+glances?\b', caseSensitive: false), 'run'),
      MapEntry(RegExp(r'\b(forward|backfoot)\s+defensive\b', caseSensitive: false), 'delivery'),
      MapEntry(RegExp(r'\bleans?\s+into\s+the\s+half[- ]volley\b', caseSensitive: false), 'connects cleanly'),
      MapEntry(RegExp(r'\bhalf[- ]volley\b', caseSensitive: false), 'delivery'),
      MapEntry(RegExp(r'\b(steps?\s+out|dances?\s+down|charges?\s+down)\b', caseSensitive: false), 'shows intent'),
      MapEntry(RegExp(r'\b(blistering|sharp)\s+cuts?\b', caseSensitive: false), 'strike'),
      MapEntry(RegExp(r'\baudacious\s+ramp\s+stroke\b', caseSensitive: false), 'quick thinking'),
      // Single-word shot types
      MapEntry(RegExp(r'\b(drives?|driven|driving)\b', caseSensitive: false), 'hits'),
      MapEntry(RegExp(r'\b(pulled|pulls?|pulling)\b', caseSensitive: false), 'hit'),
      MapEntry(RegExp(r'\b(hooked|hooks?|hooking)\b', caseSensitive: false), 'hit'),
      MapEntry(RegExp(r'\b(cuts?|cutting)\b', caseSensitive: false), 'hit'),
      MapEntry(RegExp(r'\b(flicks?|flicked|flicking)\b', caseSensitive: false), 'places it'),
      MapEntry(RegExp(r'\b(sweeps?|swept|sweeping)\b', caseSensitive: false), 'hit'),
      MapEntry(RegExp(r'\b(ramps?|ramped|ramping)\b', caseSensitive: false), 'hit'),
      MapEntry(RegExp(r'\b(scoops?|scooped|scooping)\b', caseSensitive: false), 'hit'),
      MapEntry(RegExp(r'\b(lofts?|lofted|lofting)\b', caseSensitive: false), 'hits'),
      MapEntry(RegExp(r'\b(punches?|punched|punching)\b', caseSensitive: false), 'works it'),
      MapEntry(RegExp(r'\b(pushes?|pushed|pushing)\b', caseSensitive: false), 'works it'),
      MapEntry(RegExp(r'\b(glides?|glided|gliding)\b', caseSensitive: false), 'guides it'),
      MapEntry(RegExp(r'\b(glances?|glanced|glancing)\b', caseSensitive: false), 'works it'),
      MapEntry(RegExp(r'\b(clips?|clipped|clipping)\b', caseSensitive: false), 'works it'),
      MapEntry(RegExp(r'\b(dabs?|dabbed|dabbing)\b', caseSensitive: false), 'plays it'),
      MapEntry(RegExp(r'\b(slashes?|slashed|slashing)\b', caseSensitive: false), 'hits'),
      MapEntry(RegExp(r'\b(slogs?|slogged|slogging)\b', caseSensitive: false), 'hits'),
      MapEntry(RegExp(r'\b(steers?|steered|steering)\b', caseSensitive: false), 'directs it'),
      MapEntry(RegExp(r'\b(defends?|defended|defending|defensive)\b', caseSensitive: false), 'plays'),
      MapEntry(RegExp(r'\b(blocks?|blocked|blocking)\b', caseSensitive: false), 'plays'),
      MapEntry(RegExp(r'\b(edges?|edged|edging)\b', caseSensitive: false), 'delivery'),
      // Fielding positions
      MapEntry(RegExp(r'\b(towards|to|through|past|over|in)\s+the\s+covers\b', caseSensitive: false), 'through the gap'),
      MapEntry(RegExp(r'\bthrough\s+the\s+covers\b', caseSensitive: false), 'through the gap'),
      MapEntry(RegExp(r'\bcover\s+drive\b', caseSensitive: false), 'clean hit'),
      MapEntry(RegExp(r'\bextra\s+cover\b', caseSensitive: false), 'the outfield gap'),
      MapEntry(RegExp(r'\bcovers?\b', caseSensitive: false), 'the gap'),
      MapEntry(RegExp(r'\bdeep\s+mid[- ]wicket\b', caseSensitive: false), 'the boundary'),
      MapEntry(RegExp(r'\bmid[- ]wicket\b', caseSensitive: false), 'the outfield'),
      MapEntry(RegExp(r'\bbackward\s+point\b', caseSensitive: false), 'the infield'),
      MapEntry(RegExp(r'\bdeep\s+point\b', caseSensitive: false), 'the fence'),
      MapEntry(RegExp(r'\bpoint\s+boundary\b', caseSensitive: false), 'boundary'),
      MapEntry(RegExp(r'\bpoint\b', caseSensitive: false), 'the gap'),
      MapEntry(RegExp(r'\bdeep\s+square[- ]leg\b', caseSensitive: false), 'the boundary rope'),
      MapEntry(RegExp(r'\bsquare[- ]leg\b', caseSensitive: false), 'the boundary'),
      MapEntry(RegExp(r'\bshort\s+fine[- ]leg\b', caseSensitive: false), 'the infield'),
      MapEntry(RegExp(r'\bfine[- ]leg\b', caseSensitive: false), 'the boundary fence'),
      MapEntry(RegExp(r'\bshort\s+third[- ]man\b', caseSensitive: false), 'the infield'),
      MapEntry(RegExp(r'\bthird[- ]man\b', caseSensitive: false), 'the boundary rope'),
      MapEntry(RegExp(r'\blong[- ]on\b', caseSensitive: false), 'the boundary ropes'),
      MapEntry(RegExp(r'\blong[- ]off\b', caseSensitive: false), 'down the ground'),
      MapEntry(RegExp(r'\bmid[- ]off\b', caseSensitive: false), 'the infield'),
      MapEntry(RegExp(r'\bmid[- ]on\b', caseSensitive: false), 'the infield'),
      MapEntry(RegExp(r'\bdown\s+the\s+leg\s+side\b', caseSensitive: false), 'wide outside the line'),
      MapEntry(RegExp(r'\bleg\s+side\b', caseSensitive: false), 'wide of the pads'),
      MapEntry(RegExp(r'\boff\s+side\b', caseSensitive: false), 'outside the corridor'),
      MapEntry(RegExp(r'\bcow[- ]corner\b', caseSensitive: false), 'the stands'),
      MapEntry(RegExp(r'\bdeep\s+backward\s+square\b', caseSensitive: false), 'the boundary'),
    ];

    for (final entry in replacements) {
      text = text.replaceAll(entry.key, entry.value);
    }

    return text.replaceAll(RegExp(r'\s{2,}'), ' ').trim();
  }

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
      return sanitize(_generateOverEndCommentary(ctx, isHype, isTechnical, scoreStr));
    }

    // 2. Wicket Commentary
    if (ctx.isWicket) {
      return sanitize(_generateWicketCommentary(ctx, isHype, isTechnical, isCasual, ballNumberStr, scoreStr));
    }

    // 3. Extras Commentary
    if (ctx.extraType == 'Wide') {
      return sanitize(_generateWideCommentary(ctx, isHype, isTechnical));
    }
    if (ctx.extraType == 'No Ball') {
      return sanitize(_generateNoBallCommentary(ctx, isHype, isTechnical));
    }

    // 4. Milestone Check (50s / 100s)
    if (ctx.strikerRuns != null) {
      if (ctx.strikerRuns == 50 || (ctx.strikerRuns! >= 50 && ctx.strikerRuns! - ctx.runs < 50)) {
        return sanitize("FIFTY! A magnificent half-century for ${ctx.batsman}! Reaches 50 with composure and authority, raising the bat to warm applause! Total $scoreStr.");
      }
      if (ctx.strikerRuns == 100 || (ctx.strikerRuns! >= 100 && ctx.strikerRuns! - ctx.runs < 100)) {
        return sanitize("A SENSATIONAL HUNDRED! A masterclass century from ${ctx.batsman}! Takes off the helmet to salute a standing ovation from the crowd! Total $scoreStr.");
      }
    }

    // 5. Six Commentary
    if (ctx.runs == 6) {
      return sanitize(_generateSixCommentary(ctx, isHype, isTechnical, isCasual, ballNumberStr, scoreStr));
    }

    // 6. Four Commentary
    if (ctx.runs == 4) {
      return sanitize(_generateFourCommentary(ctx, isHype, isTechnical, isCasual, ballNumberStr, scoreStr));
    }

    // 7. Dot Ball Commentary
    if (ctx.runs == 0) {
      return sanitize(_generateDotCommentary(ctx, isHype, isTechnical, ballNumberStr));
    }

    // 8. Running between wickets (1, 2, 3 runs)
    return sanitize(_generateRunCommentary(ctx, isHype, isTechnical, ballNumberStr, scoreStr));
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
    final outBatter = (ctx.dismissedBatsman != null && ctx.dismissedBatsman!.trim().isNotEmpty)
        ? ctx.dismissedBatsman!.trim()
        : ctx.batsman;
    final hasIncoming = ctx.incomingBatsman != null && ctx.incomingBatsman!.trim().isNotEmpty && !ctx.isAllOut;
    final newBatter = ctx.incomingBatsman?.trim() ?? '';

    if (hasIncoming) {
      if (wType == 'Bowled') {
        final tpls = [
          "BOWLED HIM! Clean through the gate! ${ctx.bowler} shatters the stumps to dismiss $outBatter! $newBatter walks in as the new batsman. Score $scoreStr.",
          "TIMBERRR! Absolute jaffa from ${ctx.bowler}! $outBatter has been cleaned up. $newBatter comes to the crease. Total $scoreStr.",
          "WHAT A DELIVERY! ${ctx.bowler} knocks back middle stump! $outBatter departs, and $newBatter arrives at the crease.",
        ];
        return _pick(tpls);
      }

      if (wType == 'Caught') {
        final tpls = [
          "CAUGHT! High in the air and taken safely! ${ctx.bowler} gets the breakthrough as $outBatter departs. $newBatter walks in as the new batsman. Score $scoreStr.",
          "WHAT A CATCH! Sensational grab to dismiss $outBatter off the bowling of ${ctx.bowler}! $newBatter comes to the crease.",
          "OUT! $outBatter mistimes it and is caught! Tremendous bowling from ${ctx.bowler}. $newBatter is the new batsman.",
        ];
        return _pick(tpls);
      }

      if (wType == 'LBW') {
        final tpls = [
          "LBW! Huge shout from ${ctx.bowler}, and the umpire's finger goes straight up! $outBatter is trapped right in front. $newBatter comes to the crease. Score $scoreStr.",
          "DEAD PLUMB! ${ctx.bowler} strikes the front pad and $outBatter must depart! $newBatter walks in as the new batsman.",
          "OUT! Trapped right in front of the stumps! $outBatter is given out LBW to ${ctx.bowler}. $newBatter walks in as the next batter.",
        ];
        return _pick(tpls);
      }

      if (wType == 'Run Out') {
        final tpls = [
          "RUN OUT! DIRECT HIT! Fantastic throw and $outBatter is caught short of the crease! $newBatter walks in as the new batsman. Score $scoreStr.",
          "DISASTER RUN OUT! Terrible mix-up between the wickets, and $outBatter is dismissed! $newBatter comes to the crease.",
        ];
        return _pick(tpls);
      }

      if (wType == 'Stumped') {
        final tpls = [
          "STUMPED! Beaten in flight by ${ctx.bowler}, lightning-fast glovework whips off the bails! $outBatter departs and $newBatter is the new batsman. Score $scoreStr.",
          "OUT! Dragged his foot out and the bails are off in a flash! $outBatter is stumped off ${ctx.bowler}. $newBatter comes to the middle.",
        ];
        return _pick(tpls);
      }

      final tpls = [
        "WICKET! $outBatter is OUT! ${ctx.bowler} strikes with precision. $newBatter walks in as the new batsman. Score $scoreStr.",
        "What a breakthrough! $outBatter departs off ${ctx.bowler}'s bowling, and $newBatter comes to the crease.",
        "WICKET! $outBatter has been dismissed. $newBatter is the new batsman. Total $scoreStr.",
      ];
      return _pick(tpls);
    } else if (ctx.isAllOut) {
      final tpls = [
        "WICKET AND ALL OUT! ${ctx.bowler} dismisses $outBatter! That is the final wicket and the batting side is all out. Score $scoreStr.",
        "INNINGS WRAPPED UP! $outBatter departs to ${ctx.bowler}! The innings folds as all wickets have fallen. Total $scoreStr.",
        "BOWLED OUT! ${ctx.bowler} claims $outBatter for the final wicket! Innings closed at $scoreStr.",
      ];
      return _pick(tpls);
    }

    // Graceful fallback when incoming batsman is not yet known without inventing generic names
    final tpls = [
      "WICKET! $outBatter is OUT! ${ctx.bowler} strikes at a crucial moment in the match. Score $scoreStr.",
      "What a breakthrough! $outBatter departs to a brilliant delivery from ${ctx.bowler}.",
      "WICKET! $outBatter has been dismissed! Clinical bowling by ${ctx.bowler}. Score $scoreStr.",
    ];
    return _pick(tpls);
  }

  static String _generateSixCommentary(AiCommentaryContext ctx, bool isHype, bool isTech, bool isCasual, String ballStr, String scoreStr) {
    if (isHype) {
      final tpls = [
        "SIX! MASSIVE HIT! ${ctx.batsman} connects powerfully on $ballStr and launches ${ctx.bowler} 95 meters into the top tier! Score moves to $scoreStr!",
        "THAT IS MONSTROUS! ${ctx.batsman} reads the delivery and deposits ${ctx.bowler} high into the stands for a huge maximum!",
        "INTO THE CROWD! Pure timing and muscle from ${ctx.batsman}! Dispatches ${ctx.bowler} straight back over bowler's head for SIX!",
        "BOOM! What a sensational hit on $ballStr! ${ctx.batsman} connects cleanly off ${ctx.bowler} and clears the boundary rope with ease! Score $scoreStr!",
        "MONSTROUS HIT! ${ctx.batsman} connects with ferocious power, sending the ball soaring high into the grandstand!",
      ];
      return _pick(tpls);
    } else if (isTech) {
      final tpls = [
        "SIX! Clean strike from length. ${ctx.batsman} connects cleanly and sends ${ctx.bowler} over the boundary.",
        "MAXIMUM! Superb bat speed from ${ctx.batsman}. Meets the ball on the rise, clearing the ropes with perfection.",
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
        "FOUR! GLORIOUS BOUNDARY! ${ctx.batsman} connects cleanly off ${ctx.bowler} and pierces the boundary gap for four! Score $scoreStr!",
        "CRACKING BOUNDARY! Short and wide from ${ctx.bowler}, ${ctx.batsman} punishes it with blistering power to the fence! Score $scoreStr!",
        "FOUR RUNS! Delicious timing on $ballStr! ${ctx.batsman} sends ${ctx.bowler} through the gap with supreme precision and it races to the rope!",
        "BOUNDARY! Pure precision! ${ctx.batsman} outfoxes ${ctx.bowler} for four valuable runs! Score $scoreStr!",
        "FOUR! Superb balance and intent from ${ctx.batsman}, beating the infield to find the fence!",
      ];
      return _pick(tpls);
    } else if (isTech) {
      final tpls = [
        "FOUR! Textbook timing! Head over the ball, and ${ctx.batsman} finds the outfield gap with precision.",
        "BOUNDARY! ${ctx.batsman} rides the bounce effectively off ${ctx.bowler}, beating the fielders to the rope.",
      ];
      return _pick(tpls);
    } else {
      final tpls = [
        "FOUR! Nicely timed by ${ctx.batsman}. Beats the chasing fielder and trickles into the boundary fence. Score $scoreStr.",
        "Four runs on $ballStr. ${ctx.batsman} times ${ctx.bowler} smoothly into the gap for four.",
      ];
      return _pick(tpls);
    }
  }

  static String _generateDotCommentary(AiCommentaryContext ctx, bool isHype, bool isTech, String ballStr) {
    if (isHype) {
      final tpls = [
        "Dot ball! Fast delivery from ${ctx.bowler}! No run conceded on $ballStr!",
        "Beaten! Sharp delivery from ${ctx.bowler} whizzes past the bat of ${ctx.batsman}! Brilliant bowling!",
        "No run! Played with soft hands by ${ctx.batsman}. Fielder attacks the ball with great agility to prevent the single.",
      ];
      return _pick(tpls);
    } else if (isTech) {
      final tpls = [
        "Dot ball. Good length delivery on a tight line. Solid response from ${ctx.batsman} back to ${ctx.bowler}.",
        "No run. ${ctx.bowler} hits the seam on a good length, generating steep bounce to challenge ${ctx.batsman}.",
      ];
      return _pick(tpls);
    } else {
      final tpls = [
        "Dot ball on $ballStr. Played gently back down the pitch to ${ctx.bowler}. No run.",
        "No run conceded. ${ctx.bowler} keeps it tight and disciplined.",
      ];
      return _pick(tpls);
    }
  }

  static String _generateRunCommentary(AiCommentaryContext ctx, bool isHype, bool isTech, String ballStr, String scoreStr) {
    final r = ctx.runs;
    if (r == 1) {
      final tpls = [
        "Single taken on $ballStr. ${ctx.batsman} works ${ctx.bowler} into the gap to rotate the strike. Score $scoreStr.",
        "One run. Worked away gently with soft hands by ${ctx.batsman}. Good running between the wickets.",
        "Quick single! Crisp placement into the gap, sharp call from ${ctx.batsman} and they scamper through safely. Total $scoreStr.",
        "Smart cricket! ${ctx.batsman} works it into the vacant space and sprints across for a single.",
      ];
      return _pick(tpls);
    }
    if (r == 2) {
      final tpls = [
        "Two runs! Placed firmly into the outfield gap, swift turn by ${ctx.batsman} to take a second run! Score $scoreStr.",
        "Couple of runs on $ballStr. Worked into the vacant outfield area with aggressive running by ${ctx.batsman}.",
      ];
      return _pick(tpls);
    }
    if (r == 3) {
      return "Three runs! Magnificent athletic running between the wickets by ${ctx.batsman}, putting pressure on the fielding unit! Score reaches $scoreStr.";
    }
    return "$r runs scored on $ballStr. Excellent athletic running between wickets by ${ctx.batsman}. Score reaches $scoreStr.";
  }

  static String _generateWideCommentary(AiCommentaryContext ctx, bool isHype, bool isTech) {
    return _pick([
      "Wide ball! ${ctx.bowler} sprays it beyond the tramline. Extra run added to the scoreboard.",
      "Wide called by the umpire! ${ctx.bowler} loses radar. Free run conceded to the batting team.",
      "Wide delivery! Ball strays wide of the line, extra run added to the total.",
    ]);
  }

  static String _generateNoBallCommentary(AiCommentaryContext ctx, bool isHype, bool isTech) {
    if (isHype) {
      return "NO BALL! ${ctx.bowler} oversteps the crease! That's an extra run and a FREE HIT for ${ctx.batsman} on the next delivery!";
    }
    return "No ball signaled! Overstepping from ${ctx.bowler}. Penalty run awarded and Free Hit coming up!";
  }

  /// Generate official full match result commentary
  static String generateMatchResultCommentary({
    required String winnerName,
    required String loserName,
    required int winnerRuns,
    required int winnerWickets,
    required int loserRuns,
    required int loserWickets,
    required bool isWinByWickets,
    required int margin,
    int? target,
    bool isTied = false,
    bool isAbandoned = false,
  }) {
    if (isAbandoned) {
      return "The match has been abandoned. No result.";
    }
    if (isTied) {
      return "What a thrilling contest! Both teams finished with the same score. The match ends in a tie. $winnerName scored $winnerRuns/$winnerWickets, while $loserName finished at $loserRuns/$loserWickets.";
    }

    if (isWinByWickets) {
      final targetStr = target != null && target > 0 ? ", successfully chasing the target of $target runs" : "";
      final wMargin = margin.clamp(1, 10);
      return "${winnerName.toUpperCase()} WIN! $winnerName have defeated $loserName by $wMargin wicket${wMargin == 1 ? '' : 's'}$targetStr. $winnerName finished at $winnerRuns/$winnerWickets, while $loserName scored $loserRuns/$loserWickets. A brilliant run chase!";
    } else {
      return "${winnerName.toUpperCase()} WIN! $winnerName have defeated $loserName by $margin run${margin == 1 ? '' : 's'}. $winnerName scored $winnerRuns/$winnerWickets, while $loserName finished at $loserRuns/$loserWickets. A brilliant performance from $winnerName!";
    }
  }

  /// Helper to convert simple natural language prompt or match state into rich broadcast commentary
  static String formatCustomCommentary(String rawText, {String style = 'Hype / Energetic'}) {
    final clean = sanitize(rawText.trim());
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
