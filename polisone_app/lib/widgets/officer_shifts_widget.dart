import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class OfficerShiftsWidget extends StatelessWidget {
  const OfficerShiftsWidget({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    
    if (currentUser == null) {
      return const Center(child: Text('Please login to view shifts'));
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.calendar_today, color: Color(0xFF1E40AF)),
                const SizedBox(width: 8),
                const Text(
                  'My Assigned Shifts',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.sync, color: Colors.green, size: 14),
                      SizedBox(width: 4),
                      Text(
                        'Live',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Stream shifts assigned to this officer
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('shifts')
                  .where('assignedOfficers', arrayContains: currentUser.uid)
                  .limit(10)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(Icons.event_busy, size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 12),
                          Text(
                            'No shifts assigned yet',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Sort shifts by date in memory
                final sortedDocs = snapshot.data!.docs.toList();
                sortedDocs.sort((a, b) {
                  final aData = a.data() as Map<String, dynamic>;
                  final bData = b.data() as Map<String, dynamic>;
                  final aDate = (aData['date'] as Timestamp?)?.toDate() ?? DateTime.now();
                  final bDate = (bData['date'] as Timestamp?)?.toDate() ?? DateTime.now();
                  return aDate.compareTo(bDate);
                });

                return Column(
                  children: sortedDocs.take(5).map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final shiftName = data['name'] ?? 'Shift';
                    final startTime = data['startTime'] ?? '00:00';
                    final endTime = data['endTime'] ?? '00:00';
                    final status = data['status'] ?? 'upcoming';
                    final date = (data['date'] as Timestamp?)?.toDate();
                    final assignedCount = (data['assignedOfficers'] as List?)?.length ?? 0;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: status == 'active' ? Colors.green :
                                 status == 'upcoming' ? Colors.blue : Colors.grey,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        color: status == 'active' ? Colors.green[50] :
                               status == 'upcoming' ? Colors.blue[50] : Colors.grey[50],
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: status == 'active' ? Colors.green :
                                     status == 'upcoming' ? Colors.blue : Colors.grey,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              status == 'active' ? Icons.work :
                              status == 'upcoming' ? Icons.schedule : Icons.check_circle,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  shiftName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$startTime - $endTime',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                if (date != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    DateFormat('EEE, MMM dd, yyyy').format(date),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(Icons.people, size: 14, color: Colors.grey[600]),
                                    const SizedBox(width: 4),
                                    Text(
                                      '$assignedCount officers',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: status == 'active' ? Colors.green :
                                     status == 'upcoming' ? Colors.blue : Colors.grey,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
