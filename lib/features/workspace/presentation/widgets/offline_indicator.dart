import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/connectivity_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../controllers/document_controller.dart';

/// OfflineIndicator is a floating, glassmorphic status pill
/// that visually details the application network state and offline queue size.
class OfflineIndicator extends ConsumerWidget {
  const OfflineIndicator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivityAsync = ref.watch(connectivityStatusProvider);
    final pendingCountAsync = ref.watch(pendingSyncCountProvider);

    return connectivityAsync.when(
      data: (status) {
        final pendingCount = pendingCountAsync.value ?? 0;
        final isOffline = status == ConnectivityStatus.offline;

        if (!isOffline && pendingCount == 0) {
          // Device is online and everything is synced - render nothing (clean UI)
          return const SizedBox.shrink();
        }

        // Color and icon styles based on state
        final Color pillColor;
        final Color textColor;
        final IconData icon;
        final String message;
        final bool showLoader;

        if (isOffline) {
          pillColor = AppColors.warning.withOpacity(0.15);
          textColor = AppColors.warning;
          icon = Icons.cloud_off_rounded;
          message = pendingCount > 0 
              ? 'Working Offline ($pendingCount changes cached)' 
              : 'Working Offline';
          showLoader = false;
        } else {
          // Online but syncing pending offline queue
          pillColor = AppColors.primary.withOpacity(0.15);
          textColor = AppColors.primaryLight;
          icon = Icons.sync_rounded;
          message = 'Syncing $pendingCount changes to cloud...';
          showLoader = true;
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? Color.lerp(Colors.black, pillColor, 0.5)
                : Color.lerp(Colors.white, pillColor, 0.8),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: textColor.withOpacity(0.3), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: textColor.withOpacity(0.1),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (showLoader)
                Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(textColor),
                    ),
                  ),
                )
              else
                Icon(icon, color: textColor, size: 16),
              const SizedBox(width: 8),
              Text(
                message,
                style: AppTextStyles.caption(textColor).copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
