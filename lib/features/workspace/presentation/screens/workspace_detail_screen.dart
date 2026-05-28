import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/connectivity_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/responsive_layout.dart';
import '../../domain/models/workspace_model.dart';
import '../../domain/models/document_model.dart';
import '../controllers/document_controller.dart';
import '../widgets/offline_indicator.dart';

/// WorkspaceDetailScreen renders the multi-pane split document workspace editor.
/// It uses [ResponsiveLayout] to support a three-pane editor layout on Desktop/Web
/// and single-pane navigational workflows on Mobile.
class WorkspaceDetailScreen extends ConsumerStatefulWidget {
  final WorkspaceModel workspace;

  const WorkspaceDetailScreen({super.key, required this.workspace});

  @override
  ConsumerState<WorkspaceDetailScreen> createState() => _WorkspaceDetailScreenState();
}

class _WorkspaceDetailScreenState extends ConsumerState<WorkspaceDetailScreen> {
  final _contentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Load documents for active workspace on start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(documentControllerProvider.notifier).loadDocuments(widget.workspace.id);
    });
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  void _selectDocument(DocumentModel doc) {
    ref.read(activeDocumentProvider.notifier).state = doc;
    _contentController.text = doc.content;
  }

  void _createNewDocument(BuildContext context) {
    final titleController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
          title: Text('New Document', style: AppTextStyles.h2(AppColors.adaptiveText(context))),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: titleController,
              decoration: const InputDecoration(labelText: 'Document Title', hintText: 'e.g. Sprint Architecture Spec'),
              validator: (val) => val == null || val.isEmpty ? 'Title is required' : null,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: AppColors.adaptiveText(context).withOpacity(0.6))),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  ref.read(documentControllerProvider.notifier).addDocument(titleController.text.trim(), 'Start editing your collaborative canvas here...');
                  Navigator.pop(context);
                }
              },
              child: const Text('Create'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final documentsAsync = ref.watch(documentControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final textThemeColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    // Watch connection dynamically to update connection switch
    final connectionAsync = ref.watch(connectivityStatusProvider);
    final isOnline = connectionAsync.value == ConnectivityStatus.online;

    // Detect if we should use responsive split pane
    final isDesktop = ResponsiveLayout.isDesktop(context);

    // Watch active document pointer in Riverpod
    final activeDoc = ref.watch(activeDocumentProvider);

    // Synchronize text controller when active document changes
    ref.listen<DocumentModel?>(activeDocumentProvider, (prev, next) {
      if (next != null && prev?.id != next.id) {
        _contentController.text = next.content;
      }
    });

    // Update active document sync/content pointers dynamically when list shifts
    ref.listen<AsyncValue<List<DocumentModel>>>(documentControllerProvider, (prev, next) {
      final docs = next.value;
      final currentActive = ref.read(activeDocumentProvider);
      if (docs != null && currentActive != null) {
        final matchingDoc = docs.firstWhere((d) => d.id == currentActive.id, orElse: () => currentActive);
        if (matchingDoc != currentActive && (matchingDoc.isSynced != currentActive.isSynced || matchingDoc.content != currentActive.content)) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(activeDocumentProvider.notifier).state = matchingDoc;
          });
        }
      } else if (docs != null && docs.isNotEmpty && currentActive == null && isDesktop) {
        // Auto select first document on desktop if nothing selected
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _selectDocument(docs.first);
        });
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.workspace.name),
        actions: [
          // SIMULATOR CONTROL: Dynamic switch to test offline-first queuing
          Row(
            children: [
              Icon(isOnline ? Icons.wifi_rounded : Icons.wifi_off_rounded, color: isOnline ? AppColors.accent : AppColors.warning, size: 18),
              const SizedBox(width: 8),
              Switch(
                value: isOnline,
                activeColor: AppColors.accent,
                onChanged: (val) {
                  ref.read(connectivityServiceProvider).toggleSimulation(val);
                },
              ),
            ],
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const OfflineIndicator(),
            Expanded(
              child: ResponsiveLayout(
                mobileBody: _buildMobileBody(documentsAsync, textThemeColor, secondaryTextColor),
                desktopBody: _buildDesktopBody(documentsAsync, textThemeColor, secondaryTextColor),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: ResponsiveLayout.isMobile(context)
          ? FloatingActionButton(onPressed: () => _createNewDocument(context), backgroundColor: AppColors.primary, foregroundColor: Colors.white, child: const Icon(Icons.add_rounded))
          : null,
    );
  }

  // --- RESPONSIVE MOBILE VIEW ---
  Widget _buildMobileBody(AsyncValue<List<DocumentModel>> documentsAsync, Color textThemeColor, Color secondaryTextColor) {
    return documentsAsync.when(
      data: (docs) {
        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.description_outlined, size: 48, color: AppColors.textMutedDark),
                const SizedBox(height: 16),
                Text('No documents in this workspace', style: AppTextStyles.bodyMedium(secondaryTextColor)),
                const SizedBox(height: 16),
                ElevatedButton.icon(onPressed: () => _createNewDocument(context), icon: const Icon(Icons.add), label: const Text('Add Document')),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final doc = docs[index];
            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                onTap: () {
                  _selectDocument(doc);
                  Navigator.push(context, MaterialPageRoute(builder: (context) => _buildMobileEditorScreen(doc)));
                },
                title: Text(doc.title, style: AppTextStyles.bodySemiBold(textThemeColor)),
                subtitle: Text(doc.content, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.caption(secondaryTextColor)),
                trailing: _buildSyncStatusBadge(doc),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Error: $err')),
    );
  }

  // --- MOBILE SUB-PAGE EDITOR ---
  Widget _buildMobileEditorScreen(DocumentModel doc) {
    final activeDoc = ref.watch(activeDocumentProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(doc.title),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(child: _buildSyncStatusBadge(activeDoc ?? doc)),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const OfflineIndicator(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _contentController,
                        maxLines: null,
                        expands: true,
                        decoration: const InputDecoration(hintText: 'Start writing...', border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none, filled: false),
                        onChanged: (text) {
                          final currentActive = ref.read(activeDocumentProvider);
                          if (currentActive != null) {
                            ref.read(documentControllerProvider.notifier).editDocument(currentActive, text);
                          }
                        },
                      ),
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${_contentController.text.length} characters', style: AppTextStyles.caption(AppColors.textMutedDark)),
                        Text('Optimistic Sync Mode', style: AppTextStyles.caption(AppColors.accent)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- RESPONSIVE WEB/DESKTOP VIEW ---
  Widget _buildDesktopBody(AsyncValue<List<DocumentModel>> documentsAsync, Color textThemeColor, Color secondaryTextColor) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final activeDoc = ref.watch(activeDocumentProvider);

    return Row(
      children: [
        // Left Column: Document Switcher Pane
        Container(
          width: 300,
          decoration: BoxDecoration(
            border: Border(right: BorderSide(color: Theme.of(context).dividerColor)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton.icon(onPressed: () => _createNewDocument(context), icon: const Icon(Icons.add), label: const Text('Add Document')),
              ),
              const Divider(),
              Expanded(
                child: documentsAsync.when(
                  data: (docs) {
                    if (docs.isEmpty) {
                      return Center(child: Text('No documents found.', style: AppTextStyles.caption(secondaryTextColor)));
                    }
                    return ListView.builder(
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final doc = docs[index];
                        final isSelected = activeDoc?.id == doc.id;
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent, borderRadius: BorderRadius.circular(8)),
                          child: ListTile(
                            onTap: () => _selectDocument(doc),
                            title: Text(doc.title, style: AppTextStyles.bodySemiBold(isSelected ? AppColors.primary : textThemeColor)),
                            subtitle: Text(doc.content, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppTextStyles.caption(secondaryTextColor)),
                            trailing: _buildSyncStatusBadge(doc),
                          ),
                        );
                      },
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(child: Text('Error: $err')),
                ),
              ),
            ],
          ),
        ),

        // Middle Column: Elegant Document Editor
        Expanded(
          flex: 3,
          child: activeDoc == null
              ? Center(child: Text('Select a document to begin writing.', style: AppTextStyles.bodyMedium(secondaryTextColor)))
              : Padding(
                  padding: const EdgeInsets.all(28.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(activeDoc.title, style: AppTextStyles.h1(textThemeColor)),
                          _buildSyncStatusBadge(activeDoc),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                          ),
                          child: TextField(
                            controller: _contentController,
                            maxLines: null,
                            expands: true,
                            decoration: const InputDecoration(
                              hintText: 'Start drafting details...',
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              filled: false,
                            ),
                            onChanged: (text) {
                              final currentActive = ref.read(activeDocumentProvider);
                              if (currentActive != null) {
                                ref.read(documentControllerProvider.notifier).editDocument(currentActive, text);
                              }
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Words: ${_contentController.text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length}  |  Characters: ${_contentController.text.length}',
                            style: AppTextStyles.caption(AppColors.textMutedDark),
                          ),
                          Text('Optimistic Local Saving Active', style: AppTextStyles.caption(AppColors.accent)),
                        ],
                      ),
                    ],
                  ),
                ),
        ),

        // Right Column: Canvas Details & History Pane
        if (activeDoc != null)
          Container(
            width: 260,
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: Theme.of(context).dividerColor)),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Canvas Details', style: AppTextStyles.h3(textThemeColor)),
                const SizedBox(height: 20),
                _buildInfoTile('Workspace ID', activeDoc.workspaceId, secondaryTextColor),
                _buildInfoTile('Document ID', activeDoc.id, secondaryTextColor),
                _buildInfoTile('Last Updated By', activeDoc.lastUpdatedBy, secondaryTextColor),
                _buildInfoTile('Last Updated', '${activeDoc.updatedAt.hour}:${activeDoc.updatedAt.minute.toString().padLeft(2, '0')}', secondaryTextColor),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primary.withOpacity(0.1)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.offline_bolt_rounded, color: AppColors.primary, size: 28),
                      const SizedBox(height: 10),
                      Text('Offline Mode Active', style: AppTextStyles.bodySemiBold(textThemeColor), textAlign: TextAlign.center),
                      const SizedBox(height: 6),
                      Text('Disconnect network switch above to trigger queuing logic.', style: AppTextStyles.caption(secondaryTextColor), textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildInfoTile(String label, String val, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.caption(color).copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(val, style: AppTextStyles.bodyMedium(color), overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildSyncStatusBadge(DocumentModel doc) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: doc.isSynced ? AppColors.accent.withOpacity(0.1) : AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: doc.isSynced ? AppColors.accent.withOpacity(0.3) : AppColors.warning.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(doc.isSynced ? Icons.cloud_done_rounded : Icons.offline_pin_rounded, size: 12, color: doc.isSynced ? AppColors.accent : AppColors.warning),
          const SizedBox(width: 6),
          Text(doc.isSynced ? 'Synced' : 'Sync Pending', style: AppTextStyles.caption(doc.isSynced ? AppColors.accent : AppColors.warning).copyWith(fontWeight: FontWeight.bold, fontSize: 10)),
        ],
      ),
    );
  }
}
