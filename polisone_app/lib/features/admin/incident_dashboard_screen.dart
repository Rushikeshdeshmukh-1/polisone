
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class IncidentDashboardScreen extends StatelessWidget {
  final FirebaseFirestore firestore;

  const IncidentDashboardScreen({Key? key, required this.firestore}) : super(key: key);

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.blue;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Incident Reports'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              // TODO: Implement filters
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: firestore
            .collection('patrol_incidents')
            .orderBy('reportedAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final incidents = snapshot.data!.docs;

          if (incidents.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.assignment_turned_in, size: 64, color: Colors.green),
                  SizedBox(height: 16),
                  Text('No Incidents Reported', style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: incidents.length,
            itemBuilder: (context, index) {
              final data = incidents[index].data() as Map<String, dynamic>;
              final severity = data['severity'] ?? 'Medium';
              final timestamp = data['reportedAt'] as Timestamp?;
              final dateStr = timestamp != null 
                  ? DateFormat('MMM d, y • h:mm a').format(timestamp.toDate()) 
                  : 'Pending';

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ExpansionTile(
                  leading: CircleAvatar(
                    backgroundColor: _getSeverityColor(severity).withOpacity(0.1),
                    child: Icon(Icons.report, color: _getSeverityColor(severity)),
                  ),
                  title: Text(
                    data['type'] ?? 'Unknown Type',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    '$severity Priority • $dateStr',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailRow(Icons.location_on, 'Location', data['location'] ?? 'Unknown'),
                          const SizedBox(height: 8),
                          _buildDetailRow(Icons.description, 'Description', data['description'] ?? 'No description provided'),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                onPressed: () {
                                  // TODO: Resolve incident
                                },
                                icon: const Icon(Icons.check_circle_outline),
                                label: const Text('Mark Resolved'),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 14)),
            ],
          ),
        ),
      ],
    );
  }
}
