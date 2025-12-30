import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreateSOSDialog extends StatefulWidget {
  final FirebaseFirestore firestore;
  const CreateSOSDialog({Key? key, required this.firestore}) : super(key: key);

  @override
  State<CreateSOSDialog> createState() => _CreateSOSDialogState();
}

class _CreateSOSDialogState extends State<CreateSOSDialog> {
  String _selectedType = 'Officer Down';
  final _messageController = TextEditingController();
  bool _isLoading = false;

  final List<Map<String, dynamic>> _types = [
    {'name': 'Officer Down', 'icon': Icons.local_police, 'color': Colors.red},
    {'name': 'Backup Needed', 'icon': Icons.shield, 'color': Colors.orange},
    {'name': 'Medical Emergency', 'icon': Icons.medical_services, 'color': Colors.red},
    {'name': 'Pursuit in Progress', 'icon': Icons.directions_car, 'color': Colors.orange},
    {'name': 'Other Emergency', 'icon': Icons.warning, 'color': Colors.yellow.shade700},
  ];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<String> _generateSOSNumber() async {
    final year = DateTime.now().year;
    final query = await widget.firestore
        .collection('sos_alerts')
        .where('sosNumber', isGreaterThanOrEqualTo: 'SOS-$year-')
        .where('sosNumber', isLessThan: 'SOS-${year + 1}-')
        .get();
    
    final count = query.docs.length + 1;
    return 'SOS-$year-${count.toString().padLeft(6, '0')}';
  }

  Future<void> _sendSOS() async {
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Fetch officer details
      final officerDoc = await widget.firestore
          .collection('officers')
          .where('userId', isEqualTo: user.uid)
          .limit(1)
          .get();

      String officerName = 'Unknown Officer';
      String officerBadge = 'N/A';
      String location = 'Unknown Location';
      double lat = 0.0;
      double lng = 0.0;

      if (officerDoc.docs.isNotEmpty) {
        final data = officerDoc.docs.first.data();
        officerName = data['name'] ?? 'Unknown';
        officerBadge = data['badgeNumber'] ?? 'N/A';
        // Use last known location from officer profile if available
        if (data['latitude'] != null) lat = data['latitude'];
        if (data['longitude'] != null) lng = data['longitude'];
        if (data['current_location'] != null) location = data['current_location'];
      }

      final sosNumber = await _generateSOSNumber();
      final now = Timestamp.now();
      
      final typeMap = _types.firstWhere((t) => t['name'] == _selectedType);
      String priority = 'Medium';
      if (_selectedType == 'Officer Down' || _selectedType == 'Medical Emergency') {
        priority = 'Critical';
      } else if (_selectedType == 'Backup Needed' || _selectedType == 'Pursuit in Progress') {
        priority = 'High';
      }

      await widget.firestore.collection('sos_alerts').add({
        'sosNumber': sosNumber,
        'type': _selectedType,
        'priority': priority,
        'message': _messageController.text,
        'officerId': user.uid,
        'officerName': officerName,
        'officerBadge': officerBadge,
        'location': location,
        'latitude': lat,
        'longitude': lng,
        'status': 'Active',
        'createdAt': now,
        'updatedAt': now,
        'acknowledgedBy': null,
        'resolvedAt': null,
        // Additional metadata for real-time tracking
        'responderCount': 0,
        'activeResponders': [],
      });

      if (mounted) {
        Navigator.pop(context);
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: Colors.red[50],
            title: const Row(
              children: [
                Icon(Icons.report, color: Colors.red),
                SizedBox(width: 8),
                Text('SOS SENT!', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              ],
            ),
            content: const Text(
              'Your emergency alert has been broadcasted to all units and command center.',
              style: TextStyle(fontSize: 16),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Dismiss', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending SOS: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.red[50],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Column(
                children: [
                  Icon(Icons.warning_amber_rounded, size: 48, color: Colors.red),
                  SizedBox(height: 8),
                  Text(
                    'SEND EMERGENCY ALERT',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            const Text(
              'Select Emergency Type:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: _types.length,
                itemBuilder: (context, index) {
                  final type = _types[index];
                  final isSelected = type['name'] == _selectedType;
                  return InkWell(
                    onTap: () => setState(() => _selectedType = type['name']),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? Colors.red : Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            type['icon'],
                            color: isSelected ? Colors.white : type['color'],
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            type['name'],
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          if (isSelected) const Spacer(),
                          if (isSelected) const Icon(Icons.check, color: Colors.white, size: 20),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            
            const SizedBox(height: 16),
            TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                labelText: 'Additional Message (Optional)',
                border: OutlineInputBorder(),
                fillColor: Colors.white,
                filled: true,
                hintText: 'Location details, suspect info, etc.',
              ),
              maxLines: 2,
            ),
            
            const SizedBox(height: 24),
            
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('CANCEL'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _sendSOS,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 4,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.send),
                              SizedBox(width: 8),
                              Text('SEND SOS NOW', style: TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
