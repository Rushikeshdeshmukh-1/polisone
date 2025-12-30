import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ShiftDetailsDialog extends StatelessWidget {
  final String shiftId;
  final FirebaseFirestore firestore;

  const ShiftDetailsDialog({
    Key? key,
    required this.shiftId,
    required this.firestore,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(24),
        child: StreamBuilder<DocumentSnapshot>(
          stream: firestore.collection('shifts').doc(shiftId).snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Center(child: Text('Shift not found'));
            }

            final data = snapshot.data!.data() as Map<String, dynamic>;
            final shiftName = data['name'] ?? 'Unknown Shift';
            final startTime = data['startTime'] ?? '00:00';
            final endTime = data['endTime'] ?? '00:00';
            final status = data['status'] ?? 'unknown';
            final requiredOfficers = data['requiredOfficers'] ?? 0;
            final assignedOfficerIds = (data['assignedOfficers'] as List?)?.cast<String>() ?? [];

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      status == 'active' ? Icons.work : 
                      status == 'upcoming' ? Icons.schedule : Icons.check_circle,
                      color: status == 'active' ? Colors.green :
                             status == 'upcoming' ? Colors.blue : Colors.grey,
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            shiftName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '$startTime - $endTime',
                            style: TextStyle(
                              fontSize: 14,
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
                
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: status == 'active' ? Colors.green[100] :
                           status == 'upcoming' ? Colors.blue[100] : Colors.grey[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: status == 'active' ? Colors.green[700] :
                             status == 'upcoming' ? Colors.blue[700] : Colors.grey[700],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Officer Assignment Info
                Row(
                  children: [
                    Expanded(
                      child: _buildInfoCard(
                        'Required',
                        requiredOfficers.toString(),
                        Icons.people_outline,
                        Colors.blue,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildInfoCard(
                        'Assigned',
                        assignedOfficerIds.length.toString(),
                        Icons.people,
                        Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildInfoCard(
                        'Remaining',
                        (requiredOfficers - assignedOfficerIds.length).toString(),
                        Icons.person_add,
                        Colors.orange,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                const Text(
                  'Assigned Officers',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Assigned Officers List
                Expanded(
                  child: assignedOfficerIds.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.person_off, size: 48, color: Colors.grey[400]),
                              const SizedBox(height: 8),
                              Text(
                                'No officers assigned yet',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        )
                      : Builder(
                          builder: (context) {
                            print('🔍 Looking for officers with userIds: $assignedOfficerIds');
                            
                            // If we have too many IDs, we need to handle differently
                            if (assignedOfficerIds.isEmpty) {
                              return Center(
                                child: Text('No officers assigned', style: TextStyle(color: Colors.grey[600])),
                              );
                            }
                            
                            // Query by userId field instead of document ID
                            return StreamBuilder<QuerySnapshot>(
                              stream: firestore
                                  .collection('officers')
                                  .where('userId', whereIn: assignedOfficerIds.take(10).toList())
                                  .snapshots(),
                              builder: (context, officerSnapshot) {
                                print('📊 Officer query state: ${officerSnapshot.connectionState}');
                                print('📊 Has officer data: ${officerSnapshot.hasData}');
                                print('📊 Officers found: ${officerSnapshot.data?.docs.length ?? 0}');
                                
                                if (officerSnapshot.hasError) {
                                  print('❌ Error loading officers: ${officerSnapshot.error}');
                                  return Center(
                                    child: Text('Error: ${officerSnapshot.error}'),
                                  );
                                }
                                
                                if (officerSnapshot.connectionState == ConnectionState.waiting) {
                                  return const Center(child: CircularProgressIndicator());
                                }

                                final officers = officerSnapshot.data?.docs ?? [];
                                
                                if (officers.isEmpty) {
                                  return Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.info_outline, size: 48, color: Colors.grey[400]),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Officers assigned but not found in database',
                                          style: TextStyle(color: Colors.grey[600]),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Assigned IDs: ${assignedOfficerIds.length}',
                                          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                                        ),
                                      ],
                                    ),
                                  );
                                }

                                return ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: officers.length,
                                  itemBuilder: (context, index) {
                                    final officer = officers[index].data() as Map<String, dynamic>;
                                    final name = officer['name'] ?? 'Unknown Officer';
                                    final status = officer['status'] ?? 'off_duty';
                                    final email = officer['email'] ?? '';

                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      child: ListTile(
                                        leading: CircleAvatar(
                                          backgroundColor: status == 'on_patrol' ? Colors.green :
                                                            status == 'responding' ? Colors.orange : Colors.grey,
                                          child: Text(
                                            name[0].toUpperCase(),
                                            style: const TextStyle(color: Colors.white),
                                          ),
                                        ),
                                        title: Text(name),
                                        subtitle: email.isNotEmpty ? Text(email) : null,
                                        trailing: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: status == 'on_patrol' ? Colors.green[100] :
                                                   status == 'responding' ? Colors.orange[100] : Colors.grey[100],
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            status.replaceAll('_', ' ').toUpperCase(),
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: status == 'on_patrol' ? Colors.green[700] :
                                                     status == 'responding' ? Colors.orange[700] : Colors.grey[700],
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
