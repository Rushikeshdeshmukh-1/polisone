import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EnhancedCreateFIRDialog extends StatefulWidget {
  final FirebaseFirestore firestore;
  const EnhancedCreateFIRDialog({Key? key, required this.firestore}) : super(key: key);

  @override
  State<EnhancedCreateFIRDialog> createState() => _EnhancedCreateFIRDialogState();
}

class _EnhancedCreateFIRDialogState extends State<EnhancedCreateFIRDialog> {
  final _formKey = GlobalKey<FormState>();
  int _currentStep = 0;
  bool _isLoading = false;

  // FIR Details
  final _descriptionController = TextEditingController();
  String _selectedType = 'Theft';
  String _selectedPriority = 'Medium';
  final _locationController = TextEditingController();

  // Complainant Details
  final _complainantNameController = TextEditingController();
  final _complainantPhoneController = TextEditingController();
  final _complainantAddressController = TextEditingController();

  // Accused Details (Optional)
  final _accusedNameController = TextEditingController();
  final _accusedDescriptionController = TextEditingController();

  final _types = ['Theft', 'Robbery', 'Assault', 'Cyber Crime', 'Vehicle Theft', 'Murder', 'Kidnapping', 'Fraud', 'Other'];
  final _priorities = ['Low', 'Medium', 'High', 'Critical'];

  @override
  void dispose() {
    _descriptionController.dispose();
    _locationController.dispose();
    _complainantNameController.dispose();
    _complainantPhoneController.dispose();
    _complainantAddressController.dispose();
    _accusedNameController.dispose();
    _accusedDescriptionController.dispose();
    super.dispose();
  }

  Future<String> _generateFIRNumber() async {
    final year = DateTime.now().year;
    final query = await widget.firestore
        .collection('firs')
        .where('firNumber', isGreaterThanOrEqualTo: 'FIR-$year-')
        .where('firNumber', isLessThan: 'FIR-${year + 1}-')
        .get();

    final count = query.docs.length + 1;
    return 'FIR-$year-${count.toString().padLeft(6, '0')}';
  }

  Future<void> _createFIR() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final firNumber = await _generateFIRNumber();
      final currentUser = FirebaseAuth.instance.currentUser;
      final now = Timestamp.now();

      await widget.firestore.collection('firs').add({
        // FIR Details
        'firNumber': firNumber,
        'type': _selectedType,
        'description': _descriptionController.text,
        'priority': _selectedPriority,
        'location': _locationController.text,
        'status': 'Open',
        
        // Complainant Details
        'complainantName': _complainantNameController.text,
        'complainantPhone': _complainantPhoneController.text,
        'complainantAddress': _complainantAddressController.text,
        
        // Accused Details (if provided)
        'accusedName': _accusedNameController.text.isNotEmpty ? _accusedNameController.text : null,
        'accusedDescription': _accusedDescriptionController.text.isNotEmpty ? _accusedDescriptionController.text : null,
        
        // Assignment (initially null)
        'assignedOfficerId': null,
        'assignedOfficerName': null,
        'assignedAt': null,
        
        // Metadata
        'createdBy': currentUser?.uid ?? 'unknown',
        'createdByName': currentUser?.email ?? 'Unknown',
        'createdAt': now,
        'updatedAt': now,
        
        // Additional
        'evidenceAttached': false,
        'witnessCount': 0,
      });

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ FIR $firNumber created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.description, color: Color(0xFF1E40AF), size: 32),
                const SizedBox(width: 12),
                const Text(
                  'Create New FIR',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            Expanded(
              child: Form(
                key: _formKey,
                child: Stepper(
                  currentStep: _currentStep,
                  onStepContinue: () {
                    if (_currentStep < 2) {
                      setState(() => _currentStep++);
                    } else {
                      _createFIR();
                    }
                  },
                  onStepCancel: () {
                    if (_currentStep > 0) {
                      setState(() => _currentStep--);
                    }
                  },
                  controlsBuilder: (context, details) {
                    return Row(
                      children: [
                        ElevatedButton(
                          onPressed: _isLoading ? null : details.onStepContinue,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1E40AF),
                            foregroundColor: Colors.white,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Text(_currentStep == 2 ? 'Create FIR' : 'Continue'),
                        ),
                        if (_currentStep > 0) ...[
                          const SizedBox(width: 12),
                          TextButton(
                            onPressed: details.onStepCancel,
                            child: const Text('Back'),
                          ),
                        ],
                      ],
                    );
                  },
                  steps: [
                    // Step 1: Incident Details
                    Step(
                      title: const Text('Incident Details'),
                      isActive: _currentStep >= 0,
                      state: _currentStep > 0 ? StepState.complete : StepState.indexed,
                      content: Column(
                        children: [
                          DropdownButtonFormField<String>(
                            value: _selectedType,
                            decoration: const InputDecoration(
                              labelText: 'Incident Type *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.category),
                            ),
                            items: _types.map((type) {
                              return DropdownMenuItem(value: type, child: Text(type));
                            }).toList(),
                            onChanged: (value) => setState(() => _selectedType = value!),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            value: _selectedPriority,
                            decoration: const InputDecoration(
                              labelText: 'Priority *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.priority_high),
                            ),
                            items: _priorities.map((priority) {
                              return DropdownMenuItem(
                                value: priority,
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.circle,
                                      size: 12,
                                      color: priority == 'Critical' ? Colors.red :
                                             priority == 'High' ? Colors.orange :
                                             priority == 'Medium' ? Colors.blue : Colors.green,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(priority),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (value) => setState(() => _selectedPriority = value!),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _locationController,
                            decoration: const InputDecoration(
                              labelText: 'Location *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.location_on),
                              hintText: 'Enter incident location',
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter location';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _descriptionController,
                            decoration: const InputDecoration(
                              labelText: 'Description *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.notes),
                              hintText: 'Enter detailed description of the incident',
                            ),
                            maxLines: 4,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter description';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    
                    // Step 2: Complainant Details
                    Step(
                      title: const Text('Complainant Details'),
                      isActive: _currentStep >= 1,
                      state: _currentStep > 1 ? StepState.complete : StepState.indexed,
                      content: Column(
                        children: [
                          TextFormField(
                            controller: _complainantNameController,
                            decoration: const InputDecoration(
                              labelText: 'Complainant Name *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.person),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter complainant name';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _complainantPhoneController,
                            decoration: const InputDecoration(
                              labelText: 'Phone Number *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.phone),
                            ),
                            keyboardType: TextInputType.phone,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter phone number';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _complainantAddressController,
                            decoration: const InputDecoration(
                              labelText: 'Address *',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.home),
                            ),
                            maxLines: 3,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter address';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    
                    // Step 3: Accused Details (Optional)
                    Step(
                      title: const Text('Accused Details (Optional)'),
                      isActive: _currentStep >= 2,
                      state: StepState.indexed,
                      content: Column(
                        children: [
                          TextFormField(
                            controller: _accusedNameController,
                            decoration: const InputDecoration(
                              labelText: 'Accused Name (if known)',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _accusedDescriptionController,
                            decoration: const InputDecoration(
                              labelText: 'Accused Description',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.description_outlined),
                              hintText: 'Physical description, identifying marks, etc.',
                            ),
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
