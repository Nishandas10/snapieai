import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/providers/user_provider.dart';
import '../../../core/models/user_profile.dart';

class GoalsTargetsScreen extends ConsumerStatefulWidget {
  const GoalsTargetsScreen({super.key});

  @override
  ConsumerState<GoalsTargetsScreen> createState() => _GoalsTargetsScreenState();
}

class _GoalsTargetsScreenState extends ConsumerState<GoalsTargetsScreen> {
  String _selectedGoal = '';
  double _dailyCalories = 2000;
  double _proteinGrams = 150;
  double _carbsGrams = 200;
  double _fatGrams = 65;
  bool _isLoading = false;

  final List<Map<String, dynamic>> _goals = [
    {
      'value': 'lose_fat',
      'label': 'Lose Fat',
      'emoji': '🔥',
      'description': 'Reduce body fat while preserving muscle',
    },
    {
      'value': 'gain_muscle',
      'label': 'Gain Muscle',
      'emoji': '💪',
      'description': 'Build lean muscle mass',
    },
    {
      'value': 'maintain',
      'label': 'Maintain Weight',
      'emoji': '⚖️',
      'description': 'Keep your current weight stable',
    },
    {
      'value': 'improve_health',
      'label': 'Improve Health',
      'emoji': '❤️',
      'description': 'Focus on overall wellness',
    },
    {
      'value': 'gain_weight',
      'label': 'Gain Weight',
      'emoji': '📈',
      'description': 'Healthy weight gain',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrentValues();
  }

  void _loadCurrentValues() {
    final profile = ref.read(userProfileProvider);
    if (profile != null) {
      _selectedGoal = profile.goal;
      _dailyCalories = profile.dailyCalorieTarget;
      _proteinGrams = profile.macroTargets.proteinGrams;
      _carbsGrams = profile.macroTargets.carbsGrams;
      _fatGrams = profile.macroTargets.fatGrams;
    }
  }

  Future<void> _saveGoals() async {
    if (_selectedGoal.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a goal')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref
          .read(userProfileProvider.notifier)
          .updateProfile(
            goal: _selectedGoal,
            dailyCalorieTarget: _dailyCalories,
            macroTargets: MacroTargets(
              proteinGrams: _proteinGrams,
              carbsGrams: _carbsGrams,
              fatGrams: _fatGrams,
            ),
          );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Goals updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error updating goals: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Goals & Targets'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _saveGoals,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Goals Section
          const Text(
            'Your Goal',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ..._goals.map(
            (goal) => _GoalTile(
              emoji: goal['emoji'],
              label: goal['label'],
              description: goal['description'],
              isSelected: _selectedGoal == goal['value'],
              onTap: () => setState(() => _selectedGoal = goal['value']),
            ),
          ),
          const SizedBox(height: 24),

          // Daily Calories
          const Text(
            'Daily Calorie Target',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildCalorieSlider(),
          const SizedBox(height: 24),

          // Macros Section
          const Text(
            'Macro Targets',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Customize your daily macronutrient goals',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 16),
          _buildMacroInput(
            'Protein',
            _proteinGrams,
            Icons.egg_outlined,
            AppColors.primary,
            (value) => setState(() => _proteinGrams = value),
          ),
          const SizedBox(height: 12),
          _buildMacroInput(
            'Carbs',
            _carbsGrams,
            Icons.grain,
            AppColors.secondary,
            (value) => setState(() => _carbsGrams = value),
          ),
          const SizedBox(height: 12),
          _buildMacroInput(
            'Fats',
            _fatGrams,
            Icons.water_drop,
            AppColors.accent,
            (value) => setState(() => _fatGrams = value),
          ),
          const SizedBox(height: 16),

          // Macro summary
          _buildMacroSummary(),
        ],
      ),
    );
  }

  Widget _buildCalorieSlider() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(
            '${_dailyCalories.toInt()}',
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
          const Text(
            'calories/day',
            style: TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          Slider(
            value: _dailyCalories,
            min: 1200,
            max: 4000,
            divisions: 56,
            activeColor: AppColors.primary,
            onChanged: (value) => setState(() => _dailyCalories = value),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '1200',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
              Text(
                '4000',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacroInput(
    String label,
    double value,
    IconData icon,
    Color color,
    ValueChanged<double> onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                Text(
                  '${value.toInt()}g',
                  style: TextStyle(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                onPressed: () => onChanged((value - 5).clamp(0, 500)),
                icon: const Icon(Icons.remove_circle_outline),
                color: AppColors.textSecondary,
              ),
              SizedBox(
                width: 50,
                child: Text(
                  '${value.toInt()}g',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              IconButton(
                onPressed: () => onChanged((value + 5).clamp(0, 500)),
                icon: const Icon(Icons.add_circle_outline),
                color: color,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMacroSummary() {
    final totalCalories =
        (_proteinGrams * 4) + (_carbsGrams * 4) + (_fatGrams * 9);
    final proteinPercent = ((_proteinGrams * 4) / totalCalories * 100);
    final carbsPercent = ((_carbsGrams * 4) / totalCalories * 100);
    final fatPercent = ((_fatGrams * 9) / totalCalories * 100);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.pie_chart, color: AppColors.info, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Macro Breakdown',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _MacroChip(
                'Protein',
                '${proteinPercent.toStringAsFixed(0)}%',
                AppColors.primary,
              ),
              _MacroChip(
                'Carbs',
                '${carbsPercent.toStringAsFixed(0)}%',
                AppColors.secondary,
              ),
              _MacroChip(
                'Fats',
                '${fatPercent.toStringAsFixed(0)}%',
                AppColors.accent,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Total: ${totalCalories.toInt()} kcal',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalTile extends StatelessWidget {
  final String emoji;
  final String label;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  const _GoalTile({
    required this.emoji,
    required this.label,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

class _MacroChip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MacroChip(this.label, this.value, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.bold, color: color),
        ),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
