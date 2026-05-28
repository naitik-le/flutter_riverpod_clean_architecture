import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../utils/app_logger.dart';

/// CacheService wraps the SQFlite local database to offer fast key-value
/// and JSON-like caching for mobile and desktop platforms.
class CacheService {
  // Static Box Names to avoid string typos across the app
  static const String settingsBoxName = 'app_settings';
  static const String workspaceBoxName = 'workspaces';
  static const String documentBoxName = 'documents';
  static const String syncQueueBoxName = 'sync_queue';

  late Database _db;

  // Broadcast stream to notify listeners when a box is updated
  final _boxChangeController = StreamController<String>.broadcast();

  /// Watch stream to receive events whenever a specific cache box is updated
  Stream<String> watchBox(String boxName) {
    return _boxChangeController.stream.where((event) => event == boxName);
  }

  /// Initializes the local SQLite database. Must be called in `main.dart`
  /// prior to running `runApp`.
  Future<void> init() async {
    try {
      AppLogger.i('Initializing local SQFlite database storage...');
      final dbPath = await getDatabasesPath();
      final pathString = join(dbPath, 'syncspace_cache.db');

      _db = await openDatabase(
        pathString,
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS cache_store (
              box TEXT,
              key TEXT,
              value TEXT,
              PRIMARY KEY (box, key)
            )
          ''');
        },
      );
      AppLogger.i('SQFlite database successfully initialized and tables opened.');
    } catch (e, stack) {
      AppLogger.e('Fatal: Failed to initialize local SQFlite storage', e, stack);
      rethrow;
    }
  }

  /// Retrieves a value from a specified box. Returns [defaultValue] if the key is missing.
  Future<T?> get<T>(String boxName, String key, {T? defaultValue}) async {
    try {
      final List<Map<String, dynamic>> maps = await _db.query('cache_store', columns: ['value'], where: 'box = ? AND key = ?', whereArgs: [boxName, key]);

      if (maps.isEmpty) {
        return defaultValue;
      }

      final rawValue = maps.first['value'];
      if (T == String) {
        return rawValue as T?;
      }
      return rawValue as T?;
    } catch (e) {
      AppLogger.w('Failed to read key "$key" from box "$boxName": $e');
      return defaultValue;
    }
  }

  /// Writes a value to a specified box.
  Future<void> put<T>(String boxName, String key, T value) async {
    try {
      final valueStr = value.toString();
      await _db.insert('cache_store', {'box': boxName, 'key': key, 'value': valueStr}, conflictAlgorithm: ConflictAlgorithm.replace);
      AppLogger.d('Cached in SQLite: Box "$boxName" -> Key "$key" updated.');
      _boxChangeController.add(boxName);
    } catch (e, stack) {
      AppLogger.e('Failed to write key "$key" to box "$boxName" in SQLite', e, stack);
    }
  }

  /// Deletes a key from a specified box.
  Future<void> delete(String boxName, String key) async {
    try {
      await _db.delete('cache_store', where: 'box = ? AND key = ?', whereArgs: [boxName, key]);
      AppLogger.d('Deleted from SQLite: Box "$boxName" -> Key "$key" removed.');
      _boxChangeController.add(boxName);
    } catch (e, stack) {
      AppLogger.e('Failed to delete key "$key" from box "$boxName" in SQLite', e, stack);
    }
  }

  /// Gets all values currently cached inside a specific box.
  Future<List<dynamic>> getAll(String boxName) async {
    try {
      final List<Map<String, dynamic>> maps = await _db.query('cache_store', columns: ['value'], where: 'box = ?', whereArgs: [boxName]);
      return maps.map((row) => row['value']).toList();
    } catch (e) {
      AppLogger.w('Failed to read all values from box "$boxName" in SQLite: $e');
      return [];
    }
  }

  /// Clears all keys in a box.
  Future<void> clear(String boxName) async {
    try {
      await _db.delete('cache_store', where: 'box = ?', whereArgs: [boxName]);
      AppLogger.w('Box "$boxName" completely cleared from SQLite.');
      _boxChangeController.add(boxName);
    } catch (e, stack) {
      AppLogger.e('Failed to clear box "$boxName" in SQLite', e, stack);
    }
  }

  /// Gets the total number of elements currently stored in a specific box.
  Future<int> getLength(String boxName) async {
    try {
      final result = await _db.rawQuery('SELECT COUNT(*) FROM cache_store WHERE box = ?', [boxName]);
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      AppLogger.w('Failed to count elements in SQLite box "$boxName": $e');
      return 0;
    }
  }

  /// Closes active controllers to avoid memory leaks.
  void dispose() {
    _boxChangeController.close();
  }
}

// --- Riverpod Provider ---

/// Provider that exposes our singleton cache service instance.
final cacheServiceProvider = Provider<CacheService>((ref) {
  final service = CacheService();
  ref.onDispose(() => service.dispose());
  return service;
});
