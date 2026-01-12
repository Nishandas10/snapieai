/// Application configuration constants
class AppConfig {
  AppConfig._();

  // App Info
  static const String appName = 'SnapieAI';
  static const String appVersion = '1.0.0';
  static const String appBuildNumber = '101';

  // API Configuration
  static const String openAIBaseUrl = 'https://api.openai.com/v1';
  static const String openAIModel = 'gpt-4o-mini';

  // Storage Keys
  static const String userProfileKey = 'user_profile';
  static const String onboardingCompleteKey = 'onboarding_complete';
  static const String foodLogsKey = 'food_logs';
  static const String mealPlansKey = 'meal_plans';
  static const String healthConditionsKey = 'health_conditions';
  static const String apiKeyKey = 'openai_api_key';

  // Default Values
  static const double defaultCalorieTarget = 2000;
  static const double defaultProteinPercentage = 0.30;
  static const double defaultCarbsPercentage = 0.40;
  static const double defaultFatPercentage = 0.30;

  // Validation
  static const int minAge = 13;
  static const int maxAge = 120;
  static const double minHeight = 100; // cm
  static const double maxHeight = 250; // cm
  static const double minWeight = 30; // kg
  static const double maxWeight = 300; // kg

  // AI Analysis
  static const double confidenceThreshold = 0.7;
  static const int maxFoodItemsPerScan = 10;
}
