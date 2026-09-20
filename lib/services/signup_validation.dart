class SignupValidation
{
  static String validateUsername(String username)
  {
    if (username.isEmpty)
    {
      return 'All fields are required';
    }

    if (username.length < 3)
    {
      return 'Username must be at least 3 characters';
    }

    return '';
  }

  static String validateEmail(String email)
  {
    if (email.isEmpty)
    {
      return 'All fields are required';
    }

    final emailRegex = RegExp(r'^[\w\.\-]+@[\w\-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(email))
    {
      return 'Please enter a valid email address';
    }
    return '';
  }

  static String validatePassword(String password)
  {
    if (password.isEmpty)
    {
      return 'All fields are required';
    }

    if (password.length < 8)
    {
      return 'Password must be at least 8 characters';
    }

    final digitCount = RegExp(r'\d').allMatches(password).length;
    if (digitCount < 2)
    {
      return 'Password must contain at least 2 digits';
    }

    if(!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password))
    {
      return 'Password must contain at least 1 special character';
    }
    
    return '';
  }

  static String validateConfirmPassword(String password, String confirmPassword)
  {
    if (confirmPassword.isEmpty)
    {
      return 'All fields are required';
    }

    if (password != confirmPassword)
    {
      return 'Passwords do not match';
    }

    return '';
  }

  static String validateBudget(String budget)
  {
    if (budget.isEmpty)
    {
      return 'All fields are required';
    }

    if (double.tryParse(budget) == null)
    {
      return 'Budget must be a valid number';
    }

    return '';
  }

  static String validate(
    String username,
    String email,
    String password,
    String confirmPassword,
    String budget,
  )
  {
    String usernameError = validateUsername(username);
    if (usernameError.isNotEmpty)
    {
      return usernameError;
    }

    String emailError = validateEmail(email);
    if (emailError.isNotEmpty)
    {
      return emailError;
    }

    String passwordError = validatePassword(password);
    if (passwordError.isNotEmpty)
    {
      return passwordError;
    }

    String confirmPasswordError = validateConfirmPassword(password, confirmPassword);
    if (confirmPasswordError.isNotEmpty)
    {
      return confirmPasswordError;
    }

    String budgetError = validateBudget(budget);
    if (budgetError.isNotEmpty)
    {
      return budgetError;
    }

    return '';
  }
}