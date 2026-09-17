import 'package:flutter/material.dart';

import '/models/recipe.dart';
import '/services/recipe_ai_service.dart';

import 'recipe_details_screen.dart';
import 'saved_recipes_screen.dart';

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
