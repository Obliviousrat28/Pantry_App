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

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'userName': userName,
    'userEmail': userEmail,
    'userPassword': userPassword,
    'weeklyBudgetGoal': weeklyBudgetGoal,
    'dietaryPreference': dietaryPreference,
  };

  factory User.fromJson(Map<String, dynamic> json) => User(
    userId: json['userId'],
    userName: json['userName'],
    userEmail: json['userEmail'],
    userPassword: json['userPassword'],
    weeklyBudgetGoal: (json['weeklyBudgetGoal'] as num).toDouble(),
    dietaryPreference: List<String>.from(json['dietaryPreference']),
  );

  // Returns a copy of this user with the given fields replaced -
  // used by Settings when only the goal or preferences change.
  User copyWith({
    double? weeklyBudgetGoal,
    List<String>? dietaryPreference,
  }) {
    return User(
      userId: userId,
      userName: userName,
      userEmail: userEmail,
      userPassword: userPassword,
      weeklyBudgetGoal: weeklyBudgetGoal ?? this.weeklyBudgetGoal,
      dietaryPreference: dietaryPreference ?? this.dietaryPreference,
    );
  }
}