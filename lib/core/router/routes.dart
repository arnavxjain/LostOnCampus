class Routes {
  Routes._();

  static const splash = '/splash';
  static const login = '/login';
  static const register = '/register';
  static const verifyEmail = '/verify-email';
  static const home = '/home';
  static const myPosts = '/my-posts';
  static const notifications = '/notifications';
  static const postItem = '/post';
  static const itemDetailPattern = '/items/:id';
  static String itemDetail(String id) => '/items/$id';
  static const profile = '/profile';
  static const admin = '/admin';
  static const adminVerify = '/admin/verify';
  static const adminProfile = '/admin/profile';

  /// Reachable while signed out.
  static const publicRoutes = {login, register, verifyEmail};
}
