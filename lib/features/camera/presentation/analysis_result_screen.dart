import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/widgets/food_widgets.dart';
import '../../../core/models/food_item.dart';
import '../../../core/models/daily_log.dart';
import '../../../core/providers/providers.dart';
import '../../../core/services/ai_service.dart';

class AnalysisResultScreen extends ConsumerStatefulWidget {
  final String? imagePath;
  final Map<String, dynamic>? analysisData;

  const AnalysisResultScreen({super.key, this.imagePath, this.analysisData});

  @override
  ConsumerState<AnalysisResultScreen> createState() =>
      _AnalysisResultScreenState();
}

class _AnalysisResultScreenState extends ConsumerState<AnalysisResultScreen> {
  bool _isAnalyzing = true;
  List<FoodItem> _detectedFoods = [];
  String? _error;
  MealType _selectedMealType = MealType.lunch;

  @override
  void initState() {
    super.initState();
    _setDefaultMealType();
    _analyzeImage();
  }

  void _setDefaultMealType() {
    final hour = DateTime.now().hour;
    if (hour < 11) {
      _selectedMealType = MealType.breakfast;
    } else if (hour < 15) {
      _selectedMealType = MealType.lunch;
    } else if (hour < 20) {
      _selectedMealType = MealType.dinner;
    } else {
      _selectedMealType = MealType.snack;
    }
  }

  Future<void> _analyzeImage() async {
    if (widget.imagePath == null) {
      setState(() {
        _isAnalyzing = false;
        _error = 'No image provided';
      });
      return;
    }

    try {
      final aiService = ref.read(aiServiceProvider);
      final foods = await aiService.analyzeFoodImage(widget.imagePath!);

      setState(() {
        _detectedFoods = foods;
        _isAnalyzing = false;
      });
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _logFood() async {
    if (_detectedFoods.isEmpty) return;

    await ref
        .read(foodLogProvider.notifier)
        .addMultipleFoodsToMeal(_selectedMealType, _detectedFoods);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Added ${_detectedFoods.length} item(s) to ${_selectedMealType.displayName}!',
          ),
          backgroundColor: AppColors.success,
        ),
      );

      // Navigate to food detail page for the first logged food
      final food = _detectedFoods.first;
      context.pop();
      context.push(
        '${AppRoutes.foodDetail}/${food.id}',
        extra: {'food': food, 'mealType': _selectedMealType},
      );
    }
  }

  void _removeFood(int index) {
    setState(() {
      _detectedFoods.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analysis Result'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: _isAnalyzing
          ? _buildLoadingView()
          : _error != null
          ? _buildErrorView()
          : _buildResultView(),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.imagePath != null)
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                image: DecorationImage(
                  image: FileImage(File(widget.imagePath!)),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          const SizedBox(height: 32),
          const CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          const SizedBox(height: 24),
          const Text(
            'Analyzing your food...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'AI is detecting food items and\ncalculating nutrition',
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 64, color: AppColors.error),
            const SizedBox(height: 24),
            const Text(
              'Analysis Failed',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Unknown error occurred',
              style: const TextStyle(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            PrimaryButton(
              text: 'Try Again',
              onPressed: () {
                setState(() {
                  _isAnalyzing = true;
                  _error = null;
                });
                _analyzeImage();
              },
            ),
            const SizedBox(height: 16),
            SecondaryButton(
              text: 'Enter Manually',
              onPressed: () {
                context.pop();
                context.push(AppRoutes.addFood);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultView() {
    final totalCalories = _detectedFoods.fold<double>(
      0,
      (sum, food) => sum + food.calories,
    );
    final totalProtein = _detectedFoods.fold<double>(
      0,
      (sum, food) => sum + food.protein,
    );
    final totalCarbs = _detectedFoods.fold<double>(
      0,
      (sum, food) => sum + food.carbs,
    );
    final totalFat = _detectedFoods.fold<double>(
      0,
      (sum, food) => sum + food.fat,
    );

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Image preview
              if (widget.imagePath != null)
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    image: DecorationImage(
                      image: FileImage(File(widget.imagePath!)),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              const SizedBox(height: 20),

              // Summary card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        '${totalCalories.toInt()} kcal',
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: AppColors.calories,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _MacroSummary(
                            label: 'Protein',
                            value: totalProtein,
                            color: AppColors.protein,
                          ),
                          _MacroSummary(
                            label: 'Carbs',
                            value: totalCarbs,
                            color: AppColors.carbs,
                          ),
                          _MacroSummary(
                            label: 'Fat',
                            value: totalFat,
                            color: AppColors.fat,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Meal type selector
              const Text(
                'Add to',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: MealType.values.map((type) {
                  final isSelected = _selectedMealType == type;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedMealType = type),
                      child: Container(
                        margin: EdgeInsets.only(
                          right: type != MealType.snack ? 8 : 0,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.inputBackground,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Text(
                              type.emoji,
                              style: const TextStyle(fontSize: 18),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              type.displayName.substring(0, 3),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: isSelected
                                    ? Colors.white
                                    : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Detected foods
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Detected Items (${_detectedFoods.length})',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      context.pop();
                      context.push(AppRoutes.camera);
                    },
                    icon: const Icon(Icons.camera_alt, size: 18),
                    label: const Text('Take Again'),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (_detectedFoods.isEmpty)
                const EmptyState(
                  title: 'No food detected',
                  subtitle: 'Try taking another photo or add food manually',
                  icon: Icons.search_off,
                )
              else
                ...List.generate(_detectedFoods.length, (index) {
                  final food = _detectedFoods[index];
                  return FoodItemCard(
                    food: food,
                    showConfidence: true,
                    showHealthFlags: true,
                    onDelete: () => _removeFood(index),
                  );
                }),
            ],
          ),
        ),

        // Bottom action
        if (_detectedFoods.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SafeArea(
              child: PrimaryButton(
                text: 'Log ${_detectedFoods.length} Item(s)',
                onPressed: _logFood,
              ),
            ),
          ),
      ],
    );
  }
}

class _MacroSummary extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _MacroSummary({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '${value.toInt()}g',
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
