import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';
import 'food_item.dart';

/// Represents a planned meal in a weekly meal plan
class PlannedMeal extends Equatable {
  final String id;
  final String name;
  final String mealType; // breakfast, lunch, dinner, snack
  final List<FoodItem> foods;
  final double totalCalories;
  final double totalProtein;
  final double totalCarbs;
  final double totalFat;
  final String? recipeId;
  final String? notes;
  final int prepTimeMinutes;
  final List<String> tags;
  final bool isSwapped;

  const PlannedMeal({
    required this.id,
    required this.name,
    required this.mealType,
    this.foods = const [],
    this.totalCalories = 0,
    this.totalProtein = 0,
    this.totalCarbs = 0,
    this.totalFat = 0,
    this.recipeId,
    this.notes,
    this.prepTimeMinutes = 0,
    this.tags = const [],
    this.isSwapped = false,
  });

  PlannedMeal copyWith({
    String? id,
    String? name,
    String? mealType,
    List<FoodItem>? foods,
    double? totalCalories,
    double? totalProtein,
    double? totalCarbs,
    double? totalFat,
    String? recipeId,
    String? notes,
    int? prepTimeMinutes,
    List<String>? tags,
    bool? isSwapped,
  }) {
    return PlannedMeal(
      id: id ?? this.id,
      name: name ?? this.name,
      mealType: mealType ?? this.mealType,
      foods: foods ?? this.foods,
      totalCalories: totalCalories ?? this.totalCalories,
      totalProtein: totalProtein ?? this.totalProtein,
      totalCarbs: totalCarbs ?? this.totalCarbs,
      totalFat: totalFat ?? this.totalFat,
      recipeId: recipeId ?? this.recipeId,
      notes: notes ?? this.notes,
      prepTimeMinutes: prepTimeMinutes ?? this.prepTimeMinutes,
      tags: tags ?? this.tags,
      isSwapped: isSwapped ?? this.isSwapped,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'mealType': mealType,
      'foods': foods.map((f) => f.toJson()).toList(),
      'totalCalories': totalCalories,
      'totalProtein': totalProtein,
      'totalCarbs': totalCarbs,
      'totalFat': totalFat,
      'recipeId': recipeId,
      'notes': notes,
      'prepTimeMinutes': prepTimeMinutes,
      'tags': tags,
      'isSwapped': isSwapped,
    };
  }

  factory PlannedMeal.fromJson(Map<String, dynamic> json) {
    return PlannedMeal(
      id: json['id'] as String? ?? const Uuid().v4(),
      name: json['name'] as String? ?? 'Meal',
      mealType: json['mealType'] as String? ?? 'snack',
      foods:
          (json['foods'] as List<dynamic>?)
              ?.map((f) => FoodItem.fromJson(f as Map<String, dynamic>))
              .toList() ??
          [],
      totalCalories: (json['totalCalories'] as num?)?.toDouble() ?? 0,
      totalProtein: (json['totalProtein'] as num?)?.toDouble() ?? 0,
      totalCarbs: (json['totalCarbs'] as num?)?.toDouble() ?? 0,
      totalFat: (json['totalFat'] as num?)?.toDouble() ?? 0,
      recipeId: json['recipeId'] as String?,
      notes: json['notes'] as String?,
      prepTimeMinutes: json['prepTimeMinutes'] as int? ?? 0,
      tags:
          (json['tags'] as List<dynamic>?)?.map((t) => t as String).toList() ??
          [],
      isSwapped: json['isSwapped'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    mealType,
    foods,
    totalCalories,
    totalProtein,
    totalCarbs,
    totalFat,
    recipeId,
    notes,
    prepTimeMinutes,
    tags,
    isSwapped,
  ];
}

/// Represents a day in a meal plan
class DayPlan extends Equatable {
  final String dayName; // Monday, Tuesday, etc.
  final DateTime date;
  final List<PlannedMeal> meals;
  final double targetCalories;
  final String? notes;

  const DayPlan({
    required this.dayName,
    required this.date,
    this.meals = const [],
    this.targetCalories = 2000,
    this.notes,
  });

  double get totalCalories =>
      meals.fold(0, (sum, meal) => sum + meal.totalCalories);
  double get totalProtein =>
      meals.fold(0, (sum, meal) => sum + meal.totalProtein);
  double get totalCarbs => meals.fold(0, (sum, meal) => sum + meal.totalCarbs);
  double get totalFat => meals.fold(0, (sum, meal) => sum + meal.totalFat);

  double get calorieProgress => totalCalories / targetCalories;
  bool get isComplete => meals.length >= 3;

  PlannedMeal? getMeal(String mealType) {
    try {
      return meals.firstWhere((m) => m.mealType == mealType);
    } catch (_) {
      return null;
    }
  }

  DayPlan copyWith({
    String? dayName,
    DateTime? date,
    List<PlannedMeal>? meals,
    double? targetCalories,
    String? notes,
  }) {
    return DayPlan(
      dayName: dayName ?? this.dayName,
      date: date ?? this.date,
      meals: meals ?? this.meals,
      targetCalories: targetCalories ?? this.targetCalories,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dayName': dayName,
      'date': date.toIso8601String(),
      'meals': meals.map((m) => m.toJson()).toList(),
      'targetCalories': targetCalories,
      'notes': notes,
    };
  }

  factory DayPlan.fromJson(Map<String, dynamic> json) {
    return DayPlan(
      dayName: json['dayName'] as String,
      date: DateTime.parse(json['date'] as String),
      meals:
          (json['meals'] as List<dynamic>?)
              ?.map((m) => PlannedMeal.fromJson(m as Map<String, dynamic>))
              .toList() ??
          [],
      targetCalories: (json['targetCalories'] as num?)?.toDouble() ?? 2000,
      notes: json['notes'] as String?,
    );
  }

  @override
  List<Object?> get props => [dayName, date, meals, targetCalories, notes];
}

/// Represents a weekly meal plan
class WeeklyMealPlan extends Equatable {
  final String id;
  final DateTime weekStartDate;
  final List<DayPlan> days;
  final double weeklyCalorieTarget;
  final List<String> groceryList;
  final String? notes;
  final DateTime createdAt;
  final bool isAIGenerated;

  const WeeklyMealPlan({
    required this.id,
    required this.weekStartDate,
    this.days = const [],
    this.weeklyCalorieTarget = 14000,
    this.groceryList = const [],
    this.notes,
    required this.createdAt,
    this.isAIGenerated = false,
  });

  double get totalCalories =>
      days.fold(0, (sum, day) => sum + day.totalCalories);
  double get averageDailyCalories =>
      days.isEmpty ? 0 : totalCalories / days.length;

  int get completedDays => days.where((d) => d.isComplete).length;
  double get weekProgress => days.isEmpty ? 0 : completedDays / 7;

  DayPlan? getDay(String dayName) {
    try {
      return days.firstWhere((d) => d.dayName == dayName);
    } catch (_) {
      return null;
    }
  }

  WeeklyMealPlan copyWith({
    String? id,
    DateTime? weekStartDate,
    List<DayPlan>? days,
    double? weeklyCalorieTarget,
    List<String>? groceryList,
    String? notes,
    DateTime? createdAt,
    bool? isAIGenerated,
  }) {
    return WeeklyMealPlan(
      id: id ?? this.id,
      weekStartDate: weekStartDate ?? this.weekStartDate,
      days: days ?? this.days,
      weeklyCalorieTarget: weeklyCalorieTarget ?? this.weeklyCalorieTarget,
      groceryList: groceryList ?? this.groceryList,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      isAIGenerated: isAIGenerated ?? this.isAIGenerated,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'weekStartDate': weekStartDate.toIso8601String(),
      'days': days.map((d) => d.toJson()).toList(),
      'weeklyCalorieTarget': weeklyCalorieTarget,
      'groceryList': groceryList,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'isAIGenerated': isAIGenerated,
    };
  }

  factory WeeklyMealPlan.fromJson(Map<String, dynamic> json) {
    return WeeklyMealPlan(
      id: json['id'] as String,
      weekStartDate: DateTime.parse(json['weekStartDate'] as String),
      days:
          (json['days'] as List<dynamic>?)
              ?.map((d) => DayPlan.fromJson(d as Map<String, dynamic>))
              .toList() ??
          [],
      weeklyCalorieTarget:
          (json['weeklyCalorieTarget'] as num?)?.toDouble() ?? 14000,
      groceryList:
          (json['groceryList'] as List<dynamic>?)
              ?.map((g) => g as String)
              .toList() ??
          [],
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      isAIGenerated: json['isAIGenerated'] as bool? ?? false,
    );
  }

  factory WeeklyMealPlan.empty() {
    return WeeklyMealPlan(
      id: const Uuid().v4(),
      weekStartDate: DateTime.now(),
      createdAt: DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
    id,
    weekStartDate,
    days,
    weeklyCalorieTarget,
    groceryList,
    notes,
    createdAt,
    isAIGenerated,
  ];
}
