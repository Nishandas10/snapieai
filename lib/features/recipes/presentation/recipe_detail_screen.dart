import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/common_widgets.dart';

class RecipeDetailScreen extends ConsumerWidget {
  final Map<String, dynamic>? recipe;

  const RecipeDetailScreen({super.key, this.recipe});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (recipe == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Recipe not found')),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Header image
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary,
                      AppColors.primary.withValues(alpha: 0.7),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Text(
                    recipe!['image'] ?? '🍽️',
                    style: const TextStyle(fontSize: 80),
                  ),
                ),
              ),
              title: Text(
                recipe!['name'] ?? 'Recipe',
                style: const TextStyle(fontSize: 18),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Quick info
                  Row(
                    children: [
                      _InfoChip(
                        icon: Icons.local_fire_department,
                        label: '${recipe!['calories']} kcal',
                        color: AppColors.calories,
                      ),
                      const SizedBox(width: 12),
                      _InfoChip(
                        icon: Icons.access_time,
                        label: recipe!['time'] ?? '20 min',
                        color: AppColors.info,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Tags
                  if (recipe!['tags'] != null)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: (recipe!['tags'] as List).map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            tag.toString(),
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  const SizedBox(height: 24),

                  // Nutrition summary
                  const Text(
                    'Nutrition',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _NutrientItem(
                          label: 'Protein',
                          value: '25g',
                          color: AppColors.protein,
                        ),
                        _NutrientItem(
                          label: 'Carbs',
                          value: '30g',
                          color: AppColors.carbs,
                        ),
                        _NutrientItem(
                          label: 'Fat',
                          value: '15g',
                          color: AppColors.fat,
                        ),
                        _NutrientItem(
                          label: 'Fiber',
                          value: '5g',
                          color: AppColors.fiber,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Ingredients
                  const Text(
                    'Ingredients',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ..._buildIngredients(),
                  const SizedBox(height: 24),

                  // Instructions
                  const Text(
                    'Instructions',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  ..._buildInstructions(),
                  const SizedBox(height: 32),

                  // Log this meal button
                  PrimaryButton(
                    text: 'Log This Meal',
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Meal logged successfully!'),
                        ),
                      );
                      context.pop();
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildIngredients() {
    final ingredients = [
      '2 cups mixed greens',
      '150g grilled chicken breast',
      '1/2 avocado, sliced',
      '1/4 cup cherry tomatoes',
      '2 tbsp olive oil',
      '1 tbsp lemon juice',
      'Salt and pepper to taste',
    ];

    return ingredients.map((ingredient) {
      return Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.inputBackground,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check,
                size: 14,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text(ingredient)),
          ],
        ),
      );
    }).toList();
  }

  List<Widget> _buildInstructions() {
    final instructions = [
      'Wash and dry the mixed greens, then place in a large bowl.',
      'Slice the grilled chicken breast into strips.',
      'Add the chicken, sliced avocado, and cherry tomatoes to the greens.',
      'In a small bowl, whisk together olive oil and lemon juice.',
      'Drizzle the dressing over the salad and toss gently.',
      'Season with salt and pepper to taste. Serve immediately.',
    ];

    return instructions.asMap().entries.map((entry) {
      return Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '${entry.key + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                entry.value,
                style: const TextStyle(fontSize: 14, height: 1.5),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _NutrientItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _NutrientItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
