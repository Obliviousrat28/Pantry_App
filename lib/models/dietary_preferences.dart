//THIS CLASS FOR TESTING PURPOSES ONLY

//Stores dietary preference values used when generating recipes
class DietaryPreferences {
  bool vegetarian;
  bool vegan;
  bool halal;
  bool glutenFree;
  bool dairyFree;
  bool highProtein;

  //Each value shows whether a dietary option is selected
  DietaryPreferences({
    this.vegetarian = false,
    this.vegan = false,
    this.halal = false,
    this.glutenFree = false,
    this.dairyFree = false,
    this.highProtein = false,
  });

  //Converts the preferences into JSON before sending them to the backend
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