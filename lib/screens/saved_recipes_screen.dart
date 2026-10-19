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

    //Shows the saved estimated recipe cost
    if (recipe.estimatedCost > 0) {
      infoItems.add(
        _RecipeInfo(
          icon: Icons.payments_outlined,
          text: recipe.hasUnknownPrices
              ? 'Known ~NZ\$${recipe.estimatedCost.toStringAsFixed(2)}'
              : '~NZ\$${recipe.estimatedCost.toStringAsFixed(2)}',
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
            //Shows the recipe image just like the Recipes page
            if (recipe.imageUrl.isNotEmpty) ...[
              _RetryingRecipeImage(
                imageUrl: recipe.imageUrl,
                height: 180,
                borderRadius: 14,
              ),
              const SizedBox(height: 14),
            ],

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

            //Quick inventory breakdown. Full prices appear under View Recipe.
            if (recipe.hasIngredientCostBreakdown) ...[
              const SizedBox(height: 10),
              Text(
                '${recipe.ingredientCosts.where((item) => item.inInventory).length} in inventory  •  '
                '${recipe.ingredientCosts.where((item) => !item.inInventory).length} to buy',
                style: TextStyle(
                  fontSize: 13, color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
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

//Retries a recipe image when the first network request fails
class _RetryingRecipeImage extends StatefulWidget {
  final String imageUrl;
  final double height;
  final double borderRadius;

  const _RetryingRecipeImage({
    required this.imageUrl,
    required this.height,
    required this.borderRadius,
  });

  @override
  State<_RetryingRecipeImage> createState() =>
      _RetryingRecipeImageState();
}

class _RetryingRecipeImageState
    extends State<_RetryingRecipeImage> {
  static const int _maxRetries = 2;

  int _attempt = 0;
  bool _retryScheduled = false;

  @override
  void didUpdateWidget(
    covariant _RetryingRecipeImage oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);

    //Resets retry state when a different recipe image is shown
    if (oldWidget.imageUrl != widget.imageUrl) {
      _attempt = 0;
      _retryScheduled = false;
    }
  }

  //Waits briefly and tries the same image request again
  void _scheduleRetry() {
    if (_retryScheduled || _attempt >= _maxRetries) {
      return;
    }

    _retryScheduled = true;
    final delaySeconds = (_attempt + 1) * 2;

    Future.delayed(
      Duration(seconds: delaySeconds),
      () {
        if (!mounted) {
          return;
        }

        setState(() {
          _attempt += 1;
          _retryScheduled = false;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(
        widget.borderRadius,
      ),
      child: Image.network(
        widget.imageUrl,
        key: ValueKey(
          '${widget.imageUrl}-$_attempt',
        ),
        height: widget.height,
        width: double.infinity,
        fit: BoxFit.cover,
        loadingBuilder: (
          context,
          child,
          loadingProgress,
        ) {
          if (loadingProgress == null) {
            return child;
          }

          return Container(
            height: widget.height,
            width: double.infinity,
            color: Colors.grey.shade200,
            alignment: Alignment.center,
            child: const CircularProgressIndicator(),
          );
        },
        errorBuilder: (
          context,
          error,
          stackTrace,
        ) {
          if (_attempt < _maxRetries) {
            _scheduleRetry();

            return Container(
              height: widget.height,
              width: double.infinity,
              color: Colors.grey.shade200,
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 26,
                    height: 26,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Retrying image...',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            );
          }

          return Container(
            height: widget.height,
            width: double.infinity,
            color: Colors.grey.shade200,
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.image_not_supported_outlined,
                  size: 36,
                ),
                const SizedBox(height: 6),
                Text(
                  'Image unavailable',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          );
        },
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