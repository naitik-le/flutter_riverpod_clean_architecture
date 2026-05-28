import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/user_model.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../../../core/utils/app_logger.dart';

/// AuthState encapsulates the various phases of authentication.
abstract class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class Authenticated extends AuthState {
  final UserModel user;
  const Authenticated(this.user);
}

class Unauthenticated extends AuthState {
  final String? errorMessage;
  const Unauthenticated([this.errorMessage]);
}

/// AuthController coordinates sign-in status and coordinates state
/// transitions throughout the app lifecycle.
class AuthController extends StateNotifier<AuthState> {
  final AuthRepository _repo;

  AuthController(this._repo) : super(const AuthInitial()) {
    restoreSession();
  }

  /// RESTORE active user session from Hive cache (offline persistence check)
  Future<void> restoreSession() async {
    try {
      final user = await _repo.getCurrentUser();
      if (user != null) {
        state = Authenticated(user);
      } else {
        state = const Unauthenticated();
      }
    } catch (e) {
      state = const Unauthenticated();
    }
  }

  /// Performs secure sign-in (mock authentication validation)
  Future<void> login(String email, String password) async {
    state = const AuthLoading();
    try {
      final user = await _repo.login(email, password);
      state = Authenticated(user);
    } catch (e) {
      AppLogger.w('Login attempt failed: ${e.toString()}');
      state = Unauthenticated(e.toString().replaceAll('Exception: ', ''));
    }
  }

  /// Performs logout and resets all workspace session buffers
  Future<void> logout() async {
    state = const AuthLoading();
    await _repo.logout();
    state = const Unauthenticated();
  }
}

// --- Riverpod Providers ---

/// Exposes the [AuthController] state flow to the widgets
final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return AuthController(repo);
});

/// Simplified provider yielding whether the developer is authenticated or not
final currentUserProvider = Provider<UserModel?>((ref) {
  final authState = ref.watch(authControllerProvider);
  if (authState is Authenticated) {
    return authState.user;
  }
  return null;
});
