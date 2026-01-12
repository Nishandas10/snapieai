import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/providers/providers.dart';
import '../../../core/models/user_profile.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProfileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: user != null
          ? _ProfileContent(user: user)
          : const Center(child: Text('No profile found')),
    );
  }
}

class _ProfileContent extends ConsumerWidget {
  final UserProfile user;

  const _ProfileContent({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Profile header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.primary.withValues(alpha: 0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      (user.name?.isNotEmpty ?? false)
                          ? user.name![0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  user.name ?? 'Guest',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${user.age ?? 0} years • ${_getGenderDisplay(user.gender)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getGoalDisplay(user.goal),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Stats grid
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  icon: Icons.monitor_weight,
                  label: 'Weight',
                  value: '${user.weightKg?.toInt() ?? 0} kg',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatTile(
                  icon: Icons.height,
                  label: 'Height',
                  value: '${user.heightCm?.toInt() ?? 0} cm',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatTile(
                  icon: Icons.speed,
                  label: 'BMI',
                  value: user.bmi?.toStringAsFixed(1) ?? '-',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Daily targets
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Daily Targets',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.divider),
            ),
            child: Column(
              children: [
                _TargetRow(
                  icon: Icons.local_fire_department,
                  label: 'Calories',
                  value: '${user.dailyCalorieTarget.toInt()} kcal',
                  color: AppColors.calories,
                ),
                const Divider(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _TargetItem(
                        label: 'Protein',
                        value: '${user.macroTargets.proteinGrams.toInt()}g',
                        color: AppColors.protein,
                      ),
                    ),
                    Expanded(
                      child: _TargetItem(
                        label: 'Carbs',
                        value: '${user.macroTargets.carbsGrams.toInt()}g',
                        color: AppColors.carbs,
                      ),
                    ),
                    Expanded(
                      child: _TargetItem(
                        label: 'Fat',
                        value: '${user.macroTargets.fatGrams.toInt()}g',
                        color: AppColors.fat,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Health conditions
          if (user.healthConditions.isNotEmpty) ...[
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Health Conditions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: user.healthConditions.map((condition) {
                final info = _getHealthConditionInfo(condition);
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: info.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: info.color.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(info.icon, size: 16, color: info.color),
                      const SizedBox(width: 8),
                      Text(
                        info.displayName,
                        style: TextStyle(
                          color: info.color,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],

          // Dietary preferences
          if (user.dietaryPreferences.isNotEmpty) ...[
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Dietary Preferences',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: user.dietaryPreferences.map((pref) {
                final info = _getDietaryPreferenceInfo(pref);
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(info.emoji),
                      const SizedBox(width: 8),
                      Text(
                        info.displayName,
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
          ],

          // Edit profile button
          SecondaryButton(
            text: 'Edit Profile',
            icon: Icons.edit,
            onPressed: () {
              // TODO: Navigate to edit profile
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  String _getGenderDisplay(String? gender) {
    switch (gender) {
      case 'male':
        return 'Male';
      case 'female':
        return 'Female';
      case 'other':
        return 'Other';
      default:
        return 'Not specified';
    }
  }

  String _getGoalDisplay(String goal) {
    switch (goal) {
      case 'lose_fat':
        return 'Lose Fat';
      case 'gain_muscle':
        return 'Gain Muscle';
      case 'maintain':
        return 'Maintain Weight';
      case 'improve_health':
        return 'Improve Health';
      case 'build_strength':
        return 'Build Strength';
      case 'increase_energy':
        return 'Increase Energy';
      default:
        return goal;
    }
  }

  _HealthConditionInfo _getHealthConditionInfo(String condition) {
    switch (condition) {
      case 'diabetes':
        return _HealthConditionInfo(
          'Diabetes',
          Icons.bloodtype,
          AppColors.diabetes,
        );
      case 'prediabetic':
        return _HealthConditionInfo(
          'Pre-Diabetic',
          Icons.bloodtype,
          AppColors.warning,
        );
      case 'high_blood_pressure':
        return _HealthConditionInfo(
          'High Blood Pressure',
          Icons.favorite,
          AppColors.highBP,
        );
      case 'high_cholesterol':
        return _HealthConditionInfo(
          'High Cholesterol',
          Icons.science,
          AppColors.cholesterol,
        );
      case 'pcos':
        return _HealthConditionInfo('PCOS', Icons.female, AppColors.pcos);
      case 'thyroid':
        return _HealthConditionInfo(
          'Thyroid Issues',
          Icons.healing,
          AppColors.thyroid,
        );
      case 'heart_health':
        return _HealthConditionInfo(
          'Heart Health Focus',
          Icons.favorite,
          AppColors.heartHealth,
        );
      default:
        return _HealthConditionInfo(
          condition,
          Icons.health_and_safety,
          AppColors.primary,
        );
    }
  }

  _DietaryPreferenceInfo _getDietaryPreferenceInfo(String pref) {
    switch (pref) {
      case 'vegetarian':
        return _DietaryPreferenceInfo('Vegetarian', '🥗');
      case 'vegan':
        return _DietaryPreferenceInfo('Vegan', '🌱');
      case 'keto':
        return _DietaryPreferenceInfo('Keto', '🥑');
      case 'paleo':
        return _DietaryPreferenceInfo('Paleo', '🥩');
      case 'mediterranean':
        return _DietaryPreferenceInfo('Mediterranean', '🫒');
      case 'gluten_free':
        return _DietaryPreferenceInfo('Gluten Free', '🌾');
      case 'dairy_free':
        return _DietaryPreferenceInfo('Dairy Free', '🥛');
      case 'halal':
        return _DietaryPreferenceInfo('Halal', '☪️');
      case 'kosher':
        return _DietaryPreferenceInfo('Kosher', '✡️');
      default:
        return _DietaryPreferenceInfo(pref, '🍽️');
    }
  }
}

class _HealthConditionInfo {
  final String displayName;
  final IconData icon;
  final Color color;

  _HealthConditionInfo(this.displayName, this.icon, this.color);
}

class _DietaryPreferenceInfo {
  final String displayName;
  final String emoji;

  _DietaryPreferenceInfo(this.displayName, this.emoji);
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
    );
  }
}

class _TargetRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _TargetRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(width: 16),
        Text(
          label,
          style: const TextStyle(fontSize: 16, color: AppColors.textSecondary),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _TargetItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _TargetItem({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
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
