import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/providers/providers.dart';
import '../../../core/widgets/food_widgets.dart';
import '../../../core/widgets/nutrition_widgets.dart';
import '../../../core/models/daily_log.dart';
import '../../../core/models/food_item.dart';

class FoodLogScreen extends ConsumerStatefulWidget {
  final int initialTabIndex;

  const FoodLogScreen({super.key, this.initialTabIndex = 0});

  @override
  ConsumerState<FoodLogScreen> createState() => _FoodLogScreenState();
}

class _FoodLogScreenState extends ConsumerState<FoodLogScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 3),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _onDateChanged(DateTime date) {
    ref.read(foodLogProvider.notifier).selectDate(date);
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider);
    final foodLogState = ref.watch(foodLogProvider);
    final selectedDate = foodLogState.selectedDate;
    final currentLog = foodLogState.currentLog;

    final calorieTarget = profile?.dailyCalorieTarget ?? 2000;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Food Log'),
        actions: [
          IconButton(
            onPressed: () => context.push(AppRoutes.history),
            icon: const Icon(Icons.calendar_month),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: _DateSelector(
            selectedDate: selectedDate,
            onDateChanged: _onDateChanged,
          ),
        ),
      ),
      body: Column(
        children: [
          // Calorie summary
          Container(
            padding: const EdgeInsets.all(20),
            color: AppColors.surface,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _CalorieStat(
                  label: 'Eaten',
                  value: currentLog?.totalCalories.toInt() ?? 0,
                  color: AppColors.primary,
                ),
                NutritionProgress(
                  current: currentLog?.totalCalories ?? 0,
                  target: calorieTarget,
                  label: 'Remaining',
                  unit: 'kcal',
                  color: AppColors.calories,
                  size: 90,
                  lineWidth: 8,
                ),
                _CalorieStat(
                  label: 'Goal',
                  value: calorieTarget.toInt(),
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),

          // Meal tabs
          TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            tabs: MealType.values.map((type) {
              return Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(type.emoji),
                    const SizedBox(width: 4),
                    Text(type.displayName.substring(0, 3)),
                  ],
                ),
              );
            }).toList(),
          ),

          // Meal content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: MealType.values.map((type) {
                return _MealTabContent(
                  mealType: type,
                  meal: currentLog?.getMeal(type),
                  onAddFood: () => _addFood(type),
                  onDeleteFood: (foodId) => _deleteFood(type, foodId),
                  onTapFood: (food) => _viewFoodDetails(type, food),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  void _addFood(MealType mealType) {
    context.push(AppRoutes.addFood, extra: {'mealType': mealType});
  }

  void _deleteFood(MealType mealType, String foodId) {
    final selectedDate = ref.read(foodLogProvider).selectedDate;
    ref
        .read(foodLogProvider.notifier)
        .removeFoodFromMeal(mealType, foodId, date: selectedDate);
  }

  void _viewFoodDetails(MealType mealType, FoodItem food) {
    context.push(
      '${AppRoutes.foodDetail}/${food.id}',
      extra: {'food': food, 'mealType': mealType},
    );
  }
}

class _DateSelector extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChanged;

  const _DateSelector({
    required this.selectedDate,
    required this.onDateChanged,
  });

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final dates = List.generate(
      7,
      (i) => today.subtract(Duration(days: 6 - i)),
    );

    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: dates.length,
        itemBuilder: (context, index) {
          final date = dates[index];
          final isSelected = _isSameDay(date, selectedDate);
          final isToday = _isSameDay(date, today);

          return GestureDetector(
            onTap: () => onDateChanged(date),
            child: Container(
              width: 48,
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected
                      ? AppColors.primary
                      : (isToday ? AppColors.accent : AppColors.border),
                  width: isToday && !isSelected ? 2 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    DateFormat('E').format(date).substring(0, 1),
                    style: TextStyle(
                      fontSize: 10,
                      color: isSelected
                          ? Colors.white
                          : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    date.day.toString(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _CalorieStat extends StatelessWidget {
  final String label;
  final int value;
  final Color color;

  const _CalorieStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}

class _MealTabContent extends StatelessWidget {
  final MealType mealType;
  final Meal? meal;
  final VoidCallback onAddFood;
  final Function(String) onDeleteFood;
  final Function(FoodItem) onTapFood;

  const _MealTabContent({
    required this.mealType,
    this.meal,
    required this.onAddFood,
    required this.onDeleteFood,
    required this.onTapFood,
  });

  @override
  Widget build(BuildContext context) {
    if (meal == null || meal!.foods.isEmpty) {
      return EmptyState(
        title: 'No ${mealType.displayName} logged',
        subtitle: 'Tap the button below to add food',
        icon: Icons.restaurant_outlined,
        actionLabel: 'Add Food',
        onAction: onAddFood,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: meal!.foods.length + 1,
      itemBuilder: (context, index) {
        if (index == meal!.foods.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: OutlinedButton.icon(
              onPressed: onAddFood,
              icon: const Icon(Icons.add),
              label: const Text('Add More'),
            ),
          );
        }

        final food = meal!.foods[index];
        return FoodItemCard(
          food: food,
          onTap: () => onTapFood(food),
          onDelete: () => onDeleteFood(food.id),
          showHealthFlags: true,
        );
      },
    );
  }
}
