import 'package:equatable/equatable.dart';
import 'package:uuid/uuid.dart';

/// Represents a single food item with nutritional information
class FoodItem extends Equatable {
  final String id;
  final String name;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double fiber;
  final double? sodiumMg;
  final double? cholesterolMg;
  final double? saturatedFatGrams;
  final double? sugarGrams;
  final double? potassiumMg;
  final int? glycemicIndex;
  final int? glycemicLoad;
  final double servingSize;
  final String servingUnit;
  final double confidence;
  final String? imagePath;
  final String? notes;
  final List<String> healthFlags;
  final Map<String, dynamic>? micronutrients;
  final bool isManuallyEdited;
  final String? aiExplanation;

  const FoodItem({
    required this.id,
    required this.name,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.fiber = 0,
    this.sodiumMg,
    this.cholesterolMg,
    this.saturatedFatGrams,
    this.sugarGrams,
    this.potassiumMg,
    this.glycemicIndex,
    this.glycemicLoad,
    this.servingSize = 1,
    this.servingUnit = 'serving',
    this.confidence = 1.0,
    this.imagePath,
    this.notes,
    this.healthFlags = const [],
    this.micronutrients,
    this.isManuallyEdited = false,
    this.aiExplanation,
  });

  double get totalMacroGrams => protein + carbs + fat;
  double get proteinPercentage => (protein * 4 / calories) * 100;
  double get carbsPercentage => (carbs * 4 / calories) * 100;
  double get fatPercentage => (fat * 9 / calories) * 100;

  bool get isHighSodium => (sodiumMg ?? 0) > 600;
  bool get isHighGI => (glycemicIndex ?? 0) > 70;
  bool get isHighCholesterol => (cholesterolMg ?? 0) > 100;
  bool get isHighSugar => (sugarGrams ?? 0) > 12;
  bool get isLowProtein => protein < 5;
  bool get isHighFiber => fiber >= 5;

  String get confidenceLabel {
    if (confidence >= 0.9) return 'Very High';
    if (confidence >= 0.8) return 'High';
    if (confidence >= 0.7) return 'Good';
    if (confidence >= 0.5) return 'Moderate';
    return 'Low';
  }

  FoodItem copyWith({
    String? id,
    String? name,
    double? calories,
    double? protein,
    double? carbs,
    double? fat,
    double? fiber,
    double? sodiumMg,
    double? cholesterolMg,
    double? saturatedFatGrams,
    double? sugarGrams,
    double? potassiumMg,
    int? glycemicIndex,
    int? glycemicLoad,
    double? servingSize,
    String? servingUnit,
    double? confidence,
    String? imagePath,
    String? notes,
    List<String>? healthFlags,
    Map<String, dynamic>? micronutrients,
    bool? isManuallyEdited,
    String? aiExplanation,
  }) {
    return FoodItem(
      id: id ?? this.id,
      name: name ?? this.name,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      fiber: fiber ?? this.fiber,
      sodiumMg: sodiumMg ?? this.sodiumMg,
      cholesterolMg: cholesterolMg ?? this.cholesterolMg,
      saturatedFatGrams: saturatedFatGrams ?? this.saturatedFatGrams,
      sugarGrams: sugarGrams ?? this.sugarGrams,
      potassiumMg: potassiumMg ?? this.potassiumMg,
      glycemicIndex: glycemicIndex ?? this.glycemicIndex,
      glycemicLoad: glycemicLoad ?? this.glycemicLoad,
      servingSize: servingSize ?? this.servingSize,
      servingUnit: servingUnit ?? this.servingUnit,
      confidence: confidence ?? this.confidence,
      imagePath: imagePath ?? this.imagePath,
      notes: notes ?? this.notes,
      healthFlags: healthFlags ?? this.healthFlags,
      micronutrients: micronutrients ?? this.micronutrients,
      isManuallyEdited: isManuallyEdited ?? this.isManuallyEdited,
      aiExplanation: aiExplanation ?? this.aiExplanation,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'fiber': fiber,
      'sodiumMg': sodiumMg,
      'cholesterolMg': cholesterolMg,
      'saturatedFatGrams': saturatedFatGrams,
      'sugarGrams': sugarGrams,
      'potassiumMg': potassiumMg,
      'glycemicIndex': glycemicIndex,
      'glycemicLoad': glycemicLoad,
      'servingSize': servingSize,
      'servingUnit': servingUnit,
      'confidence': confidence,
      'imagePath': imagePath,
      'notes': notes,
      'healthFlags': healthFlags,
      'micronutrients': micronutrients,
      'isManuallyEdited': isManuallyEdited,
      'aiExplanation': aiExplanation,
    };
  }

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    return FoodItem(
      id: json['id'] as String? ?? const Uuid().v4(),
      name:
          json['name'] as String? ?? json['food'] as String? ?? 'Unknown Food',
      calories: (json['calories'] as num?)?.toDouble() ?? 0,
      protein: (json['protein'] as num?)?.toDouble() ?? 0,
      carbs: (json['carbs'] as num?)?.toDouble() ?? 0,
      fat: (json['fat'] as num?)?.toDouble() ?? 0,
      fiber: (json['fiber'] as num?)?.toDouble() ?? 0,
      sodiumMg:
          (json['sodiumMg'] as num?)?.toDouble() ??
          (json['sodium_mg'] as num?)?.toDouble(),
      cholesterolMg:
          (json['cholesterolMg'] as num?)?.toDouble() ??
          (json['cholesterol_mg'] as num?)?.toDouble(),
      saturatedFatGrams: (json['saturatedFatGrams'] as num?)?.toDouble(),
      sugarGrams: (json['sugarGrams'] as num?)?.toDouble(),
      potassiumMg: (json['potassiumMg'] as num?)?.toDouble(),
      glycemicIndex:
          (json['glycemicIndex'] as num?)?.toInt() ??
          (json['glycemic_index'] as num?)?.toInt(),
      glycemicLoad:
          (json['glycemicLoad'] as num?)?.toInt() ??
          (json['glycemic_load'] as num?)?.toInt(),
      servingSize: (json['servingSize'] as num?)?.toDouble() ?? 1,
      servingUnit: json['servingUnit'] as String? ?? 'serving',
      confidence: (json['confidence'] as num?)?.toDouble() ?? 1.0,
      imagePath: json['imagePath'] as String?,
      notes: json['notes'] as String?,
      healthFlags:
          (json['healthFlags'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      micronutrients: json['micronutrients'] as Map<String, dynamic>?,
      isManuallyEdited: json['isManuallyEdited'] as bool? ?? false,
      aiExplanation: json['aiExplanation'] as String?,
    );
  }

  factory FoodItem.empty() {
    return FoodItem(
      id: const Uuid().v4(),
      name: '',
      calories: 0,
      protein: 0,
      carbs: 0,
      fat: 0,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    calories,
    protein,
    carbs,
    fat,
    fiber,
    sodiumMg,
    cholesterolMg,
    saturatedFatGrams,
    sugarGrams,
    potassiumMg,
    glycemicIndex,
    glycemicLoad,
    servingSize,
    servingUnit,
    confidence,
    imagePath,
    notes,
    healthFlags,
    micronutrients,
    isManuallyEdited,
    aiExplanation,
  ];
}
