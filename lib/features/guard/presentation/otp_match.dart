import '../../../shared/models/item.dart';

/// Result of matching the code an owner gives against items at security.
class OtpMatch {
  const OtpMatch({required this.matches, required this.isFullCode, required this.alreadyUsed});

  /// Items at security whose code starts with what was typed (all of them when
  /// nothing is typed).
  final List<Item> matches;

  /// True once all 6 digits are typed.
  final bool isFullCode;

  /// A full code with no active match that belongs to an already-returned item.
  final bool alreadyUsed;

  /// A full code that matches nothing at security: nothing may be handed over.
  bool get noMatch => isFullCode && matches.isEmpty;
}

OtpMatch matchOtp({required String typed, required List<Item> atSecurity, required List<Item> returned}) {
  final matches = typed.isEmpty
      ? atSecurity
      : atSecurity.where((i) => i.handover?.code?.startsWith(typed) ?? false).toList();
  final isFullCode = typed.length == 6;
  return OtpMatch(
    matches: matches,
    isFullCode: isFullCode,
    alreadyUsed: isFullCode && matches.isEmpty && returned.any((i) => i.handover?.code == typed),
  );
}
