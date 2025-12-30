import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class SOSDashboardScreen extends StatelessWidget {
  final FirebaseFirestore firestore;

  const SOSDashboardScreen({Key? key, required this.firestore}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: const TabBar(
              labelColor: Colors.red,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.red,
              tabs: [
                Tab(
                  icon: Icon(Icons.warning),
                  text: 'SOS Emergencies',
                ),
                Tab(
                  icon: Icon(Icons.notifications_active),
                  text: 'System Alerts',
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                // TAB 1: Real-time SOS Stream
                StreamBuilder<QuerySnapshot>(
                  stream: firestore
                      .collection('sos_alerts')
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final alerts = snapshot.data!.docs;
                    if (alerts.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
                            SizedBox(height: 16),
                            Text('No Active Emergencies', style: TextStyle(fontSize: 18, color: Colors.grey)),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: alerts.length,
                      itemBuilder: (context, index) {
                        final data = alerts[index].data() as Map<String, dynamic>;
                        final id = alerts[index].id;
                        final priority = data['priority'] ?? 'Medium';
                        final status = data['status'] ?? 'Active';
                        
                        return Card(
                          elevation: 4,
                          margin: const EdgeInsets.only(bottom: 16),
                          shape: RoundedRectangleBorder(
                            side: BorderSide(
                              color: status == 'Active' ? Colors.red : Colors.grey.shade300,
                              width: status == 'Active' ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: _getPriorityColor(priority),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        priority.toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(status).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: _getStatusColor(status)),
                                      ),
                                      child: Text(
                                        status.toUpperCase(),
                                        style: TextStyle(
                                          color: _getStatusColor(status),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      data['sosNumber'] ?? 'Unknown',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    const Icon(Icons.report, size: 24, color: Colors.black87),
                                    const SizedBox(width: 8),
                                    Text(
                                      data['type'] ?? 'Emergency',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                if (data['message'] != null && data['message'].isNotEmpty)
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[50],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      data['message'],
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    const Icon(Icons.person, size: 16, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(
                                      'Alert by: ${data['officerName']} (${data['officerBadge']})',
                                      style: const TextStyle(color: Colors.grey),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.location_on, size: 16, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        data['location'] ?? 'Unknown Location',
                                        style: const TextStyle(color: Colors.grey),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () {
                                          // View on Map
                                        },
                                        icon: const Icon(Icons.map),
                                        label: const Text('View Location'),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () {
                                          // Acknowledge/Respond
                                          if (status == 'Active') {
                                            _updateStatus(context, id, 'Acknowledged');
                                          } else if (status == 'Acknowledged') {
                                            _updateStatus(context, id, 'Responding');
                                          } else if (status == 'Responding') {
                                            _updateStatus(context, id, 'Resolved');
                                          }
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: status == 'Resolved' ? Colors.grey : Colors.blue[800],
                                          foregroundColor: Colors.white,
                                        ),
                                        icon: const Icon(Icons.check_circle),
                                        label: Text(
                                          status == 'Active' ? 'Acknowledge' :
                                          status == 'Acknowledged' ? 'Dispatch Units' :
                                          status == 'Responding' ? 'Mark Resolved' : 'Resolved',
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
                
                // TAB 2: System Alerts (Real-Time)
                StreamBuilder<QuerySnapshot>(
                  stream: firestore
                      .collection('system_alerts')
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                     if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final alerts = snapshot.data!.docs;
                    
                    if (alerts.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            const Text('No System Alerts', style: TextStyle(fontSize: 18, color: Colors.grey)),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => _generateTestAlerts(context),
                              child: const Text('Generate Test Alerts'),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: alerts.length,
                      itemBuilder: (context, index) {
                        final data = alerts[index].data() as Map<String, dynamic>;
                        return _buildAlert(
                          data['message'] ?? 'Unknown Alert',
                          _formatTime(data['createdAt']),
                          data['priority'] ?? 'medium',
                          _getIconForType(data['type'] ?? 'general'),
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'Critical': return Colors.red;
      case 'High': return Colors.orange;
      case 'Medium': return Colors.amber;
      default: return Colors.grey;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Active': return Colors.red;
      case 'Acknowledged': return Colors.blue;
      case 'Responding': return Colors.indigo;
      case 'Resolved': return Colors.green;
      case 'Cancelled': return Colors.grey;
      default: return Colors.grey;
    }
  }

  Future<void> _updateStatus(BuildContext context, String docId, String status) async {
    try {
      await firestore.collection('sos_alerts').doc(docId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
        if (status == 'Resolved') 'resolvedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating status: $e')),
      );
    }
  }

  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return 'Just now';
    final dt = timestamp.toDate();
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    return DateFormat('MMM d, h:mm a').format(dt);
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'security': return Icons.security;
      case 'traffic': return Icons.directions_car;
      case 'personnel': return Icons.people;
      case 'alert': return Icons.error;
      default: return Icons.notifications;
    }
  }

  Future<void> _generateTestAlerts(BuildContext context) async {
    final batch = firestore.batch();
    final now = DateTime.now();
    
    final alerts = [
      {
        'message': 'Evidence room access after hours detected',
        'priority': 'high',
        'type': 'security',
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(minutes: 15))),
      },
      {
        'message': 'Patrol breach at Zone-C checkpoint',
        'priority': 'medium',
        'type': 'security',
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(hours: 1))),
      },
      {
        'message': 'Vehicle speeding detected - MH-02-AB-1234',
        'priority': 'low',
        'type': 'traffic',
        'createdAt': Timestamp.fromDate(now.subtract(const Duration(minutes: 45))),
      },
    ];

    for (var alert in alerts) {
      final doc = firestore.collection('system_alerts').doc();
      batch.set(doc, alert);
    }

    await batch.commit();
  }

  Widget _buildAlert(String message, String time, String priority, IconData icon) {
    Color backgroundColor, borderColor, textColor, iconColor;
    
    switch (priority) {
      case 'critical':
        backgroundColor = Colors.red[50]!;
        borderColor = Colors.red;
        textColor = Colors.red[700]!;
        iconColor = Colors.red[600]!;
        break;
      case 'high':
        backgroundColor = Colors.orange[50]!;
        borderColor = Colors.orange;
        textColor = Colors.orange[700]!;
        iconColor = Colors.orange[600]!;
        break;
      case 'medium':
        backgroundColor = Colors.blue[50]!;
        borderColor = Colors.blue;
        textColor = Colors.blue[700]!;
        iconColor = Colors.blue[600]!;
        break;
      default:
        backgroundColor = Colors.grey[50]!;
        borderColor = Colors.grey;
        textColor = Colors.grey[700]!;
        iconColor = Colors.grey[600]!;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border(left: BorderSide(color: borderColor, width: 4)),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('View', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}
