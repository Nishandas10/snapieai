import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/providers/user_provider.dart';

class WeightGoalSpeedScreen extends ConsumerStatefulWidget {
  const WeightGoalSpeedScreen({super.key});

  @override
  ConsumerState<WeightGoalSpeedScreen> createState() =>
      _WeightGoalSpeedScreenState();
}

class _WeightGoalSpeedScreenState extends ConsumerState<WeightGoalSpeedScreen> {
  bool _isMetric = true;
  double _selectedSpeed = 0.5; // kg per week

  String get _goalVerb {
    final user = ref.read(userProfileProvider);
    return user?.goal == 'gain_muscle' ? 'Gain' : 'Lose';
  }

  String get _speedLabel {
    if (_selectedSpeed <= 0.25) {
      return 'Slow and Steady';
    } else if (_selectedSpeed <= 0.75) {
      return 'Moderate Pace';
    } else {
      return 'Aggressive';
    }
  }

  double get _displaySpeed {
    return _isMetric ? _selectedSpeed : _selectedSpeed * 2.20462;
  }

  Future<void> _continue() async {
    await ref
        .read(userProfileProvider.notifier)
        .updateProfile(weeklyWeightGoalKg: _selectedSpeed);

    if (mounted) {
      context.go(AppRoutes.healthConditions);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header with back button and progress
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _CircleBackButton(
                    onPressed: () => context.go(AppRoutes.targetWeight),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: 0.5,
                        backgroundColor: AppColors.border,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          AppColors.textPrimary,
                        ),
                        minHeight: 4,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'How fast do you want\nto reach your goal?',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Speed display
            Column(
              children: [
                Text(
                  '$_goalVerb weight speed per week',
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '${_displaySpeed.toStringAsFixed(1)} ${_isMetric ? 'kg' : 'lbs'}',
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Speed indicators with icons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _SpeedIndicator(
                    emoji: '🦥',
                    isActive: _selectedSpeed <= 0.25,
                  ),
                  _SpeedIndicator(
                    emoji: '🐕',
                    isActive: _selectedSpeed > 0.25 && _selectedSpeed <= 0.75,
                  ),
                  _SpeedIndicator(emoji: '🐆', isActive: _selectedSpeed > 0.75),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Slider
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AppColors.textSecondary.withValues(
                    alpha: 0.3,
                  ),
                  inactiveTrackColor: AppColors.textSecondary.withValues(
                    alpha: 0.3,
                  ),
                  thumbColor: AppColors.textPrimary,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 12,
                  ),
                  trackHeight: 4,
                  overlayColor: AppColors.textPrimary.withValues(alpha: 0.1),
                ),
                child: Slider(
                  value: _selectedSpeed,
                  min: 0.1,
                  max: 1.5,
                  divisions: 14,
                  onChanged: (value) {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _selectedSpeed = value;
                    });
                  },
                ),
              ),
            ),

            // Speed labels
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_isMetric ? "0.1" : "0.2"} ${_isMetric ? "kg" : "lbs"}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    '${_isMetric ? "0.75" : "1.5"} ${_isMetric ? "kg" : "lbs"}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    '${_isMetric ? "1.5" : "3.0"} ${_isMetric ? "kg" : "lbs"}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Speed label chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.inputBackground,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Text(
                _speedLabel,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ),

            const Spacer(),

            // Continue button
            Padding(
              padding: const EdgeInsets.all(24),
              child: PrimaryButton(text: 'Continue', onPressed: _continue),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleBackButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _CircleBackButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border, width: 1),
        ),
        child: const Icon(
          Icons.arrow_back,
          size: 20,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

class _SpeedIndicator extends StatelessWidget {
  final String emoji;
  final bool isActive;

  const _SpeedIndicator({required this.emoji, required this.isActive});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isActive
            ? AppColors.primary.withValues(alpha: 0.1)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(emoji, style: TextStyle(fontSize: isActive ? 36 : 28)),
    );
  }
}
