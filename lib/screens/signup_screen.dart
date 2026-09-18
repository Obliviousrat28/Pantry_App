import 'package:flutter/material.dart';
import '../models/user.dart';
import '../widgets/signup/signup_username_field.dart';
import '../widgets/signup/signup_email_field.dart';
import '../widgets/signup/signup_password_field.dart';
import '../widgets/signup/signup_confirm_password_field.dart';
import '../widgets/signup/signup_dietary_preferences.dart';
import '../widgets/signup/signup_budget_field.dart';
import '../widgets/signup/signup_error_message.dart';
import '../services/signup_validation.dart';
import '../services/storage_service.dart';
import 'package:firebase_auth/firebase_auth.dart' hide User;

class SignupScreen extends StatefulWidget
{
  const SignupScreen({Key? key}) : super(key: key);

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
{
  final StorageService _storageService = StorageService();
  final userNameController = TextEditingController();
  final userEmailController = TextEditingController();
  final userPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  final weeklyBudgetGoalController = TextEditingController();
  String errorMessage = '';

  List<String> dietaryPreference = [];

  void register() async
  {
    setState(() {
      errorMessage = SignupValidation.validate(
        userNameController.text,
        userEmailController.text,
        userPasswordController.text,
        confirmPasswordController.text,
        weeklyBudgetGoalController.text,
      );
    });

    if (errorMessage.isEmpty)
    {
      try{
        final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: userEmailController.text.trim(),
          password: userPasswordController.text.trim(),
        );

        final userId =  credential.user!.uid;

        User newUser = User(
          userId: userId,
          userName: userNameController.text,
          userEmail: userEmailController.text,
          userPassword: userPasswordController.text,
          weeklyBudgetGoal: double.parse(weeklyBudgetGoalController.text),
            dietaryPreference: dietaryPreference,
        );

      await _storageService.saveUserData(
        userName: userNameController.text.trim(),
        email: userEmailController.text.trim(),
        weeklyBudgetGoal: double.parse(weeklyBudgetGoalController.text),
        dietaryPreferences: dietaryPreference,
      );

      if(!context.mounted) return;

      print('User registered: ${newUser.userName}');
      print('User ID: ${newUser.userId}');
      print ('Email: ${newUser.userEmail}');
      print ('Password: ${newUser.userPassword}');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account created successfully!')),
      );

      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      setState(() {
        errorMessage = e.message ?? 'An error occurred during registration.';
      });
    }
  }
}

  @override
  Widget build(BuildContext context)
  {
    return Scaffold(
      appBar: AppBar(title: const Text('Sign Up')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SignupUsernameField(controller: userNameController),
              const SizedBox(height: 16),
              SignupEmailField(controller: userEmailController),
              const SizedBox(height: 16),
              SignupPasswordField(controller: userPasswordController),
              const SizedBox(height: 16),
              SignupConfirmPasswordField(controller: confirmPasswordController),
              const SizedBox(height: 16),
              SignupDietaryPreferences(
                selectedPreferences: dietaryPreference,
                onChanged: (preferences) {
                  setState(() {
                    dietaryPreference = preferences;
                  });
                },
              ),
              const SizedBox(height: 16),
              SignupBudgetField(controller: weeklyBudgetGoalController),
              const SizedBox(height: 16),
              SignupErrorMessage(errorMessage: errorMessage),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: register,
                child: const Text('Sign Up'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose()
  {
    userNameController.dispose();
    userEmailController.dispose();
    userPasswordController.dispose();
    confirmPasswordController.dispose();
    weeklyBudgetGoalController.dispose();
    super.dispose();
  }
}