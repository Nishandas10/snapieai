import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../models/food_item.dart';

/// Card displaying a food item
class FoodItemCard extends StatelessWidget {
  final FoodItem food;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;
  final bool showConfidence;
  final bool showHealthFlags;

  const FoodItemCard({
    super.key,
    required this.food,
    this.onTap,
    this.onDelete,
    this.onEdit,
    this.showConfidence = false,
    this.showHealthFlags = true,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          food.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${food.servingSize} ${food.servingUnit}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${food.calories.toInt()} kcal',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      if (showConfidence)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _getConfidenceColor(food.confidence),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${(food.confidence * 100).toInt()}% sure',
                            style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _MacroBadge(
                    label: 'P',
                    value: food.protein,
                    color: AppColors.protein,
                  ),
                  const SizedBox(width: 8),
                  _MacroBadge(
                    label: 'C',
                    value: food.carbs,
                    color: AppColors.carbs,
                  ),
                  const SizedBox(width: 8),
                  _MacroBadge(
                    label: 'F',
                    value: food.fat,
                    color: AppColors.fat,
                  ),
                  const Spacer(),
                  if (onEdit != null)
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 20),
                      onPressed: onEdit,
                      color: AppColors.textSecondary,
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(8),
                    ),
                  if (onDelete != null)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 20),
                      onPressed: onDelete,
                      color: AppColors.error,
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(8),
                    ),
                ],
              ),
              if (showHealthFlags && food.healthFlags.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: food.healthFlags.map((flag) {
                    return _HealthFlag(flag: flag);
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Color _getConfidenceColor(double confidence) {
    if (confidence >= 0.9) return AppColors.success;
    if (confidence >= 0.7) return AppColors.warning;
    return AppColors.error;
  }
}

class _MacroBadge extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _MacroBadge({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '${value.toInt()}g',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _HealthFlag extends StatelessWidget {
  final String flag;

  const _HealthFlag({required this.flag});

  @override
  Widget build(BuildContext context) {
    final (icon, label, color) = _getFlagInfo(flag);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  (String, String, Color) _getFlagInfo(String flag) {
    switch (flag) {
      case 'high_sodium':
        return ('🧂', 'High Sodium', AppColors.highSodium);
      case 'high_gi':
        return ('📈', 'High GI', AppColors.highGI);
      case 'high_sugar':
        return ('🍬', 'High Sugar', AppColors.warning);
      case 'high_cholesterol':
        return ('❤️', 'High Cholesterol', AppColors.error);
      case 'low_protein':
        return ('💪', 'Low Protein', AppColors.lowProtein);
      case 'high_fiber':
        return ('🌾', 'High Fiber', AppColors.healthyChoice);
      default:
        return ('ℹ️', flag, AppColors.info);
    }
  }
}

/// Empty state widget
class EmptyState extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyState({
    super.key,
    required this.title,
    this.subtitle,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 80, color: AppColors.textHint),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
