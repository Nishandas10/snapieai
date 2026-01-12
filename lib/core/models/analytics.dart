import 'package:equatable/equatable.dart';

/// Chat message model
class ChatMessage extends Equatable {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final bool isLoading;
  final String? error;

  const ChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.isLoading = false,
    this.error,
  });

  ChatMessage copyWith({
    String? id,
    String? content,
    bool? isUser,
    DateTime? timestamp,
    bool? isLoading,
    String? error,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      content: content ?? this.content,
      isUser: isUser ?? this.isUser,
      timestamp: timestamp ?? this.timestamp,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'content': content,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
      'isLoading': isLoading,
      'error': error,
    };
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      content: json['content'] as String,
      isUser: json['isUser'] as bool,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isLoading: json['isLoading'] as bool? ?? false,
      error: json['error'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, content, isUser, timestamp, isLoading, error];
}

/// Analytics data model
class AnalyticsData extends Equatable {
  final DateTime date;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double? weight;
  final double? calorieTarget;
  final int streak;
  final double adherenceScore;

  const AnalyticsData({
    required this.date,
    this.calories = 0,
    this.protein = 0,
    this.carbs = 0,
    this.fat = 0,
    this.weight,
    this.calorieTarget,
    this.streak = 0,
    this.adherenceScore = 0,
  });

  double get calorieProgress => calorieTarget != null && calorieTarget! > 0
      ? calories / calorieTarget!
      : 0;

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'weight': weight,
      'calorieTarget': calorieTarget,
      'streak': streak,
      'adherenceScore': adherenceScore,
    };
  }

  factory AnalyticsData.fromJson(Map<String, dynamic> json) {
    return AnalyticsData(
      date: DateTime.parse(json['date'] as String),
      calories: (json['calories'] as num?)?.toDouble() ?? 0,
      protein: (json['protein'] as num?)?.toDouble() ?? 0,
      carbs: (json['carbs'] as num?)?.toDouble() ?? 0,
      fat: (json['fat'] as num?)?.toDouble() ?? 0,
      weight: (json['weight'] as num?)?.toDouble(),
      calorieTarget: (json['calorieTarget'] as num?)?.toDouble(),
      streak: json['streak'] as int? ?? 0,
      adherenceScore: (json['adherenceScore'] as num?)?.toDouble() ?? 0,
    );
  }

  @override
  List<Object?> get props => [
    date,
    calories,
    protein,
    carbs,
    fat,
    weight,
    calorieTarget,
    streak,
    adherenceScore,
  ];
}

/// Weight entry model
class WeightEntry extends Equatable {
  final String id;
  final DateTime date;
  final double weightKg;
  final String? notes;

  const WeightEntry({
    required this.id,
    required this.date,
    required this.weightKg,
    this.notes,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'weightKg': weightKg,
      'notes': notes,
    };
  }

  factory WeightEntry.fromJson(Map<String, dynamic> json) {
    return WeightEntry(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      weightKg: (json['weightKg'] as num).toDouble(),
      notes: json['notes'] as String?,
    );
  }

  @override
  List<Object?> get props => [id, date, weightKg, notes];
}
