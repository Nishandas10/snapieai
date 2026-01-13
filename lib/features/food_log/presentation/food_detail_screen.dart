import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/models/food_item.dart';
import '../../../core/models/daily_log.dart';
import '../../../core/providers/providers.dart';

class FoodDetailScreen extends ConsumerStatefulWidget {
  final String foodId;
  final FoodItem? food;
  final MealType? mealType;

  const FoodDetailScreen({
    super.key,
    required this.foodId,
    this.food,
    this.mealType,
  });

  @override
  ConsumerState<FoodDetailScreen> createState() => _FoodDetailScreenState();
}

class _FoodDetailScreenState extends ConsumerState<FoodDetailScreen> {
  late FoodItem _food;
  bool _isEditing = false;
  bool _hasChanges = false;

  // Basic info controllers
  final _nameController = TextEditingController();
  final _servingSizeController = TextEditingController();
  final _servingUnitController = TextEditingController();

  // Macros controllers
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController();
  final _carbsController = TextEditingController();
  final _fatController = TextEditingController();
  final _fiberController = TextEditingController();

  // Micronutrients controllers
  final _sodiumController = TextEditingController();
  final _cholesterolController = TextEditingController();
  final _saturatedFatController = TextEditingController();
  final _sugarController = TextEditingController();
  final _potassiumController = TextEditingController();
  final _glycemicIndexController = TextEditingController();
  final _glycemicLoadController = TextEditingController();

  // Additional micronutrients controllers
  final _ironController = TextEditingController();
  final _calciumController = TextEditingController();
  final _vitaminAController = TextEditingController();
  final _vitaminCController = TextEditingController();

  // Notes controller
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeFood();
  }

  void _initializeFood() {
    // Use the passed food data, or create a placeholder if not available
    _food =
        widget.food ??
        FoodItem(
          id: widget.foodId,
          name: 'Unknown Food',
          calories: 0,
          protein: 0,
          carbs: 0,
          fat: 0,
        );

    _populateControllers();
  }

  void _populateControllers() {
    _nameController.text = _food.name;
    _servingSizeController.text = _food.servingSize.toString();
    _servingUnitController.text = _food.servingUnit;

    _caloriesController.text = _food.calories.toStringAsFixed(0);
    _proteinController.text = _food.protein.toStringAsFixed(1);
    _carbsController.text = _food.carbs.toStringAsFixed(1);
    _fatController.text = _food.fat.toStringAsFixed(1);
    _fiberController.text = _food.fiber.toStringAsFixed(1);

    _sodiumController.text = (_food.sodiumMg ?? 0).toStringAsFixed(0);
    _cholesterolController.text = (_food.cholesterolMg ?? 0).toStringAsFixed(0);
    _saturatedFatController.text = (_food.saturatedFatGrams ?? 0)
        .toStringAsFixed(1);
    _sugarController.text = (_food.sugarGrams ?? 0).toStringAsFixed(1);
    _potassiumController.text = (_food.potassiumMg ?? 0).toStringAsFixed(0);
    _glycemicIndexController.text = (_food.glycemicIndex ?? 0).toString();
    _glycemicLoadController.text = (_food.glycemicLoad ?? 0).toString();

    // Additional micronutrients
    _ironController.text = (_food.ironMg ?? 0).toStringAsFixed(1);
    _calciumController.text = (_food.calciumMg ?? 0).toStringAsFixed(0);
    _vitaminAController.text = (_food.vitaminAPercent ?? 0).toStringAsFixed(0);
    _vitaminCController.text = (_food.vitaminCPercent ?? 0).toStringAsFixed(0);

    _notesController.text = _food.notes ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _servingSizeController.dispose();
    _servingUnitController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    _fiberController.dispose();
    _sodiumController.dispose();
    _cholesterolController.dispose();
    _saturatedFatController.dispose();
    _sugarController.dispose();
    _potassiumController.dispose();
    _glycemicIndexController.dispose();
    _glycemicLoadController.dispose();
    _ironController.dispose();
    _calciumController.dispose();
    _vitaminAController.dispose();
    _vitaminCController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  FoodItem _buildUpdatedFood() {
    return _food.copyWith(
      name: _nameController.text.trim(),
      servingSize: double.tryParse(_servingSizeController.text) ?? 1,
      servingUnit: _servingUnitController.text.trim(),
      calories: double.tryParse(_caloriesController.text) ?? 0,
      protein: double.tryParse(_proteinController.text) ?? 0,
      carbs: double.tryParse(_carbsController.text) ?? 0,
      fat: double.tryParse(_fatController.text) ?? 0,
      fiber: double.tryParse(_fiberController.text) ?? 0,
      sodiumMg: double.tryParse(_sodiumController.text),
      cholesterolMg: double.tryParse(_cholesterolController.text),
      saturatedFatGrams: double.tryParse(_saturatedFatController.text),
      sugarGrams: double.tryParse(_sugarController.text),
      potassiumMg: double.tryParse(_potassiumController.text),
      glycemicIndex: int.tryParse(_glycemicIndexController.text),
      glycemicLoad: int.tryParse(_glycemicLoadController.text),
      ironMg: double.tryParse(_ironController.text),
      calciumMg: double.tryParse(_calciumController.text),
      vitaminAPercent: double.tryParse(_vitaminAController.text),
      vitaminCPercent: double.tryParse(_vitaminCController.text),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      isManuallyEdited: true,
    );
  }

  Future<void> _saveChanges() async {
    final updatedFood = _buildUpdatedFood();

    if (widget.mealType != null) {
      await ref
          .read(foodLogProvider.notifier)
          .updateFood(widget.mealType!, updatedFood);
    }

    setState(() {
      _food = updatedFood;
      _isEditing = false;
      _hasChanges = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Food updated successfully'),
          backgroundColor: AppColors.success,
        ),
      );
    }
  }

  void _cancelEditing() {
    _populateControllers();
    setState(() {
      _isEditing = false;
      _hasChanges = false;
    });
  }

  void _showGlycemicInfoDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.info_outline, color: AppColors.info),
            SizedBox(width: 8),
            Text('Glycemic Information'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildInfoSection(
                '📊 Glycemic Index (GI)',
                'Measures how quickly a food raises blood sugar levels on a scale of 0-100.',
              ),
              const SizedBox(height: 12),
              _buildGITable(),
              const SizedBox(height: 16),
              _buildInfoSection(
                '📈 Glycemic Load (GL)',
                'Takes into account both the GI and the carbohydrate content per serving, giving a more accurate picture of blood sugar impact.',
              ),
              const SizedBox(height: 12),
              _buildGLTable(),
              const SizedBox(height: 16),
              _buildInfoSection(
                '🩸 Impact on Blood Sugar',
                'High GI/GL foods cause rapid spikes in blood sugar, followed by crashes. This can lead to:\n'
                    '• Increased hunger and cravings\n'
                    '• Energy fluctuations\n'
                    '• Insulin resistance over time\n'
                    '• Higher risk for type 2 diabetes',
              ),
              const SizedBox(height: 16),
              _buildInfoSection(
                '🥗 Tips for Blood Sugar Management',
                '• Choose low GI foods (vegetables, legumes, whole grains)\n'
                    '• Pair carbs with protein and healthy fats\n'
                    '• Eat fiber-rich foods to slow digestion\n'
                    '• Avoid processed and sugary foods\n'
                    '• Control portion sizes to lower GL\n'
                    '• Consider foods like oats, lentils, and leafy greens',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          content,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.textSecondary,
            height: 1.4,
          ),
        ),
      ],
    );
  }

  Widget _buildGITable() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _buildTableRow('Low GI', '0-55', AppColors.success, '✓ Best choice'),
          const SizedBox(height: 8),
          _buildTableRow('Medium GI', '56-69', AppColors.warning, '⚠ Moderate'),
          const SizedBox(height: 8),
          _buildTableRow(
            'High GI',
            '70-100',
            AppColors.error,
            '✗ Limit intake',
          ),
        ],
      ),
    );
  }

  Widget _buildGLTable() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.inputBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _buildTableRow('Low GL', '0-10', AppColors.success, '✓ Best choice'),
          const SizedBox(height: 8),
          _buildTableRow('Medium GL', '11-19', AppColors.warning, '⚠ Moderate'),
          const SizedBox(height: 8),
          _buildTableRow('High GL', '20+', AppColors.error, '✗ Limit intake'),
        ],
      ),
    );
  }

  Widget _buildTableRow(String label, String range, Color color, String note) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          flex: 1,
          child: Text(
            range,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: Text(
            note,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Food' : 'Food Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (_hasChanges) {
              _showDiscardDialog();
            } else {
              context.pop();
            }
          },
        ),
        actions: [
          if (!_isEditing)
            IconButton(
              onPressed: () => setState(() => _isEditing = true),
              icon: const Icon(Icons.edit),
              tooltip: 'Edit',
            )
          else ...[
            IconButton(
              onPressed: _cancelEditing,
              icon: const Icon(Icons.close),
              tooltip: 'Cancel',
            ),
            IconButton(
              onPressed: _saveChanges,
              icon: const Icon(Icons.check),
              tooltip: 'Save',
            ),
          ],
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Confidence badge
          if (!_isEditing && _food.confidence < 1.0) ...[
            _ConfidenceBadge(confidence: _food.confidence),
            const SizedBox(height: 16),
          ],

          // Food name
          if (_isEditing)
            _EditableField(
              controller: _nameController,
              label: 'Food Name',
              onChanged: (_) => setState(() => _hasChanges = true),
            )
          else
            Text(
              _food.name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          const SizedBox(height: 8),

          // Serving size
          if (_isEditing)
            Row(
              children: [
                Expanded(
                  child: _EditableField(
                    controller: _servingSizeController,
                    label: 'Serving Size',
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() => _hasChanges = true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _EditableField(
                    controller: _servingUnitController,
                    label: 'Unit',
                    onChanged: (_) => setState(() => _hasChanges = true),
                  ),
                ),
              ],
            )
          else
            Text(
              '${_food.servingSize} ${_food.servingUnit}',
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
          const SizedBox(height: 24),

          // Calorie card
          _CalorieCard(
            calories: _food.calories,
            controller: _caloriesController,
            isEditing: _isEditing,
            onChanged: (_) => setState(() => _hasChanges = true),
          ),
          const SizedBox(height: 20),

          // Macros section
          const _SectionHeader(title: 'Macronutrients'),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _NutrientCard(
                  label: 'Protein',
                  value: _food.protein,
                  unit: 'g',
                  color: AppColors.protein,
                  controller: _proteinController,
                  isEditing: _isEditing,
                  onChanged: (_) => setState(() => _hasChanges = true),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _NutrientCard(
                  label: 'Carbs',
                  value: _food.carbs,
                  unit: 'g',
                  color: AppColors.carbs,
                  controller: _carbsController,
                  isEditing: _isEditing,
                  onChanged: (_) => setState(() => _hasChanges = true),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _NutrientCard(
                  label: 'Fat',
                  value: _food.fat,
                  unit: 'g',
                  color: AppColors.fat,
                  controller: _fatController,
                  isEditing: _isEditing,
                  onChanged: (_) => setState(() => _hasChanges = true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _NutrientCard(
                  label: 'Fiber',
                  value: _food.fiber,
                  unit: 'g',
                  color: AppColors.success,
                  controller: _fiberController,
                  isEditing: _isEditing,
                  onChanged: (_) => setState(() => _hasChanges = true),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _NutrientCard(
                  label: 'Sugar',
                  value: _food.sugarGrams ?? 0,
                  unit: 'g',
                  color: AppColors.warning,
                  controller: _sugarController,
                  isEditing: _isEditing,
                  onChanged: (_) => setState(() => _hasChanges = true),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _NutrientCard(
                  label: 'Sat. Fat',
                  value: _food.saturatedFatGrams ?? 0,
                  unit: 'g',
                  color: AppColors.fat.withValues(alpha: 0.7),
                  controller: _saturatedFatController,
                  isEditing: _isEditing,
                  onChanged: (_) => setState(() => _hasChanges = true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Micronutrients section
          const _SectionHeader(title: 'Micronutrients'),
          const SizedBox(height: 12),
          _MicronutrientRow(
            label: 'Sodium',
            value: _food.sodiumMg ?? 0,
            unit: 'mg',
            controller: _sodiumController,
            isEditing: _isEditing,
            onChanged: (_) => setState(() => _hasChanges = true),
            warning: _food.isHighSodium ? 'High sodium' : null,
          ),
          _MicronutrientRow(
            label: 'Cholesterol',
            value: _food.cholesterolMg ?? 0,
            unit: 'mg',
            controller: _cholesterolController,
            isEditing: _isEditing,
            onChanged: (_) => setState(() => _hasChanges = true),
            warning: _food.isHighCholesterol ? 'High cholesterol' : null,
          ),
          _MicronutrientRow(
            label: 'Potassium',
            value: _food.potassiumMg ?? 0,
            unit: 'mg',
            controller: _potassiumController,
            isEditing: _isEditing,
            onChanged: (_) => setState(() => _hasChanges = true),
          ),
          _MicronutrientRow(
            label: 'Iron',
            value: _food.ironMg ?? 0,
            unit: 'mg',
            controller: _ironController,
            isEditing: _isEditing,
            onChanged: (_) => setState(() => _hasChanges = true),
          ),
          _MicronutrientRow(
            label: 'Calcium',
            value: _food.calciumMg ?? 0,
            unit: 'mg',
            controller: _calciumController,
            isEditing: _isEditing,
            onChanged: (_) => setState(() => _hasChanges = true),
          ),
          const SizedBox(height: 24),

          // Vitamins section
          const _SectionHeader(title: 'Vitamins'),
          const SizedBox(height: 12),
          _MicronutrientRow(
            label: 'Vitamin A',
            value: _food.vitaminAPercent ?? 0,
            unit: '% DV',
            controller: _vitaminAController,
            isEditing: _isEditing,
            onChanged: (_) => setState(() => _hasChanges = true),
          ),
          _MicronutrientRow(
            label: 'Vitamin C',
            value: _food.vitaminCPercent ?? 0,
            unit: '% DV',
            controller: _vitaminCController,
            isEditing: _isEditing,
            onChanged: (_) => setState(() => _hasChanges = true),
          ),
          const SizedBox(height: 24),

          // Health Score section
          if (_food.healthScore != null) ...[
            const _SectionHeader(title: 'Health Score'),
            const SizedBox(height: 12),
            _HealthScoreCard(score: _food.healthScore!),
            const SizedBox(height: 24),
          ],

          // Glycemic info section
          _SectionHeader(
            title: 'Glycemic Information',
            onInfoTap: _showGlycemicInfoDialog,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _GlycemicCard(
                  label: 'Glycemic Index',
                  value: _food.glycemicIndex ?? 0,
                  controller: _glycemicIndexController,
                  isEditing: _isEditing,
                  onChanged: (_) => setState(() => _hasChanges = true),
                  isHighGI: _food.isHighGI,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _GlycemicCard(
                  label: 'Glycemic Load',
                  value: _food.glycemicLoad ?? 0,
                  controller: _glycemicLoadController,
                  isEditing: _isEditing,
                  onChanged: (_) => setState(() => _hasChanges = true),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Health flags
          if (_food.healthFlags.isNotEmpty && !_isEditing) ...[
            const _SectionHeader(title: 'Health Alerts'),
            const SizedBox(height: 12),
            ..._food.healthFlags.map((flag) => _HealthFlagCard(flag: flag)),
            const SizedBox(height: 24),
          ],

          // AI Explanation
          if (_food.aiExplanation != null && !_isEditing) ...[
            _AIExplanationCard(explanation: _food.aiExplanation!),
            const SizedBox(height: 24),
          ],

          // Notes section
          const _SectionHeader(title: 'Notes'),
          const SizedBox(height: 12),
          if (_isEditing)
            _EditableField(
              controller: _notesController,
              label: 'Add notes about this food',
              maxLines: 3,
              onChanged: (_) => setState(() => _hasChanges = true),
            )
          else if (_food.notes != null && _food.notes!.isNotEmpty)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  _food.notes!,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            )
          else
            const Text(
              'No notes added',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
          const SizedBox(height: 24),

          // Action buttons
          if (_isEditing)
            PrimaryButton(text: 'Save Changes', onPressed: _saveChanges)
          else
            SecondaryButton(
              text: 'Edit Nutrition Values',
              icon: Icons.edit_outlined,
              onPressed: () => setState(() => _isEditing = true),
            ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  void _showDiscardDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard changes?'),
        content: const Text(
          'You have unsaved changes. Are you sure you want to discard them?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              this.context.pop();
            },
            child: const Text('Discard'),
          ),
        ],
      ),
    );
  }
}

class _ConfidenceBadge extends StatelessWidget {
  final double confidence;

  const _ConfidenceBadge({required this.confidence});

  Color get _color {
    if (confidence >= 0.9) return AppColors.success;
    if (confidence >= 0.7) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.auto_awesome, size: 16, color: _color),
              const SizedBox(width: 6),
              Text(
                '${(confidence * 100).toInt()}% AI Confidence',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _color,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onInfoTap;

  const _SectionHeader({required this.title, this.onInfoTap});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        if (onInfoTap != null) ...[
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onInfoTap,
            child: Icon(
              Icons.info_outline,
              size: 18,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}

class _EditableField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final int maxLines;
  final ValueChanged<String>? onChanged;

  const _EditableField({
    required this.controller,
    required this.label,
    this.keyboardType,
    this.maxLines = 1,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
}

class _CalorieCard extends StatelessWidget {
  final double calories;
  final TextEditingController controller;
  final bool isEditing;
  final ValueChanged<String>? onChanged;

  const _CalorieCard({
    required this.calories,
    required this.controller,
    required this.isEditing,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.calories.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isEditing)
              SizedBox(
                width: 120,
                child: TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  onChanged: onChanged,
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: AppColors.calories,
                  ),
                  decoration: const InputDecoration(border: InputBorder.none),
                ),
              )
            else
              Text(
                calories.toInt().toString(),
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
    );
  }
}

class _NutrientCard extends StatelessWidget {
  final String label;
  final double value;
  final String unit;
  final Color color;
  final TextEditingController controller;
  final bool isEditing;
  final ValueChanged<String>? onChanged;

  const _NutrientCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    required this.controller,
    required this.isEditing,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            if (isEditing)
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                onChanged: onChanged,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  suffixText: unit,
                  suffixStyle: TextStyle(fontSize: 12, color: color),
                ),
              )
            else
              Text(
                '${value.toStringAsFixed(1)}$unit',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MicronutrientRow extends StatelessWidget {
  final String label;
  final double value;
  final String unit;
  final TextEditingController controller;
  final bool isEditing;
  final ValueChanged<String>? onChanged;
  final String? warning;

  const _MicronutrientRow({
    required this.label,
    required this.value,
    required this.unit,
    required this.controller,
    required this.isEditing,
    this.onChanged,
    this.warning,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          if (isEditing)
            SizedBox(
              width: 80,
              child: TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.end,
                onChanged: onChanged,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 8,
                  ),
                  suffixText: unit,
                ),
              ),
            )
          else
            Row(
              children: [
                Text(
                  '${value.toStringAsFixed(0)} $unit',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: warning != null
                        ? AppColors.warning
                        : AppColors.textPrimary,
                  ),
                ),
                if (warning != null) ...[
                  const SizedBox(width: 8),
                  Icon(
                    Icons.warning_amber_rounded,
                    size: 16,
                    color: AppColors.warning,
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _GlycemicCard extends StatelessWidget {
  final String label;
  final int value;
  final TextEditingController controller;
  final bool isEditing;
  final ValueChanged<String>? onChanged;
  final bool isHighGI;

  const _GlycemicCard({
    required this.label,
    required this.value,
    required this.controller,
    required this.isEditing,
    this.onChanged,
    this.isHighGI = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isHighGI ? AppColors.warning : AppColors.success;

    return Card(
      color: color.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (isEditing)
              TextField(
                controller: controller,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                onChanged: onChanged,
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
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    value.toString(),
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  if (isHighGI) ...[
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_upward, size: 16, color: color),
                  ],
                ],
              ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
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
                  if (description.isNotEmpty)
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
          'Consider for blood pressure management',
          AppColors.error,
        );
      case 'high_gi':
        return (
          '📈',
          'High Glycemic Index',
          'May affect blood sugar levels',
          AppColors.warning,
        );
      case 'high_sugar':
        return ('🍬', 'High Sugar', 'Contains added sugars', AppColors.warning);
      case 'high_cholesterol':
        return (
          '❤️',
          'High Cholesterol',
          'Consider for heart health',
          AppColors.error,
        );
      case 'low_protein':
        return (
          '💪',
          'Low Protein',
          'Consider adding protein sources',
          AppColors.info,
        );
      case 'high_fiber':
        return (
          '🌾',
          'High Fiber',
          'Great for digestive health',
          AppColors.success,
        );
      default:
        return (
          'ℹ️',
          flag.replaceAll('_', ' ').toUpperCase(),
          '',
          AppColors.info,
        );
    }
  }
}

class _AIExplanationCard extends StatelessWidget {
  final String explanation;

  const _AIExplanationCard({required this.explanation});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, size: 18, color: AppColors.info),
                const SizedBox(width: 8),
                const Text(
                  'AI Analysis',
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
              explanation,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HealthScoreCard extends StatelessWidget {
  final double score;

  const _HealthScoreCard({required this.score});

  @override
  Widget build(BuildContext context) {
    // Score is on a 1-10 scale
    final normalizedScore = score.clamp(0.0, 10.0);
    final color = _getScoreColor(normalizedScore);
    final label = _getScoreLabel(normalizedScore);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color.withValues(alpha: 0.15),
                    border: Border.all(color: color, width: 3),
                  ),
                  child: Center(
                    child: Text(
                      normalizedScore.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getScoreDescription(normalizedScore),
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: normalizedScore / 10,
                backgroundColor: AppColors.inputBackground,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 8,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getScoreColor(double score) {
    // 1-3: Poor (Red), 4-6: Average (Warning/Orange), 7-8: Good (Primary/Green), 9-10: Excellent (Success/Bright Green)
    if (score >= 9) return AppColors.success;
    if (score >= 7) return AppColors.primary;
    if (score >= 4) return AppColors.warning;
    return AppColors.error;
  }

  String _getScoreLabel(double score) {
    if (score >= 9) return 'Excellent';
    if (score >= 7) return 'Good';
    if (score >= 4) return 'Average';
    return 'Poor';
  }

  String _getScoreDescription(double score) {
    if (score >= 9) return 'This food has excellent nutritional value';
    if (score >= 7) return 'This food has good nutritional value';
    if (score >= 4) return 'This food has average nutritional value';
    return 'Consider healthier alternatives';
  }
}
