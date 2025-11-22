import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/loading_overlay.dart';
import '../../widgets/common/error_banner.dart';
import '../../widgets/client/avatar_picker.dart';
import '../../l10n/app_localizations.dart';

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
  final _birthdayController = TextEditingController();

  DateTime? _selectedBirthday;
  String? _avatarUrl;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _birthdayController.dispose();
    super.dispose();
  }

  void _updateBirthdayDisplay() {
    if (_selectedBirthday != null) {
      _birthdayController.text = '${_selectedBirthday!.day}/${_selectedBirthday!.month}/${_selectedBirthday!.year}';
    } else {
      _birthdayController.clear();
    }
  }

  Future<void> _selectBirthday() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedBirthday ?? DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      helpText: 'Select Birthday',
      fieldLabelText: 'Date',
    );

    if (picked != null && picked != _selectedBirthday) {
      setState(() {
        _selectedBirthday = picked;
        _updateBirthdayDisplay();
      });
    }
  }

  void _clearBirthday() {
    setState(() {
      _selectedBirthday = null;
      _updateBirthdayDisplay();
    });
  }

  Future<void> _handleSaveClient() async {
    if (!_formKey.currentState!.validate()) return;

    final clientsProvider = context.read<ClientsProvider>();

    // First create the client to get an ID
    final success = await clientsProvider.createClient(
      fullName: _nameController.text.trim(),
      phone: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      email: _emailController.text.trim().isEmpty
          ? null
          : _emailController.text.trim(),
      birthday: _selectedBirthday,
      avatarUrl: _avatarUrl,
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

    return Consumer<ClientsProvider>(
      builder: (context, clientsProvider, child) {
        return LoadingOverlay(
          isLoading: clientsProvider.isLoading,
          message: l10n.creatingClient,
          child: Scaffold(
            appBar: AppBar(
              title: Text(l10n.newClient),
              actions: [
                TextButton(
                  onPressed: clientsProvider.isLoading ? null : _handleSaveClient,
                  child: Text(l10n.save),
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

                      // Avatar picker
                      Center(
                        child: AvatarPicker(
                          onAvatarChanged: (avatarUrl) {
                            setState(() {
                              _avatarUrl = avatarUrl;
                            });
                          },
                        ),
                      ),

                      const SizedBox(height: AppTheme.spacingLarge),

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
                        textInputAction: TextInputAction.next,
                        validator: _validateEmail,
                      ),

                      const SizedBox(height: AppTheme.spacingMedium),

                      // Birthday field
                      TextFormField(
                        controller: _birthdayController,
                        decoration: InputDecoration(
                          labelText: 'Birthday (optional)',
                          hintText: 'Tap to select date',
                          suffixIcon: _selectedBirthday != null
                              ? IconButton(
                                  onPressed: _clearBirthday,
                                  icon: const Icon(Icons.clear),
                                  tooltip: 'Clear birthday',
                                )
                              : const Icon(Icons.cake_outlined),
                        ),
                        readOnly: true,
                        onTap: _selectBirthday,
                      ),

                      const SizedBox(height: AppTheme.spacingLarge),

                      // Save and add photos button
                      ElevatedButton(
                        onPressed: clientsProvider.isLoading ? null : _handleSaveClient,
                        child: Text(l10n.saveAndAddPhotos),
                      ),

                      const SizedBox(height: AppTheme.spacingMedium),

                      // Info text
                      Text(
                        l10n.afterSavingCanCapturePhotos,
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