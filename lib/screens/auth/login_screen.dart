import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/loading_overlay.dart';
import '../../widgets/common/error_banner.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignIn() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (success && mounted) {
      context.goNamed('clients');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        return LoadingOverlay(
          isLoading: authProvider.isLoading,
          message: 'Signing in...',
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Sign In'),
            ),
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingLarge),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: AppTheme.spacingLarge),

                      // Error banner
                      if (authProvider.errorMessage != null) ...[
                        ErrorBanner(
                          message: authProvider.errorMessage!,
                          onDismiss: () => authProvider.clearError(),
                        ),
                        const SizedBox(height: AppTheme.spacingLarge),
                      ],

                      // Email field
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          hintText: 'Enter your email address',
                        ),
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Email is required';
                          }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                            return 'Please enter a valid email address';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: AppTheme.spacingMedium),

                      // Password field
                      TextFormField(
                        controller: _passwordController,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          hintText: 'Enter your password',
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _handleSignIn(),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Password is required';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: AppTheme.spacingLarge),

                      // Sign in button
                      ElevatedButton(
                        onPressed: authProvider.isLoading ? null : _handleSignIn,
                        child: const Text('Sign In'),
                      ),

                      const SizedBox(height: AppTheme.spacingMedium),

                      // Forgot password link
                      Center(
                        child: TextButton(
                          onPressed: () {
                            // TODO: Implement forgot password
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Forgot password feature coming soon'),
                              ),
                            );
                          },
                          child: const Text('Forgot password?'),
                        ),
                      ),

                      const Spacer(),

                      // Create account link
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Don\'t have an account? ',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          TextButton(
                            onPressed: () {
                              context.goNamed('signup');
                            },
                            child: const Text('Create one'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}