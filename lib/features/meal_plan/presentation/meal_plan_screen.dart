import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/providers/providers.dart';
import '../../../core/services/ai_service.dart';
import '../../../core/models/meal_plan.dart';

class MealPlanScreen extends ConsumerStatefulWidget {
  const MealPlanScreen({super.key});

  @override
  ConsumerState<MealPlanScreen> createState() => _MealPlanScreenState();
}

class _MealPlanScreenState extends ConsumerState<MealPlanScreen> {
  int _selectedDayIndex = 0;
  bool _isGenerating = false;
  WeeklyMealPlan? _weeklyPlan;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meal Plan'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _generatePlan),
        ],
      ),
      body: _weeklyPlan == null ? _buildEmptyState() : _buildMealPlanView(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.calendar_month,
                size: 64,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Generate Your Meal Plan',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            const Text(
              'Get a personalized weekly meal plan based on your goals, preferences, and health conditions.',
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            PrimaryButton(
              text: _isGenerating ? 'Generating...' : 'Generate Meal Plan',
              onPressed: _isGenerating ? null : _generatePlan,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _generatePlan() async {
    setState(() => _isGenerating = true);

    try {
      final aiService = ref.read(aiServiceProvider);
      final user = ref.read(userProfileProvider);

      if (user == null) {
        throw Exception('Please complete your profile first');
      }

      final plan = await aiService.generateMealPlan(user);

      setState(() {
        _weeklyPlan = plan;
        _isGenerating = false;
      });
    } catch (e) {
      setState(() => _isGenerating = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error generating plan: $e')));
      }
    }
  }

  Widget _buildMealPlanView() {
    final days = _weeklyPlan!.days;

    return Column(
      children: [
        // Day selector
        Container(
          height: 90,
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: days.length,
            itemBuilder: (context, index) {
              final day = days[index];
              final isSelected = index == _selectedDayIndex;
              return GestureDetector(
                onTap: () => setState(() => _selectedDayIndex = index),
                child: Container(
                  width: 60,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.divider,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat('EEE').format(day.date),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isSelected
                              ? Colors.white70
                              : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        DateFormat('d').format(day.date),
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isSelected
                              ? Colors.white
                              : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        // Meal plan for selected day
        Expanded(
          child: _selectedDayIndex < days.length
              ? _buildDayPlan(days[_selectedDayIndex])
              : const Center(child: Text('No plan for this day')),
        ),
      ],
    );
  }

  Widget _buildDayPlan(DayPlan dayPlan) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Summary card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.primary,
                AppColors.primary.withValues(alpha: 0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _SummaryItem(
                label: 'Calories',
                value: '${dayPlan.totalCalories.toInt()}',
                unit: 'kcal',
              ),
              _SummaryItem(
                label: 'Protein',
                value: '${dayPlan.totalProtein.toInt()}',
                unit: 'g',
              ),
              _SummaryItem(
                label: 'Carbs',
                value: '${dayPlan.totalCarbs.toInt()}',
                unit: 'g',
              ),
              _SummaryItem(
                label: 'Fat',
                value: '${dayPlan.totalFat.toInt()}',
                unit: 'g',
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Meals
        ...dayPlan.meals.map((meal) => _MealCard(meal: meal)),
      ],
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final String value;
  final String unit;

  const _SummaryItem({
    required this.label,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          unit,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}

class _MealCard extends StatelessWidget {
  final PlannedMeal meal;

  const _MealCard({required this.meal});

  IconData _getMealIcon(String mealType) {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return Icons.wb_sunny;
      case 'lunch':
        return Icons.wb_cloudy;
      case 'dinner':
        return Icons.nightlight_round;
      case 'snack':
        return Icons.cookie;
      default:
        return Icons.restaurant;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Meal header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    _getMealIcon(meal.mealType),
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meal.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${meal.totalCalories.toInt()} kcal • ${meal.prepTimeMinutes} min',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Meal foods
          ...meal.foods.map((food) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.divider)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          food.name,
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                        Text(
                          '${food.servingSize} ${food.servingUnit}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${food.calories.toInt()} kcal',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
