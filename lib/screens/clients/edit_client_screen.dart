import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/loading_overlay.dart';
import '../../widgets/common/error_banner.dart';
import '../../l10n/app_localizations.dart';

class EditClientScreen extends StatefulWidget {
  final String clientId;

  const EditClientScreen({
    super.key,
    required this.clientId,
  });

  @override
  State<EditClientScreen> createState() => _EditClientScreenState();
}

class _EditClientScreenState extends State<EditClientScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();

  Client? _client;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeClient();
    });
  }

  void _initializeClient() {
    final clientsProvider = context.read<ClientsProvider>();
    final client = clientsProvider.getClientById(widget.clientId);

    if (client != null) {
      setState(() {
        _client = client;
        _nameController.text = client.fullName;
        _phoneController.text = client.phone ?? '';
        _emailController.text = client.email ?? '';
        _isInitialized = true;
      });
    } else {
      // Client not found, navigate back to clients list
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          context.goNamed('clients');
        }
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _handleCancel() {
    // Navigate back to client profile without saving
    context.goNamed(
      'client_profile',
      pathParameters: {'clientId': widget.clientId},
    );
  }

  Future<void> _handleUpdateClient() async {
    if (!_formKey.currentState!.validate()) return;
    if (_client == null) return;

    final clientsProvider = context.read<ClientsProvider>();

    // Create updated client with new values
    final updatedClient = _client!.copyWith(
      fullName: _nameController.text.trim(),
      phone: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      email: _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim(),
      updatedAt: DateTime.now(),
    );

    final success = await clientsProvider.updateClient(updatedClient);

    if (success && mounted) {
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Client updated successfully'), // TODO: Add to localization
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );

      // Navigate back to client profile
      context.goNamed(
        'client_profile',
        pathParameters: {'clientId': widget.clientId},
      );
    }
  }

  String? _validateEmail(String? value) {
    final l10n = AppLocalizations.of(context)!;
    if (value != null && value.trim().isNotEmpty) {
      final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
      if (!emailRegex.hasMatch(value.trim())) {
        return l10n.pleaseEnterValidEmail;
      }
    }
    return null;
  }

  String? _validatePhone(String? value) {
    final l10n = AppLocalizations.of(context)!;
    if (value != null && value.trim().isNotEmpty) {
      final phoneRegex = RegExp(r'^\+?[\d\s\-\(\)]+$');
      if (!phoneRegex.hasMatch(value.trim())) {
        return l10n.pleaseEnterValidPhoneNumber;
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    if (!_isInitialized) {
      return Scaffold(
        appBar: AppBar(
          title: Text(l10n.editClient),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Consumer<ClientsProvider>(
      builder: (context, clientsProvider, child) {
        return LoadingOverlay(
          isLoading: clientsProvider.isLoading,
          message: 'Updating client...',
          child: Scaffold(
            appBar: AppBar(
              title: Text(l10n.editClient),
              actions: [
                TextButton(
                  onPressed: clientsProvider.isLoading ? null : _handleCancel,
                  child: Text(l10n.cancel),
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
                        decoration: InputDecoration(
                          labelText: l10n.clientName,
                          hintText: l10n.enterClientFullName,
                        ),
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.words,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return l10n.clientNameRequired;
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: AppTheme.spacingMedium),

                      // Phone field
                      TextFormField(
                        controller: _phoneController,
                        decoration: InputDecoration(
                          labelText: l10n.phoneOptional,
                          hintText: l10n.enterPhoneNumber,
                        ),
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        validator: _validatePhone,
                      ),

                      const SizedBox(height: AppTheme.spacingMedium),

                      // Email field
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: l10n.emailOptional,
                          hintText: l10n.enterEmailAddress,
                        ),
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _handleUpdateClient(),
                        validator: _validateEmail,
                      ),

                      const SizedBox(height: AppTheme.spacingLarge),

                      // Save button
                      ElevatedButton(
                        onPressed: clientsProvider.isLoading ? null : _handleUpdateClient,
                        child: Text(l10n.save),
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