enum Role {
  admin('Admin'),
  employee('Employee'),
  kitchen('Kitchen');

  const Role(this.label);

  final String label;
}

class AppUser {
  final String username;
  final String password;
  final String name;
  final Role role;

  const AppUser({
    required this.username,
    required this.password,
    required this.name,
    required this.role,
  });
}
