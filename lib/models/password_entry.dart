class PasswordEntry {
  final String id;
  final String title;
  final String username;
  final String password;
  final String? totpSecret;
  final DateTime createdAt;
  final DateTime modifiedAt;

  PasswordEntry({
    required this.id,
    required this.title,
    required this.username,
    required this.password,
    this.totpSecret,
    required this.createdAt,
    required this.modifiedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'username': username,
      'password': password,
      'totpSecret': totpSecret,
      'createdAt': createdAt.toIso8601String(),
      'modifiedAt': modifiedAt.toIso8601String(),
    };
  }

  factory PasswordEntry.fromMap(Map<String, dynamic> map) {
    return PasswordEntry(
      id: map['id'],
      title: map['title'],
      username: map['username'],
      password: map['password'],
      totpSecret: map['totpSecret'],
      createdAt: DateTime.parse(map['createdAt']),
      modifiedAt: DateTime.parse(map['modifiedAt']),
    );
  }
} 