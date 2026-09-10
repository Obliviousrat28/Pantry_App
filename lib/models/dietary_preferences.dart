//THIS CLASS FOR TESTING PURPOSES ONLY, NOT USED IN THE APP

class DietaryPreferences {
  bool vegetarian;
  bool vegan;
  bool halal;
  bool glutenFree;
  bool dairyFree;
  bool highProtein;

  DietaryPreferences({
    this.vegetarian = false,
    this.vegan = false,
    this.halal = false,
    this.glutenFree = false,
    this.dairyFree = false,
    this.highProtein = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'vegetarian': vegetarian,
      'vegan': vegan,
      'halal': halal,
      'glutenFree': glutenFree,
      'dairyFree': dairyFree,
      'highProtein': highProtein,
    };
  }
}