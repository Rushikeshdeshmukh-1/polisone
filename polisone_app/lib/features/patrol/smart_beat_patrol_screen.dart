// COMPREHENSIVE SMART BEAT PATROL SCREEN
// This file contains the complete implementation with all 6 advanced features
// Copy this entire content to replace the SmartBeatPatrolScreen class in main.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../widgets/enhanced_incident_dialog.dart';
import '../../widgets/create_sos_dialog.dart';

// Smart Beat Patrol Screen - Comprehensive Advanced Version
class SmartBeatPatrolScreen extends StatefulWidget {
  const SmartBeatPatrolScreen({Key? key}) : super(key: key);

  @override
  State<SmartBeatPatrolScreen> createState() => _SmartBeatPatrolScreenState();
}

class _SmartBeatPatrolScreenState extends State<SmartBeatPatrolScreen> with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  late TabController _tabController;
  String? _activePatrolId;
  bool _isEmergencyMode = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userId = _auth.currentUser?.uid;
    
    if (userId == null) {
      return const Center(child: Text('Please log in to access patrol features'));
    }

    return Column(
      children: [
        // Emergency Banner (if active)
        if (_isEmergencyMode)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: Colors.red,
            child: Row(
              children: [
                const Icon(Icons.warning, color: Colors.white),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    '🚨 EMERGENCY MODE ACTIVE',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() => _isEmergencyMode = false),
                  child: const Text('DEACTIVATE', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        
        // Tab Bar
        Container(
          color: Colors.grey[100],
          child: TabBar(
            controller: _tabController,
            labelColor: const Color(0xFF1E40AF),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFF1E40AF),
            tabs: const [
              Tab(icon: Icon(Icons.location_on), text: 'Patrol'),
              Tab(icon: Icon(Icons.analytics), text: 'Analytics'),
              Tab(icon: Icon(Icons.history), text: 'History'),
            ],
          ),
        ),
        
        // Tab Views
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildPatrolTab(userId),
              _buildAnalyticsTab(userId),
              _buildHistoryTab(userId),
            ],
          ),
        ),
      ],
    );
  }

  // TAB 1: PATROL (Main patrol interface)
  Widget _buildPatrolTab(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('patrols')
          .where('officerId', isEqualTo: userId)
          .where('status', isEqualTo: 'active')
          .snapshots(),
      builder: (context, patrolSnapshot) {
        final hasActivePatrol = patrolSnapshot.hasData && 
                               patrolSnapshot.data!.docs.isNotEmpty;
        
        if (hasActivePatrol) {
          final patrolDoc = patrolSnapshot.data!.docs.first;
          final patrolData = patrolDoc.data() as Map<String, dynamic>;
          _activePatrolId = patrolDoc.id;
          
          return _buildActivePatrolView(patrolDoc.id, patrolData, userId);
        }
        
        return _buildStartPatrolView(userId);
      },
    );
  }

  Widget _buildStartPatrolView(String userId) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Shift Status Card
        StreamBuilder<QuerySnapshot>(
          stream: _firestore
              .collection('shifts')
              .where('assignedOfficers', arrayContains: userId)
              .snapshots(),
          builder: (context, shiftSnapshot) {
             // Filter for today's shift in memory
            final today = DateTime.now();
            final todayShifts = shiftSnapshot.hasData 
                ? shiftSnapshot.data!.docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final shiftDate = (data['date'] as Timestamp?)?.toDate();
                    if (shiftDate == null) return false;
                    return shiftDate.year == today.year && 
                           shiftDate.month == today.month && 
                           shiftDate.day == today.day;
                  }).toList()
                : [];
            
            final hasShift = todayShifts.isNotEmpty;
            final shiftData = hasShift 
                ? todayShifts.first.data() as Map<String, dynamic>
                : null;

            return Card(
              color: hasShift ? Colors.blue[50] : Colors.orange[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          hasShift ? Icons.check_circle : Icons.info,
                          color: hasShift ? Colors.green : Colors.orange,
                          size: 32,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                hasShift ? 'Shift Assigned' : 'No Shift Today',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (hasShift) ...[
                                const SizedBox(height: 4),
                                Text(
                                  shiftData!['name'] ?? 'Assigned Shift',
                                  style: TextStyle(color: Colors.grey[700]),
                                ),
                                Text(
                                  'Beat: ${shiftData['beat'] ?? 'Not assigned'}',
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),

        // Start Patrol Card
        Card(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.blue[50]!, Colors.blue[100]!],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.location_on, size: 64, color: Color(0xFF1E40AF)),
                      const SizedBox(height: 16),
                      const Text(
                        'Ready to Start Patrol',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Begin your beat patrol with real-time tracking',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => _startPatrol(userId),
                        icon: const Icon(Icons.play_arrow, size: 28),
                        label: const Text('START PATROL', style: TextStyle(fontSize: 16)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E40AF),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActivePatrolView(String patrolId, Map<String, dynamic> data, String userId) {
    // Handle null timestamp (Firestore serverTimestamp is null until it syncs)
    final startTimeData = data['startTime'];
    if (startTimeData == null) {
      return const Center(child: CircularProgressIndicator());
    }
    
    final startTime = (startTimeData as Timestamp).toDate();
    final beatZone = data['beatZone'] ?? 'General Patrol';
    final checkpoints = (data['checkpointsCompleted'] as List?)?.length ?? 0;
    final totalCheckpoints = data['totalCheckpoints'] ?? 8;
    final incidentsReported = data['incidentsReported'] ?? 0;
    final distanceCovered = (data['distanceCovered'] ?? 0.0).toDouble();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Active Patrol Status Card
        Card(
          color: Colors.green[50],
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.radio_button_checked, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'PATROL ACTIVE',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ),
                    StreamBuilder(
                      stream: Stream.periodic(const Duration(seconds: 1)),
                      builder: (context, snapshot) {
                        final duration = DateTime.now().difference(startTime);
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E40AF),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _formatDuration(duration),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Beat Zone Info
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green[200]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.location_city, color: Color(0xFF1E40AF), size: 28),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Patrol Zone',
                                  style: TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                                Text(
                                  beatZone,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Progress Bar
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Checkpoint Progress',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              Text(
                                '$checkpoints/$totalCheckpoints',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1E40AF),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: LinearProgressIndicator(
                              value: totalCheckpoints > 0 ? checkpoints / totalCheckpoints : 0,
                              backgroundColor: Colors.grey[200],
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                              minHeight: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      
                      // Stats Row
                      Row(
                        children: [
                          Expanded(
                            child: _buildStatChip(
                              Icons.flag,
                              '$checkpoints',
                              'Checkpoints',
                              Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatChip(
                              Icons.report,
                              '$incidentsReported',
                              'Incidents',
                              Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStatChip(
                              Icons.route,
                              '${distanceCovered.toStringAsFixed(1)}km',
                              'Distance',
                              Colors.purple,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Quick Actions
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Quick Actions',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _checkInAtCheckpoint(patrolId),
                        icon: const Icon(Icons.location_on),
                        label: const Text('Check-In'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _showIncidentDialog(patrolId),
                        icon: const Icon(Icons.report_problem),
                        label: const Text('Report'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _activateEmergency(patrolId),
                        icon: const Icon(Icons.emergency),
                        label: const Text('EMERGENCY'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.red,
                          side: const BorderSide(color: Colors.red, width: 2),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => _endPatrol(patrolId),
                        icon: const Icon(Icons.stop),
                        label: const Text('End Patrol'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Checkpoint List
        _buildCheckpointList(patrolId, checkpoints, totalCheckpoints),
      ],
    );
  }

  Widget _buildCheckpointList(String patrolId, int completed, int total) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.checklist, color: Color(0xFF1E40AF)),
                const SizedBox(width: 8),
                const Text(
                  'Checkpoints',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                Text(
                  '$completed/$total',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E40AF),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            StreamBuilder<DocumentSnapshot>(
              stream: _firestore.collection('patrols').doc(patrolId).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const CircularProgressIndicator();
                }

                final data = snapshot.data!.data() as Map<String, dynamic>?;
                final completedCheckpoints = (data?['checkpointsCompleted'] as List?)?.cast<Map<String, dynamic>>() ?? [];

                return Column(
                  children: List.generate(total, (index) {
                    final isCompleted = index < completedCheckpoints.length;
                    final checkpoint = isCompleted ? completedCheckpoints[index] : null;
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isCompleted ? Colors.green[50] : Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isCompleted ? Colors.green : Colors.grey[300]!,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isCompleted ? Icons.check_circle : Icons.radio_button_unchecked,
                            color: isCompleted ? Colors.green : Colors.grey,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Checkpoint ${index + 1}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: isCompleted ? Colors.green[900] : Colors.grey[700],
                                  ),
                                ),
                                if (isCompleted && checkpoint != null)
                                  Text(
                                    checkpoint['location'] ?? 'Location recorded',
                                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                  ),
                              ],
                            ),
                          ),
                          if (isCompleted && checkpoint != null)
                            Text(
                              _formatTime(checkpoint['time']),
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                        ],
                      ),
                    );
                  }),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // TAB 2: ANALYTICS
  Widget _buildAnalyticsTab(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('patrols')
          .where('officerId', isEqualTo: userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final patrols = snapshot.data!.docs;
        final completedPatrols = patrols.where((p) {
          final data = p.data() as Map<String, dynamic>;
          return data['status'] == 'completed';
        }).toList();

        // Calculate metrics
        final totalPatrols = patrols.length;
        final completionRate = totalPatrols > 0 
            ? (completedPatrols.length / totalPatrols * 100).toStringAsFixed(0)
            : '0';
        
        double avgDuration = 0;
        if (completedPatrols.isNotEmpty) {
          int totalMinutes = 0;
          for (var patrol in completedPatrols) {
            final data = patrol.data() as Map<String, dynamic>;
            if (data['startTime'] != null && data['endTime'] != null) {
              final start = (data['startTime'] as Timestamp).toDate();
              final end = (data['endTime'] as Timestamp).toDate();
              totalMinutes += end.difference(start).inMinutes;
            }
          }
          avgDuration = totalMinutes / completedPatrols.length;
        }

        double totalDistance = 0;
        int totalIncidents = 0;
        int totalCheckpoints = 0;
        
        for (var patrol in patrols) {
          final data = patrol.data() as Map<String, dynamic>;
          totalDistance += (data['distanceCovered'] ?? 0.0).toDouble();
          totalIncidents += (data['incidentsReported'] ?? 0) as int;
          totalCheckpoints += ((data['checkpointsCompleted'] as List?)?.length ?? 0);
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Performance Analytics',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Key Metrics
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              children: [
                _buildAnalyticsCard('Total Patrols', '$totalPatrols', Icons.route, Colors.blue),
                _buildAnalyticsCard('Completion Rate', '$completionRate%', Icons.check_circle, Colors.green),
                _buildAnalyticsCard('Avg Duration', '${avgDuration.toStringAsFixed(0)}m', Icons.timer, Colors.orange),
                _buildAnalyticsCard('Total Distance', '${totalDistance.toStringAsFixed(1)}km', Icons.straighten, Colors.purple),
              ],
            ),
            const SizedBox(height: 16),
            
            // Additional Stats
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Activity Summary',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    _buildStatRow('Checkpoints Completed', '$totalCheckpoints', Icons.flag),
                    _buildStatRow('Incidents Reported', '$totalIncidents', Icons.report),
                    _buildStatRow('Active Patrols', '${patrols.where((p) => (p.data() as Map)['status'] == 'active').length}', Icons.play_circle),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildAnalyticsCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E40AF),
            ),
          ),
        ],
      ),
    );
  }

  // TAB 3: HISTORY
  Widget _buildHistoryTab(String userId) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('patrols')
          .where('officerId', isEqualTo: userId)
          .orderBy('startTime', descending: true)
          .limit(20)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  'No patrol history yet',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Patrol History',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...snapshot.data!.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return _buildPatrolHistoryCard(data);
            }),
          ],
        );
      },
    );
  }

  Widget _buildPatrolHistoryCard(Map<String, dynamic> data) {
    final startTime = (data['startTime'] as Timestamp).toDate();
    final endTime = data['endTime'] != null 
        ? (data['endTime'] as Timestamp).toDate()
        : null;
    final duration = endTime != null 
        ? endTime.difference(startTime)
        : const Duration();
    final status = data['status'] ?? 'unknown';
    final beatZone = data['beatZone'] ?? 'Unknown';
    final checkpoints = (data['checkpointsCompleted'] as List?)?.length ?? 0;
    final incidents = data['incidentsReported'] ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: status == 'completed' ? Colors.green[100] : Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    status == 'completed' ? Icons.check_circle : Icons.pending,
                    color: status == 'completed' ? Colors.green : Colors.grey,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        beatZone,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        DateFormat('MMM dd, yyyy • h:mm a').format(startTime),
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                if (endTime != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _formatDuration(duration),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E40AF),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildSmallStat(Icons.flag, '$checkpoints', 'Checkpoints'),
                const SizedBox(width: 16),
                _buildSmallStat(Icons.report, '$incidents', 'Incidents'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallStat(IconData icon, String value, String label) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Text(
          '$value $label',
          style: TextStyle(fontSize: 12, color: Colors.grey[700]),
        ),
      ],
    );
  }

  // Helper Widgets
  Widget _buildStatChip(IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    } else if (minutes > 0) {
      return '${minutes}m ${seconds}s';
    } else {
      return '${seconds}s';
    }
  }

  String _formatTime(dynamic timestamp) {
    if (timestamp == null) return '';
    if (timestamp is Timestamp) {
      return DateFormat('h:mm a').format(timestamp.toDate());
    }
    if (timestamp is String) {
      try {
        final dateTime = DateTime.parse(timestamp);
        return DateFormat('h:mm a').format(dateTime);
      } catch (e) {
        return '';
      }
    }
    return '';
  }

  // Actions
  Future<void> _startPatrol(String userId) async {
    try {
      // Get current shift to determine beat
      final shiftQuery = await _firestore
          .collection('shifts')
          .where('officerId', isEqualTo: userId)
          .where('date', isEqualTo: DateFormat('yyyy-MM-dd').format(DateTime.now()))
          .get();

      String beatZone = 'General Patrol';
      if (shiftQuery.docs.isNotEmpty) {
        final shiftData = shiftQuery.docs.first.data();
        beatZone = shiftData['beat'] ?? beatZone;
      }

      await _firestore.collection('patrols').add({
        'officerId': userId,
        'officerName': _auth.currentUser?.email?.split('@')[0] ?? 'Officer',
        'beatZone': beatZone,
        'status': 'active',
        'startTime': FieldValue.serverTimestamp(),
        'endTime': null,
        'checkpointsCompleted': [],
        'totalCheckpoints': 8,
        'incidentsReported': 0,
        'incidents': [],
        'distanceCovered': 0.0,
        'locationHistory': [],
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Patrol started successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _endPatrol(String patrolId) async {
    try {
      await _firestore.collection('patrols').doc(patrolId).update({
        'status': 'completed',
        'endTime': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Patrol completed successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _checkInAtCheckpoint(String patrolId) async {
    try {
      // Use DateTime.now() instead of serverTimestamp() because arrayUnion doesn't support serverTimestamp
      final checkpoint = {
        'time': DateTime.now().toIso8601String(),
        'location': 'Checkpoint Location', // Would use GPS in production
      };

      // Simulate distance increment
      await _firestore.collection('patrols').doc(patrolId).update({
        'checkpointsCompleted': FieldValue.arrayUnion([checkpoint]),
        'distanceCovered': FieldValue.increment(1.5), // Add 1.5 km per checkpoint
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Checked in at checkpoint!'),
            backgroundColor: Colors.blue,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showIncidentDialog(String patrolId) {
    showDialog(
      context: context,
      builder: (context) => EnhancedIncidentReportDialog(
        patrolId: patrolId,
        firestore: _firestore,
      ),
    );
  }

  Future<void> _activateEmergency(String patrolId) async {
    showDialog(
      context: context,
      builder: (context) => CreateSOSDialog(firestore: _firestore),
    );
  }
}
