import 'dart:convert';
import '../../../../core/storage/cache_service.dart';
import '../../../../core/utils/app_logger.dart';
import '../../domain/models/workspace_model.dart';
import '../../domain/models/document_model.dart';

/// WorkspaceLocalDataSource manages the translation of domain models
/// to and from raw cached JSON strings in SQFlite cache tables.
class WorkspaceLocalDataSource {
  final CacheService _cache;

  WorkspaceLocalDataSource(this._cache);

  /// Retrieves cached workspaces.
  Future<List<WorkspaceModel>> getWorkspaces() async {
    try {
      final list = await _cache.getAll(CacheService.workspaceBoxName);
      return list.map((item) => WorkspaceModel.fromJson(jsonDecode(item as String) as Map<String, dynamic>)).toList();
    } catch (e) {
      AppLogger.w('Failed to parse cached workspaces: $e');
      return [];
    }
  }

  /// Caches a batch list of workspaces.
  Future<void> saveWorkspaces(List<WorkspaceModel> list) async {
    await _cache.clear(CacheService.workspaceBoxName);
    for (final ws in list) {
      await _cache.put(CacheService.workspaceBoxName, ws.id, jsonEncode(ws.toJson()));
    }
  }

  /// Retrieves cached documents for a given workspace.
  Future<List<DocumentModel>> getDocuments(String workspaceId) async {
    try {
      final list = await _cache.getAll(CacheService.documentBoxName);
      return list.map((item) => DocumentModel.fromJson(jsonDecode(item as String) as Map<String, dynamic>)).where((doc) => doc.workspaceId == workspaceId).toList();
    } catch (e) {
      AppLogger.w('Failed to parse cached documents: $e');
      return [];
    }
  }

  /// Caches a single document (adds or updates).
  Future<void> saveDocument(DocumentModel doc) async {
    await _cache.put(CacheService.documentBoxName, doc.id, jsonEncode(doc.toJson()));
  }

  /// Caches a list of documents.
  Future<void> saveDocuments(List<DocumentModel> docs) async {
    for (final doc in docs) {
      await saveDocument(doc);
    }
  }

  // --- Offline Sync Queue Helpers ---

  /// Retrieves the current queued offline actions
  Future<List<Map<String, dynamic>>> getSyncQueue() async {
    try {
      final rawList = await _cache.getAll(CacheService.syncQueueBoxName);
      return rawList.map((item) => jsonDecode(item as String) as Map<String, dynamic>).toList();
    } catch (e) {
      AppLogger.e('Failed to parse sync queue: $e');
      return [];
    }
  }

  /// Appends an action command (like create or update doc) to the offline queue
  Future<void> enqueueAction(String actionId, Map<String, dynamic> actionMap) async {
    await _cache.put(CacheService.syncQueueBoxName, actionId, jsonEncode(actionMap));
    AppLogger.d('Enqueued offline action: $actionId');
  }

  /// Removes an action from the queue once successfully synced to the remote API
  Future<void> dequeueAction(String actionId) async {
    await _cache.delete(CacheService.syncQueueBoxName, actionId);
    AppLogger.d('Dequeued offline action: $actionId');
  }
}
