import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/user_profile.dart';
import '../services/storage_service.dart';
import '../services/firebase_service.dart';

/// User profile state notifier
class UserProfileNotifier extends StateNotifier<UserProfile?> {
  UserProfileNotifier() : super(null) {
    _loadProfile();
  }

  void _loadProfile() async {
    // First load from local storage for instant display
    final localData = StorageService.getUserProfile();
    if (localData != null) {
      state = UserProfile.fromJson(localData);
      debugPrint('[UserProvider] Loaded profile from local storage');
    }

    // Then try to load from Firestore if authenticated
    await syncFromFirestore();
  }

  /// Sync profile from Firestore (call after login)
  Future<void> syncFromFirestore() async {
    final user = FirebaseService.currentUser;
    debugPrint('[UserProvider] syncFromFirestore - user: ${user?.uid}');

    if (user != null) {
      try {
        final firestoreData = await FirebaseService.getUserData(user.uid);
        debugPrint('[UserProvider] Firestore data: $firestoreData');

        if (firestoreData != null && firestoreData['profile'] != null) {
          final profile = _profileFromFirestore(firestoreData);
          state = profile;
          // Update local cache
          await StorageService.saveUserProfile(profile.toJson());
          debugPrint('[UserProvider] Profile synced from Firestore');
        }
      } catch (e) {
        debugPrint('[UserProvider] Firestore sync failed: $e');
      }
    }
  }

  /// Sync local profile to Firestore (call after login to upload onboarding data)
  Future<void> syncToFirestore() async {
    final user = FirebaseService.currentUser;
    debugPrint(
      '[UserProvider] syncToFirestore - user: ${user?.uid}, state: $state',
    );

    if (user != null && state != null) {
      try {
        await FirebaseService.saveUserData(
          userId: user.uid,
          profile: {
            'name': state!.name,
            'age': state!.age,
            'gender': state!.gender,
            'heightCm': state!.heightCm,
            'weightKg': state!.weightKg,
            'activityLevel': state!.activityLevel,
            'country': state!.country,
          },
          goals: {'primary': state!.goal},
          health: {'conditions': state!.healthConditions},
          preferences: {'dietary': state!.dietaryPreferences},
          plan: {
            'dailyCalories': state!.dailyCalorieTarget,
            'proteinGrams': state!.macroTargets.proteinGrams,
            'carbsGrams': state!.macroTargets.carbsGrams,
            'fatGrams': state!.macroTargets.fatGrams,
          },
        );
        debugPrint('[UserProvider] Profile synced to Firestore successfully');
      } catch (e) {
        debugPrint('[UserProvider] Firestore save failed: $e');
      }
    }
  }

  UserProfile _profileFromFirestore(Map<String, dynamic> data) {
    final profile = data['profile'] as Map<String, dynamic>? ?? {};
    final goals = data['goals'] as Map<String, dynamic>? ?? {};
    final health = data['health'] as Map<String, dynamic>? ?? {};
    final preferences = data['preferences'] as Map<String, dynamic>? ?? {};
    final plan = data['plan'] as Map<String, dynamic>? ?? {};

    return UserProfile(
      id: FirebaseService.currentUser?.uid ?? const Uuid().v4(),
      name: profile['name'] as String?,
      age: profile['age'] as int?,
      gender: profile['gender'] as String?,
      heightCm: (profile['heightCm'] as num?)?.toDouble(),
      weightKg: (profile['weightKg'] as num?)?.toDouble(),
      activityLevel: (profile['activityLevel'] as String?) ?? 'moderate',
      country: (profile['country'] as String?) ?? 'US',
      goal: (goals['primary'] as String?) ?? 'maintain',
      healthConditions: List<String>.from(health['conditions'] ?? []),
      dietaryPreferences: List<String>.from(preferences['dietary'] ?? []),
      dailyCalorieTarget: (plan['dailyCalories'] as num?)?.toDouble() ?? 2000,
      macroTargets: MacroTargets(
        proteinGrams: (plan['proteinGrams'] as num?)?.toDouble() ?? 100,
        carbsGrams: (plan['carbsGrams'] as num?)?.toDouble() ?? 250,
        fatGrams: (plan['fatGrams'] as num?)?.toDouble() ?? 70,
      ),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  Future<void> saveProfile(UserProfile profile) async {
    state = profile;
    // Save to local storage
    await StorageService.saveUserProfile(profile.toJson());

    // Sync to Firestore if authenticated
    final user = FirebaseService.currentUser;
    if (user != null) {
      try {
        await FirebaseService.saveUserData(
          userId: user.uid,
          profile: {
            'name': profile.name,
            'age': profile.age,
            'gender': profile.gender,
            'heightCm': profile.heightCm,
            'weightKg': profile.weightKg,
            'activityLevel': profile.activityLevel,
            'country': profile.country,
          },
          goals: {'primary': profile.goal},
          health: {'conditions': profile.healthConditions},
          preferences: {'dietary': profile.dietaryPreferences},
          plan: {
            'dailyCalories': profile.dailyCalorieTarget,
            'proteinGrams': profile.macroTargets.proteinGrams,
            'carbsGrams': profile.macroTargets.carbsGrams,
            'fatGrams': profile.macroTargets.fatGrams,
          },
        );
      } catch (e) {
        // Firestore save failed, data is still in local storage
      }
    }
  }

  Future<void> updateProfile({
    String? name,
    int? age,
    String? gender,
    double? heightCm,
    double? weightKg,
    String? activityLevel,
    String? country,
    String? goal,
    List<String>? healthConditions,
    List<String>? dietaryPreferences,
    double? dailyCalorieTarget,
    MacroTargets? macroTargets,
  }) async {
    if (state == null) {
      state = UserProfile(
        id: const Uuid().v4(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }

    final updated = state!.copyWith(
      name: name,
      age: age,
      gender: gender,
      heightCm: heightCm,
      weightKg: weightKg,
      activityLevel: activityLevel,
      country: country,
      goal: goal,
      healthConditions: healthConditions,
      dietaryPreferences: dietaryPreferences,
      dailyCalorieTarget: dailyCalorieTarget,
      macroTargets: macroTargets,
      updatedAt: DateTime.now(),
    );

    await saveProfile(updated);
  }

  Future<void> createNewProfile() async {
    final profile = UserProfile(
      id: const Uuid().v4(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    await saveProfile(profile);
  }

  Future<void> clearProfile() async {
    state = null;
    await StorageService.deleteObject('user_profile');
  }
}

/// Provider for user profile
final userProfileProvider =
    StateNotifierProvider<UserProfileNotifier, UserProfile?>((ref) {
      return UserProfileNotifier();
    });

/// Provider for checking if onboarding is complete
final isOnboardingCompleteProvider = Provider<bool>((ref) {
  return StorageService.isOnboardingComplete();
});
