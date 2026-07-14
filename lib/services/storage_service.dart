import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class StorageService with ChangeNotifier {
  SharedPreferences? _prefs;
  List<Team> _teams = [];
  List<CricketMatch> _matches = [];
  Map<String, String> _users = {}; // Email -> Password
  
  // App Session State
  String? _currentUserEmail;
  String? _currentRole; // "Admin", "Scorer", "User", "Guest"
  String? _activeScorerMatchId; // If Scorer is logged in, this is their active match

  List<Team> get teams => _teams;
  List<CricketMatch> get matches => _matches;
  String? get currentRole => _currentRole;
  String? get currentUserEmail => _currentUserEmail;
  String? get activeScorerMatchId => _activeScorerMatchId;

  StorageService() {
    _initStorage();
  }

  Future<void> _initStorage() async {
    _prefs = await SharedPreferences.getInstance();
    _loadData();
  }

  void _loadData() {
    // 1. Load users
    final usersJson = _prefs?.getString('users');
    if (usersJson != null) {
      final Map<String, dynamic> decoded = jsonDecode(usersJson);
      _users = decoded.map((key, value) => MapEntry(key, value.toString()));
    } else {
      // Default User
      _users['user@gmail.com'] = 'user123';
      _users['alex@gmail.com'] = 'alex123';
      _saveUsers();
    }

    // 2. Load Teams
    final teamsJson = _prefs?.getString('teams');
    if (teamsJson != null) {
      final List decoded = jsonDecode(teamsJson);
      _teams = decoded.map((item) => Team.fromJson(item)).toList();
    } else {
      _loadDefaultTeams();
    }

    // 3. Load Matches
    final matchesJson = _prefs?.getString('matches');
    if (matchesJson != null) {
      final List decoded = jsonDecode(matchesJson);
      _matches = decoded.map((item) => CricketMatch.fromJson(item)).toList();
    } else {
      _loadDefaultMatches();
    }

    notifyListeners();
  }

  void _saveUsers() {
    _prefs?.setString('users', jsonEncode(_users));
  }

  void _saveTeams() {
    _prefs?.setString('teams', jsonEncode(_teams.map((t) => t.toJson()).toList()));
  }

  void _saveMatches() {
    _prefs?.setString('matches', jsonEncode(_matches.map((m) => m.toJson()).toList()));
  }

  // Preload default teams and players matching the screenshots
  void _loadDefaultTeams() {
    final teamIndiaPlayers = [
      Player(id: 'v_kohli', name: 'V. Kohli', role: 'Batter', nationality: 'IND', runsScored: 2450, ballsFaced: 1800, wicketsTaken: 4, matchesPlayed: 115),
      Player(id: 's_yadav', name: 'S. Yadav', role: 'Batter', nationality: 'IND', runsScored: 1850, ballsFaced: 1100, wicketsTaken: 0, matchesPlayed: 60),
      Player(id: 'r_sharma', name: 'R. Sharma', role: 'Batter', nationality: 'IND', runsScored: 3100, ballsFaced: 2200, wicketsTaken: 2, matchesPlayed: 148),
      Player(id: 'h_pandya', name: 'H. Pandya', role: 'All-rounder', nationality: 'IND', runsScored: 1200, ballsFaced: 900, wicketsTaken: 73, matchesPlayed: 85),
      Player(id: 'j_bumrah', name: 'J. Bumrah', role: 'Bowler', nationality: 'IND', runsScored: 80, ballsFaced: 120, wicketsTaken: 89, matchesPlayed: 62),
      Player(id: 'kl_rahul', name: 'KL Rahul', role: 'Batter', nationality: 'IND', runsScored: 1750, ballsFaced: 1350, wicketsTaken: 0, matchesPlayed: 72),
      Player(id: 'r_pant', name: 'R. Pant', role: 'Batter', nationality: 'IND', runsScored: 980, ballsFaced: 750, wicketsTaken: 0, matchesPlayed: 55),
      Player(id: 'r_jadeja', name: 'R. Jadeja', role: 'All-rounder', nationality: 'IND', runsScored: 450, ballsFaced: 380, wicketsTaken: 53, matchesPlayed: 68),
      Player(id: 'k_yadav', name: 'K. Yadav', role: 'Bowler', nationality: 'IND', runsScored: 45, ballsFaced: 90, wicketsTaken: 52, matchesPlayed: 34),
      Player(id: 'm_siraj', name: 'M. Siraj', role: 'Bowler', nationality: 'IND', runsScored: 12, ballsFaced: 30, wicketsTaken: 38, matchesPlayed: 29),
      Player(id: 'a_singh', name: 'A. Singh', role: 'Bowler', nationality: 'IND', runsScored: 5, ballsFaced: 15, wicketsTaken: 28, matchesPlayed: 24),
    ];

    final teamAusPlayers = [
      Player(id: 'p_cummins', name: 'P. Cummins', role: 'Bowler', nationality: 'AUS', runsScored: 450, ballsFaced: 350, wicketsTaken: 65, matchesPlayed: 52),
      Player(id: 'm_starc', name: 'M. Starc', role: 'Bowler', nationality: 'AUS', runsScored: 120, ballsFaced: 100, wicketsTaken: 74, matchesPlayed: 58),
      Player(id: 't_head', name: 'T. Head', role: 'Batter', nationality: 'AUS', runsScored: 1100, ballsFaced: 850, wicketsTaken: 5, matchesPlayed: 38),
      Player(id: 'm_marsh', name: 'M. Marsh', role: 'All-rounder', nationality: 'AUS', runsScored: 1450, ballsFaced: 1120, wicketsTaken: 22, matchesPlayed: 54),
      Player(id: 'g_maxwell', name: 'G. Maxwell', role: 'All-rounder', nationality: 'AUS', runsScored: 2250, ballsFaced: 1500, wicketsTaken: 40, matchesPlayed: 98),
      Player(id: 'd_warner', name: 'D. Warner', role: 'Batter', nationality: 'AUS', runsScored: 2890, ballsFaced: 2000, wicketsTaken: 0, matchesPlayed: 102),
      Player(id: 's_smith', name: 'S. Smith', role: 'Batter', nationality: 'AUS', runsScored: 1050, ballsFaced: 890, wicketsTaken: 0, matchesPlayed: 65),
      Player(id: 'm_labus', name: 'M. Labuschagne', role: 'Batter', nationality: 'AUS', runsScored: 350, ballsFaced: 320, wicketsTaken: 0, matchesPlayed: 20),
      Player(id: 'a_zampa', name: 'A. Zampa', role: 'Bowler', nationality: 'AUS', runsScored: 48, ballsFaced: 95, wicketsTaken: 92, matchesPlayed: 80),
      Player(id: 'j_hazle', name: 'J. Hazlewood', role: 'Bowler', nationality: 'AUS', runsScored: 20, ballsFaced: 50, wicketsTaken: 61, matchesPlayed: 45),
      Player(id: 'm_wade', name: 'M. Wade', role: 'Batter', nationality: 'AUS', runsScored: 980, ballsFaced: 720, wicketsTaken: 0, matchesPlayed: 75),
    ];

    _teams = [
      Team(id: 'india', name: 'Team India', shortName: 'IND', logoColorHex: '0xFF0F4C81', players: teamIndiaPlayers),
      Team(id: 'australia', name: 'Team Australia', shortName: 'AUS', logoColorHex: '0xFFFFBF00', players: teamAusPlayers),
    ];
    _saveTeams();
  }

  void _loadDefaultMatches() {
    if (_teams.isEmpty) _loadDefaultTeams();

    final matchIndia = _teams.firstWhere((t) => t.id == 'india');
    final matchAus = _teams.firstWhere((t) => t.id == 'australia');

    // Live Match: IND vs AUS - T20 World Cup Final
    final liveMatch = CricketMatch(
      id: 'live_world_cup_final',
      teamA: matchIndia,
      teamB: matchAus,
      matchType: 'T20',
      venue: 'Wankhede Stadium',
      date: '09-07-2026',
      time: '19:30',
      status: 'Live',
      tossWinner: 'Team India',
      tossDecision: 'Bat',
      battingTeamId: 'india',
      playingXI_A: matchIndia.players,
      playingXI_B: matchAus.players,
      runsA: 184,
      wicketsA: 4,
      oversA: 18.2,
      runsB: 0,
      wicketsB: 0,
      oversB: 0.0,
      target: 215,
      scorerUsername: 'scorer1',
      scorerPassword: '123',
      currentStrikerId: 'v_kohli',
      currentNonStrikerId: 's_yadav',
      currentBowlerId: 'm_starc',
      isFirstInnings: true,
      balls: [
        BallRecord(run: 1, extraRun: 0, extraType: 'None', isWicket: false, wicketType: 'None', batsmanName: 'V. Kohli', bowlerName: 'M. Starc', commentary: 'Starc fires it full on the stumps, Kohli pushes it to cover for a quick single.', timestamp: DateTime.now()),
        BallRecord(run: 0, extraRun: 0, extraType: 'None', isWicket: false, wicketType: 'None', batsmanName: 'S. Yadav', bowlerName: 'M. Starc', commentary: 'Good length delivery outside off, Suryakumar plays a solid defensive block.', timestamp: DateTime.now()),
      ],
    );

    // Completed Match: IND vs AUS - Bilateral Series
    final completedMatch = CricketMatch(
      id: 'completed_bilateral_1',
      teamA: matchIndia,
      teamB: matchAus,
      matchType: 'T20',
      venue: 'Melbourne Cricket Ground',
      date: '02-07-2026',
      time: '14:30',
      status: 'Completed',
      tossWinner: 'Team Australia',
      tossDecision: 'Bowl',
      battingTeamId: 'india',
      playingXI_A: matchIndia.players,
      playingXI_B: matchAus.players,
      runsA: 172,
      wicketsA: 6,
      oversA: 20.0,
      runsB: 175,
      wicketsB: 3,
      oversB: 19.1,
      target: 173,
      scorerUsername: 'scorer2',
      scorerPassword: '456',
      balls: [],
    );

    _matches = [liveMatch, completedMatch];
    _saveMatches();
  }

  // --- Authentications ---
  bool login(String usernameOrEmail, String password) {
    // 1. Admin login
    if (usernameOrEmail == 'admin@cricketverse.ai' && password == 'admin123') {
      _currentUserEmail = 'admin@cricketverse.ai';
      _currentRole = 'Admin';
      _activeScorerMatchId = null;
      notifyListeners();
      return true;
    }

    // 2. Scorer login
    final matchScoring = _matches.firstWhere(
      (m) => m.scorerUsername == usernameOrEmail && m.scorerPassword == password,
      orElse: () => null as dynamic,
    );
    if (matchScoring != null) {
      _currentUserEmail = usernameOrEmail;
      _currentRole = 'Scorer';
      _activeScorerMatchId = matchScoring.id;
      notifyListeners();
      return true;
    }

    // 3. User login
    if (_users.containsKey(usernameOrEmail) && _users[usernameOrEmail] == password) {
      _currentUserEmail = usernameOrEmail;
      _currentRole = 'User';
      _activeScorerMatchId = null;
      notifyListeners();
      return true;
    }

    return false;
  }

  bool register(String email, String password) {
    if (_users.containsKey(email)) {
      return false;
    }
    _users[email] = password;
    _saveUsers();
    
    // Automatically log them in as User
    _currentUserEmail = email;
    _currentRole = 'User';
    notifyListeners();
    return true;
  }

  void loginAsGuest() {
    _currentUserEmail = 'guest@cricketverse.ai';
    _currentRole = 'Guest';
    notifyListeners();
  }

  void logout() {
    _currentUserEmail = null;
    _currentRole = null;
    _activeScorerMatchId = null;
    notifyListeners();
  }

  // --- Admin Methods ---

  /// Allows admin to directly activate a live match for scoring without scorer login
  void adminActivateMatch(String matchId) {
    final match = _matches.firstWhere((m) => m.id == matchId, orElse: () => _matches.first);
    _activeScorerMatchId = match.id;
    // Auto-set up the match if still Upcoming
    if (match.status == 'Upcoming') {
      final batTeam = match.teamA;
      final bowlTeam = match.teamB;
      match.battingTeamId = batTeam.id;
      match.tossWinner = batTeam.name;
      match.tossDecision = 'Bat';
      match.status = 'Live';
      match.currentStrikerId = batTeam.players.isNotEmpty ? batTeam.players[0].id : '';
      match.currentNonStrikerId = batTeam.players.length > 1 ? batTeam.players[1].id : '';
      match.currentBowlerId = bowlTeam.players.isNotEmpty ? bowlTeam.players[bowlTeam.players.length - 1].id : '';
      _saveMatches();
    }
    notifyListeners();
  }

  void addTeam(String name, String shortName, String colorHex, List<Player> players) {
    final newTeam = Team(
      id: name.toLowerCase().replaceAll(' ', '_'),
      name: name,
      shortName: shortName,
      logoColorHex: colorHex,
      players: players,
    );
    _teams.add(newTeam);
    _saveTeams();
    notifyListeners();
  }

  void scheduleMatch({
    required String teamAId,
    required String teamBId,
    required String matchType,
    required String venue,
    required String date,
    required String time,
    required String scorerUser,
    required String scorerPass,
  }) {
    final teamA = _teams.firstWhere((t) => t.id == teamAId);
    final teamB = _teams.firstWhere((t) => t.id == teamBId);

    final newMatch = CricketMatch(
      id: 'match_${DateTime.now().millisecondsSinceEpoch}',
      teamA: teamA,
      teamB: teamB,
      matchType: matchType,
      venue: venue,
      date: date,
      time: time,
      status: 'Upcoming',
      playingXI_A: teamA.players,
      playingXI_B: teamB.players,
      scorerUsername: scorerUser,
      scorerPassword: scorerPass,
      balls: [],
    );

    _matches.add(newMatch);
    _saveMatches();
    notifyListeners();
  }

  // --- Match Scorer Methods ---
  void startMatchSetup(String matchId, String tossWinnerTeam, String decision, String firstBattingTeamId) {
    final match = _matches.firstWhere((m) => m.id == matchId);
    match.tossWinner = tossWinnerTeam;
    match.tossDecision = decision;
    match.battingTeamId = firstBattingTeamId;
    match.status = 'Live';
    
    // Choose first striker & non-striker & bowler
    final batTeam = firstBattingTeamId == match.teamA.id ? match.teamA : match.teamB;
    final bowlTeam = firstBattingTeamId == match.teamA.id ? match.teamB : match.teamA;

    match.currentStrikerId = batTeam.players[0].id;
    match.currentNonStrikerId = batTeam.players[1].id;
    match.currentBowlerId = bowlTeam.players[bowlTeam.players.length - 1].id; // Last player defaults to bowler

    _saveMatches();
    notifyListeners();
  }

  void updateScore({
    required int runs,
    required String extraType, // "Wide", "No Ball", "Leg Bye", "None"
    required int extraRuns,
    required bool isWicket,
    required String wicketType,
  }) {
    if (_activeScorerMatchId == null) return;
    final match = _matches.firstWhere((m) => m.id == _activeScorerMatchId);

    final battingTeam = match.battingTeamId == match.teamA.id ? match.teamA : match.teamB;
    final bowlingTeam = match.battingTeamId == match.teamA.id ? match.teamB : match.teamA;

    final striker = battingTeam.players.firstWhere((p) => p.id == match.currentStrikerId, orElse: () => battingTeam.players[0]);
    final nonStriker = battingTeam.players.firstWhere((p) => p.id == match.currentNonStrikerId, orElse: () => battingTeam.players[1]);
    final bowler = bowlingTeam.players.firstWhere((p) => p.id == match.currentBowlerId, orElse: () => bowlingTeam.players[bowlingTeam.players.length - 1]);

    // Handle extra type balls
    int ballVal = 1;
    if (extraType == 'Wide' || extraType == 'No Ball') {
      ballVal = 0; // Wide or No ball doesn't count in the over
    }

    // Apply scores
    int totalRunsThisBall = runs + extraRuns;
    if (match.isFirstInnings) {
      match.runsA += totalRunsThisBall;
      if (isWicket) match.wicketsA += 1;
      
      // Update overs
      match.oversA = _incrementOvers(match.oversA, ballVal);
    } else {
      match.runsB += totalRunsThisBall;
      if (isWicket) match.wicketsB += 1;
      
      match.oversB = _incrementOvers(match.oversB, ballVal);
    }

    // Update individual player statistics
    if (extraType == 'None' || extraType == 'Leg Bye') {
      striker.runsScored += runs;
      striker.ballsFaced += ballVal;
    }
    
    bowler.runsConceded += totalRunsThisBall;
    if (isWicket && wicketType != 'Run Out') {
      bowler.wicketsTaken += 1;
    }
    if (ballVal > 0) {
      bowler.oversBowled = _incrementOvers(bowler.oversBowled, 1);
    }

    // AI Commentary simulation
    String commentary = _generateAICommentary(striker.name, bowler.name, runs, extraType, isWicket, wicketType);

    // Save ball record
    final newBall = BallRecord(
      run: runs,
      extraRun: extraRuns,
      extraType: extraType,
      isWicket: isWicket,
      wicketType: wicketType,
      batsmanName: striker.name,
      bowlerName: bowler.name,
      commentary: commentary,
      timestamp: DateTime.now(),
    );
    match.balls.add(newBall);

    // Strike rotation on odd runs (1, 3, etc.) if not a boundary / extra
    if (runs % 2 != 0 && (extraType == 'None' || extraType == 'Leg Bye')) {
      final temp = match.currentStrikerId;
      match.currentStrikerId = match.currentNonStrikerId;
      match.currentNonStrikerId = temp;
    }

    // Handle wicket striker change
    if (isWicket) {
      // Find next player who hasn't batted
      // In this mock, just pick the next index
      final currentBattedCount = match.isFirstInnings ? match.wicketsA : match.wicketsB;
      if (currentBattedCount + 1 < battingTeam.players.length) {
        match.currentStrikerId = battingTeam.players[currentBattedCount + 1].id;
      } else {
        // All out
        endInningsOrMatch();
      }
    }

    _saveMatches();
    notifyListeners();
  }

  void switchBowler(String newBowlerId) {
    if (_activeScorerMatchId == null) return;
    final match = _matches.firstWhere((m) => m.id == _activeScorerMatchId);
    match.currentBowlerId = newBowlerId;
    _saveMatches();
    notifyListeners();
  }

  void endOver() {
    if (_activeScorerMatchId == null) return;
    final match = _matches.firstWhere((m) => m.id == _activeScorerMatchId);

    // Rotate strike at the end of the over
    final temp = match.currentStrikerId;
    match.currentStrikerId = match.currentNonStrikerId;
    match.currentNonStrikerId = temp;

    // Automatically assign a random bowler for next over in this simulation
    final bowlingTeam = match.battingTeamId == match.teamA.id ? match.teamB : match.teamA;
    final currentBowlerIndex = bowlingTeam.players.indexWhere((p) => p.id == match.currentBowlerId);
    int nextBowlerIndex = (currentBowlerIndex - 1) % bowlingTeam.players.length;
    if (nextBowlerIndex < 0) nextBowlerIndex = bowlingTeam.players.length - 1;
    // Don't select the batsman
    match.currentBowlerId = bowlingTeam.players[nextBowlerIndex].id;

    _saveMatches();
    notifyListeners();
  }

  void endInningsOrMatch() {
    if (_activeScorerMatchId == null) return;
    final match = _matches.firstWhere((m) => m.id == _activeScorerMatchId);

    if (match.isFirstInnings) {
      // Switch innings
      match.isFirstInnings = false;
      match.battingTeamId = match.battingTeamId == match.teamA.id ? match.teamB.id : match.teamA.id;
      match.target = (match.runsA) + 1;
      
      // Set playing lineup details
      final activeBatTeam = match.battingTeamId == match.teamA.id ? match.teamA : match.teamB;
      final activeBowlTeam = match.battingTeamId == match.teamA.id ? match.teamB : match.teamA;
      
      match.currentStrikerId = activeBatTeam.players[0].id;
      match.currentNonStrikerId = activeBatTeam.players[1].id;
      match.currentBowlerId = activeBowlTeam.players[activeBowlTeam.players.length - 1].id;
    } else {
      // Completed match
      match.status = 'Completed';
    }

    _saveMatches();
    notifyListeners();
  }

  void endMatchForce() {
    if (_activeScorerMatchId == null) return;
    final match = _matches.firstWhere((m) => m.id == _activeScorerMatchId);
    match.status = 'Completed';
    _saveMatches();
    notifyListeners();
  }

  double _incrementOvers(double currentOvers, int ballsAdded) {
    if (ballsAdded == 0) return currentOvers;
    
    int oversInt = currentOvers.toInt();
    int ballsInt = ((currentOvers - oversInt) * 10).round();
    
    ballsInt += ballsAdded;
    if (ballsInt >= 6) {
      oversInt += ballsInt ~/ 6;
      ballsInt = ballsInt % 6;
    }
    
    return oversInt + (ballsInt / 10.0);
  }

  // Live win probability calculations for dashboard
  double calculateWinProbability(CricketMatch match) {
    if (match.status == 'Upcoming') return 50.0;
    if (match.status == 'Completed') {
      if (match.runsA > match.runsB) return 100.0; // Team A won
      return 0.0; // Team B won
    }

    // Live logic
    double prob = 50.0;
    if (match.isFirstInnings) {
      // Base on Run rate
      double crr = match.runsA / (match.oversA > 0 ? match.oversA : 0.1);
      prob = 50.0 + (crr - 7.5) * 5; // Higher CRR increases Team A win probability
      if (match.wicketsA > 5) {
        prob -= (match.wicketsA - 5) * 8; // More wickets decreases Team A probability
      }
    } else {
      // Chasing: Target vs runs remaining and balls remaining
      int target = match.target;
      int currentScore = match.runsB;
      int runsNeeded = target - currentScore;
      
      int totalBalls = 120; // Default T20
      int oversInt = match.oversB.toInt();
      int ballsInt = ((match.oversB - oversInt) * 10).round();
      int ballsBowled = (oversInt * 6) + ballsInt;
      int ballsRemaining = totalBalls - ballsBowled;
      
      if (runsNeeded <= 0) return 0.0; // Chaser won
      if (ballsRemaining <= 0 || match.wicketsB >= 10) return 100.0; // Defender won
      
      double requiredRate = (runsNeeded / ballsRemaining) * 6;
      prob = 50.0 - (requiredRate - 7.5) * 7 + (10 - match.wicketsB) * 3;
    }

    return prob.clamp(1.0, 99.0);
  }

  String _generateAICommentary(String batsman, String bowler, int runs, String extraType, bool isWicket, String wicketType) {
    final random = Random();
    
    if (isWicket) {
      final wicketTpls = [
        "OUT! $bowler strikes! $batsman tries to smash it but is clean bowled! Brilliant delivery!",
        "CAUGHT! In the air... and taken! $batsman goes for the big one off $bowler, but finds the fielder at deep midwicket.",
        "LBW! Huge shout from $bowler, and the finger goes up! $batsman is trapped right in front of the stumps.",
        "RUN OUT! Sensational fielding! Direct hit from point and $batsman is yards short of the crease!",
      ];
      return wicketTpls[random.nextInt(wicketTpls.length)];
    }

    if (extraType == 'Wide') {
      return "Wide ball! $bowler strays down the leg side, $batsman lets it go. Extra run to the total.";
    }
    if (extraType == 'No Ball') {
      return "No Ball! $bowler oversteps the crease. That's an extra run and a Free Hit for $batsman!";
    }

    if (runs == 6) {
      final sixTpls = [
        "SIX! $batsman steps out and launches $bowler high over long-on! That has gone miles!",
        "MAXIMUM! Incredilby struck by $batsman! Picked up off the pads and dispatched into the crowd!",
        "SIX MORE! $batsman displays pure class, a sweet pull shot that sails comfortably over deep square leg.",
      ];
      return sixTpls[random.nextInt(sixTpls.length)];
    }
    if (runs == 4) {
      final fourTpls = [
        "FOUR! Beautiful shot by $batsman. Edges past slip and races away to the third man boundary.",
        "CRACKING BOUNDARY! $batsman stands tall and drives $bowler through extra cover for four.",
        "FOUR RUNS! Short and wide from $bowler, cut away elegantly by $batsman to the fence.",
      ];
      return fourTpls[random.nextInt(fourTpls.length)];
    }
    if (runs == 0) {
      final dotTpls = [
        "No run. Good length delivery from $bowler, played defensively back to the bowler.",
        "Dot ball. $batsman swings and misses a slower delivery from $bowler.",
        "Well bowled! $bowler beats $batsman outside the off stump with a beautiful outswinger.",
      ];
      return dotTpls[random.nextInt(dotTpls.length)];
    }

    final runTpls = [
      "Just a single. $batsman drives it down to long-off to rotate the strike.",
      "Tucked away off the hips by $batsman, they scamper back for a quick couple of runs.",
      "Placed softly into the gap at cover by $batsman, allowing a quick single.",
    ];
    return runTpls[random.nextInt(runTpls.length)];
  }
}
