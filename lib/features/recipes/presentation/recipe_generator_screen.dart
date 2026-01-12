import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/providers/providers.dart';
import '../../../core/services/ai_service.dart';

class RecipeGeneratorScreen extends ConsumerStatefulWidget {
  const RecipeGeneratorScreen({super.key});

  @override
  ConsumerState<RecipeGeneratorScreen> createState() =>
      _RecipeGeneratorScreenState();
}

class _RecipeGeneratorScreenState extends ConsumerState<RecipeGeneratorScreen> {
  final TextEditingController _ingredientController = TextEditingController();
  final List<String> _ingredients = [];
  String _mealType = 'lunch';
  int _maxCalories = 500;
  bool _isGenerating = false;
  Map<String, dynamic>? _generatedRecipe;

  @override
  void dispose() {
    _ingredientController.dispose();
    super.dispose();
  }

  void _addIngredient() {
    final ingredient = _ingredientController.text.trim();
    if (ingredient.isNotEmpty && !_ingredients.contains(ingredient)) {
      setState(() {
        _ingredients.add(ingredient);
        _ingredientController.clear();
      });
    }
  }

  Future<void> _generateRecipe() async {
    if (_ingredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one ingredient')),
      );
      return;
    }

    setState(() => _isGenerating = true);

    try {
      final aiService = ref.read(aiServiceProvider);
      final user = ref.read(userProfileProvider);

      final recipe = await aiService.generateRecipe(
        _ingredients,
        profile: user,
        mealType: _mealType,
        maxCalories: _maxCalories,
      );

      setState(() {
        _generatedRecipe = {
          'name': recipe.name,
          'image': '🍽️',
          'calories': recipe.caloriesPerServing.toInt(),
          'time': '${recipe.prepTimeMinutes + recipe.cookTimeMinutes} min',
          'ingredients': recipe.ingredients.map((i) => i.name).toList(),
          'instructions': recipe.instructions,
          'tags': recipe.tags,
        };
        _isGenerating = false;
      });
    } catch (e) {
      setState(() => _isGenerating = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error generating recipe: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Recipe Generator'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _generatedRecipe != null
          ? _buildGeneratedRecipe()
          : _buildInputForm(),
    );
  }

  Widget _buildInputForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
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
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.auto_awesome,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'AI Recipe Generator',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Tell me what ingredients you have',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Add ingredient input
          const Text(
            'Your Ingredients',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ingredientController,
                  decoration: InputDecoration(
                    hintText: 'Add an ingredient...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: AppColors.inputBackground,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  onSubmitted: (_) => _addIngredient(),
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: _addIngredient,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.add, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Ingredients list
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _ingredients.map((ingredient) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      ingredient,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () =>
                          setState(() => _ingredients.remove(ingredient)),
                      child: const Icon(
                        Icons.close,
                        size: 16,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Meal type
          const Text(
            'Meal Type',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: ['breakfast', 'lunch', 'dinner', 'snack'].map((type) {
              final isSelected = _mealType == type;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _mealType = type),
                  child: Container(
                    margin: EdgeInsets.only(right: type != 'snack' ? 8 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.inputBackground,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      type[0].toUpperCase() + type.substring(1),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Max calories
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Maximum Calories',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                '$_maxCalories kcal',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Slider(
            value: _maxCalories.toDouble(),
            min: 200,
            max: 1000,
            divisions: 16,
            activeColor: AppColors.primary,
            onChanged: (value) => setState(() => _maxCalories = value.toInt()),
          ),
          const SizedBox(height: 32),

          // Generate button
          PrimaryButton(
            text: _isGenerating ? 'Generating...' : 'Generate Recipe',
            onPressed: _isGenerating ? null : _generateRecipe,
          ),
        ],
      ),
    );
  }

  Widget _buildGeneratedRecipe() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recipe header
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
            child: Column(
              children: [
                Text(
                  _generatedRecipe!['image'] ?? '🍽️',
                  style: const TextStyle(fontSize: 60),
                ),
                const SizedBox(height: 16),
                Text(
                  _generatedRecipe!['name'] ?? 'Generated Recipe',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.local_fire_department,
                      color: Colors.white70,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${_generatedRecipe!['calories']} kcal',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(width: 16),
                    const Icon(
                      Icons.access_time,
                      color: Colors.white70,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _generatedRecipe!['time'] ?? '20 min',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Instructions
          const Text(
            'Instructions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (_generatedRecipe!['instructions'] != null)
            ...(_generatedRecipe!['instructions'] as List).asMap().entries.map((
              entry,
            ) {
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
                        entry.value.toString(),
                        style: const TextStyle(fontSize: 14, height: 1.5),
                      ),
                    ),
                  ],
                ),
              );
            }),
          const SizedBox(height: 24),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: SecondaryButton(
                  text: 'New Recipe',
                  icon: Icons.refresh,
                  onPressed: () {
                    setState(() => _generatedRecipe = null);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PrimaryButton(
                  text: 'Save Recipe',
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Recipe saved!')),
                    );
                    context.pop();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
