import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../providers/providers.dart';
import '../../theme/app_theme.dart';
import '../../widgets/common/loading_overlay.dart';
import '../../widgets/common/error_banner.dart';
import '../../widgets/common/empty_state.dart';

class StaffListScreen extends StatefulWidget {
  const StaffListScreen({super.key});

  @override
  State<StaffListScreen> createState() => _StaffListScreenState();
}

class _StaffListScreenState extends State<StaffListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StaffProvider>().loadStaff();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StaffProvider>(
      builder: (context, staffProvider, child) {
        return LoadingOverlay(
          isLoading: staffProvider.isLoading,
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Staff Management'),
              actions: [
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'show_all':
                        // Toggle between active only and all staff
                        break;
                      case 'analytics':
                        _showStaffAnalytics(context, staffProvider);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'show_all',
                      child: Text('Show All Staff'),
                    ),
                    const PopupMenuItem(
                      value: 'analytics',
                      child: Text('Staff Analytics'),
                    ),
                  ],
                ),
              ],
            ),
            body: Column(
              children: [
                // Error banner
                if (staffProvider.errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.all(AppTheme.spacingMedium),
                    child: ErrorBanner(
                      message: staffProvider.errorMessage!,
                      onDismiss: () {},
                      onRetry: () => staffProvider.refreshStaff(),
                    ),
                  ),

                // Staff list
                Expanded(
                  child: _buildStaffList(staffProvider),
                ),
              ],
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () => _showAddStaffDialog(context),
              child: const Icon(Icons.add),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStaffList(StaffProvider staffProvider) {
    final activeStaff = staffProvider.activeStaff;

    if (activeStaff.isEmpty && !staffProvider.isLoading) {
      return EmptyState(
        icon: Icons.group_outlined,
        title: 'No staff members yet',
        description: 'Add your first team member to get started',
        actionText: 'Add Staff Member',
        onAction: () => _showAddStaffDialog(context),
      );
    }

    return RefreshIndicator(
      onRefresh: () => staffProvider.refreshStaff(),
      child: ListView.builder(
        padding: const EdgeInsets.all(AppTheme.spacingMedium),
        itemCount: activeStaff.length,
        itemBuilder: (context, index) {
          final staff = activeStaff[index];
          return _StaffCard(
            staff: staff,
            onTap: () => _showStaffDetails(context, staff),
            onEdit: () => _showEditStaffDialog(context, staff),
            onDelete: () => _showDeleteStaffDialog(context, staff),
          );
        },
      ),
    );
  }

  void _showAddStaffDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _AddEditStaffDialog(),
    );
  }

  void _showEditStaffDialog(BuildContext context, Staff staff) {
    showDialog(
      context: context,
      builder: (context) => _AddEditStaffDialog(staff: staff),
    );
  }

  void _showStaffDetails(BuildContext context, Staff staff) {
    // TODO: Navigate to staff details screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Staff details for ${staff.name} coming soon')),
    );
  }

  void _showDeleteStaffDialog(BuildContext context, Staff staff) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Staff Member'),
        content: Text(
          'Are you sure you want to remove ${staff.name} from your team? They will be marked as inactive but their work history will be preserved.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final staffProvider = context.read<StaffProvider>();
              final scaffoldMessenger = ScaffoldMessenger.of(context);

              navigator.pop();
              final success = await staffProvider.deleteStaff(staff.id);
              if (success && mounted) {
                scaffoldMessenger.showSnackBar(
                  SnackBar(content: Text('${staff.name} removed from team')),
                );
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: AppTheme.errorColor,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _showStaffAnalytics(BuildContext context, StaffProvider staffProvider) {
    final stats = staffProvider.getStaffStats();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Staff Analytics'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatRow('Total Staff', stats['total_staff'].toString()),
            _buildStatRow('Active Staff', stats['active_staff'].toString()),
            _buildStatRow('Inactive Staff', stats['inactive_staff'].toString()),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _StaffCard extends StatelessWidget {
  final Staff staff;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _StaffCard({
    required this.staff,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppTheme.spacingMedium),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.spacingMedium),
          child: Row(
            children: [
              // Avatar
              CircleAvatar(
                radius: 24,
                backgroundColor: AppTheme.primaryAccentColor.withValues(alpha: 0.2),
                child: Text(
                  staff.initials,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryButtonColor,
                  ),
                ),
              ),

              const SizedBox(width: AppTheme.spacingMedium),

              // Staff info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      staff.name,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      staff.displaySpecialty,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.secondaryTextColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Joined ${staff.formattedHireDate}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),

              // Actions menu
              PopupMenuButton<String>(
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      onEdit();
                      break;
                    case 'delete':
                      onDelete();
                      break;
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Text('Edit'),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Remove'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddEditStaffDialog extends StatefulWidget {
  final Staff? staff; // null for add, non-null for edit

  const _AddEditStaffDialog({this.staff});

  @override
  State<_AddEditStaffDialog> createState() => _AddEditStaffDialogState();
}

class _AddEditStaffDialogState extends State<_AddEditStaffDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _specialtyController;
  late TextEditingController _notesController;

  bool get isEditing => widget.staff != null;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.staff?.name ?? '');
    _emailController = TextEditingController(text: widget.staff?.email ?? '');
    _phoneController = TextEditingController(text: widget.staff?.phone ?? '');
    _specialtyController = TextEditingController(text: widget.staff?.specialty ?? '');
    _notesController = TextEditingController(text: widget.staff?.notes ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _specialtyController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(isEditing ? 'Edit Staff Member' : 'Add Staff Member'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Full Name',
                  hintText: 'Enter staff member name',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Name is required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppTheme.spacingMedium),

              TextFormField(
                controller: _specialtyController,
                decoration: const InputDecoration(
                  labelText: 'Specialty',
                  hintText: 'e.g., Hair Color Specialist, Nail Art',
                ),
              ),
              const SizedBox(height: AppTheme.spacingMedium),

              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  hintText: 'staff@salon.com',
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value != null && value.isNotEmpty) {
                    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                    if (!emailRegex.hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppTheme.spacingMedium),

              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  hintText: '(555) 123-4567',
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: AppTheme.spacingMedium),

              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  hintText: 'Additional information...',
                ),
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saveStaff,
          child: Text(isEditing ? 'Update' : 'Add'),
        ),
      ],
    );
  }

  void _saveStaff() async {
    if (!_formKey.currentState!.validate()) return;

    final staff = isEditing
        ? widget.staff!.copyWith(
            name: _nameController.text.trim(),
            email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
            phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
            specialty: _specialtyController.text.trim().isEmpty ? null : _specialtyController.text.trim(),
            notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
            updatedAt: DateTime.now(),
          )
        : Staff(
            userId: '', // Will be set by provider
            name: _nameController.text.trim(),
            email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
            phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
            specialty: _specialtyController.text.trim().isEmpty ? null : _specialtyController.text.trim(),
            notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
          );

    final staffProvider = context.read<StaffProvider>();
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final success = isEditing
        ? await staffProvider.updateStaff(staff)
        : await staffProvider.addStaff(staff);

    if (success && mounted) {
      navigator.pop();
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(isEditing
              ? '${staff.name} updated successfully'
              : '${staff.name} added to your team'
          ),
        ),
      );
    }
  }
}