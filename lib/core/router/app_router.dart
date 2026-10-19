import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/register_screen.dart';
import '../../features/auth/presentation/verify_email_screen.dart';
import '../../features/auth/providers/auth_providers.dart';
import '../../features/guard/presentation/admin_home_screen.dart';
import '../../features/items/presentation/feed_screen.dart';
import '../../features/items/presentation/item_detail_screen.dart';
import '../../features/items/presentation/my_posts_screen.dart';
import '../../features/items/presentation/post_item_screen.dart';
import '../../features/items/presentation/student_home_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../shared/models/user_role.dart';
import '../../shared/widgets/splash_screen.dart';
import 'routes.dart';

export 'routes.dart';

/// Pure redirect logic, kept separate from GoRouter so it can be unit tested.
///
/// - Signed out: only public routes are reachable; everything else goes to login.
/// - Role still loading or failed: wait on splash.
/// - Students can't enter `/admin`. Admins are kept inside `/admin`, except
///   that they may open item details.
@visibleForTesting
String? resolveRedirect({
  required String location,
  required bool isSignedIn,
  required AsyncValue<UserRole?> role,
}) {
  final isPublic = Routes.publicRoutes.contains(location);

  if (!isSignedIn) return isPublic ? null : Routes.login;

  final resolved = role.isLoading || role.hasError ? null : role.value;
  if (resolved == null) return location == Routes.splash ? null : Routes.splash;

  final isAdminArea = location == Routes.admin || location.startsWith('${Routes.admin}/');
  final isItemDetail = location.startsWith('/items/');
  final roleHome = resolved == UserRole.admin ? Routes.admin : Routes.home;

  if (isPublic || location == Routes.splash) return roleHome;
  if (resolved == UserRole.admin && !isAdminArea && !isItemDetail) return Routes.admin;
  if (resolved == UserRole.student && isAdminArea) return Routes.home;
  return null;
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.listen(currentUserIdProvider, (_, _) => refresh.value++);
  ref.listen(userRoleProvider, (_, _) => refresh.value++);

  final router = GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: refresh,
    redirect: (context, state) => resolveRedirect(
      location: state.matchedLocation,
      isSignedIn: ref.read(currentUserIdProvider) != null,
      role: ref.read(userRoleProvider),
    ),
    routes: [
      GoRoute(path: Routes.splash, builder: (_, _) => const SplashScreen()),
      GoRoute(path: Routes.login, builder: (_, _) => const LoginScreen()),
      GoRoute(path: Routes.register, builder: (_, _) => const RegisterScreen()),
      GoRoute(
        path: Routes.verifyEmail,
        // Needs the email from register/login; without it (e.g. app restart) go back to login.
        redirect: (_, state) => state.extra is VerifyEmailArgs ? null : Routes.login,
        builder: (_, state) => VerifyEmailScreen(args: state.extra! as VerifyEmailArgs),
      ),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => StudentHomeScreen(shell: shell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: Routes.home, builder: (_, _) => const FeedScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: Routes.myPosts, builder: (_, _) => const MyPostsScreen())]),
          StatefulShellBranch(
            routes: [GoRoute(path: Routes.notifications, builder: (_, _) => const NotificationsScreen())],
          ),
        ],
      ),
      GoRoute(path: Routes.postItem, builder: (_, _) => const PostItemScreen()),
      GoRoute(
        path: Routes.itemDetailPattern,
        builder: (_, state) => ItemDetailScreen(itemId: state.pathParameters['id']!),
      ),
      GoRoute(path: Routes.admin, builder: (_, _) => const AdminHomeScreen()),
    ],
  );

  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});
