import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
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
  static const Duration defaultTimeout = Duration(seconds: 15);
  static String? _customBaseUrl;

  static String get defaultHostIp => '10.201.145.231';

  static String get baseUrl {
    if (_customBaseUrl != null && _customBaseUrl!.trim().isNotEmpty) {
      return _customBaseUrl!.trim();
    }
    if (kIsWeb) {
      return 'http://localhost:3000/api/v1';
    }
    if (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.linux) {
      return 'http://127.0.0.1:3000/api/v1';
    }
    // Render live backend - accessible anywhere across all devices
    return 'https://cricketverse-n103.onrender.com/api/v1';
  }

  static Future<void> setCustomBaseUrl(String url) async {
    _customBaseUrl = url.trim();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cricketverse_api_base_url', _customBaseUrl!);
    } catch (_) {}
  }

  static String? _token;

  static Future<void> init() async {
    try {
      _token = await AuthStorageService.getAccessToken();
    } catch (e) {
      debugPrint('ApiService.init token error: $e');
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      final savedUrl = prefs.getString('cricketverse_api_base_url');
      if (savedUrl != null && savedUrl.trim().isNotEmpty) {
        _customBaseUrl = savedUrl.trim();
      }
    } catch (_) {}
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
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/scoring/$matchId/ball'),
        headers: _headers,
        body: jsonEncode({
          'runs': runs,
          'extraType': extraType,
          'extraRuns': extraRuns,
          'isWicket': isWicket,
          'wicketType': wicketType,
          'dismissedPlayerId': dismissedPlayerId,
          'newBatsmanId': newBatsmanId,
          'newBatsmanPosition': newBatsmanPosition,
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

  static Future<CricketMatch?> undoLastBall(String matchId) async {
    try {
      final res = await http.post(Uri.parse('$baseUrl/scoring/$matchId/undo'), headers: _headers).timeout(defaultTimeout);
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
  static Future<Map<String, dynamic>> requestForgotPasswordOtp(String email) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/forgot-password/request-otp'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({'email': email.trim().toLowerCase()}),
      ).timeout(defaultTimeout);

      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        return {'success': true, 'message': data['message'] ?? 'OTP sent to your email.', 'devOtp': data['devOtp']};
      }
      return {'success': false, 'error': data['error'] ?? 'Failed to request OTP.'};
    } catch (e) {
      debugPrint('ApiService requestForgotPasswordOtp error: $e');
      return {'success': false, 'error': 'Network error. Please try again.'};
    }
  }

  static Future<Map<String, dynamic>> verifyForgotPasswordOtp(String email, String otp) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/forgot-password/verify-otp'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({'email': email.trim().toLowerCase(), 'otp': otp.trim()}),
      ).timeout(defaultTimeout);

      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        return {'success': true, 'message': data['message'] ?? 'OTP verified.'};
      }
      return {'success': false, 'error': data['error'] ?? 'Invalid OTP code.'};
    } catch (e) {
      debugPrint('ApiService verifyForgotPasswordOtp error: $e');
      return {'success': false, 'error': 'Network error. Please try again.'};
    }
  }

  static Future<Map<String, dynamic>> resetForgotPassword({
    required String email,
    required String otp,
    required String newPassword,
    String? confirmPassword,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/forgot-password/reset-password'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({
          'email': email.trim().toLowerCase(),
          'otp': otp.trim(),
          'newPassword': newPassword,
          'confirmPassword': confirmPassword ?? newPassword,
        }),
      ).timeout(defaultTimeout);

      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        return {'success': true, 'message': data['message'] ?? 'Password reset successfully.'};
      }
      return {'success': false, 'error': data['error'] ?? 'Failed to reset password.'};
    } catch (e) {
      debugPrint('ApiService resetForgotPassword error: $e');
      return {'success': false, 'error': 'Network error. Please try again.'};
    }
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
      ).timeout(defaultTimeout);

      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        return {'success': true, 'message': data['message'] ?? 'Email configuration saved.', 'config': data['config']};
      }
      return {'success': false, 'error': data['error'] ?? 'Failed to update email configuration.'};
    } catch (e) {
      debugPrint('ApiService updateEmailConfig error: $e');
      return {'success': false, 'error': 'Network error updating email configuration.'};
    }
  }

  static Future<Map<String, dynamic>> testEmailConfig(String targetEmail) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/email-config/test'),
        headers: _headers,
        body: jsonEncode({'targetEmail': targetEmail.trim()}),
      ).timeout(defaultTimeout);

      final data = jsonDecode(res.body);
      if (res.statusCode == 200) {
        return {'success': true, 'message': data['message'] ?? 'Test email sent successfully.'};
      }
      return {'success': false, 'error': data['error'] ?? 'Failed to send test email.'};
    } catch (e) {
      debugPrint('ApiService testEmailConfig error: $e');
      return {'success': false, 'error': 'Network error sending test email.'};
    }
  }
}

