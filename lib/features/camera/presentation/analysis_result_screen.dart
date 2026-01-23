import 'dart:io';

import 'package:flutter/foundation.dart';
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
import '../../health_score/presentation/health_score_modal.dart';

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
  FoodItem? _detectedFood;
  String? _error;
  MealType _selectedMealType = MealType.lunch;
  bool _hasLoggedFood = false;

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
      final food = await aiService.analyzeFoodImage(widget.imagePath!);

      // Add image path to food item
      final foodWithImage = food.copyWith(imagePath: widget.imagePath);

      setState(() {
        _detectedFood = foodWithImage;
        _isAnalyzing = false;
      });

      // Immediately save to Firestore in the background after analysis completes
      _saveToFirestoreInBackground(foodWithImage);
    } catch (e) {
      setState(() {
        _isAnalyzing = false;
        _error = e.toString();
      });
    }
  }

  /// Save food to Firestore immediately in background (non-blocking)
  Future<void> _saveToFirestoreInBackground(FoodItem food) async {
    if (_hasLoggedFood) return; // Already saved
    try {
      await ref
          .read(foodLogProvider.notifier)
          .addFoodToMeal(_selectedMealType, food);
      _hasLoggedFood = true;
    } catch (e) {
      // Silently fail - will retry when user clicks log button
      debugPrint('Background save failed: $e');
    }
  }

  void _navigateToFoodDetail() {
    if (_detectedFood == null) return;

    // If background save failed, try one more time (non-blocking)
    if (!_hasLoggedFood) {
      _saveToFirestoreInBackground(_detectedFood!);
    }

    // Trigger health score recalculation
    ref.read(healthScoreProvider.notifier).recalculateScore();

    final itemCount = _detectedFood!.subItems?.length ?? 1;

    // Show success message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Added meal with $itemCount item(s) to ${_selectedMealType.displayName}!',
          ),
          backgroundColor: AppColors.success,
        ),
      );

      // Show health score modal, then navigate to food detail
      showHealthScoreModal(
        context,
        onViewDetails: () {
          context.push(AppRoutes.healthScoreDetail);
        },
      ).then((_) {
        if (mounted) {
          context.pop();
          context.push(
            '${AppRoutes.foodDetail}/${_detectedFood!.id}',
            extra: {
              'food': _detectedFood,
              'mealType': _selectedMealType,
              'imagePath': widget.imagePath,
            },
          );
        }
      });
    }
  }

  void _handleBackNavigation() {
    if (_detectedFood == null || _error != null) {
      context.pop();
      return;
    }

    // If background save failed, try one more time (non-blocking)
    if (!_hasLoggedFood) {
      _saveToFirestoreInBackground(_detectedFood!);
    }

    // Trigger health score recalculation
    ref.read(healthScoreProvider.notifier).recalculateScore();

    final itemCount = _detectedFood!.subItems?.length ?? 1;

    // Foods already saved in background, show health score modal
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Saved meal with $itemCount item(s) to ${_selectedMealType.displayName}!',
          ),
          backgroundColor: AppColors.success,
        ),
      );

      // Show health score modal, then navigate to food detail
      showHealthScoreModal(
        context,
        onViewDetails: () {
          context.push(AppRoutes.healthScoreDetail);
        },
      ).then((_) {
        if (mounted) {
          context.pop();
          context.push(
            '${AppRoutes.foodDetail}/${_detectedFood!.id}',
            extra: {
              'food': _detectedFood,
              'mealType': _selectedMealType,
              'imagePath': widget.imagePath,
            },
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        _handleBackNavigation();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Analysis Result'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _handleBackNavigation,
          ),
        ),
        body: _isAnalyzing
            ? _buildLoadingView()
            : _error != null
            ? _buildErrorView()
            : _buildResultView(),
      ),
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
          const AnalysisStepLoader(isImageAnalysis: true),
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
    if (_detectedFood == null) {
      return const EmptyState(
        title: 'No food detected',
        subtitle: 'Try taking another photo or add food manually',
        icon: Icons.search_off,
      );
    }

    final food = _detectedFood!;
    final subItems = food.subItems ?? [];
    final itemCount = subItems.isNotEmpty ? subItems.length : 1;

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

              // Combined meal name
              Text(
                food.name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Summary card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        '${food.calories.toInt()} kcal',
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
                            value: food.protein,
                            color: AppColors.protein,
                          ),
                          _MacroSummary(
                            label: 'Carbs',
                            value: food.carbs,
                            color: AppColors.carbs,
                          ),
                          _MacroSummary(
                            label: 'Fat',
                            value: food.fat,
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

              // Individual items breakdown (if multiple items)
              if (subItems.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Individual Items ($itemCount)',
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
                ...subItems.map((item) => _buildSubItemCard(item)),
              ] else ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
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
              ],
            ],
          ),
        ),

        // Bottom action
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
              text: 'Log Meal ($itemCount item${itemCount > 1 ? 's' : ''})',
              onPressed: _navigateToFoodDetail,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubItemCard(FoodItem item) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${item.servingSize.toInt()}${item.servingUnit}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${item.calories.toInt()} kcal',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.calories,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'P:${item.protein.toInt()}g  C:${item.carbs.toInt()}g  F:${item.fat.toInt()}g',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
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
