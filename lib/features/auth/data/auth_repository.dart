import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Thin wrapper over Supabase Auth for the app's email/password flow.
///
/// Name and phone are stored in user metadata at sign-up; the phone is not verified.
class AuthRepository {
  AuthRepository(this._auth);

  final GoTrueClient _auth;

  User? get currentUser => _auth.currentUser;

  /// Returns true when a session was created immediately, false when the project
  /// requires email confirmation first (a 6-digit code is emailed).
  Future<bool> register({
    required String fullName,
    required String email,
    required String password,
    required String phone,
  }) async {
    final res = await _auth.signUp(
      email: email,
      password: password,
      data: {'full_name': fullName, 'phone': phone},
    );
    return res.session != null;
  }

  Future<void> verifyEmailCode({required String email, required String code}) =>
      _auth.verifyOTP(email: email, token: code, type: OtpType.signup);

  Future<void> resendEmailCode(String email) =>
      _auth.resend(email: email, type: OtpType.signup);

  Future<void> signIn({required String email, required String password}) =>
      _auth.signInWithPassword(email: email, password: password);

  Future<void> signOut() => _auth.signOut();
}

/// Maps auth errors to messages suitable for a snackbar.
String authErrorMessage(Object error) {
  debugPrint('Auth error: $error');
  if (error is AuthRetryableFetchException) {
    // Thrown both when the request never reached Supabase (no status code)
    // and when Supabase answered with a 5xx error (status code + raw body).
    if (error.statusCode == null) return 'Network error. Check your connection and try again.';
    return _serverErrorMessage(error);
  }
  if (error is AuthException) {
    switch (error.code) {
      case 'invalid_credentials':
        return 'Incorrect email or password.';
      case 'email_not_confirmed':
        return 'Please confirm your email first. Check your inbox.';
      case 'user_already_exists':
      case 'email_exists':
        return 'An account with this email already exists.';
      case 'otp_expired':
        // Supabase returns this for both wrong and expired codes.
        return 'That code is wrong or has expired. Check it or request a new one.';
      case 'otp_disabled':
        return 'Code verification is disabled on the server.';
      case 'over_request_rate_limit':
      case 'over_email_send_rate_limit':
        return 'Too many attempts. Please wait a minute and try again.';
    }
    return error.message;
  }
  return 'Something went wrong. Please try again.';
}

String _serverErrorMessage(AuthRetryableFetchException error) {
  String reason = error.message;
  try {
    final body = jsonDecode(error.message);
    if (body is Map) reason = (body['msg'] ?? body['message'] ?? body['error_description'] ?? reason).toString();
  } on FormatException {
    // Not JSON; use the raw body.
  }

  final lower = reason.toLowerCase();
  if (lower.contains('sending confirmation email') || lower.contains('sending magic link')) {
    return "Couldn't send the confirmation email. Please try again later.";
  }
  if (lower.contains('database error saving new user')) {
    return "The server couldn't set up your account. Please try again later.";
  }
  return 'Server error (${error.statusCode}): $reason';
}
