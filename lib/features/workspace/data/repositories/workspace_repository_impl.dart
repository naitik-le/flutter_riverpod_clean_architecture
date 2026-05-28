import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/network/connectivity_service.dart';
import '../../../../core/storage/cache_service.dart';
import '../../../../core/utils/app_logger.dart';
import '../../domain/models/workspace_model.dart';
import '../../domain/models/document_model.dart';
import '../../domain/repositories/workspace_repository.dart';
import '../datasources/workspace_local_datasource.dart';
import '../datasources/workspace_remote_datasource.dart';

/// WorkspaceRepositoryImpl coordinates data fetching and syncing.
/// It operates offline-first: serving local cache immediately, and
/// queuing background writes when offline to sync once reconnected.
class WorkspaceRepositoryImpl implements WorkspaceRepository {
  final WorkspaceLocalDataSource _local;
  final WorkspaceRemoteDataSource _remote;
  final ConnectivityService _connectivity;
  final CacheService _cache;
  final _uuid = const Uuid();

  // Reentrancy safety locks for offline sync queue execution
  bool _isSyncing = false;
  Completer<void>? _syncCompleter;

  // Controller to emit remaining transactions in offline sync queue
  final _syncQueueController = StreamController<int>.broadcast();

  WorkspaceRepositoryImpl({
    required WorkspaceLocalDataSource local,
    required WorkspaceRemoteDataSource remote,
    required ConnectivityService connectivity,
    required CacheService cache,
  })  : _local = local,
        _remote = remote,
        _connectivity = connectivity,
        _cache = cache {
    _initConnectivityListener();
  }

  void _initConnectivityListener() {
    // Automatically trigger offline sync playback whenever we reconnect!
    _connectivity.connectivityStream.listen((status) {
      if (status == ConnectivityStatus.online) {
        AppLogger.i('Device reconnected! Initiating offline queue synchronization...');
        syncPendingOfflineEdits();
      }
    });

    // Watch SQLite sync queue box updates to emit count changes
    _cache.watchBox(CacheService.syncQueueBoxName).listen((_) {
      _emitQueueLength();
    });
    // Emit initial length
    _emitQueueLength();
  }

  void _emitQueueLength() async {
    if (!_syncQueueController.isClosed) {
      final len = await _cache.getLength(CacheService.syncQueueBoxName);
      _syncQueueController.add(len);
    }
  }

  @override
  Stream<int> get pendingSyncCountStream => _syncQueueController.stream;

  @override
  Future<List<WorkspaceModel>> getWorkspaces() async {
    // 1. Return cache immediately
    final cached = await _local.getWorkspaces();
    AppLogger.d('Returning ${cached.length} workspaces from SQLite cache.');

    // 2. Fetch remote in the background if online
    if (await _connectivity.isOnline) {
      try {
        // Sync any pending offline changes first to avoid race conditions and overwrites
        await syncPendingOfflineEdits();

        final remoteData = await _remote.getWorkspaces();
        await _local.saveWorkspaces(remoteData);
        AppLogger.i('Workspaces updated from network and SQLite cached.');
        return remoteData;
      } catch (e, stack) {
        AppLogger.e('Failed to fetch workspaces from network, using cache', e, stack);
      }
    }

    return cached;
  }

  @override
  Future<WorkspaceModel> createWorkspace(String name, String description) async {
    final workspace = WorkspaceModel(
      id: 'ws_${_uuid.v4()}',
      name: name,
      description: description,
      ownerId: 'usr_mock_dev', // In real app, resolved from active session
      createdAt: DateTime.now(),
    );

    // Save to local SQLite cache first
    final currentCached = await _local.getWorkspaces();
    currentCached.add(workspace);
    await _local.saveWorkspaces(currentCached);

    if (await _connectivity.isOnline) {
      try {
        await _remote.createWorkspace(workspace);
        AppLogger.i('Workspace ${workspace.name} synced directly to remote.');
      } catch (e) {
        AppLogger.w('Failed to write workspace to cloud directly, enqueuing action...');
        await _enqueueAction(workspace.id, 'create_workspace', workspace.toJson());
      }
    } else {
      AppLogger.w('App is offline. Enqueuing workspace creation.');
      await _enqueueAction(workspace.id, 'create_workspace', workspace.toJson());
    }

    return workspace;
  }

  @override
  Future<List<DocumentModel>> getDocuments(String workspaceId) async {
    // 1. Return cache immediately
    final cached = await _local.getDocuments(workspaceId);
    AppLogger.d('Returning ${cached.length} documents for workspace $workspaceId from SQLite cache.');

    // 2. Fetch remote in the background if online
    if (await _connectivity.isOnline) {
      try {
        // Sync any pending offline changes first to avoid race conditions and overwrites
        await syncPendingOfflineEdits();

        final remoteData = await _remote.getDocuments(workspaceId);
        await _local.saveDocuments(remoteData);
        AppLogger.i('Documents for $workspaceId updated from network.');
        return await _local.getDocuments(workspaceId); // Return newly cached list (merging changes)
      } catch (e, stack) {
        AppLogger.e('Failed to fetch documents for $workspaceId from network', e, stack);
      }
    }

    return cached;
  }

  @override
  Future<DocumentModel> createDocument(String workspaceId, String title, String content) async {
    final isOnline = await _connectivity.isOnline;
    final document = DocumentModel(
      id: 'doc_${_uuid.v4()}',
      workspaceId: workspaceId,
      title: title,
      content: content,
      lastUpdatedBy: 'Developer',
      updatedAt: DateTime.now(),
      isSynced: isOnline,
    );

    // Save locally to SQLite
    await _local.saveDocument(document);

    if (isOnline) {
      try {
        await _remote.createDocument(document);
        AppLogger.i('Document "${document.title}" successfully synced to remote.');
      } catch (e) {
        AppLogger.w('Failed to write document online, marking unsynced and enqueuing.');
        final unsyncedDoc = document.copyWith(isSynced: false);
        await _local.saveDocument(unsyncedDoc);
        await _enqueueAction(document.id, 'create_document', unsyncedDoc.toJson());
      }
    } else {
      AppLogger.w('App is offline. Enqueuing document creation.');
      await _enqueueAction(document.id, 'create_document', document.toJson());
    }

    return document;
  }

  @override
  Future<DocumentModel> updateDocument(DocumentModel document) async {
    final isOnline = await _connectivity.isOnline;
    final updatedDoc = document.copyWith(
      updatedAt: DateTime.now(),
      lastUpdatedBy: 'Developer',
      isSynced: isOnline,
    );

    // Save locally to SQLite immediately
    await _local.saveDocument(updatedDoc);

    if (isOnline) {
      try {
        await _remote.updateDocument(updatedDoc);
        AppLogger.d('Document "${updatedDoc.title}" changes saved on server.');
      } catch (e) {
        AppLogger.w('Cloud write failed for update. Enqueuing offline.');
        final unsyncedDoc = updatedDoc.copyWith(isSynced: false);
        await _local.saveDocument(unsyncedDoc);
        await _enqueueAction(document.id, 'update_document', unsyncedDoc.toJson());
      }
    } else {
      AppLogger.d('Offline document change cached. Enqueuing update.');
      final unsyncedDoc = updatedDoc.copyWith(isSynced: false);
      await _local.saveDocument(unsyncedDoc);
      await _enqueueAction(document.id, 'update_document', unsyncedDoc.toJson());
    }

    return updatedDoc;
  }

  @override
  Future<void> syncPendingOfflineEdits() async {
    if (_isSyncing) {
      // If already syncing, await the active sync process to finish
      await _syncCompleter?.future;
      return;
    }

    final isOnline = await _connectivity.isOnline;
    if (!isOnline) {
      AppLogger.w('Sync execution aborted: device remains offline.');
      return;
    }

    final queue = await _local.getSyncQueue();
    if (queue.isEmpty) {
      AppLogger.i('Offline sync queue is empty. No operations to sync.');
      return;
    }

    _isSyncing = true;
    _syncCompleter = Completer<void>();

    try {
      AppLogger.i('Beginning synchronization of ${queue.length} pending changes...');

      for (final action in queue) {
        final actionId = action['actionId'] as String;
        final type = action['type'] as String;
        final data = action['data'] as Map<String, dynamic>;

        try {
          if (type == 'create_workspace') {
            final ws = WorkspaceModel.fromJson(data);
            await _remote.createWorkspace(ws);
            AppLogger.i('Offline action synced: Created workspace "${ws.name}" on remote.');
          } else if (type == 'create_document') {
            final doc = DocumentModel.fromJson(data);
            await _remote.createDocument(doc);

            // Mark document as synced locally
            final syncedDoc = doc.copyWith(isSynced: true);
            await _local.saveDocument(syncedDoc);
            AppLogger.i('Offline action synced: Created document "${doc.title}" on remote.');
          } else if (type == 'update_document') {
            final doc = DocumentModel.fromJson(data);
            await _remote.updateDocument(doc);

            // Mark document as synced locally
            final syncedDoc = doc.copyWith(isSynced: true);
            await _local.saveDocument(syncedDoc);
            AppLogger.i('Offline action synced: Updated document "${doc.title}" on remote.');
          }

          // Successfully synced, remove from SQLite queue
          await _local.dequeueAction(actionId);
        } catch (e, stack) {
          AppLogger.e('Failed syncing offline action $actionId ($type)', e, stack);
          // Break out to avoid infinite crash loops if remote is acting up
          break;
        }
      }

      AppLogger.i('Synchronization playback complete.');
      _emitQueueLength();
    } finally {
      _isSyncing = false;
      _syncCompleter?.complete();
      _syncCompleter = null;
    }
  }

  Future<void> _enqueueAction(String id, String type, Map<String, dynamic> dataJson) async {
    final actionMap = {'actionId': id, 'type': type, 'data': dataJson};
    await _local.enqueueAction(id, actionMap);
    _emitQueueLength();
  }

  void dispose() {
    _syncQueueController.close();
  }
}

// --- Riverpod Providers ---

/// Single instances of local and remote datasources
final workspaceLocalDataSourceProvider = Provider<WorkspaceLocalDataSource>((ref) {
  final cache = ref.watch(cacheServiceProvider);
  return WorkspaceLocalDataSource(cache);
});

final workspaceRemoteDataSourceProvider = Provider<WorkspaceRemoteDataSource>((ref) {
  return WorkspaceRemoteDataSource();
});

/// Exposes the [WorkspaceRepository] implementation injected with dependency services
final workspaceRepositoryProvider = Provider<WorkspaceRepository>((ref) {
  final local = ref.watch(workspaceLocalDataSourceProvider);
  final remote = ref.watch(workspaceRemoteDataSourceProvider);
  final connectivity = ref.watch(connectivityServiceProvider);
  final cache = ref.watch(cacheServiceProvider);

  final repo = WorkspaceRepositoryImpl(
    local: local,
    remote: remote,
    connectivity: connectivity,
    cache: cache,
  );

  ref.onDispose(() => repo.dispose());
  return repo;
});
