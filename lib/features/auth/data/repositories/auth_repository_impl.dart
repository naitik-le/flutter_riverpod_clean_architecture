import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/storage/cache_service.dart';
import '../../../../core/utils/app_logger.dart';
import '../../domain/models/user_model.dart';
import '../../domain/repositories/auth_repository.dart';

/// AuthRepositoryImpl manages user sessions, caching details in local
/// storage so that developers remain signed in while working offline.
class AuthRepositoryImpl implements AuthRepository {
  final CacheService _cacheService;
  static const String _userCacheKey = 'cached_active_user';

  AuthRepositoryImpl(this._cacheService);

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      final cachedJson = await _cacheService.get<String>(CacheService.settingsBoxName, _userCacheKey);
      if (cachedJson != null) {
        AppLogger.i('Active user restored from offline cache.');
        return UserModel.fromJson(jsonDecode(cachedJson) as Map<String, dynamic>);
      }
    } catch (e) {
      AppLogger.w('Failed to parse cached active user: $e');
    }
    return null;
  }

  @override
  Future<UserModel> login(String email, String password) async {
    // Simulating remote authentication request with a network delay
    AppLogger.d('Attempting login for $email...');
    await Future.delayed(const Duration(milliseconds: 800));

    if (email.contains('@') && password.length >= 6) {
      // Create user details (In production, this would come from the API payload)
      final name = email.split('@').first;
      final user = UserModel(id: 'usr_mock_${name.toLowerCase()}', name: name[0].toUpperCase() + name.substring(1), email: email, avatarUrl: 'https://api.dicebear.com/7.x/bottts/png?seed=$name');

      // Persist user in offline cache
      await _cacheService.put(CacheService.settingsBoxName, _userCacheKey, jsonEncode(user.toJson()));

      AppLogger.i('User ${user.name} logged in and cached locally.');
      return user;
    } else {
      AppLogger.w('Login failed for $email: Invalid credentials.');
      throw Exception('Invalid email or password (min 6 chars).');
    }
  }

  @override
  Future<void> logout() async {
    AppLogger.i('Logging user out and clearing local cache...');
    await _cacheService.delete(CacheService.settingsBoxName, _userCacheKey);
    // Clear workspaces and document boxes upon logout for security/cleanliness
    await _cacheService.clear(CacheService.workspaceBoxName);
    await _cacheService.clear(CacheService.documentBoxName);
    await _cacheService.clear(CacheService.syncQueueBoxName);
  }
}

// --- Riverpod Provider ---

/// Provider exposing the [AuthRepository] implementation injected with the [CacheService]
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final cacheService = ref.watch(cacheServiceProvider);
  return AuthRepositoryImpl(cacheService);
});
