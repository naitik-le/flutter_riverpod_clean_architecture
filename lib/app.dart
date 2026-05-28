import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/controllers/auth_controller.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/workspace/presentation/screens/dashboard_screen.dart';

/// App acts as the core entry controller for SyncSpace, configuring Material,
/// importing custom themes, and routing based on user session status.
class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);

    return MaterialApp(
      title: 'SyncSpace Collaborative Suite',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // Dynamically swaps light/dark according to platform settings
      home: _routeScreen(authState),
    );
  }

  Widget _routeScreen(AuthState state) {
    if (state is Authenticated) {
      return const DashboardScreen();
    } else if (state is AuthLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    } else {
      // Unauthenticated, AuthInitial, or login errors
      return const LoginScreen();
    }
  }
}
