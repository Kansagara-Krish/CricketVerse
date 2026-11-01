// ignore_for_file: non_constant_identifier_names

class Player {
  final String id;
  final String name;
  final String role; // "Batter", "Bowler", "All-rounder"
  final String nationality;
  bool isCaptain;
  bool isViceCaptain;
  int runsScored;
  int ballsFaced;
  int wicketsTaken;
  int runsConceded;
  double oversBowled;
  int matchesPlayed;
  bool isOut;
  String dismissalInfo;

  Player({
    required this.id,
    required this.name,
    required this.role,
    required this.nationality,
    this.isCaptain = false,
    this.isViceCaptain = false,
    this.runsScored = 0,
    this.ballsFaced = 0,
    this.wicketsTaken = 0,
    this.runsConceded = 0,
    this.oversBowled = 0.0,
    this.matchesPlayed = 0,
    this.isOut = false,
    this.dismissalInfo = '',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'role': role,
        'nationality': nationality,
        'isCaptain': isCaptain,
        'isViceCaptain': isViceCaptain,
        'runsScored': runsScored,
        'ballsFaced': ballsFaced,
        'wicketsTaken': wicketsTaken,
        'runsConceded': runsConceded,
        'oversBowled': oversBowled,
        'matchesPlayed': matchesPlayed,
        'isOut': isOut,
        'dismissalInfo': dismissalInfo,
      };

  factory Player.fromJson(Map<dynamic, dynamic> json) => Player(
        id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
        name: json['name']?.toString() ?? 'Player',
        role: json['role']?.toString() ?? 'Batter',
        nationality: json['nationality']?.toString() ?? 'IND',
        isCaptain: json['isCaptain'] == true || json['is_captain'] == true,
        isViceCaptain: json['isViceCaptain'] == true || json['is_vice_captain'] == true,
        runsScored: (json['runsScored'] as num?)?.toInt() ?? 0,
        ballsFaced: (json['ballsFaced'] as num?)?.toInt() ?? 0,
        wicketsTaken: (json['wicketsTaken'] as num?)?.toInt() ?? 0,
        runsConceded: (json['runsConceded'] as num?)?.toInt() ?? 0,
        oversBowled: (json['oversBowled'] as num?)?.toDouble() ?? 0.0,
        matchesPlayed: (json['matchesPlayed'] as num?)?.toInt() ?? 0,
        isOut: json['isOut'] == true,
        dismissalInfo: json['dismissalInfo']?.toString() ?? '',
      );
}

class Team {
  final String id;
  String name;
  String shortName;
  String logoColorHex; // UI coloring matching the screenshots
  final List<Player> players;


  Team({
    required this.id,
    required this.name,
    required this.shortName,
    required this.logoColorHex,
    required this.players,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'shortName': shortName,
        'logoColorHex': logoColorHex,
        'players': players.map((p) => p.toJson()).toList(),
      };

  factory Team.fromJson(Map<dynamic, dynamic> json) => Team(
        id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        shortName: json['shortName']?.toString() ?? '',
        logoColorHex: json['logoColorHex']?.toString() ?? '0xFF028A6B',
        players: (json['players'] as List?)
                ?.map((p) => Player.fromJson(p is Map ? p : {}))
                .toList() ??
            [],
      );
}

class BallRecord {
  final int run;
  final int extraRun;
  final String extraType; // "Wide", "No Ball", "Leg Bye", "None"
  final bool isWicket;
  final String wicketType; // "Bowled", "Caught", "LBW", "Run Out", "None"
  String batsmanName;
  String bowlerName;
  final String commentary;
  final DateTime timestamp;
  final String? strikerId;
  final String? nonStrikerId;
  final String? bowlerId;
  final int? innings;
  final String? battingTeamId;
  final double? over;

  BallRecord({
    required this.run,
    required this.extraRun,
    required this.extraType,
    required this.isWicket,
    required this.wicketType,
    required this.batsmanName,
    required this.bowlerName,
    required this.commentary,
    required this.timestamp,
    this.strikerId,
    this.nonStrikerId,
    this.bowlerId,
    this.innings,
    this.battingTeamId,
    this.over,
  });

  Map<String, dynamic> toJson() => {
        'run': run,
        'extraRun': extraRun,
        'extraType': extraType,
        'isWicket': isWicket,
        'wicketType': wicketType,
        'batsmanName': batsmanName,
        'bowlerName': bowlerName,
        'commentary': commentary,
        'timestamp': timestamp.toIso8601String(),
        'strikerId': strikerId,
        'nonStrikerId': nonStrikerId,
        'bowlerId': bowlerId,
        'innings': innings,
        'battingTeamId': battingTeamId,
        'over': over,
      };

  factory BallRecord.fromJson(Map<dynamic, dynamic> json) => BallRecord(
        run: (json['run'] as num?)?.toInt() ?? 0,
        extraRun: (json['extraRun'] as num?)?.toInt() ?? 0,
        extraType: json['extraType']?.toString() ?? 'None',
        isWicket: json['isWicket'] == true,
        wicketType: json['wicketType']?.toString() ?? 'None',
        batsmanName: json['batsmanName']?.toString() ?? '',
        bowlerName: json['bowlerName']?.toString() ?? '',
        commentary: json['commentary']?.toString() ?? '',
        timestamp: json['timestamp'] != null
            ? (json['timestamp'] is DateTime
                ? json['timestamp'] as DateTime
                : DateTime.tryParse(json['timestamp'].toString()) ?? DateTime.now())
            : DateTime.now(),
        strikerId: json['strikerId']?.toString(),
        nonStrikerId: json['nonStrikerId']?.toString(),
        bowlerId: json['bowlerId']?.toString(),
        innings: (json['innings'] as num?)?.toInt(),
        battingTeamId: json['battingTeamId']?.toString(),
        over: (json['over'] as num?)?.toDouble(),
      );
}

class CricketMatch {
  final String id;
  String? tournamentId;
  Team teamA;
  Team teamB;
  String matchType; // "T20" or "ODI"
  String venue;
  String date;
  String time;
  String status; // "Upcoming", "Live", "Completed"
  String tossWinner; // "Team A" or "Team B" or ""
  String tossDecision; // "Bat" or "Bowl" or ""
  String battingTeamId; // active batting team id
  List<Player> playingXI_A;
  List<Player> playingXI_B;

  // Innings 1 status
  int runsA;
  int wicketsA;
  double oversA; // e.g. 15.2

  // Innings 2 status
  int runsB;
  int wicketsB;
  double oversB;

  int target; // Target for chasing team

  String scorerUsername;
  String scorerPassword;

  String currentStrikerId;
  String currentNonStrikerId;
  String currentBowlerId;

  List<BallRecord> balls;
  bool isFirstInnings;
  String winnerTeamId;
  String winnerName;
  String resultText;

  CricketMatch({
    required this.id,
    this.tournamentId,
    required this.teamA,
    required this.teamB,
    required this.matchType,
    required this.venue,
    required this.date,
    required this.time,
    this.status = "Upcoming",
    this.tossWinner = "",
    this.tossDecision = "",
    this.battingTeamId = "",
    required this.playingXI_A,
    required this.playingXI_B,
    this.runsA = 0,
    this.wicketsA = 0,
    this.oversA = 0.0,
    this.runsB = 0,
    this.wicketsB = 0,
    this.oversB = 0.0,
    this.target = 0,
    required this.scorerUsername,
    required this.scorerPassword,
    this.currentStrikerId = "",
    this.currentNonStrikerId = "",
    this.currentBowlerId = "",
    required this.balls,
    this.isFirstInnings = true,
    this.winnerTeamId = "",
    this.winnerName = "",
    this.resultText = "",
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'tournamentId': tournamentId,
        'teamA': teamA.toJson(),
        'teamB': teamB.toJson(),
        'matchType': matchType,
        'venue': venue,
        'date': date,
        'time': time,
        'status': status,
        'tossWinner': tossWinner,
        'tossDecision': tossDecision,
        'battingTeamId': battingTeamId,
        'playingXI_A': playingXI_A.map((p) => p.toJson()).toList(),
        'playingXI_B': playingXI_B.map((p) => p.toJson()).toList(),
        'runsA': runsA,
        'wicketsA': wicketsA,
        'oversA': oversA,
        'runsB': runsB,
        'wicketsB': wicketsB,
        'oversB': oversB,
        'target': target,
        'scorerUsername': scorerUsername,
        'scorerPassword': scorerPassword,
        'currentStrikerId': currentStrikerId,
        'currentNonStrikerId': currentNonStrikerId,
        'currentBowlerId': currentBowlerId,
        'balls': balls.map((b) => b.toJson()).toList(),
        'isFirstInnings': isFirstInnings,
        'winnerTeamId': winnerTeamId,
        'winnerName': winnerName,
        'resultText': resultText,
      };

  factory CricketMatch.fromJson(Map<dynamic, dynamic> json) => CricketMatch(
        id: json['id']?.toString() ?? '',
        tournamentId: json['tournamentId']?.toString(),
        teamA: Team.fromJson(json['teamA'] is Map ? json['teamA'] as Map : {}),
        teamB: Team.fromJson(json['teamB'] is Map ? json['teamB'] as Map : {}),
        matchType: json['matchType']?.toString() ?? 'T20',
        venue: json['venue']?.toString() ?? '',
        date: json['date']?.toString() ?? '',
        time: json['time']?.toString() ?? '',
        status: json['status']?.toString() ?? 'Upcoming',
        tossWinner: json['tossWinner']?.toString() ?? '',
        tossDecision: json['tossDecision']?.toString() ?? '',
        battingTeamId: json['battingTeamId']?.toString() ?? '',
        playingXI_A: (json['playingXI_A'] as List?)
                ?.map((p) => Player.fromJson(p is Map ? p : {}))
                .toList() ??
            [],
        playingXI_B: (json['playingXI_B'] as List?)
                ?.map((p) => Player.fromJson(p is Map ? p : {}))
                .toList() ??
            [],
        runsA: (json['runsA'] as num?)?.toInt() ?? 0,
        wicketsA: (json['wicketsA'] as num?)?.toInt() ?? 0,
        oversA: (json['oversA'] as num?)?.toDouble() ?? 0.0,
        runsB: (json['runsB'] as num?)?.toInt() ?? 0,
        wicketsB: (json['wicketsB'] as num?)?.toInt() ?? 0,
        oversB: (json['oversB'] as num?)?.toDouble() ?? 0.0,
        target: (json['target'] as num?)?.toInt() ?? 0,
        scorerUsername: json['scorerUsername']?.toString() ?? '',
        scorerPassword: json['scorerPassword']?.toString() ?? '',
        currentStrikerId: json['currentStrikerId']?.toString() ?? '',
        currentNonStrikerId: json['currentNonStrikerId']?.toString() ?? '',
        currentBowlerId: json['currentBowlerId']?.toString() ?? '',
        balls: (json['balls'] as List?)
                ?.map((b) => BallRecord.fromJson(b is Map ? b : {}))
                .toList() ??
            [],
        isFirstInnings: json['isFirstInnings'] ?? true,
        winnerTeamId: json['winnerTeamId']?.toString() ?? '',
        winnerName: json['winnerName']?.toString() ?? '',
        resultText: json['resultText']?.toString() ?? '',
      );
}

class Tournament {
  final String id;
  String name;
  String format; // "T20", "ODI", "TEST"
  String status; // "Live", "Upcoming", "Completed"
  int teamsCount;
  int matchesCount;
  String startDate; // e.g. "01-07-2026"
  String endDate;   // e.g. "30-07-2026"
  List<String> participatingTeamIds;

  Tournament({
    required this.id,
    required this.name,
    this.format = 'T20',
    this.status = 'Upcoming',
    this.teamsCount = 0,
    this.matchesCount = 0,
    this.startDate = '',
    this.endDate = '',
    this.participatingTeamIds = const [],
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'format': format,
        'status': status,
        'teamsCount': teamsCount,
        'matchesCount': matchesCount,
        'startDate': startDate,
        'endDate': endDate,
        'participatingTeamIds': participatingTeamIds,
      };

  factory Tournament.fromJson(Map<String, dynamic> json) => Tournament(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        format: json['format']?.toString() ?? 'T20',
        status: json['status']?.toString() ?? 'Upcoming',
        teamsCount: json['teamsCount'] is int
            ? json['teamsCount']
            : int.tryParse('${json['teamsCount'] ?? json['teams'] ?? 0}') ?? 0,
        matchesCount: json['matchesCount'] is int
            ? json['matchesCount']
            : int.tryParse('${json['matchesCount'] ?? json['matches'] ?? 0}') ?? 0,
        startDate: json['startDate']?.toString() ?? json['start']?.toString() ?? '',
        endDate: json['endDate']?.toString() ?? json['end']?.toString() ?? '',
        participatingTeamIds: json['participatingTeamIds'] != null
            ? List<String>.from(json['participatingTeamIds'])
            : [],
      );
}

class SearchHistoryItem {
  final String id;
  final String title;
  final String subtitle;
  final String category; // 'Tournament', 'Team', 'Player', 'Match', 'Query'
  final DateTime timestamp;
  final String? targetId;

  SearchHistoryItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.timestamp,
    this.targetId,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'subtitle': subtitle,
        'category': category,
        'timestamp': timestamp.millisecondsSinceEpoch,
        'targetId': targetId,
      };

  factory SearchHistoryItem.fromJson(Map<String, dynamic> json) => SearchHistoryItem(
        id: json['id']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        subtitle: json['subtitle']?.toString() ?? '',
        category: json['category']?.toString() ?? 'Query',
        timestamp: DateTime.fromMillisecondsSinceEpoch(
          json['timestamp'] is int
              ? json['timestamp']
              : int.tryParse(json['timestamp']?.toString() ?? '') ?? DateTime.now().millisecondsSinceEpoch,
        ),
        targetId: json['targetId']?.toString(),
      );
}

class Manager {
  final String id;
  final String name;
  final String username;
  final String password;
  final String? phone;

  Manager({
    required this.id,
    required this.name,
    required this.username,
    required this.password,
    this.phone,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'username': username,
        'password': password,
        'phone': phone,
      };

  factory Manager.fromJson(Map<String, dynamic> json) => Manager(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        username: json['username']?.toString() ?? '',
        password: json['password']?.toString() ?? '',
        phone: json['phone']?.toString(),
      );
}

