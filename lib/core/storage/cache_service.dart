import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/app_logger.dart';

/// CacheService wraps the Hive local database to offer fast key-value
/// and JSON-like caching for web and mobile platforms.
class CacheService {
  // Static Box Names to avoid string typos across the app
  static const String settingsBoxName = 'app_settings';
  static const String workspaceBoxName = 'workspaces';
  static const String documentBoxName = 'documents';
  static const String syncQueueBoxName = 'sync_queue';

  /// Initializes the local database storage. Must be called in `main.dart`
  /// prior to running `runApp`.
  Future<void> init() async {
    try {
      AppLogger.i('Initializing local Hive database storage...');
      await Hive.initFlutter();
      
      // Open standard boxes eagerly to prevent late-initialization lag
      await Hive.openBox(settingsBoxName);
      await Hive.openBox(workspaceBoxName);
      await Hive.openBox(documentBoxName);
      await Hive.openBox(syncQueueBoxName);
      
      AppLogger.i('Hive database successfully initialized and boxes opened.');
    } catch (e, stack) {
      AppLogger.e('Fatal: Failed to initialize local Hive storage', e, stack);
      rethrow;
    }
  }

  /// Retrieves a value from a specified box. Returns [defaultValue] if the key is missing.
  T? get<T>(String boxName, String key, {T? defaultValue}) {
    try {
      final box = Hive.box(boxName);
      return box.get(key, defaultValue: defaultValue) as T?;
    } catch (e) {
      AppLogger.w('Failed to read key "$key" from box "$boxName": $e');
      return defaultValue;
    }
  }

  /// Writes a value to a specified box.
  Future<void> put<T>(String boxName, String key, T value) async {
    try {
      final box = Hive.box(boxName);
      await box.put(key, value);
      AppLogger.d('Cached: Box "$boxName" -> Key "$key" updated.');
    } catch (e, stack) {
      AppLogger.e('Failed to write key "$key" to box "$boxName"', e, stack);
    }
  }

  /// Deletes a key from a specified box.
  Future<void> delete(String boxName, String key) async {
    try {
      final box = Hive.box(boxName);
      await box.delete(key);
      AppLogger.d('Deleted: Box "$boxName" -> Key "$key" removed.');
    } catch (e, stack) {
      AppLogger.e('Failed to delete key "$key" from box "$boxName"', e, stack);
    }
  }

  /// Gets all values currently cached inside a specific box.
  List<dynamic> getAll(String boxName) {
    try {
      final box = Hive.box(boxName);
      return box.values.toList();
    } catch (e) {
      AppLogger.w('Failed to read all values from box "$boxName": $e');
      return [];
    }
  }

  /// Clears all keys in a box.
  Future<void> clear(String boxName) async {
    try {
      final box = Hive.box(boxName);
      await box.clear();
      AppLogger.w('Box "$boxName" completely cleared.');
    } catch (e, stack) {
      AppLogger.e('Failed to clear box "$boxName"', e, stack);
    }
  }
}

// --- Riverpod Provider ---

/// Provider that exposes our singleton cache service instance.
/// This makes the storage system easy to mock in unit tests!
final cacheServiceProvider = Provider<CacheService>((ref) {
  return CacheService();
});
