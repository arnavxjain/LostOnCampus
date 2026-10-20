import 'dart:io';

import 'package:http/http.dart' show ClientException;
import 'package:supabase_flutter/supabase_flutter.dart';

/// Maps data/storage errors to short messages suitable for a snackbar.
String friendlyError(Object error) {
  // ClientException: the HTTP request itself failed (e.g. connection dropped).
  if (error is SocketException || error is ClientException || error is AuthRetryableFetchException) {
    return 'Network error. Check your connection and try again.';
  }
  if (error is StorageException) {
    return switch (error.statusCode) {
      '413' => 'That image is too large (max 5 MB).',
      '415' => "That image type isn't supported. Use JPG, PNG, WebP or HEIC.",
      _ => "Couldn't upload the image. Please try again.",
    };
  }
  if (error is PostgrestException) {
    // Raised by our own database functions with a user-facing message.
    if (error.code == 'P0001') return error.message;
    if (error.code == '42501') return "You don't have permission to do that.";
    return 'Something went wrong on the server. Please try again.';
  }
  if (error is StateError) return error.message;
  return 'Something went wrong. Please try again.';
}
