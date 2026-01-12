import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/providers/providers.dart';
import '../../../core/models/food_item.dart';
import '../../../core/models/daily_log.dart';
import '../../../core/services/ai_service.dart';

class AddFoodScreen extends ConsumerStatefulWidget {
  const AddFoodScreen({super.key});

  @override
  ConsumerState<AddFoodScreen> createState() => _AddFoodScreenState();
}

class _AddFoodScreenState extends ConsumerState<AddFoodScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();
  final _servingSizeController = TextEditingController(text: '1');
  final _servingUnitController = TextEditingController(text: 'serving');

  MealType _selectedMealType = MealType.lunch;
  bool _isLoading = false;
  bool _isAIMode = true;

  @override
  void dispose() {
    _descriptionController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _servingSizeController.dispose();
    _servingUnitController.dispose();
    super.dispose();
  }

  Future<void> _analyzeWithAI() async {
    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please describe your food')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final aiService = ref.read(aiServiceProvider);
      final foods = await aiService.analyzeFoodText(
        _descriptionController.text,
      );

      if (foods.isNotEmpty) {
        await ref
            .read(foodLogProvider.notifier)
            .addMultipleFoodsToMeal(_selectedMealType, foods);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Added ${foods.length} item(s) successfully!'),
            ),
          );
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _addManually() async {
    if (!_formKey.currentState!.validate()) return;

    final food = FoodItem(
      id: const Uuid().v4(),
      name: _descriptionController.text.trim(),
      calories: double.tryParse(_caloriesController.text) ?? 0,
      protein: double.tryParse(_proteinController.text) ?? 0,
      carbs: double.tryParse(_carbsController.text) ?? 0,
      fat: double.tryParse(_fatController.text) ?? 0,
      servingSize: double.tryParse(_servingSizeController.text) ?? 1,
      servingUnit: _servingUnitController.text,
      isManuallyEdited: true,
    );

    await ref
        .read(foodLogProvider.notifier)
        .addFoodToMeal(_selectedMealType, food);

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Food added successfully!')));
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Food'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: LoadingOverlay(
        isLoading: _isLoading,
        message: 'Analyzing food...',
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Mode toggle
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Row(
                    children: [
                      Expanded(
                        child: _ModeButton(
                          label: 'AI Analysis',
                          icon: Icons.auto_awesome,
                          isSelected: _isAIMode,
                          onTap: () => setState(() => _isAIMode = true),
                        ),
                      ),
                      Expanded(
                        child: _ModeButton(
                          label: 'Manual Entry',
                          icon: Icons.edit,
                          isSelected: !_isAIMode,
                          onTap: () => setState(() => _isAIMode = false),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

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
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : AppColors.border,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              type.emoji,
                              style: const TextStyle(fontSize: 20),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              type.displayName.substring(0, 3),
                              style: TextStyle(
                                fontSize: 11,
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
              const SizedBox(height: 24),

              // Food description
              CustomTextField(
                controller: _descriptionController,
                label: _isAIMode ? 'Describe your food' : 'Food name',
                hint: _isAIMode
                    ? 'e.g., 2 scrambled eggs with toast and butter'
                    : 'e.g., Scrambled Eggs',
                maxLines: _isAIMode ? 3 : 1,
                prefixIcon: Icon(
                  _isAIMode ? Icons.auto_awesome : Icons.restaurant,
                ),
              ),

              if (_isAIMode) ...[
                const SizedBox(height: 12),
                Text(
                  'Tip: Be specific about portions for better accuracy',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textHint,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],

              if (!_isAIMode) ...[
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: _caloriesController,
                        label: 'Calories',
                        hint: '0',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomTextField(
                        controller: _proteinController,
                        label: 'Protein (g)',
                        hint: '0',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: _carbsController,
                        label: 'Carbs (g)',
                        hint: '0',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomTextField(
                        controller: _fatController,
                        label: 'Fat (g)',
                        hint: '0',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        controller: _servingSizeController,
                        label: 'Serving Size',
                        hint: '1',
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: CustomTextField(
                        controller: _servingUnitController,
                        label: 'Unit',
                        hint: 'serving',
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 32),

              PrimaryButton(
                text: _isAIMode ? 'Analyze with AI' : 'Add Food',
                icon: _isAIMode ? Icons.auto_awesome : Icons.add,
                onPressed: _isAIMode ? _analyzeWithAI : _addManually,
                isLoading: _isLoading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
