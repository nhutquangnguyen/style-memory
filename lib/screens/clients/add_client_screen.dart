import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/loading_overlay.dart';
import '../../widgets/common/error_banner.dart';

class AddClientScreen extends StatefulWidget {
  const AddClientScreen({super.key});

  @override
  State<AddClientScreen> createState() => _AddClientScreenState();
}

class _AddClientScreenState extends State<AddClientScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _handleSaveClient() async {
    if (!_formKey.currentState!.validate()) return;

    final clientsProvider = context.read<ClientsProvider>();
    final success = await clientsProvider.createClient(
      fullName: _nameController.text.trim(),
      phone: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      email: _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim(),
    );

    if (success && mounted) {
      // Get the newly created client
      final clients = clientsProvider.clients;
      if (clients.isNotEmpty) {
        final newClient = clients.first;
        context.goNamed(
          'capture_photos',
          pathParameters: {'clientId': newClient.id},
        );
      }
    }
  }

  String? _validateEmail(String? value) {
    if (value != null && value.trim().isNotEmpty) {
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegex.hasMatch(value.trim())) {
        return 'Please enter a valid email address';
      }
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value != null && value.trim().isNotEmpty) {
      final phoneRegex = RegExp(r'^\+?[\d\s\-\(\)]+$');
      if (!phoneRegex.hasMatch(value.trim())) {
        return 'Please enter a valid phone number';
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ClientsProvider>(
      builder: (context, clientsProvider, child) {
        return LoadingOverlay(
          isLoading: clientsProvider.isLoading,
          message: 'Creating client...',
          child: Scaffold(
            appBar: AppBar(
              title: const Text('New Client'),
              actions: [
                TextButton(
                  onPressed: clientsProvider.isLoading ? null : _handleSaveClient,
                  child: const Text('Save'),
                ),
              ],
            ),
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppTheme.spacingLarge),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Error banner
                      if (clientsProvider.errorMessage != null) ...[
                        ErrorBanner(
                          message: clientsProvider.errorMessage!,
                          onDismiss: () => clientsProvider.clearError(),
                        ),
                        const SizedBox(height: AppTheme.spacingLarge),
                      ],

                      // Client name field
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Client Name',
                          hintText: 'Enter client\'s full name',
                        ),
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.words,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Client name is required';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: AppTheme.spacingMedium),

                      // Phone field
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Phone (optional)',
                          hintText: 'Enter phone number',
                        ),
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        validator: _validatePhone,
                      ),

                      const SizedBox(height: AppTheme.spacingMedium),

                      // Email field
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email (optional)',
                          hintText: 'Enter email address',
                        ),
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _handleSaveClient(),
                        validator: _validateEmail,
                      ),

                      const SizedBox(height: AppTheme.spacingLarge),

                      // Save and add photos button
                      ElevatedButton(
                        onPressed: clientsProvider.isLoading ? null : _handleSaveClient,
                        child: const Text('Save & Add Photos'),
                      ),

                      const SizedBox(height: AppTheme.spacingMedium),

                      // Info text
                      Text(
                        'After saving, you\'ll be able to capture photos for this client\'s first visit.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.secondaryTextColor,
                        ),
                        textAlign: TextAlign.center,
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