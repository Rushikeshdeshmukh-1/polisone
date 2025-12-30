import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class FIRDetailsDialog extends StatefulWidget {
  final String firId;
  final FirebaseFirestore firestore;
  final bool canAssignOfficer;

  const FIRDetailsDialog({
    Key? key,
    required this.firId,
    required this.firestore,
    this.canAssignOfficer = false,
  }) : super(key: key);

  @override
  State<FIRDetailsDialog> createState() => _FIRDetailsDialogState();
}

class _FIRDetailsDialogState extends State<FIRDetailsDialog> {
  String? _selectedOfficerId;
  String? _newStatus;

  Future<void> _assignOfficer() async {
    if (_selectedOfficerId == null) return;

    try {
      // Get officer details
      final officerDoc = await widget.firestore
          .collection('officers')
          .where('userId', isEqualTo: _selectedOfficerId)
          .limit(1)
          .get();

      if (officerDoc.docs.isEmpty) {
        throw Exception('Officer not found');
      }

      final officerData = officerDoc.docs.first.data();

      await widget.firestore.collection('firs').doc(widget.firId).update({
        'assignedOfficerId': _selectedOfficerId,
        'assignedOfficerName': officerData['name'] ?? 'Unknown',
        'assignedAt': FieldValue.serverTimestamp(),
        'status': 'Under Investigation',
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Officer assigned successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
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

  Future<void> _updateStatus(String status) async {
    try {
      await widget.firestore.collection('firs').doc(widget.firId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Status updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
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
        width: 700,
        height: 600,
        padding: const EdgeInsets.all(24),
        child: StreamBuilder<DocumentSnapshot>(
          stream: widget.firestore.collection('firs').doc(widget.firId).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Center(child: Text('FIR not found'));
            }

            final data = snapshot.data!.data() as Map<String, dynamic>;
            final firNumber = data['firNumber'] ?? 'N/A';
            final type = data['type'] ?? 'Unknown';
            final priority = data['priority'] ?? 'Medium';
            final status = data['status'] ?? 'Pending';
            final description = data['description'] ?? '';
            final location = data['location'] ?? 'N/A';
            
            final complainantName = data['complainantName'] ?? 'N/A';
            final complainantPhone = data['complainantPhone'] ?? 'N/A';
            final complainantAddress = data['complainantAddress'] ?? 'N/A';
            
            final accusedName = data['accusedName'] ?? 'Not specified';
            final accusedDescription = data['accusedDescription'] ?? 'Not specified';
            
            final assignedOfficerName = data['assignedOfficerName'];
            final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E40AF).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.description,
                        color: Color(0xFF1E40AF),
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            firNumber,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (createdAt != null)
                            Text(
                              DateFormat('MMM dd, yyyy - hh:mm a').format(createdAt),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Status and Priority Badges
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getStatusColor(status).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _getStatusColor(status)),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _getStatusColor(status),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _getPriorityColor(priority).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _getPriorityColor(priority)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.priority_high, size: 14, color: _getPriorityColor(priority)),
                          const SizedBox(width: 4),
                          Text(
                            priority,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _getPriorityColor(priority),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        type,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSection('Incident Details', [
                          _buildInfoRow('Location', location, Icons.location_on),
                          _buildInfoRow('Description', description, Icons.notes),
                        ]),
                        
                        const SizedBox(height: 16),
                        
                        _buildSection('Complainant Information', [
                          _buildInfoRow('Name', complainantName, Icons.person),
                          _buildInfoRow('Phone', complainantPhone, Icons.phone),
                          _buildInfoRow('Address', complainantAddress, Icons.home),
                        ]),
                        
                        const SizedBox(height: 16),
                        
                        _buildSection('Accused Information', [
                          _buildInfoRow('Name', accusedName, Icons.person_outline),
                          _buildInfoRow('Description', accusedDescription, Icons.description_outlined),
                        ]),
                        
                        const SizedBox(height: 16),
                        
                        _buildSection('Assignment', [
                          if (assignedOfficerName != null)
                            _buildInfoRow('Assigned Officer', assignedOfficerName, Icons.badge)
                          else
                            const Text('Not assigned yet', style: TextStyle(fontStyle: FontStyle.italic)),
                        ]),
                      ],
                    ),
                  ),
                ),
                
                const Divider(),
                
                // Actions
                Row(
                  children: [
                    // Status Update
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: ['Open', 'Pending', 'Under Investigation', 'Resolved', 'Closed', 'Rejected'].contains(status) ? status : null,
                        decoration: const InputDecoration(
                          labelText: 'Update Status',
                          border: OutlineInputBorder(),
                          isDense: true,
                        ),
                        items: [
                          'Open',
                          'Pending', 
                          'Under Investigation', 
                          'Resolved', 
                          'Closed', 
                          'Rejected'
                        ]
                        .toSet() // Remove duplicates
                        .toList()
                        .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                        onChanged: (value) {
                          if (value != null && value != status) {
                            _updateStatus(value);
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Officer Assignment
                    if (widget.canAssignOfficer && assignedOfficerName == null)
                      Expanded(
                        child: StreamBuilder<QuerySnapshot>(
                          stream: widget.firestore
                              .collection('users')
                              .where('role', isEqualTo: 'officer')
                              .snapshots(),
                          builder: (context, officerSnapshot) {
                            if (!officerSnapshot.hasData) {
                              return const SizedBox();
                            }

                            return Row(
                              children: [
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: _selectedOfficerId,
                                    decoration: const InputDecoration(
                                      labelText: 'Assign Officer',
                                      border: OutlineInputBorder(),
                                      isDense: true,
                                    ),
                                    items: officerSnapshot.data!.docs
                                        .where((doc) {
                                          final data = doc.data() as Map<String, dynamic>;
                                          return data['uid'] != null; // Using uid as standard
                                        })
                                        .map<DropdownMenuItem<String>>((doc) {
                                      final data = doc.data() as Map<String, dynamic>;
                                      final userId = data['uid'] as String;
                                      final name = data['name'] ?? 'Unknown';
                                      return DropdownMenuItem<String>(
                                        value: userId,
                                        child: Text(name),
                                      );
                                    }).toList(),
                                    onChanged: (value) {
                                      setState(() => _selectedOfficerId = value);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  onPressed: _assignOfficer,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1E40AF),
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Assign'),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E40AF),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'Under Investigation':
        return Colors.blue;
      case 'Resolved':
        return Colors.green;
      case 'Closed':
        return Colors.grey;
      case 'Rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'Critical':
        return Colors.red;
      case 'High':
        return Colors.orange;
      case 'Medium':
        return Colors.blue;
      case 'Low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
