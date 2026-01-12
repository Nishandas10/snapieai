import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_functions/cloud_functions.dart';

/// Service for calling Cloud Functions
class CloudFunctionsService {
  static final FirebaseFunctions _functions = FirebaseFunctions.instance;

  // ============ FOOD ANALYSIS ============

  /// Analyze food image with AI
  static Future<FoodAnalysisResult> analyzeFood({
    required Uint8List imageBytes,
    String mimeType = 'image/jpeg',
    String? userContext,
  }) async {
    try {
      final imageBase64 = base64Encode(imageBytes);

      final callable = _functions.httpsCallable(
        'analyzeFood',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 60)),
      );

      final result = await callable.call<Map<String, dynamic>>({
        'imageBase64': imageBase64,
        'mimeType': mimeType,
        'userContext': userContext,
      });

      if (result.data['success'] == true) {
        return FoodAnalysisResult.fromJson(
          Map<String, dynamic>.from(result.data['data']),
        );
      } else {
        throw Exception('Analysis failed');
      }
    } catch (e) {
      throw _handleError(e);
    }
  }

  /// Analyze food from file
  static Future<FoodAnalysisResult> analyzeFoodFromFile({
    required File imageFile,
    String? userContext,
  }) async {
    final bytes = await imageFile.readAsBytes();
    final extension = imageFile.path.split('.').last.toLowerCase();
    final mimeType = extension == 'png' ? 'image/png' : 'image/jpeg';

    return analyzeFood(
      imageBytes: bytes,
      mimeType: mimeType,
      userContext: userContext,
    );
  }

  // ============ MEAL PLAN ============

  /// Generate personalized meal plan
  static Future<MealPlanResult> generateMealPlan({
    required int targetCalories,
    required int targetProtein,
    required int targetCarbs,
    required int targetFat,
    List<String>? dietaryRestrictions,
    List<String>? preferences,
    int daysCount = 7,
  }) async {
    try {
      final callable = _functions.httpsCallable(
        'generateMealPlan',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 120)),
      );

      final result = await callable.call<Map<String, dynamic>>({
        'targetCalories': targetCalories,
        'targetProtein': targetProtein,
        'targetCarbs': targetCarbs,
        'targetFat': targetFat,
        'dietaryRestrictions': dietaryRestrictions ?? [],
        'preferences': preferences ?? [],
        'daysCount': daysCount,
      });

      if (result.data['success'] == true) {
        return MealPlanResult.fromJson(
          Map<String, dynamic>.from(result.data['data']),
        );
      } else {
        throw Exception('Failed to generate meal plan');
      }
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ============ RECIPE GENERATION ============

  /// Generate a recipe
  static Future<RecipeResult> generateRecipe({
    String? recipeName,
    int targetCalories = 400,
    List<String>? dietaryRestrictions,
    int servings = 4,
    String? cuisine,
    String difficulty = 'medium',
  }) async {
    try {
      final callable = _functions.httpsCallable(
        'generateRecipe',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 60)),
      );

      final result = await callable.call<Map<String, dynamic>>({
        'recipeName': recipeName,
        'targetCalories': targetCalories,
        'dietaryRestrictions': dietaryRestrictions ?? [],
        'servings': servings,
        'cuisine': cuisine,
        'difficulty': difficulty,
      });

      if (result.data['success'] == true) {
        return RecipeResult.fromJson(
          Map<String, dynamic>.from(result.data['data']),
        );
      } else {
        throw Exception('Failed to generate recipe');
      }
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ============ AI CHAT ============

  /// Chat with AI assistant
  static Future<String> chat({
    required String message,
    List<ChatHistoryMessage>? conversationHistory,
    String? sessionId,
  }) async {
    try {
      final callable = _functions.httpsCallable(
        'chat',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 30)),
      );

      final history =
          conversationHistory
              ?.map((m) => {'role': m.role, 'content': m.content})
              .toList() ??
          [];

      final result = await callable.call<Map<String, dynamic>>({
        'message': message,
        'conversationHistory': history,
        'sessionId': sessionId,
      });

      if (result.data['success'] == true) {
        return result.data['data']['message'] as String;
      } else {
        throw Exception('Chat failed');
      }
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ============ CORRECTIONS ============

  /// Submit food analysis correction
  static Future<void> correctFoodAnalysis({
    required String foodLogId,
    required Map<String, dynamic> correction,
    required Map<String, dynamic> originalAnalysis,
  }) async {
    try {
      final callable = _functions.httpsCallable('correctFoodAnalysis');

      await callable.call({
        'foodLogId': foodLogId,
        'correction': correction,
        'originalAnalysis': originalAnalysis,
      });
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ============ DAILY SUMMARY ============

  /// Get daily summary with AI insights
  static Future<DailySummaryResult> getDailySummary({DateTime? date}) async {
    try {
      final callable = _functions.httpsCallable('getDailySummary');

      final result = await callable.call<Map<String, dynamic>>({
        'date': date?.toIso8601String(),
      });

      if (result.data['success'] == true) {
        return DailySummaryResult.fromJson(
          Map<String, dynamic>.from(result.data['data']),
        );
      } else {
        throw Exception('Failed to get daily summary');
      }
    } catch (e) {
      throw _handleError(e);
    }
  }

  // ============ ERROR HANDLING ============

  static Exception _handleError(dynamic error) {
    if (error is FirebaseFunctionsException) {
      switch (error.code) {
        case 'unauthenticated':
          return AuthenticationRequiredException(
            error.message ?? 'Please sign in',
          );
        case 'invalid-argument':
          return InvalidArgumentException(error.message ?? 'Invalid input');
        case 'internal':
          return ServerException(error.message ?? 'Server error');
        default:
          return CloudFunctionException(error.message ?? 'An error occurred');
      }
    }
    return CloudFunctionException(error.toString());
  }
}

// ============ RESULT MODELS ============

/// Food analysis result from AI
class FoodAnalysisResult {
  final String foodName;
  final String description;
  final String servingSize;
  final int servingSizeGrams;
  final double calories;
  final double protein;
  final double carbohydrates;
  final double fat;
  final double fiber;
  final double sugar;
  final double sodium;
  final double saturatedFat;
  final double transFat;
  final double cholesterol;
  final double potassium;
  final double vitaminA;
  final double vitaminC;
  final double calcium;
  final double iron;
  final List<String> ingredients;
  final double healthScore;
  final String healthNotes;
  final List<String> warnings;
  final double confidence;

  FoodAnalysisResult({
    required this.foodName,
    required this.description,
    required this.servingSize,
    required this.servingSizeGrams,
    required this.calories,
    required this.protein,
    required this.carbohydrates,
    required this.fat,
    required this.fiber,
    required this.sugar,
    required this.sodium,
    required this.saturatedFat,
    required this.transFat,
    required this.cholesterol,
    required this.potassium,
    required this.vitaminA,
    required this.vitaminC,
    required this.calcium,
    required this.iron,
    required this.ingredients,
    required this.healthScore,
    required this.healthNotes,
    required this.warnings,
    required this.confidence,
  });

  factory FoodAnalysisResult.fromJson(Map<String, dynamic> json) {
    return FoodAnalysisResult(
      foodName: json['foodName'] ?? 'Unknown Food',
      description: json['description'] ?? '',
      servingSize: json['servingSize'] ?? '1 serving',
      servingSizeGrams: json['servingSizeGrams'] ?? 100,
      calories: (json['calories'] ?? 0).toDouble(),
      protein: (json['protein'] ?? 0).toDouble(),
      carbohydrates: (json['carbohydrates'] ?? 0).toDouble(),
      fat: (json['fat'] ?? 0).toDouble(),
      fiber: (json['fiber'] ?? 0).toDouble(),
      sugar: (json['sugar'] ?? 0).toDouble(),
      sodium: (json['sodium'] ?? 0).toDouble(),
      saturatedFat: (json['saturatedFat'] ?? 0).toDouble(),
      transFat: (json['transFat'] ?? 0).toDouble(),
      cholesterol: (json['cholesterol'] ?? 0).toDouble(),
      potassium: (json['potassium'] ?? 0).toDouble(),
      vitaminA: (json['vitaminA'] ?? 0).toDouble(),
      vitaminC: (json['vitaminC'] ?? 0).toDouble(),
      calcium: (json['calcium'] ?? 0).toDouble(),
      iron: (json['iron'] ?? 0).toDouble(),
      ingredients: List<String>.from(json['ingredients'] ?? []),
      healthScore: (json['healthScore'] ?? 5.0).toDouble(),
      healthNotes: json['healthNotes'] ?? '',
      warnings: List<String>.from(json['warnings'] ?? []),
      confidence: (json['confidence'] ?? 0.5).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'foodName': foodName,
      'description': description,
      'servingSize': servingSize,
      'servingSizeGrams': servingSizeGrams,
      'calories': calories,
      'protein': protein,
      'carbohydrates': carbohydrates,
      'fat': fat,
      'fiber': fiber,
      'sugar': sugar,
      'sodium': sodium,
      'saturatedFat': saturatedFat,
      'transFat': transFat,
      'cholesterol': cholesterol,
      'potassium': potassium,
      'vitaminA': vitaminA,
      'vitaminC': vitaminC,
      'calcium': calcium,
      'iron': iron,
      'ingredients': ingredients,
      'healthScore': healthScore,
      'healthNotes': healthNotes,
      'warnings': warnings,
      'confidence': confidence,
    };
  }
}

/// Meal plan result
class MealPlanResult {
  final String id;
  final String planName;
  final String description;
  final List<MealPlanDay> days;
  final Map<String, List<String>> shoppingList;
  final List<String> tips;

  MealPlanResult({
    required this.id,
    required this.planName,
    required this.description,
    required this.days,
    required this.shoppingList,
    required this.tips,
  });

  factory MealPlanResult.fromJson(Map<String, dynamic> json) {
    return MealPlanResult(
      id: json['id'] ?? '',
      planName: json['planName'] ?? 'Custom Meal Plan',
      description: json['description'] ?? '',
      days:
          (json['days'] as List<dynamic>?)
              ?.map((d) => MealPlanDay.fromJson(d))
              .toList() ??
          [],
      shoppingList: Map<String, List<String>>.from(
        (json['shoppingList'] as Map<String, dynamic>? ?? {}).map(
          (key, value) => MapEntry(key, List<String>.from(value ?? [])),
        ),
      ),
      tips: List<String>.from(json['tips'] ?? []),
    );
  }
}

/// Single day in meal plan
class MealPlanDay {
  final int day;
  final String dayName;
  final List<MealPlanMeal> meals;
  final int totalCalories;
  final int totalProtein;
  final int totalCarbs;
  final int totalFat;

  MealPlanDay({
    required this.day,
    required this.dayName,
    required this.meals,
    required this.totalCalories,
    required this.totalProtein,
    required this.totalCarbs,
    required this.totalFat,
  });

  factory MealPlanDay.fromJson(Map<String, dynamic> json) {
    return MealPlanDay(
      day: json['day'] ?? 1,
      dayName: json['dayName'] ?? 'Day 1',
      meals:
          (json['meals'] as List<dynamic>?)
              ?.map((m) => MealPlanMeal.fromJson(m))
              .toList() ??
          [],
      totalCalories: json['totalCalories'] ?? 0,
      totalProtein: json['totalProtein'] ?? 0,
      totalCarbs: json['totalCarbs'] ?? 0,
      totalFat: json['totalFat'] ?? 0,
    );
  }
}

/// Single meal in meal plan
class MealPlanMeal {
  final String mealType;
  final String name;
  final String description;
  final int calories;
  final int protein;
  final int carbs;
  final int fat;
  final int prepTime;
  final List<String> ingredients;
  final List<String> instructions;

  MealPlanMeal({
    required this.mealType,
    required this.name,
    required this.description,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.prepTime,
    required this.ingredients,
    required this.instructions,
  });

  factory MealPlanMeal.fromJson(Map<String, dynamic> json) {
    return MealPlanMeal(
      mealType: json['mealType'] ?? 'meal',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      calories: json['calories'] ?? 0,
      protein: json['protein'] ?? 0,
      carbs: json['carbs'] ?? 0,
      fat: json['fat'] ?? 0,
      prepTime: json['prepTime'] ?? 0,
      ingredients: List<String>.from(json['ingredients'] ?? []),
      instructions: List<String>.from(json['instructions'] ?? []),
    );
  }
}

/// Recipe result
class RecipeResult {
  final String name;
  final String description;
  final String cuisine;
  final String difficulty;
  final int prepTime;
  final int cookTime;
  final int totalTime;
  final int servings;
  final int caloriesPerServing;
  final Map<String, dynamic> nutritionPerServing;
  final List<RecipeIngredient> ingredients;
  final List<RecipeInstruction> instructions;
  final List<String> tips;
  final List<RecipeSubstitution> substitutions;
  final String storage;
  final List<String> tags;

  RecipeResult({
    required this.name,
    required this.description,
    required this.cuisine,
    required this.difficulty,
    required this.prepTime,
    required this.cookTime,
    required this.totalTime,
    required this.servings,
    required this.caloriesPerServing,
    required this.nutritionPerServing,
    required this.ingredients,
    required this.instructions,
    required this.tips,
    required this.substitutions,
    required this.storage,
    required this.tags,
  });

  factory RecipeResult.fromJson(Map<String, dynamic> json) {
    return RecipeResult(
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      cuisine: json['cuisine'] ?? '',
      difficulty: json['difficulty'] ?? 'medium',
      prepTime: json['prepTime'] ?? 0,
      cookTime: json['cookTime'] ?? 0,
      totalTime: json['totalTime'] ?? 0,
      servings: json['servings'] ?? 4,
      caloriesPerServing: json['caloriesPerServing'] ?? 0,
      nutritionPerServing: Map<String, dynamic>.from(
        json['nutritionPerServing'] ?? {},
      ),
      ingredients:
          (json['ingredients'] as List<dynamic>?)
              ?.map((i) => RecipeIngredient.fromJson(i))
              .toList() ??
          [],
      instructions:
          (json['instructions'] as List<dynamic>?)
              ?.map((i) => RecipeInstruction.fromJson(i))
              .toList() ??
          [],
      tips: List<String>.from(json['tips'] ?? []),
      substitutions:
          (json['substitutions'] as List<dynamic>?)
              ?.map((s) => RecipeSubstitution.fromJson(s))
              .toList() ??
          [],
      storage: json['storage'] ?? '',
      tags: List<String>.from(json['tags'] ?? []),
    );
  }
}

class RecipeIngredient {
  final String item;
  final String amount;
  final String? notes;

  RecipeIngredient({required this.item, required this.amount, this.notes});

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) {
    return RecipeIngredient(
      item: json['item'] ?? '',
      amount: json['amount'] ?? '',
      notes: json['notes'],
    );
  }
}

class RecipeInstruction {
  final int step;
  final String instruction;
  final int? duration;

  RecipeInstruction({
    required this.step,
    required this.instruction,
    this.duration,
  });

  factory RecipeInstruction.fromJson(Map<String, dynamic> json) {
    return RecipeInstruction(
      step: json['step'] ?? 0,
      instruction: json['instruction'] ?? '',
      duration: json['duration'],
    );
  }
}

class RecipeSubstitution {
  final String original;
  final String substitute;
  final String? notes;

  RecipeSubstitution({
    required this.original,
    required this.substitute,
    this.notes,
  });

  factory RecipeSubstitution.fromJson(Map<String, dynamic> json) {
    return RecipeSubstitution(
      original: json['original'] ?? '',
      substitute: json['substitute'] ?? '',
      notes: json['notes'],
    );
  }
}

/// Chat history message
class ChatHistoryMessage {
  final String role;
  final String content;

  ChatHistoryMessage({required this.role, required this.content});
}

/// Daily summary result
class DailySummaryResult {
  final String date;
  final List<Map<String, dynamic>> foodLogs;
  final Map<String, double> totals;
  final Map<String, int> goals;
  final Map<String, double> remaining;
  final Map<String, int> progress;

  DailySummaryResult({
    required this.date,
    required this.foodLogs,
    required this.totals,
    required this.goals,
    required this.remaining,
    required this.progress,
  });

  factory DailySummaryResult.fromJson(Map<String, dynamic> json) {
    return DailySummaryResult(
      date: json['date'] ?? '',
      foodLogs: List<Map<String, dynamic>>.from(json['foodLogs'] ?? []),
      totals: Map<String, double>.from(
        (json['totals'] as Map<String, dynamic>? ?? {}).map(
          (k, v) => MapEntry(k, (v ?? 0).toDouble()),
        ),
      ),
      goals: Map<String, int>.from(
        (json['goals'] as Map<String, dynamic>? ?? {}).map(
          (k, v) => MapEntry(k, (v ?? 0).toInt()),
        ),
      ),
      remaining: Map<String, double>.from(
        (json['remaining'] as Map<String, dynamic>? ?? {}).map(
          (k, v) => MapEntry(k, (v ?? 0).toDouble()),
        ),
      ),
      progress: Map<String, int>.from(
        (json['progress'] as Map<String, dynamic>? ?? {}).map(
          (k, v) => MapEntry(k, (v ?? 0).toInt()),
        ),
      ),
    );
  }
}

// ============ EXCEPTIONS ============

class CloudFunctionException implements Exception {
  final String message;
  CloudFunctionException(this.message);

  @override
  String toString() => message;
}

class AuthenticationRequiredException extends CloudFunctionException {
  AuthenticationRequiredException(super.message);
}

class InvalidArgumentException extends CloudFunctionException {
  InvalidArgumentException(super.message);
}

class ServerException extends CloudFunctionException {
  ServerException(super.message);
}
