import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/routes.dart';
import '../../core/theme/app_colors.dart';
import 'profile_avatar.dart';

/// Top bar used across the app: the "LostOnCampus" wordmark (or a page title)
/// on the left and the profile avatar on the right.
class AppHeader extends StatelessWidget implements PreferredSizeWidget {
  const AppHeader({super.key, this.title, this.showAvatar = true, this.onAvatarTap, this.actions = const []});

  /// Page title; null shows the brand wordmark.
  final String? title;
  final bool showAvatar;

  /// Defaults to opening the student profile page.
  final VoidCallback? onAvatarTap;
  final List<Widget> actions;

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AppBar(
      toolbarHeight: 64,
      titleSpacing: 20,
      title: Text(
        title ?? 'LostOnCampus',
        style: title == null
            ? textTheme.headlineSmall?.copyWith(color: AppColors.teal, fontWeight: FontWeight.w800, letterSpacing: -0.4)
            : textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
      actions: [
        ...actions,
        if (showAvatar)
          Padding(
            padding: const EdgeInsets.only(right: 20, left: 8),
            child: ProfileAvatar(onTap: onAvatarTap ?? () => context.push(Routes.profile)),
          ),
      ],
    );
  }
}
