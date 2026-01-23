import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/providers/health_score_provider.dart';
import '../../../core/providers/providers.dart';
import '../../../core/widgets/health_score_widgets.dart';

class HealthScoreDetailScreen extends ConsumerWidget {
  const HealthScoreDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final healthState = ref.watch(healthScoreProvider);
    final score = healthState.todayScore;
    final profile = ref.watch(userProfileProvider);
    final todayLog = ref.watch(foodLogProvider).todayLog;

    if (score == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Health Score')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final totalScore = score.totalScore;
    final color = _getScoreColor(totalScore);
    final potentialScore = ref
        .read(healthScoreProvider.notifier)
        .getPotentialScore();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Score'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main score card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color.withValues(alpha: 0.15),
                    color.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withValues(alpha: 0.2)),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            DateFormat('EEEE').format(DateTime.now()),
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            DateFormat('MMMM d, y').format(DateTime.now()),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      if (score.streak > 0) StreakBadge(streak: score.streak),
                    ],
                  ),
                  const SizedBox(height: 24),
                  HealthScoreGauge(
                    score: totalScore,
                    size: 160,
                    showLabel: true,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    score.scoreLabel,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _getScoreDescription(totalScore),
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Score breakdown
            const Text(
              'Score Breakdown',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'How your score is calculated',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            _DetailedBreakdownCard(breakdown: score.breakdown),

            const SizedBox(height: 24),

            // Today's nutrition summary
            if (todayLog != null && todayLog.totalFoodItems > 0) ...[
              const Text(
                'Today\'s Nutrition',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              _NutritionSummaryCard(
                calories: todayLog.totalCalories,
                calorieTarget: profile?.dailyCalorieTarget ?? 2000,
                protein: todayLog.totalProtein,
                proteinTarget: profile?.macroTargets.proteinGrams ?? 150,
                sugar: todayLog.totalSugar,
                sugarTarget: profile?.macroTargets.sugarGrams ?? 50,
                fiber: todayLog.totalFiber,
              ),
              const SizedBox(height: 24),
            ],

            // Improvement suggestions
            if (score.suggestions.isNotEmpty) ...[
              Row(
                children: [
                  const Icon(
                    Icons.lightbulb_outline,
                    color: AppColors.accent,
                    size: 22,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'How to Improve',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  if (potentialScore > totalScore + 5)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.success.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Potential: ${potentialScore.toInt()}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Follow these tips to boost your score',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 16),
              ...score.suggestions.map(
                (suggestion) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: HealthScoreSuggestionCard(suggestion: suggestion),
                ),
              ),
            ],

            // Improvement areas
            if (score.improvements.isNotEmpty) ...[
              const SizedBox(height: 24),
              const Text(
                'Areas for Improvement',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              ...score.improvements.map(
                (improvement) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _ImprovementItem(text: improvement),
                ),
              ),
            ],

            // Yesterday comparison
            if (score.yesterdayScore != null) ...[
              const SizedBox(height: 24),
              _YesterdayComparisonCard(
                todayScore: totalScore,
                yesterdayScore: score.yesterdayScore!,
              ),
            ],

            const SizedBox(height: 40),
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

  String _getScoreDescription(double score) {
    if (score >= 80) {
      return 'Excellent! Your nutrition choices today are supporting optimal health.';
    }
    if (score >= 51) {
      return 'Good progress! A few adjustments could help you reach the optimal zone.';
    }
    return 'There\'s room for improvement. Check the suggestions below to boost your score.';
  }
}

class _DetailedBreakdownCard extends StatelessWidget {
  final dynamic breakdown;

  const _DetailedBreakdownCard({required this.breakdown});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _DetailedScoreRow(
              icon: Icons.fitness_center,
              title: 'Macro Balance',
              description: 'Protein, carbs & fat balance',
              score: breakdown.macroBalanceScore,
              maxScore: 40,
              color: AppColors.protein,
            ),
            const Divider(height: 24),
            _DetailedScoreRow(
              icon: Icons.bloodtype,
              title: 'Glycemic Control',
              description: 'Sugar & GI management',
              score: breakdown.glycemicControlScore,
              maxScore: 30,
              color: AppColors.secondary,
            ),
            const Divider(height: 24),
            _DetailedScoreRow(
              icon: Icons.eco,
              title: 'Micronutrients',
              description: 'Vitamins & minerals',
              score: breakdown.micronutrientScore,
              maxScore: 20,
              color: AppColors.success,
            ),
            const Divider(height: 24),
            _DetailedScoreRow(
              icon: Icons.track_changes,
              title: 'Consistency & Goals',
              description: 'Calories, streaks & health targets',
              score: breakdown.consistencyScore,
              maxScore: 10,
              color: AppColors.accent,
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailedScoreRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final double score;
  final double maxScore;
  final Color color;

  const _DetailedScoreRow({
    required this.icon,
    required this.title,
    required this.description,
    required this.score,
    required this.maxScore,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = (score / maxScore).clamp(0.0, 1.0);

    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    '${score.toInt()}/${maxScore.toInt()}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: percentage,
                  backgroundColor: color.withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NutritionSummaryCard extends StatelessWidget {
  final double calories;
  final double calorieTarget;
  final double protein;
  final double proteinTarget;
  final double sugar;
  final double sugarTarget;
  final double fiber;

  const _NutritionSummaryCard({
    required this.calories,
    required this.calorieTarget,
    required this.protein,
    required this.proteinTarget,
    required this.sugar,
    required this.sugarTarget,
    required this.fiber,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: _NutritionItem(
                    label: 'Calories',
                    value: '${calories.toInt()}',
                    target: '/ ${calorieTarget.toInt()}',
                    color: AppColors.calories,
                    progress: calories / calorieTarget,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _NutritionItem(
                    label: 'Protein',
                    value: '${protein.toInt()}g',
                    target: '/ ${proteinTarget.toInt()}g',
                    color: AppColors.protein,
                    progress: protein / proteinTarget,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _NutritionItem(
                    label: 'Sugar',
                    value: '${sugar.toInt()}g',
                    target: '/ ${sugarTarget.toInt()}g',
                    color: sugar <= sugarTarget
                        ? AppColors.success
                        : AppColors.error,
                    progress: sugar / sugarTarget,
                    inverted: true,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _NutritionItem(
                    label: 'Fiber',
                    value: '${fiber.toInt()}g',
                    target: '/ 30g',
                    color: AppColors.fiber,
                    progress: fiber / 30,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NutritionItem extends StatelessWidget {
  final String label;
  final String value;
  final String target;
  final Color color;
  final double progress;
  final bool inverted;

  const _NutritionItem({
    required this.label,
    required this.value,
    required this.target,
    required this.color,
    required this.progress,
    this.inverted = false,
  });

  @override
  Widget build(BuildContext context) {
    final clampedProgress = progress.clamp(0.0, 1.0);
    final displayColor = inverted && progress > 1.0 ? AppColors.error : color;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 4),
        Row(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: displayColor,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              target,
              style: const TextStyle(fontSize: 12, color: AppColors.textHint),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: clampedProgress,
            backgroundColor: displayColor.withValues(alpha: 0.15),
            valueColor: AlwaysStoppedAnimation<Color>(displayColor),
            minHeight: 4,
          ),
        ),
      ],
    );
  }
}

class _ImprovementItem extends StatelessWidget {
  final String text;

  const _ImprovementItem({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: AppColors.warning, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _YesterdayComparisonCard extends StatelessWidget {
  final double todayScore;
  final double yesterdayScore;

  const _YesterdayComparisonCard({
    required this.todayScore,
    required this.yesterdayScore,
  });

  @override
  Widget build(BuildContext context) {
    final difference = todayScore - yesterdayScore;
    final isImproved = difference > 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: (isImproved ? AppColors.success : AppColors.error)
                    .withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isImproved ? Icons.trending_up : Icons.trending_down,
                color: isImproved ? AppColors.success : AppColors.error,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Compared to Yesterday',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Yesterday: ${yesterdayScore.toInt()} → Today: ${todayScore.toInt()}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: (isImproved ? AppColors.success : AppColors.error)
                    .withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${isImproved ? '+' : ''}${difference.toInt()}',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isImproved ? AppColors.success : AppColors.error,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
