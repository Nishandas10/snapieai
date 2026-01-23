import 'dart:math';
import '../models/health_score.dart';
import '../models/daily_log.dart';
import '../models/food_item.dart';
import '../models/user_profile.dart';

/// Service for calculating daily health scores based on nutrition data
class HealthScoreService {
  HealthScoreService._();

  /// Calculate the health score for a given daily log
  ///
  /// Score Breakdown (Total: 100 points):
  /// - Macro Balance: 40 points (Protein goals, balanced macros)
  /// - Glycemic Control: 30 points (Sugar control, low GI foods - USP)
  /// - Micronutrient Density: 20 points (Iron, Vitamins, Minerals)
  /// - Consistency & Goals: 10 points (Calorie adherence, logging, health goals)
  static DailyHealthScore calculateScore({
    required DailyLog? todayLog,
    required UserProfile? profile,
    int currentStreak = 0,
    double? yesterdayScore,
  }) {
    final date = todayLog?.date ?? DateTime.now();
    final dateKey =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    if (todayLog == null || profile == null) {
      return DailyHealthScore(
        dateKey: dateKey,
        date: date,
        breakdown: const HealthScoreBreakdown(),
        streak: currentStreak,
        yesterdayScore: yesterdayScore,
        suggestions: _getDefaultSuggestions(),
      );
    }

    // Calculate individual scores
    final macroScore = _calculateMacroBalanceScore(todayLog, profile);
    final glycemicScore = _calculateGlycemicControlScore(todayLog, profile);
    final microScore = _calculateMicronutrientScore(todayLog);
    final consistencyScore = _calculateConsistencyScore(
      todayLog,
      profile,
      currentStreak,
    );

    final breakdown = HealthScoreBreakdown(
      macroBalanceScore: macroScore,
      glycemicControlScore: glycemicScore,
      micronutrientScore: microScore,
      consistencyScore: consistencyScore,
    );

    // Generate improvement areas and suggestions
    final improvements = _getImprovementAreas(breakdown, todayLog, profile);
    final suggestions = _generateSuggestions(breakdown, todayLog, profile);

    return DailyHealthScore(
      dateKey: dateKey,
      date: date,
      breakdown: breakdown,
      improvements: improvements,
      suggestions: suggestions,
      streak: currentStreak,
      yesterdayScore: yesterdayScore,
    );
  }

  /// Calculate Macro Balance Score (out of 40 points)
  /// - 20 points for protein goal
  /// - 10 points for carbs balance
  /// - 10 points for fat balance
  ///
  /// Uses progressive scoring based on how close you are to your goal.
  /// Scoring is optimized at 100% of goal with penalty for going over.
  static double _calculateMacroBalanceScore(DailyLog log, UserProfile profile) {
    double score = 0;

    final proteinGoal = profile.macroTargets.proteinGrams;
    final carbsGoal = profile.macroTargets.carbsGrams;
    final fatGoal = profile.macroTargets.fatGrams;

    final proteinConsumed = log.totalProtein;
    final carbsConsumed = log.totalCarbs;
    final fatConsumed = log.totalFat;

    // Protein score (20 points) - Progressive scoring
    // Get full points when at goal, proportional points when under
    // Small penalty when significantly over (>130%)
    if (proteinGoal > 0) {
      final proteinRatio = proteinConsumed / proteinGoal;
      if (proteinRatio <= 1.0) {
        // Under or at goal: score proportionally (0-100% = 0-20 points)
        score += (proteinRatio * 20).clamp(0, 20);
      } else if (proteinRatio <= 1.3) {
        // Slightly over goal: still good, full points with small reduction
        score += 20 - ((proteinRatio - 1.0) * 10); // 20 to 17 points
      } else {
        // Way over goal: reduce more but still give credit
        score += 15 - ((proteinRatio - 1.3) * 5).clamp(0, 10); // 15 to 5 points
      }
    }

    // Carbs score (10 points) - Progressive scoring
    if (carbsGoal > 0) {
      final carbsRatio = carbsConsumed / carbsGoal;
      if (carbsRatio <= 1.0) {
        // Under or at goal: score proportionally
        score += (carbsRatio * 10).clamp(0, 10);
      } else if (carbsRatio <= 1.3) {
        // Slightly over: small penalty
        score += 10 - ((carbsRatio - 1.0) * 10); // 10 to 7 points
      } else {
        // Way over: bigger penalty but still give credit
        score += 7 - ((carbsRatio - 1.3) * 7).clamp(0, 5); // 7 to 2 points
      }
    }

    // Fat score (10 points) - Progressive scoring
    if (fatGoal > 0) {
      final fatRatio = fatConsumed / fatGoal;
      if (fatRatio <= 1.0) {
        // Under or at goal: score proportionally
        score += (fatRatio * 10).clamp(0, 10);
      } else if (fatRatio <= 1.3) {
        // Slightly over: small penalty
        score += 10 - ((fatRatio - 1.0) * 10); // 10 to 7 points
      } else {
        // Way over: heavy penalty (oily/junk food)
        // 1.3 -> 7 pts
        // 1.6 -> 0 pts
        score += 7 - ((fatRatio - 1.3) * 23).clamp(0, 7);
      }
    }

    // Penalties for unbalanced intake (Junk Food detection)
    // High fat + High carbs usually means junk food
    if (fatConsumed > fatGoal * 1.2 && carbsConsumed > carbsGoal * 1.2) {
      score -= 5;
    }

    return score.clamp(0, 40);
  }

  /// Calculate Glycemic Control Score (out of 30 points) - YOUR USP
  /// - 15 points for sugar control
  /// - 15 points for low GI food choices
  ///
  /// Uses progressive scoring that rewards keeping sugar low
  static double _calculateGlycemicControlScore(
    DailyLog log,
    UserProfile profile,
  ) {
    double score = 0;

    // Get all food items
    final allFoods = <FoodItem>[];
    for (final meal in log.meals) {
      for (final food in meal.foods) {
        allFoods.add(food);
        if (food.subItems != null) {
          allFoods.addAll(food.subItems!);
        }
      }
    }

    if (allFoods.isEmpty) return 0;

    // Sugar control (15 points) - Progressive scoring
    // Lower sugar = higher score (inverse relationship)
    final sugarTarget = profile.macroTargets.sugarGrams ?? 50;
    final sugarConsumed = log.totalSugar;

    if (sugarConsumed <= 0) {
      // No sugar logged yet - give base points for logging
      score += 10;
    } else {
      final sugarRatio = sugarConsumed / sugarTarget;
      if (sugarRatio <= 0.5) {
        // Excellent - less than half sugar target
        score += 15;
      } else if (sugarRatio <= 1.0) {
        // Good - under target, progressive scoring from 15 to 9
        score += 15 - ((sugarRatio - 0.5) * 12); // 15 at 50%, 9 at 100%
      } else if (sugarRatio <= 1.2) {
        // Over target - sharp drop
        // 1.0 -> 9 pts
        // 1.2 -> 2 pts
        score += 9 - ((sugarRatio - 1.0) * 35);
      } else {
        // Way over - 0 points
        score += 0;
      }
    }

    // Penalty for diabetic/prediabetic users with high sugar
    if (profile.hasDiabetes && sugarConsumed > sugarTarget) {
      score -= 5;
    }

    // Heavy penalty for extreme sugar (junk food detection)
    if (sugarConsumed > sugarTarget * 1.5) {
      score -= 5;
    }

    // GI score (15 points) - Progressive based on ratio of low GI foods
    int lowGICount = 0;
    int highGICount = 0;

    for (final food in allFoods) {
      final gi = food.glycemicIndex ?? 50;
      if (gi <= 55) {
        lowGICount++;
      } else if (gi > 70) {
        highGICount++;
      }
    }

    final totalItems = allFoods.length;
    if (totalItems > 0) {
      final lowGIRatio = lowGICount / totalItems;
      final highGIRatio = highGICount / totalItems;

      // Progressive scoring based on low GI ratio
      // 100% low GI = 15 points, 0% low GI = 4 points
      score += 4 + (lowGIRatio * 11);

      // Penalty for high GI foods (progressive)
      if (highGIRatio > 0.2) {
        score -= ((highGIRatio - 0.2) * 8).clamp(0, 5);
      }

      // Extra penalty for diabetics with high GI foods
      if (profile.hasDiabetes && highGIRatio > 0.15) {
        score -= 2;
      }
    }

    return score.clamp(0, 30);
  }

  /// Calculate Micronutrient Density Score (out of 20 points)
  /// - 5 points for iron
  /// - 5 points for vitamins
  /// - 5 points for calcium
  /// - 5 points for fiber
  ///
  /// Uses progressive linear scoring - partial credit for partial intake
  static double _calculateMicronutrientScore(DailyLog log) {
    double score = 0;

    // Get all food items
    final allFoods = <FoodItem>[];
    for (final meal in log.meals) {
      for (final food in meal.foods) {
        allFoods.add(food);
        if (food.subItems != null) {
          allFoods.addAll(food.subItems!);
        }
      }
    }

    // If no foods logged yet, return 0 but allow score to grow as foods are added
    if (allFoods.isEmpty) return 0;

    // Calculate totals
    double totalIronPercent = 0;
    double totalVitaminAPercent = 0;
    double totalVitaminCPercent = 0;
    double totalCalciumPercent = 0;

    for (final food in allFoods) {
      // Iron is in mg, convert to approximate %DV (18mg is 100%)
      final ironDV = ((food.ironMg ?? 0) / 18) * 100;
      totalIronPercent += ironDV;
      totalVitaminAPercent += food.vitaminAPercent ?? 0;
      totalVitaminCPercent += food.vitaminCPercent ?? 0;
      // Calcium is in mg, convert to approximate %DV (1000mg is 100%)
      final calciumDV = ((food.calciumMg ?? 0) / 1000) * 100;
      totalCalciumPercent += calciumDV;
    }

    // Iron score (5 points) - Progressive: 1% DV = 0.05 points, max at 100% DV
    score += (totalIronPercent / 100 * 5).clamp(0, 5);

    // Vitamin score (5 points) - average of A and C, progressive
    final avgVitaminPercent = (totalVitaminAPercent + totalVitaminCPercent) / 2;
    score += (avgVitaminPercent / 100 * 5).clamp(0, 5);

    // Calcium score (5 points) - Progressive
    score += (totalCalciumPercent / 100 * 5).clamp(0, 5);

    // Fiber score (5 points) - 30g target, progressive
    final fiberTarget = 30.0;
    final fiberConsumed = log.totalFiber;
    score += (fiberConsumed / fiberTarget * 5).clamp(0, 5);

    return score.clamp(0, 20);
  }

  /// Calculate Consistency & Goals Score (out of 10 points)
  /// - 4 points for calorie adherence
  /// - 3 points for logging consistency (streak bonus)
  /// - 3 points for health condition adherence
  ///
  /// Uses progressive scoring for calorie adherence
  static double _calculateConsistencyScore(
    DailyLog log,
    UserProfile profile,
    int streak,
  ) {
    double score = 0;

    // Calorie adherence (4 points) - Progressive scoring
    final calorieTarget = profile.dailyCalorieTarget;
    final caloriesConsumed = log.totalCalories;

    if (calorieTarget > 0 && caloriesConsumed > 0) {
      final calorieRatio = caloriesConsumed / calorieTarget;

      if (calorieRatio <= 1.0) {
        // Under or at goal: score proportionally
        score += (calorieRatio * 4).clamp(0, 4);
      } else if (calorieRatio <= 1.2) {
        // Slightly over (up to 20%): full points with small reduction
        score += 4 - ((calorieRatio - 1.0) * 10); // 4 to 2 points
      } else {
        // Way over: minimum credit for logging
        score += 1;
      }
    }

    // Streak bonus (3 points)
    if (streak >= 7) {
      score += 3; // Week-long streak
    } else if (streak >= 3) {
      score += 2; // 3+ day streak
    } else if (streak >= 1) {
      score += 1; // At least logged today
    }

    // Health condition adherence (3 points)
    double healthScore = 3;

    if (profile.hasHighBP) {
      // Sodium check
      final sodiumLimit = profile.macroTargets.sodiumMg ?? 2300;
      if (log.totalSodium > sodiumLimit) {
        healthScore -= 1;
      }
    }

    if (profile.hasDiabetes) {
      // Already penalized in glycemic score, small check here
      final sugarTarget = profile.macroTargets.sugarGrams ?? 50;
      if (log.totalSugar > sugarTarget * 1.5) {
        healthScore -= 1;
      }
    }

    if (profile.hasHighCholesterol) {
      // Check saturated fat
      final allFoods = <FoodItem>[];
      for (final meal in log.meals) {
        allFoods.addAll(meal.foods);
      }
      final totalSatFat = allFoods.fold(
        0.0,
        (sum, f) => sum + (f.saturatedFatGrams ?? 0),
      );
      if (totalSatFat > 20) {
        healthScore -= 1;
      }
    }

    score += max(0, healthScore);

    return score.clamp(0, 10);
  }

  /// Get improvement areas based on score breakdown
  static List<String> _getImprovementAreas(
    HealthScoreBreakdown breakdown,
    DailyLog log,
    UserProfile profile,
  ) {
    final improvements = <String>[];

    if (breakdown.macroBalanceScore < 30) {
      final proteinConsumed = log.totalProtein;
      final proteinGoal = profile.macroTargets.proteinGrams;
      if (proteinConsumed < proteinGoal * 0.8) {
        improvements.add(
          'Protein intake is low (${proteinConsumed.toInt()}g / ${proteinGoal.toInt()}g)',
        );
      }
    }

    if (breakdown.glycemicControlScore < 20) {
      if (log.totalSugar > (profile.macroTargets.sugarGrams ?? 50)) {
        improvements.add('Sugar intake is high');
      }
      improvements.add('Consider more low-GI food choices');
    }

    if (breakdown.micronutrientScore < 12) {
      improvements.add('Add more nutrient-dense foods (leafy greens, fruits)');
    }

    if (breakdown.consistencyScore < 6) {
      final calorieRatio = log.totalCalories / profile.dailyCalorieTarget;
      if (calorieRatio < 0.8 || calorieRatio > 1.2) {
        improvements.add('Calorie intake is off target');
      }
    }

    return improvements;
  }

  /// Generate actionable suggestions to improve score
  static List<HealthScoreSuggestion> _generateSuggestions(
    HealthScoreBreakdown breakdown,
    DailyLog log,
    UserProfile profile,
  ) {
    final suggestions = <HealthScoreSuggestion>[];

    // Macro suggestions
    if (breakdown.macroBalanceScore < 30) {
      final proteinGap = profile.macroTargets.proteinGrams - log.totalProtein;
      if (proteinGap > 20) {
        suggestions.add(
          HealthScoreSuggestion(
            category: 'Protein',
            title: 'Boost Your Protein',
            description:
                'You\'re ${proteinGap.toInt()}g short of your protein goal.',
            foodSuggestion:
                'Add grilled chicken, Greek yogurt, or eggs to your next meal.',
            potentialPoints: 10,
            icon: '🥩',
          ),
        );
      }
    }

    // Glycemic suggestions
    if (breakdown.glycemicControlScore < 20) {
      if (log.totalSugar > (profile.macroTargets.sugarGrams ?? 50)) {
        suggestions.add(
          HealthScoreSuggestion(
            category: 'Sugar Control',
            title: 'Reduce Sugar Intake',
            description: 'Your sugar intake is above target.',
            foodSuggestion: 'Swap sugary drinks for water or unsweetened tea.',
            potentialPoints: 8,
            icon: '🍬',
          ),
        );
      } else {
        suggestions.add(
          HealthScoreSuggestion(
            category: 'Glycemic Index',
            title: 'Choose Low-GI Foods',
            description: 'Try foods that keep blood sugar stable.',
            foodSuggestion:
                'Opt for quinoa, oats, or legumes instead of white rice.',
            potentialPoints: 7,
            icon: '📊',
          ),
        );
      }
    }

    // Micronutrient suggestions
    if (breakdown.micronutrientScore < 12) {
      suggestions.add(
        HealthScoreSuggestion(
          category: 'Micronutrients',
          title: 'Add Nutrient-Dense Foods',
          description: 'Your vitamin and mineral intake could be better.',
          foodSuggestion: 'Eat a spinach salad or a handful of almonds.',
          potentialPoints: 6,
          icon: '🥬',
        ),
      );
    }

    // Fiber suggestions
    if (log.totalFiber < 25) {
      suggestions.add(
        HealthScoreSuggestion(
          category: 'Fiber',
          title: 'Increase Fiber Intake',
          description: 'Fiber helps digestion and keeps you full.',
          foodSuggestion: 'Add beans, berries, or whole grains to your meals.',
          potentialPoints: 4,
          icon: '🌾',
        ),
      );
    }

    // Health condition specific suggestions
    if (profile.hasHighBP && log.totalSodium > 1500) {
      suggestions.add(
        HealthScoreSuggestion(
          category: 'Blood Pressure',
          title: 'Watch Your Sodium',
          description: 'High sodium affects blood pressure.',
          foodSuggestion: 'Choose fresh foods over processed options.',
          potentialPoints: 3,
          icon: '🧂',
        ),
      );
    }

    if (profile.hasDiabetes && log.totalSugar > 30) {
      suggestions.add(
        HealthScoreSuggestion(
          category: 'Diabetes Management',
          title: 'Monitor Carb Quality',
          description: 'Focus on complex carbs for steady blood sugar.',
          foodSuggestion: 'Replace white bread with whole grain alternatives.',
          potentialPoints: 5,
          icon: '🩺',
        ),
      );
    }

    return suggestions;
  }

  /// Get default suggestions when no food is logged
  static List<HealthScoreSuggestion> _getDefaultSuggestions() {
    return [
      const HealthScoreSuggestion(
        category: 'Getting Started',
        title: 'Log Your First Meal',
        description: 'Start tracking to see your health score improve!',
        foodSuggestion: 'Snap a photo of your breakfast to begin.',
        potentialPoints: 10,
        icon: '📸',
      ),
    ];
  }

  /// Calculate potential score after following suggestions
  static double calculatePotentialScore(DailyHealthScore currentScore) {
    final current = currentScore.totalScore;
    final potentialGain = currentScore.suggestions.fold(
      0,
      (sum, s) => sum + s.potentialPoints,
    );
    return min(100, current + potentialGain);
  }
}
