import 'dart:async';

import 'package:flutter/widgets.dart';

/// Tracks a "Resend code" cooldown on a [State]. Call [startCooldown] after a
/// code is sent and disable the resend button while [canResend] is false.
mixin ResendCooldown<T extends StatefulWidget> on State<T> {
  static const cooldownSeconds = 60;

  Timer? _cooldownTimer;
  int _secondsLeft = 0;

  int get secondsLeft => _secondsLeft;
  bool get canResend => _secondsLeft == 0;

  String get resendLabel => canResend ? 'Resend code' : 'Resend in ${_secondsLeft}s';

  void startCooldown() {
    _cooldownTimer?.cancel();
    setState(() => _secondsLeft = cooldownSeconds);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft <= 1) t.cancel();
      setState(() => _secondsLeft--);
    });
  }

  void cancelCooldown() {
    _cooldownTimer?.cancel();
    setState(() => _secondsLeft = 0);
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    super.dispose();
  }
}
