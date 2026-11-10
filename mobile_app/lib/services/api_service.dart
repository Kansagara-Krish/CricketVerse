import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/config/app_config.dart';
import '../models/models.dart';
import 'auth_storage_service.dart';

class RegisterResponse {
  final bool isSuccess;
  final int statusCode;
  final String? errorMessage;
  final String? errorField;
  final Map<String, dynamic>? data;

  RegisterResponse({
    required this.isSuccess,
    required this.statusCode,
    this.errorMessage,
    this.errorField,
    this.data,
  });
}

class ApiService {
  static const Duration defaultTimeout = Duration(seconds: 35);

  /// Primary centralized API Base URL (defaults globally to public cloud backend)
  static String get baseUrl => AppConfig.apiBaseUrl;

  /// Candidate URLs for multi-host fallback and verification
  static List<String> get candidateBaseUrls => AppConfig.candidateApiBaseUrls;

  /// Configure runtime custom base URL (persisted in user settings)
  static Future<void> setCustomBaseUrl(String url) async {
    await AppConfig.setCustomBaseUrl(url);
  }

  static String? _token;

  static Future<void> init() async {
    await AppConfig.init();

    try {
      _token = await AuthStorageService.getAccessToken();
    } catch (e) {
      debugPrint('ApiService.init token error: $e');
    }
  }

  static Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_token != null && _token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  static Future<void> _saveToken(String token, {Map<String, dynamic>? userData}) async {
    _token = token;
    if (userData != null) {
      final user = userData['user'] ?? {};
      await AuthStorageService.saveAuthData(
        accessToken: token,
        refreshToken: userData['refreshToken'],
        userId: user['id']?.toString() ?? '',
        userEmail: user['email']?.toString() ?? '',
        userRole: user['role']?.toString() ?? 'User',
        userName: user['name']?.toString() ?? '',
      );
    } else {
      await AuthStorageService.saveAuthData(
        accessToken: token,
        userId: '',
        userEmail: '',
        userRole: 'User',
        userName: '',
      );
    }
  }

  static Future<void> clearToken() async {
    _token = null;
    await AuthStorageService.clearAuthData();
  }

  // --- Auth API ---
  static Future<bool> logout({String? name, String? email, String? role}) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/logout'),
        headers: _headers,
        body: jsonEncode({
          'name': name,
          'email': email,
          'role': role,
        }),
      ).timeout(defaultTimeout);
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('ApiService logout error: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      ).timeout(defaultTimeout);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['token'] != null) {
          await _saveToken(data['token'], userData: data);
        }
        return data;
      }
      return null;
    } catch (e) {
      debugPrint('ApiService login error: $e');
      return null;
    }
  }

  static Future<RegisterResponse> register({
    required String email,
    required String password,
    required String name,
    String? confirmPassword,
  }) async {
    try {
      final normalizedEmail = email.trim().toLowerCase();
      final body = <String, dynamic>{
        'email': normalizedEmail,
        'password': password,
        'name': name.trim(),
      };
      if (confirmPassword != null) {
        body['confirmPassword'] = confirmPassword;
      }

      final res = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode(body),
      ).timeout(defaultTimeout);

      if (res.statusCode == 201) {
        final data = jsonDecode(res.body);
        if (data['token'] != null) {
          await _saveToken(data['token'], userData: data);
        }
        return RegisterResponse(
          isSuccess: true,
          statusCode: 201,
          data: data,
        );
      }

      String? errorMsg;
      String? field;
      try {
        final errorData = jsonDecode(res.body);
        errorMsg = errorData['error'];
        field = errorData['field'];
      } catch (_) {
        errorMsg = 'Registration failed (${res.statusCode})';
      }

      return RegisterResponse(
        isSuccess: false,
        statusCode: res.statusCode,
        errorMessage: errorMsg ?? 'Registration failed.',
        errorField: field,
      );
    } catch (e) {
      debugPrint('ApiService register error: $e');
      return RegisterResponse(
        isSuccess: false,
        statusCode: 500,
        errorMessage: 'Unable to connect to server. Please verify network or server status.',
      );
    }
  }

  static Future<Map<String, dynamic>?> getMe() async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/auth/me'),
        headers: _headers,
      ).timeout(defaultTimeout);
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
      return null;
    } catch (e) {
      debugPrint('ApiService getMe error: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> updateProfile({String? name, String? email}) async {
    try {
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (email != null) body['email'] = email;

      final res = await http.put(
        Uri.parse('$baseUrl/auth/profile'),
        headers: _headers,
        body: jsonEncode(body),
      ).timeout(defaultTimeout);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['token'] != null) {
          await _saveToken(data['token']);
        }
        return data;
      }
      return null;
    } catch (e) {
      debugPrint('ApiService updateProfile error: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> requestPasswordOtp() async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/password-otp'),
        headers: _headers,
      ).timeout(defaultTimeout);

      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
      return null;
    } catch (e) {
      debugPrint('ApiService requestPasswordOtp error: $e');
      return null;
    }
  }

  static Future<bool> updatePassword(String otp, String newPassword) async {
    try {
      final res = await http.put(
        Uri.parse('$baseUrl/auth/password'),
        headers: _headers,
        body: jsonEncode({'otp': otp, 'newPassword': newPassword}),
      ).timeout(defaultTimeout);
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('ApiService updatePassword error: $e');
      return false;
    }
  }

  static Future<bool> broadcastNotification(String title, String message) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/broadcast'),
        headers: _headers,
        body: jsonEncode({'title': title, 'message': message}),
      ).timeout(defaultTimeout);
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('ApiService broadcastNotification error: $e');
      return false;
    }
  }

  // --- Teams API ---
  static Future<List<Team>> getTeams() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/teams'), headers: _headers).timeout(defaultTimeout);
      if (res.statusCode == 200) {
        final List decoded = jsonDecode(res.body);
        return decoded.map((item) => Team.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('ApiService getTeams error: $e');
      return [];
    }
  }

  static Future<bool> addTeam(String name, String shortName, String colorHex, List<Player> players) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/teams'),
        headers: _headers,
        body: jsonEncode({
          'name': name,
          'shortName': shortName,
          'logoColorHex': colorHex,
          'players': players.map((p) => p.toJson()).toList(),
        }),
      ).timeout(defaultTimeout);
      return res.statusCode == 201;
    } catch (e) {
      debugPrint('ApiService addTeam error: $e');
      return false;
    }
  }

  static Future<bool> updateTeam(String id, String name, String shortName, String colorHex) async {
    try {
      final res = await http.put(
        Uri.parse('$baseUrl/teams/$id'),
        headers: _headers,
        body: jsonEncode({
          'name': name,
          'shortName': shortName,
          'logoColorHex': colorHex,
        }),
      ).timeout(defaultTimeout);
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('ApiService updateTeam error: $e');
      return false;
    }
  }

  static Future<bool> deleteTeam(String id) async {
    try {
      final res = await http.delete(Uri.parse('$baseUrl/teams/$id'), headers: _headers).timeout(defaultTimeout);
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('ApiService deleteTeam error: $e');
      return false;
    }
  }

  static Future<bool> addPlayer(String teamId, Player player) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/teams/$teamId/players'),
        headers: _headers,
        body: jsonEncode(player.toJson()),
      ).timeout(defaultTimeout);
      return res.statusCode == 201;
    } catch (e) {
      debugPrint('ApiService addPlayer error: $e');
      return false;
    }
  }

  static Future<bool> updatePlayer(Player player) async {
    try {
      final res = await http.put(
        Uri.parse('$baseUrl/teams/players/${player.id}'),
        headers: _headers,
        body: jsonEncode(player.toJson()),
      ).timeout(defaultTimeout);
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('ApiService updatePlayer error: $e');
      return false;
    }
  }

  static Future<bool> removePlayer(String playerId) async {
    try {
      final res = await http.delete(Uri.parse('$baseUrl/teams/players/$playerId'), headers: _headers).timeout(defaultTimeout);
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('ApiService removePlayer error: $e');
      return false;
    }
  }

  // --- Matches API ---
  static Future<List<CricketMatch>> getMatches() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/matches'), headers: _headers).timeout(defaultTimeout);
      if (res.statusCode == 200) {
        final List decoded = jsonDecode(res.body);
        return decoded.map((item) => CricketMatch.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('ApiService getMatches error: $e');
      return [];
    }
  }

  static Future<CricketMatch?> getMatchById(String id) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/matches/$id'), headers: _headers).timeout(defaultTimeout);
      if (res.statusCode == 200) {
        return CricketMatch.fromJson(jsonDecode(res.body));
      }
      return null;
    } catch (e) {
      debugPrint('ApiService getMatchById error: $e');
      return null;
    }
  }

  static Future<bool> scheduleMatch({
    required String teamAId,
    required String teamBId,
    required String matchType,
    required String venue,
    required String date,
    required String time,
    required String scorerUser,
    required String scorerPass,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/matches'),
        headers: _headers,
        body: jsonEncode({
          'teamAId': teamAId,
          'teamBId': teamBId,
          'matchType': matchType,
          'venue': venue,
          'date': date,
          'time': time,
          'scorerUser': scorerUser,
          'scorerPass': scorerPass,
        }),
      ).timeout(defaultTimeout);
      return res.statusCode == 201;
    } catch (e) {
      debugPrint('ApiService scheduleMatch error: $e');
      return false;
    }
  }

  static Future<bool> updateMatch({
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
    try {
      final res = await http.put(
        Uri.parse('$baseUrl/matches/$matchId'),
        headers: _headers,
        body: jsonEncode({
          'teamAId': teamAId,
          'teamBId': teamBId,
          'matchType': matchType,
          'venue': venue,
          'date': date,
          'time': time,
          'scorerUser': scorerUser,
          'scorerPass': scorerPass,
        }),
      ).timeout(defaultTimeout);
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('ApiService updateMatch error: $e');
      return false;
    }
  }

  static Future<bool> adminActivateMatch(String id) async {
    try {
      final res = await http.post(Uri.parse('$baseUrl/matches/$id/activate'), headers: _headers).timeout(defaultTimeout);
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('ApiService adminActivateMatch error: $e');
      return false;
    }
  }

  static Future<bool> resetMatchToZero(String id) async {
    try {
      final res = await http.post(Uri.parse('$baseUrl/matches/$id/reset'), headers: _headers).timeout(defaultTimeout);
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('ApiService resetMatchToZero error: $e');
      return false;
    }
  }

  static Future<bool> deleteMatch(String id) async {
    try {
      final res = await http.delete(Uri.parse('$baseUrl/matches/$id'), headers: _headers).timeout(defaultTimeout);
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('ApiService deleteMatch error: $e');
      return false;
    }
  }

  // --- Scoring API ---
  static Future<CricketMatch?> startMatchSetup(String matchId, String tossWinner, String decision, String firstBattingTeamId) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/scoring/$matchId/toss'),
        headers: _headers,
        body: jsonEncode({
          'tossWinner': tossWinner,
          'tossDecision': decision,
          'firstBattingTeamId': firstBattingTeamId,
        }),
      ).timeout(defaultTimeout);
      if (res.statusCode == 200) {
        return CricketMatch.fromJson(jsonDecode(res.body));
      }
      return null;
    } catch (e) {
      debugPrint('ApiService startMatchSetup error: $e');
      return null;
    }
  }

  static Future<CricketMatch?> updateScore({
    required String matchId,
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
    try {
      final key = idempotencyKey ??
          '${DateTime.now().millisecondsSinceEpoch}_${matchId}_${runs}_${extraType}_${extraRuns}_${isWicket}_${DateTime.now().microsecondsSinceEpoch}';
      final headers = Map<String, String>.from(_headers);
      headers['X-Idempotency-Key'] = key;

      final res = await http.post(
        Uri.parse('$baseUrl/scoring/$matchId/ball'),
        headers: headers,
        body: jsonEncode({
          'runs': runs,
          'extraType': extraType,
          'extraRuns': extraRuns,
          'isWicket': isWicket,
          'wicketType': wicketType,
          'dismissedPlayerId': dismissedPlayerId,
          'newBatsmanId': newBatsmanId,
          'newBatsmanPosition': newBatsmanPosition,
          'idempotencyKey': key,
        }),
      ).timeout(defaultTimeout);
      if (res.statusCode == 200) {
        return CricketMatch.fromJson(jsonDecode(res.body));
      }
      return null;
    } catch (e) {
      debugPrint('ApiService updateScore error: $e');
      return null;
    }
  }

  static Future<CricketMatch?> undoLastBall(String matchId, {String? idempotencyKey}) async {
    try {
      final headers = Map<String, String>.from(_headers);
      if (idempotencyKey != null) {
        headers['X-Idempotency-Key'] = idempotencyKey;
      }
      final res = await http.post(
        Uri.parse('$baseUrl/scoring/$matchId/undo'),
        headers: headers,
        body: idempotencyKey != null ? jsonEncode({'idempotencyKey': idempotencyKey}) : null,
      ).timeout(defaultTimeout);
      if (res.statusCode == 200) {
        return CricketMatch.fromJson(jsonDecode(res.body));
      }
      return null;
    } catch (e) {
      debugPrint('ApiService undoLastBall error: $e');
      return null;
    }
  }

  static Future<CricketMatch?> swapStrikers(String matchId) async {
    try {
      final res = await http.post(Uri.parse('$baseUrl/scoring/$matchId/swap-strike'), headers: _headers).timeout(defaultTimeout);
      if (res.statusCode == 200) {
        return CricketMatch.fromJson(jsonDecode(res.body));
      }
      return null;
    } catch (e) {
      debugPrint('ApiService swapStrikers error: $e');
      return null;
    }
  }

  static Future<CricketMatch?> switchBowler(String matchId, String bowlerId) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/scoring/$matchId/switch-bowler'),
        headers: _headers,
        body: jsonEncode({'bowlerId': bowlerId}),
      ).timeout(defaultTimeout);
      if (res.statusCode == 200) {
        return CricketMatch.fromJson(jsonDecode(res.body));
      }
      return null;
    } catch (e) {
      debugPrint('ApiService switchBowler error: $e');
      return null;
    }
  }

  static Future<CricketMatch?> endInningsOrMatch(String matchId) async {
    try {
      final res = await http.post(Uri.parse('$baseUrl/scoring/$matchId/end-innings'), headers: _headers).timeout(defaultTimeout);
      if (res.statusCode == 200) {
        return CricketMatch.fromJson(jsonDecode(res.body));
      }
      return null;
    } catch (e) {
      debugPrint('ApiService endInningsOrMatch error: $e');
      return null;
    }
  }

  static Future<CricketMatch?> endMatchForce(String matchId) async {
    try {
      final res = await http.post(Uri.parse('$baseUrl/scoring/$matchId/end-match'), headers: _headers).timeout(defaultTimeout);
      if (res.statusCode == 200) {
        return CricketMatch.fromJson(jsonDecode(res.body));
      }
      return null;
    } catch (e) {
      debugPrint('ApiService endMatchForce error: $e');
      return null;
    }
  }

  // --- Tournaments API ---
  static Future<List<Tournament>> getTournaments() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/tournaments'), headers: _headers).timeout(defaultTimeout);
      if (res.statusCode == 200) {
        final List decoded = jsonDecode(res.body);
        return decoded.map((item) => Tournament.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('ApiService getTournaments error: $e');
      return [];
    }
  }

  static Future<Tournament?> getTournamentById(String id) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/tournaments/$id'), headers: _headers).timeout(defaultTimeout);
      if (res.statusCode == 200) {
        return Tournament.fromJson(jsonDecode(res.body));
      }
      return null;
    } catch (e) {
      debugPrint('ApiService getTournamentById error: $e');
      return null;
    }
  }

  static Future<bool> createTournament(Tournament tournament) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/tournaments'),
        headers: _headers,
        body: jsonEncode(tournament.toJson()),
      ).timeout(defaultTimeout);
      return res.statusCode == 201;
    } catch (e) {
      debugPrint('ApiService createTournament error: $e');
      return false;
    }
  }

  static Future<bool> updateTournament(Tournament tournament) async {
    try {
      final res = await http.put(
        Uri.parse('$baseUrl/tournaments/${tournament.id}'),
        headers: _headers,
        body: jsonEncode(tournament.toJson()),
      ).timeout(defaultTimeout);
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('ApiService updateTournament error: $e');
      return false;
    }
  }

  static Future<bool> deleteTournament(String id) async {
    try {
      final res = await http.delete(Uri.parse('$baseUrl/tournaments/$id'), headers: _headers).timeout(defaultTimeout);
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('ApiService deleteTournament error: $e');
      return false;
    }
  }

  // --- Prediction API ---
  static Future<Map<String, dynamic>?> getMatchPrediction(String matchId) async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/matches/$matchId/prediction'), headers: _headers).timeout(defaultTimeout);
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
      return null;
    } catch (e) {
      debugPrint('ApiService getMatchPrediction error: $e');
      return null;
    }
  }

  // --- Notifications API ---
  static Future<List<Map<String, dynamic>>> getNotifications() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/notifications'), headers: _headers).timeout(defaultTimeout);
      if (res.statusCode == 200) {
        final List decoded = jsonDecode(res.body);
        return decoded.cast<Map<String, dynamic>>();
      }
      return [];
    } catch (e) {
      debugPrint('ApiService getNotifications error: $e');
      return [];
    }
  }

  static Future<bool> createNotification(String title, String message, {String? category}) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/notifications'),
        headers: _headers,
        body: jsonEncode({
          'title': title,
          'message': message,
          if (category != null) 'category': category,
        }),
      ).timeout(defaultTimeout);
      return res.statusCode == 201;
    } catch (e) {
      debugPrint('ApiService createNotification error: $e');
      return false;
    }
  }

  static Future<bool> markNotificationRead(String notifId) async {
    try {
      final res = await http.put(Uri.parse('$baseUrl/notifications/$notifId/read'), headers: _headers).timeout(defaultTimeout);
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('ApiService markNotificationRead error: $e');
      return false;
    }
  }

  // --- Analytics API ---
  static Future<Map<String, dynamic>?> getSystemAnalytics() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/analytics/stats'), headers: _headers).timeout(defaultTimeout);
      if (res.statusCode == 200) {
        return jsonDecode(res.body);
      }
      return null;
    } catch (e) {
      debugPrint('ApiService getSystemAnalytics error: $e');
      return null;
    }
  }

  // --- Voice / TTS API ---
  static Future<String?> generateCommentaryVoice(String text, {String? voiceId}) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/ai/voice'),
        headers: _headers,
        body: jsonEncode({
          'text': text,
          if (voiceId != null) 'voiceId': voiceId,
        }),
      ).timeout(defaultTimeout);
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['audioBase64'];
      }
      return null;
    } catch (e) {
      debugPrint('ApiService generateCommentaryVoice error: $e');
      return null;
    }
  }

  // --- Managers / Scorers API ---
  static Future<List<Manager>> getManagers() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/managers'), headers: _headers).timeout(defaultTimeout);
      if (res.statusCode == 200) {
        final List decoded = jsonDecode(res.body);
        return decoded.map((item) => Manager.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('ApiService getManagers error: $e');
      return [];
    }
  }

  static Future<Manager?> createManager({
    required String name,
    required String username,
    required String password,
    String? phone,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/managers'),
        headers: _headers,
        body: jsonEncode({
          'name': name.trim(),
          'username': username.trim().toLowerCase(),
          'password': password.trim(),
          'phone': phone?.trim(),
        }),
      ).timeout(defaultTimeout);
      if (res.statusCode == 201) {
        final data = jsonDecode(res.body);
        if (data['manager'] != null) {
          return Manager.fromJson(data['manager']);
        }
      }
      return null;
    } catch (e) {
      debugPrint('ApiService createManager error: $e');
      return null;
    }
  }

  static Future<bool> deleteManager(String id) async {
    try {
      final res = await http.delete(
        Uri.parse('$baseUrl/managers/$id'),
        headers: _headers,
      ).timeout(defaultTimeout);
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('ApiService deleteManager error: $e');
      return false;
    }
  }

  // --- Forgot Password API ---
  static Future<Map<String, dynamic>> requestForgotPasswordOtp(
    String email, {
    String? requestId,
  }) async {
    final reqId = requestId ?? 'fp_${DateTime.now().millisecondsSinceEpoch}';
    final cleanEmail = email.trim().toLowerCase();
    final payload = {'email': cleanEmail};
    String lastError = 'Unable to send verification code. Please check your network and try again.';

    for (final host in candidateBaseUrls) {
      for (final endpoint in ['/auth/forgot-password', '/auth/forgot-password/request-otp']) {
        final fullUrl = '$host$endpoint';
        debugPrint('[FP_TRACE][$reqId] Request started: POST $fullUrl');
        debugPrint('[FP_TRACE][$reqId] Body keys: ${payload.keys.toList()}');

        try {
          final res = await http.post(
            Uri.parse(fullUrl),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'X-Request-Id': reqId,
            },
            body: jsonEncode(payload),
          ).timeout(const Duration(seconds: 35));

          debugPrint('[FP_TRACE][$reqId] Response status: ${res.statusCode}');
          // Redact tokens/OTP if any ever appeared
          final safeBody = res.body.replaceAll(RegExp(r'"resetToken"\s*:\s*"[^"]+"'), '"resetToken":"[REDACTED]"');
          debugPrint('[FP_TRACE][$reqId] Response body: $safeBody');

          if (res.statusCode == 404) {
            debugPrint('[FP_TRACE][$reqId] 404 on $endpoint, trying fallback route...');
            continue;
          }

          final data = jsonDecode(res.body);
          if (res.statusCode == 200) {
            if (data['emailSent'] == false || data['success'] == false) {
              return {
                'success': false,
                'error': data['warning'] ?? data['error'] ?? data['message'] ?? 'Email delivery failed on server.',
              };
            }
            return {
              'success': true,
              'message': data['message'] ?? 'A 6-digit verification code has been sent to your email.',
            };
          }
          if (data['error'] != null) {
            return {'success': false, 'error': data['error']};
          }
          return {'success': false, 'error': 'Server error (${res.statusCode}). Please try again.'};
        } catch (e, stack) {
          final timedOut = e is TimeoutException || e.toString().contains('TimeoutException');
          debugPrint('[FP_TRACE][$reqId] Exception type: ${e.runtimeType}, timedOut=$timedOut, error=$e');
          debugPrint('[FP_TRACE][$reqId] StackTrace: $stack');
          if (timedOut) {
            lastError = 'Server is waking up or taking too long to respond. Please tap Send Verification Code again.';
          } else {
            lastError = 'Connection error. Please ensure you have an active internet connection.';
          }
        }
      }
    }
    return {'success': false, 'error': lastError};
  }

  static Future<Map<String, dynamic>> resendForgotPasswordOtp(String email) async {
    final cleanEmail = email.trim().toLowerCase();
    String lastError = 'Unable to resend verification code. Please try again.';

    for (final host in candidateBaseUrls) {
      for (final endpoint in ['/auth/resend-reset-otp', '/auth/forgot-password/resend-otp', '/auth/forgot-password']) {
        try {
          final res = await http.post(
            Uri.parse('$host$endpoint'),
            headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
            body: jsonEncode({'email': cleanEmail}),
          ).timeout(const Duration(seconds: 30));

          if (res.statusCode == 404) continue;

          final data = jsonDecode(res.body);
          if (res.statusCode == 200) {
            if (data['emailSent'] == false || data['success'] == false) {
              return {
                'success': false,
                'error': data['warning'] ?? data['error'] ?? data['message'] ?? 'Email delivery failed on server.',
              };
            }
            return {'success': true, 'message': data['message'] ?? 'A fresh 6-digit code has been sent to your email.'};
          }
          if (data['error'] != null) {
            return {'success': false, 'error': data['error']};
          }
          return {'success': false, 'error': 'Server error (${res.statusCode}). Please try again.'};
        } catch (e) {
          if (e.toString().contains('TimeoutException')) {
            lastError = 'Request timed out while waiting for server. Please retry.';
          } else {
            lastError = 'Connection error. Please check your internet connection.';
          }
        }
      }
    }
    return {'success': false, 'error': lastError};
  }

  static Future<Map<String, dynamic>> verifyForgotPasswordOtp(String email, String otp) async {
    final cleanEmail = email.trim().toLowerCase();
    final cleanOtp = otp.trim();
    String lastError = 'Invalid or expired verification code.';

    for (final host in candidateBaseUrls) {
      for (final endpoint in ['/auth/verify-reset-otp', '/auth/forgot-password/verify-otp']) {
        try {
          final res = await http.post(
            Uri.parse('$host$endpoint'),
            headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
            body: jsonEncode({'email': cleanEmail, 'otp': cleanOtp}),
          ).timeout(const Duration(seconds: 25));

          if (res.statusCode == 404) continue;

          final data = jsonDecode(res.body);
          if (res.statusCode == 200) {
            return {
              'success': true,
              'message': data['message'] ?? 'OTP verified successfully.',
              'resetToken': data['resetToken'],
            };
          }
          if (data['error'] != null) {
            return {'success': false, 'error': data['error']};
          }
        } catch (e) {
          lastError = 'Connection error verifying code. Please retry.';
        }
      }
    }
    return {'success': false, 'error': lastError};
  }

  static Future<Map<String, dynamic>> resetForgotPassword({
    required String email,
    required String newPassword,
    String? resetToken,
    String? otp,
    String? confirmPassword,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    String lastError = 'Failed to reset password. Please try again.';

    for (final host in candidateBaseUrls) {
      for (final endpoint in ['/auth/reset-password', '/auth/forgot-password/reset-password']) {
        try {
          final res = await http.post(
            Uri.parse('$host$endpoint'),
            headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
            body: jsonEncode({
              'email': cleanEmail,
              'newPassword': newPassword,
              'confirmPassword': confirmPassword ?? newPassword,
              if (resetToken != null && resetToken.isNotEmpty) 'resetToken': resetToken,
              if (otp != null && otp.isNotEmpty) 'otp': otp.trim(),
            }),
          ).timeout(const Duration(seconds: 25));

          if (res.statusCode == 404) continue;

          final data = jsonDecode(res.body);
          if (res.statusCode == 200) {
            return {'success': true, 'message': data['message'] ?? 'Password reset successfully.'};
          }
          if (data['error'] != null) {
            return {'success': false, 'error': data['error']};
          }
        } catch (e) {
          lastError = 'Connection error updating password. Please retry.';
        }
      }
    }
    return {'success': false, 'error': lastError};
  }

  // --- Admin Email Sender & App Password Configuration API ---
  static Future<Map<String, dynamic>?> getEmailConfig() async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/auth/email-config'),
        headers: _headers,
      ).timeout(defaultTimeout);

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return data['config'] as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      debugPrint('ApiService getEmailConfig error: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>> updateEmailConfig({
    required String senderEmail,
    String? appPassword,
    String? senderName,
    String? host,
    int? port,
    bool? secure,
  }) async {
    try {
      final body = <String, dynamic>{
        'senderEmail': senderEmail.trim(),
        if (appPassword != null && appPassword.trim().isNotEmpty) 'appPassword': appPassword.trim(),
        if (senderName != null) 'senderName': senderName.trim(),
        if (host != null) 'host': host.trim(),
        if (port != null) 'port': port,
        if (secure != null) 'secure': secure,
      };

      final res = await http.put(
        Uri.parse('$baseUrl/auth/email-config'),
        headers: _headers,
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 30));

      Map<String, dynamic> data = {};
      try {
        data = jsonDecode(res.body);
      } catch (_) {}

      if (res.statusCode == 200) {
        return {'success': true, 'message': data['message'] ?? 'Email configuration saved.', 'config': data['config']};
      }
      return {'success': false, 'error': data['error'] ?? 'Server error (${res.statusCode}): Failed to update email config.'};
    } catch (e) {
      debugPrint('ApiService updateEmailConfig error: $e');
      return {'success': false, 'error': 'Connection timed out or failed to reach backend server.'};
    }
  }

  static Future<Map<String, dynamic>> testEmailConfig(String targetEmail) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/email-config/test'),
        headers: _headers,
        body: jsonEncode({'targetEmail': targetEmail.trim()}),
      ).timeout(const Duration(seconds: 30));

      Map<String, dynamic> data = {};
      try {
        data = jsonDecode(res.body);
      } catch (_) {}

      if (res.statusCode == 200) {
        return {'success': true, 'message': data['message'] ?? 'Test email sent successfully.'};
      }
      return {'success': false, 'error': data['error'] ?? 'Failed to send test email.'};
    } catch (e) {
      debugPrint('ApiService testEmailConfig error: $e');
      return {'success': false, 'error': 'Connection timed out or failed to reach backend server.'};
    }
  }

  // --- Centralized ElevenLabs & AI Config API ---
  static Future<Map<String, dynamic>?> getAiConfig() async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/ai/config'),
        headers: _headers,
      ).timeout(defaultTimeout);

      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      debugPrint('ApiService getAiConfig error: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>> updateAiConfig(Map<String, dynamic> configData) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/ai/config'),
        headers: _headers,
        body: jsonEncode(configData),
      ).timeout(defaultTimeout);

      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        return {'success': true, 'message': data['message'] ?? 'AI config saved.', 'config': data['config']};
      }
      return {'success': false, 'error': data['error'] ?? 'Failed to update AI config.'};
    } catch (e) {
      debugPrint('ApiService updateAiConfig error: $e');
      return {'success': false, 'error': 'Network error updating AI configuration.'};
    }
  }

  static Future<Map<String, dynamic>> testElevenLabsKey(String apiKey) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/ai/test-key'),
        headers: _headers,
        body: jsonEncode({'apiKey': apiKey.trim()}),
      ).timeout(defaultTimeout);

      final data = jsonDecode(res.body);
      return data is Map<String, dynamic> ? data : {'success': false, 'message': 'Unknown response'};
    } catch (e) {
      debugPrint('ApiService testElevenLabsKey error: $e');
      return {'success': false, 'message': 'Network error reaching ElevenLabs server: $e'};
    }
  }

  // --- Tournament Live Standings API ---
  static Future<Map<String, dynamic>?> getTournamentStandings(String tournamentId) async {
    try {
      final res = await http.get(
        Uri.parse('$baseUrl/tournaments/$tournamentId/standings'),
        headers: _headers,
      ).timeout(defaultTimeout);

      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      debugPrint('ApiService getTournamentStandings error: $e');
      return null;
    }
  }
}

