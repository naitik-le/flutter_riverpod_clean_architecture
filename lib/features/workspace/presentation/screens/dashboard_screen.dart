import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../controllers/workspace_controller.dart';
import '../widgets/offline_indicator.dart';
import 'package:collaborative_workspace_app/features/game/game_screen.dart';
import 'workspace_detail_screen.dart';

/// DashboardScreen is the command center showing collaborative environments.
/// Responsive grid items are sized via LayoutBuilder.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  void _showCreateWorkspaceDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('New Workspace', style: AppTextStyles.h2(AppColors.adaptiveText(context))),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Workspace Name', hintText: 'e.g. Development Team'),
                  validator: (val) => val == null || val.isEmpty ? 'Name is required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: descController,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Description', hintText: 'What is this space for?'),
                ),
              ],
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
                  ref.read(workspaceControllerProvider.notifier).addWorkspace(nameController.text.trim(), descController.text.trim());
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
  Widget build(BuildContext context, WidgetRef ref) {
    final workspacesAsync = ref.watch(workspaceControllerProvider);
    final user = ref.watch(currentUserProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final textThemeColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.layers_rounded, color: AppColors.primary, size: 26),
            const SizedBox(width: 10),
            Text('SyncSpace Dashboard', style: AppTextStyles.h2(textThemeColor)),
          ],
        ),
        actions: [
          if (MediaQuery.of(context).size.width <= 600)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: IconButton(
                tooltip: 'Playroom Game',
                icon: const Icon(Icons.sports_esports_rounded, color: AppColors.primary, size: 26),
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const GameScreen()));
                },
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Floating network status bar
            const OfflineIndicator(),

            // Premium User Greeting & Profile Header inside main canvas
            if (user != null)
              Container(
                margin: const EdgeInsets.fromLTRB(24, 16, 24, 8),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.2 : 0.02), blurRadius: 10, offset: const Offset(0, 4))],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.primary.withOpacity(0.2)),
                      child: ClipOval(
                        child: Image.network(user.avatarUrl ?? '', fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.person)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Welcome back,', style: AppTextStyles.caption(secondaryTextColor)),
                          const SizedBox(height: 2),
                          Text(user.name, style: AppTextStyles.h2(textThemeColor), maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => ref.read(authControllerProvider.notifier).logout(),
                      icon: const Icon(Icons.logout_rounded, size: 14),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        foregroundColor: AppColors.error,
                        side: BorderSide(color: AppColors.error.withOpacity(0.3)),
                      ),
                    ),
                  ],
                ),
              ),

            // Team Playroom / Breakroom Launcher Card - Visible only on Desktop/Web
            if (MediaQuery.of(context).size.width > 600)
              Container(
                margin: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [AppColors.primary.withOpacity(0.15), AppColors.accent.withOpacity(0.08)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.2), shape: BoxShape.circle),
                      child: const Icon(Icons.videogame_asset_rounded, color: AppColors.primary, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Team Breakroom', style: AppTextStyles.bodySemiBold(textThemeColor)),
                          const SizedBox(height: 2),
                          Text('Bounce off work stress! Clear bugs and tasks in our interactive breakout game.', style: AppTextStyles.caption(secondaryTextColor)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const GameScreen()));
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10)),
                      child: const Text('Play'),
                    ),
                  ],
                ),
              ),

            Expanded(
              child: workspacesAsync.when(
                data: (workspaces) {
                  if (workspaces.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.inbox_outlined, size: 64, color: AppColors.textMutedDark),
                          const SizedBox(height: 16),
                          Text('No active workspaces.', style: AppTextStyles.h3(secondaryTextColor)),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(onPressed: () => _showCreateWorkspaceDialog(context, ref), icon: const Icon(Icons.add), label: const Text('Create First Workspace')),
                        ],
                      ),
                    );
                  }

                  // Responsive Column Sizing using LayoutBuilder
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final double width = constraints.maxWidth;

                      // Calculate number of grid columns dynamically
                      final int crossAxisCount;
                      if (width <= 600) {
                        crossAxisCount = 1;
                      } else if (width <= 1000) {
                        crossAxisCount = 2;
                      } else {
                        crossAxisCount = 3;
                      }

                      return GridView.builder(
                        padding: const EdgeInsets.all(24),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: crossAxisCount, crossAxisSpacing: 20, mainAxisSpacing: 20, childAspectRatio: 1.5),
                        itemCount: workspaces.length,
                        itemBuilder: (context, index) {
                          final ws = workspaces[index];
                          return Card(
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => WorkspaceDetailScreen(workspace: ws)));
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(20.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                                          child: Icon(Icons.folder_shared_rounded, color: AppColors.primary, size: 20),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Text(ws.name, style: AppTextStyles.h3(textThemeColor), maxLines: 1, overflow: TextOverflow.ellipsis),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 16),
                                    Expanded(
                                      child: Text(ws.description, style: AppTextStyles.bodyMedium(secondaryTextColor), maxLines: 2, overflow: TextOverflow.ellipsis),
                                    ),
                                    const Divider(),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Member-owned', style: AppTextStyles.caption(AppColors.accent)),
                                        Icon(Icons.arrow_forward_ios_rounded, size: 14, color: textThemeColor.withOpacity(0.4)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(child: Text('Error loading workspaces: $err')),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: workspacesAsync.maybeWhen(
        data: (list) => list.isEmpty
            ? null
            : FloatingActionButton.extended(
                onPressed: () => _showCreateWorkspaceDialog(context, ref),
                icon: const Icon(Icons.add),
                label: const Text('New Workspace'),
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
        orElse: () => null,
      ),
    );
  }
}
