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
      }
    } catch (e) {
      debugPrint('_initStorage error: $e');
    }
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

      _recalculatePlayerStats();
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading online data from MongoDB: $e');
    }
  }

  void _recalculatePlayerStats() {
    if (_teams.isEmpty) return;

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

        if (r != null && r > player.runsScored) player.runsScored = r;
        if (b != null && b > player.ballsFaced) player.ballsFaced = b;
        if (w != null && w > player.wicketsTaken) player.wicketsTaken = w;
        if (c != null && c > player.runsConceded) player.runsConceded = c;
        if (lb != null) {
          final totalOvers = (lb ~/ 6) + (lb % 6) / 10.0;
          if (totalOvers > player.oversBowled) player.oversBowled = totalOvers;
        }
        if (mc != null && mc > player.matchesPlayed) player.matchesPlayed = mc;
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
        if (_currentRole == 'Scorer') {
          _activeScorerMatchId = res['activeScorerMatchId'];
          if (_activeScorerMatchId == null && res['user']['id'] != null) {
            final String userId = res['user']['id'];
            if (userId.startsWith('scorer_')) {
              _activeScorerMatchId = userId.substring(7);
            }
          }
        } else {
          _activeScorerMatchId = null;
        }
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
      _activeScorerMatchId = res['activeScorerMatchId'];
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
        t.players.add(player);
      }
    }
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
        }
      }
    }
    notifyListeners();

    final ok = await ApiService.updatePlayer(updatedPlayer);
    if (ok) {
      await loadData();
    }
  }

  void removePlayer(String teamId, String playerId) async {
    for (var t in _teams) {
      if (t.id == teamId) {
        t.players.removeWhere((p) => p.id == playerId);
      }
    }
    for (var m in _matches) {
      if (m.teamA.id == teamId) {
        m.teamA.players.removeWhere((p) => p.id == playerId);
      }
      if (m.teamB.id == teamId) {
        m.teamB.players.removeWhere((p) => p.id == playerId);
      }
    }
    notifyListeners();

    final ok = await ApiService.removePlayer(playerId);
    if (ok) {
      await loadData();
    }
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
    _activeScorerMatchId = matchId;
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
      );
      if (updated != null) {
        final idx = _matches.indexWhere((m) => m.id == _activeScorerMatchId);
        if (idx != -1) _matches[idx] = updated;

        _recalculatePlayerStats();

        // Auto-play voice commentary if enabled in ElevenLabs settings
        final elevenSettings = ElevenLabsService().settings;
        if (elevenSettings.autoPlayVoice && updated.balls.isNotEmpty) {
          final lastBall = updated.balls.last;
          final commentary = lastBall.commentary;
          final currentOvers = updated.isFirstInnings ? updated.oversA : updated.oversB;
          final trigger = elevenSettings.commentaryTrigger;
          bool shouldSpeak = (trigger == 'Every Ball') ||
              (trigger == 'Boundaries & Wickets' && (runs >= 4 || isWicket)) ||
              (trigger == 'Over Finish' && currentOvers.toString().endsWith('.0'));
          if (shouldSpeak && commentary.isNotEmpty) {
            ElevenLabsService().speakCommentary(commentary);
          }
        }

        notifyListeners();
      }
    } catch (e) {
      debugPrint('updateScore error: $e');
    }
  }

  void switchBowler(String newBowlerId) async {
    if (_activeScorerMatchId == null) return;
    final updated = await ApiService.switchBowler(_activeScorerMatchId!, newBowlerId);
    if (updated != null) {
      final idx = _matches.indexWhere((m) => m.id == _activeScorerMatchId);
      if (idx != -1) _matches[idx] = updated;
      notifyListeners();
    }
  }

  void setStriker(String strikerId) {
    if (_activeScorerMatchId == null) return;
    final idx = _matches.indexWhere((m) => m.id == _activeScorerMatchId);
    if (idx != -1) {
      _matches[idx].currentStrikerId = strikerId;
      notifyListeners();
    }
  }

  void setNonStriker(String nonStrikerId) {
    if (_activeScorerMatchId == null) return;
    final idx = _matches.indexWhere((m) => m.id == _activeScorerMatchId);
    if (idx != -1) {
      _matches[idx].currentNonStrikerId = nonStrikerId;
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

  void undoLastBall() async {
    if (_activeScorerMatchId == null) return;
    final updated = await ApiService.undoLastBall(_activeScorerMatchId!);
    if (updated != null) {
      final idx = _matches.indexWhere((m) => m.id == _activeScorerMatchId);
      if (idx != -1) _matches[idx] = updated;
      _recalculatePlayerStats();
      notifyListeners();
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

        if (match.isFirstInnings) {
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
      }
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

  // --- Forgot Password Methods ---
  Future<Map<String, dynamic>> requestForgotPasswordOtp(String email) async {
    return await ApiService.requestForgotPasswordOtp(email);
  }

  Future<Map<String, dynamic>> verifyForgotPasswordOtp(String email, String otp) async {
    return await ApiService.verifyForgotPasswordOtp(email, otp);
  }

  Future<Map<String, dynamic>> resetForgotPassword({
    required String email,
    required String otp,
    required String newPassword,
    String? confirmPassword,
  }) async {
    return await ApiService.resetForgotPassword(
      email: email,
      otp: otp,
      newPassword: newPassword,
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
