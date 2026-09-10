import 'package:flutter/material.dart';
import '/models/dietary_preferences.dart';
import '/models/recipe.dart';
import 'recipe_details_screen.dart';
import '/services/recipe_ai_service.dart';



class RecipesScreen extends StatefulWidget {
  const RecipesScreen({super.key});

  @override
  State<RecipesScreen> createState() => _RecipesScreenState();
}

class _RecipesScreenState extends State<RecipesScreen> {
  final DietaryPreferences preferences = DietaryPreferences();
  final RecipeService recipeService = RecipeService();

  List<Recipe> recipes = [];

  bool isLoading = false;

  Future<void> generateRecipes() async {
    setState(() {
      isLoading = true;
    });

    try {
      final generatedRecipes =
          await recipeService.generateRecipes(preferences);

      if (!mounted) return;

      setState(() {
        recipes = generatedRecipes;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Recipes generated successfully!',
          ),
        ),
      );
    } catch (e) {
      debugPrint('Recipe error: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to generate recipes: $e',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recipes'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Find Your Recipe',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Choose your dietary preferences and let AI recommend recipes for you.',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),

              const SizedBox(height: 30),

              const Text(
                'Dietary Preferences',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Vegetarian'),
                value: preferences.vegetarian,
                onChanged: (value) {
                  setState(() {
                    preferences.vegetarian = value ?? false;
                  });
                },
              ),

              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Vegan'),
                value: preferences.vegan,
                onChanged: (value) {
                  setState(() {
                    preferences.vegan = value ?? false;
                  });
                },
              ),

              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Halal'),
                value: preferences.halal,
                onChanged: (value) {
                  setState(() {
                    preferences.halal = value ?? false;
                  });
                },
              ),

              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Gluten Free'),
                value: preferences.glutenFree,
                onChanged: (value) {
                  setState(() {
                    preferences.glutenFree = value ?? false;
                  });
                },
              ),

              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Dairy Free'),
                value: preferences.dairyFree,
                onChanged: (value) {
                  setState(() {
                    preferences.dairyFree = value ?? false;
                  });
                },
              ),

              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('High Protein'),
                value: preferences.highProtein,
                onChanged: (value) {
                  setState(() {
                    preferences.highProtein = value ?? false;
                  });
                },
              ),

              const SizedBox(height: 25),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton.icon(
                  onPressed: isLoading ? null : generateRecipes,
                  icon: isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.auto_awesome),
                  label: Text(
                    isLoading
                        ? 'Generating...'
                        : 'Generate Recipes',
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 35),

              const Text(
                'Recommended Recipes',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 15),

              // Henüz tarif yoksa
              if (recipes.isEmpty && !isLoading)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(15),
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
                        'Your AI-generated recipes will appear here.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),


              ...recipes.map(
                (recipe) => RecipeCard(
                  recipe: recipe,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RecipeCard extends StatelessWidget {
  final Recipe recipe;

  const RecipeCard({
    super.key,
    required this.recipe,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              recipe.title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              recipe.description,
              style: TextStyle(
                color: Colors.grey.shade700,
              ),
            ),

            const SizedBox(height: 15),

            Wrap(
              spacing: 15,
              runSpacing: 10,
              children: [
                RecipeInfo(
                  icon: Icons.timer_outlined,
                  text: '${recipe.prepTime} min',
                ),
                RecipeInfo(
                  icon: Icons.local_fire_department_outlined,
                  text: '${recipe.calories} kcal',
                ),
                RecipeInfo(
                  icon: Icons.fitness_center,
                  text: '${recipe.protein}g protein',
                ),
              ],
            ),

            const SizedBox(height: 15),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => RecipeDetailsScreen(recipe: recipe),
                    ),
                  );
                },
                child: const Text('View Recipe'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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