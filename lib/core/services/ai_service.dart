import 'dart:convert';
import 'dart:io';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/food_item.dart';
import '../models/meal_plan.dart';
import '../models/recipe.dart';
import '../models/user_profile.dart';

/// AI Service using Firebase Cloud Functions
class AIService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  AIService();

  void setApiKey(String apiKey) {
    // Deprecated: API key is now managed by Cloud Functions
  }

  /// Check if user is authenticated before making Cloud Function calls
  void _checkAuth() {
    final user = FirebaseAuth.instance.currentUser;
    debugPrint('[AIService] Current user: ${user?.uid}');
    if (user == null) {
      throw Exception(
        'User must be signed in to use this feature. Please sign in first.',
      );
    }
  }

  /// Analyze food from image using Cloud Function
  Future<FoodItem> analyzeFoodImage(String imagePath) async {
    _checkAuth();

    try {
      final bytes = await File(imagePath).readAsBytes();
      final base64Image = base64Encode(bytes);

      debugPrint('[AIService] Calling analyzeFood with image...');
      final callable = _functions.httpsCallable(
        'analyzeFood',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 60)),
      );
      debugPrint('[AIService] Making Cloud Function call...');
      final result = await callable.call({
        'imageBase64': base64Image,
        'mimeType': 'image/jpeg',
      });

      debugPrint('[AIService] Result received: ${result.data}');
      final data = Map<String, dynamic>.from(result.data as Map);
      if (data['success'] != true) {
        throw Exception(data['error'] ?? 'Analysis failed');
      }

      final analysisData = Map<String, dynamic>.from(data['data'] as Map);

      // Check if response contains multiple items
      if (analysisData.containsKey('items') && analysisData['items'] is List) {
        final items = analysisData['items'] as List;
        final subItems = items.map((item) {
          final itemData = Map<String, dynamic>.from(item as Map);
          return _createFoodItemFromData(itemData);
        }).toList();

        // Create combined meal entry
        return _createCombinedMealEntry(
          subItems,
          analysisData,
          imagePath: imagePath,
        );
      }

      // Fallback: Single item response (backward compatibility)
      return _createFoodItemFromData(analysisData, imagePath: imagePath);
    } on FirebaseFunctionsException catch (e) {
      debugPrint(
        '[AIService] FirebaseFunctionsException: ${e.code} - ${e.message}',
      );
      debugPrint('[AIService] Details: ${e.details}');
      throw Exception('Cloud Function error: ${e.message}');
    } catch (e) {
      debugPrint('[AIService] Error in analyzeFoodImage: $e');
      throw Exception('Failed to analyze food: ${e.toString()}');
    }
  }

  /// Analyze food from text description
  Future<FoodItem> analyzeFoodText(String description) async {
    _checkAuth();

    try {
      debugPrint('[AIService] Calling analyzeFood with text: $description');
      final callable = _functions.httpsCallable(
        'analyzeFood',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 60)),
      );
      debugPrint('[AIService] Making Cloud Function call...');
      final result = await callable.call({
        'userContext': description,
        'imageBase64': '', // Empty image, using text context
      });

      debugPrint('[AIService] Result received: ${result.data}');
      final data = Map<String, dynamic>.from(result.data as Map);
      if (data['success'] != true) {
        throw Exception(data['error'] ?? 'Analysis failed');
      }

      final analysisData = Map<String, dynamic>.from(data['data'] as Map);

      // Check if response contains multiple items
      if (analysisData.containsKey('items') && analysisData['items'] is List) {
        final items = analysisData['items'] as List;
        final subItems = items.map((item) {
          final itemData = Map<String, dynamic>.from(item as Map);
          return _createFoodItemFromData(itemData);
        }).toList();

        // Create combined meal entry
        return _createCombinedMealEntry(subItems, analysisData);
      }

      // Fallback: Single item response (backward compatibility)
      return _createFoodItemFromData(analysisData);
    } on FirebaseFunctionsException catch (e) {
      debugPrint(
        '[AIService] FirebaseFunctionsException: ${e.code} - ${e.message}',
      );
      debugPrint('[AIService] Details: ${e.details}');
      throw Exception('Cloud Function error: ${e.message}');
    } catch (e) {
      debugPrint('[AIService] Error in analyzeFoodText: $e');
      throw Exception('Failed to analyze food: ${e.toString()}');
    }
  }

  /// Create a combined meal entry from multiple food items
  FoodItem _createCombinedMealEntry(
    List<FoodItem> subItems,
    Map<String, dynamic> analysisData, {
    String? imagePath,
  }) {
    // Generate combined name from all items
    final itemNames = subItems.map((item) => item.name).toList();
    final combinedName = itemNames.length > 3
        ? '${itemNames.take(3).join(', ')} & more'
        : itemNames.join(', ');

    // Calculate totals from subItems
    double totalCalories = 0;
    double totalProtein = 0;
    double totalCarbs = 0;
    double totalFat = 0;
    double totalFiber = 0;
    double totalSodium = 0;
    double totalCholesterol = 0;
    double totalSugar = 0;
    double totalSaturatedFat = 0;
    double totalTransFat = 0;
    double totalPotassium = 0;
    double totalIron = 0;
    double totalCalcium = 0;
    double totalVitaminA = 0;
    double totalVitaminC = 0;
    double totalServingSize = 0;
    double avgHealthScore = 0;
    double minConfidence = 1.0;
    List<String> allWarnings = [];

    // For weighted GI/GL calculation
    double weightedGISum = 0;
    double totalGLSum = 0;
    double carbsWithGI = 0;

    for (final item in subItems) {
      totalCalories += item.calories;
      totalProtein += item.protein;
      totalCarbs += item.carbs;
      totalFat += item.fat;
      totalFiber += item.fiber;
      totalSodium += item.sodiumMg ?? 0;
      totalCholesterol += item.cholesterolMg ?? 0;
      totalSugar += item.sugarGrams ?? 0;
      totalSaturatedFat += item.saturatedFatGrams ?? 0;
      totalTransFat += item.transFatGrams ?? 0;
      totalPotassium += item.potassiumMg ?? 0;
      totalIron += item.ironMg ?? 0;
      totalCalcium += item.calciumMg ?? 0;
      totalVitaminA += item.vitaminAPercent ?? 0;
      totalVitaminC += item.vitaminCPercent ?? 0;
      totalServingSize += item.servingSize;
      avgHealthScore += item.healthScore ?? 5.0;
      if (item.confidence < minConfidence) {
        minConfidence = item.confidence;
      }
      allWarnings.addAll(item.healthFlags);

      // Calculate weighted GI (weighted by carb content)
      if (item.glycemicIndex != null &&
          item.glycemicIndex! > 0 &&
          item.carbs > 0) {
        weightedGISum += item.glycemicIndex! * item.carbs;
        carbsWithGI += item.carbs;
      }

      // Sum GL values directly (GL is additive for a meal)
      if (item.glycemicLoad != null && item.glycemicLoad! > 0) {
        totalGLSum += item.glycemicLoad!;
      }
    }

    avgHealthScore = avgHealthScore / subItems.length;

    // Calculate weighted average GI (only if we have valid data)
    int? combinedGI;
    if (carbsWithGI > 0) {
      combinedGI = (weightedGISum / carbsWithGI).round();
    }

    // Total GL for the meal
    int? combinedGL = totalGLSum > 0 ? totalGLSum.round() : null;

    // Get meal summary from AI response, or generate a basic one
    String mealSummary = analysisData['mealSummary'] as String? ?? '';
    if (mealSummary.isEmpty) {
      // Generate a basic summary if AI didn't provide one
      final itemList = itemNames.join(', ');
      final proteinPercent = ((totalProtein * 4 / totalCalories) * 100).round();
      final carbsPercent = ((totalCarbs * 4 / totalCalories) * 100).round();
      final fatPercent = ((totalFat * 9 / totalCalories) * 100).round();

      mealSummary =
          'This meal contains $itemList, providing ${totalCalories.round()} calories with a macro distribution of $proteinPercent% protein, $carbsPercent% carbs, and $fatPercent% fat. ';

      if (avgHealthScore >= 7) {
        mealSummary += 'Overall, this is a nutritious meal with good balance.';
      } else if (avgHealthScore >= 5) {
        mealSummary += 'This meal provides moderate nutritional value.';
      } else {
        mealSummary +=
            'Consider adding more vegetables or protein for better nutrition.';
      }
    }

    return FoodItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: combinedName,
      calories: totalCalories,
      protein: totalProtein,
      carbs: totalCarbs,
      fat: totalFat,
      fiber: totalFiber,
      sodiumMg: totalSodium,
      cholesterolMg: totalCholesterol,
      sugarGrams: totalSugar,
      saturatedFatGrams: totalSaturatedFat,
      transFatGrams: totalTransFat,
      potassiumMg: totalPotassium,
      glycemicIndex: combinedGI,
      glycemicLoad: combinedGL,
      servingSize: totalServingSize,
      servingUnit: 'g',
      confidence: minConfidence,
      imagePath: imagePath,
      aiExplanation: mealSummary,
      healthFlags: allWarnings.toSet().toList(), // Remove duplicates
      ironMg: totalIron,
      calciumMg: totalCalcium,
      vitaminAPercent: totalVitaminA,
      vitaminCPercent: totalVitaminC,
      healthScore: avgHealthScore,
      subItems: subItems,
    );
  }

  /// Helper method to create FoodItem from analysis data
  FoodItem _createFoodItemFromData(
    Map<String, dynamic> analysisData, {
    String? imagePath,
  }) {
    return FoodItem(
      id:
          DateTime.now().millisecondsSinceEpoch.toString() +
          '_${analysisData['foodName']?.toString().hashCode ?? 0}',
      name: analysisData['foodName'] ?? 'Unknown Food',
      calories: (analysisData['calories'] ?? 0).toDouble(),
      protein: (analysisData['protein'] ?? 0).toDouble(),
      carbs: (analysisData['carbohydrates'] ?? 0).toDouble(),
      fat: (analysisData['fat'] ?? 0).toDouble(),
      fiber: (analysisData['fiber'] ?? 0).toDouble(),
      sodiumMg: (analysisData['sodium'] ?? 0).toDouble(),
      cholesterolMg: (analysisData['cholesterol'] ?? 0).toDouble(),
      sugarGrams: (analysisData['sugar'] ?? 0).toDouble(),
      saturatedFatGrams: (analysisData['saturatedFat'] ?? 0).toDouble(),
      transFatGrams: (analysisData['transFat'] ?? 0).toDouble(),
      potassiumMg: (analysisData['potassium'] ?? 0).toDouble(),
      glycemicIndex: (analysisData['glycemicIndex'] ?? analysisData['gi'] ?? 0)
          .toInt(),
      glycemicLoad: (analysisData['glycemicLoad'] ?? 0).toInt(),
      servingSize: (analysisData['servingSizeGrams'] ?? 100).toDouble(),
      servingUnit: 'g',
      confidence: (analysisData['confidence'] ?? 0.8).toDouble(),
      imagePath: imagePath,
      aiExplanation: analysisData['healthNotes'] ?? '',
      healthFlags: List<String>.from(analysisData['warnings'] ?? []),
      ironMg: (analysisData['iron'] ?? 0).toDouble(),
      calciumMg: (analysisData['calcium'] ?? 0).toDouble(),
      vitaminAPercent: (analysisData['vitaminA'] ?? 0).toDouble(),
      vitaminCPercent: (analysisData['vitaminC'] ?? 0).toDouble(),
      healthScore: (analysisData['healthScore'] ?? 5.0).toDouble(),
    );
  }

  /// Chat with AI nutrition assistant
  Future<String> chat(
    String message, {
    UserProfile? userProfile,
    List<Map<String, String>>? conversationHistory,
    String? recentFoodContext,
  }) async {
    try {
      final callable = _functions.httpsCallable('chat');

      // Build user profile data to send to the cloud function
      Map<String, dynamic>? profileData;
      if (userProfile != null) {
        profileData = {
          'name': userProfile.name,
          'age': userProfile.age,
          'gender': userProfile.gender,
          'heightCm': userProfile.heightCm,
          'weightKg': userProfile.weightKg,
          'activityLevel': userProfile.activityLevel,
          'country': userProfile.country,
          'goal': userProfile.goal,
          'healthConditions': userProfile.healthConditions,
          'dietaryPreferences': userProfile.dietaryPreferences,
          'dailyCalorieTarget': userProfile.dailyCalorieTarget,
          'macroTargets': {
            'proteinGrams': userProfile.macroTargets.proteinGrams,
            'carbsGrams': userProfile.macroTargets.carbsGrams,
            'fatGrams': userProfile.macroTargets.fatGrams,
            'fiberGrams': userProfile.macroTargets.fiberGrams,
          },
          'bmi': userProfile.bmi,
          'giLimit': 55, // Default GI limit for diabetics
          'sodiumLimitMg': 2300, // Default sodium limit
        };
      }

      final result = await callable.call({
        'message': message,
        'conversationHistory':
            conversationHistory
                ?.map((msg) => {'role': msg['role'], 'content': msg['content']})
                .toList() ??
            [],
        'userProfile': profileData,
      });

      final data = Map<String, dynamic>.from(result.data as Map);
      if (data['success'] != true) {
        throw Exception(data['error'] ?? 'Chat failed');
      }

      final chatData = Map<String, dynamic>.from(data['data'] as Map);
      return chatData['message'] as String;
    } catch (e) {
      throw Exception('Failed to get response: ${e.toString()}');
    }
  }

  /// Generate weekly meal plan
  Future<WeeklyMealPlan> generateMealPlan(UserProfile profile) async {
    try {
      final callable = _functions.httpsCallable('generateMealPlan');
      final result = await callable.call({
        'targetCalories': profile.dailyCalorieTarget.toInt(),
        'targetProtein': profile.macroTargets.proteinGrams.toInt(),
        'targetCarbs': profile.macroTargets.carbsGrams.toInt(),
        'targetFat': profile.macroTargets.fatGrams.toInt(),
        'dietaryRestrictions': profile.dietaryPreferences,
        'preferences': profile.healthConditions,
        'daysCount': 7,
      });

      final data = Map<String, dynamic>.from(result.data as Map);
      if (data['success'] != true) {
        throw Exception(data['error'] ?? 'Meal plan generation failed');
      }

      final planData = Map<String, dynamic>.from(data['data'] as Map);

      return WeeklyMealPlan.fromJson({
        ...planData,
        'id':
            planData['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        'weekStartDate': DateTime.now().toIso8601String(),
        'createdAt': DateTime.now().toIso8601String(),
        'isAIGenerated': true,
      });
    } catch (e) {
      throw Exception('Failed to generate meal plan: ${e.toString()}');
    }
  }

  /// Generate recipe from ingredients
  Future<Recipe> generateRecipe(
    List<String> ingredients, {
    UserProfile? profile,
    String? mealType,
    int? maxCalories,
  }) async {
    try {
      final callable = _functions.httpsCallable('generateRecipe');
      final result = await callable.call({
        'recipeName': 'Recipe with ${ingredients.take(3).join(", ")}',
        'targetCalories': maxCalories ?? 400,
        'servings': 4,
        'cuisine': 'Any',
        'difficulty': 'medium',
        'dietaryRestrictions': profile?.dietaryPreferences ?? [],
      });

      final data = Map<String, dynamic>.from(result.data as Map);
      if (data['success'] != true) {
        throw Exception(data['error'] ?? 'Recipe generation failed');
      }

      final recipeData = Map<String, dynamic>.from(data['data'] as Map);

      return Recipe.fromJson({
        ...recipeData,
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'isAIGenerated': true,
        'createdAt': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      throw Exception('Failed to generate recipe: ${e.toString()}');
    }
  }

  /// Calculate nutrition targets based on profile (local calculation)
  Future<Map<String, dynamic>> calculateNutritionTargets(
    UserProfile profile,
  ) async {
    // Basic Mifflin-St Jeor calculation
    double bmr;
    final weight = profile.weightKg ?? 70.0;
    final height = profile.heightCm ?? 170.0;
    final age = profile.age ?? 30;
    final gender = profile.gender ?? 'male';

    if (gender == 'female') {
      bmr = (10 * weight) + (6.25 * height) - (5 * age) - 161;
    } else {
      bmr = (10 * weight) + (6.25 * height) - (5 * age) + 5;
    }

    // Activity multiplier
    double activityMultiplier;
    switch (profile.activityLevel) {
      case 'sedentary':
        activityMultiplier = 1.2;
        break;
      case 'light':
        activityMultiplier = 1.375;
        break;
      case 'moderate':
        activityMultiplier = 1.55;
        break;
      case 'active':
        activityMultiplier = 1.725;
        break;
      case 'very_active':
        activityMultiplier = 1.9;
        break;
      default:
        activityMultiplier = 1.55;
    }

    double tdee = bmr * activityMultiplier;

    // Goal adjustment
    switch (profile.goal) {
      case 'lose_fat':
        tdee *= 0.8;
        break;
      case 'gain_muscle':
        tdee *= 1.1;
        break;
      default:
        break;
    }

    return {
      'dailyCalories': tdee.round(),
      'proteinGrams': ((tdee * 0.3) / 4).round(),
      'carbsGrams': ((tdee * 0.4) / 4).round(),
      'fatGrams': ((tdee * 0.3) / 9).round(),
      'fiberGrams': 30,
      'sodiumMg': profile.healthConditions.contains('high_blood_pressure')
          ? 1500
          : 2300,
      'sugarGrams': profile.healthConditions.contains('diabetes') ? 25 : 50,
      'warnings': [],
      'recommendations': [],
    };
  }
}

/// Provider for AI Service
final aiServiceProvider = Provider<AIService>((ref) {
  return AIService();
});
