import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/providers/providers.dart';
import '../../../core/models/food_item.dart';
import '../../../core/models/daily_log.dart';
import '../../../core/services/ai_service.dart';
import '../../../core/services/subscription_service.dart';

class AddFoodScreen extends ConsumerStatefulWidget {
  final MealType? initialMealType;

  const AddFoodScreen({super.key, this.initialMealType});

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

  late MealType _selectedMealType;
  bool _isLoading = false;
  bool _isAIMode = true;

  @override
  void initState() {
    super.initState();
    _selectedMealType = widget.initialMealType ?? MealType.lunch;
  }

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

  Future<void> _showPaywall() async {
    final result = await context.push<bool>(
      AppRoutes.paywall,
      extra: {'featureType': 'ai_text'},
    );

    if (result == true) {
      // User purchased, refresh subscription state
      await ref.read(subscriptionProvider.notifier).refresh();
    }
  }

  Future<void> _analyzeWithAI() async {
    if (_descriptionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please describe your food')),
      );
      return;
    }

    // Check subscription before AI analysis
    final subscription = ref.read(subscriptionProvider);
    if (!subscription.canUseAIScan) {
      await _showPaywall();
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Record usage before analysis
      await ref.read(subscriptionProvider.notifier).recordAIScanUsage();

      final aiService = ref.read(aiServiceProvider);
      final food = await aiService.analyzeFoodText(_descriptionController.text);

      await ref
          .read(foodLogProvider.notifier)
          .addFoodToMeal(_selectedMealType, food);

      final itemCount = food.subItems?.length ?? 1;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added meal with $itemCount item(s) successfully!'),
          ),
        );

        // Navigate to food detail page for the logged food
        context.pop();
        context.push(
          '${AppRoutes.foodDetail}/${food.id}',
          extra: {'food': food, 'mealType': _selectedMealType},
        );
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
              if (_isAIMode)
                CustomTextField(
                  controller: _descriptionController,
                  label: 'Describe your food',
                  hint: 'e.g., 2 scrambled eggs with toast and butter',
                  maxLines: 3,
                  suffixIcon: Container(
                    margin: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      onPressed: _isLoading ? null : _analyzeWithAI,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Icon(Icons.arrow_upward, color: Colors.white),
                      padding: const EdgeInsets.all(8),
                      constraints: const BoxConstraints(
                        minWidth: 40,
                        minHeight: 40,
                      ),
                    ),
                  ),
                )
              else
                CustomTextField(
                  controller: _descriptionController,
                  label: 'Food name',
                  hint: 'e.g., Scrambled Eggs',
                  maxLines: 1,
                  prefixIcon: const Icon(Icons.restaurant),
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
                const SizedBox(height: 16),
                // Camera scan option
                OutlinedButton.icon(
                  onPressed: () {
                    context.push(
                      AppRoutes.camera,
                      extra: {'mealType': _selectedMealType},
                    );
                  },
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Or scan with camera'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(
                      color: AppColors.primary.withValues(alpha: 0.5),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                // More Actions Section
                const SizedBox(height: 32),
                const Text(
                  'More Actions',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _ActionCard(
                        icon: Icons.qr_code_scanner,
                        label: 'Scan Barcode',
                        color: AppColors.secondary,
                        onTap: () => context.push(
                          AppRoutes.barcodeScanner,
                          extra: {'mealType': _selectedMealType},
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionCard(
                        icon: Icons.mic,
                        label: 'Voice Log',
                        color: AppColors.accent,
                        onTap: () => context.push(
                          AppRoutes.voiceInput,
                          extra: {'mealType': _selectedMealType},
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _ActionCard(
                        icon: Icons.auto_awesome,
                        label: 'Ask Sara',
                        color: AppColors.primary,
                        onTap: () => context.push(AppRoutes.chat),
                      ),
                    ),
                  ],
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

              if (!_isAIMode) ...[
                const SizedBox(height: 32),
                PrimaryButton(
                  text: 'Add Food',
                  icon: Icons.add,
                  onPressed: _addManually,
                  isLoading: _isLoading,
                ),
              ],
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

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 28, color: color),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
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
