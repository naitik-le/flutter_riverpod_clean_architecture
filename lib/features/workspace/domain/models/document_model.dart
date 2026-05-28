/// DocumentModel represents a collaborative writing canvas inside a workspace.
/// The [isSynced] field is a key component of our offline-first Clean Architecture,
/// indicating whether the local cached changes are synced to the remote server.
class DocumentModel {
  final String id;
  final String workspaceId;
  final String title;
  final String content;
  final String lastUpdatedBy;
  final DateTime updatedAt;
  final bool isSynced;

  const DocumentModel({
    required this.id,
    required this.workspaceId,
    required this.title,
    required this.content,
    required this.lastUpdatedBy,
    required this.updatedAt,
    this.isSynced = true,
  });

  /// Factory helper to build model from standard JSON map
  factory DocumentModel.fromJson(Map<String, dynamic> json) {
    return DocumentModel(
      id: json['id'] as String,
      workspaceId: json['workspaceId'] as String,
      title: json['title'] as String,
      content: json['content'] as String,
      lastUpdatedBy: json['lastUpdatedBy'] as String,
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      isSynced: json['isSynced'] as bool? ?? true,
    );
  }

  /// Converts the document state into JSON map representation
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'workspaceId': workspaceId,
      'title': title,
      'content': content,
      'lastUpdatedBy': lastUpdatedBy,
      'updatedAt': updatedAt.toIso8601String(),
      'isSynced': isSynced,
    };
  }

  /// Helper to duplicate a document model with minor updates
  DocumentModel copyWith({
    String? id,
    String? workspaceId,
    String? title,
    String? content,
    String? lastUpdatedBy,
    DateTime? updatedAt,
    bool? isSynced,
  }) {
    return DocumentModel(
      id: id ?? this.id,
      workspaceId: workspaceId ?? this.workspaceId,
      title: title ?? this.title,
      content: content ?? this.content,
      lastUpdatedBy: lastUpdatedBy ?? this.lastUpdatedBy,
      updatedAt: updatedAt ?? this.updatedAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }
}
