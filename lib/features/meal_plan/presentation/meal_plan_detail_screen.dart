import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';

class MealPlanDetailScreen extends ConsumerWidget {
  final String day;

  const MealPlanDetailScreen({super.key, required this.day});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Sample meals for the day
    final meals = _getMealsForDay();

    return Scaffold(
      appBar: AppBar(
        title: Text(_formatDay(day)),
        actions: [
          IconButton(
            onPressed: () => _regeneratePlan(context),
            icon: const Icon(Icons.refresh),
            tooltip: 'Regenerate',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Day summary
          _buildDaySummary(context),
          const SizedBox(height: 24),

          // Meals list
          ...meals.map((meal) => _buildMealCard(context, meal)),

          const SizedBox(height: 16),

          // Total nutrition
          _buildNutritionSummary(context, meals),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addMeal(context),
        icon: const Icon(Icons.add),
        label: const Text('Add Meal'),
      ),
    );
  }

  String _formatDay(String day) {
    // Format day string (e.g., "monday" -> "Monday")
    if (day.isEmpty) return 'Today';
    return day[0].toUpperCase() + day.substring(1);
  }

  List<Map<String, dynamic>> _getMealsForDay() {
    return [
      {
        'type': 'Breakfast',
        'name': 'Oatmeal with Berries',
        'time': '8:00 AM',
        'calories': 350,
        'protein': 12,
        'carbs': 55,
        'fat': 8,
        'icon': Icons.free_breakfast,
        'color': Colors.orange,
      },
      {
        'type': 'Snack',
        'name': 'Greek Yogurt',
        'time': '10:30 AM',
        'calories': 150,
        'protein': 15,
        'carbs': 12,
        'fat': 5,
        'icon': Icons.icecream,
        'color': Colors.pink,
      },
      {
        'type': 'Lunch',
        'name': 'Grilled Chicken Salad',
        'time': '1:00 PM',
        'calories': 450,
        'protein': 35,
        'carbs': 25,
        'fat': 18,
        'icon': Icons.lunch_dining,
        'color': Colors.green,
      },
      {
        'type': 'Snack',
        'name': 'Mixed Nuts',
        'time': '4:00 PM',
        'calories': 200,
        'protein': 6,
        'carbs': 8,
        'fat': 18,
        'icon': Icons.spa,
        'color': Colors.brown,
      },
      {
        'type': 'Dinner',
        'name': 'Salmon with Vegetables',
        'time': '7:00 PM',
        'calories': 550,
        'protein': 40,
        'carbs': 30,
        'fat': 25,
        'icon': Icons.dinner_dining,
        'color': Colors.blue,
      },
    ];
  }

  Widget _buildDaySummary(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_today, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                _formatDay(day),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            '5 Meals Planned',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildQuickStat('1700', 'kcal'),
              const SizedBox(width: 24),
              _buildQuickStat('108g', 'Protein'),
              const SizedBox(width: 24),
              _buildQuickStat('130g', 'Carbs'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat(String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white60, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildMealCard(BuildContext context, Map<String, dynamic> meal) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _viewMealDetails(context, meal),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: (meal['color'] as Color).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    meal['icon'] as IconData,
                    color: meal['color'] as Color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: (meal['color'] as Color).withValues(
                                alpha: 0.1,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              meal['type'] as String,
                              style: TextStyle(
                                color: meal['color'] as Color,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            meal['time'] as String,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        meal['name'] as String,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildMacroChip(
                            '${meal['calories']} kcal',
                            AppColors.primary,
                          ),
                          const SizedBox(width: 8),
                          _buildMacroChip('${meal['protein']}g P', Colors.red),
                          const SizedBox(width: 8),
                          _buildMacroChip('${meal['carbs']}g C', Colors.orange),
                          const SizedBox(width: 8),
                          _buildMacroChip(
                            '${meal['fat']}g F',
                            Colors.yellow.shade700,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMacroChip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildNutritionSummary(
    BuildContext context,
    List<Map<String, dynamic>> meals,
  ) {
    int totalCalories = 0;
    int totalProtein = 0;
    int totalCarbs = 0;
    int totalFat = 0;

    for (var meal in meals) {
      totalCalories += meal['calories'] as int;
      totalProtein += meal['protein'] as int;
      totalCarbs += meal['carbs'] as int;
      totalFat += meal['fat'] as int;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Daily Total',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNutrientColumn(
                'Calories',
                '$totalCalories',
                'kcal',
                AppColors.primary,
              ),
              _buildNutrientColumn('Protein', '$totalProtein', 'g', Colors.red),
              _buildNutrientColumn('Carbs', '$totalCarbs', 'g', Colors.orange),
              _buildNutrientColumn(
                'Fat',
                '$totalFat',
                'g',
                Colors.yellow.shade700,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNutrientColumn(
    String label,
    String value,
    String unit,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
        ),
      ],
    );
  }

  void _regeneratePlan(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Regenerate Plan'),
        content: const Text(
          'This will create a new meal plan for this day. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Regenerating meal plan...')),
              );
            },
            child: const Text('Regenerate'),
          ),
        ],
      ),
    );
  }

  void _addMeal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Add Meal',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    children: [
                      _buildAddMealOption(
                        context,
                        Icons.search,
                        'Search Food',
                        'Find from database',
                        () => Navigator.pop(context),
                      ),
                      _buildAddMealOption(
                        context,
                        Icons.camera_alt,
                        'Scan Food',
                        'Use camera to identify',
                        () => Navigator.pop(context),
                      ),
                      _buildAddMealOption(
                        context,
                        Icons.restaurant,
                        'Generate Recipe',
                        'AI-powered recipe suggestion',
                        () => Navigator.pop(context),
                      ),
                      _buildAddMealOption(
                        context,
                        Icons.edit,
                        'Manual Entry',
                        'Enter nutrition manually',
                        () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildAddMealOption(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppColors.primary),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }

  void _viewMealDetails(BuildContext context, Map<String, dynamic> meal) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: (meal['color'] as Color).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    meal['icon'] as IconData,
                    color: meal['color'] as Color,
                    size: 30,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meal['name'] as String,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${meal['type']} • ${meal['time']}',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'Nutrition Information',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            _buildNutritionRow('Calories', '${meal['calories']} kcal'),
            _buildNutritionRow('Protein', '${meal['protein']} g'),
            _buildNutritionRow('Carbohydrates', '${meal['carbs']} g'),
            _buildNutritionRow('Fat', '${meal['fat']} g'),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      // Edit functionality
                    },
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      // Log functionality
                    },
                    icon: const Icon(Icons.check),
                    label: const Text('Log Meal'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildNutritionRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: AppColors.textSecondary)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
