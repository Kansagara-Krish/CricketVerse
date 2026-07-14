// lib/core/constants/app_constants.dart
// CricketVerse AI — Dummy Data Constants & Content Pools

class AppConstants {
  // ─── App Info ───────────────────────────────────────────────────────────────
  static const String appName      = 'CricketVerse AI';
  static const String appVersion   = '1.0.0';
  static const String appTagline   = 'Intelligence Meets Action';
  static const String adminEmail   = 'admin@cricketverse.ai';
  static const String adminName    = 'Rajesh Kumar';
  static const String adminRole    = 'Tournament Administrator';

  // ─── Commentary Pool ────────────────────────────────────────────────────────
  static const List<String> sixCommentary = [
    "🎯 SIX! The ball sails over long-on! Incredible power from the batsman!",
    "💥 MAXIMUM! That's out of the stadium! What a clean strike!",
    "🚀 SIX RUNS! Picked up off the pads and dispatched into the crowd!",
    "⚡ MONSTER SIX! Down the ground with absolute authority!",
    "🌟 HUGE SIX! Over deep midwicket — the crowd goes absolutely wild!",
    "🎆 TOWERING SIX! Smashed straight back over the bowler's head!",
  ];

  static const List<String> fourCommentary = [
    "🔥 FOUR! Beautiful shot! Races to the boundary at third man!",
    "💫 BOUNDARY! Cracking cover drive — beats the fielder easily!",
    "⚡ FOUR RUNS! Short and wide, cut away elegantly to the fence!",
    "✨ FOUR! Driven through extra cover with pure elegance!",
    "🎯 BOUNDARY! Flicked off the hips, races to the fine leg rope!",
  ];

  static const List<String> singleCommentary = [
    "• Quick single. Pushed to mid-off and the batsmen cross comfortably.",
    "• Soft hands to third man. They jog through for one.",
    "• Tucked away to square leg, easy single.",
    "• Driven to long-off and the batsmen scamper through.",
    "• Nudged to midwicket, comfortable single taken.",
  ];

  static const List<String> dotCommentary = [
    "◆ Dot ball. Good length delivery played back to the bowler.",
    "◆ Excellent delivery! Batsman beaten outside the off stump!",
    "◆ Defended solidly. No run.",
    "◆ Misses the drive — keeper takes it cleanly.",
    "◆ Short ball, ducked under. No run.",
  ];

  static const List<String> wicketCommentary = [
    "🔴 WICKET! Clean bowled! The stumps are shattered! Brilliant delivery!",
    "🔴 OUT! Caught at the boundary — superb catch! Walks back in disbelief!",
    "🔴 LBW! Plumb in front! The finger goes up immediately!",
    "🔴 RUN OUT! Direct hit! The batsman is yards short of the crease!",
    "🔴 CAUGHT BEHIND! Thin edge and the keeper pouches it!",
    "🔴 STUMPED! Quick as lightning — the bails are off before the foot is in!",
  ];

  static const List<String> wideCommentary = [
    "Wide ball! Strays down the leg side, the batsman lets it go.",
    "Wide! The ball misses the tramline on the off side.",
    "Called wide. Umpire signals immediately — extra run added.",
  ];

  static const List<String> noBallCommentary = [
    "No Ball! Oversteps the crease. Free Hit coming up!",
    "No Ball! The front foot lands well past the crease!",
    "No Ball signalled. Extra run, and it's a Free Hit next ball!",
  ];

  // ─── Dummy Notifications ────────────────────────────────────────────────────
  static const List<Map<String, String>> dummyNotifications = [
    {
      'title': '🟢 Match Started',
      'body':  'India vs Australia T20 World Cup Final has started at Wankhede Stadium.',
      'time':  '2 min ago',
      'type':  'match',
    },
    {
      'title': '🔴 WICKET!',
      'body':  'V. Kohli is out! Caught at deep midwicket off M. Starc. Score: 184/4.',
      'time':  '5 min ago',
      'type':  'wicket',
    },
    {
      'title': '🎯 Prediction Updated',
      'body':  'India\'s win probability rises to 74% after consecutive boundaries.',
      'time':  '8 min ago',
      'type':  'prediction',
    },
    {
      'title': '💥 HALF CENTURY!',
      'body':  'S. Yadav scores 50 off 28 balls! Incredible innings in progress.',
      'time':  '12 min ago',
      'type':  'milestone',
    },
    {
      'title': '📅 Match Scheduled',
      'body':  'New match scheduled: India vs England ODI on 20-07-2026 at Eden Gardens.',
      'time':  '1 hour ago',
      'type':  'schedule',
    },
    {
      'title': '🔴 WICKET!',
      'body':  'T. Head dismissed by J. Bumrah! Australia 45/2 at the end of powerplay.',
      'time':  '2 hours ago',
      'type':  'wicket',
    },
    {
      'title': '🟡 Rain Delay',
      'body':  'Play suspended due to rain at MCG. Players leaving the field.',
      'time':  '3 hours ago',
      'type':  'alert',
    },
    {
      'title': '✅ Match Completed',
      'body':  'India beat Australia by 7 wickets in the T20 bilateral series match.',
      'time':  '1 day ago',
      'type':  'result',
    },
    {
      'title': '👤 New Team Added',
      'body':  'Team England has been added to the system by admin.',
      'time':  '2 days ago',
      'type':  'team',
    },
    {
      'title': '🏆 Tournament Created',
      'body':  'CricketVerse Premier League 2026 has been created with 8 teams.',
      'time':  '3 days ago',
      'type':  'tournament',
    },
  ];

  // ─── Dummy Venues ────────────────────────────────────────────────────────────
  static const List<String> venues = [
    'Wankhede Stadium, Mumbai',
    'Eden Gardens, Kolkata',
    'M. Chinnaswamy Stadium, Bengaluru',
    'Narendra Modi Stadium, Ahmedabad',
    'Melbourne Cricket Ground, Australia',
    'Lord\'s Cricket Ground, London',
    'Sydney Cricket Ground, Australia',
    'Dubai International Cricket Stadium',
    'Gaddafi Stadium, Lahore',
    'SuperSport Park, South Africa',
  ];

  // ─── Prediction Factors ──────────────────────────────────────────────────────
  static const List<String> predictionFactors = [
    'Current Run Rate',
    'Required Run Rate',
    'Wickets in Hand',
    'Powerplay Performance',
    'Death Overs History',
    'Head-to-Head Record',
    'Pitch Conditions',
    'Weather Impact',
  ];

  // ─── FAQ Content ─────────────────────────────────────────────────────────────
  static const List<Map<String, String>> faqItems = [
    {
      'question': 'How do I schedule a new match?',
      'answer': 'Go to the Matches section from the drawer, then tap the "+" button or navigate to Schedule Match. Fill in both team details, venue, date, time, and assign a scorer.',
    },
    {
      'question': 'How does Live Scoring work?',
      'answer': 'Navigate to any Live Match and tap "Go to Live Scoring". Use the run buttons (0,1,2,3,4,6), extras, and wicket buttons to update the score in real time.',
    },
    {
      'question': 'What is AI Commentary?',
      'answer': 'AI Commentary automatically generates descriptive ball-by-ball commentary using intelligent templates and match context. It activates during Live Scoring.',
    },
    {
      'question': 'How is Win Probability calculated?',
      'answer': 'The prediction engine uses current run rate, required run rate, wickets in hand, powerplay data, and historical head-to-head records to compute live win probability.',
    },
    {
      'question': 'Can I add players to an existing team?',
      'answer': 'Yes! Go to Team Management, select a team, open the Team Detail screen, and use the "Add Player" button to add new players to the roster.',
    },
    {
      'question': 'How do I create a tournament?',
      'answer': 'Use the drawer to navigate to "Create Tournament". Fill in the tournament name, format, dates, and select participating teams. The tournament will appear in the Tournament List.',
    },
    {
      'question': 'What match formats are supported?',
      'answer': 'Currently CricketVerse AI supports T20 (20 overs) and ODI (50 overs) match formats. More formats like Test matches are coming in future updates.',
    },
    {
      'question': 'How do I view a player\'s statistics?',
      'answer': 'Go to Player Management or open a Team Detail screen, then tap on any player to view their detailed career statistics including batting and bowling metrics.',
    },
  ];
}
