import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/utils/resend_cooldown.dart';
import '../../../shared/utils/snackbar.dart';
import '../../../shared/widgets/loading_button.dart';
import '../../../shared/widgets/otp_code_field.dart';
import '../data/auth_repository.dart';
import '../providers/auth_providers.dart';

/// Route argument for [VerifyEmailScreen].
class VerifyEmailArgs {
  const VerifyEmailArgs({required this.email, this.codeJustSent = true});

  final String email;

  /// True right after sign-up, so the resend cooldown starts immediately.
  final bool codeJustSent;
}

/// Confirms a new account with the 6-digit code from the "Confirm signup" email.
class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key, required this.args});

  final VerifyEmailArgs args;

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> with ResendCooldown {
  final _formKey = GlobalKey<FormState>();
  final _code = TextEditingController();
  bool _verifying = false;
  bool _resending = false;

  String get _email => widget.args.email;

  @override
  void initState() {
    super.initState();
    if (widget.args.codeJustSent) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) startCooldown();
      });
    }
  }

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _verifying = true);
    try {
      await ref.read(authRepositoryProvider).verifyEmailCode(
            email: _email,
            code: _code.text.trim(),
          );
      // Verifying creates a session; the router moves on to home.
    } catch (e) {
      if (mounted) showErrorSnackBar(context, authErrorMessage(e));
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  Future<void> _resend() async {
    setState(() => _resending = true);
    try {
      await ref.read(authRepositoryProvider).resendEmailCode(_email);
      if (!mounted) return;
      _code.clear();
      startCooldown();
      showInfoSnackBar(context, 'New code sent to $_email');
    } catch (e) {
      if (mounted) showErrorSnackBar(context, authErrorMessage(e));
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = _verifying || _resending;

    return Scaffold(
      appBar: AppBar(title: const Text('Verify email')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'Enter the 6-digit code we emailed to $_email.',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 24),
              OtpCodeField(controller: _code, onSubmitted: (_) => _verify()),
              const SizedBox(height: 24),
              LoadingButton(label: 'Verify', loading: _verifying, onPressed: _verify),
              const SizedBox(height: 12),
              TextButton(
                onPressed: busy || !canResend ? null : _resend,
                child: Text(resendLabel),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
