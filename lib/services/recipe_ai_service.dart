import 'dart:convert';

import 'package:http/http.dart' as http;

import '/models/dietary_preferences.dart';
import '/models/recipe.dart';

class RecipeService {
  final String baseUrl = 'http://10.0.2.2:3000';

  Future<List<Recipe>> generateRecipes(
    DietaryPreferences preferences,
  ) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl/generate-recipes'),
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'dietaryPreferences': preferences.toJson(),
          }),
        )
        .timeout(
          const Duration(seconds: 30),
        );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data =
          jsonDecode(response.body);

      final List<dynamic> recipeJson =
          data['recipes'];

      return recipeJson
          .map(
            (json) => Recipe.fromJson(
              json as Map<String, dynamic>,
            ),
          )
          .toList();
    }

    throw Exception(
      'Failed to generate recipes: ${response.body}',
    );
  }
}