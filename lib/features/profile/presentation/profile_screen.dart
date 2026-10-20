import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../shared/models/profile.dart';
import '../../../shared/models/user_role.dart';
import '../../../shared/widgets/app_header.dart';
import '../../../shared/widgets/async_view.dart';
import '../../../shared/widgets/pill.dart';
import '../../../shared/widgets/profile_avatar.dart';
import '../../auth/providers/auth_providers.dart';
import '../../items/presentation/widgets/item_grid.dart';
import '../../items/presentation/widgets/owner_pills.dart';
import '../../items/providers/items_providers.dart';

/// The signed-in user's details and sign out. Students also see their posts.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key, this.showPosts = true});

  final bool showPosts;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(currentProfileProvider);

    return Scaffold(
      appBar: const AppHeader(title: 'Profile', showAvatar: false),
      body: AsyncView(
        value: profile,
        onRetry: () => ref.invalidate(currentProfileProvider),
        data: (p) {
          final header = _ProfileHeader(profile: p, onSignOut: () => ref.read(authRepositoryProvider).signOut());
          if (!showPosts) {
            return ListView(children: [header]);
          }

          final posts = ref.watch(myItemsProvider);
          return RefreshIndicator(
            onRefresh: () => ref.refresh(myItemsProvider.future),
            child: posts.when(
              data: (list) => ItemGrid(
                header: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    header,
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                      child: Text(
                        list.isEmpty ? 'You haven\'t posted anything yet.' : 'My posts',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
                items: list,
                pillsFor: ownerPills,
                onTap: (item) => context.push(Routes.itemDetail(item.id)),
              ),
              loading: () => ListView(
                children: [header, const Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator()))],
              ),
              error: (e, _) => ListView(
                children: [
                  header,
                  MessageView(
                    icon: CupertinoIcons.wifi_slash,
                    title: "Couldn't load your posts",
                    action: FilledButton.tonalIcon(
                      onPressed: () => ref.invalidate(myItemsProvider),
                      icon: const Icon(CupertinoIcons.arrow_clockwise, size: 18),
                      label: const Text('Retry'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profile, required this.onSignOut});

  final Profile? profile;
  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final p = profile;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
      child: Column(
        children: [
          const ProfileAvatar(size: 88),
          const SizedBox(height: 14),
          Text(
            (p?.fullName.isNotEmpty ?? false) ? p!.fullName : 'Your profile',
            style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          if (p?.email case final email?) Text(email, style: textTheme.bodyMedium),
          if (p?.phone case final phone? when phone.isNotEmpty) Text(phone, style: textTheme.bodyMedium),
          const SizedBox(height: 10),
          Pill(
            p?.role == UserRole.admin ? 'Security' : 'Student',
            icon: p?.role == UserRole.admin ? CupertinoIcons.shield : CupertinoIcons.book,
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(onPressed: onSignOut, icon: const Icon(CupertinoIcons.square_arrow_right), label: const Text('Sign out')),
        ],
      ),
    );
  }
}
