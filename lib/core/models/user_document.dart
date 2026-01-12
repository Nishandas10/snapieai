import 'package:cloud_firestore/cloud_firestore.dart';

/// User profile information
class UserProfile {
  final int age;
  final String gender;
  final double heightCm;
  final double weightKg;

  UserProfile({
    required this.age,
    required this.gender,
    required this.heightCm,
    required this.weightKg,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      age: json['age'] ?? 0,
      gender: json['gender'] ?? '',
      heightCm: (json['heightCm'] ?? 0).toDouble(),
      weightKg: (json['weightKg'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'age': age,
      'gender': gender,
      'heightCm': heightCm,
      'weightKg': weightKg,
    };
  }
}

/// User goals
class UserGoals {
  final String type; // lose_fat, gain_muscle, maintain
  final double? targetWeightKg;
  final double? weeklyGoalKg;

  UserGoals({required this.type, this.targetWeightKg, this.weeklyGoalKg});

  factory UserGoals.fromJson(Map<String, dynamic> json) {
    return UserGoals(
      type: json['type'] ?? 'maintain',
      targetWeightKg: (json['targetWeightKg'])?.toDouble(),
      weeklyGoalKg: (json['weeklyGoalKg'])?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      if (targetWeightKg != null) 'targetWeightKg': targetWeightKg,
      if (weeklyGoalKg != null) 'weeklyGoalKg': weeklyGoalKg,
    };
  }
}

/// Health conditions
class UserHealth {
  final bool bp;
  final bool pcos;
  final bool diabetes;
  final bool cholesterol;

  UserHealth({
    this.bp = false,
    this.pcos = false,
    this.diabetes = false,
    this.cholesterol = false,
  });

  factory UserHealth.fromJson(Map<String, dynamic> json) {
    final conditions = json['conditions'] as Map<String, dynamic>? ?? {};
    return UserHealth(
      bp: conditions['bp'] ?? false,
      pcos: conditions['pcos'] ?? false,
      diabetes: conditions['diabetes'] ?? false,
      cholesterol: conditions['cholesterol'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'conditions': {
        'bp': bp,
        'pcos': pcos,
        'diabetes': diabetes,
        'cholesterol': cholesterol,
      },
    };
  }

  List<String> get activeConditions {
    final conditions = <String>[];
    if (bp) conditions.add('bp');
    if (pcos) conditions.add('pcos');
    if (diabetes) conditions.add('diabetes');
    if (cholesterol) conditions.add('cholesterol');
    return conditions;
  }
}

/// User dietary preferences
class UserPreferences {
  final List<String> dietType;
  final List<String> cuisine;
  final int mealCountPerDay;

  UserPreferences({
    this.dietType = const [],
    this.cuisine = const [],
    this.mealCountPerDay = 3,
  });

  factory UserPreferences.fromJson(Map<String, dynamic> json) {
    return UserPreferences(
      dietType: List<String>.from(json['dietType'] ?? []),
      cuisine: List<String>.from(json['cuisine'] ?? []),
      mealCountPerDay: json['mealCountPerDay'] ?? 3,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dietType': dietType,
      'cuisine': cuisine,
      'mealCountPerDay': mealCountPerDay,
    };
  }
}

/// Macros breakdown
class Macros {
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;

  Macros({
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.fiber,
  });

  factory Macros.fromJson(Map<String, dynamic> json) {
    return Macros(
      protein: (json['protein'] ?? 0).toDouble(),
      carbs: (json['carbs'] ?? 0).toDouble(),
      fat: (json['fat'] ?? 0).toDouble(),
      fiber: (json['fiber'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'protein': protein, 'carbs': carbs, 'fat': fat, 'fiber': fiber};
  }
}

/// User nutrition plan
class UserPlan {
  final int dailyCalories;
  final Macros macros;
  final int sodiumLimitMg;
  final int giLimit;

  UserPlan({
    required this.dailyCalories,
    required this.macros,
    this.sodiumLimitMg = 2300,
    this.giLimit = 55,
  });

  factory UserPlan.fromJson(Map<String, dynamic> json) {
    return UserPlan(
      dailyCalories: json['dailyCalories'] ?? 2000,
      macros: Macros.fromJson(json['macros'] ?? {}),
      sodiumLimitMg: json['sodiumLimitMg'] ?? 2300,
      giLimit: json['giLimit'] ?? 55,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dailyCalories': dailyCalories,
      'macros': macros.toJson(),
      'sodiumLimitMg': sodiumLimitMg,
      'giLimit': giLimit,
    };
  }
}

/// User stats
class UserStats {
  final double currentBMI;
  final int streakDays;

  UserStats({this.currentBMI = 0, this.streakDays = 0});

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      currentBMI: (json['currentBMI'] ?? 0).toDouble(),
      streakDays: json['streakDays'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'currentBMI': currentBMI, 'streakDays': streakDays};
  }
}

/// User settings
class UserSettings {
  final String units;
  final bool notifications;

  UserSettings({this.units = 'metric', this.notifications = true});

  factory UserSettings.fromJson(Map<String, dynamic> json) {
    return UserSettings(
      units: json['units'] ?? 'metric',
      notifications: json['notifications'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {'units': units, 'notifications': notifications};
  }
}

/// Complete user document model
class UserDocument {
  final String id;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final UserProfile profile;
  final UserGoals goals;
  final UserHealth health;
  final UserPreferences preferences;
  final UserPlan plan;
  final UserStats stats;
  final UserSettings settings;
  final DateTime createdAt;
  final DateTime updatedAt;

  UserDocument({
    required this.id,
    this.email,
    this.displayName,
    this.photoUrl,
    required this.profile,
    required this.goals,
    required this.health,
    required this.preferences,
    required this.plan,
    required this.stats,
    required this.settings,
    required this.createdAt,
    required this.updatedAt,
  });

  factory UserDocument.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UserDocument(
      id: doc.id,
      email: data['email'],
      displayName: data['displayName'],
      photoUrl: data['photoUrl'],
      profile: UserProfile.fromJson(data['profile'] ?? {}),
      goals: UserGoals.fromJson(data['goals'] ?? {}),
      health: UserHealth.fromJson(data['health'] ?? {}),
      preferences: UserPreferences.fromJson(data['preferences'] ?? {}),
      plan: UserPlan.fromJson(data['plan'] ?? {}),
      stats: UserStats.fromJson(data['stats'] ?? {}),
      settings: UserSettings.fromJson(data['settings'] ?? {}),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'profile': profile.toJson(),
      'goals': goals.toJson(),
      'health': health.toJson(),
      'preferences': preferences.toJson(),
      'plan': plan.toJson(),
      'stats': stats.toJson(),
      'settings': settings.toJson(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  UserDocument copyWith({
    String? email,
    String? displayName,
    String? photoUrl,
    UserProfile? profile,
    UserGoals? goals,
    UserHealth? health,
    UserPreferences? preferences,
    UserPlan? plan,
    UserStats? stats,
    UserSettings? settings,
  }) {
    return UserDocument(
      id: id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      profile: profile ?? this.profile,
      goals: goals ?? this.goals,
      health: health ?? this.health,
      preferences: preferences ?? this.preferences,
      plan: plan ?? this.plan,
      stats: stats ?? this.stats,
      settings: settings ?? this.settings,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}
