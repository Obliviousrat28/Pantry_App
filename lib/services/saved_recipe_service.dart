import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/recipe.dart';

class SavedRecipeService {
  //Firestore instance
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  //Gets the currently signed in user ID
  String get _userId {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      throw Exception('No user is currently signed in');
    }

    return user.uid;
  }

  //Gets the saved recipes collection for the current user
  CollectionReference<Map<String, dynamic>>
      get _savedRecipesCollection {
    return _firestore
        .collection('users')
        .doc(_userId)
        .collection('saved_recipes');
  }

  //Checks if two recipes are the same
  bool _sameRecipe(
    Recipe firstRecipe,
    Recipe secondRecipe,
  ) {
    //Uses source URL when both recipes have one
    if (firstRecipe.sourceUrl.isNotEmpty &&
        secondRecipe.sourceUrl.isNotEmpty) {
      return firstRecipe.sourceUrl ==
          secondRecipe.sourceUrl;
    }

    //Falls back to title and description
    return firstRecipe.title ==
            secondRecipe.title &&
        firstRecipe.description ==
            secondRecipe.description;
  }

  //Loads saved recipes for the current user
  Future<List<Recipe>> getSavedRecipes() async {
    final snapshot =
        await _savedRecipesCollection.get();

    return snapshot.docs.map((doc) {
      return Recipe.fromJson(
        doc.data(),
      );
    }).toList();
  }

  //Checks if the recipe is already saved
  Future<bool> isRecipeSaved(
    Recipe recipe,
  ) async {
    final snapshot =
        await _savedRecipesCollection.get();

    for (final doc in snapshot.docs) {
      final savedRecipe =
          Recipe.fromJson(doc.data());

      if (_sameRecipe(savedRecipe, recipe)) {
        return true;
      }
    }

    return false;
  }

  //Saves the recipe to the current user account
  Future<void> saveRecipe(
    Recipe recipe,
  ) async {
    final alreadySaved =
        await isRecipeSaved(recipe);

    //Stops duplicate recipes from being saved
    if (alreadySaved) {
      return;
    }

    await _savedRecipesCollection.add({
      ...recipe.toJson(),
      'savedAt': FieldValue.serverTimestamp(),
    });
  }

  //Removes the recipe from the current user account
  Future<void> removeRecipe(
    Recipe recipe,
  ) async {
    final snapshot =
        await _savedRecipesCollection.get();

    final batch = _firestore.batch();

    for (final doc in snapshot.docs) {
      final savedRecipe =
          Recipe.fromJson(doc.data());

      //Deletes the matching recipe
      if (_sameRecipe(savedRecipe, recipe)) {
        batch.delete(doc.reference);
      }
    }

    await batch.commit();
  }
}