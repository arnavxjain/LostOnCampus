/// Form field validators. Each returns an error message, or null when valid.
class Validators {
  Validators._();

  static final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final _e164 = RegExp(r'^\+[1-9]\d{7,14}$');
  static final _otp = RegExp(r'^\d{6}$');

  static const minPasswordLength = 8;

  static String? fullName(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Enter your name';
    if (v.length < 2) return 'Name is too short';
    return null;
  }

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Enter your email';
    if (!_email.hasMatch(v)) return 'Enter a valid email';
    return null;
  }

  static String? password(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Enter a password';
    if (v.length < minPasswordLength) {
      return 'Password must be at least $minPasswordLength characters';
    }
    return null;
  }

  static String? phone(String? value) {
    final v = normalizePhone(value ?? '');
    if (v.isEmpty) return 'Enter your phone number';
    if (!_e164.hasMatch(v)) return 'Include country code, e.g. +919876543210';
    return null;
  }

  static String? otp(String? value) {
    if (!_otp.hasMatch(value?.trim() ?? '')) return 'Enter the 6-digit code';
    return null;
  }

  /// Strips spaces, dashes, dots and parentheses so "+91 98765-43210" becomes E.164.
  static String normalizePhone(String value) => value.replaceAll(RegExp(r'[\s\-().]'), '');
}
