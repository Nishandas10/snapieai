import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/health_score.dart';
import '../models/daily_log.dart';
import '../models/user_profile.dart';
import '../services/health_score_service.dart';
import '../services/storage_service.dart';
import 'food_log_provider.dart';
import 'user_provider.dart';

/// State for health score
class HealthScoreState {
  final DailyHealthScore? todayScore;
  final DailyHealthScore? yesterdayScore;
  final bool isLoading;
  final bool showMorningBriefing;
  final bool showMealLoggedModal;
  final bool showAppOpenModal;
  final DateTime? lastModalShown;

  HealthScoreState({
    this.todayScore,
    this.yesterdayScore,
    this.isLoading = false,
    this.showMorningBriefing = false,
    this.showMealLoggedModal = false,
    this.showAppOpenModal = false,
    this.lastModalShown,
  });

  HealthScoreState copyWith({
    DailyHealthScore? todayScore,
    DailyHealthScore? yesterdayScore,
    bool? isLoading,
    bool? showMorningBriefing,
    bool? showMealLoggedModal,
    bool? showAppOpenModal,
    DateTime? lastModalShown,
  }) {
    return HealthScoreState(
      todayScore: todayScore ?? this.todayScore,
      yesterdayScore: yesterdayScore ?? this.yesterdayScore,
      isLoading: isLoading ?? this.isLoading,
      showMorningBriefing: showMorningBriefing ?? this.showMorningBriefing,
      showMealLoggedModal: showMealLoggedModal ?? this.showMealLoggedModal,
      showAppOpenModal: showAppOpenModal ?? this.showAppOpenModal,
      lastModalShown: lastModalShown ?? this.lastModalShown,
    );
  }
}

/// Health score notifier
class HealthScoreNotifier extends StateNotifier<HealthScoreState> {
  final Ref _ref;

  HealthScoreNotifier(this._ref) : super(HealthScoreState()) {
    _initialize();
  }

  void _initialize() async {
    try {
      await _loadYesterdayScore();
    } catch (e) {
      debugPrint('Error loading yesterday score: $e');
    }

    try {
      await _checkMorningBriefing();
    } catch (e) {
      debugPrint('Error checking morning briefing: $e');
    }

    try {
      _calculateTodayScore();
    } catch (e) {
      debugPrint('Error calculating today score: $e');
    }

    // Set flag to show app-open modal (will be consumed by HomeScreen)
    state = state.copyWith(showAppOpenModal: true);

    // Listen to food log changes
    _ref.listen<DailyLogState>(foodLogProvider, (previous, next) {
      if (previous?.todayLog != next.todayLog) {
        _calculateTodayScore();
      }
    });

    // Listen to profile changes
    _ref.listen<UserProfile?>(userProfileProvider, (previous, next) {
      if (previous != next) {
        _calculateTodayScore();
      }
    });
  }

  /// Calculate today's health score based on current food log
  void _calculateTodayScore() {
    final todayLog = _ref.read(foodLogProvider).todayLog;
    final profile = _ref.read(userProfileProvider);
    final streak = _calculateStreak();

    final score = HealthScoreService.calculateScore(
      todayLog: todayLog,
      profile: profile,
      currentStreak: streak,
      yesterdayScore: state.yesterdayScore?.totalScore,
    );

    state = state.copyWith(todayScore: score);

    // Save today's score for tomorrow's reference
    _saveTodayScore(score);
  }

  /// Recalculate score - call this after a meal is logged
  void recalculateScore() {
    _calculateTodayScore();
  }

  /// Calculate current logging streak
  int _calculateStreak() {
    int streak = 0;
    var checkDate = DateTime.now();

    // Check if today has logs
    final todayLog = _ref.read(foodLogProvider).todayLog;
    if (todayLog != null && todayLog.totalFoodItems > 0) {
      streak = 1;
    }

    // Check previous days
    for (int i = 1; i <= 30; i++) {
      final prevDate = checkDate.subtract(Duration(days: i));
      final dateKey =
          '${prevDate.year}-${prevDate.month.toString().padLeft(2, '0')}-${prevDate.day.toString().padLeft(2, '0')}';
      final logData = StorageService.getFoodLog(dateKey);

      if (logData != null) {
        final log = DailyLog.fromJson(logData);
        if (log.totalFoodItems > 0) {
          streak++;
        } else {
          break;
        }
      } else {
        break;
      }
    }

    return streak;
  }

  /// Load yesterday's score from storage
  Future<void> _loadYesterdayScore() async {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    final dateKey =
        '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';

    final scoreData = StorageService.getObject('health_score_$dateKey');
    if (scoreData != null) {
      try {
        final yesterdayScore = DailyHealthScore.fromJson(scoreData);
        state = state.copyWith(yesterdayScore: yesterdayScore);
      } catch (e) {
        debugPrint('[HealthScoreProvider] Error loading yesterday score: $e');
      }
    }
  }

  /// Save today's score to storage
  Future<void> _saveTodayScore(DailyHealthScore score) async {
    await StorageService.saveObject(
      'health_score_${score.dateKey}',
      score.toJson(),
    );
  }

  /// Check if we should show morning briefing
  Future<void> _checkMorningBriefing() async {
    final now = DateTime.now();
    final todayKey =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final briefingShownKey = 'morning_briefing_$todayKey';

    final alreadyShown = StorageService.getBool(briefingShownKey);

    // Show morning briefing if:
    // 1. Not already shown today
    // 2. It's before noon
    // 3. We have yesterday's score
    if (alreadyShown != true && now.hour < 12 && state.yesterdayScore != null) {
      state = state.copyWith(showMorningBriefing: true);
    }
  }

  /// Mark morning briefing as shown
  void dismissMorningBriefing() {
    final now = DateTime.now();
    final todayKey =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    StorageService.setBool('morning_briefing_$todayKey', true);
    state = state.copyWith(showMorningBriefing: false);
  }

  /// Trigger meal logged modal
  void showMealLoggedPopup() {
    // Recalculate score first
    _calculateTodayScore();

    // Show modal
    state = state.copyWith(
      showMealLoggedModal: true,
      lastModalShown: DateTime.now(),
    );
  }

  /// Dismiss meal logged modal
  void dismissMealLoggedModal() {
    state = state.copyWith(showMealLoggedModal: false);
  }

  /// Dismiss app open modal
  void dismissAppOpenModal() {
    state = state.copyWith(showAppOpenModal: false);
  }

  /// Get potential score if user follows suggestions
  double getPotentialScore() {
    if (state.todayScore == null) return 0;
    return HealthScoreService.calculatePotentialScore(state.todayScore!);
  }
}

/// Provider for health score state
final healthScoreProvider =
    StateNotifierProvider<HealthScoreNotifier, HealthScoreState>((ref) {
      return HealthScoreNotifier(ref);
    });

/// Provider for just the current score value (for simpler widgets)
final currentHealthScoreProvider = Provider<double>((ref) {
  final state = ref.watch(healthScoreProvider);
  return state.todayScore?.totalScore ?? 0;
});

/// Provider for health score breakdown
final healthScoreBreakdownProvider = Provider<HealthScoreBreakdown?>((ref) {
  final state = ref.watch(healthScoreProvider);
  return state.todayScore?.breakdown;
});

/// Provider for health score suggestions
final healthScoreSuggestionsProvider = Provider<List<HealthScoreSuggestion>>((
  ref,
) {
  final state = ref.watch(healthScoreProvider);
  return state.todayScore?.suggestions ?? [];
});

/// Provider for current streak
final healthStreakProvider = Provider<int>((ref) {
  final state = ref.watch(healthScoreProvider);
  return state.todayScore?.streak ?? 0;
});
