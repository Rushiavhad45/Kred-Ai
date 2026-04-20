// lib/utils/validators.dart
class Validators {
  static String? validateIncome(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your income';
    }
    final income = double.tryParse(value);
    if (income == null) {
      return 'Please enter a valid number';
    }
    if (income < 1000) {
      return 'Income must be at least ₹1,000';
    }
    return null;
  }

  static String? validateEmploymentLength(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter employment length';
    }
    final length = double.tryParse(value);
    if (length == null) {
      return 'Please enter a valid number';
    }
    if (length < 0) {
      return 'Employment length cannot be negative';
    }
    return null;
  }

  static String? validateAge(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your age';
    }
    final age = int.tryParse(value);
    if (age == null) {
      return 'Please enter a valid age';
    }
    if (age < 18 || age > 100) {
      return 'Age must be between 18 and 100';
    }
    return null;
  }

  static String? validateLoanAmount(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter loan amount';
    }
    final amount = double.tryParse(value);
    if (amount == null) {
      return 'Please enter a valid amount';
    }
    if (amount <= 0) {
      return 'Loan amount must be greater than 0';
    }
    if (amount > 8000000) {
      return 'Loan amount cannot exceed ₹8,000,000';
    }
    return null;
  }

  static String? validateInterestRate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter interest rate';
    }
    final rate = double.tryParse(value);
    if (rate == null) {
      return 'Please enter a valid rate';
    }
    if (rate < 0 || rate > 50) {
      return 'Interest rate must be between 0% and 50%';
    }
    return null;
  }

  static String? validateCreditHistory(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter credit history length';
    }
    final length = double.tryParse(value);
    if (length == null) {
      return 'Please enter a valid number';
    }
    if (length < 0) {
      return 'Credit history length cannot be negative';
    }
    return null;
  }

  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Please enter a valid email';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your name';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  static String? validateConfirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != password) {
      return 'Passwords do not match';
    }
    return null;
  }
}
