import 'package:flutter/material.dart';
import '/models/recipe.dart';

class RecipeDetailsScreen extends StatelessWidget {
  final Recipe recipe;

  const RecipeDetailsScreen({
    super.key,
    required this.recipe,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(recipe.title),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              recipe.title,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              recipe.description,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade700,
              ),
            ),

            const SizedBox(height: 25),

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

            const Text(
              'Ingredients',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            ...recipe.ingredients.map(
              (ingredient) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
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

            const Text(
              'Cooking Instructions',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 12),

            ...List.generate(
              recipe.instructions.length,
              (index) {
                final instruction = recipe.instructions[index];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 18),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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

                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 5),
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