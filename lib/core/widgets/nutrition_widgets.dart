import 'package:flutter/material.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';
import '../theme/app_colors.dart';

/// Circular progress for calories/macros
class NutritionProgress extends StatelessWidget {
  final double current;
  final double target;
  final String label;
  final String unit;
  final Color color;
  final double size;
  final double lineWidth;
  final bool showPercentage;

  const NutritionProgress({
    super.key,
    required this.current,
    required this.target,
    required this.label,
    this.unit = 'g',
    this.color = AppColors.primary,
    this.size = 100,
    this.lineWidth = 10,
    this.showPercentage = false,
  });

  double get percentage => target > 0 ? (current / target).clamp(0, 1) : 0;
  bool get isOverTarget => current > target;

  @override
  Widget build(BuildContext context) {
    return CircularPercentIndicator(
      radius: size / 2,
      lineWidth: lineWidth,
      percent: percentage,
      animation: true,
      animationDuration: 800,
      circularStrokeCap: CircularStrokeCap.round,
      progressColor: isOverTarget ? AppColors.error : color,
      backgroundColor: color.withValues(alpha: 0.15),
      center: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            showPercentage
                ? '${(percentage * 100).toInt()}%'
                : current.toInt().toString(),
            style: TextStyle(
              fontSize: size / 4,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          if (!showPercentage)
            Text(
              '/ ${target.toInt()} $unit',
              style: TextStyle(
                fontSize: size / 8,
                color: AppColors.textSecondary,
              ),
            ),
        ],
      ),
      footer: Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

/// Linear macro progress bar
class MacroProgressBar extends StatelessWidget {
  final String label;
  final double current;
  final double target;
  final Color color;
  final String? suffix;
  final bool showValues;

  const MacroProgressBar({
    super.key,
    required this.label,
    required this.current,
    required this.target,
    required this.color,
    this.suffix,
    this.showValues = true,
  });

  double get percentage => target > 0 ? (current / target).clamp(0, 1) : 0;
  bool get isOverTarget => current > target;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
            if (showValues)
              Text(
                '${current.toInt()}${suffix ?? 'g'} / ${target.toInt()}${suffix ?? 'g'}',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isOverTarget
                      ? AppColors.error
                      : AppColors.textSecondary,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            Container(
              height: 8,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              height: 8,
              width: MediaQuery.of(context).size.width * 0.9 * percentage,
              decoration: BoxDecoration(
                color: isOverTarget ? AppColors.error : color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Macro summary card with swipable pages
class MacroSummaryCard extends StatefulWidget {
  final double calories;
  final double calorieTarget;
  final double protein;
  final double proteinTarget;
  final double carbs;
  final double carbsTarget;
  final double fat;
  final double fatTarget;
  final double fiber;
  final double fiberTarget;
  final double sodium;
  final double sodiumTarget;
  final double sugar;
  final double sugarTarget;

  const MacroSummaryCard({
    super.key,
    required this.calories,
    required this.calorieTarget,
    required this.protein,
    required this.proteinTarget,
    required this.carbs,
    required this.carbsTarget,
    required this.fat,
    required this.fatTarget,
    this.fiber = 0,
    this.fiberTarget = 30,
    this.sodium = 0,
    this.sodiumTarget = 2300,
    this.sugar = 0,
    this.sugarTarget = 50,
  });

  @override
  State<MacroSummaryCard> createState() => _MacroSummaryCardState();
}

class _MacroSummaryCardState extends State<MacroSummaryCard> {
  int _currentPage = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Calorie progress - always visible
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                NutritionProgress(
                  current: widget.calories,
                  target: widget.calorieTarget,
                  label: 'Calories',
                  unit: 'kcal',
                  color: AppColors.calories,
                  size: 120,
                  lineWidth: 12,
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Swipable macro pages
            SizedBox(
              height: 90,
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                children: [
                  // Page 1: Protein, Carbs, Fat
                  Row(
                    children: [
                      Expanded(
                        child: _MacroMini(
                          label: 'Protein',
                          current: widget.protein,
                          target: widget.proteinTarget,
                          color: AppColors.protein,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _MacroMini(
                          label: 'Carbs',
                          current: widget.carbs,
                          target: widget.carbsTarget,
                          color: AppColors.carbs,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _MacroMini(
                          label: 'Fat',
                          current: widget.fat,
                          target: widget.fatTarget,
                          color: AppColors.fat,
                        ),
                      ),
                    ],
                  ),
                  // Page 2: Fiber, Sodium, Sugar
                  Row(
                    children: [
                      Expanded(
                        child: _MacroMini(
                          label: 'Fiber',
                          current: widget.fiber,
                          target: widget.fiberTarget,
                          color: AppColors.fiber,
                          unit: 'g',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _MacroMini(
                          label: 'Sodium',
                          current: widget.sodium,
                          target: widget.sodiumTarget,
                          color: AppColors.highSodium,
                          unit: 'mg',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _MacroMini(
                          label: 'Sugar',
                          current: widget.sugar,
                          target: widget.sugarTarget,
                          color: AppColors.warning,
                          unit: 'g',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Page indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _PageDot(isActive: _currentPage == 0),
                const SizedBox(width: 8),
                _PageDot(isActive: _currentPage == 1),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PageDot extends StatelessWidget {
  final bool isActive;

  const _PageDot({required this.isActive});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: isActive ? 20 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive ? AppColors.primary : AppColors.border,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

class _MacroMini extends StatelessWidget {
  final String label;
  final double current;
  final double target;
  final Color color;
  final String unit;

  const _MacroMini({
    required this.label,
    required this.current,
    required this.target,
    required this.color,
    this.unit = 'g',
  });

  @override
  Widget build(BuildContext context) {
    final percentage = target > 0 ? (current / target).clamp(0.0, 1.0) : 0.0;

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 50,
              height: 50,
              child: CircularProgressIndicator(
                value: percentage,
                strokeWidth: 5,
                backgroundColor: color.withValues(alpha: 0.15),
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            Text(
              '${current.toInt()}',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
        ),
        Text(
          '${target.toInt()}$unit',
          style: const TextStyle(fontSize: 10, color: AppColors.textHint),
        ),
      ],
    );
  }
}
