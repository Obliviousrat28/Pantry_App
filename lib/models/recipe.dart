class Recipe {
  final String title;
  final String description;
  final int prepTime;
  final int calories;
  final int protein;
  final List<String> ingredients;
  final List<String> instructions;

  Recipe({
    required this.title,
    required this.description,
    required this.prepTime,
    required this.calories,
    required this.protein,
    required this.ingredients,
    required this.instructions,
  });

  //Creates a Recipe object from JSON data
  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      prepTime: json['prepTime'] ?? 0,
      calories: json['calories'] ?? 0,
      protein: json['protein'] ?? 0,
      ingredients: List<String>.from(json['ingredients'] ?? []),
      instructions: List<String>.from(json['instructions'] ?? []),
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
    };
  }
}