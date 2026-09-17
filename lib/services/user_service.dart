import '../models/user.dart';

class UserService
{
    UserService._internal();

  static final UserService _instance = UserService._internal();
  final List<User> registeredUsers = [];

  factory UserService()
  {
    return _instance;
  }

  void registerUser(User user)
  {
    registeredUsers.add(user);
  }

  User? validateLogin(String email, String password)
  {
    for (User user in registeredUsers)
    {
      if (user.userEmail == email && user.userPassword == password)
      {
        return user;
      }
    }
    return null;
  }
}