import 'package:cloud_firestore/cloud_firestore.dart';

/// Body metrics log entry
class BodyLog {
  final String id;
  final double weightKg;
  final double? bmi;
  final double? bodyFatPercent;
  final DateTime createdAt;

  BodyLog({
    required this.id,
    required this.weightKg,
    this.bmi,
    this.bodyFatPercent,
    required this.createdAt,
  });

  factory BodyLog.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return BodyLog(
      id: doc.id,
      weightKg: (data['weightKg'] ?? 0).toDouble(),
      bmi: (data['bmi'])?.toDouble(),
      bodyFatPercent: (data['bodyFatPercent'])?.toDouble(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'weightKg': weightKg,
      if (bmi != null) 'bmi': bmi,
      if (bodyFatPercent != null) 'bodyFatPercent': bodyFatPercent,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}

/// AI correction entry for learning loop
class AICorrection {
  final String id;
  final String? foodLogId;
  final String originalFood;
  final Map<String, dynamic> aiEstimate;
  final Map<String, dynamic> userCorrection;
  final String source;
  final DateTime createdAt;

  AICorrection({
    required this.id,
    this.foodLogId,
    required this.originalFood,
    required this.aiEstimate,
    required this.userCorrection,
    required this.source,
    required this.createdAt,
  });

  factory AICorrection.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return AICorrection(
      id: doc.id,
      foodLogId: data['foodLogId'],
      originalFood: data['originalFood'] ?? '',
      aiEstimate: data['aiEstimate'] ?? {},
      userCorrection: data['userCorrection'] ?? {},
      source: data['source'] ?? 'camera',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      if (foodLogId != null) 'foodLogId': foodLogId,
      'originalFood': originalFood,
      'aiEstimate': aiEstimate,
      'userCorrection': userCorrection,
      'source': source,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}

/// Chat message in a session
class ChatMessage {
  final String role; // user, assistant
  final String text;
  final DateTime timestamp;

  ChatMessage({
    required this.role,
    required this.text,
    required this.timestamp,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      role: json['role'] ?? '',
      text: json['text'] ?? '',
      timestamp: (json['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'role': role,
      'text': text,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}

/// Chat session with AI assistant
class ChatSession {
  final String id;
  final Map<String, dynamic> context;
  final List<ChatMessage> messages;
  final DateTime createdAt;
  final DateTime? updatedAt;

  ChatSession({
    required this.id,
    this.context = const {},
    this.messages = const [],
    required this.createdAt,
    this.updatedAt,
  });

  factory ChatSession.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return ChatSession(
      id: doc.id,
      context: data['context'] ?? {},
      messages:
          (data['messages'] as List<dynamic>?)
              ?.map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'context': context,
      'messages': messages.map((e) => e.toJson()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  ChatSession addMessage(ChatMessage message) {
    return ChatSession(
      id: id,
      context: context,
      messages: [...messages, message],
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

/// Meal plan document
class MealPlan {
  final String id;
  final String week; // e.g., 2026-W02
  final String goal;
  final int dailyCalories;
  final Map<String, List<String>> days; // day -> recipe IDs
  final DateTime createdAt;
  final bool isActive;

  MealPlan({
    required this.id,
    required this.week,
    required this.goal,
    required this.dailyCalories,
    required this.days,
    required this.createdAt,
    this.isActive = false,
  });

  factory MealPlan.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    final daysData = data['days'] as Map<String, dynamic>? ?? {};
    final days = <String, List<String>>{};
    daysData.forEach((key, value) {
      days[key] = List<String>.from(value ?? []);
    });

    return MealPlan(
      id: doc.id,
      week: data['week'] ?? '',
      goal: data['goal'] ?? '',
      dailyCalories: data['dailyCalories'] ?? 2000,
      days: days,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'week': week,
      'goal': goal,
      'dailyCalories': dailyCalories,
      'days': days,
      'createdAt': Timestamp.fromDate(createdAt),
      'isActive': isActive,
    };
  }
}

/// Recipe model
class Recipe {
  final String id;
  final String name;
  final List<String> ingredients;
  final Map<String, dynamic> nutrition;
  final List<String> tags;
  final String? instructions;
  final int? prepTimeMinutes;
  final int? cookTimeMinutes;
  final int? servings;
  final String? imageUrl;

  Recipe({
    required this.id,
    required this.name,
    required this.ingredients,
    required this.nutrition,
    this.tags = const [],
    this.instructions,
    this.prepTimeMinutes,
    this.cookTimeMinutes,
    this.servings,
    this.imageUrl,
  });

  factory Recipe.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return Recipe(
      id: doc.id,
      name: data['name'] ?? '',
      ingredients: List<String>.from(data['ingredients'] ?? []),
      nutrition: data['nutrition'] ?? {},
      tags: List<String>.from(data['tags'] ?? []),
      instructions: data['instructions'],
      prepTimeMinutes: data['prepTimeMinutes'],
      cookTimeMinutes: data['cookTimeMinutes'],
      servings: data['servings'],
      imageUrl: data['imageUrl'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'ingredients': ingredients,
      'nutrition': nutrition,
      'tags': tags,
      if (instructions != null) 'instructions': instructions,
      if (prepTimeMinutes != null) 'prepTimeMinutes': prepTimeMinutes,
      if (cookTimeMinutes != null) 'cookTimeMinutes': cookTimeMinutes,
      if (servings != null) 'servings': servings,
      if (imageUrl != null) 'imageUrl': imageUrl,
    };
  }
}

/// Weekly analytics document
class WeeklyAnalytics {
  final String id; // e.g., weekly_2026-W02
  final double avgCalories;
  final double proteinConsistency;
  final double weightChangeKg;
  final int highSodiumDays;
  final DateTime createdAt;

  WeeklyAnalytics({
    required this.id,
    required this.avgCalories,
    required this.proteinConsistency,
    required this.weightChangeKg,
    required this.highSodiumDays,
    required this.createdAt,
  });

  factory WeeklyAnalytics.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return WeeklyAnalytics(
      id: doc.id,
      avgCalories: (data['avgCalories'] ?? 0).toDouble(),
      proteinConsistency: (data['proteinConsistency'] ?? 0).toDouble(),
      weightChangeKg: (data['weightChangeKg'] ?? 0).toDouble(),
      highSodiumDays: data['highSodiumDays'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'avgCalories': avgCalories,
      'proteinConsistency': proteinConsistency,
      'weightChangeKg': weightChangeKg,
      'highSodiumDays': highSodiumDays,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}

/// Usage analytics
class UsageAnalytics {
  final int totalScans;
  final int totalChatMessages;
  final DateTime? lastScanAt;
  final DateTime? lastChatAt;

  UsageAnalytics({
    this.totalScans = 0,
    this.totalChatMessages = 0,
    this.lastScanAt,
    this.lastChatAt,
  });

  factory UsageAnalytics.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return UsageAnalytics(
      totalScans: data['totalScans'] ?? 0,
      totalChatMessages: data['totalChatMessages'] ?? 0,
      lastScanAt: (data['lastScanAt'] as Timestamp?)?.toDate(),
      lastChatAt: (data['lastChatAt'] as Timestamp?)?.toDate(),
    );
  }
}
