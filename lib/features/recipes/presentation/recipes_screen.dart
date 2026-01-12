import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/food_widgets.dart';

class RecipesScreen extends ConsumerStatefulWidget {
  const RecipesScreen({super.key});

  @override
  ConsumerState<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends ConsumerState<RecipesScreen> {
  String _selectedCategory = 'All';
  final List<String> _categories = [
    'All',
    'Breakfast',
    'Lunch',
    'Dinner',
    'Snacks',
    'Healthy',
    'Quick',
    'Low Carb',
  ];

  final List<Map<String, dynamic>> _recipes = [
    {
      'name': 'Grilled Chicken Salad',
      'image': '🥗',
      'calories': 350,
      'time': '20 min',
      'category': 'Lunch',
      'tags': ['Healthy', 'High Protein'],
    },
    {
      'name': 'Avocado Toast',
      'image': '🥑',
      'calories': 280,
      'time': '10 min',
      'category': 'Breakfast',
      'tags': ['Quick', 'Healthy'],
    },
    {
      'name': 'Salmon with Vegetables',
      'image': '🐟',
      'calories': 450,
      'time': '30 min',
      'category': 'Dinner',
      'tags': ['Healthy', 'Low Carb'],
    },
    {
      'name': 'Greek Yogurt Parfait',
      'image': '🍨',
      'calories': 220,
      'time': '5 min',
      'category': 'Snacks',
      'tags': ['Quick', 'High Protein'],
    },
    {
      'name': 'Quinoa Buddha Bowl',
      'image': '🥙',
      'calories': 400,
      'time': '25 min',
      'category': 'Lunch',
      'tags': ['Healthy', 'Vegan'],
    },
    {
      'name': 'Egg White Omelette',
      'image': '🍳',
      'calories': 180,
      'time': '15 min',
      'category': 'Breakfast',
      'tags': ['Low Carb', 'High Protein'],
    },
  ];

  @override
  Widget build(BuildContext context) {
    final filteredRecipes = _selectedCategory == 'All'
        ? _recipes
        : _recipes
              .where(
                (r) =>
                    r['category'] == _selectedCategory ||
                    (r['tags'] as List).contains(_selectedCategory),
              )
              .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recipes'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome),
            onPressed: () => context.push('/recipes/generate'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Category filter
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = category == _selectedCategory;
                return GestureDetector(
                  onTap: () => setState(() => _selectedCategory = category),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.divider,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      category,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),

          // Recipes grid
          Expanded(
            child: filteredRecipes.isEmpty
                ? const EmptyState(
                    title: 'No recipes found',
                    subtitle: 'Try a different category',
                    icon: Icons.menu_book,
                  )
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.8,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                    itemCount: filteredRecipes.length,
                    itemBuilder: (context, index) {
                      return _RecipeCard(recipe: filteredRecipes[index]);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/recipes/generate'),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.auto_awesome, color: Colors.white),
        label: const Text('AI Generate', style: TextStyle(color: Colors.white)),
      ),
    );
  }
}

class _RecipeCard extends StatelessWidget {
  final Map<String, dynamic> recipe;

  const _RecipeCard({required this.recipe});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/recipes/detail', extra: recipe),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image placeholder
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Center(
                child: Text(
                  recipe['image'] ?? '🍽️',
                  style: const TextStyle(fontSize: 48),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    recipe['name'] ?? '',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.local_fire_department,
                        size: 14,
                        color: AppColors.calories,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${recipe['calories']} kcal',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.access_time,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        recipe['time'] ?? '',
                        style: const TextStyle(
                          fontSize: 12,
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
      ),
    );
  }
}
