class AppValidators {
  AppValidators._();

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    final emailRegex = RegExp(r'^[\w.+-]+@[\w-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value.trim())) return 'Enter a valid email address';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'Password must be at least 8 characters';
    return null;
  }

  static String? confirmPassword(String? value, String original) {
    if (value == null || value.isEmpty) return 'Please confirm your password';
    if (value != original) return 'Passwords do not match';
    return null;
  }

  static String? required(String? value, [String fieldName = 'This field']) {
    if (value == null || value.trim().isEmpty) return '$fieldName is required';
    return null;
  }

  static String? fullName(String? value) {
    if (value == null || value.trim().isEmpty) return 'Full name is required';
    if (value.trim().length < 2) return 'Enter a valid full name';
    return null;
  }

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return 'Phone number is required';
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 10) return 'Enter a valid 10-digit phone number';
    return null;
  }

  static String? otp(String? value) {
    if (value == null || value.isEmpty) return 'OTP is required';
    if (value.length != 6 || !RegExp(r'^\d{6}$').hasMatch(value)) {
      return 'Enter a valid 6-digit OTP';
    }
    return null;
  }

  static String? noteTooLong(String? value, [int maxLength = 1000]) {
    if (value != null && value.length > maxLength) {
      return 'Note cannot exceed $maxLength characters';
    }
    return null;
  }
}
