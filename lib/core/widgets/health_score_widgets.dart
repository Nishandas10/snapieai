import 'dart:math';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../models/health_score.dart';

/// Circular gauge widget for displaying health score
class HealthScoreGauge extends StatelessWidget {
  final double score;
  final double size;
  final bool showLabel;
  final bool animated;
  final VoidCallback? onTap;

  const HealthScoreGauge({
    super.key,
    required this.score,
    this.size = 120,
    this.showLabel = true,
    this.animated = true,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final clampedScore = score.clamp(0.0, 100.0);
    final color = _getScoreColor(clampedScore);
    final label = _getScoreLabel(clampedScore);

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Background ring
            SizedBox(
              width: size,
              height: size,
              child: CircularProgressIndicator(
                value: 1,
                strokeWidth: size * 0.08,
                backgroundColor: Colors.transparent,
                valueColor: AlwaysStoppedAnimation<Color>(
                  color.withValues(alpha: 0.15),
                ),
              ),
            ),
            // Progress ring
            SizedBox(
              width: size,
              height: size,
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: clampedScore / 100),
                duration: animated
                    ? const Duration(milliseconds: 1200)
                    : Duration.zero,
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return CustomPaint(
                    painter: _GaugePainter(
                      progress: value,
                      color: color,
                      strokeWidth: size * 0.08,
                    ),
                  );
                },
              ),
            ),
            // Center content
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: clampedScore),
                  duration: animated
                      ? const Duration(milliseconds: 1200)
                      : Duration.zero,
                  builder: (context, value, child) {
                    return Text(
                      value.toInt().toString(),
                      style: TextStyle(
                        fontSize: size * 0.28,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    );
                  },
                ),
                if (showLabel)
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: size * 0.09,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
              ],
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

  String _getScoreLabel(double score) {
    if (score >= 80) return 'Optimal';
    if (score >= 51) return 'Fair';
    return 'Needs\nWork';
  }
}

/// Custom painter for the gauge arc
class _GaugePainter extends CustomPainter {
  final double progress;
  final Color color;
  final double strokeWidth;

  _GaugePainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Start from top (-90 degrees) and sweep clockwise
    const startAngle = -pi / 2;
    final sweepAngle = 2 * pi * progress;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}

/// Compact health score indicator for header
class HealthScoreIndicator extends StatelessWidget {
  final double score;
  final VoidCallback? onTap;

  const HealthScoreIndicator({super.key, required this.score, this.onTap});

  @override
  Widget build(BuildContext context) {
    final clampedScore = score.clamp(0.0, 100.0);
    final color = _getScoreColor(clampedScore);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.2),
                border: Border.all(color: color, width: 2),
              ),
              child: Center(
                child: Text(
                  clampedScore.toInt().toString(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Icon(_getScoreIcon(clampedScore), size: 16, color: color),
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

  IconData _getScoreIcon(double score) {
    if (score >= 80) return Icons.trending_up;
    if (score >= 51) return Icons.trending_flat;
    return Icons.trending_down;
  }
}

/// Score breakdown card showing individual components
class HealthScoreBreakdownCard extends StatelessWidget {
  final HealthScoreBreakdown breakdown;
  final bool compact;

  const HealthScoreBreakdownCard({
    super.key,
    required this.breakdown,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(compact ? 12 : 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!compact) ...[
              const Text(
                'Score Breakdown',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
            ],
            _ScoreRow(
              icon: Icons.fitness_center,
              label: 'Macro Balance',
              score: breakdown.macroBalanceScore,
              maxScore: 40,
              color: AppColors.protein,
              compact: compact,
            ),
            SizedBox(height: compact ? 8 : 12),
            _ScoreRow(
              icon: Icons.bloodtype,
              label: 'Glycemic Control',
              score: breakdown.glycemicControlScore,
              maxScore: 30,
              color: AppColors.secondary,
              compact: compact,
            ),
            SizedBox(height: compact ? 8 : 12),
            _ScoreRow(
              icon: Icons.eco,
              label: 'Micronutrients',
              score: breakdown.micronutrientScore,
              maxScore: 20,
              color: AppColors.success,
              compact: compact,
            ),
            SizedBox(height: compact ? 8 : 12),
            _ScoreRow(
              icon: Icons.track_changes,
              label: 'Consistency',
              score: breakdown.consistencyScore,
              maxScore: 10,
              color: AppColors.accent,
              compact: compact,
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final double score;
  final double maxScore;
  final Color color;
  final bool compact;

  const _ScoreRow({
    required this.icon,
    required this.label,
    required this.score,
    required this.maxScore,
    required this.color,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = (score / maxScore).clamp(0.0, 1.0);

    return Row(
      children: [
        Icon(icon, size: compact ? 16 : 20, color: color),
        SizedBox(width: compact ? 8 : 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: compact ? 12 : 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    '${score.toInt()}/${maxScore.toInt()}',
                    style: TextStyle(
                      fontSize: compact ? 11 : 12,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: percentage,
                  backgroundColor: color.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: compact ? 4 : 6,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Suggestion card for improving health score
class HealthScoreSuggestionCard extends StatelessWidget {
  final HealthScoreSuggestion suggestion;
  final VoidCallback? onTap;

  const HealthScoreSuggestionCard({
    super.key,
    required this.suggestion,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    suggestion.icon,
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            suggestion.title,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '+${suggestion.potentialPoints}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppColors.success,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      suggestion.foodSuggestion,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Morning briefing card showing yesterday's score
class MorningBriefingCard extends StatelessWidget {
  final double yesterdayScore;
  final int streak;
  final VoidCallback? onDismiss;

  const MorningBriefingCard({
    super.key,
    required this.yesterdayScore,
    required this.streak,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final color = _getScoreColor(yesterdayScore);
    final label = _getScoreLabel(yesterdayScore);

    return Card(
      color: color.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.wb_sunny, color: AppColors.accent, size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Good Morning!',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                if (onDismiss != null)
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: onDismiss,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: 0.2),
                    border: Border.all(color: color, width: 3),
                  ),
                  child: Center(
                    child: Text(
                      yesterdayScore.toInt().toString(),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Yesterday\'s Score: $label',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      if (streak > 1)
                        Row(
                          children: [
                            const Text('🔥', style: TextStyle(fontSize: 14)),
                            const SizedBox(width: 4),
                            Text(
                              'Current Streak: $streak Days',
                              style: const TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              yesterdayScore >= 80
                  ? 'Amazing job yesterday! Keep it up today! 💪'
                  : yesterdayScore >= 51
                  ? 'Good effort! Let\'s aim higher today! 🎯'
                  : 'New day, fresh start! You\'ve got this! 🌟',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
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

  String _getScoreLabel(double score) {
    if (score >= 80) return 'Elite!';
    if (score >= 51) return 'Good';
    return 'Needs Work';
  }
}

/// Streak display widget
class StreakBadge extends StatelessWidget {
  final int streak;
  final bool compact;

  const StreakBadge({super.key, required this.streak, this.compact = false});

  @override
  Widget build(BuildContext context) {
    if (streak <= 0) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('🔥', style: TextStyle(fontSize: compact ? 12 : 16)),
          SizedBox(width: compact ? 4 : 6),
          Text(
            '$streak',
            style: TextStyle(
              fontSize: compact ? 12 : 14,
              fontWeight: FontWeight.bold,
              color: AppColors.accent,
            ),
          ),
          if (!compact) ...[
            const SizedBox(width: 2),
            Text(
              streak == 1 ? 'day' : 'days',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
