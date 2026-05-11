class AppUser {
  final String id;
  final String email;
  final String role; // 'student' or 'admin'

  const AppUser({
    required this.id,
    required this.email,
    required this.role,
  });
}

