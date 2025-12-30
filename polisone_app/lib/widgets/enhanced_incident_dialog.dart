import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class EnhancedIncidentReportDialog extends StatefulWidget {
  final String patrolId;
  final FirebaseFirestore firestore;
  
  const EnhancedIncidentReportDialog({
    Key? key,
    required this.patrolId,
    required this.firestore,
  }) : super(key: key);

  @override
  State<EnhancedIncidentReportDialog> createState() => _EnhancedIncidentReportDialogState();
}

class _EnhancedIncidentReportDialogState extends State<EnhancedIncidentReportDialog> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  
  String _selectedType = 'Suspicious Activity';
  String _selectedSeverity = 'Medium';
  bool _isSubmitting = false;

  final _incidentTypes = [
    'Suspicious Activity',
    'Traffic Violation',
    'Public Disturbance',
    'Emergency',
    'Theft',
    'Assault',
    'Vandalism',
    'Other',
  ];

  final _severityLevels = ['Low', 'Medium', 'High', 'Critical'];

  @override
  void dispose() {
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      
      // Create incident report
      final incidentRef = await widget.firestore.collection('patrol_incidents').add({
        'patrolId': widget.patrolId,
        'officerId': userId,
        'type': _selectedType,
        'severity': _selectedSeverity,
        'description': _descriptionController.text,
        'location': _locationController.text,
        'reportedAt': FieldValue.serverTimestamp(),
        'status': 'Open',
      });

      // Update patrol incident count
      await widget.firestore.collection('patrols').doc(widget.patrolId).update({
        'incidentsReported': FieldValue.increment(1),
        'incidents': FieldValue.arrayUnion([incidentRef.id]),
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Incident reported successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.report_problem, color: Colors.orange, size: 28),
                  const SizedBox(width: 12),
                  const Text(
                    'Report Incident',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              
              // Incident Type
              DropdownButtonFormField<String>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Incident Type',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.category),
                ),
                items: _incidentTypes.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: (value) => setState(() => _selectedType = value!),
              ),
              const SizedBox(height: 16),
              
              // Severity Level
              const Text('Severity Level', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _severityLevels.map((level) {
                  final isSelected = _selectedSeverity == level;
                  Color color = level == 'Critical' ? Colors.red :
                               level == 'High' ? Colors.orange :
                               level == 'Medium' ? Colors.blue : Colors.green;
                  
                  return ChoiceChip(
                    label: Text(level),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedSeverity = level);
                    },
                    selectedColor: color.withOpacity(0.3),
                    labelStyle: TextStyle(
                      color: isSelected ? color : Colors.grey[700],
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              
              // Location
              TextFormField(
                controller: _locationController,
                decoration: const InputDecoration(
                  labelText: 'Location',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                  hintText: 'Current location',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter location';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.notes),
                  hintText: 'Describe the incident...',
                ),
                maxLines: 4,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submitReport,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('Submit Report'),
                    ),
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
