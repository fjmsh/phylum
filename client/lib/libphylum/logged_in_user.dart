class LoggedInUser {
  final int id;
  final String email;
  final String name;
  final String home;
  final int permissions;

  LoggedInUser({
    required this.id,
    required this.email,
    required this.name,
    required this.home,
    required this.permissions,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! LoggedInUser) return false;

    return id == other.id &&
        email == other.email &&
        name == other.name &&
        home == other.home &&
        permissions == other.permissions;
  }

  @override
  int get hashCode => id.hashCode ^ email.hashCode ^ name.hashCode ^ home.hashCode ^ permissions.hashCode;

  Map<String, dynamic> toJson() => {
        "id": id,
        "email": email,
        "name": name,
        "home": home,
        "permissions": permissions,
      };

  factory LoggedInUser.fromJson(Map<String, dynamic> map) {
    return LoggedInUser(
      id: map['id'],
      email: map['email'],
      name: map['name'],
      home: map['home'],
      permissions: map['permissions'],
    );
  }
}
