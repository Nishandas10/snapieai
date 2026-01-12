import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Firebase Service for Authentication, Firestore, Storage, and Cloud Functions
class FirebaseService {
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseStorage _storage = FirebaseStorage.instance;
  static final FirebaseFunctions _functions = FirebaseFunctions.instance;

  // ============ AUTH ============

  /// Get current user
  static User? get currentUser => _auth.currentUser;

  /// Check if user is authenticated
  static bool get isAuthenticated => _auth.currentUser != null;

  /// Auth state stream
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Sign in with email and password
  static Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Sign up with email and password
  static Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Sign in with Google
  static Future<UserCredential?> signInWithGoogle() async {
    try {
      // Trigger the Google Sign-In flow
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

      if (googleUser == null) {
        // User cancelled the sign-in
        return null;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Create a new credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google credential
      return await _auth.signInWithCredential(credential);
    } catch (e) {
      rethrow;
    }
  }

  /// Sign out
  static Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Send password reset email
  static Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  /// Update display name
  static Future<void> updateDisplayName(String name) async {
    await _auth.currentUser?.updateDisplayName(name);
  }

  // ============ FIRESTORE - USER DOCUMENT ============

  /// Get user document reference
  static DocumentReference<Map<String, dynamic>> _userDoc(String userId) {
    return _firestore.collection('users').doc(userId);
  }

  /// Create or update user document with onboarding data
  static Future<void> saveUserData({
    required String userId,
    required Map<String, dynamic> profile,
    required Map<String, dynamic> goals,
    required Map<String, dynamic> health,
    required Map<String, dynamic> preferences,
    required Map<String, dynamic> plan,
  }) async {
    final now = FieldValue.serverTimestamp();

    await _userDoc(userId).set({
      'profile': profile,
      'goals': goals,
      'health': health,
      'preferences': preferences,
      'plan': plan,
      'stats': {
        'currentBMI': _calculateBMI(
          profile['heightCm']?.toDouble() ?? 170,
          profile['weightKg']?.toDouble() ?? 70,
        ),
        'streakDays': 0,
      },
      'settings': {'units': 'metric', 'notifications': true},
      'createdAt': now,
      'updatedAt': now,
    }, SetOptions(merge: true));
  }

  static double _calculateBMI(double heightCm, double weightKg) {
    final heightM = heightCm / 100;
    return weightKg / (heightM * heightM);
  }

  /// Get user data
  static Future<Map<String, dynamic>?> getUserData(String userId) async {
    final doc = await _userDoc(userId).get();
    return doc.data();
  }

  /// Stream user data
  static Stream<DocumentSnapshot<Map<String, dynamic>>> streamUserData(
    String userId,
  ) {
    return _userDoc(userId).snapshots();
  }

  /// Update user profile
  static Future<void> updateUserProfile(
    String userId,
    Map<String, dynamic> data,
  ) async {
    await _userDoc(
      userId,
    ).update({...data, 'updatedAt': FieldValue.serverTimestamp()});
  }

  // ============ FIRESTORE - FOOD LOGS ============

  /// Get food log for a specific date
  static Future<Map<String, dynamic>?> getFoodLog(
    String userId,
    String date,
  ) async {
    final doc = await _userDoc(userId).collection('foodLogs').doc(date).get();
    return doc.data();
  }

  /// Stream food log for a specific date
  static Stream<DocumentSnapshot<Map<String, dynamic>>> streamFoodLog(
    String userId,
    String date,
  ) {
    return _userDoc(userId).collection('foodLogs').doc(date).snapshots();
  }

  /// Save food log for a specific date
  static Future<void> saveFoodLog({
    required String userId,
    required String date,
    required Map<String, dynamic> meals,
    required Map<String, dynamic> totals,
    List<Map<String, dynamic>>? aiWarnings,
  }) async {
    await _userDoc(userId).collection('foodLogs').doc(date).set({
      'meals': meals,
      'totals': totals,
      'aiWarnings': aiWarnings ?? [],
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Add food item to a meal
  static Future<void> addFoodToMeal({
    required String userId,
    required String date,
    required String mealType, // breakfast, lunch, dinner, snacks
    required Map<String, dynamic> foodItem,
  }) async {
    final docRef = _userDoc(userId).collection('foodLogs').doc(date);

    await _firestore.runTransaction((transaction) async {
      final doc = await transaction.get(docRef);

      Map<String, dynamic> data;
      if (doc.exists) {
        data = doc.data()!;
      } else {
        data = {
          'meals': {'breakfast': [], 'lunch': [], 'dinner': [], 'snacks': []},
          'totals': {
            'calories': 0,
            'protein': 0,
            'carbs': 0,
            'fat': 0,
            'fiber': 0,
            'sodiumMg': 0,
            'sugarG': 0,
          },
          'aiWarnings': [],
        };
      }

      // Add food item to meal
      final meals = Map<String, dynamic>.from(data['meals'] ?? {});
      final mealList = List<Map<String, dynamic>>.from(meals[mealType] ?? []);
      mealList.add(foodItem);
      meals[mealType] = mealList;

      // Update totals
      final totals = Map<String, dynamic>.from(data['totals'] ?? {});
      final nutrition = foodItem['nutrition'] as Map<String, dynamic>? ?? {};
      totals['calories'] =
          (totals['calories'] ?? 0) + (nutrition['calories'] ?? 0);
      totals['protein'] =
          (totals['protein'] ?? 0) + (nutrition['protein'] ?? 0);
      totals['carbs'] = (totals['carbs'] ?? 0) + (nutrition['carbs'] ?? 0);
      totals['fat'] = (totals['fat'] ?? 0) + (nutrition['fat'] ?? 0);
      totals['fiber'] = (totals['fiber'] ?? 0) + (nutrition['fiber'] ?? 0);
      totals['sodiumMg'] =
          (totals['sodiumMg'] ?? 0) + (nutrition['sodiumMg'] ?? 0);

      transaction.set(docRef, {
        'meals': meals,
        'totals': totals,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  /// Get recent food logs (last N days)
  static Future<List<Map<String, dynamic>>> getRecentFoodLogs(
    String userId,
    int days,
  ) async {
    final now = DateTime.now();
    final dates = List.generate(days, (i) {
      final date = now.subtract(Duration(days: i));
      return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    });

    final List<Map<String, dynamic>> logs = [];
    for (final date in dates) {
      final log = await getFoodLog(userId, date);
      if (log != null) {
        logs.add({'date': date, ...log});
      }
    }
    return logs;
  }

  // ============ FIRESTORE - BODY LOGS ============

  /// Add body metrics log
  static Future<void> addBodyLog({
    required String userId,
    required double weightKg,
    double? bmi,
    double? bodyFatPercent,
  }) async {
    await _userDoc(userId).collection('bodyLogs').add({
      'weightKg': weightKg,
      'bmi': bmi,
      'bodyFatPercent': bodyFatPercent,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Get recent body logs
  static Future<List<Map<String, dynamic>>> getBodyLogs(
    String userId, {
    int limit = 30,
  }) async {
    final query = await _userDoc(userId)
        .collection('bodyLogs')
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    return query.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  // ============ FIRESTORE - CHAT SESSIONS ============

  /// Create new chat session
  static Future<String> createChatSession({
    required String userId,
    required Map<String, dynamic> context,
  }) async {
    final doc = await _userDoc(userId).collection('chatSessions').add({
      'context': context,
      'messages': [],
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  /// Add message to chat session
  static Future<void> addChatMessage({
    required String userId,
    required String sessionId,
    required String role,
    required String text,
  }) async {
    await _userDoc(userId).collection('chatSessions').doc(sessionId).update({
      'messages': FieldValue.arrayUnion([
        {
          'role': role,
          'text': text,
          'timestamp': DateTime.now().toIso8601String(),
        },
      ]),
    });
  }

  /// Get chat session
  static Future<Map<String, dynamic>?> getChatSession(
    String userId,
    String sessionId,
  ) async {
    final doc = await _userDoc(
      userId,
    ).collection('chatSessions').doc(sessionId).get();
    return doc.data();
  }

  // ============ FIRESTORE - MEAL PLANS ============

  /// Save meal plan
  static Future<void> saveMealPlan({
    required String userId,
    required String week,
    required String goal,
    required int dailyCalories,
    required Map<String, List<String>> days,
  }) async {
    await _userDoc(userId).collection('mealPlans').doc(week).set({
      'week': week,
      'goal': goal,
      'dailyCalories': dailyCalories,
      'days': days,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Get meal plan for a week
  static Future<Map<String, dynamic>?> getMealPlan(
    String userId,
    String week,
  ) async {
    final doc = await _userDoc(userId).collection('mealPlans').doc(week).get();
    return doc.data();
  }

  // ============ FIRESTORE - SAVED RECIPES ============

  /// Save recipe
  static Future<void> saveRecipe({
    required String userId,
    required String recipeId,
    required Map<String, dynamic> recipeData,
  }) async {
    await _userDoc(userId).collection('savedRecipes').doc(recipeId).set({
      ...recipeData,
      'savedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Get saved recipes
  static Future<List<Map<String, dynamic>>> getSavedRecipes(
    String userId,
  ) async {
    final query = await _userDoc(userId).collection('savedRecipes').get();
    return query.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
  }

  // ============ FIRESTORE - AI CORRECTIONS ============

  /// Log AI correction for learning
  static Future<void> logAICorrection({
    required String userId,
    required String originalFood,
    required Map<String, dynamic> aiEstimate,
    required Map<String, dynamic> userCorrection,
    required String source,
  }) async {
    await _userDoc(userId).collection('aiCorrections').add({
      'originalFood': originalFood,
      'aiEstimate': aiEstimate,
      'userCorrection': userCorrection,
      'source': source,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ============ STORAGE ============

  /// Upload food image
  static Future<String> uploadFoodImage({
    required String userId,
    required String date,
    required File imageFile,
    required String foodId,
  }) async {
    final ref = _storage.ref().child(
      'users/$userId/food_images/$date/$foodId.jpg',
    );

    final uploadTask = await ref.putFile(
      imageFile,
      SettableMetadata(contentType: 'image/jpeg'),
    );

    return await uploadTask.ref.getDownloadURL();
  }

  /// Delete food image
  static Future<void> deleteFoodImage({
    required String userId,
    required String date,
    required String foodId,
  }) async {
    try {
      await _storage
          .ref()
          .child('users/$userId/food_images/$date/$foodId.jpg')
          .delete();
    } catch (e) {
      // Image might not exist
    }
  }

  // ============ CLOUD FUNCTIONS ============

  /// Analyze food image with AI
  static Future<Map<String, dynamic>> analyzeFood({
    required String imageBase64,
    String? imageUrl,
    Map<String, dynamic>? userContext,
  }) async {
    final callable = _functions.httpsCallable('analyzeFood');
    final result = await callable.call({
      'imageBase64': imageBase64,
      'imageUrl': imageUrl,
      'userContext': userContext,
    });
    return Map<String, dynamic>.from(result.data);
  }

  /// Chat with AI assistant
  static Future<String> chatWithAI({
    required String message,
    required List<Map<String, String>> history,
    Map<String, dynamic>? userContext,
  }) async {
    final callable = _functions.httpsCallable('chatWithAI');
    final result = await callable.call({
      'message': message,
      'history': history,
      'userContext': userContext,
    });
    return result.data['response'] as String;
  }

  /// Generate meal plan with AI
  static Future<Map<String, dynamic>> generateMealPlan({
    required Map<String, dynamic> userProfile,
    required String goal,
    required int dailyCalories,
  }) async {
    final callable = _functions.httpsCallable('generateMealPlan');
    final result = await callable.call({
      'userProfile': userProfile,
      'goal': goal,
      'dailyCalories': dailyCalories,
    });
    return Map<String, dynamic>.from(result.data);
  }

  /// Generate recipe with AI
  static Future<Map<String, dynamic>> generateRecipe({
    required List<String> ingredients,
    String? mealType,
    int? maxCalories,
    List<String>? dietaryRestrictions,
  }) async {
    final callable = _functions.httpsCallable('generateRecipe');
    final result = await callable.call({
      'ingredients': ingredients,
      'mealType': mealType,
      'maxCalories': maxCalories,
      'dietaryRestrictions': dietaryRestrictions,
    });
    return Map<String, dynamic>.from(result.data);
  }
}
