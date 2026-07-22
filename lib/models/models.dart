// ignore_for_file: non_constant_identifier_names

class Player {
  final String id;
  final String name;
  final String role; // "Batter", "Bowler", "All-rounder"
  final String nationality;
  int runsScored;
  int ballsFaced;
  int wicketsTaken;
  int runsConceded;
  double oversBowled;
  int matchesPlayed;

  Player({
    required this.id,
    required this.name,
    required this.role,
    required this.nationality,
    this.runsScored = 0,
    this.ballsFaced = 0,
    this.wicketsTaken = 0,
    this.runsConceded = 0,
    this.oversBowled = 0.0,
    this.matchesPlayed = 0,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'role': role,
        'nationality': nationality,
        'runsScored': runsScored,
        'ballsFaced': ballsFaced,
        'wicketsTaken': wicketsTaken,
        'runsConceded': runsConceded,
        'oversBowled': oversBowled,
        'matchesPlayed': matchesPlayed,
      };

  factory Player.fromJson(Map<String, dynamic> json) => Player(
        id: json['id'],
        name: json['name'],
        role: json['role'],
        nationality: json['nationality'],
        runsScored: json['runsScored'] ?? 0,
        ballsFaced: json['ballsFaced'] ?? 0,
        wicketsTaken: json['wicketsTaken'] ?? 0,
        runsConceded: json['runsConceded'] ?? 0,
        oversBowled: (json['oversBowled'] as num?)?.toDouble() ?? 0.0,
        matchesPlayed: json['matchesPlayed'] ?? 0,
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

  factory Team.fromJson(Map<String, dynamic> json) => Team(
        id: json['id'],
        name: json['name'],
        shortName: json['shortName'],
        logoColorHex: json['logoColorHex'],
        players: (json['players'] as List)
            .map((p) => Player.fromJson(p))
            .toList(),
      );
}

class BallRecord {
  final int run;
  final int extraRun;
  final String extraType; // "Wide", "No Ball", "Leg Bye", "None"
  final bool isWicket;
  final String wicketType; // "Bowled", "Caught", "LBW", "Run Out", "None"
  final String batsmanName;
  final String bowlerName;
  final String commentary;
  final DateTime timestamp;
  final String? strikerId;
  final String? nonStrikerId;
  final String? bowlerId;

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
      };

  factory BallRecord.fromJson(Map<String, dynamic> json) => BallRecord(
        run: json['run'],
        extraRun: json['extraRun'],
        extraType: json['extraType'],
        isWicket: json['isWicket'],
        wicketType: json['wicketType'] ?? 'None',
        batsmanName: json['batsmanName'] ?? '',
        bowlerName: json['bowlerName'] ?? '',
        commentary: json['commentary'] ?? '',
        timestamp: DateTime.parse(json['timestamp']),
        strikerId: json['strikerId'],
        nonStrikerId: json['nonStrikerId'],
        bowlerId: json['bowlerId'],
      );
}

class CricketMatch {
  final String id;
  final Team teamA;
  final Team teamB;
  final String matchType; // "T20" or "ODI"
  final String venue;
  final String date;
  final String time;
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

  CricketMatch({
    required this.id,
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
  });

  Map<String, dynamic> toJson() => {
        'id': id,
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
      };

  factory CricketMatch.fromJson(Map<String, dynamic> json) => CricketMatch(
        id: json['id'],
        teamA: Team.fromJson(json['teamA']),
        teamB: Team.fromJson(json['teamB']),
        matchType: json['matchType'],
        venue: json['venue'],
        date: json['date'],
        time: json['time'],
        status: json['status'] ?? 'Upcoming',
        tossWinner: json['tossWinner'] ?? '',
        tossDecision: json['tossDecision'] ?? '',
        battingTeamId: json['battingTeamId'] ?? '',
        playingXI_A: (json['playingXI_A'] as List)
            .map((p) => Player.fromJson(p))
            .toList(),
        playingXI_B: (json['playingXI_B'] as List)
            .map((p) => Player.fromJson(p))
            .toList(),
        runsA: json['runsA'] ?? 0,
        wicketsA: json['wicketsA'] ?? 0,
        oversA: (json['oversA'] as num?)?.toDouble() ?? 0.0,
        runsB: json['runsB'] ?? 0,
        wicketsB: json['wicketsB'] ?? 0,
        oversB: (json['oversB'] as num?)?.toDouble() ?? 0.0,
        target: json['target'] ?? 0,
        scorerUsername: json['scorerUsername'] ?? '',
        scorerPassword: json['scorerPassword'] ?? '',
        currentStrikerId: json['currentStrikerId'] ?? '',
        currentNonStrikerId: json['currentNonStrikerId'] ?? '',
        currentBowlerId: json['currentBowlerId'] ?? '',
        balls: (json['balls'] as List)
            .map((b) => BallRecord.fromJson(b))
            .toList(),
        isFirstInnings: json['isFirstInnings'] ?? true,
      );
}
