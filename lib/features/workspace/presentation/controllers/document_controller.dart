import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/document_model.dart';
import '../../domain/repositories/workspace_repository.dart';
import '../../data/repositories/workspace_repository_impl.dart';

/// DocumentController manages the documents within an active workspace.
/// Coordinates optimistic edits, local persistence triggers, and sync queues.
class DocumentController extends StateNotifier<AsyncValue<List<DocumentModel>>> {
  final WorkspaceRepository _repo;
  String? _activeWorkspaceId;

  DocumentController(this._repo) : super(const AsyncValue.loading());

  /// Loads documents for a specific workspace and holds the active pointer
  Future<void> loadDocuments(String workspaceId) async {
    _activeWorkspaceId = workspaceId;
    state = const AsyncValue.loading();
    try {
      final list = await _repo.getDocuments(workspaceId);
      // Ensure we only update state if the user didn't switch workspaces in the meantime
      if (_activeWorkspaceId == workspaceId) {
        state = AsyncValue.data(list);
      }
    } catch (e, stack) {
      if (_activeWorkspaceId == workspaceId) {
        state = AsyncValue.error(e, stack);
      }
    }
  }

  /// Creates a new document and adds it to the active workspace list
  Future<void> addDocument(String title, String content) async {
    final wsId = _activeWorkspaceId;
    if (wsId == null) return;

    final currentDocs = state.value ?? [];
    try {
      final newDoc = await _repo.createDocument(wsId, title, content);

      // Update UI immediately (optimistic update)
      if (_activeWorkspaceId == wsId) {
        state = AsyncValue.data([...currentDocs, newDoc]);
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Edits the text content of a document and triggers local/remote sync saving.
  Future<void> editDocument(DocumentModel doc, String newContent) async {
    final wsId = _activeWorkspaceId;
    if (wsId == null) return;

    final currentDocs = state.value ?? [];
    final updatedDoc = doc.copyWith(content: newContent);

    // 1. Instantly update UI (highly responsive optimistic typing feed)
    final updatedList = currentDocs.map((item) {
      return item.id == doc.id ? updatedDoc : item;
    }).toList();
    state = AsyncValue.data(updatedList);

    // 2. Persist in background repository
    try {
      await _repo.updateDocument(updatedDoc);

      // If synced successfully from background, we might refresh state to reflect latest timestamps
      // but keeping optimistic state preserves seamless editing experience.
    } catch (e) {
      // Offline writes do not throw, but in case of a fatal error we could handle it
    }
  }
}

// --- Riverpod Providers ---

/// Exposes the [DocumentController] to the views
final documentControllerProvider = StateNotifierProvider<DocumentController, AsyncValue<List<DocumentModel>>>((ref) {
  final repo = ref.watch(workspaceRepositoryProvider);
  return DocumentController(repo);
});

/// Exposes the active selected document inside a workspace
final activeDocumentProvider = StateProvider<DocumentModel?>((ref) => null);

/// Exposes the active synchronization pending items count
final pendingSyncCountProvider = StreamProvider<int>((ref) {
  final repo = ref.watch(workspaceRepositoryProvider);
  return repo.pendingSyncCountStream;
});
