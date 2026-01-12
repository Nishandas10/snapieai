import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

/// Represents a recipe
class Recipe extends Equatable {
  final String id;
  final String name;
  final String description;
  final String? imageUrl;
  final int prepTimeMinutes;
  final int cookTimeMinutes;
  final int servings;
  final double caloriesPerServing;
  final double proteinPerServing;
  final double carbsPerServing;
  final double fatPerServing;
  final double? fiberPerServing;
  final List<RecipeIngredient> ingredients;
  final List<String> instructions;
  final List<String> tags;
  final List<String> healthConditionsSuitable;
  final List<String> dietarySuitable;
  final String difficulty;
  final double rating;
  final int ratingCount;
  final bool isFavorite;
  final bool isAIGenerated;
  final DateTime? createdAt;

  const Recipe({
    required this.id,
    required this.name,
    this.description = '',
    this.imageUrl,
    this.prepTimeMinutes = 0,
    this.cookTimeMinutes = 0,
    this.servings = 1,
    this.caloriesPerServing = 0,
    this.proteinPerServing = 0,
    this.carbsPerServing = 0,
    this.fatPerServing = 0,
    this.fiberPerServing,
    this.ingredients = const [],
    this.instructions = const [],
    this.tags = const [],
    this.healthConditionsSuitable = const [],
    this.dietarySuitable = const [],
    this.difficulty = 'Easy',
    this.rating = 0,
    this.ratingCount = 0,
    this.isFavorite = false,
    this.isAIGenerated = false,
    this.createdAt,
  });

  int get totalTimeMinutes => prepTimeMinutes + cookTimeMinutes;

  String get totalTimeFormatted {
    final hours = totalTimeMinutes ~/ 60;
    final mins = totalTimeMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${mins}m';
    }
    return '${mins}m';
  }

  Recipe copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    int? prepTimeMinutes,
    int? cookTimeMinutes,
    int? servings,
    double? caloriesPerServing,
    double? proteinPerServing,
    double? carbsPerServing,
    double? fatPerServing,
    double? fiberPerServing,
    List<RecipeIngredient>? ingredients,
    List<String>? instructions,
    List<String>? tags,
    List<String>? healthConditionsSuitable,
    List<String>? dietarySuitable,
    String? difficulty,
    double? rating,
    int? ratingCount,
    bool? isFavorite,
    bool? isAIGenerated,
    DateTime? createdAt,
  }) {
    return Recipe(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      prepTimeMinutes: prepTimeMinutes ?? this.prepTimeMinutes,
      cookTimeMinutes: cookTimeMinutes ?? this.cookTimeMinutes,
      servings: servings ?? this.servings,
      caloriesPerServing: caloriesPerServing ?? this.caloriesPerServing,
      proteinPerServing: proteinPerServing ?? this.proteinPerServing,
      carbsPerServing: carbsPerServing ?? this.carbsPerServing,
      fatPerServing: fatPerServing ?? this.fatPerServing,
      fiberPerServing: fiberPerServing ?? this.fiberPerServing,
      ingredients: ingredients ?? this.ingredients,
      instructions: instructions ?? this.instructions,
      tags: tags ?? this.tags,
      healthConditionsSuitable:
          healthConditionsSuitable ?? this.healthConditionsSuitable,
      dietarySuitable: dietarySuitable ?? this.dietarySuitable,
      difficulty: difficulty ?? this.difficulty,
      rating: rating ?? this.rating,
      ratingCount: ratingCount ?? this.ratingCount,
      isFavorite: isFavorite ?? this.isFavorite,
      isAIGenerated: isAIGenerated ?? this.isAIGenerated,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'prepTimeMinutes': prepTimeMinutes,
      'cookTimeMinutes': cookTimeMinutes,
      'servings': servings,
      'caloriesPerServing': caloriesPerServing,
      'proteinPerServing': proteinPerServing,
      'carbsPerServing': carbsPerServing,
      'fatPerServing': fatPerServing,
      'fiberPerServing': fiberPerServing,
      'ingredients': ingredients.map((i) => i.toJson()).toList(),
      'instructions': instructions,
      'tags': tags,
      'healthConditionsSuitable': healthConditionsSuitable,
      'dietarySuitable': dietarySuitable,
      'difficulty': difficulty,
      'rating': rating,
      'ratingCount': ratingCount,
      'isFavorite': isFavorite,
      'isAIGenerated': isAIGenerated,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'] as String? ?? const Uuid().v4(),
      name: json['name'] as String? ?? 'Recipe',
      description: json['description'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
      prepTimeMinutes: json['prepTimeMinutes'] as int? ?? 0,
      cookTimeMinutes: json['cookTimeMinutes'] as int? ?? 0,
      servings: json['servings'] as int? ?? 1,
      caloriesPerServing: (json['caloriesPerServing'] as num?)?.toDouble() ?? 0,
      proteinPerServing: (json['proteinPerServing'] as num?)?.toDouble() ?? 0,
      carbsPerServing: (json['carbsPerServing'] as num?)?.toDouble() ?? 0,
      fatPerServing: (json['fatPerServing'] as num?)?.toDouble() ?? 0,
      fiberPerServing: (json['fiberPerServing'] as num?)?.toDouble(),
      ingredients:
          (json['ingredients'] as List<dynamic>?)
              ?.map((i) => RecipeIngredient.fromJson(i as Map<String, dynamic>))
              .toList() ??
          [],
      instructions:
          (json['instructions'] as List<dynamic>?)
              ?.map((i) => i as String)
              .toList() ??
          [],
      tags:
          (json['tags'] as List<dynamic>?)?.map((t) => t as String).toList() ??
          [],
      healthConditionsSuitable:
          (json['healthConditionsSuitable'] as List<dynamic>?)
              ?.map((h) => h as String)
              .toList() ??
          [],
      dietarySuitable:
          (json['dietarySuitable'] as List<dynamic>?)
              ?.map((d) => d as String)
              .toList() ??
          [],
      difficulty: json['difficulty'] as String? ?? 'Easy',
      rating: (json['rating'] as num?)?.toDouble() ?? 0,
      ratingCount: json['ratingCount'] as int? ?? 0,
      isFavorite: json['isFavorite'] as bool? ?? false,
      isAIGenerated: json['isAIGenerated'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    description,
    imageUrl,
    prepTimeMinutes,
    cookTimeMinutes,
    servings,
    caloriesPerServing,
    proteinPerServing,
    carbsPerServing,
    fatPerServing,
    fiberPerServing,
    ingredients,
    instructions,
    tags,
    healthConditionsSuitable,
    dietarySuitable,
    difficulty,
    rating,
    ratingCount,
    isFavorite,
    isAIGenerated,
    createdAt,
  ];
}

/// Represents an ingredient in a recipe
class RecipeIngredient extends Equatable {
  final String name;
  final double amount;
  final String unit;
  final String? notes;
  final bool isOptional;

  const RecipeIngredient({
    required this.name,
    required this.amount,
    required this.unit,
    this.notes,
    this.isOptional = false,
  });

  String get displayText {
    final amountStr = amount == amount.toInt()
        ? amount.toInt().toString()
        : amount.toStringAsFixed(1);
    return '$amountStr $unit $name${isOptional ? ' (optional)' : ''}';
  }

  RecipeIngredient copyWith({
    String? name,
    double? amount,
    String? unit,
    String? notes,
    bool? isOptional,
  }) {
    return RecipeIngredient(
      name: name ?? this.name,
      amount: amount ?? this.amount,
      unit: unit ?? this.unit,
      notes: notes ?? this.notes,
      isOptional: isOptional ?? this.isOptional,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'amount': amount,
      'unit': unit,
      'notes': notes,
      'isOptional': isOptional,
    };
  }

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) {
    return RecipeIngredient(
      name: json['name'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
      unit: json['unit'] as String? ?? '',
      notes: json['notes'] as String?,
      isOptional: json['isOptional'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [name, amount, unit, notes, isOptional];
}
