import 'package:flutter/material.dart';

import 'package:my_pantry/models/recipe.dart';
import 'package:my_pantry/services/saved_recipe_service.dart';

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

    //Builds only the information that is available for this recipe
    final infoItems = <Widget>[];

    //Tracks whether nutrition or preparation information is available
    final hasNutritionInfo =
        recipe.prepTime > 0 || recipe.calories > 0 || recipe.protein > 0;

    if (recipe.prepTime > 0) {
      infoItems.add(
        _InfoItem(
          icon: Icons.timer_outlined,
          text: '${recipe.prepTime} min',
        ),
      );
    }

    if (recipe.calories > 0) {
      infoItems.add(
        _InfoItem(
          icon: Icons.local_fire_department_outlined,
          text: '${recipe.calories} kcal',
        ),
      );
    }

    if (recipe.protein > 0) {
      infoItems.add(
        _InfoItem(
          icon: Icons.fitness_center,
          text: '${recipe.protein}g protein',
        ),
      );
    }

    //Shows the estimated total ingredient value
    if (recipe.estimatedCost > 0) {
      infoItems.add(
        _InfoItem(
          icon: Icons.payments_outlined,
          text:
              '~NZ\$${recipe.estimatedCost.toStringAsFixed(2)}',
        ),
      );
    }

    //Shows the estimated extra amount the user needs to spend
    if (recipe.estimatedPurchaseCost > 0) {
      infoItems.add(
        _InfoItem(
          icon: Icons.shopping_cart_outlined,
          text:
              'Buy ~NZ\$${recipe.estimatedPurchaseCost.toStringAsFixed(2)}',
        ),
      );
    }

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

            //Shows the recipe image when one is available
            if (recipe.imageUrl.isNotEmpty) ...[
              _RetryingRecipeImage(
                imageUrl: recipe.imageUrl,
                height: 230,
                borderRadius: 16,
              ),
              const SizedBox(height: 20),
            ],

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

            if (infoItems.isNotEmpty) ...[
              const SizedBox(height: 25),

              //Recipe information
              Wrap(
                spacing: 20,
                runSpacing: 10,
                children: infoItems,
              ),
            ],

            if (recipe.estimatedCost > 0) ...[
              const SizedBox(height: 12),

              //Explains how recipe prices are estimated
              Text(
                'Cost uses your inventory prices where available. Missing ingredient prices are estimated from typical New Zealand prices.',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],

            //Shows the over budget amount only when the user is over budget
            if (recipe.overBudgetAmount > 0) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .errorContainer,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: Theme.of(context)
                          .colorScheme
                          .onErrorContainer,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Over budget by NZ\$${recipe.overBudgetAmount.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context)
                              .colorScheme
                              .onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            //Explains why nutrition values may be missing from real recipes
            if (recipe.isRealRecipe && !hasNutritionInfo) ...[
              const SizedBox(height: 20),
              Text(
                'Nutrition and preparation time are not provided by this recipe source.',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],

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