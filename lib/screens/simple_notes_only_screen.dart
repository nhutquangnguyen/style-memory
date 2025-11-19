import 'package:flutter/material.dart';

import '../models/models.dart';
import '../services/supabase_service.dart';

class SimpleNotesOnlyScreen extends StatefulWidget {
  final Client client;

  const SimpleNotesOnlyScreen({
    super.key,
    required this.client,
  });

  @override
  State<SimpleNotesOnlyScreen> createState() => _SimpleNotesOnlyScreenState();
}

class _SimpleNotesOnlyScreenState extends State<SimpleNotesOnlyScreen> {
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _serviceController = TextEditingController();

  bool _isSaving = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Add Service Notes'),
            Text(
              widget.client.fullName,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Service Type Input
            TextField(
              controller: _serviceController,
              decoration: const InputDecoration(
                labelText: 'Service Type',
                hintText: 'e.g. Hair Cut, Color, Styling...',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.content_cut),
              ),
            ),
            const SizedBox(height: 16),

            // Notes Section
            Expanded(
              child: TextField(
                controller: _notesController,
                maxLines: null,
                expands: true,
                textAlignVertical: TextAlignVertical.top,
                decoration: const InputDecoration(
                  labelText: 'Service Notes',
                  hintText: 'Add notes about the service:\n• Products used\n• Techniques applied\n• Client preferences\n• Next appointment suggestions\n• Color formulas\n• Any other important details...',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(bottom: 200),
                    child: Icon(Icons.note_add),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Info Card
            Card(
              color: Colors.blue.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Photo upload will be available after setting up storage. For now, focus on documenting your services with detailed notes.',
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Save Button
            ElevatedButton(
              onPressed: _isSaving ? null : _saveVisit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: _isSaving
                  ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text('Saving...'),
                      ],
                    )
                  : const Text('Save Visit'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveVisit() async {
    if (_notesController.text.trim().isEmpty && _serviceController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add a service type or some notes'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      // Create visit without photos
      final visit = Visit(
        id: '', // Will be generated by database
        clientId: widget.client.id,
        userId: SupabaseService.currentUser!.id,
        visitDate: DateTime.now(),
        serviceId: _serviceController.text.trim().isNotEmpty
            ? _serviceController.text.trim()
            : null,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        photos: [],
      );

      // Save visit
      await SupabaseService.createVisit(visit);

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Service notes saved successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving visit: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _serviceController.dispose();
    super.dispose();
  }
}