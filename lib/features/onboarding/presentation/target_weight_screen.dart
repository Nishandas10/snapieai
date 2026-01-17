import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/common_widgets.dart';
import '../../../core/providers/user_provider.dart';

class TargetWeightScreen extends ConsumerStatefulWidget {
  const TargetWeightScreen({super.key});

  @override
  ConsumerState<TargetWeightScreen> createState() => _TargetWeightScreenState();
}

class _TargetWeightScreenState extends ConsumerState<TargetWeightScreen> {
  bool _isMetric = true; // true = kg, false = lbs
  double _targetWeight = 70.0;
  late ScrollController _scrollController;
  final double _itemExtent = 12.0;

  @override
  void initState() {
    super.initState();
    _initializeWeight();
    _scrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToWeight(_targetWeight);
    });
  }

  void _initializeWeight() {
    // Default target weight is 75 kg for all goals
    _targetWeight = 75.0;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToWeight(double weight) {
    final weightValue = _isMetric ? weight : weight * 2.20462;
    final minWeight = _isMetric ? 30.0 : 66.0;
    final index = ((weightValue - minWeight) * 10).round();
    final offset =
        index * _itemExtent -
        (MediaQuery.of(context).size.width / 2) +
        (_itemExtent / 2);
    _scrollController.animateTo(
      offset.clamp(0.0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _onScroll() {
    final centerOffset =
        _scrollController.offset + (MediaQuery.of(context).size.width / 2);
    final index = (centerOffset / _itemExtent).round();
    final minWeight = _isMetric ? 30.0 : 66.0;
    final newWeight = minWeight + (index / 10);

    final weightInKg = _isMetric ? newWeight : newWeight / 2.20462;

    if ((weightInKg - _targetWeight).abs() > 0.05) {
      HapticFeedback.selectionClick();
      setState(() {
        _targetWeight = weightInKg.clamp(30.0, 300.0);
      });
    }
  }

  void _toggleUnit(bool isMetric) {
    if (_isMetric == isMetric) return;
    setState(() {
      _isMetric = isMetric;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToWeight(_targetWeight);
    });
  }

  String get _goalLabel {
    final user = ref.read(userProfileProvider);
    return user?.goal == 'gain_muscle' ? 'Gain Muscle' : 'Lose Weight';
  }

  Future<void> _continue() async {
    await ref
        .read(userProfileProvider.notifier)
        .updateProfile(targetWeightKg: _targetWeight);

    if (mounted) {
      context.go(AppRoutes.weightGoalSpeed);
    }
  }

  @override
  Widget build(BuildContext context) {
    final displayWeight = _isMetric ? _targetWeight : _targetWeight * 2.20462;
    final user = ref.watch(userProfileProvider);
    final currentWeight = user?.weightKg ?? 70.0;
    final currentDisplayWeight = _isMetric
        ? currentWeight
        : currentWeight * 2.20462;

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
                    onPressed: () => context.go(AppRoutes.goals),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: 0.4,
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
                  const Text(
                    'What is your\ndesired weight?',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Current weight: ${currentDisplayWeight.toStringAsFixed(1)} ${_isMetric ? 'kg' : 'lbs'}',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Unit toggle
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.inputBackground,
                borderRadius: BorderRadius.circular(25),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _UnitToggleButton(
                    label: 'lbs',
                    isSelected: !_isMetric,
                    onTap: () => _toggleUnit(false),
                  ),
                  _UnitToggleButton(
                    label: 'Kg',
                    isSelected: _isMetric,
                    onTap: () => _toggleUnit(true),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Goal label and weight display
            Text(
              _goalLabel,
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${displayWeight.toStringAsFixed(1)} ${_isMetric ? 'kg' : 'lbs'}',
              style: const TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),

            const SizedBox(height: 32),

            // Ruler/Scale picker with center indicator
            SizedBox(
              height: 100,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Ruler
                  NotificationListener<ScrollNotification>(
                    onNotification: (notification) {
                      if (notification is ScrollUpdateNotification) {
                        _onScroll();
                      }
                      return true;
                    },
                    child: ListView.builder(
                      controller: _scrollController,
                      scrollDirection: Axis.horizontal,
                      itemCount: _isMetric
                          ? 2701
                          : 5951, // 30-300 kg or 66-660 lbs with 0.1 increments
                      itemBuilder: (context, index) {
                        final minWeight = _isMetric ? 30.0 : 66.0;
                        final weight = minWeight + (index / 10);
                        final isMajor =
                            (weight * 10).round() % 50 == 0; // Every 5 units
                        final isMinor =
                            (weight * 10).round() % 10 == 0; // Every 1 unit

                        return SizedBox(
                          width: _itemExtent,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: isMajor ? 2 : 1,
                                height: isMajor ? 45 : (isMinor ? 30 : 18),
                                color: isMajor
                                    ? AppColors.textPrimary
                                    : AppColors.textSecondary.withValues(
                                        alpha: 0.4,
                                      ),
                              ),
                              if (isMajor) ...[
                                const SizedBox(height: 6),
                                Text(
                                  weight.toInt().toString(),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  // Center indicator
                  IgnorePointer(
                    child: Container(
                      width: 3,
                      height: 70,
                      decoration: BoxDecoration(
                        color: AppColors.textPrimary,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ],
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

class _UnitToggleButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _UnitToggleButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isSelected ? AppColors.textPrimary : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
