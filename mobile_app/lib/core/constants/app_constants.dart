// lib/core/constants/app_constants.dart
// CricketVerse AI — Dummy Data Constants & Content Pools

class AppConstants {
  // ─── App Info ───────────────────────────────────────────────────────────────
  static const String appName      = 'CricketVerse AI';
  static const String appVersion   = '1.0.0';
  static const String appTagline   = 'Intelligence Meets Action';
  static const String adminEmail   = 'admin@gmail.com';
  static const String adminName    = 'Rajesh Kumar';
  static const String adminRole    = 'Tournament Administrator';

  // ─── Commentary Pool ────────────────────────────────────────────────────────
  static const List<String> sixCommentary = [
    "🎯 SIX! The ball sails high into the stands! Incredible power from the batsman!",
    "💥 MAXIMUM! That's out of the stadium! What a clean strike!",
    "🚀 SIX RUNS! Picked up off the pads and dispatched into the crowd!",
    "⚡ MONSTER SIX! Down the ground with absolute authority!",
    "🌟 HUGE SIX! Smashed high and handsome — the crowd goes absolutely wild!",
    "🎆 TOWERING SIX! Smashed straight back over the bowler's head!",
  ];

  static const List<String> fourCommentary = [
    "🔥 FOUR! Beautiful shot! Pierces the outfield gap and races to the boundary!",
    "💫 BOUNDARY! Cracking stroke — timed to perfection to beat the chase!",
    "⚡ FOUR RUNS! Short and wide, cut away elegantly to the fence!",
    "✨ FOUR! Driven with pure elegance through the boundary gap!",
    "🎯 BOUNDARY! Flicked with sublime wrist-work, races away to the rope!",
  ];

  static const List<String> singleCommentary = [
    "• Quick single. Crisp push into the gap and the batsmen cross comfortably.",
    "• Soft hands into the outfield. They jog through for one.",
    "• Tucked away neatly, easy single taken to rotate strike.",
    "• Driven down the pitch and the batsmen scamper through.",
    "• Nudged into the vacant area, comfortable single taken.",
  ];

  static const List<String> dotCommentary = [
    "◆ Dot ball. Good length delivery played defensively back to the bowler.",
    "◆ Excellent delivery! Batsman beaten by the sharp movement!",
    "◆ Defended solidly off the front foot. No run.",
    "◆ Misses the drive — keeper takes it cleanly.",
    "◆ Fierce bouncer, ducked under. No run.",
  ];

  static const List<String> wicketCommentary = [
    "🔴 WICKET! Clean bowled! The stumps are shattered! Brilliant delivery!",
    "🔴 OUT! Caught in the outfield — superb catch! The batsman must depart!",
    "🔴 LBW! Plumb in front! The umpire's finger goes up immediately!",
    "🔴 RUN OUT! Direct hit! The batsman is yards short of the crease!",
    "🔴 CAUGHT BEHIND! Thin edge and the keeper pouches it cleanly!",
    "🔴 STUMPED! Quick as lightning — the bails are whipped off in a flash!",
  ];

  static const List<String> wideCommentary = [
    "Wide ball! Strays beyond the tramline, the batsman lets it go.",
    "Wide! The ball misses the radar outside the tramline.",
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
