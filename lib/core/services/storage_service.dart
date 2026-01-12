import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/app_config.dart';

/// Service for handling local storage operations
class StorageService {
  StorageService._();

  static late SharedPreferences _prefs;
  static late Box _generalBox;
  static late Box _foodLogsBox;
  static late Box _mealPlansBox;

  /// Initialize storage service
  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _generalBox = await Hive.openBox('general');
    _foodLogsBox = await Hive.openBox('food_logs');
    _mealPlansBox = await Hive.openBox('meal_plans');
  }

  // SharedPreferences methods
  static Future<bool> setBool(String key, bool value) async {
    return await _prefs.setBool(key, value);
  }

  static bool? getBool(String key) {
    return _prefs.getBool(key);
  }

  static Future<bool> setString(String key, String value) async {
    return await _prefs.setString(key, value);
  }

  static String? getString(String key) {
    return _prefs.getString(key);
  }

  static Future<bool> setInt(String key, int value) async {
    return await _prefs.setInt(key, value);
  }

  static int? getInt(String key) {
    return _prefs.getInt(key);
  }

  static Future<bool> setDouble(String key, double value) async {
    return await _prefs.setDouble(key, value);
  }

  static double? getDouble(String key) {
    return _prefs.getDouble(key);
  }

  static Future<bool> remove(String key) async {
    return await _prefs.remove(key);
  }

  // Hive methods for complex objects
  static Future<void> saveObject(String key, Map<String, dynamic> data) async {
    await _generalBox.put(key, jsonEncode(data));
  }

  static Map<String, dynamic>? getObject(String key) {
    final data = _generalBox.get(key);
    if (data != null) {
      return jsonDecode(data) as Map<String, dynamic>;
    }
    return null;
  }

  static Future<void> deleteObject(String key) async {
    await _generalBox.delete(key);
  }

  // Food Logs methods
  static Future<void> saveFoodLog(String date, Map<String, dynamic> log) async {
    await _foodLogsBox.put(date, jsonEncode(log));
  }

  static Map<String, dynamic>? getFoodLog(String date) {
    final data = _foodLogsBox.get(date);
    if (data != null) {
      return jsonDecode(data) as Map<String, dynamic>;
    }
    return null;
  }

  static List<String> getAllFoodLogDates() {
    return _foodLogsBox.keys.cast<String>().toList();
  }

  static Future<void> deleteFoodLog(String date) async {
    await _foodLogsBox.delete(date);
  }

  // Meal Plans methods
  static Future<void> saveMealPlan(
    String weekKey,
    Map<String, dynamic> plan,
  ) async {
    await _mealPlansBox.put(weekKey, jsonEncode(plan));
  }

  static Map<String, dynamic>? getMealPlan(String weekKey) {
    final data = _mealPlansBox.get(weekKey);
    if (data != null) {
      return jsonDecode(data) as Map<String, dynamic>;
    }
    return null;
  }

  // User Profile methods
  static Future<void> saveUserProfile(Map<String, dynamic> profile) async {
    await saveObject(AppConfig.userProfileKey, profile);
  }

  static Map<String, dynamic>? getUserProfile() {
    return getObject(AppConfig.userProfileKey);
  }

  // Onboarding status
  static Future<void> setOnboardingComplete(bool value) async {
    await setBool(AppConfig.onboardingCompleteKey, value);
  }

  static bool isOnboardingComplete() {
    return getBool(AppConfig.onboardingCompleteKey) ?? false;
  }

  // API Key
  static Future<void> saveApiKey(String apiKey) async {
    await setString(AppConfig.apiKeyKey, apiKey);
  }

  static String? getApiKey() {
    return getString(AppConfig.apiKeyKey);
  }

  // Clear all data
  static Future<void> clearAll() async {
    await _prefs.clear();
    await _generalBox.clear();
    await _foodLogsBox.clear();
    await _mealPlansBox.clear();
  }
}
