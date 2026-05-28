/// UserModel represents a registered user or developer participating
/// inside a collaborative workspace.
class UserModel {
  final String id;
  final String name;
  final String email;
  final String? avatarUrl;

  const UserModel({required this.id, required this.name, required this.email, this.avatarUrl});

  /// Factory helper to build model from standard JSON map
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(id: json['id'] as String, name: json['name'] as String, email: json['email'] as String, avatarUrl: json['avatarUrl'] as String?);
  }

  /// Converts the user state into JSON map representation
  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'email': email, 'avatarUrl': avatarUrl};
  }

  /// Helper to duplicate a user model with minor updates
  UserModel copyWith({String? id, String? name, String? email, String? avatarUrl}) {
    return UserModel(id: id ?? this.id, name: name ?? this.name, email: email ?? this.email, avatarUrl: avatarUrl ?? this.avatarUrl);
  }
}
