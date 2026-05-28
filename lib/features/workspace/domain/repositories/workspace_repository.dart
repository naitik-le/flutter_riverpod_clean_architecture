import '../models/workspace_model.dart';
import '../models/document_model.dart';

/// WorkspaceRepository defines the contract for accessing and managing
/// collaborative workspaces and documents, with built-in support for offline queue-based syncing.
abstract class WorkspaceRepository {
  /// Retrieves all workspaces available to the current user.
  Future<List<WorkspaceModel>> getWorkspaces();

  /// Creates a new workspace.
  Future<WorkspaceModel> createWorkspace(String name, String description);

  /// Retrieves all documents inside a specific workspace.
  Future<List<DocumentModel>> getDocuments(String workspaceId);

  /// Creates a new document within a workspace.
  Future<DocumentModel> createDocument(String workspaceId, String title, String content);

  /// Updates an existing document's content/meta.
  Future<DocumentModel> updateDocument(DocumentModel document);

  /// Plays back any pending local modifications made while offline to the remote API.
  Future<void> syncPendingOfflineEdits();

  /// Emits the count of remaining unsynced transactions in queue.
  Stream<int> get pendingSyncCountStream;
}
