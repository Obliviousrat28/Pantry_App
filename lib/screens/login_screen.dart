import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/login/login_email_field.dart';
import '../widgets/login/login_password_field.dart';
import '../widgets/login/login_error_message.dart';
import '../services/login_validation.dart';
import 'signup_screen.dart';
import '../screens/main_navigation_screen.dart';


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

  void login() async
  {
    setState(() {
      errorMessage = LoginValidation.validate(
        userEmailController.text,
        userPasswordController.text,
      );
    });

    if (errorMessage.isEmpty)
    {
      try{
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: userEmailController.text.trim(),
          password: userPasswordController.text.trim(),
        );

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Login successful!')),
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
        );
      });
    } on FirebaseAuthException catch (e) {
      setState(() {
        errorMessage = e.message ?? 'An error occurred during login.';
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