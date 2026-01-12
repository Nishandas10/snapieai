import 'package:cloud_firestore/cloud_firestore.dart';

/// Nutrition information for a food item
class FoodNutrition {
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final double sodiumMg;
  final double cholesterolMg;
  final double sugarG;
  final int gi;

  FoodNutrition({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.fiber = 0,
    this.sodiumMg = 0,
    this.cholesterolMg = 0,
    this.sugarG = 0,
    this.gi = 0,
  });

  factory FoodNutrition.fromJson(Map<String, dynamic> json) {
    return FoodNutrition(
      calories: (json['calories'] ?? 0).toDouble(),
      protein: (json['protein'] ?? 0).toDouble(),
      carbs: (json['carbs'] ?? 0).toDouble(),
      fat: (json['fat'] ?? 0).toDouble(),
      fiber: (json['fiber'] ?? 0).toDouble(),
      sodiumMg: (json['sodiumMg'] ?? 0).toDouble(),
      cholesterolMg: (json['cholesterolMg'] ?? 0).toDouble(),
      sugarG: (json['sugarG'] ?? 0).toDouble(),
      gi: json['gi'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'fiber': fiber,
      'sodiumMg': sodiumMg,
      'cholesterolMg': cholesterolMg,
      'sugarG': sugarG,
      'gi': gi,
    };
  }

  FoodNutrition operator +(FoodNutrition other) {
    return FoodNutrition(
      calories: calories + other.calories,
      protein: protein + other.protein,
      carbs: carbs + other.carbs,
      fat: fat + other.fat,
      fiber: fiber + other.fiber,
      sodiumMg: sodiumMg + other.sodiumMg,
      cholesterolMg: cholesterolMg + other.cholesterolMg,
      sugarG: sugarG + other.sugarG,
      gi: ((gi + other.gi) / 2).round(),
    );
  }

  static FoodNutrition zero() {
    return FoodNutrition(calories: 0, protein: 0, carbs: 0, fat: 0);
  }
}

/// A single food entry in a meal
class FoodEntry {
  final String foodId;
  final String name;
  final String source; // camera, manual, barcode
  final String quantity;
  final FoodNutrition nutrition;
  final double confidence;
  final bool edited;
  final String? imageUrl;
  final DateTime createdAt;

  FoodEntry({
    required this.foodId,
    required this.name,
    required this.source,
    required this.quantity,
    required this.nutrition,
    this.confidence = 1.0,
    this.edited = false,
    this.imageUrl,
    required this.createdAt,
  });

  factory FoodEntry.fromJson(Map<String, dynamic> json) {
    return FoodEntry(
      foodId: json['foodId'] ?? '',
      name: json['name'] ?? '',
      source: json['source'] ?? 'manual',
      quantity: json['quantity'] ?? '',
      nutrition: FoodNutrition.fromJson(json['nutrition'] ?? {}),
      confidence: (json['confidence'] ?? 1.0).toDouble(),
      edited: json['edited'] ?? false,
      imageUrl: json['imageUrl'],
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'foodId': foodId,
      'name': name,
      'source': source,
      'quantity': quantity,
      'nutrition': nutrition.toJson(),
      'confidence': confidence,
      'edited': edited,
      if (imageUrl != null) 'imageUrl': imageUrl,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  FoodEntry copyWith({
    String? name,
    String? quantity,
    FoodNutrition? nutrition,
    bool? edited,
    String? imageUrl,
  }) {
    return FoodEntry(
      foodId: foodId,
      name: name ?? this.name,
      source: source,
      quantity: quantity ?? this.quantity,
      nutrition: nutrition ?? this.nutrition,
      confidence: confidence,
      edited: edited ?? this.edited,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt,
    );
  }
}

/// AI warning for the day
class AIWarning {
  final String type;
  final String message;

  AIWarning({required this.type, required this.message});

  factory AIWarning.fromJson(Map<String, dynamic> json) {
    return AIWarning(type: json['type'] ?? '', message: json['message'] ?? '');
  }

  Map<String, dynamic> toJson() {
    return {'type': type, 'message': message};
  }
}

/// Daily totals
class DailyTotals {
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final double sodiumMg;
  final double sugarG;

  DailyTotals({
    this.calories = 0,
    this.protein = 0,
    this.carbs = 0,
    this.fat = 0,
    this.fiber = 0,
    this.sodiumMg = 0,
    this.sugarG = 0,
  });

  factory DailyTotals.fromJson(Map<String, dynamic> json) {
    return DailyTotals(
      calories: (json['calories'] ?? 0).toDouble(),
      protein: (json['protein'] ?? 0).toDouble(),
      carbs: (json['carbs'] ?? 0).toDouble(),
      fat: (json['fat'] ?? 0).toDouble(),
      fiber: (json['fiber'] ?? 0).toDouble(),
      sodiumMg: (json['sodiumMg'] ?? 0).toDouble(),
      sugarG: (json['sugarG'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'fiber': fiber,
      'sodiumMg': sodiumMg,
      'sugarG': sugarG,
    };
  }

  factory DailyTotals.fromFoodEntries(List<FoodEntry> entries) {
    double calories = 0;
    double protein = 0;
    double carbs = 0;
    double fat = 0;
    double fiber = 0;
    double sodiumMg = 0;
    double sugarG = 0;

    for (final entry in entries) {
      calories += entry.nutrition.calories;
      protein += entry.nutrition.protein;
      carbs += entry.nutrition.carbs;
      fat += entry.nutrition.fat;
      fiber += entry.nutrition.fiber;
      sodiumMg += entry.nutrition.sodiumMg;
      sugarG += entry.nutrition.sugarG;
    }

    return DailyTotals(
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      fiber: fiber,
      sodiumMg: sodiumMg,
      sugarG: sugarG,
    );
  }
}

/// Meals container
class DailyMeals {
  final List<FoodEntry> breakfast;
  final List<FoodEntry> lunch;
  final List<FoodEntry> dinner;
  final List<FoodEntry> snacks;

  DailyMeals({
    this.breakfast = const [],
    this.lunch = const [],
    this.dinner = const [],
    this.snacks = const [],
  });

  factory DailyMeals.fromJson(Map<String, dynamic> json) {
    return DailyMeals(
      breakfast:
          (json['breakfast'] as List<dynamic>?)
              ?.map((e) => FoodEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      lunch:
          (json['lunch'] as List<dynamic>?)
              ?.map((e) => FoodEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      dinner:
          (json['dinner'] as List<dynamic>?)
              ?.map((e) => FoodEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      snacks:
          (json['snacks'] as List<dynamic>?)
              ?.map((e) => FoodEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'breakfast': breakfast.map((e) => e.toJson()).toList(),
      'lunch': lunch.map((e) => e.toJson()).toList(),
      'dinner': dinner.map((e) => e.toJson()).toList(),
      'snacks': snacks.map((e) => e.toJson()).toList(),
    };
  }

  List<FoodEntry> get allEntries => [
    ...breakfast,
    ...lunch,
    ...dinner,
    ...snacks,
  ];

  int get totalCount => allEntries.length;

  DailyMeals addEntry(String mealType, FoodEntry entry) {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return DailyMeals(
          breakfast: [...breakfast, entry],
          lunch: lunch,
          dinner: dinner,
          snacks: snacks,
        );
      case 'lunch':
        return DailyMeals(
          breakfast: breakfast,
          lunch: [...lunch, entry],
          dinner: dinner,
          snacks: snacks,
        );
      case 'dinner':
        return DailyMeals(
          breakfast: breakfast,
          lunch: lunch,
          dinner: [...dinner, entry],
          snacks: snacks,
        );
      case 'snacks':
      case 'snack':
        return DailyMeals(
          breakfast: breakfast,
          lunch: lunch,
          dinner: dinner,
          snacks: [...snacks, entry],
        );
      default:
        return this;
    }
  }

  DailyMeals removeEntry(String mealType, String foodId) {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return DailyMeals(
          breakfast: breakfast.where((e) => e.foodId != foodId).toList(),
          lunch: lunch,
          dinner: dinner,
          snacks: snacks,
        );
      case 'lunch':
        return DailyMeals(
          breakfast: breakfast,
          lunch: lunch.where((e) => e.foodId != foodId).toList(),
          dinner: dinner,
          snacks: snacks,
        );
      case 'dinner':
        return DailyMeals(
          breakfast: breakfast,
          lunch: lunch,
          dinner: dinner.where((e) => e.foodId != foodId).toList(),
          snacks: snacks,
        );
      case 'snacks':
      case 'snack':
        return DailyMeals(
          breakfast: breakfast,
          lunch: lunch,
          dinner: dinner,
          snacks: snacks.where((e) => e.foodId != foodId).toList(),
        );
      default:
        return this;
    }
  }
}

/// Daily food log document - one per day
class DailyFoodLog {
  final String date; // YYYY-MM-DD format
  final DailyMeals meals;
  final DailyTotals totals;
  final List<AIWarning> aiWarnings;
  final DateTime updatedAt;

  DailyFoodLog({
    required this.date,
    required this.meals,
    required this.totals,
    this.aiWarnings = const [],
    required this.updatedAt,
  });

  factory DailyFoodLog.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return DailyFoodLog(
      date: doc.id,
      meals: DailyMeals.fromJson(data['meals'] ?? {}),
      totals: DailyTotals.fromJson(data['totals'] ?? {}),
      aiWarnings:
          (data['aiWarnings'] as List<dynamic>?)
              ?.map((e) => AIWarning.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  factory DailyFoodLog.empty(String date) {
    return DailyFoodLog(
      date: date,
      meals: DailyMeals(),
      totals: DailyTotals(),
      aiWarnings: [],
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'meals': meals.toJson(),
      'totals': totals.toJson(),
      'aiWarnings': aiWarnings.map((e) => e.toJson()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  DailyFoodLog addFood(String mealType, FoodEntry entry) {
    final newMeals = meals.addEntry(mealType, entry);
    final newTotals = DailyTotals.fromFoodEntries(newMeals.allEntries);
    return DailyFoodLog(
      date: date,
      meals: newMeals,
      totals: newTotals,
      aiWarnings: aiWarnings,
      updatedAt: DateTime.now(),
    );
  }

  DailyFoodLog removeFood(String mealType, String foodId) {
    final newMeals = meals.removeEntry(mealType, foodId);
    final newTotals = DailyTotals.fromFoodEntries(newMeals.allEntries);
    return DailyFoodLog(
      date: date,
      meals: newMeals,
      totals: newTotals,
      aiWarnings: aiWarnings,
      updatedAt: DateTime.now(),
    );
  }
}
