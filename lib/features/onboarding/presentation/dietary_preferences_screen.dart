import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/providers/user_provider.dart';

class DietaryPreferencesScreen extends ConsumerStatefulWidget {
  const DietaryPreferencesScreen({super.key});

  @override
  ConsumerState<DietaryPreferencesScreen> createState() =>
      _DietaryPreferencesScreenState();
}

class _DietaryPreferencesScreenState
    extends ConsumerState<DietaryPreferencesScreen> {
  final Set<String> _selectedPreferences = {};

  final List<Map<String, dynamic>> _preferences = [
    {'value': 'vegetarian', 'label': 'Vegetarian', 'emoji': '🥬'},
    {'value': 'vegan', 'label': 'Vegan', 'emoji': '🌱'},
    {'value': 'keto', 'label': 'Keto / Low Carb', 'emoji': '🥑'},
    {'value': 'high_protein', 'label': 'High Protein', 'emoji': '🍖'},
    {'value': 'low_sodium', 'label': 'Low Sodium', 'emoji': '🧂'},
    {'value': 'low_sugar', 'label': 'Low Sugar', 'emoji': '🍬'},
    {'value': 'gluten_free', 'label': 'Gluten-Free', 'emoji': '🌾'},
    {'value': 'dairy_free', 'label': 'Dairy-Free', 'emoji': '🥛'},
    {'value': 'halal', 'label': 'Halal', 'emoji': '🕌'},
    {'value': 'kosher', 'label': 'Kosher', 'emoji': '✡️'},
    {'value': 'mediterranean', 'label': 'Mediterranean', 'emoji': '🫒'},
    {'value': 'indian', 'label': 'Indian Cuisine', 'emoji': '🍛'},
    {'value': 'asian', 'label': 'Asian Cuisine', 'emoji': '🍜'},
  ];

  void _togglePreference(String value) {
    setState(() {
      if (_selectedPreferences.contains(value)) {
        _selectedPreferences.remove(value);
      } else {
        _selectedPreferences.add(value);
      }
    });
  }

  Future<void> _continue() async {
    await ref
        .read(userProfileProvider.notifier)
        .updateProfile(dietaryPreferences: _selectedPreferences.toList());

    if (mounted) {
      context.go(AppRoutes.planGeneration);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dietary Preferences'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.healthConditions),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Any dietary preferences?',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Select all that apply (optional)',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),

              Expanded(
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _preferences.map((pref) {
                      final isSelected = _selectedPreferences.contains(
                        pref['value'],
                      );
                      return SelectionChip(
                        label: pref['label'],
                        emoji: pref['emoji'],
                        isSelected: isSelected,
                        onTap: () => _togglePreference(pref['value']),
                      );
                    }).toList(),
                  ),
                ),
              ),

              const SizedBox(height: 24),
              PrimaryButton(text: 'Generate My Plan', onPressed: _continue),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () async {
                    await ref
                        .read(userProfileProvider.notifier)
                        .updateProfile(dietaryPreferences: []);
                    if (mounted) {
                      context.go(AppRoutes.planGeneration);
                    }
                  },
                  child: const Text('Skip for now'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
