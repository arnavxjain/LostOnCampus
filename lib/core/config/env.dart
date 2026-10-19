import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Typed access to values loaded from `.env`.
class Env {
  Env._();

  static Future<void> load() => dotenv.load(fileName: '.env');

  static String get supabaseUrl => _require('SUPABASE_URL');
  static String get supabasePublishableKey => _require('SUPABASE_PUBLISHABLE_KEY');

  static String _require(String key) {
    final value = dotenv.maybeGet(key)?.trim() ?? '';
    if (value.isEmpty || value.contains('your-')) {
      throw StateError('Missing $key in .env. Copy .env.example to .env and fill it in.');
    }
    return value;
  }
}
