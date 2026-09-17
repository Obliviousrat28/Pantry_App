import 'dart:convert';

import 'package:http/http.dart' as http;

import '/models/recipe.dart';
import '/services/storage_service.dart';

//Stores real recipe results and AI generated results separately
class RecipeRecommendations {
  final List<Recipe> realRecipes;
  final List<Recipe> aiRecipes;

  RecipeRecommendations({
    required this.realRecipes,
    required this.aiRecipes,
  });

  //Returns true when neither source returned a recipe
  bool get isEmpty => realRecipes.isEmpty && aiRecipes.isEmpty;
}

//Handles recipe generation and loads the latest user data
class RecipeService {
  //10.0.2.2 lets the Android emulator access localhost on the computer
  final String baseUrl = 'http://10.0.2.2:3000';

  //Uses the existing group storage service without changing it
  final StorageService storageService = StorageService();

  //Loads the latest budget dietary preferences and inventory
  Future<RecipeRecommendations> generateRecipes() async {
    //Loads the saved user profile
    final profile = await storageService.loadUserProfile();

    //Loads the current inventory from the existing storage service
    final inventoryItems = await storageService.loadItems();

    //Loads the current weekly budget goal
    final double weeklyBudgetGoal =
        await storageService.loadWeeklyBudgetGoal(120.0);

    //Loads the current remaining budget
    final double remainingBudget =
        await storageService.loadRemainingBudget(weeklyBudgetGoal);

    //Loads dietary preferences already saved by the group project
    final List<String> dietaryPreferences = profile == null
        ? <String>[]
        : List<String>.from(
            profile['dietaryPreferences'] ?? <String>[],
          );

    //Removes expired or empty inventory items before sending data
    final activeInventory = inventoryItems
        .where(
          (item) =>
              !item.isExpired() && item.itemQuantity > 0,
        )
        .toList();

    //Converts inventory items into simple JSON data for the backend
    final List<Map<String, dynamic>> inventory = activeInventory
        .map(
          (item) => {
            'name': item.itemName,
            'quantity': item.itemQuantity,
            'price': item.price,
            'priceUnknown': item.priceUnknown,
            'expiryDate': item.expiryDate.toIso8601String(),
            'expiringSoon': item.isExpiringSoon(),
            'storageZone': item.storageZone.name,
          },
        )
        .toList();

    //Sends inventory budget and dietary preferences to the backend
    final response = await http
        .post(
          Uri.parse('$baseUrl/generate-recipes'),
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'dietaryPreferences': dietaryPreferences,
            'weeklyBudgetGoal': weeklyBudgetGoal,
            'remainingBudget': remainingBudget,
            'inventory': inventory,
          }),
        )
        .timeout(
          const Duration(seconds: 45),
        );

    //Converts a successful response into separate recipe lists
    if (response.statusCode == 200) {
      final Map<String, dynamic> data =
          jsonDecode(response.body);

      final List<dynamic> realRecipeJson =
          data['realRecipes'] ?? <dynamic>[];

      final List<dynamic> aiRecipeJson =
          data['aiRecipes'] ?? <dynamic>[];

      return RecipeRecommendations(
        realRecipes: realRecipeJson
            .map(
              (json) => Recipe.fromJson(
                json as Map<String, dynamic>,
              ),
            )
            .toList(),
        aiRecipes: aiRecipeJson
            .map(
              (json) => Recipe.fromJson(
                json as Map<String, dynamic>,
              ),
            )
            .toList(),
      );
    }

    //Throws an error if the backend request was not successful
    throw Exception(
      'Failed to generate recipes: ${response.body}',
    );
  }
}
