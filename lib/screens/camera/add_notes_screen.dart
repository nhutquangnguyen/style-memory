import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/loading_overlay.dart';
import '../../widgets/common/error_banner.dart';

class AddNotesScreen extends StatefulWidget {
  final String clientId;

  const AddNotesScreen({
    super.key,
    required this.clientId,
  });

  @override
  State<AddNotesScreen> createState() => _AddNotesScreenState();
}

class _AddNotesScreenState extends State<AddNotesScreen> {
  final _formKey = GlobalKey<FormState>();
  final _serviceTypeController = TextEditingController();
  final _notesController = TextEditingController();
  final _productsController = TextEditingController();
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    _serviceTypeController.dispose();
    _notesController.dispose();
    _productsController.dispose();
    super.dispose();
  }

  Future<void> _handleSaveVisit() async {
    final cameraProvider = context.read<CameraProvider>();
    final visitsProvider = context.read<VisitsProvider>();

    if (cameraProvider.capturedPhotos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No photos to save')),
      );
      return;
    }

    final success = await visitsProvider.createVisitWithPhotos(
      clientId: widget.clientId,
      photos: cameraProvider.capturedPhotos,
      serviceId: _serviceTypeController.text.trim().isEmpty
          ? null
          : _serviceTypeController.text.trim(),
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      productsUsed: _productsController.text.trim().isEmpty
          ? null
          : _productsController.text.trim(),
      visitDate: _selectedDate,
    );

    if (success && mounted) {
      // Clear camera provider
      cameraProvider.resetCapture();

      // Navigate back to client profile (preserving navigation stack)
      context.pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Visit saved successfully!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final client = context.read<ClientsProvider>().getClientById(widget.clientId);

    if (client == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Client Not Found')),
        body: const Center(
          child: Text('Client not found'),
        ),
      );
    }

    return Consumer<VisitsProvider>(
      builder: (context, visitsProvider, child) {
        return LoadingOverlay(
          isLoading: visitsProvider.isUploading,
          message: 'Saving visit and uploading photos...',
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Add Visit Details'),
              actions: [
                TextButton(
                  onPressed: visitsProvider.isUploading ? null : _handleSaveVisit,
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
                      // Client info
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(AppTheme.spacingMedium),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: AppTheme.primaryAccentColor.withOpacity(0.2),
                                child: Text(
                                  client.initials,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.primaryButtonColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppTheme.spacingMedium),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    client.fullName,
                                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    'New Visit - ${_formatDate(_selectedDate)}',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: AppTheme.secondaryTextColor,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: AppTheme.spacingLarge),

                      // Error banner
                      if (visitsProvider.errorMessage != null) ...[
                        ErrorBanner(
                          message: visitsProvider.errorMessage!,
                          onDismiss: () => visitsProvider.clearError(),
                        ),
                        const SizedBox(height: AppTheme.spacingLarge),
                      ],

                      // Date picker
                      Card(
                        child: ListTile(
                          leading: const Icon(Icons.calendar_today),
                          title: const Text('Visit Date'),
                          subtitle: Text(_formatDate(_selectedDate)),
                          trailing: const Icon(Icons.edit),
                          onTap: _selectDate,
                        ),
                      ),

                      const SizedBox(height: AppTheme.spacingMedium),

                      // Service type field
                      TextFormField(
                        controller: _serviceTypeController,
                        decoration: const InputDecoration(
                          labelText: 'Service Type (optional)',
                          hintText: 'e.g., Haircut, Color, Highlights',
                        ),
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.sentences,
                      ),

                      const SizedBox(height: AppTheme.spacingMedium),

                      // Notes field
                      TextFormField(
                        controller: _notesController,
                        decoration: const InputDecoration(
                          labelText: 'Notes (optional)',
                          hintText: 'Add any special notes about this visit',
                          alignLabelWithHint: true,
                        ),
                        maxLines: 3,
                        textInputAction: TextInputAction.next,
                        textCapitalization: TextCapitalization.sentences,
                      ),

                      const SizedBox(height: AppTheme.spacingMedium),

                      // Products used field
                      TextFormField(
                        controller: _productsController,
                        decoration: const InputDecoration(
                          labelText: 'Products Used (optional)',
                          hintText: 'List products used during this session',
                          alignLabelWithHint: true,
                        ),
                        maxLines: 2,
                        textInputAction: TextInputAction.done,
                        textCapitalization: TextCapitalization.sentences,
                      ),

                      const SizedBox(height: AppTheme.spacingLarge),

                      // Save button
                      ElevatedButton(
                        onPressed: visitsProvider.isUploading ? null : _handleSaveVisit,
                        child: const Text('Save Visit'),
                      ),

                      const SizedBox(height: AppTheme.spacingMedium),

                      // Info text
                      Text(
                        'Photos will be uploaded and associated with this visit.',
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

  Future<void> _selectDate() async {
    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );

    if (selectedDate != null && selectedDate != _selectedDate) {
      setState(() {
        _selectedDate = selectedDate;
      });
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}