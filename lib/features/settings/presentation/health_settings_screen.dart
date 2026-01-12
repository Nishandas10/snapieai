import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/providers/user_provider.dart';

class HealthSettingsScreen extends ConsumerStatefulWidget {
  const HealthSettingsScreen({super.key});

  @override
  ConsumerState<HealthSettingsScreen> createState() =>
      _HealthSettingsScreenState();
}

class _HealthSettingsScreenState extends ConsumerState<HealthSettingsScreen> {
  final Set<String> _selectedConditions = {};
  final Set<String> _selectedPreferences = {};
  final List<String> _allergies = [];
  final TextEditingController _allergyController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }

  void _loadCurrentSettings() {
    final profile = ref.read(userProfileProvider);
    if (profile != null) {
      _selectedConditions.addAll(profile.healthConditions);
      _selectedPreferences.addAll(profile.dietaryPreferences);
    }
  }

  @override
  void dispose() {
    _allergyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Health Settings'),
        actions: [
          TextButton(onPressed: _saveSettings, child: const Text('Save')),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Health Conditions Section
          _buildSectionHeader(
            'Health Conditions',
            'Select any conditions that apply to you',
            Icons.medical_services_outlined,
          ),
          const SizedBox(height: 12),
          _buildHealthConditions(),
          const SizedBox(height: 24),

          // Dietary Preferences Section
          _buildSectionHeader(
            'Dietary Preferences',
            'Select your dietary preferences',
            Icons.restaurant_outlined,
          ),
          const SizedBox(height: 12),
          _buildDietaryPreferences(),
          const SizedBox(height: 24),

          // Allergies Section
          _buildSectionHeader(
            'Allergies & Intolerances',
            'Add any food allergies or intolerances',
            Icons.warning_outlined,
          ),
          const SizedBox(height: 12),
          _buildAllergiesSection(),
          const SizedBox(height: 24),

          // Info card
          _buildInfoCard(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, String subtitle, IconData icon) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHealthConditions() {
    final conditions = [
      ('diabetes', 'Diabetes', Icons.bloodtype_outlined, AppColors.diabetes),
      (
        'high_blood_pressure',
        'High Blood Pressure',
        Icons.favorite_border,
        AppColors.highBP,
      ),
      (
        'high_cholesterol',
        'High Cholesterol',
        Icons.water_drop_outlined,
        AppColors.cholesterol,
      ),
      ('pcos', 'PCOS', Icons.woman_outlined, AppColors.pcos),
      (
        'thyroid',
        'Thyroid Issues',
        Icons.health_and_safety_outlined,
        AppColors.thyroid,
      ),
      (
        'heart_health',
        'Heart Disease',
        Icons.monitor_heart_outlined,
        AppColors.heartHealth,
      ),
      (
        'kidney_disease',
        'Kidney Disease',
        Icons.medical_information_outlined,
        Colors.purple,
      ),
      ('celiac', 'Celiac Disease', Icons.grain, Colors.amber),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: conditions.map((condition) {
        final isSelected = _selectedConditions.contains(condition.$1);
        return FilterChip(
          selected: isSelected,
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                condition.$3,
                size: 16,
                color: isSelected ? Colors.white : condition.$4,
              ),
              const SizedBox(width: 6),
              Text(condition.$2),
            ],
          ),
          selectedColor: condition.$4,
          checkmarkColor: Colors.white,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedConditions.add(condition.$1);
              } else {
                _selectedConditions.remove(condition.$1);
              }
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildDietaryPreferences() {
    final preferences = [
      ('vegetarian', 'Vegetarian', Icons.eco_outlined, Colors.green),
      ('vegan', 'Vegan', Icons.grass, Colors.lightGreen),
      ('keto', 'Keto', Icons.egg_outlined, Colors.orange),
      ('paleo', 'Paleo', Icons.restaurant, Colors.brown),
      ('gluten_free', 'Gluten-Free', Icons.no_food_outlined, Colors.amber),
      ('dairy_free', 'Dairy-Free', Icons.block, Colors.blue),
      ('low_carb', 'Low-Carb', Icons.grain, Colors.purple),
      ('low_fat', 'Low-Fat', Icons.water_drop, Colors.cyan),
      ('halal', 'Halal', Icons.check_circle_outline, Colors.teal),
      ('kosher', 'Kosher', Icons.verified_outlined, Colors.indigo),
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: preferences.map((pref) {
        final isSelected = _selectedPreferences.contains(pref.$1);
        return FilterChip(
          selected: isSelected,
          label: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                pref.$3,
                size: 16,
                color: isSelected ? Colors.white : pref.$4,
              ),
              const SizedBox(width: 6),
              Text(pref.$2),
            ],
          ),
          selectedColor: pref.$4,
          checkmarkColor: Colors.white,
          labelStyle: TextStyle(
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedPreferences.add(pref.$1);
              } else {
                _selectedPreferences.remove(pref.$1);
              }
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildAllergiesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Add allergy input
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _allergyController,
                decoration: InputDecoration(
                  hintText: 'Enter allergy (e.g., peanuts)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                onSubmitted: (_) => _addAllergy(),
              ),
            ),
            const SizedBox(width: 12),
            FilledButton(onPressed: _addAllergy, child: const Icon(Icons.add)),
          ],
        ),
        const SizedBox(height: 12),

        // Common allergies quick add
        const Text(
          'Common allergies:',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              [
                'Peanuts',
                'Tree Nuts',
                'Milk',
                'Eggs',
                'Wheat',
                'Soy',
                'Fish',
                'Shellfish',
              ].map((allergy) {
                final isAdded = _allergies.contains(allergy.toLowerCase());
                return ActionChip(
                  label: Text(allergy),
                  avatar: Icon(isAdded ? Icons.check : Icons.add, size: 16),
                  backgroundColor: isAdded
                      ? AppColors.primary.withValues(alpha: 0.1)
                      : null,
                  onPressed: () {
                    if (!isAdded) {
                      setState(() {
                        _allergies.add(allergy.toLowerCase());
                      });
                    }
                  },
                );
              }).toList(),
        ),
        const SizedBox(height: 16),

        // Added allergies list
        if (_allergies.isNotEmpty) ...[
          const Text(
            'Your allergies:',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _allergies.map((allergy) {
              return Chip(
                label: Text(allergy),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () {
                  setState(() {
                    _allergies.remove(allergy);
                  });
                },
                backgroundColor: AppColors.error.withValues(alpha: 0.1),
                side: BorderSide(color: AppColors.error.withValues(alpha: 0.3)),
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildInfoCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.info.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.info),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Your health settings help us provide personalized nutrition recommendations. '
              'This information is kept private and stored only on your device.',
              style: TextStyle(color: AppColors.info, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  void _addAllergy() {
    final allergy = _allergyController.text.trim().toLowerCase();
    if (allergy.isNotEmpty && !_allergies.contains(allergy)) {
      setState(() {
        _allergies.add(allergy);
        _allergyController.clear();
      });
    }
  }

  void _saveSettings() {
    ref
        .read(userProfileProvider.notifier)
        .updateProfile(
          healthConditions: _selectedConditions.toList(),
          dietaryPreferences: _selectedPreferences.toList(),
        );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Health settings saved'),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.pop(context);
  }
}
