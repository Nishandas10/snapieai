import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/providers/user_provider.dart';

class HealthConditionsScreen extends ConsumerStatefulWidget {
  const HealthConditionsScreen({super.key});

  @override
  ConsumerState<HealthConditionsScreen> createState() =>
      _HealthConditionsScreenState();
}

class _HealthConditionsScreenState
    extends ConsumerState<HealthConditionsScreen> {
  bool _hasConditions = false;
  final Set<String> _selectedConditions = {};

  final List<Map<String, dynamic>> _conditions = [
    {
      'value': 'high_blood_pressure',
      'label': 'High Blood Pressure',
      'emoji': '🩺',
      'description': 'Low sodium recommendations',
    },
    {
      'value': 'pcos',
      'label': 'PCOS',
      'emoji': '🎀',
      'description': 'Insulin-friendly meal plans',
    },
    {
      'value': 'type1_diabetes',
      'label': 'Type 1 Diabetes',
      'emoji': '💉',
      'description': 'Carb counting & GI focus',
    },
    {
      'value': 'type2_diabetes',
      'label': 'Type 2 Diabetes',
      'emoji': '📊',
      'description': 'Blood sugar management',
    },
    {
      'value': 'prediabetic',
      'label': 'Prediabetic',
      'emoji': '⚠️',
      'description': 'Prevention-focused nutrition',
    },
    {
      'value': 'high_cholesterol',
      'label': 'High Cholesterol',
      'emoji': '❤️',
      'description': 'Heart-healthy choices',
    },
    {
      'value': 'thyroid',
      'label': 'Thyroid Issues',
      'emoji': '🦋',
      'description': 'Metabolism-aware planning',
    },
    {
      'value': 'heart_health',
      'label': 'Heart Health Focus',
      'emoji': '💖',
      'description': 'Cardiovascular wellness',
    },
  ];

  void _toggleCondition(String value) {
    setState(() {
      if (_selectedConditions.contains(value)) {
        _selectedConditions.remove(value);
      } else {
        _selectedConditions.add(value);
      }
    });
  }

  Future<void> _continue() async {
    await ref
        .read(userProfileProvider.notifier)
        .updateProfile(healthConditions: _selectedConditions.toList());

    if (mounted) {
      context.go(AppRoutes.dietaryPreferences);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Conditions'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.goals),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Any health conditions?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'This helps us provide safer, more relevant recommendations',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),

              // Toggle for having conditions
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'I have health conditions',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Get personalized nutrition guidance',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _hasConditions,
                        onChanged: (value) {
                          setState(() {
                            _hasConditions = value;
                            if (!value) _selectedConditions.clear();
                          });
                        },
                        activeColor: AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              if (_hasConditions)
                Expanded(
                  child: ListView.separated(
                    itemCount: _conditions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final condition = _conditions[index];
                      final isSelected = _selectedConditions.contains(
                        condition['value'],
                      );
                      return _ConditionTile(
                        label: condition['label'],
                        description: condition['description'],
                        emoji: condition['emoji'],
                        isSelected: isSelected,
                        onTap: () => _toggleCondition(condition['value']),
                      );
                    },
                  ),
                )
              else
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.health_and_safety_outlined,
                          size: 80,
                          color: AppColors.textHint,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No worries!',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'You can always update this later\nin settings',
                          style: TextStyle(color: AppColors.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
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

class _ConditionTile extends StatelessWidget {
  final String label;
  final String description;
  final String emoji;
  final bool isSelected;
  final VoidCallback onTap;

  const _ConditionTile({
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
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
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
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textPrimary,
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
            Checkbox(
              value: isSelected,
              onChanged: (_) => onTap(),
              activeColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
