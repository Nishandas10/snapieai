import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/providers/health_score_provider.dart';
import '../../../core/widgets/health_score_widgets.dart';

/// Modal popup showing current health score after meal logging
class HealthScoreModal extends ConsumerWidget {
  final VoidCallback? onDismiss;
  final VoidCallback? onViewDetails;

  const HealthScoreModal({super.key, this.onDismiss, this.onViewDetails});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final healthState = ref.watch(healthScoreProvider);
    final score = healthState.todayScore;

    if (score == null) return const SizedBox.shrink();

    final totalScore = score.totalScore;
    final color = _getScoreColor(totalScore);
    final label = score.scoreLabel;
    final potentialScore = ref
        .read(healthScoreProvider.notifier)
        .getPotentialScore();

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 340),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header with gradient
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color.withValues(alpha: 0.15),
                    color.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Health Score',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: onDismiss,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  HealthScoreGauge(
                    score: totalScore,
                    size: 140,
                    showLabel: true,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  if (score.streak > 1) ...[
                    const SizedBox(height: 8),
                    StreakBadge(streak: score.streak),
                  ],
                ],
              ),
            ),

            // Habit building message
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _HabitBuilderMessage(
                score: totalScore,
                streak: score.streak,
                itemsLogged: score.breakdown.macroBalanceScore > 0,
              ),
            ),

            // Breakdown section
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HealthScoreBreakdownCard(
                    breakdown: score.breakdown,
                    compact: true,
                  ),

                  // Potential score hint
                  if (potentialScore > totalScore + 5) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.trending_up,
                            color: AppColors.success,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Log more meals to reach ${potentialScore.toInt()}!',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.success,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  // CTA Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: onDismiss,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Continue'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            // Only call onViewDetails, which handles dismissal itself in the show function
                            onViewDetails?.call();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('View Details'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return AppColors.success;
    if (score >= 51) return AppColors.warning;
    return AppColors.error;
  }
}

/// Shows the health score modal dialog
Future<void> showHealthScoreModal(
  BuildContext context, {
  VoidCallback? onViewDetails,
}) async {
  await showDialog(
    context: context,
    barrierDismissible: true,
    builder: (dialogContext) => HealthScoreModal(
      onDismiss: () => Navigator.of(dialogContext).pop(),
      onViewDetails: () {
        Navigator.of(dialogContext).pop();
        onViewDetails?.call();
      },
    ),
  );
}

/// Morning briefing dialog
class MorningBriefingDialog extends ConsumerWidget {
  final VoidCallback? onDismiss;
  final VoidCallback? onViewDetails;

  const MorningBriefingDialog({super.key, this.onDismiss, this.onViewDetails});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final healthState = ref.watch(healthScoreProvider);
    final yesterdayScore = healthState.yesterdayScore;
    final todayScore = healthState.todayScore;

    if (yesterdayScore == null) return const SizedBox.shrink();

    final color = _getScoreColor(yesterdayScore.totalScore);
    final streak = todayScore?.streak ?? 0;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 340),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Greeting
              Row(
                children: [
                  const Text('☀️', style: TextStyle(fontSize: 28)),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Good Morning!',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: onDismiss,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Yesterday's score
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    HealthScoreGauge(
                      score: yesterdayScore.totalScore,
                      size: 80,
                      showLabel: false,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Yesterday\'s Score',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            yesterdayScore.scoreLabel,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                          if (streak > 1) ...[
                            const SizedBox(height: 8),
                            StreakBadge(streak: streak, compact: true),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Motivational message
              Text(
                _getMotivationalMessage(yesterdayScore.totalScore, streak),
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 20),

              // CTA Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    onDismiss?.call();
                    ref
                        .read(healthScoreProvider.notifier)
                        .dismissMorningBriefing();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Start Today Strong! 💪',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return AppColors.success;
    if (score >= 51) return AppColors.warning;
    return AppColors.error;
  }

  String _getMotivationalMessage(double score, int streak) {
    if (score >= 80) {
      if (streak >= 7) {
        return 'Incredible week! You\'re building amazing habits. Keep the momentum going! 🏆';
      }
      return 'Outstanding performance yesterday! You\'re on fire. Let\'s keep this energy today! 🔥';
    }
    if (score >= 51) {
      if (streak >= 3) {
        return 'You\'re building consistency! Small improvements each day lead to big results. 📈';
      }
      return 'Good effort yesterday! A few small tweaks and you\'ll hit that elite zone. You\'ve got this! 💪';
    }
    return 'Every day is a fresh start! Today is your chance to make healthier choices. Let\'s do this! 🌟';
  }
}

/// Habit builder message widget
class _HabitBuilderMessage extends StatelessWidget {
  final double score;
  final int streak;
  final bool itemsLogged;

  const _HabitBuilderMessage({
    required this.score,
    required this.streak,
    required this.itemsLogged,
  });

  @override
  Widget build(BuildContext context) {
    final (message, icon, color) = _getMessage();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                color: color,
                fontWeight: FontWeight.w500,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  (String, String, Color) _getMessage() {
    // No items logged yet
    if (!itemsLogged || score == 0) {
      return (
        'Start your day strong! Log your first meal to begin building your health score.',
        '🌅',
        AppColors.info,
      );
    }

    // Score-based messages with streak consideration
    if (score >= 80) {
      if (streak >= 7) {
        return (
          'You\'re on a ${streak}-day streak! Champion-level consistency. Keep it up!',
          '🏆',
          AppColors.success,
        );
      } else if (streak >= 3) {
        return (
          '${streak} days strong! You\'re building great habits. Almost at a week!',
          '🔥',
          AppColors.success,
        );
      }
      return (
        'Amazing score! Keep logging to build your streak and maintain these results.',
        '⭐',
        AppColors.success,
      );
    }

    if (score >= 65) {
      if (streak >= 3) {
        return (
          'Great ${streak}-day streak! Small improvements each day = big results.',
          '📈',
          AppColors.success,
        );
      }
      return (
        'You\'re doing great! Log consistently to build momentum and improve your score.',
        '💪',
        AppColors.success,
      );
    }

    if (score >= 50) {
      if (streak >= 2) {
        return (
          '${streak} days logged! Keep the streak alive - you\'re building momentum.',
          '🚀',
          AppColors.warning,
        );
      }
      return (
        'Good start! Log all your meals today to see your score climb.',
        '🌱',
        AppColors.warning,
      );
    }

    if (score >= 30) {
      return (
        'Every meal logged is progress! Add more meals to boost your score.',
        '🎯',
        AppColors.warning,
      );
    }

    return (
      'Log your meals to start tracking your nutrition journey!',
      '✨',
      AppColors.info,
    );
  }
}

/// Shows the morning briefing dialog
Future<void> showMorningBriefingDialog(BuildContext context) async {
  await showDialog(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => MorningBriefingDialog(
      onDismiss: () => Navigator.of(dialogContext).pop(),
    ),
  );
}
