import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../features/auth/providers/auth_providers.dart';

/// The signed-in user's initial on the accent circle.
class ProfileAvatar extends ConsumerWidget {
  const ProfileAvatar({super.key, this.size = 36, this.onTap});

  final double size;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final initial = ref.watch(currentProfileProvider).value?.initial ?? '';
    final avatar = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(color: AppColors.accent, shape: BoxShape.circle),
      child: Text(
        initial,
        style: TextStyle(fontSize: size * 0.42, fontWeight: FontWeight.w600, color: AppColors.ink),
      ),
    );
    if (onTap == null) return avatar;
    return Semantics(
      button: true,
      label: 'Profile',
      child: InkResponse(onTap: onTap, radius: size * 0.7, child: avatar),
    );
  }
}
