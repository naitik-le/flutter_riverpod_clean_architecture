/// WorkspaceModel represents a container of collaborative document resources
/// managed by users.
class WorkspaceModel {
  final String id;
  final String name;
  final String description;
  final String ownerId;
  final DateTime createdAt;

  const WorkspaceModel({
    required this.id,
    required this.name,
    required this.description,
    required this.ownerId,
    required this.createdAt,
  });

  /// Factory helper to build model from standard JSON map
  factory WorkspaceModel.fromJson(Map<String, dynamic> json) {
    return WorkspaceModel(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      ownerId: json['ownerId'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  /// Converts the workspace state into JSON map representation
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'ownerId': ownerId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Helper to duplicate a workspace model with minor updates
  WorkspaceModel copyWith({
    String? id,
    String? name,
    String? description,
    String? ownerId,
    DateTime? createdAt,
  }) {
    return WorkspaceModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      ownerId: ownerId ?? this.ownerId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
