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
    }
    
    // Always ensure default users exist for quick login buttons to succeed
    if (!_users.containsKey('user@gmail.com')) {
      _users['user@gmail.com'] = 'user123';
    }
    if (!_users.containsKey('alex@gmail.com')) {
      _users['alex@gmail.com'] = 'alex123';
    }
    _saveUsers();

    final isUvpceLoaded = _prefs?.getBool('data_version_uvpce_2026') ?? false;

    // 2. Load Teams
    final teamsJson = _prefs?.getString('teams');
    if (teamsJson != null && isUvpceLoaded) {
      final List decoded = jsonDecode(teamsJson);
      _teams = decoded.map((item) => Team.fromJson(item)).toList();
    } else {
      _loadDefaultTeams();
    }

    // 3. Load Matches
    final matchesJson = _prefs?.getString('matches');
    if (matchesJson != null && isUvpceLoaded) {
      final List decoded = jsonDecode(matchesJson);
      _matches = decoded.map((item) => CricketMatch.fromJson(item)).toList();
    } else {
      _loadDefaultMatches();
      _prefs?.setBool('data_version_uvpce_2026', true);
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

  // Preload UVPCE College cricket teams and player names
  void _loadDefaultTeams() {
    final firstNames = [
      'Aarav', 'Vihaan', 'Arjun', 'Kabir', 'Ishaan', 'Rohan', 'Aditya', 'Kunal',
      'Reyansh', 'Vivaan', 'Advik', 'Sai', 'Atharva', 'Shaurya', 'Rudra', 'Aaryan',
      'Veer', 'Ayaan', 'Kiaan', 'Krishna', 'Dev', 'Aryan', 'Madhav', 'Ryan',
      'Dhruv', 'Kian', 'Yuvan'
    ];
    final lastNames = ['Patel', 'Shah', 'Mehta', 'Sharma', 'Joshi', 'Gani', 'Amin', 'Chaudhari', 'Vaghela', 'Trivedi', 'Dave'];

    List<Player> generatePlayersForTeam(String teamShort, int startIndex) {
      final roles = ['Batter', 'Batter', 'Batter', 'Batter', 'All-rounder', 'All-rounder', 'All-rounder', 'Bowler', 'Bowler', 'Bowler', 'Bowler'];
      final List<Player> teamPlayers = [];
      for (int i = 0; i < 11; i++) {
        final fName = firstNames[(startIndex + i) % firstNames.length];
        final lName = lastNames[(startIndex * 3 + i) % lastNames.length];
        final fullName = '$fName $lName';
        final id = '${teamShort.toLowerCase()}_${fName.toLowerCase()}_$i';
        
        final runs = (200 + (startIndex * 35 + i * 55) % 1800);
        final wickets = (i >= 7) ? (10 + (startIndex * 4 + i * 5) % 50) : (0 + (startIndex + i) % 4);
        final matches = 15 + (runs ~/ 120);

        teamPlayers.add(Player(
          id: id,
          name: fullName,
          role: roles[i],
          nationality: 'IND',
          runsScored: runs,
          ballsFaced: (runs * 1.3).round(),
          wicketsTaken: wickets,
          matchesPlayed: matches,
        ));
      }
      return teamPlayers;
    }

    _teams = [
      Team(id: 'uvpce_a', name: 'UVPCE A', shortName: 'UVP-A', logoColorHex: '0xFF0284C7', players: generatePlayersForTeam('UVP-A', 0)),
      Team(id: 'uvpce_b', name: 'UVPCE B', shortName: 'UVP-B', logoColorHex: '0xFF10B981', players: generatePlayersForTeam('UVP-B', 5)),
      Team(id: 'uvpce_c', name: 'UVPCE C', shortName: 'UVP-C', logoColorHex: '0xFF8B5CF6', players: generatePlayersForTeam('UVP-C', 10)),
      Team(id: 'uvpce_titans', name: 'UVPCE Titans', shortName: 'UVP-TT', logoColorHex: '0xFFF59E0B', players: generatePlayersForTeam('UVP-TT', 15)),
      Team(id: 'uvpce_warriors', name: 'UVPCE Warriors', shortName: 'UVP-WR', logoColorHex: '0xFFEF4444', players: generatePlayersForTeam('UVP-WR', 20)),
      Team(id: 'uvpce_challengers', name: 'UVPCE Challengers', shortName: 'UVP-CH', logoColorHex: '0xFFEC4899', players: generatePlayersForTeam('UVP-CH', 25)),
      Team(id: 'uvpce_strikers', name: 'UVPCE Strikers', shortName: 'UVP-ST', logoColorHex: '0xFF06B6D4', players: generatePlayersForTeam('UVP-ST', 3)),
      Team(id: 'uvpce_legends', name: 'UVPCE Legends', shortName: 'UVP-LG', logoColorHex: '0xFF14B8A6', players: generatePlayersForTeam('UVP-LG', 8)),
    ];
    _saveTeams();
  }

  void _loadDefaultMatches() {
    if (_teams.isEmpty) _loadDefaultTeams();

    final teamTitans = _teams.firstWhere((t) => t.id == 'uvpce_titans');
    final teamWarriors = _teams.firstWhere((t) => t.id == 'uvpce_warriors');
    final teamA = _teams.firstWhere((t) => t.id == 'uvpce_a');
    final teamB = _teams.firstWhere((t) => t.id == 'uvpce_b');

    // Live Match: Titans vs Warriors
    final liveMatch = CricketMatch(
      id: 'live_world_cup_final',
      teamA: teamTitans,
      teamB: teamWarriors,
      matchType: 'T20',
      venue: 'Narendra Modi Stadium',
      date: '17-07-2026',
      time: '19:30',
      status: 'Live',
      tossWinner: teamTitans.name,
      tossDecision: 'Bat',
      battingTeamId: 'uvpce_titans',
      playingXI_A: teamTitans.players,
      playingXI_B: teamWarriors.players,
      runsA: 145,
      wicketsA: 4,
      oversA: 15.4,
      runsB: 0,
      wicketsB: 0,
      oversB: 0.0,
      target: 185,
      scorerUsername: 'scorer1',
      scorerPassword: '123',
      currentStrikerId: teamTitans.players[0].id,
      currentNonStrikerId: teamTitans.players[1].id,
      currentBowlerId: teamWarriors.players[teamWarriors.players.length - 1].id,
      isFirstInnings: true,
      balls: [
        BallRecord(
          run: 4,
          extraRun: 0,
          extraType: 'None',
          isWicket: false,
          wicketType: 'None',
          batsmanName: teamTitans.players[0].name,
          bowlerName: teamWarriors.players[teamWarriors.players.length - 1].name,
          commentary: 'CRACKING BOUNDARY! Smashed down the ground past mid-on for four!',
          timestamp: DateTime.now(),
        ),
        BallRecord(
          run: 1,
          extraRun: 0,
          extraType: 'None',
          isWicket: false,
          wicketType: 'None',
          batsmanName: teamTitans.players[0].name,
          bowlerName: teamWarriors.players[teamWarriors.players.length - 1].name,
          commentary: 'Pushed to deep cover for a single to keep strike.',
          timestamp: DateTime.now(),
        ),
      ],
    );

    // Completed Match: UVPCE A vs UVPCE B
    final completedMatch = CricketMatch(
      id: 'completed_bilateral_1',
      teamA: teamA,
      teamB: teamB,
      matchType: 'T20',
      venue: 'Wankhede Stadium',
      date: '15-07-2026',
      time: '14:30',
      status: 'Completed',
      tossWinner: teamB.name,
      tossDecision: 'Bowl',
      battingTeamId: 'uvpce_a',
      playingXI_A: teamA.players,
      playingXI_B: teamB.players,
      runsA: 168,
      wicketsA: 6,
      oversA: 20.0,
      runsB: 169,
      wicketsB: 5,
      oversB: 19.3,
      target: 169,
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
    CricketMatch? matchScoring;
    for (final m in _matches) {
      if (m.scorerUsername == usernameOrEmail && m.scorerPassword == password) {
        matchScoring = m;
        break;
      }
    }
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

  void setStriker(String strikerId) {
    if (_activeScorerMatchId == null) return;
    final match = _matches.firstWhere((m) => m.id == _activeScorerMatchId);
    match.currentStrikerId = strikerId;
    _saveMatches();
    notifyListeners();
  }

  void setNonStriker(String nonStrikerId) {
    if (_activeScorerMatchId == null) return;
    final match = _matches.firstWhere((m) => m.id == _activeScorerMatchId);
    match.currentNonStrikerId = nonStrikerId;
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
