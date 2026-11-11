import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import 'api_service.dart';
import 'socket_service.dart';
import 'auth_storage_service.dart';
import 'notification_cache_service.dart';
import 'elevenlabs_service.dart';

class StorageService with ChangeNotifier {
  SharedPreferences? _prefs;
  List<Team> _teams = [];
  List<CricketMatch> _matches = [];
  List<Tournament> _tournaments = [];
  List<Manager> _managers = [];
  Timer? _delayedCommentaryTimer;

  // App Session State
  String? _currentUserEmail;
  String? _currentRole; // "Admin", "Scorer", "User"
  String? _activeScorerMatchId; // Active match ID currently being scored
  String? _currentUserName;

  List<Team> get teams => _teams;
  List<CricketMatch> get matches => _matches;
  List<Tournament> get tournaments => _tournaments;
  List<Manager> get managers => _managers;
  String? get currentRole => _currentRole;
  String? get currentUserEmail => _currentUserEmail;
  String? get currentUserName => _currentUserName;
  String? get activeScorerMatchId => _activeScorerMatchId;
  bool get isOnlineMode => true;
  int get pendingScoreCount => 0;
  int get unreadNotificationCount => NotificationCacheService.getUnreadCount();

  String? _lastAuthError;
  String? get lastAuthError => _lastAuthError;
  String? _lastAuthErrorField;
  String? get lastAuthErrorField => _lastAuthErrorField;

  StorageService() {
    _initStorage();
  }

  Future<void> _initStorage() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      await ApiService.init();
      final hasSession = await AuthStorageService.hasValidSession();
      if (hasSession) {
        await tryTokenAuth();
      } else {
        await loadData();
      }
      _setupGlobalSocketListener();
    } catch (e) {
      debugPrint('_initStorage error: $e');
    }
  }

  void _setupGlobalSocketListener() {
    SocketService.connect();
    SocketService.listenToMatchUpdates((data) {
      try {
        final updatedMatch = CricketMatch.fromJson(data);
        final teamMap = {for (var t in _teams) t.id: t};
        _syncSingleMatchWithTeams(updatedMatch, teamMap);

        final idx = _matches.indexWhere((m) => m.id == updatedMatch.id);
        if (idx != -1) {
          final existing = _matches[idx];
          // Preserve local in-flight active pitch IDs if backend payload had them empty
          if (updatedMatch.currentStrikerId.isEmpty && existing.currentStrikerId.isNotEmpty) {
            updatedMatch.currentStrikerId = existing.currentStrikerId;
          }
          if (updatedMatch.currentNonStrikerId.isEmpty && existing.currentNonStrikerId.isNotEmpty) {
            updatedMatch.currentNonStrikerId = existing.currentNonStrikerId;
          }
          if (updatedMatch.currentBowlerId.isEmpty && existing.currentBowlerId.isNotEmpty) {
            updatedMatch.currentBowlerId = existing.currentBowlerId;
          }
          _matches[idx] = updatedMatch;
        } else {
          _matches.add(updatedMatch);
        }

        if (updatedMatch.latestMilestone != null) {
          SocketService.dispatchMilestone(updatedMatch.latestMilestone!.toJson());
        }

        _recalculatePlayerStats();
        notifyListeners();
      } catch (e) {
        debugPrint('Error handling global socket match update: $e');
      }
    });

    SocketService.listenToTeamUpdates((data) {
      try {
        final updatedTeam = Team.fromJson(data);
        final tIdx = _teams.indexWhere((t) => t.id == updatedTeam.id);
        if (tIdx != -1) {
          _teams[tIdx] = updatedTeam;
        } else {
          _teams.add(updatedTeam);
        }

        // Live sync squad to all matches containing this team
        _syncAllMatchesWithLatestTeams();
        _recalculatePlayerStats();
        notifyListeners();
      } catch (e) {
        debugPrint('Error handling global socket team update: $e');
      }
    });

    // Auto-refresh active match if socket reconnects
    SocketService.addReconnectListener(() {
      if (_activeScorerMatchId != null) {
        debugPrint('Socket reconnected: refreshing active match $_activeScorerMatchId');
        refreshMatch(_activeScorerMatchId!);
      }
    });
  }

  void isolateMatchStats(CricketMatch m) {
    final Map<String, Player> matchPlayerMap = {};
    final Map<String, Player> nameMap = {};

    void registerPlayers(List<Player> players) {
      for (final p in players) {
        p.runsScored = 0;
        p.ballsFaced = 0;
        p.wicketsTaken = 0;
        p.runsConceded = 0;
        p.oversBowled = 0.0;
        p.isOut = false;
        p.dismissalInfo = '';
        matchPlayerMap[p.id] = p;
        nameMap[p.name.trim().toLowerCase()] = p;
      }
    }

    registerPlayers(m.playingXI_A);
    registerPlayers(m.playingXI_B);

    final Map<String, int> legalBallsMap = {};

    // Calculate match stats strictly from this match's confirmed balls
    for (final b in m.balls) {
      final runs = b.run;
      final extraRuns = b.extraRun;
      final extraType = b.extraType;
      final isWicket = b.isWicket;
      final wicketType = b.wicketType;

      Player? striker = b.strikerId != null ? matchPlayerMap[b.strikerId] : null;
      striker ??= nameMap[b.batsmanName.trim().toLowerCase()];

      if (striker != null) {
        if (extraType == 'None' || extraType == 'No Ball') {
          striker.runsScored += runs;
        }
        if (extraType != 'Wide') {
          striker.ballsFaced += 1;
        }
      }

      Player? bowler = b.bowlerId != null ? matchPlayerMap[b.bowlerId] : null;
      bowler ??= nameMap[b.bowlerName.trim().toLowerCase()];

      if (bowler != null) {
        if (extraType == 'None' || extraType == 'Wide' || extraType == 'No Ball') {
          bowler.runsConceded += (runs + extraRuns);
        }
        final isLegal = extraType != 'Wide' && extraType != 'No Ball';
        if (isLegal) {
          legalBallsMap[bowler.id] = (legalBallsMap[bowler.id] ?? 0) + 1;
        }
        final isBowlerCredited = isWicket && !['Run Out', 'Retired Out', 'Retired Hurt', 'Timed Out', 'Obstructing Field'].contains(wicketType);
        if (isBowlerCredited) {
          bowler.wicketsTaken += 1;
        }
      }

      if (isWicket) {
        Player? dismissed = striker;
        if (dismissed != null) {
          dismissed.isOut = true;
          dismissed.dismissalInfo = '${wicketType.isNotEmpty ? wicketType : "Out"} b ${b.bowlerName}';
        }
      }
    }

    // Set oversBowled
    for (final p in matchPlayerMap.values) {
      final legalBalls = legalBallsMap[p.id] ?? 0;
      final ov = (legalBalls ~/ 6) + ((legalBalls % 6) / 10.0);
      p.oversBowled = double.parse(ov.toStringAsFixed(1));
    }

    // Ensure teamA.players and teamB.players match the match-isolated playingXI lists
    m.teamA.players.clear();
    m.teamA.players.addAll(m.playingXI_A);
    m.teamB.players.clear();
    m.teamB.players.addAll(m.playingXI_B);
  }

  void _syncSingleMatchWithTeams(CricketMatch m, Map<String, Team> teamMap) {
    // 1. Sync Team A
    final liveA = teamMap[m.teamA.id];
    if (liveA != null) {
      m.teamA.name = liveA.name;
      m.teamA.shortName = liveA.shortName;

      final livePlayerMapA = {for (var p in liveA.players) p.id: p};
      final existingXI = List<Player>.from(m.playingXI_A);
      final updatedXiA = <Player>[];
      final seenIdsA = <String>{};

      for (var p in existingXI) {
        final live = livePlayerMapA[p.id];
        if (live != null) {
          updatedXiA.add(Player(
            id: p.id,
            name: live.name,
            role: live.role,
            nationality: live.nationality,
            isCaptain: live.isCaptain,
            isViceCaptain: live.isViceCaptain,
            runsScored: p.runsScored,
            ballsFaced: p.ballsFaced,
            wicketsTaken: p.wicketsTaken,
            runsConceded: p.runsConceded,
            oversBowled: p.oversBowled,
            matchesPlayed: 1,
            isOut: p.isOut,
            dismissalInfo: p.dismissalInfo,
          ));
        } else {
          final hasParticipated = (p.runsScored > 0) ||
              (p.ballsFaced > 0) ||
              (p.oversBowled > 0) ||
              p.isOut ||
              (p.id == m.currentStrikerId) ||
              (p.id == m.currentNonStrikerId) ||
              (p.id == m.currentBowlerId);
          if (hasParticipated) {
            updatedXiA.add(p);
          }
        }
        seenIdsA.add(p.id);
      }

      for (var lp in liveA.players) {
        if (!seenIdsA.contains(lp.id)) {
          updatedXiA.add(Player(
            id: lp.id,
            name: lp.name,
            role: lp.role,
            nationality: lp.nationality,
            isCaptain: lp.isCaptain,
            isViceCaptain: lp.isViceCaptain,
            runsScored: 0,
            ballsFaced: 0,
            wicketsTaken: 0,
            runsConceded: 0,
            oversBowled: 0.0,
            matchesPlayed: 1,
            isOut: false,
            dismissalInfo: '',
          ));
          seenIdsA.add(lp.id);
        }
      }
      m.playingXI_A = updatedXiA;
      m.teamA.players.clear();
      m.teamA.players.addAll(updatedXiA);
    }

    // 2. Sync Team B
    final liveB = teamMap[m.teamB.id];
    if (liveB != null) {
      m.teamB.name = liveB.name;
      m.teamB.shortName = liveB.shortName;

      final livePlayerMapB = {for (var p in liveB.players) p.id: p};
      final existingXI = List<Player>.from(m.playingXI_B);
      final updatedXiB = <Player>[];
      final seenIdsB = <String>{};

      for (var p in existingXI) {
        final live = livePlayerMapB[p.id];
        if (live != null) {
          updatedXiB.add(Player(
            id: p.id,
            name: live.name,
            role: live.role,
            nationality: live.nationality,
            isCaptain: live.isCaptain,
            isViceCaptain: live.isViceCaptain,
            runsScored: p.runsScored,
            ballsFaced: p.ballsFaced,
            wicketsTaken: p.wicketsTaken,
            runsConceded: p.runsConceded,
            oversBowled: p.oversBowled,
            matchesPlayed: 1,
            isOut: p.isOut,
            dismissalInfo: p.dismissalInfo,
          ));
        } else {
          final hasParticipated = (p.runsScored > 0) ||
              (p.ballsFaced > 0) ||
              (p.oversBowled > 0) ||
              p.isOut ||
              (p.id == m.currentStrikerId) ||
              (p.id == m.currentNonStrikerId) ||
              (p.id == m.currentBowlerId);
          if (hasParticipated) {
            updatedXiB.add(p);
          }
        }
        seenIdsB.add(p.id);
      }

      for (var lp in liveB.players) {
        if (!seenIdsB.contains(lp.id)) {
          updatedXiB.add(Player(
            id: lp.id,
            name: lp.name,
            role: lp.role,
            nationality: lp.nationality,
            isCaptain: lp.isCaptain,
            isViceCaptain: lp.isViceCaptain,
            runsScored: 0,
            ballsFaced: 0,
            wicketsTaken: 0,
            runsConceded: 0,
            oversBowled: 0.0,
            matchesPlayed: 1,
            isOut: false,
            dismissalInfo: '',
          ));
          seenIdsB.add(lp.id);
        }
      }
      m.playingXI_B = updatedXiB;
      m.teamB.players.clear();
      m.teamB.players.addAll(updatedXiB);
    }

    // 3. Update player names in ball records
    final allPlayersMap = <String, Player>{};
    if (liveA != null) {
      for (var p in liveA.players) {
        allPlayersMap[p.id] = p;
      }
    }
    if (liveB != null) {
      for (var p in liveB.players) {
        allPlayersMap[p.id] = p;
      }
    }
    for (var ball in m.balls) {
      if (ball.strikerId != null && allPlayersMap.containsKey(ball.strikerId)) {
        ball.batsmanName = allPlayersMap[ball.strikerId]!.name;
      }
      if (ball.bowlerId != null && allPlayersMap.containsKey(ball.bowlerId)) {
        ball.bowlerName = allPlayersMap[ball.bowlerId]!.name;
      }
    }

    // Isolate match stats strictly from confirmed match balls
    isolateMatchStats(m);
  }

  void _syncAllMatchesWithLatestTeams() {
    if (_teams.isEmpty) return;
    final teamMap = {for (var t in _teams) t.id: t};
    for (var m in _matches) {
      _syncSingleMatchWithTeams(m, teamMap);
    }
  }

  Future<CricketMatch?> refreshMatch(String matchId) async {
    try {
      final remote = await ApiService.getMatchById(matchId);
      if (remote != null) {
        final teamMap = {for (var t in _teams) t.id: t};
        _syncSingleMatchWithTeams(remote, teamMap);
        final idx = _matches.indexWhere((m) => m.id == matchId);
        if (idx != -1) {
          _matches[idx] = remote;
        } else {
          _matches.add(remote);
        }
        if (remote.latestMilestone != null) {
          SocketService.dispatchMilestone(remote.latestMilestone!.toJson());
        }
        _recalculatePlayerStats();
        notifyListeners();
        return remote;
      }
    } catch (e) {
      debugPrint('Error refreshing match $matchId: $e');
    }
    return null;
  }

  Future<void> toggleOnlineMode(bool val) async {
    await loadData();
    notifyListeners();
  }

  Future<void> loadData() async {
    try {
      final remoteTeams = await ApiService.getTeams();
      _teams = remoteTeams;

      final remoteMatches = await ApiService.getMatches();
      _matches = remoteMatches;

      final remoteTournaments = await ApiService.getTournaments();
      _tournaments = remoteTournaments;

      final remoteManagers = await ApiService.getManagers();
      _managers = remoteManagers;

      _syncAllMatchesWithLatestTeams();

      _recalculatePlayerStats();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading online data from MongoDB: $e');
    }
  }

  void _recalculatePlayerStats() {
    if (_teams.isEmpty) return;

    for (var m in _matches) {
      isolateMatchStats(m);
    }

    final Map<String, int> runsMap = {};
    final Map<String, int> ballsMap = {};
    final Map<String, int> wicketsMap = {};
    final Map<String, int> concededMap = {};
    final Map<String, int> legalBallsMap = {};
    final Map<String, int> matchesCountMap = {};

    for (var m in _matches) {
      final matchPlayers = <String>{};

      for (var p in m.playingXI_A) {
        matchPlayers.add(p.id);
        runsMap[p.id] = (runsMap[p.id] ?? 0) + p.runsScored;
        ballsMap[p.id] = (ballsMap[p.id] ?? 0) + p.ballsFaced;
        wicketsMap[p.id] = (wicketsMap[p.id] ?? 0) + p.wicketsTaken;
        concededMap[p.id] = (concededMap[p.id] ?? 0) + p.runsConceded;
        final o = p.oversBowled;
        final balls = (o.floor() * 6) + ((o - o.floor()) * 10).round();
        legalBallsMap[p.id] = (legalBallsMap[p.id] ?? 0) + balls;
      }

      for (var p in m.playingXI_B) {
        matchPlayers.add(p.id);
        runsMap[p.id] = (runsMap[p.id] ?? 0) + p.runsScored;
        ballsMap[p.id] = (ballsMap[p.id] ?? 0) + p.ballsFaced;
        wicketsMap[p.id] = (wicketsMap[p.id] ?? 0) + p.wicketsTaken;
        concededMap[p.id] = (concededMap[p.id] ?? 0) + p.runsConceded;
        final o = p.oversBowled;
        final balls = (o.floor() * 6) + ((o - o.floor()) * 10).round();
        legalBallsMap[p.id] = (legalBallsMap[p.id] ?? 0) + balls;
      }

      for (var pId in matchPlayers) {
        matchesCountMap[pId] = (matchesCountMap[pId] ?? 0) + 1;
      }
    }

    for (var team in _teams) {
      for (var player in team.players) {
        final r = runsMap[player.id];
        final b = ballsMap[player.id];
        final w = wicketsMap[player.id];
        final c = concededMap[player.id];
        final lb = legalBallsMap[player.id];
        final mc = matchesCountMap[player.id];

        player.runsScored = r ?? 0;
        player.ballsFaced = b ?? 0;
        player.wicketsTaken = w ?? 0;
        player.runsConceded = c ?? 0;
        if (lb != null) {
          final totalOvers = (lb ~/ 6) + (lb % 6) / 10.0;
          player.oversBowled = double.parse(totalOvers.toStringAsFixed(1));
        } else {
          player.oversBowled = 0.0;
        }
        player.matchesPlayed = mc ?? 0;
      }
    }
  }

  Future<void> loadManagers() async {
    try {
      final remoteManagers = await ApiService.getManagers();
      _managers = remoteManagers;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading managers: $e');
    }
  }

  Future<Manager?> addManager({
    required String name,
    required String username,
    required String password,
    String? phone,
  }) async {
    final created = await ApiService.createManager(
      name: name,
      username: username,
      password: password,
      phone: phone,
    );
    if (created != null) {
      _managers.removeWhere((m) => m.id == created.id || m.username == created.username);
      _managers.insert(0, created);
      notifyListeners();
      return created;
    }
    return null;
  }

  Future<bool> deleteManager(String id) async {
    final ok = await ApiService.deleteManager(id);
    if (ok) {
      _managers.removeWhere((m) => m.id == id);
      notifyListeners();
      return true;
    }
    return false;
  }

  // --- Real-time WebSockets Subscriptions ---
  void subscribeToMatchLiveUpdates(String matchId) {
    SocketService.connect();
    SocketService.joinMatch(matchId);
  }

  void unsubscribeFromMatchLiveUpdates(String matchId) {
    SocketService.leaveMatch(matchId);
  }

  // --- Authentications ---
  Future<bool> tryTokenAuth() async {
    final hasSession = await AuthStorageService.hasValidSession();
    if (!hasSession) return false;

    try {
      final res = await ApiService.getMe();
      if (res != null && res['user'] != null) {
        _currentUserEmail = res['user']['email'];
        _currentRole = res['user']['role'];
        _currentUserName = res['user']['name'];
        // Always land manager/scorer on their main dashboard (Assigned Matches list) on auth
        _activeScorerMatchId = null;
        await loadData();
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('tryTokenAuth online error: $e');
    }

    return false;
  }

  Future<bool> login(String usernameOrEmail, String password) async {
    final res = await ApiService.login(usernameOrEmail, password);
    if (res != null && res['user'] != null) {
      _currentUserEmail = res['user']['email'];
      _currentRole = res['user']['role'];
      _currentUserName = res['user']['name'];
      // Always land manager/scorer on their main dashboard (Assigned Matches list) after login
      _activeScorerMatchId = null;
      await loadData();
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> register({
    required String name,
    required String email,
    required String password,
    String? phone,
    String? confirmPassword,
  }) async {
    _lastAuthError = null;
    _lastAuthErrorField = null;

    final trimmedName = name.trim();
    final normalizedEmail = email.trim().toLowerCase();

    final res = await ApiService.register(
      email: normalizedEmail,
      password: password,
      name: trimmedName,
      phone: phone,
      confirmPassword: confirmPassword,
    );

    if (res.isSuccess && res.data != null) {
      _currentUserEmail = res.data!['user']?['email'] ?? normalizedEmail;
      _currentRole = res.data!['user']?['role'] ?? 'User';
      _currentUserName = res.data!['user']?['name'] ?? trimmedName;
      await loadData();
      notifyListeners();
      return true;
    }
    _lastAuthError = res.errorMessage ?? 'Registration failed.';
    _lastAuthErrorField = res.errorField;
    notifyListeners();
    return false;
  }

  Future<void> logout() async {
    final prevName = _currentUserName;
    final prevEmail = _currentUserEmail;
    final prevRole = _currentRole;

    await ApiService.logout(name: prevName, email: prevEmail, role: prevRole);
    await ApiService.clearToken();
    SocketService.disconnect();

    _currentUserEmail = null;
    _currentRole = null;
    _currentUserName = null;
    _activeScorerMatchId = null;

    await AuthStorageService.clearAuthData();
    await NotificationCacheService.clearCache();

    notifyListeners();
  }

  // --- Admin / CRUD Methods ---
  void adminActivateMatch(String matchId) async {
    final ok = await ApiService.adminActivateMatch(matchId);
    if (ok) {
      _activeScorerMatchId = matchId;
      await loadData();
    }
  }

  void addTeam(String name, String shortName, String colorHex, List<Player> players) async {
    final ok = await ApiService.addTeam(name, shortName, colorHex, players);
    if (ok) {
      await loadData();
    }
  }

  void updateTeam(String teamId, String name, String shortName, String colorHex) async {
    final ok = await ApiService.updateTeam(teamId, name, shortName, colorHex);
    if (ok) {
      await loadData();
    }
  }

  void deleteTeam(String teamId) async {
    final ok = await ApiService.deleteTeam(teamId);
    if (ok) {
      await loadData();
    }
  }

  void addPlayer(String teamId, Player player) async {
    for (var t in _teams) {
      if (t.id == teamId) {
        t.players.removeWhere((p) => p.id == player.id);
        t.players.add(player);
      }
    }
    _syncAllMatchesWithLatestTeams();
    _recalculatePlayerStats();
    notifyListeners();

    final ok = await ApiService.addPlayer(teamId, player);
    if (ok) {
      await loadData();
    }
  }

  void updatePlayer(String teamId, Player updatedPlayer) async {
    for (var t in _teams) {
      if (t.id == teamId) {
        final idx = t.players.indexWhere((p) => p.id == updatedPlayer.id);
        if (idx != -1) {
          t.players[idx] = updatedPlayer;
        } else {
          t.players.add(updatedPlayer);
        }
      }
    }
    _syncAllMatchesWithLatestTeams();
    _recalculatePlayerStats();
    notifyListeners();

    final ok = await ApiService.updatePlayer(updatedPlayer);
    if (ok) {
      await loadData();
    }
  }

  Future<String?> removePlayer(String teamId, String playerId) async {
    // Safety check: Cannot remove player if actively participating in live match
    for (var m in _matches) {
      if (m.status == 'Live') {
        if (m.currentStrikerId == playerId || m.currentNonStrikerId == playerId || m.currentBowlerId == playerId) {
          return 'Cannot delete this player while they are actively batting or bowling in an ongoing Live match. Please change the active batsman/bowler first.';
        }
      }
    }

    final ok = await ApiService.removePlayer(playerId);
    if (!ok) {
      return 'Failed to remove player. Please check your internet connection and try again.';
    }

    for (var t in _teams) {
      if (t.id == teamId) {
        t.players.removeWhere((p) => p.id == playerId);
      }
    }
    _syncAllMatchesWithLatestTeams();
    _recalculatePlayerStats();
    notifyListeners();
    await loadData();
    return null;
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
    if (ok) {
      await loadData();
    }
  }

  void updateMatch({
    required String matchId,
    required String teamAId,
    required String teamBId,
    required String matchType,
    required String venue,
    required String date,
    required String time,
    required String scorerUser,
    required String scorerPass,
  }) async {
    final ok = await ApiService.updateMatch(
      matchId: matchId,
      teamAId: teamAId,
      teamBId: teamBId,
      matchType: matchType,
      venue: venue,
      date: date,
      time: time,
      scorerUser: scorerUser,
      scorerPass: scorerPass,
    );
    if (ok) {
      await loadData();
    }
  }

  Future<bool> deleteMatch(String matchId) async {
    final ok = await ApiService.deleteMatch(matchId);
    if (ok) {
      _matches.removeWhere((m) => m.id == matchId);
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<void> addTournament(Tournament tournament) async {
    await ApiService.createTournament(tournament);
    await loadData();
  }

  Future<void> updateTournament(Tournament updated) async {
    await ApiService.updateTournament(updated);
    await loadData();
  }

  Future<void> deleteTournament(String id) async {
    await ApiService.deleteTournament(id);
    await loadData();
  }

  // --- Scorer / Live Scoring Methods ---
  Future<bool> startMatchSetup(String matchId, String tossWinnerTeam, String decision, String firstBattingTeamId) async {
    final updated = await ApiService.startMatchSetup(matchId, tossWinnerTeam, decision, firstBattingTeamId);
    if (updated != null) {
      final idx = _matches.indexWhere((m) => m.id == matchId);
      if (idx != -1) {
        _matches[idx] = updated;
      } else {
        _matches.add(updated);
      }
      _activeScorerMatchId = matchId;
      notifyListeners();
      return true;
    }
    return false;
  }

  void setActiveScorerMatchId(String? matchId) {
    if (_activeScorerMatchId != null && _activeScorerMatchId != matchId) {
      unsubscribeFromMatchLiveUpdates(_activeScorerMatchId!);
    }
    _activeScorerMatchId = matchId;
    if (matchId != null) {
      subscribeToMatchLiveUpdates(matchId);
    }
    notifyListeners();
  }

  void swapStrikers() async {
    if (_activeScorerMatchId == null) return;
    final updated = await ApiService.swapStrikers(_activeScorerMatchId!);
    if (updated != null) {
      final idx = _matches.indexWhere((m) => m.id == _activeScorerMatchId);
      if (idx != -1) _matches[idx] = updated;
      notifyListeners();
    }
  }

  final Set<String> _localCelebratedMilestones = {};

  Player? _findMatchPlayer(CricketMatch match, String playerId) {
    if (playerId.isEmpty) return null;
    final normalized = playerId.trim().toLowerCase();

    // 1. Search playingXI_A (live match state)
    for (final p in match.playingXI_A) {
      if (p.id.trim().toLowerCase() == normalized || p.name.trim().toLowerCase() == normalized) {
        return p;
      }
    }
    // 2. Search playingXI_B (live match state)
    for (final p in match.playingXI_B) {
      if (p.id.trim().toLowerCase() == normalized || p.name.trim().toLowerCase() == normalized) {
        return p;
      }
    }
    // 3. Search teamA.players (squad roster)
    for (final p in match.teamA.players) {
      if (p.id.trim().toLowerCase() == normalized || p.name.trim().toLowerCase() == normalized) {
        return p;
      }
    }
    // 4. Search teamB.players (squad roster)
    for (final p in match.teamB.players) {
      if (p.id.trim().toLowerCase() == normalized || p.name.trim().toLowerCase() == normalized) {
        return p;
      }
    }
    return null;
  }

  Future<bool> updateScore({
    required int runs,
    required String extraType,
    required int extraRuns,
    required bool isWicket,
    required String wicketType,
    String? dismissedPlayerId,
    String? newBatsmanId,
    String? newBatsmanPosition,
    String? idempotencyKey,
  }) async {
    if (_activeScorerMatchId == null) return false;

    // Snapshot pre-ball striker stats for fail-safe milestone detection
    final curMatchIdx = _matches.indexWhere((m) => m.id == _activeScorerMatchId);
    CricketMatch? matchBefore = curMatchIdx != -1 ? _matches[curMatchIdx] : null;
    int prevStrikerRuns = 0;
    int prevBallsFaced = 0;
    String strikerId = '';
    String strikerName = 'Batsman';
    String teamName = '';
    String teamShortName = '';
    String teamColorHex = '0xFF078B70';
    int curInnings = 1;
    Player? bowlerBefore;
    int prevBowlerWickets = 0;

    if (matchBefore != null) {
      curInnings = matchBefore.isFirstInnings ? 1 : 2;
      final isTeamABatting = matchBefore.battingTeamId == matchBefore.teamA.id;
      final battingTeam = isTeamABatting ? matchBefore.teamA : matchBefore.teamB;
      teamName = battingTeam.name;
      teamShortName = battingTeam.shortName;
      teamColorHex = battingTeam.logoColorHex;

      strikerId = matchBefore.currentStrikerId;
      Player? strikerPlayer = _findMatchPlayer(matchBefore, strikerId);

      // Fallback: If currentStrikerId wasn't found by id, find from batting playingXI
      if (strikerPlayer == null) {
        final batXI = isTeamABatting ? matchBefore.playingXI_A : matchBefore.playingXI_B;
        if (batXI.isNotEmpty) {
          strikerPlayer = batXI.first;
          strikerId = strikerPlayer.id;
        }
      }

      if (strikerPlayer != null) {
        prevStrikerRuns = strikerPlayer.runsScored;
        prevBallsFaced = strikerPlayer.ballsFaced;
        strikerName = strikerPlayer.name;
      }

      if (matchBefore.currentBowlerId.isNotEmpty) {
        bowlerBefore = _findMatchPlayer(matchBefore, matchBefore.currentBowlerId);
        prevBowlerWickets = bowlerBefore?.wicketsTaken ?? 0;
      }
      debugPrint('[MILESTONE_MANAGER_DEBUG] Pre-ball striker snapshot: name=$strikerName, id=$strikerId, runs=$prevStrikerRuns, balls=$prevBallsFaced');
    }

    try {
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
        idempotencyKey: idempotencyKey,
      );
      if (updated != null) {
        final idx = _matches.indexWhere((m) => m.id == _activeScorerMatchId);
        if (idx != -1) _matches[idx] = updated;

        // 1. If backend returned latestMilestone, dispatch and broadcast it
        if (updated.latestMilestone != null) {
          debugPrint('[MILESTONE_MANAGER_DEBUG] updateScore: Backend returned latestMilestone: ${updated.latestMilestone!.type} for ${updated.latestMilestone!.batsmanName}');
          SocketService.dispatchMilestone(updated.latestMilestone!.toJson());
          SocketService.emitMilestoneCelebration(updated.latestMilestone!.toJson());
        } else {
          // 2. Client-side fail-safe detection
          final isTeamABatting = updated.battingTeamId == updated.teamA.id;
          final battingTeam = isTeamABatting ? updated.teamA : updated.teamB;
          final bowlingTeam = isTeamABatting ? updated.teamB : updated.teamA;
          final batXI = isTeamABatting ? updated.playingXI_A : updated.playingXI_B;

          Player? strikerAfter = _findMatchPlayer(updated, strikerId);
          if (strikerAfter == null && batXI.isNotEmpty) {
            strikerAfter = batXI.where((p) => p.name.trim().toLowerCase() == strikerName.trim().toLowerCase()).firstOrNull ?? batXI.first;
          }

          final newStrikerRuns = strikerAfter != null ? strikerAfter.runsScored : (prevStrikerRuns + runs);
          final newBallsFaced = strikerAfter != null ? strikerAfter.ballsFaced : (prevBallsFaced + (extraType != 'Wide' ? 1 : 0));
          final finalStrikerName = (strikerAfter != null && strikerAfter.name.isNotEmpty) ? strikerAfter.name : strikerName;

          final m100Key = '${updated.id}_${curInnings}_${strikerId}_100';
          final m50Key = '${updated.id}_${curInnings}_${strikerId}_50';

          MilestoneCelebration? detected;
          if (prevStrikerRuns < 100 && newStrikerRuns >= 100 && !_localCelebratedMilestones.contains(m100Key)) {
            _localCelebratedMilestones.add(m100Key);
            detected = MilestoneCelebration(
              eventId: 'ms_${updated.id}_${curInnings}_${strikerId}_100_${DateTime.now().millisecondsSinceEpoch}',
              matchId: updated.id,
              type: '100',
              batsmanId: strikerId,
              batsmanName: finalStrikerName,
              runs: newStrikerRuns,
              ballsFaced: newBallsFaced,
              teamName: battingTeam.name.isNotEmpty ? battingTeam.name : teamName,
              teamShortName: battingTeam.shortName.isNotEmpty ? battingTeam.shortName : teamShortName,
              teamColorHex: battingTeam.logoColorHex.isNotEmpty ? battingTeam.logoColorHex : teamColorHex,
              innings: curInnings,
              timestamp: DateTime.now(),
            );
          } else if (prevStrikerRuns < 50 && newStrikerRuns >= 50 && !_localCelebratedMilestones.contains(m50Key)) {
            _localCelebratedMilestones.add(m50Key);
            detected = MilestoneCelebration(
              eventId: 'ms_${updated.id}_${curInnings}_${strikerId}_50_${DateTime.now().millisecondsSinceEpoch}',
              matchId: updated.id,
              type: '50',
              batsmanId: strikerId,
              batsmanName: finalStrikerName,
              runs: newStrikerRuns,
              ballsFaced: newBallsFaced,
              teamName: battingTeam.name.isNotEmpty ? battingTeam.name : teamName,
              teamShortName: battingTeam.shortName.isNotEmpty ? battingTeam.shortName : teamShortName,
              teamColorHex: battingTeam.logoColorHex.isNotEmpty ? battingTeam.logoColorHex : teamColorHex,
              innings: curInnings,
              timestamp: DateTime.now(),
            );
          } else if (runs == 6 && (extraType == 'None' || extraType == 'No Ball')) {
            detected = MilestoneCelebration(
              eventId: 'six_${updated.id}_${curInnings}_${DateTime.now().millisecondsSinceEpoch}',
              matchId: updated.id,
              type: 'SIX',
              batsmanId: strikerId,
              batsmanName: finalStrikerName,
              runs: 6,
              ballsFaced: newBallsFaced,
              bowlerId: bowlerBefore?.id ?? '',
              bowlerName: bowlerBefore?.name ?? '',
              teamName: battingTeam.name.isNotEmpty ? battingTeam.name : teamName,
              teamShortName: battingTeam.shortName.isNotEmpty ? battingTeam.shortName : teamShortName,
              teamColorHex: battingTeam.logoColorHex.isNotEmpty ? battingTeam.logoColorHex : teamColorHex,
              innings: curInnings,
              timestamp: DateTime.now(),
            );
          } else if (isWicket) {
            final isBowlerCredited = !['Run Out', 'Retired Out', 'Retired Hurt'].contains(wicketType);
            final bowlerAfter = bowlerBefore != null ? _findMatchPlayer(updated, bowlerBefore.id) : null;
            final newBowlerWickets = bowlerAfter?.wicketsTaken ?? (prevBowlerWickets + (isBowlerCredited ? 1 : 0));
            final m5wKey = '${updated.id}_${curInnings}_${bowlerBefore?.id}_5w';

            if (isBowlerCredited && bowlerBefore != null && prevBowlerWickets < 5 && newBowlerWickets >= 5 && !_localCelebratedMilestones.contains(m5wKey)) {
              _localCelebratedMilestones.add(m5wKey);
              detected = MilestoneCelebration(
                eventId: '5w_${updated.id}_${curInnings}_${bowlerBefore.id}_${DateTime.now().millisecondsSinceEpoch}',
                matchId: updated.id,
                type: 'FIVE_WICKET',
                bowlerId: bowlerBefore.id,
                bowlerName: bowlerBefore.name,
                bowlerWickets: newBowlerWickets,
                bowlerRunsConceded: bowlerAfter?.runsConceded ?? bowlerBefore.runsConceded,
                bowlerOvers: bowlerAfter?.oversBowled ?? bowlerBefore.oversBowled,
                batsmanId: '',
                batsmanName: bowlerBefore.name,
                runs: 0,
                ballsFaced: 0,
                teamName: bowlingTeam.name,
                teamShortName: bowlingTeam.shortName,
                teamColorHex: bowlingTeam.logoColorHex,
                innings: curInnings,
                timestamp: DateTime.now(),
              );
            } else {
              detected = MilestoneCelebration(
                eventId: 'wkt_${updated.id}_${curInnings}_${DateTime.now().millisecondsSinceEpoch}',
                matchId: updated.id,
                type: 'WICKET',
                batsmanId: dismissedPlayerId ?? strikerId,
                batsmanName: dismissedPlayerId != null
                    ? (_findMatchPlayer(updated, dismissedPlayerId)?.name ?? finalStrikerName)
                    : finalStrikerName,
                bowlerId: isBowlerCredited ? (bowlerBefore?.id ?? '') : '',
                bowlerName: isBowlerCredited ? (bowlerBefore?.name ?? '') : '',
                dismissalType: wicketType.isNotEmpty ? wicketType : 'Out',
                teamRuns: isTeamABatting ? updated.runsA : updated.runsB,
                teamWickets: isTeamABatting ? updated.wicketsA : updated.wicketsB,
                teamOvers: isTeamABatting ? updated.oversA : updated.oversB,
                runs: strikerAfter?.runsScored ?? prevStrikerRuns,
                ballsFaced: newBallsFaced,
                teamName: battingTeam.name.isNotEmpty ? battingTeam.name : teamName,
                teamShortName: battingTeam.shortName.isNotEmpty ? battingTeam.shortName : teamShortName,
                teamColorHex: battingTeam.logoColorHex.isNotEmpty ? battingTeam.logoColorHex : teamColorHex,
                innings: curInnings,
                timestamp: DateTime.now(),
              );
            }
          }

          if (updated.status == 'Completed' && updated.winnerName.isNotEmpty) {
            final winKey = 'win_${updated.id}';
            if (!_localCelebratedMilestones.contains(winKey)) {
              _localCelebratedMilestones.add(winKey);
              final winCelebration = MilestoneCelebration(
                eventId: 'win_${updated.id}_${DateTime.now().millisecondsSinceEpoch}',
                matchId: updated.id,
                type: 'MATCH_WON',
                winnerTeamName: updated.winnerName,
                resultText: updated.resultText,
                teamName: updated.winnerName,
                batsmanId: '',
                batsmanName: updated.winnerName,
                runs: isTeamABatting ? updated.runsA : updated.runsB,
                ballsFaced: 0,
                innings: curInnings,
                timestamp: DateTime.now(),
              );
              detected = winCelebration;
            }
          }

          if (detected != null) {
            debugPrint('[MILESTONE_MANAGER_DEBUG] Client detected milestone: ${detected.type} for ${detected.batsmanName}');
            updated.latestMilestone = detected;
            SocketService.dispatchMilestone(detected.toJson());
            SocketService.emitMilestoneCelebration(detected.toJson());
          }
        }

        _recalculatePlayerStats();
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('updateScore error: $e');
      return false;
    }
  }

  void switchBowler(String newBowlerId) async {
    if (_activeScorerMatchId == null) return;
    final idx = _matches.indexWhere((m) => m.id == _activeScorerMatchId);
    if (idx != -1) {
      _matches[idx].currentBowlerId = newBowlerId;
      notifyListeners();
    }
    final updated = await ApiService.switchBowler(_activeScorerMatchId!, newBowlerId);
    if (updated != null) {
      final currentIdx = _matches.indexWhere((m) => m.id == _activeScorerMatchId);
      if (currentIdx != -1) _matches[currentIdx] = updated;
      notifyListeners();
    }
  }

  void setStriker(String strikerId) {
    if (_activeScorerMatchId == null) return;
    final idx = _matches.indexWhere((m) => m.id == _activeScorerMatchId);
    if (idx != -1) {
      _matches[idx].currentStrikerId = strikerId;
      saveMatchesState();
      notifyListeners();
    }
  }

  void setNonStriker(String nonStrikerId) {
    if (_activeScorerMatchId == null) return;
    final idx = _matches.indexWhere((m) => m.id == _activeScorerMatchId);
    if (idx != -1) {
      _matches[idx].currentNonStrikerId = nonStrikerId;
      saveMatchesState();
      notifyListeners();
    }
  }

  void setTarget(int target) {
    if (_activeScorerMatchId == null) return;
    final idx = _matches.indexWhere((m) => m.id == _activeScorerMatchId);
    if (idx != -1) {
      _matches[idx].target = target;
      notifyListeners();
    }
  }

  void endOver() {
    if (_activeScorerMatchId == null) return;
    final idx = _matches.indexWhere((m) => m.id == _activeScorerMatchId);
    if (idx != -1) {
      final match = _matches[idx];
      final temp = match.currentStrikerId;
      match.currentStrikerId = match.currentNonStrikerId;
      match.currentNonStrikerId = temp;

      final bowlingTeam = match.battingTeamId == match.teamA.id ? match.teamB : match.teamA;
      if (bowlingTeam.players.isNotEmpty) {
        final currentBowlerIndex = bowlingTeam.players.indexWhere((p) => p.id == match.currentBowlerId);
        int nextBowlerIndex = (currentBowlerIndex - 1) % bowlingTeam.players.length;
        if (nextBowlerIndex < 0) nextBowlerIndex = bowlingTeam.players.length - 1;
        match.currentBowlerId = bowlingTeam.players[nextBowlerIndex].id;
      }
      notifyListeners();
    }
  }

  void endInningsOrMatch() async {
    if (_activeScorerMatchId == null) return;
    final updated = await ApiService.endInningsOrMatch(_activeScorerMatchId!);
    if (updated != null) {
      final idx = _matches.indexWhere((m) => m.id == _activeScorerMatchId);
      if (idx != -1) _matches[idx] = updated;
      notifyListeners();
    }
  }

  void endMatchForce() async {
    if (_activeScorerMatchId == null) return;
    final updated = await ApiService.endMatchForce(_activeScorerMatchId!);
    if (updated != null) {
      final idx = _matches.indexWhere((m) => m.id == _activeScorerMatchId);
      if (idx != -1) _matches[idx] = updated;
      notifyListeners();
    }
  }

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

  void resetMatchToZero(String matchId) async {
    final ok = await ApiService.resetMatchToZero(matchId);
    if (ok) {
      await loadData();
    } else {
      final idx = _matches.indexWhere((m) => m.id == matchId);
      if (idx != -1) {
        final match = _matches[idx];
        match.runsA = 0;
        match.wicketsA = 0;
        match.oversA = 0.0;
        match.runsB = 0;
        match.wicketsB = 0;
        match.oversB = 0.0;
        match.target = 0;
        match.status = 'Upcoming';
        match.isFirstInnings = true;
        match.tossWinner = '';
        match.tossDecision = '';
        match.battingTeamId = '';
        match.balls.clear();
        for (final p in match.teamA.players) {
          p.runsScored = 0;
          p.ballsFaced = 0;
          p.wicketsTaken = 0;
          p.runsConceded = 0;
          p.oversBowled = 0.0;
        }
        for (final p in match.teamB.players) {
          p.runsScored = 0;
          p.ballsFaced = 0;
          p.wicketsTaken = 0;
          p.runsConceded = 0;
          p.oversBowled = 0.0;
        }
        _recalculatePlayerStats();
        notifyListeners();
      }
    }
  }

  Future<bool> undoLastBall({String? idempotencyKey}) async {
    _delayedCommentaryTimer?.cancel();
    ElevenLabsService().stopAudio();
    if (_activeScorerMatchId == null) return false;
    final updated = await ApiService.undoLastBall(_activeScorerMatchId!, idempotencyKey: idempotencyKey);
    if (updated != null) {
      final idx = _matches.indexWhere((m) => m.id == _activeScorerMatchId);
      if (idx != -1) {
        _matches[idx] = updated;
        final curInnings = updated.isFirstInnings ? 1 : 2;
        final striker = _findMatchPlayer(updated, updated.currentStrikerId);
        if (striker != null) {
          if (striker.runsScored < 100) {
            _localCelebratedMilestones.remove('${updated.id}_${curInnings}_${striker.id}_100');
          }
          if (striker.runsScored < 50) {
            _localCelebratedMilestones.remove('${updated.id}_${curInnings}_${striker.id}_50');
          }
        }
      }
      _recalculatePlayerStats();
      notifyListeners();
      return true;
    } else {
      // Offline fallback: Revert locally
      final idx = _matches.indexWhere((m) => m.id == _activeScorerMatchId);
      if (idx != -1 && _matches[idx].balls.isNotEmpty) {
        final match = _matches[idx];
        final lastBall = match.balls.removeLast();
        final runsNum = lastBall.run;
        final extraRunsNum = lastBall.extraRun;
        final totalRunsThisBall = runsNum + extraRunsNum;
        final isLegalBall = lastBall.extraType != 'Wide' && lastBall.extraType != 'No Ball';

        final isTeamABatting = match.battingTeamId == match.teamA.id;
        if (isTeamABatting) {
          match.runsA = (match.runsA - totalRunsThisBall).clamp(0, 9999);
          if (lastBall.isWicket && lastBall.wicketType != 'Retired Hurt') {
            match.wicketsA = (match.wicketsA - 1).clamp(0, 10);
          }
          if (isLegalBall) match.oversA = _decrementOvers(match.oversA);
        } else {
          match.runsB = (match.runsB - totalRunsThisBall).clamp(0, 9999);
          if (lastBall.isWicket && lastBall.wicketType != 'Retired Hurt') {
            match.wicketsB = (match.wicketsB - 1).clamp(0, 10);
          }
          if (isLegalBall) match.oversB = _decrementOvers(match.oversB);
        }

        if (lastBall.strikerId != null && lastBall.strikerId!.isNotEmpty) {
          match.currentStrikerId = lastBall.strikerId!;
        }
        if (lastBall.nonStrikerId != null && lastBall.nonStrikerId!.isNotEmpty) {
          match.currentNonStrikerId = lastBall.nonStrikerId!;
        }
        if (lastBall.bowlerId != null && lastBall.bowlerId!.isNotEmpty) {
          match.currentBowlerId = lastBall.bowlerId!;
        }

        _recalculatePlayerStats();
        notifyListeners();
        return true;
      }
      return false;
    }
  }

  double _decrementOvers(double currentOvers) {
    int oversInt = currentOvers.toInt();
    int ballsInt = ((currentOvers - oversInt) * 10).round();

    ballsInt -= 1;
    if (ballsInt < 0) {
      if (oversInt > 0) {
        oversInt -= 1;
        ballsInt = 5;
      } else {
        ballsInt = 0;
      }
    }

    return oversInt + (ballsInt / 10.0);
  }

  void saveMatchesState() {
    _recalculatePlayerStats();
    notifyListeners();
  }

  // --- Profile, Password and Settings persistence helper methods ---
  Future<bool> updateProfile({String? name, String? email}) async {
    final res = await ApiService.updateProfile(name: name, email: email);
    if (res != null && res['user'] != null) {
      _currentUserEmail = res['user']['email'];
      _currentUserName = res['user']['name'];
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<String?> requestPasswordOtp() async {
    final res = await ApiService.requestPasswordOtp();
    if (res != null && res['otp'] != null) {
      return res['otp'].toString();
    }
    return null;
  }

  Future<bool> updatePassword(String otp, String newPassword) async {
    return await ApiService.updatePassword(otp, newPassword);
  }

  // --- Forgot Password Methods (Twilio SMS OTP) ---
  Future<Map<String, dynamic>> requestForgotPasswordOtp(String phone, {String? requestId}) async {
    return await ApiService.requestForgotPasswordOtp(phone, requestId: requestId);
  }

  Future<Map<String, dynamic>> resendForgotPasswordOtp(String phone) async {
    return await ApiService.resendForgotPasswordOtp(phone);
  }

  Future<Map<String, dynamic>> verifyForgotPasswordOtp(String phone, String otp) async {
    return await ApiService.verifyForgotPasswordOtp(phone, otp);
  }

  Future<Map<String, dynamic>> resetForgotPassword({
    required String phone,
    required String newPassword,
    String? resetToken,
    String? otp,
    String? confirmPassword,
  }) async {
    return await ApiService.resetForgotPassword(
      phone: phone,
      newPassword: newPassword,
      resetToken: resetToken,
      otp: otp,
      confirmPassword: confirmPassword,
    );
  }

  // --- Admin Email Sender & App Password Configuration Methods ---
  Future<Map<String, dynamic>?> getEmailConfig() async {
    return await ApiService.getEmailConfig();
  }

  Future<Map<String, dynamic>> updateEmailConfig({
    required String senderEmail,
    String? appPassword,
    String? senderName,
    String? host,
    int? port,
    bool? secure,
  }) async {
    return await ApiService.updateEmailConfig(
      senderEmail: senderEmail,
      appPassword: appPassword,
      senderName: senderName,
      host: host,
      port: port,
      secure: secure,
    );
  }

  Future<Map<String, dynamic>> testEmailConfig(String targetEmail) async {
    return await ApiService.testEmailConfig(targetEmail);
  }


  // Favorites persistence
  List<String> getFavoriteTeams() {
    if (_currentUserEmail == null) return [];
    final key = 'favorites_$_currentUserEmail';
    return _prefs?.getStringList(key) ?? [];
  }

  Future<void> toggleFavoriteTeam(String teamId) async {
    if (_currentUserEmail == null) return;
    final key = 'favorites_$_currentUserEmail';
    final current = getFavoriteTeams();
    if (current.contains(teamId)) {
      current.remove(teamId);
    } else {
      current.add(teamId);
    }
    await _prefs?.setStringList(key, current);
    notifyListeners();
  }

  // Notification settings persistence
  bool getNotificationSetting(String settingKey) {
    if (_currentUserEmail == null) return true;
    final key = 'notif_${settingKey}_$_currentUserEmail';
    return _prefs?.getBool(key) ?? true;
  }

  Future<void> setNotificationSetting(String settingKey, bool value) async {
    if (_currentUserEmail == null) return;
    final key = 'notif_${settingKey}_$_currentUserEmail';
    await _prefs?.setBool(key, value);
    notifyListeners();
  }

  // ─── Search History Methods (1 Week Retention Policy) ───────────────────────
  List<SearchHistoryItem> getSearchHistory() {
    if (_prefs == null) return [];
    final rawList = _prefs!.getStringList('admin_search_history_v2') ?? [];
    final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));

    List<SearchHistoryItem> validItems = [];
    bool needsSave = false;

    for (var str in rawList) {
      try {
        final item = SearchHistoryItem.fromJson(json.decode(str));
        if (item.timestamp.isAfter(sevenDaysAgo)) {
          validItems.add(item);
        } else {
          needsSave = true;
        }
      } catch (_) {}
    }

    if (needsSave) {
      _saveSearchHistory(validItems);
    }
    return validItems;
  }

  Future<void> addSearchHistoryItem(SearchHistoryItem newItem) async {
    List<SearchHistoryItem> currentList = getSearchHistory();
    currentList.removeWhere((item) =>
        item.title.toLowerCase() == newItem.title.toLowerCase() &&
        item.category == newItem.category);

    currentList.insert(0, newItem);

    if (currentList.length > 30) {
      currentList = currentList.sublist(0, 30);
    }

    await _saveSearchHistory(currentList);
    notifyListeners();
  }

  Future<void> removeSearchHistoryItem(String id) async {
    List<SearchHistoryItem> currentList = getSearchHistory();
    currentList.removeWhere((item) => item.id == id);
    await _saveSearchHistory(currentList);
    notifyListeners();
  }

  Future<void> clearSearchHistory() async {
    if (_prefs != null) {
      await _prefs!.remove('admin_search_history_v2');
      notifyListeners();
    }
  }

  Future<void> _saveSearchHistory(List<SearchHistoryItem> list) async {
    if (_prefs == null) return;
    final jsonStrings = list.map((item) => json.encode(item.toJson())).toList();
    await _prefs!.setStringList('admin_search_history_v2', jsonStrings);
  }
}
