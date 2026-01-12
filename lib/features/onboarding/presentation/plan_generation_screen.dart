import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/services/storage_service.dart';

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

  final List<String> _steps = [
    'Analyzing your profile...',
    'Calculating nutrition targets...',
    'Considering health conditions...',
    'Generating personalized plan...',
    'Finalizing recommendations...',
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
        await Future.delayed(const Duration(milliseconds: 800));
        if (mounted) {
          setState(() {
            _stepIndex = i;
            _currentStep = _steps[i];
          });
        }
      }

      // Calculate basic targets locally (no API needed for initial setup)
      final profile = ref.read(userProfileProvider);
      if (profile != null) {
        final targets = _calculateTargets(profile);

        await ref
            .read(userProfileProvider.notifier)
            .updateProfile(
              dailyCalorieTarget: targets['dailyCalories']?.toDouble(),
              macroTargets: profile.macroTargets.copyWith(
                proteinGrams: targets['proteinGrams']?.toDouble(),
                carbsGrams: targets['carbsGrams']?.toDouble(),
                fatGrams: targets['fatGrams']?.toDouble(),
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

  Map<String, double> _calculateTargets(dynamic profile) {
    // Basic Mifflin-St Jeor calculation
    double bmr;
    final weight = profile.weightKg ?? 70.0;
    final height = profile.heightCm ?? 170.0;
    final age = profile.age ?? 30;
    final gender = profile.gender ?? 'male';

    if (gender == 'female') {
      bmr = (10 * weight) + (6.25 * height) - (5 * age) - 161;
    } else {
      bmr = (10 * weight) + (6.25 * height) - (5 * age) + 5;
    }

    // Activity multiplier
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

    // Goal adjustment
    switch (profile.goal) {
      case 'lose_fat':
        tdee *= 0.8; // 20% deficit
        break;
      case 'gain_muscle':
        tdee *= 1.1; // 10% surplus
        break;
      default:
        break;
    }

    // Macro split based on goal
    double proteinPercent, carbsPercent, fatPercent;
    switch (profile.goal) {
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
      default:
        proteinPercent = 0.25;
        carbsPercent = 0.45;
        fatPercent = 0.30;
    }

    return {
      'dailyCalories': tdee.round().toDouble(),
      'proteinGrams': ((tdee * proteinPercent) / 4).round().toDouble(),
      'carbsGrams': ((tdee * carbsPercent) / 4).round().toDouble(),
      'fatGrams': ((tdee * fatPercent) / 9).round().toDouble(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _isGenerating
              ? _buildGeneratingView()
              : _hasError
              ? _buildErrorView()
              : _buildSuccessView(profile),
        ),
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
              if (mounted) context.go(AppRoutes.auth);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView(dynamic profile) {
    return Column(
      children: [
        const Spacer(),
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: AppColors.success.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.check_circle,
            size: 60,
            color: AppColors.success,
          ),
        ),
        const SizedBox(height: 32),
        const Text(
          'Your Plan is Ready!',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'Here\'s your personalized nutrition targets',
          style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
        ),
        const SizedBox(height: 40),

        // Summary card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                _SummaryRow(
                  icon: Icons.local_fire_department,
                  label: 'Daily Calories',
                  value: '${profile?.dailyCalorieTarget.toInt() ?? 2000} kcal',
                  color: AppColors.calories,
                ),
                const Divider(height: 24),
                _SummaryRow(
                  icon: Icons.fitness_center,
                  label: 'Protein',
                  value:
                      '${profile?.macroTargets.proteinGrams.toInt() ?? 150}g',
                  color: AppColors.protein,
                ),
                const Divider(height: 24),
                _SummaryRow(
                  icon: Icons.grain,
                  label: 'Carbs',
                  value: '${profile?.macroTargets.carbsGrams.toInt() ?? 200}g',
                  color: AppColors.carbs,
                ),
                const Divider(height: 24),
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

        const Spacer(),
        PrimaryButton(
          text: 'Create Account & Start',
          onPressed: () => context.go(AppRoutes.auth),
        ),
        const SizedBox(height: 24),
      ],
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
