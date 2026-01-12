import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/models/food_item.dart';

class FoodDetailScreen extends ConsumerStatefulWidget {
  final String foodId;

  const FoodDetailScreen({super.key, required this.foodId});

  @override
  ConsumerState<FoodDetailScreen> createState() => _FoodDetailScreenState();
}

class _FoodDetailScreenState extends ConsumerState<FoodDetailScreen> {
  // Mock food for demo - in real app, fetch from provider
  late FoodItem food;
  bool _isEditing = false;

  final _nameController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Mock data
    food = FoodItem(
      id: widget.foodId,
      name: 'Chicken Biryani',
      calories: 420,
      protein: 22,
      carbs: 45,
      fat: 18,
      fiber: 4,
      sodiumMg: 980,
      cholesterolMg: 85,
      glycemicIndex: 72,
      confidence: 0.87,
      healthFlags: ['high_sodium', 'high_gi'],
      aiExplanation:
          'Estimated based on typical restaurant portion of chicken biryani with rice, spices, and vegetables.',
    );

    _nameController.text = food.name;
    _caloriesController.text = food.calories.toString();
    _proteinController.text = food.protein.toString();
    _carbsController.text = food.carbs.toString();
    _fatController.text = food.fat.toString();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Food' : 'Food Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            onPressed: () => setState(() => _isEditing = !_isEditing),
            icon: Icon(_isEditing ? Icons.close : Icons.edit),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Confidence badge
          if (!_isEditing) ...[
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _getConfidenceColor(
                      food.confidence,
                    ).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        size: 16,
                        color: _getConfidenceColor(food.confidence),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${(food.confidence * 100).toInt()}% AI Confidence',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: _getConfidenceColor(food.confidence),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],

          // Food name
          if (_isEditing)
            CustomTextField(controller: _nameController, label: 'Food Name')
          else
            Text(
              food.name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          const SizedBox(height: 8),
          Text(
            '${food.servingSize.toInt()} ${food.servingUnit}',
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 24),

          // Calorie card
          Card(
            color: AppColors.calories.withValues(alpha: 0.1),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_isEditing)
                    SizedBox(
                      width: 100,
                      child: TextField(
                        controller: _caloriesController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: AppColors.calories,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                        ),
                      ),
                    )
                  else
                    Text(
                      food.calories.toInt().toString(),
                      style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: AppColors.calories,
                      ),
                    ),
                  const SizedBox(width: 8),
                  const Text(
                    'kcal',
                    style: TextStyle(fontSize: 18, color: AppColors.calories),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Macros
          Row(
            children: [
              Expanded(
                child: _MacroCard(
                  label: 'Protein',
                  value: _isEditing ? _proteinController : null,
                  displayValue: food.protein,
                  color: AppColors.protein,
                  isEditing: _isEditing,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MacroCard(
                  label: 'Carbs',
                  value: _isEditing ? _carbsController : null,
                  displayValue: food.carbs,
                  color: AppColors.carbs,
                  isEditing: _isEditing,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MacroCard(
                  label: 'Fat',
                  value: _isEditing ? _fatController : null,
                  displayValue: food.fat,
                  color: AppColors.fat,
                  isEditing: _isEditing,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Health flags
          if (food.healthFlags.isNotEmpty && !_isEditing) ...[
            const Text(
              'Health Alerts',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            ...food.healthFlags.map((flag) => _HealthFlagCard(flag: flag)),
            const SizedBox(height: 24),
          ],

          // AI Explanation
          if (food.aiExplanation != null && !_isEditing) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 18,
                          color: AppColors.info,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Why AI estimated this',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.info,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      food.aiExplanation!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Action buttons
          if (_isEditing)
            PrimaryButton(
              text: 'Save Changes',
              onPressed: () {
                // Save changes
                setState(() => _isEditing = false);
              },
            )
          else
            SecondaryButton(
              text: 'Was this accurate?',
              icon: Icons.feedback_outlined,
              onPressed: () {
                // Feedback flow
              },
            ),
        ],
      ),
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.9) return AppColors.success;
    if (confidence >= 0.7) return AppColors.warning;
    return AppColors.error;
  }
}

class _MacroCard extends StatelessWidget {
  final String label;
  final TextEditingController? value;
  final double displayValue;
  final Color color;
  final bool isEditing;

  const _MacroCard({
    required this.label,
    this.value,
    required this.displayValue,
    required this.color,
    required this.isEditing,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (isEditing && value != null)
              TextField(
                controller: value,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                ),
              )
            else
              Text(
                '${displayValue.toInt()}g',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HealthFlagCard extends StatelessWidget {
  final String flag;

  const _HealthFlagCard({required this.flag});

  @override
  Widget build(BuildContext context) {
    final (icon, label, description, color) = _getFlagInfo(flag);

    return Card(
      color: color.withValues(alpha: 0.1),
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 12,
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

  (String, String, String, Color) _getFlagInfo(String flag) {
    switch (flag) {
      case 'high_sodium':
        return (
          '🧂',
          'High Sodium',
          'Contains 980mg sodium - consider for BP management',
          AppColors.error,
        );
      case 'high_gi':
        return (
          '📈',
          'High Glycemic Index',
          'GI of 72 may affect blood sugar levels',
          AppColors.warning,
        );
      case 'high_sugar':
        return ('🍬', 'High Sugar', 'Contains added sugars', AppColors.warning);
      default:
        return ('ℹ️', flag, '', AppColors.info);
    }
  }
}
