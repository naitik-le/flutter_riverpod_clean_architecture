import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/app_logger.dart';

/// ConnectivityStatus represents the internet connection state
enum ConnectivityStatus { online, offline }

/// Service that monitors and handles internet connectivity.
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  final _controller = StreamController<ConnectivityStatus>.broadcast();

  static bool isSimulatedOffline = false;

  ConnectivityService() {
    _init();
  }

  Stream<ConnectivityStatus> get connectivityStream => _controller.stream;

  Future<void> _init() async {
    // Initial check
    try {
      if (isSimulatedOffline) {
        _controller.add(ConnectivityStatus.offline);
      } else {
        final results = await _connectivity.checkConnectivity();
        _updateStatus(results);
      }
    } catch (e, stack) {
      AppLogger.e('Failed to check initial connectivity status', e, stack);
      _controller.add(ConnectivityStatus.offline);
    }

    // Subscribe to changes (connectivity_plus v6.x uses Stream<List<ConnectivityResult>>)
    _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        if (!isSimulatedOffline) {
          _updateStatus(results);
        }
      },
      onError: (error, stack) {
        AppLogger.e('Error inside connectivity change listener', error, stack);
      },
    );
  }

  void _updateStatus(List<ConnectivityResult> results) {
    if (isSimulatedOffline) return;

    // If the list contains only 'none' or is empty, the user is offline
    final isOffline = results.isEmpty || (results.length == 1 && results.first == ConnectivityResult.none);

    final status = isOffline ? ConnectivityStatus.offline : ConnectivityStatus.online;

    AppLogger.d('Network status updated: $status (Raw results: $results)');
    _controller.add(status);
  }

  /// Toggles simulated connection online/offline state for manual developer testing.
  void toggleSimulation(bool online) {
    isSimulatedOffline = !online;
    final status = online ? ConnectivityStatus.online : ConnectivityStatus.offline;
    AppLogger.i('Simulating Connection Status Change -> $status');
    _controller.add(status);
  }

  /// Synchronously checks if online at this exact moment
  Future<bool> get isOnline async {
    if (isSimulatedOffline) return false;
    final results = await _connectivity.checkConnectivity();
    return results.isNotEmpty && !results.contains(ConnectivityResult.none);
  }

  void dispose() {
    _controller.close();
  }
}

// --- Riverpod Providers ---

/// Provider that exposes a single instance of the [ConnectivityService]
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  final service = ConnectivityService();
  ref.onDispose(() => service.dispose());
  return service;
});

/// StreamProvider that components can watch to receive real-time updates
/// on whether the user is online or offline.
final connectivityStatusProvider = StreamProvider<ConnectivityStatus>((ref) {
  final service = ref.watch(connectivityServiceProvider);
  return service.connectivityStream;
});
