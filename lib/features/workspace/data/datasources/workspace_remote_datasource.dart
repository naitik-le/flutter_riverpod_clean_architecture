import '../../domain/models/workspace_model.dart';
import '../../domain/models/document_model.dart';
import '../../../../core/utils/app_logger.dart';

/// WorkspaceRemoteDataSource simulates an external API endpoint or Cloud Server.
/// It maintains an in-memory database during runtime to accurately simulate cloud synchronizations.
class WorkspaceRemoteDataSource {
  // Mock Cloud Database
  final List<WorkspaceModel> _remoteWorkspaces = [];
  final List<DocumentModel> _remoteDocuments = [];

  WorkspaceRemoteDataSource() {
    _seedData();
  }

  void _seedData() {
    AppLogger.d('Seeding cloud mock database with starter workspaces and docs...');

    // Seed Workspaces
    _remoteWorkspaces.addAll([
      WorkspaceModel(
        id: 'ws_eng_team',
        name: 'Engineering Workspace',
        description: 'Collaborative development plans, architecture notes, and sprint tasks.',
        ownerId: 'usr_mock_dev',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      ),
      WorkspaceModel(
        id: 'ws_marketing',
        name: 'Design & Marketing Board',
        description: 'Brand colors, asset design schedules, and social media campaigns.',
        ownerId: 'usr_mock_designer',
        createdAt: DateTime.now().subtract(const Duration(days: 15)),
      ),
    ]);

    // Seed Documents
    _remoteDocuments.addAll([
      DocumentModel(
        id: 'doc_arch_spec',
        workspaceId: 'ws_eng_team',
        title: 'System Architecture Specification',
        content:
            'Our core app is constructed using a Feature-First Clean Architecture.\n'
            'State management is handled by Riverpod.\n'
            'Local database storage uses a lightweight JSON-based Hive implementation.\n\n'
            'Developers must adhere to standard logger patterns and completely avoid print statements.',
        lastUpdatedBy: 'System Architect',
        updatedAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
      DocumentModel(
        id: 'doc_sprint_goals',
        workspaceId: 'ws_eng_team',
        title: 'Sprint 24 Goals',
        content:
            '1. Setup Clean Architecture scaffolding.\n'
            '2. Integrate Riverpod state flows.\n'
            '3. Support full offline caching.\n'
            '4. Implement responsive Web & Mobile split-pane layout.',
        lastUpdatedBy: 'Tech Lead',
        updatedAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      DocumentModel(
        id: 'doc_brand_assets',
        workspaceId: 'ws_marketing',
        title: 'Brand Colors & Aesthetics',
        content:
            'Primary Color: Indigo (HSL 239, 84%, 66%)\n'
            'Background Color: Dark Slate (Slate 900)\n'
            'Typography: Outfit for branding, Inter for functional UI body text.\n\n'
            'This styling gives a state-of-the-art developer tools feeling.',
        lastUpdatedBy: 'Lead Designer',
        updatedAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ]);
  }

  /// Simulates fetching workspaces from network
  Future<List<WorkspaceModel>> getWorkspaces() async {
    AppLogger.d('GET /workspaces ...');
    await Future.delayed(const Duration(milliseconds: 600));
    return List.from(_remoteWorkspaces);
  }

  /// Simulates creating a new workspace
  Future<WorkspaceModel> createWorkspace(WorkspaceModel ws) async {
    AppLogger.d('POST /workspaces ... Payload: ${ws.name}');
    await Future.delayed(const Duration(milliseconds: 500));
    _remoteWorkspaces.add(ws);
    return ws;
  }

  /// Simulates fetching documents from network
  Future<List<DocumentModel>> getDocuments(String workspaceId) async {
    AppLogger.d('GET /documents?workspaceId=$workspaceId ...');
    await Future.delayed(const Duration(milliseconds: 600));
    return _remoteDocuments.where((doc) => doc.workspaceId == workspaceId).toList();
  }

  /// Simulates creating a new document on server
  Future<DocumentModel> createDocument(DocumentModel doc) async {
    AppLogger.d('POST /documents ... Payload: ${doc.title}');
    await Future.delayed(const Duration(milliseconds: 500));
    _remoteDocuments.add(doc);
    return doc;
  }

  /// Simulates updating a document on server
  Future<DocumentModel> updateDocument(DocumentModel doc) async {
    AppLogger.d('PUT /documents/${doc.id} ...');
    await Future.delayed(const Duration(milliseconds: 500));

    final index = _remoteDocuments.indexWhere((element) => element.id == doc.id);
    if (index != -1) {
      _remoteDocuments[index] = doc;
      return doc;
    } else {
      // If it was created offline and server doesn't have it, add it
      _remoteDocuments.add(doc);
      return doc;
    }
  }
}
