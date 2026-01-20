import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/models/user_profile.dart';

class PlanGenerationScreen extends ConsumerStatefulWidget {
  const PlanGenerationScreen({super.key});

  @override
  ConsumerState<PlanGenerationScreen> createState() =>
      _PlanGenerationScreenState();
}

class _PlanGenerationScreenState extends ConsumerState<PlanGenerationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  bool _isGenerating = true;
  bool _hasError = false;
  String _currentStep = 'Analyzing your profile...';
  int _stepIndex = 0;
  List<HealthTip> _healthTips = [];

  final List<String> _steps = [
    'Analyzing your profile...',
    'Calculating BMR & TDEE...',
    'Adjusting for health conditions...',
    'Optimizing macro distribution...',
    'Generating health recommendations...',
    'Finalizing your personalized plan...',
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _generatePlan();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _generatePlan() async {
    try {
      // Simulate step progression
      for (int i = 0; i < _steps.length; i++) {
        await Future.delayed(const Duration(milliseconds: 700));
        if (mounted) {
          setState(() {
            _stepIndex = i;
            _currentStep = _steps[i];
          });
        }
      }

      // Calculate personalized targets
      final profile = ref.read(userProfileProvider);
      if (profile != null) {
        final targets = _calculatePersonalizedTargets(profile);
        _healthTips = _generateHealthTips(profile);

        await ref
            .read(userProfileProvider.notifier)
            .updateProfile(
              dailyCalorieTarget: targets['dailyCalories'],
              macroTargets: profile.macroTargets.copyWith(
                proteinGrams: targets['proteinGrams'],
                carbsGrams: targets['carbsGrams'],
                fatGrams: targets['fatGrams'],
              ),
            );
      }

      await Future.delayed(const Duration(milliseconds: 500));

      // Mark onboarding as complete
      await StorageService.setOnboardingComplete(true);

      if (mounted) {
        setState(() => _isGenerating = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _isGenerating = false;
        });
      }
    }
  }

  Map<String, double> _calculatePersonalizedTargets(UserProfile profile) {
    // Provide sensible defaults for missing profile data
    final gender = profile.gender ?? 'male';
    final age = profile.age ?? 30;

    // Weight fallback: Use gender-based average if not provided
    double weight = profile.weightKg ?? 0;
    if (weight <= 0) {
      weight = gender == 'female' ? 65.0 : 75.0; // Average adult weight
    }

    // Height fallback: Use gender-based average if not provided
    double height = profile.heightCm ?? 0;
    if (height <= 0) {
      height = gender == 'female' ? 162.0 : 175.0; // Average adult height
    }

    final goal = profile.goal;
    final healthConditions = profile.healthConditions;
    final dietaryPreferences = profile.dietaryPreferences;

    // Step 1: Calculate BMR using Mifflin-St Jeor (most accurate)
    double bmr;
    if (gender == 'female') {
      bmr = (10 * weight) + (6.25 * height) - (5 * age) - 161;
    } else {
      bmr = (10 * weight) + (6.25 * height) - (5 * age) + 5;
    }

    // Step 2: Apply activity multiplier for TDEE
    double activityMultiplier;
    switch (profile.activityLevel) {
      case 'sedentary':
        activityMultiplier = 1.2;
        break;
      case 'light':
        activityMultiplier = 1.375;
        break;
      case 'moderate':
        activityMultiplier = 1.55;
        break;
      case 'active':
        activityMultiplier = 1.725;
        break;
      case 'very_active':
        activityMultiplier = 1.9;
        break;
      default:
        activityMultiplier = 1.55;
    }

    double tdee = bmr * activityMultiplier;

    // Step 3: Adjust calories based on goal
    double calorieAdjustment = 0;
    switch (goal) {
      case 'lose_fat':
        // More aggressive deficit for higher BMI, moderate for normal
        final bmi = profile.bmi ?? 25;
        if (bmi >= 30) {
          calorieAdjustment = -0.25; // 25% deficit for obese
        } else if (bmi >= 25) {
          calorieAdjustment = -0.20; // 20% deficit for overweight
        } else {
          calorieAdjustment = -0.15; // 15% deficit for normal weight
        }
        break;
      case 'gain_muscle':
        // Surplus based on training experience (assume beginner)
        calorieAdjustment = 0.10; // 10% surplus
        break;
      case 'athletic_performance':
        calorieAdjustment = 0.15; // 15% surplus for performance
        break;
      case 'maintain':
      case 'improve_health':
      case 'medical_nutrition':
      default:
        calorieAdjustment = 0;
    }

    tdee = tdee * (1 + calorieAdjustment);

    // Step 4: Adjust for health conditions
    if (healthConditions.contains('thyroid')) {
      // Thyroid issues can slow metabolism
      tdee *= 0.95;
    }
    if (healthConditions.contains('pcos')) {
      // PCOS often benefits from slightly lower calories
      tdee *= 0.95;
    }

    // Ensure minimum safe calories
    final minCalories = gender == 'female' ? 1200.0 : 1500.0;
    tdee = tdee.clamp(minCalories, 5000.0);

    // Step 5: Calculate optimal macro distribution
    double proteinPercent, carbsPercent, fatPercent;

    // Base distribution on goal
    switch (goal) {
      case 'gain_muscle':
        proteinPercent = 0.30;
        carbsPercent = 0.45;
        fatPercent = 0.25;
        break;
      case 'lose_fat':
        proteinPercent = 0.35;
        carbsPercent = 0.35;
        fatPercent = 0.30;
        break;
      case 'athletic_performance':
        proteinPercent = 0.25;
        carbsPercent = 0.50;
        fatPercent = 0.25;
        break;
      default:
        proteinPercent = 0.25;
        carbsPercent = 0.45;
        fatPercent = 0.30;
    }

    // Adjust for dietary preferences
    if (dietaryPreferences.contains('keto')) {
      // Keto: Very low carb, high fat
      proteinPercent = 0.25;
      carbsPercent = 0.05;
      fatPercent = 0.70;
    } else if (dietaryPreferences.contains('high_protein')) {
      // High protein adjustment
      proteinPercent += 0.05;
      carbsPercent -= 0.05;
    }

    // Adjust for health conditions
    if (healthConditions.any(
      (c) => c.contains('diabetes') || c == 'prediabetic' || c == 'pcos',
    )) {
      // Lower carb for insulin resistance conditions
      if (!dietaryPreferences.contains('keto')) {
        carbsPercent = (carbsPercent - 0.10).clamp(0.20, 0.50);
        fatPercent = (fatPercent + 0.05).clamp(0.20, 0.40);
        proteinPercent = (proteinPercent + 0.05).clamp(0.20, 0.40);
      }
    }

    if (healthConditions.contains('high_cholesterol') ||
        healthConditions.contains('heart_health')) {
      // Heart-healthy: Moderate fat, more emphasis on healthy fats
      fatPercent = fatPercent.clamp(0.25, 0.30);
    }

    // Normalize percentages to sum to 1.0
    final total = proteinPercent + carbsPercent + fatPercent;
    proteinPercent /= total;
    carbsPercent /= total;
    fatPercent /= total;

    // Step 6: Calculate gram amounts
    // Protein: 4 cal/g, Carbs: 4 cal/g, Fat: 9 cal/g
    double proteinGrams = (tdee * proteinPercent) / 4;
    double carbsGrams = (tdee * carbsPercent) / 4;
    double fatGrams = (tdee * fatPercent) / 9;

    // Apply protein minimum based on body weight (0.8-1.6g per kg for general, higher for muscle gain)
    // Ensure minimum protein even with low/missing weight data
    double minProtein = (weight * 0.8).clamp(50.0, weight * 2.2);
    if (goal == 'gain_muscle' || goal == 'athletic_performance') {
      minProtein = (weight * 1.6).clamp(80.0, weight * 2.2);
    } else if (goal == 'lose_fat') {
      minProtein = (weight * 1.2).clamp(
        60.0,
        weight * 2.2,
      ); // Preserve muscle during deficit
    }

    // Ensure protein is reasonable even with calculated values
    proteinGrams = proteinGrams
        .clamp(minProtein, weight * 2.2)
        .clamp(50.0, 300.0);

    return {
      'dailyCalories': tdee.roundToDouble(),
      'proteinGrams': proteinGrams.roundToDouble(),
      'carbsGrams': carbsGrams.roundToDouble(),
      'fatGrams': fatGrams.roundToDouble(),
    };
  }

  List<HealthTip> _generateHealthTips(UserProfile profile) {
    final tips = <HealthTip>[];
    final goal = profile.goal;
    final conditions = profile.healthConditions;
    final preferences = profile.dietaryPreferences;

    // Goal-based tips
    switch (goal) {
      case 'lose_fat':
        tips.add(
          HealthTip(
            icon: Icons.restaurant,
            title: 'Eat protein with every meal',
            description:
                'Protein helps preserve muscle and keeps you feeling full longer.',
            category: TipCategory.nutrition,
          ),
        );
        tips.add(
          HealthTip(
            icon: Icons.directions_walk,
            title: 'Aim for 8,000-10,000 steps daily',
            description:
                'Walking burns calories without stressing your body or increasing appetite.',
            category: TipCategory.workout,
          ),
        );
        tips.add(
          HealthTip(
            icon: Icons.no_food,
            title: 'Avoid liquid calories',
            description:
                'Skip sodas, juices, and fancy coffees. They add calories without satisfying hunger.',
            category: TipCategory.avoid,
          ),
        );
        break;

      case 'gain_muscle':
        tips.add(
          HealthTip(
            icon: Icons.fitness_center,
            title: 'Progressive overload is key',
            description:
                'Gradually increase weights or reps each week to stimulate muscle growth.',
            category: TipCategory.workout,
          ),
        );
        tips.add(
          HealthTip(
            icon: Icons.bedtime,
            title: 'Prioritize sleep (7-9 hours)',
            description:
                'Muscle growth and recovery happen primarily during deep sleep.',
            category: TipCategory.lifestyle,
          ),
        );
        tips.add(
          HealthTip(
            icon: Icons.schedule,
            title: 'Eat protein every 3-4 hours',
            description:
                'Spread protein intake throughout the day for optimal muscle protein synthesis.',
            category: TipCategory.nutrition,
          ),
        );
        break;

      case 'athletic_performance':
        tips.add(
          HealthTip(
            icon: Icons.water_drop,
            title: 'Stay hydrated',
            description:
                'Drink water before, during, and after workouts. Aim for 3-4 liters daily.',
            category: TipCategory.nutrition,
          ),
        );
        tips.add(
          HealthTip(
            icon: Icons.bolt,
            title: 'Time your carbs around training',
            description:
                'Eat carbs before and after workouts for energy and recovery.',
            category: TipCategory.nutrition,
          ),
        );
        break;

      case 'improve_health':
      case 'maintain':
        tips.add(
          HealthTip(
            icon: Icons.colorize,
            title: 'Eat the rainbow',
            description:
                'Include fruits and vegetables of different colors for diverse nutrients.',
            category: TipCategory.nutrition,
          ),
        );
        tips.add(
          HealthTip(
            icon: Icons.self_improvement,
            title: 'Manage stress levels',
            description:
                'High stress affects hormones that regulate appetite and fat storage.',
            category: TipCategory.lifestyle,
          ),
        );
        break;
    }

    // Health condition-specific tips
    if (conditions.contains('high_blood_pressure')) {
      tips.add(
        HealthTip(
          icon: Icons.no_meals,
          title: 'Limit sodium to 1,500-2,000mg',
          description:
              'Avoid processed foods, canned soups, and excessive salt. Use herbs and spices instead.',
          category: TipCategory.avoid,
        ),
      );
      tips.add(
        HealthTip(
          icon: Icons.favorite,
          title: 'Eat potassium-rich foods',
          description:
              'Bananas, spinach, and sweet potatoes help balance sodium and lower blood pressure.',
          category: TipCategory.nutrition,
        ),
      );
    }

    if (conditions.any(
      (c) => c.contains('diabetes') || c == 'prediabetic' || c == 'pcos',
    )) {
      tips.add(
        HealthTip(
          icon: Icons.show_chart,
          title: 'Choose low glycemic foods',
          description:
              'Opt for whole grains, legumes, and non-starchy vegetables to manage blood sugar.',
          category: TipCategory.nutrition,
        ),
      );
      tips.add(
        HealthTip(
          icon: Icons.no_food,
          title: 'Avoid refined carbs & sugars',
          description:
              'White bread, pastries, and sugary drinks cause blood sugar spikes.',
          category: TipCategory.avoid,
        ),
      );
      tips.add(
        HealthTip(
          icon: Icons.directions_walk,
          title: 'Walk after meals',
          description:
              'A 10-15 minute walk after eating helps lower blood sugar levels.',
          category: TipCategory.workout,
        ),
      );
    }

    if (conditions.contains('pcos')) {
      tips.add(
        HealthTip(
          icon: Icons.egg,
          title: 'Focus on anti-inflammatory foods',
          description:
              'Include fatty fish, leafy greens, berries, and turmeric to reduce inflammation.',
          category: TipCategory.nutrition,
        ),
      );
      tips.add(
        HealthTip(
          icon: Icons.fitness_center,
          title: 'Combine cardio with strength training',
          description:
              'Both help improve insulin sensitivity and manage PCOS symptoms.',
          category: TipCategory.workout,
        ),
      );
    }

    if (conditions.contains('high_cholesterol') ||
        conditions.contains('heart_health')) {
      tips.add(
        HealthTip(
          icon: Icons.favorite_border,
          title: 'Choose healthy fats',
          description:
              'Eat olive oil, avocados, nuts, and fatty fish. Limit saturated and trans fats.',
          category: TipCategory.nutrition,
        ),
      );
      tips.add(
        HealthTip(
          icon: Icons.no_food,
          title: 'Avoid fried and processed foods',
          description:
              'These are high in unhealthy fats that raise LDL cholesterol.',
          category: TipCategory.avoid,
        ),
      );
      tips.add(
        HealthTip(
          icon: Icons.grass,
          title: 'Increase soluble fiber',
          description:
              'Oats, beans, apples, and flaxseed help lower LDL cholesterol.',
          category: TipCategory.nutrition,
        ),
      );
    }

    if (conditions.contains('thyroid')) {
      tips.add(
        HealthTip(
          icon: Icons.local_pharmacy,
          title: 'Take thyroid meds on empty stomach',
          description:
              'Wait 30-60 minutes before eating for proper absorption.',
          category: TipCategory.lifestyle,
        ),
      );
      tips.add(
        HealthTip(
          icon: Icons.eco,
          title: 'Include selenium-rich foods',
          description:
              'Brazil nuts, seafood, and eggs support thyroid function.',
          category: TipCategory.nutrition,
        ),
      );
    }

    // Dietary preference tips
    if (preferences.contains('vegetarian') || preferences.contains('vegan')) {
      tips.add(
        HealthTip(
          icon: Icons.spa,
          title: 'Combine plant proteins',
          description:
              'Pair legumes with grains (rice & beans) to get complete proteins.',
          category: TipCategory.nutrition,
        ),
      );
      if (preferences.contains('vegan')) {
        tips.add(
          HealthTip(
            icon: Icons.wb_sunny,
            title: 'Consider B12 & Vitamin D',
            description:
                'These are harder to get from plant sources. Consider supplements.',
            category: TipCategory.nutrition,
          ),
        );
      }
    }

    if (preferences.contains('keto')) {
      tips.add(
        HealthTip(
          icon: Icons.water_drop,
          title: 'Stay hydrated & get electrolytes',
          description:
              'Keto increases water loss. Add salt, potassium, and magnesium.',
          category: TipCategory.nutrition,
        ),
      );
      tips.add(
        HealthTip(
          icon: Icons.warning,
          title: 'Watch for keto flu',
          description:
              'Fatigue and headaches in the first week are normal. They will pass.',
          category: TipCategory.lifestyle,
        ),
      );
    }

    // General tips everyone should know
    tips.add(
      HealthTip(
        icon: Icons.local_drink,
        title: 'Drink water before meals',
        description:
            'A glass of water 30 minutes before eating aids digestion and helps control portions.',
        category: TipCategory.nutrition,
      ),
    );

    // Limit to top 6 most relevant tips
    return tips.take(6).toList();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider);

    return Scaffold(
      body: SafeArea(
        child: _isGenerating
            ? Padding(
                padding: const EdgeInsets.all(24),
                child: _buildGeneratingView(),
              )
            : _hasError
            ? Padding(
                padding: const EdgeInsets.all(24),
                child: _buildErrorView(),
              )
            : _buildSuccessView(profile),
      ),
    );
  }

  Widget _buildGeneratingView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          RotationTransition(
            turns: _animationController,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.auto_awesome,
                size: 40,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 32),
          const Text(
            'Creating Your Plan',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _currentStep,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: 200,
            child: LinearProgressIndicator(
              value: (_stepIndex + 1) / _steps.length,
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primary,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditTargetsDialog(dynamic profile) {
    final caloriesController = TextEditingController(
      text: '${profile?.dailyCalorieTarget.toInt() ?? 2000}',
    );
    final proteinController = TextEditingController(
      text: '${profile?.macroTargets.proteinGrams.toInt() ?? 150}',
    );
    final carbsController = TextEditingController(
      text: '${profile?.macroTargets.carbsGrams.toInt() ?? 200}',
    );
    final fatController = TextEditingController(
      text: '${profile?.macroTargets.fatGrams.toInt() ?? 65}',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.edit, color: AppColors.primary, size: 24),
            const SizedBox(width: 8),
            const Text('Edit Nutrition Targets'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Adjust your daily nutrition goals',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),
              _EditTargetField(
                controller: caloriesController,
                label: 'Daily Calories',
                suffix: 'kcal',
                icon: Icons.local_fire_department,
                color: AppColors.calories,
              ),
              const SizedBox(height: 16),
              _EditTargetField(
                controller: proteinController,
                label: 'Protein',
                suffix: 'g',
                icon: Icons.fitness_center,
                color: AppColors.protein,
              ),
              const SizedBox(height: 16),
              _EditTargetField(
                controller: carbsController,
                label: 'Carbs',
                suffix: 'g',
                icon: Icons.grain,
                color: AppColors.carbs,
              ),
              const SizedBox(height: 16),
              _EditTargetField(
                controller: fatController,
                label: 'Fat',
                suffix: 'g',
                icon: Icons.water_drop,
                color: AppColors.fat,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final calories = double.tryParse(caloriesController.text) ?? 2000;
              final protein = double.tryParse(proteinController.text) ?? 150;
              final carbs = double.tryParse(carbsController.text) ?? 200;
              final fat = double.tryParse(fatController.text) ?? 65;

              await ref
                  .read(userProfileProvider.notifier)
                  .updateProfile(
                    dailyCalorieTarget: calories,
                    macroTargets: profile?.macroTargets.copyWith(
                      proteinGrams: protein,
                      carbsGrams: carbs,
                      fatGrams: fat,
                    ),
                  );

              if (mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 80, color: AppColors.error),
          const SizedBox(height: 24),
          const Text(
            'Something went wrong',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'We\'ll use default settings. You can adjust later.',
            style: TextStyle(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          PrimaryButton(
            text: 'Continue Anyway',
            onPressed: () async {
              await StorageService.setOnboardingComplete(true);
              if (mounted) context.go('${AppRoutes.auth}?signup=true');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView(dynamic profile) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle,
              size: 50,
              color: AppColors.success,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Your Plan is Ready!',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Personalized nutrition targets based on your profile',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),

          // Nutrition Summary card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.restaurant_menu,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Daily Nutrition Targets',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => _showEditTargetsDialog(profile),
                        icon: const Icon(Icons.edit, size: 16),
                        label: const Text('Edit'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _SummaryRow(
                    icon: Icons.local_fire_department,
                    label: 'Daily Calories',
                    value:
                        '${profile?.dailyCalorieTarget.toInt() ?? 2000} kcal',
                    color: AppColors.calories,
                  ),
                  const Divider(height: 20),
                  _SummaryRow(
                    icon: Icons.fitness_center,
                    label: 'Protein',
                    value:
                        '${profile?.macroTargets.proteinGrams.toInt() ?? 150}g',
                    color: AppColors.protein,
                  ),
                  const Divider(height: 20),
                  _SummaryRow(
                    icon: Icons.grain,
                    label: 'Carbs',
                    value:
                        '${profile?.macroTargets.carbsGrams.toInt() ?? 200}g',
                    color: AppColors.carbs,
                  ),
                  const Divider(height: 20),
                  _SummaryRow(
                    icon: Icons.water_drop,
                    label: 'Fat',
                    value: '${profile?.macroTargets.fatGrams.toInt() ?? 65}g',
                    color: AppColors.fat,
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Health Tips Section
          if (_healthTips.isNotEmpty) ...[
            Row(
              children: [
                Icon(
                  Icons.tips_and_updates,
                  color: AppColors.secondary,
                  size: 22,
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Personalized Health Tips',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Based on your goals and health conditions',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            ..._healthTips.map((tip) => _HealthTipCard(tip: tip)),
          ],

          const SizedBox(height: 32),
          PrimaryButton(
            text: 'Create Account & Start',
            onPressed: () => context.go('${AppRoutes.auth}?signup=true'),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

enum TipCategory { nutrition, workout, avoid, lifestyle }

class HealthTip {
  final IconData icon;
  final String title;
  final String description;
  final TipCategory category;

  HealthTip({
    required this.icon,
    required this.title,
    required this.description,
    required this.category,
  });
}

class _HealthTipCard extends StatelessWidget {
  final HealthTip tip;

  const _HealthTipCard({required this.tip});

  Color get _categoryColor {
    switch (tip.category) {
      case TipCategory.nutrition:
        return AppColors.success;
      case TipCategory.workout:
        return AppColors.primary;
      case TipCategory.avoid:
        return AppColors.error;
      case TipCategory.lifestyle:
        return AppColors.secondary;
    }
  }

  String get _categoryLabel {
    switch (tip.category) {
      case TipCategory.nutrition:
        return 'NUTRITION';
      case TipCategory.workout:
        return 'WORKOUT';
      case TipCategory.avoid:
        return 'AVOID';
      case TipCategory.lifestyle:
        return 'LIFESTYLE';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _categoryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _categoryColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _categoryColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(tip.icon, color: _categoryColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _categoryColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _categoryLabel,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: _categoryColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  tip.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  tip.description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _EditTargetField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String suffix;
  final IconData icon;
  final Color color;

  const _EditTargetField({
    required this.controller,
    required this.label,
    required this.suffix,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextFormField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: label,
              suffixText: suffix,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: color, width: 2),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
