import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/providers.dart';
import '../../../core/widgets/nutrition_widgets.dart';
import '../../../core/models/daily_log.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    final foodLogState = ref.watch(foodLogProvider);
    final todayLog = foodLogState.todayLog;
    final macros = ref.watch(todayMacrosProvider);

    final calorieTarget = profile?.dailyCalorieTarget ?? 2000;
    final proteinTarget = profile?.macroTargets.proteinGrams ?? 150;
    final carbsTarget = profile?.macroTargets.carbsGrams ?? 200;
    final fatTarget = profile?.macroTargets.fatGrams ?? 65;

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getGreeting(),
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              profile?.name ?? 'Friend',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            IconButton(
                              onPressed: () => context.push(AppRoutes.chat),
                              icon: const Icon(Icons.chat_bubble_outline),
                              color: AppColors.primary,
                            ),
                            GestureDetector(
                              onTap: () => context.go(AppRoutes.settings),
                              child: CircleAvatar(
                                backgroundColor: AppColors.primary.withValues(
                                  alpha: 0.1,
                                ),
                                child: Text(
                                  (profile?.name?.isNotEmpty ?? false)
                                      ? profile!.name![0].toUpperCase()
                                      : '👋',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      DateFormat('EEEE, MMMM d').format(DateTime.now()),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Macro Summary Card
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: MacroSummaryCard(
                  calories: macros['calories'] ?? 0,
                  calorieTarget: calorieTarget,
                  protein: macros['protein'] ?? 0,
                  proteinTarget: proteinTarget,
                  carbs: macros['carbs'] ?? 0,
                  carbsTarget: carbsTarget,
                  fat: macros['fat'] ?? 0,
                  fatTarget: fatTarget,
                ),
              ),
            ),

            // Quick Actions
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _QuickActionCard(
                            icon: Icons.camera_alt,
                            label: 'Scan Food',
                            color: AppColors.primary,
                            onTap: () => context.push(AppRoutes.camera),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _QuickActionCard(
                            icon: Icons.edit_note,
                            label: 'Log Manually',
                            color: AppColors.secondary,
                            onTap: () => context.push(AppRoutes.addFood),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _QuickActionCard(
                            icon: Icons.auto_awesome,
                            label: 'Ask Sara',
                            color: AppColors.accent,
                            onTap: () => context.push(AppRoutes.chat),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Today's Meals
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Today\'s Meals',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        TextButton(
                          onPressed: () => context.go(AppRoutes.foodLog),
                          child: const Text('See All'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Meal cards
            SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final mealType = MealType.values[index];
                final meal = todayLog?.getMeal(mealType);
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 6,
                  ),
                  child: _MealCard(
                    mealType: mealType,
                    meal: meal,
                    onTap: () => context.go(AppRoutes.foodLog, extra: index),
                    onAdd: () => context.push(AppRoutes.addFood),
                  ),
                );
              }, childCount: 4),
            ),

            // Health tips section
            if (profile?.healthConditions.isNotEmpty ?? false)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: _HealthTipCard(conditions: profile!.healthConditions),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _MealCard extends StatelessWidget {
  final MealType mealType;
  final Meal? meal;
  final VoidCallback onTap;
  final VoidCallback onAdd;

  const _MealCard({
    required this.mealType,
    this.meal,
    required this.onTap,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final hasFoods = meal != null && meal!.foods.isNotEmpty;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    mealType.emoji,
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mealType.displayName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      hasFoods
                          ? '${meal!.foodCount} items • ${meal!.totalCalories.toInt()} kcal'
                          : 'No items logged',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: onAdd,
                icon: const Icon(Icons.add_circle_outline),
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HealthTipCard extends StatelessWidget {
  final List<String> conditions;

  const _HealthTipCard({required this.conditions});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.info.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.info.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.lightbulb_outline,
                color: AppColors.info,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Health Tip',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.info,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getTip(),
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTip() {
    if (conditions.contains('high_blood_pressure')) {
      return 'Keep sodium under 1500mg for optimal BP management.';
    }
    if (conditions.contains('type2_diabetes') ||
        conditions.contains('type1_diabetes')) {
      return 'Focus on low GI foods to maintain stable blood sugar.';
    }
    if (conditions.contains('pcos')) {
      return 'Include anti-inflammatory foods and maintain protein balance.';
    }
    return 'Stay hydrated and aim for balanced meals throughout the day.';
  }
}
