// flutter_app/lib/utils/data_validator.dart
class DataValidator {
  // Name validation
  static String? validateFullName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Full name is required';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters long';
    }
    if (!RegExp(r'^[a-zA-Z\s\.]+$').hasMatch(value)) {
      return 'Name can only contain letters, spaces, and dots';
    }
    return null;
  }

  // Phone number validation
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    if (value.length != 10) {
      return 'Phone number must be 10 digits';
    }
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(value)) {
      return 'Enter a valid Indian mobile number';
    }
    return null;
  }

  // Email validation
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email address is required';
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  // PAN validation
  static String? validatePAN(String? value) {
    if (value != null && value.isNotEmpty) {
      if (!RegExp(r'^[A-Z]{5}[0-9]{4}[A-Z]{1}$').hasMatch(value)) {
        return 'Enter a valid PAN number (e.g., ABCDE1234F)';
      }
    }
    return null;
  }

  // Address validation
  static String? validateAddress(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Address is required';
    }
    if (value.trim().length < 10) {
      return 'Please enter a complete address';
    }
    return null;
  }

  // City validation
  static String? validateCity(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'City is required';
    }
    if (value.trim().length < 2) {
      return 'Enter a valid city name';
    }
    if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(value)) {
      return 'City name can only contain letters and spaces';
    }
    return null;
  }

  // PIN code validation
  static String? validatePinCode(String? value) {
    if (value == null || value.isEmpty) {
      return 'PIN code is required';
    }
    if (value.length != 6) {
      return 'PIN code must be 6 digits';
    }
    if (!RegExp(r'^\d{6}$').hasMatch(value)) {
      return 'Enter a valid PIN code';
    }
    return null;
  }

  // Aadhar validation
  static String? validateAadhar(String? value) {
    if (value != null && value.isNotEmpty) {
      if (value.length != 12) {
        return 'Aadhar number must be 12 digits';
      }
      if (!RegExp(r'^\d{12}$').hasMatch(value)) {
        return 'Enter a valid Aadhar number';
      }
    }
    return null;
  }

  // Date of birth validation
  static String? validateDateOfBirth(DateTime? dateOfBirth) {
    if (dateOfBirth == null) {
      return 'Date of birth is required';
    }
    
    final now = DateTime.now();
    final age = now.year - dateOfBirth.year;
    
    if (age < 18) {
      return 'You must be at least 18 years old';
    }
    
    if (age > 100) {
      return 'Please enter a valid date of birth';
    }
    
    return null;
  }
}
