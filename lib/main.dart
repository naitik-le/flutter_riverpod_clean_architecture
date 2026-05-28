import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';
import 'core/storage/cache_service.dart';
import 'core/utils/app_logger.dart';

void main() async {
  // Ensure Flutter engine integrations are initialized prior to DB actions
  WidgetsFlutterBinding.ensureInitialized();

  // Create cache service and initialize offline Hive storage boxes
  final cacheService = CacheService();
  
  try {
    await cacheService.init();
  } catch (e, stack) {
    AppLogger.e('Fatal application startup failure: local storage crashed.', e, stack);
  }

  runApp(
    // Wrap root with ProviderScope to activate Riverpod across all widgets.
    // Injected CacheService is registered here to be shared throughout the project lifecycle.
    ProviderScope(overrides: [cacheServiceProvider.overrideWithValue(cacheService)], child: const App()),
  );
}
