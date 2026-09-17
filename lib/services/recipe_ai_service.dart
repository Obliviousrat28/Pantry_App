import 'dart:convert';

import 'package:http/http.dart' as http;

import '/models/dietary_preferences.dart';
import '/models/recipe.dart';

//Handles communication between the Flutter app and the recipe backend
class RecipeService {
  //10.0.2.2 lets the Android emulator access localhost on the computer
  final String baseUrl = 'http://10.0.2.2:3000';

  //Sends the selected dietary preferences to the backend and returns recipes
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

    //Convert a successful JSON response into Recipe objects
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

    //Throw an error if the backend request was not successful
    throw Exception(
      'Failed to generate recipes: ${response.body}',
    );
  }
}