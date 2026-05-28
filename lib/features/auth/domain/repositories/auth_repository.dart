import '../models/user_model.dart';

/// AuthRepository defines the strict interface contract that the data layer
/// must implement for handling authentication tasks.
abstract class AuthRepository {
  /// Fetches the currently authenticated user session. Returns null if unauthorized.
  Future<UserModel?> getCurrentUser();

  /// Performs user authentication with email and password.
  Future<UserModel> login(String email, String password);

  /// Clears the user session and logs out.
  Future<void> logout();
}
