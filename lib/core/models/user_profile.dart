import 'package:equatable/equatable.dart';

/// User profile model containing all user information
class UserProfile extends Equatable {
  final String id;
  final String? name;
  final int? age;
  final String? gender;
  final double? heightCm;
  final double? weightKg;
  final double? targetWeightKg; // Desired weight for lose_fat/gain_muscle goals
  final double?
  startingWeightKg; // Starting weight when goal was set (for progress tracking)
  final double?
  weeklyWeightGoalKg; // Weekly weight change goal (e.g., 0.5 kg/week)
  final String activityLevel;
  final String country;
  final String goal;
  final List<String> healthConditions;
  final List<String> dietaryPreferences;
  final double dailyCalorieTarget;
  final MacroTargets macroTargets;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserProfile({
    required this.id,
    this.name,
    this.age,
    this.gender,
    this.heightCm,
    this.weightKg,
    this.targetWeightKg,
    this.startingWeightKg,
    this.weeklyWeightGoalKg,
    this.activityLevel = 'moderate',
    this.country = 'US',
    this.goal = 'maintain',
    this.healthConditions = const [],
    this.dietaryPreferences = const [],
    this.dailyCalorieTarget = 2000,
    this.macroTargets = const MacroTargets(),
    required this.createdAt,
    required this.updatedAt,
  });

  double? get bmi {
    if (heightCm != null && weightKg != null && heightCm! > 0) {
      final heightM = heightCm! / 100;
      return weightKg! / (heightM * heightM);
    }
    return null;
  }

  String get bmiCategory {
    final bmiValue = bmi;
    if (bmiValue == null) return 'Unknown';
    if (bmiValue < 18.5) return 'Underweight';
    if (bmiValue < 25) return 'Normal';
    if (bmiValue < 30) return 'Overweight';
    return 'Obese';
  }

  bool get hasHighBP => healthConditions.contains('high_blood_pressure');
  bool get hasPCOS => healthConditions.contains('pcos');
  bool get hasDiabetes =>
      healthConditions.any((c) => c.contains('diabetes') || c == 'prediabetic');
  bool get hasHighCholesterol => healthConditions.contains('high_cholesterol');
  bool get hasThyroidIssues => healthConditions.contains('thyroid');
  bool get hasHeartHealthFocus => healthConditions.contains('heart_health');

  /// Returns true if the user's goal requires weight tracking (lose_fat or gain_muscle)
  bool get hasWeightGoal => goal == 'lose_fat' || goal == 'gain_muscle';

  /// Calculate weight progress percentage (0.0 to 1.0)
  /// Uses startingWeightKg to calculate actual progress from start to target
  double? get weightProgressPercentage {
    if (!hasWeightGoal || weightKg == null || targetWeightKg == null) {
      return null;
    }

    // Use starting weight if available, otherwise use current weight as starting point
    final starting = startingWeightKg ?? weightKg!;
    final current = weightKg!;
    final target = targetWeightKg!;

    // Calculate total distance from start to target
    final totalDistance = (starting - target).abs();
    if (totalDistance == 0) return 1.0; // Already at target

    // Calculate how much progress has been made
    final isLosing = goal == 'lose_fat';

    if (isLosing) {
      // For weight loss: progress = how much weight lost / total to lose
      final weightLost = starting - current;
      final progress = weightLost / totalDistance;
      return progress.clamp(0.0, 1.0);
    } else {
      // For muscle gain: progress = how much weight gained / total to gain
      final weightGained = current - starting;
      final progress = weightGained / totalDistance;
      return progress.clamp(0.0, 1.0);
    }
  }

  /// Get weight difference to target
  double? get weightToTarget {
    if (weightKg == null || targetWeightKg == null) return null;
    return (weightKg! - targetWeightKg!).abs();
  }

  UserProfile copyWith({
    String? id,
    String? name,
    int? age,
    String? gender,
    double? heightCm,
    double? weightKg,
    double? targetWeightKg,
    double? startingWeightKg,
    double? weeklyWeightGoalKg,
    String? activityLevel,
    String? country,
    String? goal,
    List<String>? healthConditions,
    List<String>? dietaryPreferences,
    double? dailyCalorieTarget,
    MacroTargets? macroTargets,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      targetWeightKg: targetWeightKg ?? this.targetWeightKg,
      startingWeightKg: startingWeightKg ?? this.startingWeightKg,
      weeklyWeightGoalKg: weeklyWeightGoalKg ?? this.weeklyWeightGoalKg,
      activityLevel: activityLevel ?? this.activityLevel,
      country: country ?? this.country,
      goal: goal ?? this.goal,
      healthConditions: healthConditions ?? this.healthConditions,
      dietaryPreferences: dietaryPreferences ?? this.dietaryPreferences,
      dailyCalorieTarget: dailyCalorieTarget ?? this.dailyCalorieTarget,
      macroTargets: macroTargets ?? this.macroTargets,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'gender': gender,
      'heightCm': heightCm,
      'weightKg': weightKg,
      'targetWeightKg': targetWeightKg,
      'startingWeightKg': startingWeightKg,
      'weeklyWeightGoalKg': weeklyWeightGoalKg,
      'activityLevel': activityLevel,
      'country': country,
      'goal': goal,
      'healthConditions': healthConditions,
      'dietaryPreferences': dietaryPreferences,
      'dailyCalorieTarget': dailyCalorieTarget,
      'macroTargets': macroTargets.toJson(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      name: json['name'] as String?,
      age: json['age'] as int?,
      gender: json['gender'] as String?,
      heightCm: (json['heightCm'] as num?)?.toDouble(),
      weightKg: (json['weightKg'] as num?)?.toDouble(),
      targetWeightKg: (json['targetWeightKg'] as num?)?.toDouble(),
      startingWeightKg: (json['startingWeightKg'] as num?)?.toDouble(),
      weeklyWeightGoalKg: (json['weeklyWeightGoalKg'] as num?)?.toDouble(),
      activityLevel: json['activityLevel'] as String? ?? 'moderate',
      country: json['country'] as String? ?? 'US',
      goal: json['goal'] as String? ?? 'maintain',
      healthConditions:
          (json['healthConditions'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      dietaryPreferences:
          (json['dietaryPreferences'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      dailyCalorieTarget:
          (json['dailyCalorieTarget'] as num?)?.toDouble() ?? 2000,
      macroTargets: json['macroTargets'] != null
          ? MacroTargets.fromJson(json['macroTargets'] as Map<String, dynamic>)
          : const MacroTargets(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  factory UserProfile.empty() {
    return UserProfile(
      id: '',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    age,
    gender,
    heightCm,
    weightKg,
    targetWeightKg,
    startingWeightKg,
    weeklyWeightGoalKg,
    activityLevel,
    country,
    goal,
    healthConditions,
    dietaryPreferences,
    dailyCalorieTarget,
    macroTargets,
    createdAt,
    updatedAt,
  ];
}

/// Macro nutrient targets
class MacroTargets extends Equatable {
  final double proteinGrams;
  final double carbsGrams;
  final double fatGrams;
  final double fiberGrams;
  final double? sodiumMg;
  final double? sugarGrams;
  final double? cholesterolMg;

  const MacroTargets({
    this.proteinGrams = 150,
    this.carbsGrams = 200,
    this.fatGrams = 65,
    this.fiberGrams = 30,
    this.sodiumMg,
    this.sugarGrams,
    this.cholesterolMg,
  });

  double get proteinCalories => proteinGrams * 4;
  double get carbsCalories => carbsGrams * 4;
  double get fatCalories => fatGrams * 9;
  double get totalCalories => proteinCalories + carbsCalories + fatCalories;

  double get proteinPercentage => (proteinCalories / totalCalories) * 100;
  double get carbsPercentage => (carbsCalories / totalCalories) * 100;
  double get fatPercentage => (fatCalories / totalCalories) * 100;

  MacroTargets copyWith({
    double? proteinGrams,
    double? carbsGrams,
    double? fatGrams,
    double? fiberGrams,
    double? sodiumMg,
    double? sugarGrams,
    double? cholesterolMg,
  }) {
    return MacroTargets(
      proteinGrams: proteinGrams ?? this.proteinGrams,
      carbsGrams: carbsGrams ?? this.carbsGrams,
      fatGrams: fatGrams ?? this.fatGrams,
      fiberGrams: fiberGrams ?? this.fiberGrams,
      sodiumMg: sodiumMg ?? this.sodiumMg,
      sugarGrams: sugarGrams ?? this.sugarGrams,
      cholesterolMg: cholesterolMg ?? this.cholesterolMg,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'proteinGrams': proteinGrams,
      'carbsGrams': carbsGrams,
      'fatGrams': fatGrams,
      'fiberGrams': fiberGrams,
      'sodiumMg': sodiumMg,
      'sugarGrams': sugarGrams,
      'cholesterolMg': cholesterolMg,
    };
  }

  factory MacroTargets.fromJson(Map<String, dynamic> json) {
    return MacroTargets(
      proteinGrams: (json['proteinGrams'] as num?)?.toDouble() ?? 150,
      carbsGrams: (json['carbsGrams'] as num?)?.toDouble() ?? 200,
      fatGrams: (json['fatGrams'] as num?)?.toDouble() ?? 65,
      fiberGrams: (json['fiberGrams'] as num?)?.toDouble() ?? 30,
      sodiumMg: (json['sodiumMg'] as num?)?.toDouble(),
      sugarGrams: (json['sugarGrams'] as num?)?.toDouble(),
      cholesterolMg: (json['cholesterolMg'] as num?)?.toDouble(),
    );
  }

  @override
  List<Object?> get props => [
    proteinGrams,
    carbsGrams,
    fatGrams,
    fiberGrams,
    sodiumMg,
    sugarGrams,
    cholesterolMg,
  ];
}
