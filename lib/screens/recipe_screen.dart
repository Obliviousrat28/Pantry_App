import 'package:flutter/material.dart';

import 'package:my_pantry/models/recipe.dart';
import 'package:my_pantry/services/recipe_ai_service.dart';
import 'package:my_pantry/screens/recipe_details_screen.dart';
import 'package:my_pantry/screens/saved_recipes_screen.dart';

class RecipesScreen extends StatefulWidget {
  const RecipesScreen({super.key});

  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen> {
  //Service used to load real recipes and generate AI recipes
  final RecipeService recipeService = RecipeService();

  //Stores real recipes returned by the recipe database
  List<Recipe> realRecipes = [];

  //Stores recipes created by AI
  List<Recipe> aiRecipes = [];

  //Controls the loading state
  bool isLoading = false;

  //Tracks whether recommendations have been requested
  bool hasGenerated = false;

  //Loads real recipes and AI recipes using the latest saved user data
  Future<void> generateRecipes() async {
    setState(() {
      isLoading = true;
    });

    try {
      //Loads current inventory budget and preferences before requesting recipes
      final recommendations =
          await recipeService.generateRecipes();

      if (!mounted) return;

      //Updates both recipe sections
      setState(() {
        realRecipes = recommendations.realRecipes;
        aiRecipes = recommendations.aiRecipes;
        hasGenerated = true;
      });

      //Shows a success message when at least one source returned recipes
      if (!recommendations.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Recipe recommendations loaded successfully!',
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Recipe error: $e');

      if (!mounted) return;

      //Shows an error message if the request fails completely
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to load recipe recommendations: $e',
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  //Opens the saved recipes screen
  Future<void> openSavedRecipes() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const SavedRecipesScreen(),
      ),
    );
  }

  //Builds one recipe result section
  Widget buildRecipeSection({
    required String title,
    required String description,
    required List<Recipe> recipes,
    required String emptyMessage,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),

        const SizedBox(height: 5),

        Text(
          description,
          style: TextStyle(
            color: Colors.grey.shade600,
          ),
        ),

        const SizedBox(height: 15),

        if (recipes.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Text(
              emptyMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
              ),
            ),
          )
        else
          ...recipes.map(
            (recipe) => RecipeCard(
              recipe: recipe,
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recipes'),
        centerTitle: true,

        //Button used to open saved recipes
        actions: [
          IconButton(
            tooltip: 'Saved Recipes',
            icon: const Icon(
              Icons.bookmarks_outlined,
            ),
            onPressed: openSavedRecipes,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              //Main page title
              const Text(
                'Find Your Recipe',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              //Explains which saved data is used for recommendations
              const Text(
                'Recommendations use your saved dietary preferences, remaining budget, and current inventory.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 25),

              //Shows the information used by the recommendation system
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius:
                      BorderRadius.circular(15),
                ),
                child: const Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Current inventory',
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.account_balance_wallet_outlined,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Remaining weekly budget',
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          Icons.restaurant_outlined,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Saved dietary preferences',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              //Button used to request recipe recommendations
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed:
                      isLoading ? null : generateRecipes,
                  icon: isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(
                          Icons.auto_awesome,
                        ),
                  label: Text(
                    isLoading
                        ? 'Finding Recipes...'
                        : 'Find Recipes',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 35),

              //Shows a loading indicator while recommendations are loaded
              if (isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(
                    vertical: 30,
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 15),
                        Text(
                          'Finding recipes for you...',
                        ),
                      ],
                    ),
                  ),
                ),

              //Shows the initial empty state before the first request
              if (!hasGenerated && !isLoading)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius:
                        BorderRadius.circular(15),
                  ),
                  child: const Column(
                    children: [
                      Icon(
                        Icons.restaurant_menu,
                        size: 50,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Your recipe recommendations will appear here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),

              //Shows real recipes and AI recipes in separate sections
              if (hasGenerated && !isLoading) ...[
                buildRecipeSection(
                  title: 'Real Recipes',
                  description:
                      'Existing recipes matched to your inventory, budget, and preferences',
                  recipes: realRecipes,
                  emptyMessage:
                      'No suitable real recipes were found for the current data',
                ),

                const SizedBox(height: 30),

                buildRecipeSection(
                  title: 'AI Suggestions',
                  description:
                      'New recipe ideas created for your current situation',
                  recipes: aiRecipes,
                  emptyMessage:
                      'AI suggestions are currently unavailable',
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

//Card used to display a recipe recommendation
class RecipeCard extends StatelessWidget {
  final Recipe recipe;

  const RecipeCard({
    super.key,
    required this.recipe,
  });

  @override
  Widget build(BuildContext context) {
    //Builds only the information that is available for this recipe
    final infoItems = <Widget>[];

    if (recipe.prepTime > 0) {
      infoItems.add(
        RecipeInfo(
          icon: Icons.timer_outlined,
          text: '${recipe.prepTime} min',
        ),
      );
    }

    if (recipe.calories > 0) {
      infoItems.add(
        RecipeInfo(
          icon: Icons.local_fire_department_outlined,
          text: '${recipe.calories} kcal',
        ),
      );
    }

    if (recipe.protein > 0) {
      infoItems.add(
        RecipeInfo(
          icon: Icons.fitness_center,
          text: '${recipe.protein}g protein',
        ),
      );
    }

    //Shows the estimated total ingredient value
    if (recipe.estimatedCost > 0) {
      infoItems.add(
        RecipeInfo(
          icon: Icons.payments_outlined,
          text:
              '~NZ\$${recipe.estimatedCost.toStringAsFixed(2)}',
        ),
      );
    }

    //Shows how much extra spending is needed
    if (recipe.estimatedPurchaseCost > 0) {
      infoItems.add(
        RecipeInfo(
          icon: Icons.shopping_cart_outlined,
          text:
              'Buy ~NZ\$${recipe.estimatedPurchaseCost.toStringAsFixed(2)}',
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.only(
        bottom: 15,
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            //Shows the recipe image when one is available
            if (recipe.imageUrl.isNotEmpty) ...[
              _RetryingRecipeImage(
                imageUrl: recipe.imageUrl,
                height: 180,
                borderRadius: 14,
              ),
              const SizedBox(height: 14),
            ],

            //Shows whether the recipe is real or AI generated
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

            //Shows the over budget amount only when the user is over budget
            if (recipe.overBudgetAmount > 0) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
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

            const SizedBox(height: 15),

            //Button used to open recipe details
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          RecipeDetailsScreen(
                        recipe: recipe,
                      ),
                    ),
                  );
                },
                child: const Text(
                  'View Recipe',
                ),
              ),
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
class RecipeInfo extends StatelessWidget {
  final IconData icon;
  final String text;

  const RecipeInfo({
    super.key,
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
          size: 18,
        ),
        const SizedBox(width: 5),
        Text(text),
      ],
    );
  }
}