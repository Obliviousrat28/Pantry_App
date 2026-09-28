class LoginValidation
{
  static String validateEmail(String email)
  {
    if (email.isEmpty)
    {
      return 'Email and password cannot be empty';
    }

    if (email.length < 3)
    {
      return 'Email must be valid';
    }

    return '';
  }

  static String validatePassword(String password)
  {
    if (password.isEmpty)
    {
      return 'Email and password cannot be empty';
    }

    if (password.length < 6)
    {
      return 'Password must be at least 6 characters';
    }

    return '';
  }

  static String validate(String email, String password)
  {
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

    return '';
  }
}