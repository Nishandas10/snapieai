import 'package:flutter/material.dart';

/// Application color palette
class AppColors {
  AppColors._();

  // Primary Colors
  static const Color primary = Color(0xFF10B981); // Emerald green
  static const Color primaryLight = Color(0xFF34D399);
  static const Color primaryDark = Color(0xFF059669);

  // Secondary Colors
  static const Color secondary = Color(0xFF3B82F6); // Blue
  static const Color secondaryLight = Color(0xFF60A5FA);
  static const Color secondaryDark = Color(0xFF2563EB);

  // Accent Colors
  static const Color accent = Color(0xFFF59E0B); // Amber
  static const Color accentLight = Color(0xFFFBBF24);
  static const Color accentDark = Color(0xFFD97706);

  // Semantic Colors
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Macro Colors
  static const Color protein = Color(0xFFEC4899); // Pink
  static const Color carbs = Color(0xFF8B5CF6); // Purple
  static const Color fat = Color(0xFFF59E0B); // Amber
  static const Color fiber = Color(0xFF10B981); // Green
  static const Color calories = Color(0xFFEF4444); // Red

  // Health Condition Colors
  static const Color highSodium = Color(0xFFEF4444);
  static const Color highGI = Color(0xFFF59E0B);
  static const Color lowProtein = Color(0xFFFBBF24);
  static const Color healthyChoice = Color(0xFF10B981);

  // Health Condition Specific Colors
  static const Color diabetes = Color(0xFF3B82F6); // Blue
  static const Color highBP = Color(0xFFEF4444); // Red
  static const Color cholesterol = Color(0xFFF59E0B); // Amber
  static const Color pcos = Color(0xFFEC4899); // Pink
  static const Color thyroid = Color(0xFF8B5CF6); // Purple
  static const Color heartHealth = Color(0xFFEF4444); // Red

  // Background Colors
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color inputBackground = Color(0xFFF1F5F9);

  // Text Colors
  static const Color textPrimary = Color(0xFF1E293B);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textHint = Color(0xFF94A3B8);
  static const Color textDisabled = Color(0xFFCBD5E1);

  // Border & Divider Colors
  static const Color border = Color(0xFFE2E8F0);
  static const Color divider = Color(0xFFE2E8F0);

  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient calorieGradient = LinearGradient(
    colors: [Color(0xFFEF4444), Color(0xFFF87171)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient proteinGradient = LinearGradient(
    colors: [Color(0xFFEC4899), Color(0xFFF472B6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient carbsGradient = LinearGradient(
    colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient fatGradient = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Rating Colors
  static const Color ratingExcellent = Color(0xFF10B981);
  static const Color ratingGood = Color(0xFF34D399);
  static const Color ratingFair = Color(0xFFFBBF24);
  static const Color ratingPoor = Color(0xFFF59E0B);
  static const Color ratingBad = Color(0xFFEF4444);

  // Shimmer Colors
  static const Color shimmerBase = Color(0xFFE2E8F0);
  static const Color shimmerHighlight = Color(0xFFF8FAFC);
}
