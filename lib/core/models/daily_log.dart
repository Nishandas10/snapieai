import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import 'food_item.dart';

/// Meal type enum
enum MealType {
  breakfast,
  lunch,
  dinner,
  snack;

  String get displayName {
    switch (this) {
      case MealType.breakfast:
        return 'Breakfast';
      case MealType.lunch:
        return 'Lunch';
      case MealType.dinner:
        return 'Dinner';
      case MealType.snack:
        return 'Snack';
    }
  }

  String get emoji {
    switch (this) {
      case MealType.breakfast:
        return '🌅';
      case MealType.lunch:
        return '☀️';
      case MealType.dinner:
        return '🌙';
      case MealType.snack:
        return '🍎';
    }
  }
}

/// Represents a meal containing multiple food items
class Meal extends Equatable {
  final String id;
  final MealType type;
  final List<FoodItem> foods;
  final DateTime loggedAt;
  final String? notes;
  final String? imagePath;

  const Meal({
    required this.id,
    required this.type,
    this.foods = const [],
    required this.loggedAt,
    this.notes,
    this.imagePath,
  });

  double get totalCalories => foods.fold(0, (sum, food) => sum + food.calories);
  double get totalProtein => foods.fold(0, (sum, food) => sum + food.protein);
  double get totalCarbs => foods.fold(0, (sum, food) => sum + food.carbs);
  double get totalFat => foods.fold(0, (sum, food) => sum + food.fat);
  double get totalFiber => foods.fold(0, (sum, food) => sum + food.fiber);
  double get totalSodium =>
      foods.fold(0, (sum, food) => sum + (food.sodiumMg ?? 0));
  double get totalSugar =>
      foods.fold(0, (sum, food) => sum + (food.sugarGrams ?? 0));

  int get foodCount => foods.length;
  double get averageConfidence => foods.isEmpty
      ? 0
      : foods.fold(0.0, (sum, food) => sum + food.confidence) / foods.length;

  List<String> get allHealthFlags {
    final flags = <String>{};
    for (final food in foods) {
      flags.addAll(food.healthFlags);
    }
    return flags.toList();
  }

  Meal copyWith({
    String? id,
    MealType? type,
    List<FoodItem>? foods,
    DateTime? loggedAt,
    String? notes,
    String? imagePath,
  }) {
    return Meal(
      id: id ?? this.id,
      type: type ?? this.type,
      foods: foods ?? this.foods,
      loggedAt: loggedAt ?? this.loggedAt,
      notes: notes ?? this.notes,
      imagePath: imagePath ?? this.imagePath,
    );
  }

  Meal addFood(FoodItem food) {
    return copyWith(foods: [...foods, food]);
  }

  Meal removeFood(String foodId) {
    return copyWith(foods: foods.where((f) => f.id != foodId).toList());
  }

  Meal updateFood(FoodItem updatedFood) {
    return copyWith(
      foods: foods
          .map((f) => f.id == updatedFood.id ? updatedFood : f)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'foods': foods.map((f) => f.toJson()).toList(),
      'loggedAt': loggedAt.toIso8601String(),
      'notes': notes,
      'imagePath': imagePath,
    };
  }

  factory Meal.fromJson(Map<String, dynamic> json) {
    return Meal(
      id: json['id'] as String,
      type: MealType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => MealType.snack,
      ),
      foods:
          (json['foods'] as List<dynamic>?)
              ?.map((f) => FoodItem.fromJson(f as Map<String, dynamic>))
              .toList() ??
          [],
      loggedAt: DateTime.parse(json['loggedAt'] as String),
      notes: json['notes'] as String?,
      imagePath: json['imagePath'] as String?,
    );
  }

  factory Meal.empty(MealType type) {
    return Meal(id: const Uuid().v4(), type: type, loggedAt: DateTime.now());
  }

  @override
  List<Object?> get props => [id, type, foods, loggedAt, notes, imagePath];
}

/// Represents a full day of food logging
class DailyLog extends Equatable {
  final String id;
  final DateTime date;
  final List<Meal> meals;
  final double? weightKg;
  final String? notes;
  final int? waterGlasses;
  final int? exerciseMinutes;

  const DailyLog({
    required this.id,
    required this.date,
    this.meals = const [],
    this.weightKg,
    this.notes,
    this.waterGlasses,
    this.exerciseMinutes,
  });

  String get dateKey =>
      '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

  double get totalCalories =>
      meals.fold(0, (sum, meal) => sum + meal.totalCalories);
  double get totalProtein =>
      meals.fold(0, (sum, meal) => sum + meal.totalProtein);
  double get totalCarbs => meals.fold(0, (sum, meal) => sum + meal.totalCarbs);
  double get totalFat => meals.fold(0, (sum, meal) => sum + meal.totalFat);
  double get totalFiber => meals.fold(0, (sum, meal) => sum + meal.totalFiber);
  double get totalSodium =>
      meals.fold(0, (sum, meal) => sum + meal.totalSodium);
  double get totalSugar => meals.fold(0, (sum, meal) => sum + meal.totalSugar);

  int get totalFoodItems => meals.fold(0, (sum, meal) => sum + meal.foodCount);

  Meal? getMeal(MealType type) {
    try {
      return meals.firstWhere((m) => m.type == type);
    } catch (_) {
      return null;
    }
  }

  double getMealCalories(MealType type) {
    return getMeal(type)?.totalCalories ?? 0;
  }

  DailyLog copyWith({
    String? id,
    DateTime? date,
    List<Meal>? meals,
    double? weightKg,
    String? notes,
    int? waterGlasses,
    int? exerciseMinutes,
  }) {
    return DailyLog(
      id: id ?? this.id,
      date: date ?? this.date,
      meals: meals ?? this.meals,
      weightKg: weightKg ?? this.weightKg,
      notes: notes ?? this.notes,
      waterGlasses: waterGlasses ?? this.waterGlasses,
      exerciseMinutes: exerciseMinutes ?? this.exerciseMinutes,
    );
  }

  DailyLog addMeal(Meal meal) {
    final existingIndex = meals.indexWhere((m) => m.type == meal.type);
    if (existingIndex != -1) {
      final updatedMeals = List<Meal>.from(meals);
      final existingMeal = updatedMeals[existingIndex];
      updatedMeals[existingIndex] = existingMeal.copyWith(
        foods: [...existingMeal.foods, ...meal.foods],
      );
      return copyWith(meals: updatedMeals);
    }
    return copyWith(meals: [...meals, meal]);
  }

  DailyLog updateMeal(Meal updatedMeal) {
    return copyWith(
      meals: meals
          .map((m) => m.type == updatedMeal.type ? updatedMeal : m)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'meals': meals.map((m) => m.toJson()).toList(),
      'weightKg': weightKg,
      'notes': notes,
      'waterGlasses': waterGlasses,
      'exerciseMinutes': exerciseMinutes,
    };
  }

  factory DailyLog.fromJson(Map<String, dynamic> json) {
    return DailyLog(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      meals:
          (json['meals'] as List<dynamic>?)
              ?.map((m) => Meal.fromJson(m as Map<String, dynamic>))
              .toList() ??
          [],
      weightKg: (json['weightKg'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
      waterGlasses: json['waterGlasses'] as int?,
      exerciseMinutes: json['exerciseMinutes'] as int?,
    );
  }

  factory DailyLog.empty(DateTime date) {
    return DailyLog(id: const Uuid().v4(), date: date);
  }

  @override
  List<Object?> get props => [
    id,
    date,
    meals,
    weightKg,
    notes,
    waterGlasses,
    exerciseMinutes,
  ];
}
