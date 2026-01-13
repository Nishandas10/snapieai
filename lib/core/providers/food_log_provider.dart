import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/daily_log.dart';
import '../models/food_item.dart';
import '../services/storage_service.dart';
import '../services/firebase_service.dart';

/// State for daily food log
class DailyLogState {
  final DailyLog? todayLog;
  final Map<String, DailyLog> logHistory;
  final bool isLoading;
  final String? error;
  final DateTime selectedDate;
  final DailyLog? selectedDateLog;

  DailyLogState({
    this.todayLog,
    this.logHistory = const {},
    this.isLoading = false,
    this.error,
    DateTime? selectedDate,
    this.selectedDateLog,
  }) : selectedDate = selectedDate ?? DateTime.now();

  DailyLogState copyWith({
    DailyLog? todayLog,
    Map<String, DailyLog>? logHistory,
    bool? isLoading,
    String? error,
    DateTime? selectedDate,
    DailyLog? selectedDateLog,
    bool clearSelectedDateLog = false,
  }) {
    return DailyLogState(
      todayLog: todayLog ?? this.todayLog,
      logHistory: logHistory ?? this.logHistory,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedDate: selectedDate ?? this.selectedDate,
      selectedDateLog: clearSelectedDateLog
          ? null
          : (selectedDateLog ?? this.selectedDateLog),
    );
  }

  /// Get the log for the currently selected date
  DailyLog? get currentLog {
    final todayKey = _getDateKey(DateTime.now());
    final selectedKey = _getDateKey(selectedDate);

    if (todayKey == selectedKey) {
      return todayLog;
    }
    return selectedDateLog ?? logHistory[selectedKey];
  }

  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

/// Food log state notifier
class FoodLogNotifier extends StateNotifier<DailyLogState> {
  FoodLogNotifier() : super(DailyLogState()) {
    _loadTodayLog();
  }

  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  void _loadTodayLog() async {
    final today = DateTime.now();
    final dateKey = _getDateKey(today);
    debugPrint('[FoodLogProvider] Loading today\'s log for $dateKey');

    // First load from local storage for instant display
    final localData = StorageService.getFoodLog(dateKey);
    if (localData != null) {
      state = state.copyWith(todayLog: DailyLog.fromJson(localData));
    } else {
      state = state.copyWith(todayLog: DailyLog.empty(today));
    }

    // Then try to sync from Firestore if authenticated
    final user = FirebaseService.currentUser;
    if (user != null) {
      try {
        final firestoreData = await FirebaseService.getFoodLog(
          user.uid,
          dateKey,
        );
        if (firestoreData != null) {
          final log = _logFromFirestore(dateKey, firestoreData);
          state = state.copyWith(todayLog: log);
          // Update local cache
          await StorageService.saveFoodLog(dateKey, log.toJson());
        }
      } catch (e) {
        // Firestore load failed, keep local data
      }
    }
  }

  DailyLog _logFromFirestore(String dateKey, Map<String, dynamic> data) {
    final meals = data['meals'] as Map<String, dynamic>? ?? {};
    final mealsList = <Meal>[];

    meals.forEach((mealTypeName, mealData) {
      final mealType = MealType.values.firstWhere(
        (t) => t.name == mealTypeName,
        orElse: () => MealType.snack,
      );

      final foodsList =
          (mealData as List<dynamic>?)?.map((foodData) {
            final food = foodData as Map<String, dynamic>;
            final nutrition = food['nutrition'] as Map<String, dynamic>? ?? {};
            return FoodItem(
              id:
                  food['id'] as String? ??
                  DateTime.now().millisecondsSinceEpoch.toString(),
              name: food['name'] as String? ?? 'Unknown Food',
              calories: (nutrition['calories'] as num?)?.toDouble() ?? 0,
              protein: (nutrition['protein'] as num?)?.toDouble() ?? 0,
              carbs: (nutrition['carbs'] as num?)?.toDouble() ?? 0,
              fat: (nutrition['fat'] as num?)?.toDouble() ?? 0,
              fiber: (nutrition['fiber'] as num?)?.toDouble() ?? 0,
              sodiumMg: (nutrition['sodiumMg'] as num?)?.toDouble(),
              sugarGrams:
                  (nutrition['sugarGrams'] as num?)?.toDouble() ??
                  (nutrition['sugarG'] as num?)?.toDouble(),
              cholesterolMg: (nutrition['cholesterolMg'] as num?)?.toDouble(),
              saturatedFatGrams: (nutrition['saturatedFatGrams'] as num?)
                  ?.toDouble(),
              transFatGrams: (nutrition['transFatGrams'] as num?)?.toDouble(),
              potassiumMg: (nutrition['potassiumMg'] as num?)?.toDouble(),
              ironMg: (nutrition['ironMg'] as num?)?.toDouble(),
              calciumMg: (nutrition['calciumMg'] as num?)?.toDouble(),
              vitaminAPercent: (nutrition['vitaminAPercent'] as num?)
                  ?.toDouble(),
              vitaminCPercent: (nutrition['vitaminCPercent'] as num?)
                  ?.toDouble(),
              glycemicIndex: (nutrition['glycemicIndex'] as num?)?.toInt(),
              glycemicLoad: (nutrition['glycemicLoad'] as num?)?.toInt(),
              healthScore: (nutrition['healthScore'] as num?)?.toDouble(),
              servingSize: (food['servingSize'] as num?)?.toDouble() ?? 1,
              servingUnit: food['servingUnit'] as String? ?? 'serving',
              imagePath: food['imagePath'] as String?,
              notes: food['notes'] as String?,
              confidence: (food['confidence'] as num?)?.toDouble() ?? 1.0,
              isManuallyEdited: food['isManuallyEdited'] as bool? ?? false,
              aiExplanation: food['aiExplanation'] as String?,
              healthFlags:
                  (food['healthFlags'] as List<dynamic>?)
                      ?.map((e) => e as String)
                      .toList() ??
                  [],
            );
          }).toList() ??
          [];

      if (foodsList.isNotEmpty) {
        mealsList.add(
          Meal(
            id: '${dateKey}_$mealTypeName',
            type: mealType,
            foods: foodsList,
            loggedAt: DateTime.now(),
          ),
        );
      }
    });

    final dateParts = dateKey.split('-');
    final date = DateTime(
      int.parse(dateParts[0]),
      int.parse(dateParts[1]),
      int.parse(dateParts[2]),
    );

    return DailyLog(id: dateKey, date: date, meals: mealsList);
  }

  /// Select a specific date and load its data
  Future<void> selectDate(DateTime date) async {
    final dateKey = _getDateKey(date);
    final todayKey = _getDateKey(DateTime.now());

    state = state.copyWith(
      selectedDate: date,
      isLoading: true,
      clearSelectedDateLog: true,
    );

    // If it's today, use todayLog
    if (dateKey == todayKey) {
      state = state.copyWith(isLoading: false, selectedDateLog: state.todayLog);
      return;
    }

    // Check cache first
    if (state.logHistory.containsKey(dateKey)) {
      state = state.copyWith(
        isLoading: false,
        selectedDateLog: state.logHistory[dateKey],
      );
      return;
    }

    // Load from local storage
    final localData = StorageService.getFoodLog(dateKey);
    if (localData != null) {
      final log = DailyLog.fromJson(localData);
      state = state.copyWith(
        logHistory: {...state.logHistory, dateKey: log},
        selectedDateLog: log,
        isLoading: false,
      );
    } else {
      // Create empty log for that date
      final emptyLog = DailyLog.empty(date);
      state = state.copyWith(selectedDateLog: emptyLog, isLoading: false);
    }

    // Try to sync from Firestore if authenticated
    final user = FirebaseService.currentUser;
    if (user != null) {
      try {
        final firestoreData = await FirebaseService.getFoodLog(
          user.uid,
          dateKey,
        );
        if (firestoreData != null) {
          final log = _logFromFirestore(dateKey, firestoreData);
          state = state.copyWith(
            logHistory: {...state.logHistory, dateKey: log},
            selectedDateLog: log,
          );
          // Update local cache
          await StorageService.saveFoodLog(dateKey, log.toJson());
        }
      } catch (e) {
        debugPrint('[FoodLogProvider] Failed to load from Firestore: $e');
      }
    }
  }

  Future<DailyLog> getOrCreateLog(DateTime date) async {
    final dateKey = _getDateKey(date);

    // Check if it's today
    if (dateKey == _getDateKey(DateTime.now()) && state.todayLog != null) {
      return state.todayLog!;
    }

    // Check cache
    if (state.logHistory.containsKey(dateKey)) {
      return state.logHistory[dateKey]!;
    }

    // Load from storage
    final data = StorageService.getFoodLog(dateKey);
    if (data != null) {
      final log = DailyLog.fromJson(data);
      state = state.copyWith(logHistory: {...state.logHistory, dateKey: log});
      return log;
    }

    // Create new
    final newLog = DailyLog.empty(date);
    await _saveLog(newLog);
    return newLog;
  }

  Future<void> _saveLog(DailyLog log) async {
    final dateKey = log.dateKey;
    debugPrint('[FoodLogProvider] Saving log for $dateKey');

    // Save to local storage
    await StorageService.saveFoodLog(dateKey, log.toJson());
    debugPrint('[FoodLogProvider] Saved to local storage');

    if (dateKey == _getDateKey(DateTime.now())) {
      state = state.copyWith(todayLog: log);
    } else {
      state = state.copyWith(logHistory: {...state.logHistory, dateKey: log});
    }

    // Sync to Firestore if authenticated
    final user = FirebaseService.currentUser;
    debugPrint(
      '[FoodLogProvider] Current user for Firestore sync: ${user?.uid}',
    );

    if (user != null) {
      try {
        final mealsMap = <String, List<Map<String, dynamic>>>{};
        final totals = {
          'calories': log.totalCalories,
          'protein': log.totalProtein,
          'carbs': log.totalCarbs,
          'fat': log.totalFat,
          'fiber': log.totalFiber,
          'sodiumMg': log.totalSodium,
          'sugarG': log.totalSugar,
        };

        for (final meal in log.meals) {
          mealsMap[meal.type.name] = meal.foods
              .map(
                (food) => {
                  'id': food.id,
                  'name': food.name,
                  'servingSize': food.servingSize,
                  'servingUnit': food.servingUnit,
                  'imagePath': food.imagePath,
                  'notes': food.notes,
                  'confidence': food.confidence,
                  'isManuallyEdited': food.isManuallyEdited,
                  'aiExplanation': food.aiExplanation,
                  'healthFlags': food.healthFlags,
                  'nutrition': {
                    'calories': food.calories,
                    'protein': food.protein,
                    'carbs': food.carbs,
                    'fat': food.fat,
                    'fiber': food.fiber,
                    'sodiumMg': food.sodiumMg,
                    'sugarGrams': food.sugarGrams,
                    'cholesterolMg': food.cholesterolMg,
                    'saturatedFatGrams': food.saturatedFatGrams,
                    'transFatGrams': food.transFatGrams,
                    'potassiumMg': food.potassiumMg,
                    'ironMg': food.ironMg,
                    'calciumMg': food.calciumMg,
                    'vitaminAPercent': food.vitaminAPercent,
                    'vitaminCPercent': food.vitaminCPercent,
                    'glycemicIndex': food.glycemicIndex,
                    'glycemicLoad': food.glycemicLoad,
                    'healthScore': food.healthScore,
                  },
                },
              )
              .toList();
        }

        debugPrint(
          '[FoodLogProvider] Syncing to Firestore: meals=${mealsMap.length}, totals=$totals',
        );
        await FirebaseService.saveFoodLog(
          userId: user.uid,
          date: dateKey,
          meals: mealsMap,
          totals: totals,
        );
        debugPrint('[FoodLogProvider] Successfully synced to Firestore');
      } catch (e) {
        debugPrint('[FoodLogProvider] Firestore sync failed: $e');
      }
    }
  }

  Future<void> addFoodToMeal(
    MealType mealType,
    FoodItem food, {
    DateTime? date,
  }) async {
    final targetDate = date ?? DateTime.now();
    final log = await getOrCreateLog(targetDate);

    final meal = log.getMeal(mealType) ?? Meal.empty(mealType);
    final updatedMeal = meal.addFood(food);

    DailyLog updatedLog;
    if (log.meals.any((m) => m.type == mealType)) {
      updatedLog = log.updateMeal(updatedMeal);
    } else {
      updatedLog = log.addMeal(updatedMeal);
    }

    await _saveLog(updatedLog);
  }

  Future<void> addMultipleFoodsToMeal(
    MealType mealType,
    List<FoodItem> foods, {
    DateTime? date,
  }) async {
    final targetDate = date ?? DateTime.now();
    final log = await getOrCreateLog(targetDate);

    final meal = log.getMeal(mealType) ?? Meal.empty(mealType);
    var updatedMeal = meal;
    for (final food in foods) {
      updatedMeal = updatedMeal.addFood(food);
    }

    DailyLog updatedLog;
    if (log.meals.any((m) => m.type == mealType)) {
      updatedLog = log.updateMeal(updatedMeal);
    } else {
      updatedLog = log.addMeal(updatedMeal);
    }

    await _saveLog(updatedLog);
  }

  Future<void> removeFoodFromMeal(
    MealType mealType,
    String foodId, {
    DateTime? date,
  }) async {
    final targetDate = date ?? DateTime.now();
    final log = await getOrCreateLog(targetDate);

    final meal = log.getMeal(mealType);
    if (meal == null) return;

    final updatedMeal = meal.removeFood(foodId);
    final updatedLog = log.updateMeal(updatedMeal);

    await _saveLog(updatedLog);
  }

  Future<void> updateFood(
    MealType mealType,
    FoodItem updatedFood, {
    DateTime? date,
  }) async {
    final targetDate = date ?? DateTime.now();
    final log = await getOrCreateLog(targetDate);

    final meal = log.getMeal(mealType);
    if (meal == null) return;

    final updatedMeal = meal.updateFood(updatedFood);
    final updatedLog = log.updateMeal(updatedMeal);

    await _saveLog(updatedLog);
  }

  Future<void> updateWeight(double weightKg, {DateTime? date}) async {
    final targetDate = date ?? DateTime.now();
    final log = await getOrCreateLog(targetDate);

    final updatedLog = log.copyWith(weightKg: weightKg);
    await _saveLog(updatedLog);
  }

  Future<void> updateWater(int glasses, {DateTime? date}) async {
    final targetDate = date ?? DateTime.now();
    final log = await getOrCreateLog(targetDate);

    final updatedLog = log.copyWith(waterGlasses: glasses);
    await _saveLog(updatedLog);
  }

  Future<void> updateExercise(int minutes, {DateTime? date}) async {
    final targetDate = date ?? DateTime.now();
    final log = await getOrCreateLog(targetDate);

    final updatedLog = log.copyWith(exerciseMinutes: minutes);
    await _saveLog(updatedLog);
  }

  Future<List<DailyLog>> getLogsForDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final logs = <DailyLog>[];
    var current = start;
    final user = FirebaseService.currentUser;

    while (!current.isAfter(end)) {
      final dateKey = _getDateKey(current);

      // Try to load from cache first
      DailyLog? log;

      if (dateKey == _getDateKey(DateTime.now()) && state.todayLog != null) {
        log = state.todayLog;
      } else if (state.logHistory.containsKey(dateKey)) {
        log = state.logHistory[dateKey];
      } else {
        // Try local storage
        final localData = StorageService.getFoodLog(dateKey);
        if (localData != null) {
          log = DailyLog.fromJson(localData);
          state = state.copyWith(
            logHistory: {...state.logHistory, dateKey: log},
          );
        } else if (user != null) {
          // Try Firebase
          try {
            final firestoreData = await FirebaseService.getFoodLog(
              user.uid,
              dateKey,
            );
            if (firestoreData != null) {
              log = _logFromFirestore(dateKey, firestoreData);
              state = state.copyWith(
                logHistory: {...state.logHistory, dateKey: log},
              );
              await StorageService.saveFoodLog(dateKey, log.toJson());
            }
          } catch (e) {
            debugPrint(
              '[FoodLogProvider] Failed to load $dateKey from Firestore: $e',
            );
          }
        }
      }

      // Only add logs that have actual data
      if (log != null && log.meals.isNotEmpty) {
        logs.add(log);
      }

      current = current.add(const Duration(days: 1));
    }

    return logs;
  }

  List<String> getAllLogDates() {
    return StorageService.getAllFoodLogDates();
  }
}

/// Provider for food log
final foodLogProvider = StateNotifierProvider<FoodLogNotifier, DailyLogState>((
  ref,
) {
  return FoodLogNotifier();
});

/// Provider for today's calorie total
final todayCaloriesProvider = Provider<double>((ref) {
  final state = ref.watch(foodLogProvider);
  return state.todayLog?.totalCalories ?? 0;
});

/// Provider for today's macro totals
final todayMacrosProvider = Provider<Map<String, double>>((ref) {
  final state = ref.watch(foodLogProvider);
  final log = state.todayLog;

  return {
    'calories': log?.totalCalories ?? 0,
    'protein': log?.totalProtein ?? 0,
    'carbs': log?.totalCarbs ?? 0,
    'fat': log?.totalFat ?? 0,
    'fiber': log?.totalFiber ?? 0,
    'sodium': log?.totalSodium ?? 0,
    'sugar': log?.totalSugar ?? 0,
  };
});

/// Provider for selected date macro totals
final selectedDateMacrosProvider = Provider<Map<String, double>>((ref) {
  final state = ref.watch(foodLogProvider);
  final log = state.currentLog;

  return {
    'calories': log?.totalCalories ?? 0,
    'protein': log?.totalProtein ?? 0,
    'carbs': log?.totalCarbs ?? 0,
    'fat': log?.totalFat ?? 0,
    'fiber': log?.totalFiber ?? 0,
    'sodium': log?.totalSodium ?? 0,
    'sugar': log?.totalSugar ?? 0,
  };
});
