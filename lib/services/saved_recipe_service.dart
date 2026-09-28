import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/recipe.dart';

class SavedRecipeService {
  //Key used to store saved recipes
  static const String savedRecipesKey = 'saved_recipes';

  //Loads all saved recipes from local storage
  Future<List<Recipe>> getSavedRecipes() async {
    final prefs = await SharedPreferences.getInstance();

    final savedData =
        prefs.getStringList(savedRecipesKey) ?? [];

    return savedData.map((recipeString) {
      final jsonData = jsonDecode(recipeString);

      return Recipe.fromJson(
        jsonData as Map<String, dynamic>,
      );
    }).toList();
  }

  //Checks if a recipe is already saved
  Future<bool> isRecipeSaved(Recipe recipe) async {
    final recipes = await getSavedRecipes();

    return recipes.any(
      (savedRecipe) =>
          savedRecipe.title == recipe.title &&
          savedRecipe.description == recipe.description,
    );
  }

  //Saves a recipe to local storage
  Future<void> saveRecipe(Recipe recipe) async {
    final prefs = await SharedPreferences.getInstance();

    final recipes = await getSavedRecipes();

    //Checks if the recipe is already saved
    final alreadySaved = recipes.any(
      (savedRecipe) =>
          savedRecipe.title == recipe.title &&
          savedRecipe.description == recipe.description,
    );

    //Stops duplicate recipes from being saved
    if (alreadySaved) {
      return;
    }

    recipes.add(recipe);

    //Converts recipes into JSON strings
    final savedData = recipes.map((savedRecipe) {
      return jsonEncode(
        savedRecipe.toJson(),
      );
    }).toList();

    //Stores the updated recipe list
    await prefs.setStringList(
      savedRecipesKey,
      savedData,
    );
  }

  //Removes a recipe from local storage
  Future<void> removeRecipe(Recipe recipe) async {
    final prefs = await SharedPreferences.getInstance();

    final recipes = await getSavedRecipes();

    //Finds and removes the selected recipe
    recipes.removeWhere(
      (savedRecipe) =>
          savedRecipe.title == recipe.title &&
          savedRecipe.description == recipe.description,
    );

    //Converts the updated list into JSON strings
    final savedData = recipes.map((savedRecipe) {
      return jsonEncode(
        savedRecipe.toJson(),
      );
    }).toList();

    //Saves the updated list
    await prefs.setStringList(
      savedRecipesKey,
      savedData,
    );
  }
}