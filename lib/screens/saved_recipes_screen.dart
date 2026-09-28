import 'package:flutter/material.dart';

import '/models/recipe.dart';
import '/services/saved_recipe_service.dart';
import 'recipe_details_screen.dart';

class SavedRecipesScreen extends StatefulWidget {
  const SavedRecipesScreen({super.key});

  @override
  State<SavedRecipesScreen> createState() =>
      _SavedRecipesScreenState();
}

class _SavedRecipesScreenState
    extends State<SavedRecipesScreen> {
  //Service used to load and remove saved recipes
  final SavedRecipeService savedRecipeService =
      SavedRecipeService();

  //Stores all saved recipes
  List<Recipe> savedRecipes = [];

  //Controls the loading state
  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    //Loads saved recipes when the screen opens
    loadSavedRecipes();
  }

  //Loads all recipes from local storage
  Future<void> loadSavedRecipes() async {
    final recipes =
        await savedRecipeService.getSavedRecipes();

    if (!mounted) return;

    setState(() {
      savedRecipes = recipes;
      isLoading = false;
    });
  }

  //Removes a recipe from saved recipes
  Future<void> removeRecipe(Recipe recipe) async {
    await savedRecipeService.removeRecipe(recipe);

    if (!mounted) return;

    //Reloads the list after removing a recipe
    await loadSavedRecipes();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Recipe removed from saved recipes.',
        ),
      ),
    );
  }

  //Opens the recipe details screen
  Future<void> openRecipeDetails(
    Recipe recipe,
  ) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            RecipeDetailsScreen(
          recipe: recipe,
        ),
      ),
    );

    //Reloads the list after returning from details
    await loadSavedRecipes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Saved Recipes',
        ),
        centerTitle: true,
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : savedRecipes.isEmpty
              ? const _EmptySavedRecipes()
              : ListView.builder(
                  padding:
                      const EdgeInsets.all(20),
                  itemCount:
                      savedRecipes.length,
                  itemBuilder:
                      (context, index) {
                    final recipe =
                        savedRecipes[index];

                    return SavedRecipeCard(
                      recipe: recipe,
                      onView: () {
                        openRecipeDetails(
                          recipe,
                        );
                      },
                      onRemove: () {
                        removeRecipe(
                          recipe,
                        );
                      },
                    );
                  },
                ),
    );
  }
}

//Shown when no recipes are saved
class _EmptySavedRecipes extends StatelessWidget {
  const _EmptySavedRecipes();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.bookmark_border,
              size: 70,
              color: Colors.grey,
            ),
            const SizedBox(height: 15),
            const Text(
              'No Saved Recipes',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Recipes you save will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

//Card used to display a saved recipe
class SavedRecipeCard extends StatelessWidget {
  final Recipe recipe;
  final VoidCallback onView;
  final VoidCallback onRemove;

  const SavedRecipeCard({
    super.key,
    required this.recipe,
    required this.onView,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    //Builds only the information that is available for this recipe
    final infoItems = <Widget>[];

    if (recipe.prepTime > 0) {
      infoItems.add(
        _RecipeInfo(
          icon: Icons.timer_outlined,
          text: '${recipe.prepTime} min',
        ),
      );
    }

    if (recipe.calories > 0) {
      infoItems.add(
        _RecipeInfo(
          icon: Icons.local_fire_department_outlined,
          text: '${recipe.calories} kcal',
        ),
      );
    }

    if (recipe.protein > 0) {
      infoItems.add(
        _RecipeInfo(
          icon: Icons.fitness_center,
          text: '${recipe.protein}g protein',
        ),
      );
    }

    return Card(
      margin:
          const EdgeInsets.only(bottom: 15),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            //Shows the recipe source
            Chip(
              avatar: Icon(
                recipe.isRealRecipe
                    ? Icons.menu_book_outlined
                    : Icons.auto_awesome,
                size: 17,
              ),
              label: Text(
                recipe.isRealRecipe
                    ? 'Real Recipe • ${recipe.sourceName}'
                    : 'AI Generated',
              ),
            ),

            const SizedBox(height: 10),

            //Recipe title
            Text(
              recipe.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 8),

            //Recipe description
            Text(
              recipe.description,
              style: TextStyle(
                color: Colors.grey.shade700,
              ),
            ),

            if (infoItems.isNotEmpty) ...[
              const SizedBox(height: 15),

              //Recipe information
              Wrap(
                spacing: 15,
                runSpacing: 10,
                children: infoItems,
              ),
            ],

            const SizedBox(height: 15),

            Row(
              children: [
                //Opens the recipe details screen
                Expanded(
                  child: OutlinedButton(
                    onPressed: onView,
                    child: const Text(
                      'View Recipe',
                    ),
                  ),
                ),

                const SizedBox(width: 10),

                //Removes the recipe from saved recipes
                IconButton(
                  onPressed: onRemove,
                  tooltip: 'Remove Recipe',
                  icon: const Icon(
                    Icons.delete_outline,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

//Reusable widget for recipe information
class _RecipeInfo extends StatelessWidget {
  final IconData icon;
  final String text;

  const _RecipeInfo({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize:
          MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 18,
        ),
        const SizedBox(width: 5),
        Text(text),
      ],
    );
  }
}
