import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/workspace_model.dart';
import '../../domain/repositories/workspace_repository.dart';
import '../../data/repositories/workspace_repository_impl.dart';

/// WorkspaceController manages the list of collaborative workspaces,
/// supporting optimistic UI updates during creation.
class WorkspaceController extends StateNotifier<AsyncValue<List<WorkspaceModel>>> {
  final WorkspaceRepository _repo;

  WorkspaceController(this._repo) : super(const AsyncValue.loading()) {
    loadWorkspaces();
  }

  /// Refreshes or loads the workspace list
  Future<void> loadWorkspaces() async {
    state = const AsyncValue.loading();
    try {
      final list = await _repo.getWorkspaces();
      state = AsyncValue.data(list);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  /// Adds a new workspace and triggers a hot state refresh
  Future<void> addWorkspace(String name, String description) async {
    final currentList = state.value ?? [];
    try {
      final newWorkspace = await _repo.createWorkspace(name, description);
      
      // Update UI state immediately (optimistic UI flow)
      state = AsyncValue.data([...currentList, newWorkspace]);
    } catch (e, stack) {
      // Rollback or emit error
      state = AsyncValue.error(e, stack);
    }
  }
}

// --- Riverpod Providers ---

/// Exposes the [WorkspaceController] state notifier
final workspaceControllerProvider = StateNotifierProvider<WorkspaceController, AsyncValue<List<WorkspaceModel>>>((ref) {
  final repo = ref.watch(workspaceRepositoryProvider);
  return WorkspaceController(repo);
});
