import 'dart:collection';
import 'package:flutter/foundation.dart';
import '../models/models.dart';

class CelebrationQueueService {
  static final CelebrationQueueService _instance = CelebrationQueueService._internal();
  factory CelebrationQueueService() => _instance;
  CelebrationQueueService._internal();

  final List<MilestoneCelebration> _queue = [];
  final Set<String> _processedEventIds = {};
  final Set<String> _processedMilestoneKeys = {};
  MilestoneCelebration? _currentActive;

  final ValueNotifier<MilestoneCelebration?> activeCelebrationNotifier =
      ValueNotifier<MilestoneCelebration?>(null);

  MilestoneCelebration? get currentActive => _currentActive;

  static int getPriority(String type) {
    switch (type.trim().toUpperCase()) {
      case 'MATCH_WON':
      case 'MATCH_WIN':
        return 1;
      case 'FIVE_WICKET':
      case '5W':
        return 2;
      case '100':
        return 3;
      case '50':
        return 4;
      case 'WICKET':
        return 5;
      case 'SIX':
        return 6;
      default:
        return 7;
    }
  }

  /// Evaluates and enqueues an incoming celebration.
  /// Returns true if accepted, false if rejected as duplicate or stale.
  bool enqueue(MilestoneCelebration celebration) {
    final eventId = celebration.eventId.trim();
    if (eventId.isNotEmpty && _processedEventIds.contains(eventId)) {
      debugPrint('[CELEBRATION_QUEUE] Ignored duplicate eventId: $eventId');
      return false;
    }

    // Discard events older than 25 seconds (e.g. from historical socket replay on reconnect)
    final ageMs = DateTime.now().difference(celebration.timestamp).inMilliseconds.abs();
    if (ageMs > 25000) {
      debugPrint('[CELEBRATION_QUEUE] Discarded stale historical event ($ageMs ms old): $eventId');
      return false;
    }

    final type = celebration.type.trim().toUpperCase();
    final innings = celebration.innings;

    // Per-batter / per-bowler / per-match duplicate protection
    if (type == '50' && celebration.batsmanId.isNotEmpty) {
      final key = '50_${celebration.matchId}_${innings}_${celebration.batsmanId}';
      if (_processedMilestoneKeys.contains(key)) return false;
      _processedMilestoneKeys.add(key);
    } else if (type == '100' && celebration.batsmanId.isNotEmpty) {
      final key = '100_${celebration.matchId}_${innings}_${celebration.batsmanId}';
      if (_processedMilestoneKeys.contains(key)) return false;
      _processedMilestoneKeys.add(key);
    } else if ((type == 'FIVE_WICKET' || type == '5W') && celebration.bowlerId.isNotEmpty) {
      final key = '5w_${celebration.matchId}_${innings}_${celebration.bowlerId}';
      if (_processedMilestoneKeys.contains(key)) return false;
      _processedMilestoneKeys.add(key);
    } else if (type == 'MATCH_WON') {
      final key = 'win_${celebration.matchId}';
      if (_processedMilestoneKeys.contains(key)) return false;
      _processedMilestoneKeys.add(key);
    }

    if (eventId.isNotEmpty) {
      _processedEventIds.add(eventId);
      if (_processedEventIds.length > 300) {
        _processedEventIds.remove(_processedEventIds.first);
      }
    }

    // Insert into priority queue
    _insertInPriorityOrder(celebration);

    // If nothing currently displayed, advance
    if (_currentActive == null) {
      _advanceQueue();
    }
    return true;
  }

  void _insertInPriorityOrder(MilestoneCelebration item) {
    final newPriority = getPriority(item.type);

    // If a six completed a 50 or 100 milestone, remove any lower six queued for the same ball
    if (newPriority == 3 || newPriority == 4) { // 100 or 50
      _queue.removeWhere((q) =>
          getPriority(q.type) == 6 &&
          q.batsmanId == item.batsmanId &&
          q.matchId == item.matchId);
    }

    // Top priority (MATCH_WON) preempts non-critical queued celebrations
    if (newPriority == 1 && _queue.isNotEmpty) {
      _queue.removeWhere((q) => getPriority(q.type) >= 5); // remove queued ordinary 6s/wickets
    }

    int insertIdx = _queue.length;
    for (int i = 0; i < _queue.length; i++) {
      if (newPriority < getPriority(_queue[i].type)) {
        insertIdx = i;
        break;
      }
    }
    _queue.insert(insertIdx, item);
  }

  void dismissCurrent() {
    _currentActive = null;
    activeCelebrationNotifier.value = null;
    _advanceQueue();
  }

  void _advanceQueue() {
    if (_queue.isNotEmpty) {
      _currentActive = _queue.removeAt(0);
      activeCelebrationNotifier.value = _currentActive;
      debugPrint('[CELEBRATION_QUEUE] Active celebration set: ${_currentActive?.type} for ${_currentActive?.batsmanName ?? _currentActive?.winnerTeamName}');
    } else {
      _currentActive = null;
      activeCelebrationNotifier.value = null;
    }
  }

  void clearMatch(String matchId) {
    _queue.removeWhere((c) => c.matchId == matchId);
    if (_currentActive?.matchId == matchId) {
      dismissCurrent();
    }
  }

  void reset() {
    _queue.clear();
    _processedEventIds.clear();
    _processedMilestoneKeys.clear();
    _currentActive = null;
    activeCelebrationNotifier.value = null;
  }
}

