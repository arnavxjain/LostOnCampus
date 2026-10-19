import 'package:flutter_test/flutter_test.dart';
import 'package:loc/features/auth/data/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  String msg(String code) => authErrorMessage(AuthApiException('raw', code: code));

  test('wrong or expired code', () => expect(msg('otp_expired'), contains('wrong or has expired')));

  test('rate limits', () {
    expect(msg('over_email_send_rate_limit'), contains('Too many attempts'));
    expect(msg('over_request_rate_limit'), contains('Too many attempts'));
  });

  test('unknown codes fall back to the server message', () => expect(msg('something_new'), 'raw'));

  test('network errors', () {
    expect(authErrorMessage(AuthRetryableFetchException()), contains('Network error'));
  });

  test('server 5xx errors are not reported as network errors', () {
    String server(String body) => authErrorMessage(AuthRetryableFetchException(message: body, statusCode: '500'));
    expect(server('{"code":500,"error_code":"unexpected_failure","msg":"Error sending confirmation email"}'),
        contains('confirmation email'));
    expect(server('{"msg":"Database error saving new user"}'), contains("couldn't set up your account"));
    expect(server('{"msg":"Something odd"}'), 'Server error (500): Something odd');
    expect(server('<html>Bad gateway</html>'), contains('Server error (500)'));
  });
}
