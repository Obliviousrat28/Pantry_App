//Price and availability information for one ingredient in a recipe.
class RecipeIngredientCost {
  final String ingredient;
  final bool inInventory;
  final double? estimatedCost;
  final double? estimatedPurchaseCost;
  final String priceSource;
  final bool priceUnknown;

  const RecipeIngredientCost({
    required this.ingredient,
    required this.inInventory,
    required this.estimatedCost,
    required this.estimatedPurchaseCost,
    required this.priceSource,
    required this.priceUnknown,
  });

  factory RecipeIngredientCost.fromJson(Map<String, dynamic> json) {
    double? readPrice(dynamic value) {
      if (value == null) return null;
      final price = value is num ? value.toDouble() : double.tryParse(value.toString());
      return price != null && price >= 0 ? price : null;
    }

    return RecipeIngredientCost(
      ingredient: json['ingredient']?.toString() ?? '',
      inInventory: json['inInventory'] == true,
      estimatedCost: readPrice(json['estimatedCost']),
      estimatedPurchaseCost: readPrice(json['estimatedPurchaseCost']),
      priceSource: json['priceSource']?.toString() ?? 'unavailable',
      priceUnknown: json['priceUnknown'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
    'ingredient': ingredient,
    'inInventory': inInventory,
    'estimatedCost': estimatedCost,
    'estimatedPurchaseCost': estimatedPurchaseCost,
    'priceSource': priceSource,
    'priceUnknown': priceUnknown,
  };
}

class Recipe {
  final String title;
  final String description;
  final int prepTime;
  final int calories;
  final int protein;
  final List<String> ingredients;
  final List<String> instructions;
  final String sourceType;
  final String sourceName;
  final String sourceUrl;
  final String imageUrl;
  final double estimatedCost;
  final double estimatedPurchaseCost;
  final double overBudgetAmount;
  final List<RecipeIngredientCost> ingredientCosts;
  final bool hasUnknownPrices;
  final bool hasUnknownPurchasePrices;
  final double? remainingBudget;
  final String budgetStatus;

  bool get hasIngredientCostBreakdown =>
      ingredientCosts.isNotEmpty && ingredientCosts.length == ingredients.length;

  Recipe({
    required this.title,
    required this.description,
    required this.prepTime,
    required this.calories,
    required this.protein,
    required this.ingredients,
    required this.instructions,
    this.sourceType = 'ai',
    this.sourceName = 'AI Generated',
    this.sourceUrl = '',
    this.imageUrl = '',
    this.estimatedCost = 0.0,
    this.estimatedPurchaseCost = 0.0,
    this.overBudgetAmount = 0.0,
    this.ingredientCosts = const [],
    this.hasUnknownPrices = false,
    this.hasUnknownPurchasePrices = false,
    this.remainingBudget,
    this.budgetStatus = '',
  });

  //Returns true when the recipe comes from a real recipe database
  bool get isRealRecipe => sourceType == 'real';

  //Returns true when the recipe was created by AI
  bool get isAiRecipe => sourceType == 'ai';

  //Creates a Recipe object from JSON data
  factory Recipe.fromJson(Map<String, dynamic> json) {
    final sourceType = json['sourceType']?.toString() ?? 'ai';
    final rawCosts = json['ingredientCosts'] as List<dynamic>? ?? [];
    //Older server responses contain prices but no inventory status. Do not
    //incorrectly label all their ingredients as missing from inventory.
    final hasAvailabilityData = rawCosts.isNotEmpty && rawCosts.every(
      (row) => row is Map && row.containsKey('inInventory'),
    );

    return Recipe(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      prepTime: (json['prepTime'] as num?)?.toInt() ?? 0,
      calories: (json['calories'] as num?)?.toInt() ?? 0,
      protein: (json['protein'] as num?)?.toInt() ?? 0,
      ingredients: List<String>.from(json['ingredients'] ?? []),
      instructions: List<String>.from(json['instructions'] ?? []),
      sourceType: sourceType,
      sourceName: json['sourceName']?.toString() ??
          (sourceType == 'real' ? 'Real Recipe' : 'AI Generated'),
      sourceUrl: json['sourceUrl']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString() ?? '',
      estimatedCost:
          (json['estimatedCost'] as num?)?.toDouble() ?? 0.0,
      estimatedPurchaseCost:
          (json['estimatedPurchaseCost'] as num?)?.toDouble() ?? 0.0,
      overBudgetAmount:
          (json['overBudgetAmount'] as num?)?.toDouble() ?? 0.0,
      ingredientCosts: (hasAvailabilityData ? rawCosts : <dynamic>[])
          .whereType<Map>()
          .map((row) => RecipeIngredientCost.fromJson(
              Map<String, dynamic>.from(row)))
          .toList(),
      hasUnknownPrices: json['hasUnknownPrices'] == true,
      hasUnknownPurchasePrices: json['hasUnknownPurchasePrices'] == true,
      remainingBudget: (json['remainingBudget'] as num?)?.toDouble(),
      budgetStatus: json['budgetStatus']?.toString() ?? '',
    );
  }

  //Converts the Recipe object into JSON data
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'prepTime': prepTime,
      'calories': calories,
      'protein': protein,
      'ingredients': ingredients,
      'instructions': instructions,
      'sourceType': sourceType,
      'sourceName': sourceName,
      'sourceUrl': sourceUrl,
      'imageUrl': imageUrl,
      'estimatedCost': estimatedCost,
      'estimatedPurchaseCost': estimatedPurchaseCost,
      'overBudgetAmount': overBudgetAmount,
      'ingredientCosts': ingredientCosts.map((row) => row.toJson()).toList(),
      'hasUnknownPrices': hasUnknownPrices,
      'hasUnknownPurchasePrices': hasUnknownPurchasePrices,
      'remainingBudget': remainingBudget,
      'budgetStatus': budgetStatus,
    };
  }
}