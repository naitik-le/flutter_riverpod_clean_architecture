import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../controllers/auth_controller.dart';

/// LoginScreen presents a beautiful login gate using Slate and Indigo theme accents.
/// Offers full glassmorphism elements, subtle gradients, and input feedback.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: 'dev@collaborative.com');
  final _passwordController = TextEditingController(text: 'password123');
  final _obscurePassword = ValueNotifier<bool>(true);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _obscurePassword.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      ref.read(authControllerProvider.notifier).login(_emailController.text.trim(), _passwordController.text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final primaryColor = AppColors.primary;
    final textThemeColor = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondaryTextColor = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Scaffold(
      body: Stack(
        children: [
          // Background Gradient decoration
          Positioned(
            top: -200,
            left: -200,
            child: Container(
              width: 500,
              height: 500,
              decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.primary.withOpacity(0.08)),
            ),
          ),
          Positioned(
            bottom: -150,
            right: -150,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.accent.withOpacity(0.06)),
            ),
          ),

          // Main Content
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Brand Icon & Header
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(color: primaryColor.withOpacity(0.1), shape: BoxShape.circle),
                        child: Icon(Icons.grid_view_rounded, color: primaryColor, size: 48),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text('Welcome to SyncSpace', textAlign: TextAlign.center, style: AppTextStyles.display(textThemeColor)),
                    const SizedBox(height: 8),
                    Text('The premium, offline-first collaborative suite.', textAlign: TextAlign.center, style: AppTextStyles.bodyMedium(secondaryTextColor)),
                    const SizedBox(height: 36),

                    // Error Message Banner (if any)
                    if (authState is Unauthenticated && authState.errorMessage != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.error.withOpacity(0.3)),
                        ),
                        child: Text(
                          authState.errorMessage!,
                          style: AppTextStyles.caption(AppColors.error).copyWith(fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),

                    // Login Card Form
                    Container(
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceDark : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDark ? 0.3 : 0.05), blurRadius: 30, offset: const Offset(0, 10))],
                        border: Border.all(color: isDark ? AppColors.borderDark : AppColors.borderLight, width: 1),
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Email Input
                            Text('Email Address', style: AppTextStyles.bodySemiBold(textThemeColor)),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(hintText: 'e.g. dev@collaborative.com', prefixIcon: Icon(Icons.email_outlined, size: 20)),
                              validator: (val) {
                                if (val == null || val.isEmpty || !val.contains('@')) {
                                  return 'Please enter a valid email address.';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),

                            // Password Input
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Password', style: AppTextStyles.bodySemiBold(textThemeColor)),
                                Text('Min. 6 chars', style: AppTextStyles.caption(secondaryTextColor)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ValueListenableBuilder<bool>(
                              valueListenable: _obscurePassword,
                              builder: (context, obscure, child) {
                                return TextFormField(
                                  controller: _passwordController,
                                  obscureText: obscure,
                                  decoration: InputDecoration(
                                    hintText: '••••••••',
                                    prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                                    suffixIcon: IconButton(
                                      icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                                      onPressed: () => _obscurePassword.value = !obscure,
                                    ),
                                  ),
                                  validator: (val) {
                                    if (val == null || val.isEmpty || val.length < 6) {
                                      return 'Password must be at least 6 characters.';
                                    }
                                    return null;
                                  },
                                );
                              },
                            ),
                            const SizedBox(height: 28),

                            // Submit Button
                            ElevatedButton(
                              onPressed: authState is AuthLoading ? null : _submit,
                              child: authState is AuthLoading
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)))
                                  : const Text('Access Workspace'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text('Press Access Workspace to login with mock credentials', textAlign: TextAlign.center, style: AppTextStyles.caption(secondaryTextColor)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
