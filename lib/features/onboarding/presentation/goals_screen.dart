import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/providers/user_provider.dart';

class GoalsScreen extends ConsumerStatefulWidget {
  const GoalsScreen({super.key});

  @override
  ConsumerState<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends ConsumerState<GoalsScreen> {
  String _selectedGoal = '';

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
      'value': 'athletic_performance',
      'label': 'Athletic Performance',
      'emoji': '🏃',
      'description': 'Optimize nutrition for sports',
    },
    {
      'value': 'medical_nutrition',
      'label': 'Medical Nutrition',
      'emoji': '🏥',
      'description': 'Guided nutrition for health conditions',
    },
  ];

  Future<void> _continue() async {
    if (_selectedGoal.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a goal')));
      return;
    }

    await ref
        .read(userProfileProvider.notifier)
        .updateProfile(goal: _selectedGoal);

    if (mounted) {
      context.go(AppRoutes.healthConditions);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Goal'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.profileSetup),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'What\'s your main goal?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'We\'ll customize your experience based on this',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 32),
              Expanded(
                child: ListView.separated(
                  itemCount: _goals.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final goal = _goals[index];
                    return _GoalTile(
                      label: goal['label'],
                      description: goal['description'],
                      emoji: goal['emoji'],
                      isSelected: _selectedGoal == goal['value'],
                      onTap: () =>
                          setState(() => _selectedGoal = goal['value']),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              PrimaryButton(text: 'Continue', onPressed: _continue),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoalTile extends StatelessWidget {
  final String label;
  final String description;
  final String emoji;
  final bool isSelected;
  final VoidCallback onTap;

  const _GoalTile({
    required this.label,
    required this.description,
    required this.emoji,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppColors.primary,
                size: 28,
              ),
          ],
        ),
      ),
    );
  }
}
