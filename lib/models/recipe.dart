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
  });

  //Returns true when the recipe comes from a real recipe database
  bool get isRealRecipe => sourceType == 'real';

  //Returns true when the recipe was created by AI
  bool get isAiRecipe => sourceType == 'ai';

  //Creates a Recipe object from JSON data
  factory Recipe.fromJson(Map<String, dynamic> json) {
    final sourceType = json['sourceType']?.toString() ?? 'ai';

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
    };
  }
}
