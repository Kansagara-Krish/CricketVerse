import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';

class ApiService {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:3000/api/v1';
    }
    // Auto-detect emulator vs local windows desktop execution
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000/api/v1';
    }
    return 'http://localhost:3000/api/v1';
  }

  static String? _token;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
  }

  static Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  static Future<void> _saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  static Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  // --- Auth API ---
  static Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['token'] != null) {
          await _saveToken(data['token']);
        }
        return data;
      }
      return null;
    } catch (e) {
      debugPrint('ApiService login error: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> register(String email, String password) async {
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (res.statusCode == 201) {
        final data = jsonDecode(res.body);
        if (data['token'] != null) {
          await _saveToken(data['token']);
        }
        return data;
      }
      return null;
    } catch (e) {
      debugPrint('ApiService register error: $e');
      return null;
    }
  }

  // --- Teams API ---
  static Future<List<Team>> getTeams() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/teams'), headers: _headers);
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
      );
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
      );
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('ApiService updateTeam error: $e');
      return false;
    }
  }

  static Future<bool> deleteTeam(String id) async {
    try {
      final res = await http.delete(Uri.parse('$baseUrl/teams/$id'), headers: _headers);
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
      );
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
      );
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('ApiService updatePlayer error: $e');
      return false;
    }
  }

  static Future<bool> removePlayer(String playerId) async {
    try {
      final res = await http.delete(Uri.parse('$baseUrl/teams/players/$playerId'), headers: _headers);
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('ApiService removePlayer error: $e');
      return false;
    }
  }

  // --- Matches API ---
  static Future<List<CricketMatch>> getMatches() async {
    try {
      final res = await http.get(Uri.parse('$baseUrl/matches'), headers: _headers);
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
      final res = await http.get(Uri.parse('$baseUrl/matches/$id'), headers: _headers);
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
      );
      return res.statusCode == 201;
    } catch (e) {
      debugPrint('ApiService scheduleMatch error: $e');
      return false;
    }
  }

  static Future<bool> adminActivateMatch(String id) async {
    try {
      final res = await http.post(Uri.parse('$baseUrl/matches/$id/activate'), headers: _headers);
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('ApiService adminActivateMatch error: $e');
      return false;
    }
  }

  static Future<bool> resetMatchToZero(String id) async {
    try {
      final res = await http.post(Uri.parse('$baseUrl/matches/$id/reset'), headers: _headers);
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('ApiService resetMatchToZero error: $e');
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
      );
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
      );
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
      final res = await http.post(Uri.parse('$baseUrl/scoring/$matchId/undo'), headers: _headers);
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
      final res = await http.post(Uri.parse('$baseUrl/scoring/$matchId/swap-strike'), headers: _headers);
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
      );
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
      final res = await http.post(Uri.parse('$baseUrl/scoring/$matchId/end-innings'), headers: _headers);
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
      final res = await http.post(Uri.parse('$baseUrl/scoring/$matchId/end-match'), headers: _headers);
      if (res.statusCode == 200) {
        return CricketMatch.fromJson(jsonDecode(res.body));
      }
      return null;
    } catch (e) {
      debugPrint('ApiService endMatchForce error: $e');
      return null;
    }
  }
}
