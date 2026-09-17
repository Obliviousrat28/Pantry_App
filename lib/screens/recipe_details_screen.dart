import 'package:flutter/material.dart';

import '/models/recipe.dart';
import '/services/saved_recipe_service.dart';

class RecipeDetailsScreen extends StatefulWidget {
  final Recipe recipe;

  const RecipeDetailsScreen({
    super.key,
    required this.recipe,
  });

  @override
  State<RecipeDetailsScreen> createState() =>
      _RecipeDetailsScreenState();
}

class _RecipeDetailsScreenState
    extends State<RecipeDetailsScreen> {
  //Service used to save and remove recipes
  final SavedRecipeService savedRecipeService =
      SavedRecipeService();

  //Stores the current saved state
  bool isSaved = false;

  //Checks if the saved state is still loading
  bool isCheckingSavedStatus = true;

  @override
  void initState() {
    super.initState();

    //Checks the saved state when the screen opens
    checkSavedStatus();
  }

  //Checks if the current recipe is already saved
  Future<void> checkSavedStatus() async {
    final result =
        await savedRecipeService.isRecipeSaved(
      widget.recipe,
    );

    if (!mounted) return;

    setState(() {
      isSaved = result;
      isCheckingSavedStatus = false;
    });
  }

  //Saves or removes the recipe
  Future<void> toggleSave() async {
    if (isSaved) {
      await savedRecipeService.removeRecipe(
        widget.recipe,
      );
    } else {
      await savedRecipeService.saveRecipe(
        widget.recipe,
      );
    }

    if (!mounted) return;

    //Updates the saved state
    setState(() {
      isSaved = !isSaved;
    });

    //Shows a message after saving or removing
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isSaved
              ? 'Recipe saved successfully!'
              : 'Recipe removed from saved recipes.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    //Stores the current recipe for easier access
    final recipe = widget.recipe;

    return Scaffold(
      appBar: AppBar(
        title: Text(recipe.title),

        //Save button
        actions: [
          IconButton(
            onPressed:
                isCheckingSavedStatus ? null : toggleSave,
            tooltip:
                isSaved ? 'Remove Recipe' : 'Save Recipe',
            icon: Icon(
              isSaved
                  ? Icons.bookmark
                  : Icons.bookmark_border,
            ),
          ),
        ],
      ),

      //Allows the page to scroll
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //Recipe title
            Text(
              recipe.title,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            //Recipe description
            Text(
              recipe.description,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
              ),
            ),

            const SizedBox(height: 25),

            //Recipe information
            Wrap(
              spacing: 20,
              runSpacing: 10,
              children: [
                _InfoItem(
                  icon: Icons.timer_outlined,
                  text: '${recipe.prepTime} min',
                ),
                _InfoItem(
                  icon: Icons.local_fire_department_outlined,
                  text: '${recipe.calories} kcal',
                ),
                _InfoItem(
                  icon: Icons.fitness_center,
                  text: '${recipe.protein}g protein',
                ),
              ],
            ),

            const SizedBox(height: 30),

            //Ingredients title
            const Text(
              'Ingredients',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            //Displays every ingredient
            ...recipe.ingredients.map(
              (ingredient) => Padding(
                padding: const EdgeInsets.only(
                  bottom: 10,
                ),
                child: Row(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.circle,
                      size: 8,
                    ),

                    const SizedBox(width: 10),

                    Expanded(
                      child: Text(
                        ingredient,
                        style: const TextStyle(
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 30),

            //Cooking instructions title
            const Text(
              'Cooking Instructions',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            //Creates numbered cooking steps
            ...List.generate(
              recipe.instructions.length,
              (index) {
                final instruction =
                    recipe.instructions[index];

                return Padding(
                  padding: const EdgeInsets.only(
                    bottom: 18,
                  ),
                  child: Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      //Instruction number
                      Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      const SizedBox(width: 12),

                      //Instruction text
                      Expanded(
                        child: Padding(
                          padding:
                              const EdgeInsets.only(
                            top: 5,
                          ),
                          child: Text(
                            instruction,
                            style: const TextStyle(
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

//Reusable widget for recipe information
class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoItem({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          size: 20,
        ),

        const SizedBox(width: 6),

        Text(
          text,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}