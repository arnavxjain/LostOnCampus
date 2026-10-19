enum UserRole {
  student,

  /// Security staff. Created manually in the database, never by sign-up.
  admin;

  /// Unknown or missing values fall back to [student], the least-privileged role.
  static UserRole fromString(String? value) =>
      value == 'admin' ? UserRole.admin : UserRole.student;
}
