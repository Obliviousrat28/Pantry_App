class User
{
  final String userId;
  final String userName;
  final String userEmail;
  final String userPassword;
  final double weeklyBudgetGoal;
  final List<String> dietaryPreference;

  User({
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.userPassword,
    required this.weeklyBudgetGoal,
    required this.dietaryPreference,
  });
}