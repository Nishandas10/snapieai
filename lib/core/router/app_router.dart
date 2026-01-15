import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/food_item.dart';
import '../models/daily_log.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/onboarding/presentation/profile_setup_screen.dart';
import '../../features/onboarding/presentation/goals_screen.dart';
import '../../features/onboarding/presentation/health_conditions_screen.dart';
import '../../features/onboarding/presentation/dietary_preferences_screen.dart';
import '../../features/onboarding/presentation/plan_generation_screen.dart';
import '../../features/onboarding/presentation/auth_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/home/presentation/main_navigation_screen.dart';
import '../../features/food_log/presentation/food_log_screen.dart';
import '../../features/food_log/presentation/add_food_screen.dart';
import '../../features/food_log/presentation/food_detail_screen.dart';
import '../../features/camera/presentation/camera_screen.dart';
import '../../features/camera/presentation/analysis_result_screen.dart';
import '../../features/analytics/presentation/analytics_screen.dart';
import '../../features/analytics/presentation/progress_detail_screen.dart';
import '../../features/chat/presentation/chat_screen.dart';
import '../../features/meal_plan/presentation/meal_plan_screen.dart';
import '../../features/meal_plan/presentation/meal_plan_detail_screen.dart';
import '../../features/recipes/presentation/recipes_screen.dart';
import '../../features/recipes/presentation/recipe_detail_screen.dart';
import '../../features/recipes/presentation/recipe_generator_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/settings/presentation/edit_profile_screen.dart';
import '../../features/settings/presentation/goals_targets_screen.dart';
import '../../features/settings/presentation/meal_reminder_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/settings/presentation/health_settings_screen.dart';
import '../../features/history/presentation/history_screen.dart';
import '../../features/subscription/presentation/paywall_screen.dart';

/// Application routes
class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String auth = '/auth';
  static const String profileSetup = '/profile-setup';
  static const String goals = '/goals';
  static const String healthConditions = '/health-conditions';
  static const String dietaryPreferences = '/dietary-preferences';
  static const String planGeneration = '/plan-generation';
  static const String main = '/main';
  static const String home = '/home';
  static const String foodLog = '/food-log';
  static const String addFood = '/add-food';
  static const String foodDetail = '/food-detail';
  static const String camera = '/camera';
  static const String analysisResult = '/analysis-result';
  static const String analytics = '/analytics';
  static const String progressDetail = '/progress-detail';
  static const String chat = '/chat';
  static const String mealPlan = '/meal-plan';
  static const String mealPlanDetail = '/meal-plan-detail';
  static const String recipes = '/recipes';
  static const String recipeDetail = '/recipe-detail';
  static const String smartRecipeGenerator = '/smart-recipe-generator';
  static const String settings = '/settings';
  static const String editProfile = '/edit-profile';
  static const String goalsTargets = '/goals-targets';
  static const String mealReminders = '/meal-reminders';
  static const String profile = '/profile';
  static const String healthSettings = '/health-settings';
  static const String history = '/history';
  static const String paywall = '/paywall';
}

/// Provider for GoRouter
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.profileSetup,
        name: 'profileSetup',
        builder: (context, state) => const ProfileSetupScreen(),
      ),
      GoRoute(
        path: AppRoutes.goals,
        name: 'goals',
        builder: (context, state) => const GoalsScreen(),
      ),
      GoRoute(
        path: AppRoutes.healthConditions,
        name: 'healthConditions',
        builder: (context, state) => const HealthConditionsScreen(),
      ),
      GoRoute(
        path: AppRoutes.dietaryPreferences,
        name: 'dietaryPreferences',
        builder: (context, state) => const DietaryPreferencesScreen(),
      ),
      GoRoute(
        path: AppRoutes.planGeneration,
        name: 'planGeneration',
        builder: (context, state) => const PlanGenerationScreen(),
      ),
      GoRoute(
        path: AppRoutes.auth,
        name: 'auth',
        builder: (context, state) {
          // Check if we should show signup screen (coming from onboarding)
          final showSignup = state.uri.queryParameters['signup'] == 'true';
          return AuthScreen(initialShowLogin: !showSignup);
        },
      ),
      ShellRoute(
        builder: (context, state, child) => MainNavigationScreen(child: child),
        routes: [
          GoRoute(
            path: AppRoutes.home,
            name: 'home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: AppRoutes.foodLog,
            name: 'foodLog',
            builder: (context, state) {
              final tabIndex = state.extra as int? ?? 0;
              return FoodLogScreen(initialTabIndex: tabIndex);
            },
          ),
          GoRoute(
            path: AppRoutes.analytics,
            name: 'analytics',
            builder: (context, state) => const AnalyticsScreen(),
          ),
          GoRoute(
            path: AppRoutes.mealPlan,
            name: 'mealPlan',
            builder: (context, state) => const MealPlanScreen(),
          ),
          GoRoute(
            path: AppRoutes.settings,
            name: 'settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.addFood,
        name: 'addFood',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return AddFoodScreen(
            initialMealType: extra?['mealType'] as MealType?,
          );
        },
      ),
      GoRoute(
        path: '${AppRoutes.foodDetail}/:id',
        name: 'foodDetail',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return FoodDetailScreen(
            foodId: state.pathParameters['id']!,
            food: extra?['food'] as FoodItem?,
            mealType: extra?['mealType'] as MealType?,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.camera,
        name: 'camera',
        builder: (context, state) => const CameraScreen(),
      ),
      GoRoute(
        path: AppRoutes.analysisResult,
        name: 'analysisResult',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return AnalysisResultScreen(
            imagePath: extra?['imagePath'] as String?,
            analysisData: extra?['analysisData'] as Map<String, dynamic>?,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.progressDetail,
        name: 'progressDetail',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return ProgressDetailScreen(
            metricType: extra?['metricType'] as String? ?? 'weight',
          );
        },
      ),
      GoRoute(
        path: AppRoutes.chat,
        name: 'chat',
        builder: (context, state) => const ChatScreen(),
      ),
      GoRoute(
        path: '${AppRoutes.mealPlanDetail}/:day',
        name: 'mealPlanDetail',
        builder: (context, state) =>
            MealPlanDetailScreen(day: state.pathParameters['day']!),
      ),
      GoRoute(
        path: AppRoutes.recipes,
        name: 'recipes',
        builder: (context, state) => const RecipesScreen(),
      ),
      GoRoute(
        path: '${AppRoutes.recipeDetail}/:id',
        name: 'recipeDetail',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return RecipeDetailScreen(recipe: extra);
        },
      ),
      GoRoute(
        path: AppRoutes.smartRecipeGenerator,
        name: 'smartRecipeGenerator',
        builder: (context, state) => const RecipeGeneratorScreen(),
      ),
      GoRoute(
        path: AppRoutes.profile,
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.healthSettings,
        name: 'healthSettings',
        builder: (context, state) => const HealthSettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.editProfile,
        name: 'editProfile',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.goalsTargets,
        name: 'goalsTargets',
        builder: (context, state) => const GoalsTargetsScreen(),
      ),
      GoRoute(
        path: AppRoutes.mealReminders,
        name: 'mealReminders',
        builder: (context, state) => const MealReminderScreen(),
      ),
      GoRoute(
        path: AppRoutes.history,
        name: 'history',
        builder: (context, state) => const HistoryScreen(),
      ),
      GoRoute(
        path: AppRoutes.paywall,
        name: 'paywall',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return PaywallScreen(featureType: extra?['featureType'] as String?);
        },
      ),
    ],
    redirect: (context, state) {
      // Add any global redirects here
      return null;
    },
    errorBuilder: (context, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.uri.path}')),
    ),
  );
});
