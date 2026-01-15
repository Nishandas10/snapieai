import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:country_picker/country_picker.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/providers/user_provider.dart';

class ProfileSetupScreen extends ConsumerStatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  ConsumerState<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends ConsumerState<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();

  String _selectedGender = '';
  String _selectedActivityLevel = 'moderate';
  Country _selectedCountry = CountryParser.parseCountryCode('US');

  final List<Map<String, String>> _activityLevels = [
    {
      'value': 'sedentary',
      'label': 'Sedentary',
      'desc': 'Little to no exercise',
    },
    {'value': 'light', 'label': 'Light', 'desc': '1-3 days/week'},
    {'value': 'moderate', 'label': 'Moderate', 'desc': '3-5 days/week'},
    {'value': 'active', 'label': 'Active', 'desc': '6-7 days/week'},
    {'value': 'very_active', 'label': 'Very Active', 'desc': 'Athlete level'},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (!_formKey.currentState!.validate()) return;

    await ref.read(userProfileProvider.notifier).createNewProfile();
    await ref
        .read(userProfileProvider.notifier)
        .updateProfile(
          name: _nameController.text.trim(),
          age: int.tryParse(_ageController.text),
          gender: _selectedGender.isNotEmpty ? _selectedGender : null,
          heightCm: double.tryParse(_heightController.text),
          weightKg: double.tryParse(_weightController.text),
          activityLevel: _selectedActivityLevel,
          country: _selectedCountry.countryCode,
        );

    if (mounted) {
      context.go(AppRoutes.goals);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Profile'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRoutes.onboarding),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text(
                'Tell us about yourself',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'This helps us personalize your nutrition plan',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 32),

              // Name
              CustomTextField(
                controller: _nameController,
                label: 'Name (optional)',
                hint: 'Enter your name',
                prefixIcon: const Icon(Icons.person_outline),
              ),
              const SizedBox(height: 20),

              // Age
              CustomTextField(
                controller: _ageController,
                label: 'Age',
                hint: 'Enter your age',
                keyboardType: TextInputType.number,
                prefixIcon: const Icon(Icons.cake_outlined),
              ),
              const SizedBox(height: 20),

              // Gender
              const Text(
                'Gender (optional)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: SelectionChip(
                      label: 'Male',
                      emoji: '👨',
                      isSelected: _selectedGender == 'male',
                      onTap: () => setState(() => _selectedGender = 'male'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SelectionChip(
                      label: 'Female',
                      emoji: '👩',
                      isSelected: _selectedGender == 'female',
                      onTap: () => setState(() => _selectedGender = 'female'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SelectionChip(
                      label: 'Other',
                      isSelected: _selectedGender == 'other',
                      onTap: () => setState(() => _selectedGender = 'other'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Height & Weight
              Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      controller: _heightController,
                      label: 'Height (cm)',
                      hint: 'e.g., 170',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: CustomTextField(
                      controller: _weightController,
                      label: 'Weight (kg)',
                      hint: 'e.g., 70',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Activity Level
              const Text(
                'Activity Level',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              ...(_activityLevels.map(
                (level) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _ActivityLevelTile(
                    label: level['label']!,
                    description: level['desc']!,
                    isSelected: _selectedActivityLevel == level['value'],
                    onTap: () => setState(
                      () => _selectedActivityLevel = level['value']!,
                    ),
                  ),
                ),
              )),
              const SizedBox(height: 20),

              // Country
              const Text(
                'Country',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: () {
                  showCountryPicker(
                    context: context,
                    showPhoneCode: false,
                    showWorldWide: false,
                    showSearch: true,
                    countryListTheme: CountryListThemeData(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                      inputDecoration: InputDecoration(
                        hintText: 'Search country',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                      ),
                      searchTextStyle: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 16,
                      ),
                    ),
                    onSelect: (Country country) {
                      setState(() => _selectedCountry = country);
                    },
                  );
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.inputBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Text(
                        _selectedCountry.flagEmoji,
                        style: const TextStyle(fontSize: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedCountry.name,
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.keyboard_arrow_down,
                        color: AppColors.textSecondary,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              PrimaryButton(text: 'Continue', onPressed: _continue),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityLevelTile extends StatelessWidget {
  final String label;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  const _ActivityLevelTile({
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
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
            if (isSelected)
              const Icon(Icons.check_circle, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
