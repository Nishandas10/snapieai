import 'package:equatable/equatable.dart';

/// Health score breakdown showing points from each category
class HealthScoreBreakdown extends Equatable {
  /// Macro Balance Score (out of 40 points)
  /// - Protein goal achievement
  final double macroBalanceScore;

  /// Glycemic Control Score (out of 30 points)
  /// - Sugar control and low GI foods
  final double glycemicControlScore;

  /// Micronutrient Density Score (out of 20 points)
  /// - Iron, Vitamins, Minerals
  final double micronutrientScore;

  /// Consistency & Goals Score (out of 10 points)
  /// - Daily logging, hitting calorie target, health condition adherence
  final double consistencyScore;

  const HealthScoreBreakdown({
    this.macroBalanceScore = 0,
    this.glycemicControlScore = 0,
    this.micronutrientScore = 0,
    this.consistencyScore = 0,
  });

  /// Total health score (out of 100)
  double get totalScore =>
      macroBalanceScore +
      glycemicControlScore +
      micronutrientScore +
      consistencyScore;

  /// Get score category label - Habit builder focused messaging
  String get categoryLabel {
    final score = totalScore;
    if (score >= 80) return 'Champion! 🏆';
    if (score >= 65) return 'Great Progress! 💪';
    if (score >= 50) return 'Building Momentum! 🚀';
    if (score >= 30) return 'Good Start! 🌱';
    return 'Let\'s Get Started! ✨';
  }

  /// Get score category color name
  String get categoryColorName {
    final score = totalScore;
    if (score >= 80) return 'green';
    if (score >= 50) return 'yellow';
    return 'red';
  }

  HealthScoreBreakdown copyWith({
    double? macroBalanceScore,
    double? glycemicControlScore,
    double? micronutrientScore,
    double? consistencyScore,
  }) {
    return HealthScoreBreakdown(
      macroBalanceScore: macroBalanceScore ?? this.macroBalanceScore,
      glycemicControlScore: glycemicControlScore ?? this.glycemicControlScore,
      micronutrientScore: micronutrientScore ?? this.micronutrientScore,
      consistencyScore: consistencyScore ?? this.consistencyScore,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'macroBalanceScore': macroBalanceScore,
      'glycemicControlScore': glycemicControlScore,
      'micronutrientScore': micronutrientScore,
      'consistencyScore': consistencyScore,
      'totalScore': totalScore,
    };
  }

  factory HealthScoreBreakdown.fromJson(Map<String, dynamic> json) {
    return HealthScoreBreakdown(
      macroBalanceScore: (json['macroBalanceScore'] as num?)?.toDouble() ?? 0,
      glycemicControlScore:
          (json['glycemicControlScore'] as num?)?.toDouble() ?? 0,
      micronutrientScore: (json['micronutrientScore'] as num?)?.toDouble() ?? 0,
      consistencyScore: (json['consistencyScore'] as num?)?.toDouble() ?? 0,
    );
  }

  @override
  List<Object?> get props => [
    macroBalanceScore,
    glycemicControlScore,
    micronutrientScore,
    consistencyScore,
  ];
}

/// Represents a day's health score with breakdown and suggestions
class DailyHealthScore extends Equatable {
  final String dateKey;
  final DateTime date;
  final HealthScoreBreakdown breakdown;
  final List<String> improvements;
  final List<HealthScoreSuggestion> suggestions;
  final int streak;
  final double? yesterdayScore;

  const DailyHealthScore({
    required this.dateKey,
    required this.date,
    required this.breakdown,
    this.improvements = const [],
    this.suggestions = const [],
    this.streak = 0,
    this.yesterdayScore,
  });

  double get totalScore => breakdown.totalScore;

  String get scoreLabel => breakdown.categoryLabel;

  DailyHealthScore copyWith({
    String? dateKey,
    DateTime? date,
    HealthScoreBreakdown? breakdown,
    List<String>? improvements,
    List<HealthScoreSuggestion>? suggestions,
    int? streak,
    double? yesterdayScore,
  }) {
    return DailyHealthScore(
      dateKey: dateKey ?? this.dateKey,
      date: date ?? this.date,
      breakdown: breakdown ?? this.breakdown,
      improvements: improvements ?? this.improvements,
      suggestions: suggestions ?? this.suggestions,
      streak: streak ?? this.streak,
      yesterdayScore: yesterdayScore ?? this.yesterdayScore,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'dateKey': dateKey,
      'date': date.toIso8601String(),
      'breakdown': breakdown.toJson(),
      'improvements': improvements,
      'suggestions': suggestions.map((s) => s.toJson()).toList(),
      'streak': streak,
      'yesterdayScore': yesterdayScore,
    };
  }

  factory DailyHealthScore.fromJson(Map<String, dynamic> json) {
    return DailyHealthScore(
      dateKey: json['dateKey'] as String,
      date: DateTime.parse(json['date'] as String),
      breakdown: HealthScoreBreakdown.fromJson(
        json['breakdown'] as Map<String, dynamic>,
      ),
      improvements: List<String>.from(json['improvements'] ?? []),
      suggestions:
          (json['suggestions'] as List<dynamic>?)
              ?.map(
                (s) =>
                    HealthScoreSuggestion.fromJson(s as Map<String, dynamic>),
              )
              .toList() ??
          [],
      streak: json['streak'] as int? ?? 0,
      yesterdayScore: (json['yesterdayScore'] as num?)?.toDouble(),
    );
  }

  factory DailyHealthScore.empty(DateTime date) {
    final dateKey =
        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    return DailyHealthScore(
      dateKey: dateKey,
      date: date,
      breakdown: const HealthScoreBreakdown(),
    );
  }

  @override
  List<Object?> get props => [
    dateKey,
    date,
    breakdown,
    improvements,
    suggestions,
    streak,
    yesterdayScore,
  ];
}

/// A suggestion to improve health score
class HealthScoreSuggestion extends Equatable {
  final String category;
  final String title;
  final String description;
  final String foodSuggestion;
  final int potentialPoints;
  final String icon;

  const HealthScoreSuggestion({
    required this.category,
    required this.title,
    required this.description,
    required this.foodSuggestion,
    required this.potentialPoints,
    this.icon = '💡',
  });

  Map<String, dynamic> toJson() {
    return {
      'category': category,
      'title': title,
      'description': description,
      'foodSuggestion': foodSuggestion,
      'potentialPoints': potentialPoints,
      'icon': icon,
    };
  }

  factory HealthScoreSuggestion.fromJson(Map<String, dynamic> json) {
    return HealthScoreSuggestion(
      category: json['category'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      foodSuggestion: json['foodSuggestion'] as String,
      potentialPoints: json['potentialPoints'] as int,
      icon: json['icon'] as String? ?? '💡',
    );
  }

  @override
  List<Object?> get props => [
    category,
    title,
    description,
    foodSuggestion,
    potentialPoints,
    icon,
  ];
}
