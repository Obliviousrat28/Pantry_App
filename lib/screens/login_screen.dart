import 'package:flutter/material.dart';
import '../widgets/login/login_email_field.dart';
import '../widgets/login/login_password_field.dart';
import '../widgets/login/login_error_message.dart';
import '../services/login_validation.dart';
import 'signup_screen.dart';
import '../services/user_service.dart';
import '../screens/main_navigation_screen.dart';
import '../models/user.dart';

class LoginScreen extends StatefulWidget
{
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
{
  final userEmailController = TextEditingController();
  final userPasswordController = TextEditingController();
  String errorMessage = '';

  void login()
  {
    setState(() {
      errorMessage = LoginValidation.validate(
        userEmailController.text,
        userPasswordController.text,
      );
    });

    if (errorMessage.isEmpty)
    {
      UserService userService = UserService();
      User? user = userService.validateLogin(
        userEmailController.text,
        userPasswordController.text,
      );

      if (user != null)
      {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
        );
      } else {
        setState(() {
          errorMessage = 'Email or password is incorrect';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context)
  {
    return Scaffold(
      appBar: AppBar(title: const Text('My Pantry')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LoginEmailField(controller: userEmailController),
            const SizedBox(height: 16),
            LoginPasswordField(controller: userPasswordController),
            const SizedBox(height: 16),
            LoginErrorMessage(errorMessage: errorMessage),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: login,
              child: const Text('Login'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SignupScreen()),
                );
              },
              child: const Text('Don\'t have an account? Sign up'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose()
  {
    userEmailController.dispose();
    userPasswordController.dispose();
    super.dispose();
  }
}