import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../models/models.dart';
import 'api_service.dart';
import 'socket_service.dart';

class StorageService with ChangeNotifier {
  SharedPreferences? _prefs;
  List<Team> _teams = [];
  List<CricketMatch> _matches = [];
  Map<String, String> _users = {}; // Email -> Password
  
  // App Session State
  String? _currentUserEmail;
  String? _currentRole; // "Admin", "Scorer", "User", "Guest"
  String? _activeScorerMatchId; // Active match ID currently being scored
  bool _isOnlineMode = false;

  List<Team> get teams => _teams;
  List<CricketMatch> get matches => _matches;
  String? get currentRole => _currentRole;
  String? get currentUserEmail => _currentUserEmail;
  String? get activeScorerMatchId => _activeScorerMatchId;
  bool get isOnlineMode => _isOnlineMode;

  StorageService() {
    _initStorage();
  }

  Future<void> _initStorage() async {
    _prefs = await SharedPreferences.getInstance();
    await ApiService.init();

    // Health check check to auto detect server online
    try {
      final res = await http.get(Uri.parse('${ApiService.baseUrl}/health')).timeout(const Duration(seconds: 2));
      if (res.statusCode == 200) {
        _isOnlineMode = true;
        debugPrint('Backend server detected. Running in ONLINE mode.');
      } else {
        _isOnlineMode = false;
        debugPrint('Backend server health check failed. Running in OFFLINE mode.');
      }
    } catch (_) {
      _isOnlineMode = false;
      debugPrint('Backend server unreachable. Running in OFFLINE mode.');
    }

    await loadData();
  }

  Future<void> toggleOnlineMode(bool val) async {
    _isOnlineMode = val;
    await loadData();
    notifyListeners();
  }

  Future<void> loadData() async {
    if (_isOnlineMode) {
      try {
        final remoteTeams = await ApiService.getTeams();
        if (remoteTeams.isNotEmpty) {
          _teams = remoteTeams;
        }
        final remoteMatches = await ApiService.getMatches();
        if (remoteMatches.isNotEmpty) {
          _matches = remoteMatches;
        }
        notifyListeners();
        return;
      } catch (e) {
        debugPrint('Error loading online data, falling back: $e');
      }
    }

    // --- Offline Data Loading ---
    // 1. Load users
    final usersJson = _prefs?.getString('users');
    if (usersJson != null) {
      final Map<String, dynamic> decoded = jsonDecode(usersJson);
      _users = decoded.map((key, value) => MapEntry(key, value.toString()));
    }
    
    if (!_users.containsKey('user@gmail.com')) {
      _users['user@gmail.com'] = 'user123';
    }
    if (!_users.containsKey('alex@gmail.com')) {
      _users['alex@gmail.com'] = 'alex123';
    }
    _saveUsers();

    final isUvpceLoaded = _prefs?.getBool('data_version_uvpce_2026_v2') ?? false;

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
      _prefs?.setBool('data_version_uvpce_2026_v2', true);
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
      'Veer', 'Aayaan', 'Kiaan', 'Krishna', 'Dev', 'Aryan', 'Madhav', 'Ryan',
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
      Team(id: 'uvpce_a', name: 'UVPCE - A', shortName: 'UVPCE - A', logoColorHex: '0xFF028A6B', players: generatePlayersForTeam('UVPCE - A', 0)),
      Team(id: 'uvpce_b', name: 'UVPCE - B', shortName: 'UVPCE - B', logoColorHex: '0xFF10B981', players: generatePlayersForTeam('UVPCE - B', 5)),
      Team(id: 'uvpce_c', name: 'UVPCE - C', shortName: 'UVPCE - C', logoColorHex: '0xFFD97706', players: generatePlayersForTeam('UVPCE - C', 10)),
      Team(id: 'uvpce_titans', name: 'UVPCE - Titans', shortName: 'UVPCE - Titans', logoColorHex: '0xFFF59E0B', players: generatePlayersForTeam('UVPCE - Titans', 15)),
      Team(id: 'uvpce_warriors', name: 'UVPCE - Warriors', shortName: 'UVPCE - Warriors', logoColorHex: '0xFFEF4444', players: generatePlayersForTeam('UVPCE - Warriors', 20)),
      Team(id: 'uvpce_challengers', name: 'UVPCE - Challengers', shortName: 'UVPCE - Challengers', logoColorHex: '0xFFEA580C', players: generatePlayersForTeam('UVPCE - Challengers', 25)),
      Team(id: 'uvpce_strikers', name: 'UVPCE - Strikers', shortName: 'UVPCE - Strikers', logoColorHex: '0xFF0B6623', players: generatePlayersForTeam('UVPCE - Strikers', 3)),
      Team(id: 'uvpce_legends', name: 'UVPCE - Legends', shortName: 'UVPCE - Legends', logoColorHex: '0xFF14B8A6', players: generatePlayersForTeam('UVPCE - Legends', 8)),
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
      ],
    );

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

  // --- Real-time WebSockets Subscriptions ---
  void subscribeToMatchLiveUpdates(String matchId) {
    if (!_isOnlineMode) return;
    SocketService.connect();
    SocketService.joinMatch(matchId);
    SocketService.listenToMatchUpdates((data) {
      final updatedMatch = CricketMatch.fromJson(data);
      final idx = _matches.indexWhere((m) => m.id == updatedMatch.id);
      if (idx != -1) {
        _matches[idx] = updatedMatch;
      } else {
        _matches.add(updatedMatch);
      }
      notifyListeners();
    });
  }

  void unsubscribeFromMatchLiveUpdates(String matchId) {
    if (!_isOnlineMode) return;
    SocketService.leaveMatch(matchId);
  }

  // --- Authentications ---
  Future<bool> login(String usernameOrEmail, String password) async {
    if (_isOnlineMode) {
      final res = await ApiService.login(usernameOrEmail, password);
      if (res != null) {
        _currentUserEmail = res['user']['email'];
        _currentRole = res['user']['role'];
        _activeScorerMatchId = res['activeScorerMatchId'];
        await loadData();
        return true;
      }
      return false;
    }

    // --- Offline Auth ---
    if (usernameOrEmail == 'admin@cricketverse.ai' && password == 'admin123') {
      _currentUserEmail = 'admin@cricketverse.ai';
      _currentRole = 'Admin';
      _activeScorerMatchId = null;
      notifyListeners();
      return true;
    }

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
      _activeScorerMatchId = matchScoring.id; // Scorer matches immediately to their match ID
      notifyListeners();
      return true;
    }

    if (_users.containsKey(usernameOrEmail) && _users[usernameOrEmail] == password) {
      _currentUserEmail = usernameOrEmail;
      _currentRole = 'User';
      _activeScorerMatchId = null;
      notifyListeners();
      return true;
    }

    return false;
  }

  Future<bool> register(String email, String password) async {
    if (_isOnlineMode) {
      final res = await ApiService.register(email, password);
      if (res != null) {
        _currentUserEmail = res['user']['email'];
        _currentRole = res['user']['role'];
        await loadData();
        return true;
      }
      return false;
    }

    // --- Offline Register ---
    if (_users.containsKey(email)) {
      return false;
    }
    _users[email] = password;
    _saveUsers();
    
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

  Future<void> logout() async {
    _currentUserEmail = null;
    _currentRole = null;
    _activeScorerMatchId = null;
    if (_isOnlineMode) {
      await ApiService.clearToken();
      SocketService.disconnect();
    }
    notifyListeners();
  }

  // --- Admin / CRUD Methods ---
  void adminActivateMatch(String matchId) async {
    if (_isOnlineMode) {
      final ok = await ApiService.adminActivateMatch(matchId);
      if (ok) {
        _activeScorerMatchId = matchId;
        await loadData();
      }
      return;
    }

    // --- Offline ---
    final match = _matches.firstWhere((m) => m.id == matchId, orElse: () => _matches.first);
    _activeScorerMatchId = match.id;
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

  void addTeam(String name, String shortName, String colorHex, List<Player> players) async {
    if (_isOnlineMode) {
      final ok = await ApiService.addTeam(name, shortName, colorHex, players);
      if (ok) await loadData();
      return;
    }

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

  void updateTeam(String teamId, String name, String shortName, String colorHex) async {
    if (_isOnlineMode) {
      final ok = await ApiService.updateTeam(teamId, name, shortName, colorHex);
      if (ok) await loadData();
      return;
    }

    final index = _teams.indexWhere((t) => t.id == teamId);
    if (index != -1) {
      _teams[index].name = name;
      _teams[index].shortName = shortName;
      _teams[index].logoColorHex = colorHex;
      _saveTeams();
      notifyListeners();
    }
  }

  void deleteTeam(String teamId) async {
    if (_isOnlineMode) {
      final ok = await ApiService.deleteTeam(teamId);
      if (ok) await loadData();
      return;
    }

    _teams.removeWhere((t) => t.id == teamId);
    _saveTeams();
    notifyListeners();
  }

  void addPlayer(String teamId, Player player) async {
    if (_isOnlineMode) {
      final ok = await ApiService.addPlayer(teamId, player);
      if (ok) await loadData();
      return;
    }

    final team = _teams.firstWhere((t) => t.id == teamId);
    team.players.add(player);
    _saveTeams();
    notifyListeners();
  }

  void updatePlayer(String teamId, Player updatedPlayer) async {
    if (_isOnlineMode) {
      final ok = await ApiService.updatePlayer(updatedPlayer);
      if (ok) await loadData();
      return;
    }

    final team = _teams.firstWhere((t) => t.id == teamId, orElse: () => _teams.first);
    final pIndex = team.players.indexWhere((p) => p.id == updatedPlayer.id);
    if (pIndex != -1) {
      team.players[pIndex] = updatedPlayer;
    } else {
      team.players.add(updatedPlayer);
    }
    _saveTeams();
    notifyListeners();
  }

  void removePlayer(String teamId, String playerId) async {
    if (_isOnlineMode) {
      final ok = await ApiService.removePlayer(playerId);
      if (ok) await loadData();
      return;
    }

    final team = _teams.firstWhere((t) => t.id == teamId, orElse: () => _teams.first);
    team.players.removeWhere((p) => p.id == playerId);
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
  }) async {
    if (_isOnlineMode) {
      final ok = await ApiService.scheduleMatch(
        teamAId: teamAId,
        teamBId: teamBId,
        matchType: matchType,
        venue: venue,
        date: date,
        time: time,
        scorerUser: scorerUser,
        scorerPass: scorerPass,
      );
      if (ok) await loadData();
      return;
    }

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

  // --- Scorer / Live Scoring Methods ---
  void startMatchSetup(String matchId, String tossWinnerTeam, String decision, String firstBattingTeamId) async {
    if (_isOnlineMode) {
      final updated = await ApiService.startMatchSetup(matchId, tossWinnerTeam, decision, firstBattingTeamId);
      if (updated != null) {
        final idx = _matches.indexWhere((m) => m.id == matchId);
        if (idx != -1) _matches[idx] = updated;
        notifyListeners();
      }
      return;
    }

    // --- Offline ---
    final match = _matches.firstWhere((m) => m.id == matchId);
    match.tossWinner = tossWinnerTeam;
    match.tossDecision = decision;
    match.battingTeamId = firstBattingTeamId;
    match.status = 'Live';
    
    final batTeam = firstBattingTeamId == match.teamA.id ? match.teamA : match.teamB;
    final bowlTeam = firstBattingTeamId == match.teamA.id ? match.teamB : match.teamA;

    match.currentStrikerId = batTeam.players[0].id;
    match.currentNonStrikerId = batTeam.players[1].id;
    match.currentBowlerId = bowlTeam.players[bowlTeam.players.length - 1].id;

    _saveMatches();
    notifyListeners();
  }

  void setActiveScorerMatchId(String? matchId) {
    _activeScorerMatchId = matchId;
    notifyListeners();
  }

  void swapStrikers() async {
    if (_activeScorerMatchId == null) return;
    if (_isOnlineMode) {
      final updated = await ApiService.swapStrikers(_activeScorerMatchId!);
      if (updated != null) {
        final idx = _matches.indexWhere((m) => m.id == _activeScorerMatchId);
        if (idx != -1) _matches[idx] = updated;
        notifyListeners();
      }
      return;
    }

    // --- Offline ---
    final match = _matches.firstWhere((m) => m.id == _activeScorerMatchId);
    final temp = match.currentStrikerId;
    match.currentStrikerId = match.currentNonStrikerId;
    match.currentNonStrikerId = temp;
    _saveMatches();
    notifyListeners();
  }

  void updateScore({
    required int runs,
    required String extraType,
    required int extraRuns,
    required bool isWicket,
    required String wicketType,
    String? dismissedPlayerId,
    String? newBatsmanId,
    String? newBatsmanPosition,
  }) async {
    if (_activeScorerMatchId == null) return;

    if (_isOnlineMode) {
      final updated = await ApiService.updateScore(
        matchId: _activeScorerMatchId!,
        runs: runs,
        extraType: extraType,
        extraRuns: extraRuns,
        isWicket: isWicket,
        wicketType: wicketType,
        dismissedPlayerId: dismissedPlayerId,
        newBatsmanId: newBatsmanId,
        newBatsmanPosition: newBatsmanPosition,
      );
      if (updated != null) {
        final idx = _matches.indexWhere((m) => m.id == _activeScorerMatchId);
        if (idx != -1) _matches[idx] = updated;
        notifyListeners();
      }
      return;
    }

    // --- Offline ---
    final match = _matches.firstWhere((m) => m.id == _activeScorerMatchId);

    final String currentStrikerIdBefore = match.currentStrikerId;
    final String currentNonStrikerIdBefore = match.currentNonStrikerId;
    final String currentBowlerIdBefore = match.currentBowlerId;

    final battingTeam = match.battingTeamId == match.teamA.id ? match.teamA : match.teamB;
    final bowlingTeam = match.battingTeamId == match.teamA.id ? match.teamB : match.teamA;

    final striker = battingTeam.players.firstWhere((p) => p.id == match.currentStrikerId, orElse: () => battingTeam.players[0]);
    final bowler = bowlingTeam.players.firstWhere((p) => p.id == match.currentBowlerId, orElse: () => bowlingTeam.players[bowlingTeam.players.length - 1]);

    int ballVal = 1;
    if (extraType == 'Wide' || extraType == 'No Ball') {
      ballVal = 0;
    }

    int totalRunsThisBall = runs + extraRuns;
    if (match.isFirstInnings) {
      match.runsA += totalRunsThisBall;
      if (isWicket && wicketType != 'Retired Hurt') match.wicketsA += 1;
      match.oversA = _incrementOvers(match.oversA, ballVal);
    } else {
      match.runsB += totalRunsThisBall;
      if (isWicket && wicketType != 'Retired Hurt') match.wicketsB += 1;
      match.oversB = _incrementOvers(match.oversB, ballVal);
    }

    if (extraType == 'None' || extraType == 'Leg Bye') {
      striker.runsScored += runs;
      striker.ballsFaced += ballVal;
    }
    
    bowler.runsConceded += totalRunsThisBall;
    if (isWicket && wicketType != 'Run Out' && wicketType != 'Retired Out' && wicketType != 'Retired Hurt') {
      bowler.wicketsTaken += 1;
    }
    if (ballVal > 0) {
      bowler.oversBowled = _incrementOvers(bowler.oversBowled, 1);
    }

    String commentary = _generateAICommentary(striker.name, bowler.name, runs, extraType, isWicket, wicketType);

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
      strikerId: currentStrikerIdBefore,
      nonStrikerId: currentNonStrikerIdBefore,
      bowlerId: currentBowlerIdBefore,
    );
    match.balls.add(newBall);

    if (runs % 2 != 0 && (extraType == 'None' || extraType == 'Leg Bye')) {
      final temp = match.currentStrikerId;
      match.currentStrikerId = match.currentNonStrikerId;
      match.currentNonStrikerId = temp;
    }

    if (isWicket) {
      final currentBattedCount = match.isFirstInnings ? match.wicketsA : match.wicketsB;
      final partnerId = (dismissedPlayerId == match.currentStrikerId) ? match.currentNonStrikerId : match.currentStrikerId;

      if (newBatsmanId != null && newBatsmanPosition != null) {
        if (newBatsmanPosition == 'Striker') {
          match.currentStrikerId = newBatsmanId;
          match.currentNonStrikerId = partnerId;
        } else {
          match.currentStrikerId = partnerId;
          match.currentNonStrikerId = newBatsmanId;
        }
      } else if (currentBattedCount + 1 < battingTeam.players.length) {
        final nextPlayer = battingTeam.players[currentBattedCount + 1];
        if (dismissedPlayerId != null && dismissedPlayerId == match.currentNonStrikerId) {
          match.currentNonStrikerId = nextPlayer.id;
        } else {
          match.currentStrikerId = nextPlayer.id;
        }
      } else {
        endInningsOrMatch();
      }
    }

    _saveMatches();
    notifyListeners();
  }

  void switchBowler(String newBowlerId) async {
    if (_activeScorerMatchId == null) return;

    if (_isOnlineMode) {
      final updated = await ApiService.switchBowler(_activeScorerMatchId!, newBowlerId);
      if (updated != null) {
        final idx = _matches.indexWhere((m) => m.id == _activeScorerMatchId);
        if (idx != -1) _matches[idx] = updated;
        notifyListeners();
      }
      return;
    }

    // --- Offline ---
    final match = _matches.firstWhere((m) => m.id == _activeScorerMatchId);
    match.currentBowlerId = newBowlerId;
    _saveMatches();
    notifyListeners();
  }

  void setStriker(String strikerId) {
    if (_activeScorerMatchId == null) return;
    final match = _matches.firstWhere((m) => m.id == _activeScorerMatchId);
    match.currentStrikerId = strikerId;
    if (!_isOnlineMode) _saveMatches();
    notifyListeners();
  }

  void setNonStriker(String nonStrikerId) {
    if (_activeScorerMatchId == null) return;
    final match = _matches.firstWhere((m) => m.id == _activeScorerMatchId);
    match.currentNonStrikerId = nonStrikerId;
    if (!_isOnlineMode) _saveMatches();
    notifyListeners();
  }

  void endOver() {
    if (_activeScorerMatchId == null) return;
    final match = _matches.firstWhere((m) => m.id == _activeScorerMatchId);

    // Rotate strike at the end of the over
    final temp = match.currentStrikerId;
    match.currentStrikerId = match.currentNonStrikerId;
    match.currentNonStrikerId = temp;

    // Automatically assign next bowler (cycle backwards)
    final bowlingTeam = match.battingTeamId == match.teamA.id ? match.teamB : match.teamA;
    final currentBowlerIndex = bowlingTeam.players.indexWhere((p) => p.id == match.currentBowlerId);
    int nextBowlerIndex = (currentBowlerIndex - 1) % bowlingTeam.players.length;
    if (nextBowlerIndex < 0) nextBowlerIndex = bowlingTeam.players.length - 1;
    match.currentBowlerId = bowlingTeam.players[nextBowlerIndex].id;

    if (!_isOnlineMode) _saveMatches();
    notifyListeners();
  }

  void endInningsOrMatch() async {
    if (_activeScorerMatchId == null) return;

    if (_isOnlineMode) {
      final updated = await ApiService.endInningsOrMatch(_activeScorerMatchId!);
      if (updated != null) {
        final idx = _matches.indexWhere((m) => m.id == _activeScorerMatchId);
        if (idx != -1) _matches[idx] = updated;
        notifyListeners();
      }
      return;
    }

    // --- Offline ---
    final match = _matches.firstWhere((m) => m.id == _activeScorerMatchId);

    if (match.isFirstInnings) {
      match.isFirstInnings = false;
      match.battingTeamId = match.battingTeamId == match.teamA.id ? match.teamB.id : match.teamA.id;
      match.target = (match.runsA) + 1;
      
      final activeBatTeam = match.battingTeamId == match.teamA.id ? match.teamA : match.teamB;
      final activeBowlTeam = match.battingTeamId == match.teamA.id ? match.teamB : match.teamA;
      
      match.currentStrikerId = activeBatTeam.players[0].id;
      match.currentNonStrikerId = activeBatTeam.players[1].id;
      match.currentBowlerId = activeBowlTeam.players[activeBowlTeam.players.length - 1].id;
    } else {
      match.status = 'Completed';
    }

    _saveMatches();
    notifyListeners();
  }

  void endMatchForce() async {
    if (_activeScorerMatchId == null) return;

    if (_isOnlineMode) {
      final updated = await ApiService.endMatchForce(_activeScorerMatchId!);
      if (updated != null) {
        final idx = _matches.indexWhere((m) => m.id == _activeScorerMatchId);
        if (idx != -1) _matches[idx] = updated;
        notifyListeners();
      }
      return;
    }

    // --- Offline ---
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

  // win probability calculator
  double calculateWinProbability(CricketMatch match) {
    if (match.status == 'Upcoming') return 50.0;
    if (match.status == 'Completed') {
      if (match.runsA > match.runsB) return 100.0;
      return 0.0;
    }

    double prob = 50.0;
    if (match.isFirstInnings) {
      double crr = match.runsA / (match.oversA > 0 ? match.oversA : 0.1);
      prob = 50.0 + (crr - 7.5) * 5;
      if (match.wicketsA > 5) {
        prob -= (match.wicketsA - 5) * 8;
      }
    } else {
      int target = match.target;
      int currentScore = match.runsB;
      int runsNeeded = target - currentScore;
      
      int totalBalls = 120;
      int oversInt = match.oversB.toInt();
      int ballsInt = ((match.oversB - oversInt) * 10).round();
      int ballsBowled = (oversInt * 6) + ballsInt;
      int ballsRemaining = totalBalls - ballsBowled;
      
      if (runsNeeded <= 0) return 0.0;
      if (ballsRemaining <= 0 || match.wicketsB >= 10) return 100.0;
      
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

  void resetMatchToZero(String matchId) async {
    if (_isOnlineMode) {
      final ok = await ApiService.resetMatchToZero(matchId);
      if (ok) await loadData();
      return;
    }

    // --- Offline ---
    final match = _matches.firstWhere((m) => m.id == matchId);
    
    match.runsA = 0;
    match.wicketsA = 0;
    match.oversA = 0.0;
    match.runsB = 0;
    match.wicketsB = 0;
    match.oversB = 0.0;
    match.target = 0;
    match.balls = [];
    match.isFirstInnings = true;

    for (var p in match.teamA.players) {
      p.runsScored = 0;
      p.ballsFaced = 0;
    }
    for (var p in match.teamB.players) {
      p.oversBowled = 0.0;
      p.runsConceded = 0;
      p.wicketsTaken = 0;
    }

    match.currentStrikerId = match.teamA.players[0].id;
    match.currentNonStrikerId = match.teamA.players[1].id;
    match.currentBowlerId = match.teamB.players[match.teamB.players.length - 1].id;

    _saveMatches();
    notifyListeners();
  }

  double _decrementOvers(double currentOvers, int ballsRemoved) {
    if (ballsRemoved == 0) return currentOvers;
    
    int oversInt = currentOvers.toInt();
    int ballsInt = ((currentOvers - oversInt) * 10).round();
    
    ballsInt -= ballsRemoved;
    if (ballsInt < 0) {
      int oversNeeded = (ballsInt.abs() / 6).ceil();
      oversInt -= oversNeeded;
      ballsInt = (ballsInt + (oversNeeded * 6)) % 6;
      if (oversInt < 0) {
        oversInt = 0;
        ballsInt = 0;
      }
    }
    
    return oversInt + (ballsInt / 10.0);
  }

  void undoLastBall() async {
    if (_activeScorerMatchId == null) return;

    if (_isOnlineMode) {
      final updated = await ApiService.undoLastBall(_activeScorerMatchId!);
      if (updated != null) {
        final idx = _matches.indexWhere((m) => m.id == _activeScorerMatchId);
        if (idx != -1) _matches[idx] = updated;
        notifyListeners();
      }
      return;
    }

    // --- Offline ---
    final match = _matches.firstWhere((m) => m.id == _activeScorerMatchId);
    if (match.balls.isEmpty) return;

    final lastBall = match.balls.removeLast();

    final battingTeam = match.battingTeamId == match.teamA.id ? match.teamA : match.teamB;
    final bowlingTeam = match.battingTeamId == match.teamA.id ? match.teamB : match.teamA;

    if (lastBall.strikerId != null) match.currentStrikerId = lastBall.strikerId!;
    if (lastBall.nonStrikerId != null) match.currentNonStrikerId = lastBall.nonStrikerId!;
    if (lastBall.bowlerId != null) match.currentBowlerId = lastBall.bowlerId!;

    final striker = battingTeam.players.firstWhere((p) => p.id == match.currentStrikerId, orElse: () => battingTeam.players[0]);
    final bowler = bowlingTeam.players.firstWhere((p) => p.id == match.currentBowlerId, orElse: () => bowlingTeam.players[bowlingTeam.players.length - 1]);

    int ballVal = 1;
    if (lastBall.extraType == 'Wide' || lastBall.extraType == 'No Ball') {
      ballVal = 0;
    }

    int totalRunsThisBall = lastBall.run + lastBall.extraRun;

    if (match.isFirstInnings) {
      match.runsA -= totalRunsThisBall;
      if (match.runsA < 0) match.runsA = 0;
      
      if (lastBall.isWicket && lastBall.wicketType != 'Retired Hurt') {
        match.wicketsA -= 1;
        if (match.wicketsA < 0) match.wicketsA = 0;
      }
      
      match.oversA = _decrementOvers(match.oversA, ballVal);
    } else {
      match.runsB -= totalRunsThisBall;
      if (match.runsB < 0) match.runsB = 0;
      
      if (lastBall.isWicket && lastBall.wicketType != 'Retired Hurt') {
        match.wicketsB -= 1;
        if (match.wicketsB < 0) match.wicketsB = 0;
      }
      
      match.oversB = _decrementOvers(match.oversB, ballVal);
    }

    if (lastBall.extraType == 'None' || lastBall.extraType == 'Leg Bye') {
      striker.runsScored -= lastBall.run;
      if (striker.runsScored < 0) striker.runsScored = 0;
      
      striker.ballsFaced -= ballVal;
      if (striker.ballsFaced < 0) striker.ballsFaced = 0;
    }

    bowler.runsConceded -= totalRunsThisBall;
    if (bowler.runsConceded < 0) bowler.runsConceded = 0;

    if (lastBall.isWicket && lastBall.wicketType != 'Run Out' && lastBall.wicketType != 'Retired Out' && lastBall.wicketType != 'Retired Hurt') {
      bowler.wicketsTaken -= 1;
      if (bowler.wicketsTaken < 0) bowler.wicketsTaken = 0;
    }

    if (ballVal > 0) {
      bowler.oversBowled = _decrementOvers(bowler.oversBowled, 1);
    }

    if (match.status == 'Completed') {
      match.status = 'Live';
    }

    _saveMatches();
    notifyListeners();
  }

  void saveMatchesState() {
    if (!_isOnlineMode) _saveMatches();
    notifyListeners();
  }
}
