import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'firebase_options.dart';
import 'widgets/create_fir_dialog.dart';
import 'widgets/officer_map_widget.dart';
import 'widgets/google_maps_widget.dart';
import 'widgets/proper_google_maps_widget.dart';
import 'widgets/leave_request_dialog.dart';
import 'widgets/shift_details_dialog.dart';
import 'widgets/fir_details_dialog.dart';
import 'widgets/officer_shifts_widget.dart';
import 'widgets/sos_alert_button.dart';
import 'features/admin/sos_dashboard_screen.dart';
import 'services/roster_service.dart';
import 'screens/login_screen.dart';
import 'features/communication/chat_screen.dart';
import 'features/patrol/smart_beat_patrol_screen.dart';
import 'features/malkhana/malkhana.dart';
import 'widgets/officer_shifts_widget.dart';
import 'features/communication/communication_hub_screen.dart';
import 'widgets/enhanced_incident_dialog.dart';
import 'features/admin/incident_dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    print("Initializing Firebase...");
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      print("Firebase Initialized Successfully");
    } on FirebaseException catch (e) {
      if (e.code == 'duplicate-app') {
        print("Firebase already initialized (native persistence)");
      } else {
        rethrow;
      }
    } catch (e) {
      // Any other non-firebase error
      print("Non-Firebase Init Error: $e");
    }
    runApp(const PolisOneApp());
  } catch (e, stack) {
    print("Initialization Error: $e\n$stack");
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Text("Startup Error:\n$e", style: const TextStyle(color: Colors.red)),
            ),
          ),
        ),
      ),
    );
  }
}

class PolisOneApp extends StatelessWidget {
  const PolisOneApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PolisOne',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: const ModuleSelectionScreen(),
      routes: {
        '/login': (context) => const LoginScreen(moduleType: 'admin'),
        '/modules': (context) => const ModuleSelectionScreen(),
        '/admin': (context) => const AdminDashboard(),
        '/officer': (context) => const OfficerDashboard(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}

// Module Selection Screen
class ModuleSelectionScreen extends StatelessWidget {
  const ModuleSelectionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1E40AF), Color(0xFF7C3AED)],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.shield, size: 80, color: Colors.white),
                const SizedBox(height: 24),
                const Text(
                  'PolisOne',
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Integrated Smart Policing Ecosystem',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 64),
                _buildModuleCard(
                  context,
                  icon: Icons.shield,
                  title: 'Admin Module',
                  subtitle: 'Operations, Analytics & Management',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(moduleType: 'admin'),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 20),
                _buildModuleCard(
                  context,
                  icon: Icons.people,
                  title: 'Officer Module',
                  subtitle: 'Field Operations & Communication',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(moduleType: 'officer'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildModuleCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 40, color: const Color(0xFF1E40AF)),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.grey[400]),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// Admin Dashboard
class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  String currentTab = 'operations-map';

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: currentTab == 'operations-map',
      onPopInvoked: (didPop) {
        if (didPop) return;
        setState(() {
          currentTab = 'operations-map';
        });
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_getAppBarTitle()),
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Logout',
              onPressed: () async {
                await FirebaseAuth.instance.signOut();
                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/modules',
                    (route) => false,
                  );
                }
              },
            ),
          ],
        ),
        drawer: _buildAdminDrawer(),
        body: _getAdminContent(),
      ),
    );
  }

  String _getAppBarTitle() {
    switch (currentTab) {
      case 'operations-map': return 'Real-Time Operations';
      case 'communication': return 'Department Communication';
      case 'roster': return 'Smart Roster';
      case 'evidence': return 'Digital Malkhana';
      case 'fir': return 'Digital FIR';
      case 'analytics': return 'Crime Analytics';
      case 'sos': return 'Emergency Response Center';
      case 'incidents': return 'Incident Reports';
      default: return 'Admin Module';
    }
  }

  Widget _buildAdminDrawer() {
    return Drawer(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1E40AF), Color(0xFF7C3AED)],
              ),
            ),
            padding: const EdgeInsets.fromLTRB(16, 48, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.shield, size: 48, color: Colors.white),
                const SizedBox(height: 12),
                const Text(
                  'Admin Dashboard',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Mumbai Police HQ',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(8),
              children: [
                _buildDrawerItem(Icons.map, 'Real-Time Operations Map', 'operations-map'),
                _buildDrawerItem(Icons.radio, 'Communication Channels', 'communication'),
                _buildDrawerItem(Icons.calendar_today, 'Smart Roster System', 'roster'),
                _buildDrawerItem(Icons.inventory_2, 'Digital Malkhana', 'evidence'),
                _buildDrawerItem(Icons.description, 'Digital FIR', 'fir'),
                _buildDrawerItem(Icons.bar_chart, 'Crime Analytics', 'analytics'),
                _buildDrawerItem(Icons.warning_amber_rounded, 'SOS Emergency Response', 'sos'),
                _buildDrawerItem(Icons.report_problem, 'Incident Reports', 'incidents'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String label, String id) {
    final isSelected = currentTab == id;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: ListTile(
        leading: Icon(icon, size: 20),
        title: Text(label, style: const TextStyle(fontSize: 14)),
        selected: isSelected,
        selectedTileColor: Colors.blue[50],
        selectedColor: const Color(0xFF1E40AF),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        onTap: () {
          setState(() {
            currentTab = id;
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  Widget _getAdminContent() {
    switch (currentTab) {
      case 'operations-map':
        return const OperationsMapScreen();
      case 'communication':
        return const CommunicationHubScreen(isAdmin: true);
      case 'roster':
        return const SmartRosterScreen();
      case 'evidence':
        return const EvidenceListScreen();
      case 'fir':
        return const DigitalFIRScreen();
      case 'analytics':
        return const CrimeAnalyticsScreen();
      case 'sos':
        return SOSDashboardScreen(firestore: FirebaseFirestore.instance);
      case 'incidents':
        return IncidentDashboardScreen(firestore: FirebaseFirestore.instance);
      default:
        return const OperationsMapScreen();
    }
  }
}

// Operations Map Screen - WITH FIREBASE
class OperationsMapScreen extends StatefulWidget {
  const OperationsMapScreen({Key? key}) : super(key: key);

  @override
  State<OperationsMapScreen> createState() => _OperationsMapScreenState();
}

class _OperationsMapScreenState extends State<OperationsMapScreen> {
  final _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.map, color: Color(0xFF1E40AF)),
                    const SizedBox(width: 8),
                    const Text(
                      'Real-Time Operations Map',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.circle, size: 8, color: Colors.green),
                          SizedBox(width: 4),
                          Text(
                            'Live',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Real-time officer count from Firebase (ONLY authenticated officers)
                StreamBuilder<QuerySnapshot>(
                  stream: _firestore.collection('officers')
                      .where('userId', isNotEqualTo: null) // Only authenticated officers
                      .snapshots(),
                  builder: (context, snapshot) {
                    final totalOfficers = snapshot.data?.docs.length ?? 0;
                    final onPatrol = snapshot.data?.docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return data['status'] == 'on_patrol' && data['userId'] != null;
                    }).length ?? 0;
                    final responding = snapshot.data?.docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return data['status'] == 'responding' && data['userId'] != null;
                    }).length ?? 0;
                    final offDuty = snapshot.data?.docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return data['status'] == 'off_duty' && data['userId'] != null;
                    }).length ?? 0;

                    return Container(
                      padding: const EdgeInsets.all(32),
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
                          const Icon(Icons.map, size: 80, color: Color(0xFF1E40AF)),
                          const SizedBox(height: 16),
                          const Text(
                            'Live GPS Tracking',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '$totalOfficers Units Active',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E40AF),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Wrap(
                            spacing: 16,
                            runSpacing: 16,
                            alignment: WrapAlignment.center,
                            children: [
                              _buildStatusChip('On Patrol ($onPatrol)', Colors.green),
                              _buildStatusChip('Responding ($responding)', Colors.orange),
                              _buildStatusChip('Off-Duty ($offDuty)', Colors.grey),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Google Maps with Officer Tracking
        ProperGoogleMapsWidget(firestore: _firestore),
        const SizedBox(height: 16),
        StreamBuilder<QuerySnapshot>(
          stream: _firestore.collection('officers')
              .where('userId', isNotEqualTo: null) // Only authenticated officers
              .snapshots(),
          builder: (context, snapshot) {
            final activeCount = snapshot.data?.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return data['status'] != 'off_duty' && data['userId'] != null;
            }).length ?? 0;

            return Row(
              children: [
                Expanded(
                  child: _buildStatCard('Active Units', '$activeCount', 'Real-time count', Colors.green),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard('Avg Response Time', '4.2m', 'Last hour', Colors.green),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Active Officers',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                // Real-time officer list (ONLY authenticated officers)
                StreamBuilder<QuerySnapshot>(
                  stream: _firestore.collection('officers')
                      .where('status', whereIn: ['on_patrol', 'responding'])
                      .where('userId', isNotEqualTo: null) // Only authenticated officers
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Text(
                            'No active officers. Add officers in Firebase.',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ),
                      );
                    }

                    return Column(
                      children: snapshot.data!.docs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final name = data['name'] ?? 'Unknown';
                        final status = data['status'] ?? 'off_duty';
                        final location = data['current_location'] ?? 'Unknown';
                        final lastUpdate = (data['last_updated'] as Timestamp?)?.toDate();
                        final timeAgo = lastUpdate != null 
                            ? _getTimeAgo(lastUpdate)
                            : 'Unknown';

                        return _buildActivity(
                          name,
                          status == 'on_patrol' ? 'On Patrol' : 'Responding to incident',
                          location,
                          timeAgo,
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hr ago';
    return '${diff.inDays} days ago';
  }

  Widget _buildStatusChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, String subtitle, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActivity(String unit, String action, String location, String time) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          left: const BorderSide(color: Colors.blue, width: 4),
          bottom: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      padding: const EdgeInsets.only(left: 12, bottom: 12, top: 4),
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$unit - $action',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '📍 $location • $time',
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



// Smart Roster Screen - Firebase Powered
class SmartRosterScreen extends StatefulWidget {
  const SmartRosterScreen({Key? key}) : super(key: key);

  @override
  State<SmartRosterScreen> createState() => _SmartRosterScreenState();
}

class _SmartRosterScreenState extends State<SmartRosterScreen> {
  final _firestore = FirebaseFirestore.instance;
  final _rosterService = RosterService();
  bool _isGenerating = false;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.calendar_today, color: Color(0xFF1E40AF)),
                    SizedBox(width: 8),
                    Text(
                      'Smart Roster System',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Auto-Schedule Generation',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Generate optimal shift assignments',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _isGenerating ? null : _generateSchedule,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E40AF),
                          foregroundColor: Colors.white,
                        ),
                        child: _isGenerating
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text('Generate Now'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Real-time metrics
                StreamBuilder<QuerySnapshot>(
                  stream: _firestore.collection('officers')
                      .where('userId', isNotEqualTo: null)
                      .snapshots(),
                  builder: (context, officerSnapshot) {
                    return StreamBuilder<QuerySnapshot>(
                      stream: _firestore.collection('leave_requests')
                          .where('status', isEqualTo: 'pending')
                          .snapshots(),
                      builder: (context, leaveSnapshot) {
                        final totalOfficers = officerSnapshot.data?.docs.length ?? 0;
                        final pendingLeaves = leaveSnapshot.data?.docs.length ?? 0;
                        
                        // Calculate workload balance (simplified)
                        final workloadBalance = totalOfficers > 0 ? 94 : 0;
                        
                        return Row(
                          children: [
                            Expanded(child: _buildMetricCard('Workload Balanced', '$workloadBalance%', Colors.green)),
                            const SizedBox(width: 8),
                            Expanded(child: _buildMetricCard('Total Officers', '$totalOfficers', Colors.blue)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: InkWell(
                                onTap: () => _showLeaveRequests(context),
                                child: _buildMetricCard('Leave Requests', '$pendingLeaves', Colors.orange),
                              ),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 16),
                const Text(
                  "Today's Schedule",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                // Real-time shift list - ALL SHIFTS
                StreamBuilder<QuerySnapshot>(
                  stream: _firestore.collection('shifts').snapshots(),
                  builder: (context, snapshot) {
                    print('📊 Shift StreamBuilder state: ${snapshot.connectionState}');
                    print('📊 Has data: ${snapshot.hasData}');
                    print('📊 Docs count: ${snapshot.data?.docs.length ?? 0}');
                    
                    if (snapshot.hasError) {
                      print('❌ Error in shift stream: ${snapshot.error}');
                      return Center(
                        child: Text('Error: ${snapshot.error}'),
                      );
                    }
                    
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      print('⚠️ No shifts found in query');
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Icon(Icons.event_busy, size: 48, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                'No shifts scheduled for today',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton(
                                onPressed: _generateSchedule,
                                child: const Text('Generate Schedule'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    print('✅ Displaying ${snapshot.data!.docs.length} shifts');
                    return Column(
                      children: snapshot.data!.docs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        print('📝 Shift: ${data['name']} - ${data['status']}');
                        return _buildShiftCard(
                          data['name'] ?? 'Shift',
                          (data['assignedOfficers'] as List?)?.length ?? 0,
                          data['status'] ?? 'upcoming',
                          data['status'] == 'active',
                          doc.id,
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _generateSchedule() async {
    setState(() => _isGenerating = true);
    
    try {
      await _rosterService.generateSchedule(DateTime.now());
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Schedule generated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating schedule: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  void _showLeaveRequests(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const LeaveRequestDialog(),
    );
  }

  Widget _buildMetricCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
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
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShiftCard(String shift, int officers, String status, bool isActive, String shiftId) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shift,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$officers officers assigned',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: isActive ? Colors.green[100] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isActive ? Colors.green[700] : Colors.grey[700],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.visibility, size: 20),
                onPressed: () => _showShiftDetails(shiftId),
                tooltip: 'View Details',
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showShiftDetails(String shiftId) {
    showDialog(
      context: context,
      builder: (context) => ShiftDetailsDialog(
        shiftId: shiftId,
        firestore: _firestore,
      ),
    );
  }
}

// Digital Malkhana Screen
class DigitalMalkhanaScreen extends StatelessWidget {
  const DigitalMalkhanaScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.inventory_2, color: Colors.green),
                    SizedBox(width: 8),
                    Text(
                      'Digital Malkhana (Evidence Vault)',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.5,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  children: [
                    _buildStatCard('Total Items', '1,247', Colors.green),
                    _buildStatCard('Pending Disposal', '89', Colors.orange),
                    _buildStatCard('Alerts', '5', Colors.red),
                    _buildStatCard('Accessed Today', '23', Colors.blue),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Recent Evidence Entries',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildEvidenceCard('EV-2024-00123', 'Seized Vehicle', 'FIR-456/2024', 'In Custody', false),
                _buildEvidenceCard('EV-2024-00122', 'Cash ₹50,000', 'FIR-455/2024', 'Court Pending', false),
                _buildEvidenceCard('EV-2024-00121', 'Mobile Phone', 'FIR-454/2024', 'In Custody', true),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
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
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEvidenceCard(String id, String type, String caseNumber, String status, bool hasAlert) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: hasAlert ? Colors.red[50] : Colors.white,
        border: Border.all(color: hasAlert ? Colors.red[300]! : Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      id,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    ),
                    if (hasAlert) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'ALERT',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  type,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Case: $caseNumber',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: status == 'In Custody' ? Colors.green[100] : Colors.yellow[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: status == 'In Custody' ? Colors.green[700] : Colors.yellow[800],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Digital FIR Screen - WITH FIREBASE
class DigitalFIRScreen extends StatefulWidget {
  const DigitalFIRScreen({Key? key}) : super(key: key);

  @override
  State<DigitalFIRScreen> createState() => _DigitalFIRScreenState();
}

class _DigitalFIRScreenState extends State<DigitalFIRScreen> {
  final _firestore = FirebaseFirestore.instance;

  Future<void> _createNewFIR() async {
    // Show dialog to create new FIR
    showDialog(
      context: context,
      builder: (context) => EnhancedCreateFIRDialog(firestore: _firestore),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.description, color: Color(0xFF1E40AF)),
                        SizedBox(width: 8),
                        Text(
                          'Digital FIR',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: _createNewFIR,
                      icon: const Icon(Icons.add),
                      label: const Text('New FIR'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E40AF),
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Real-time metrics from Firebase
                StreamBuilder<QuerySnapshot>(
                  stream: _firestore.collection('firs').snapshots(),
                  builder: (context, snapshot) {
                    final total = snapshot.data?.docs.length ?? 0;
                    final thisMonth = snapshot.data?.docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
                      if (createdAt == null) return false;
                      final now = DateTime.now();
                      return createdAt.year == now.year && createdAt.month == now.month;
                    }).length ?? 0;
                    final pending = snapshot.data?.docs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return data['status'] == 'Open';
                    }).length ?? 0;

                    return Row(
                      children: [
                        Expanded(child: _buildMetricCard('Total FIRs', '$total', Colors.blue)),
                        const SizedBox(width: 8),
                        Expanded(child: _buildMetricCard('This Month', '$thisMonth', Colors.green)),
                        const SizedBox(width: 8),
                        Expanded(child: _buildMetricCard('Pending', '$pending', Colors.orange)),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text(
                      'Recent FIRs',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.circle, size: 8, color: Colors.green),
                          SizedBox(width: 4),
                          Text(
                            'Live',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Real-time FIR list from Firebase
                StreamBuilder<QuerySnapshot>(
                  stream: _firestore.collection('firs')
                      .orderBy('createdAt', descending: true)
                      .limit(10)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            children: [
                              Icon(Icons.description_outlined, size: 48, color: Colors.grey[400]),
                              const SizedBox(height: 8),
                              Text(
                                'No FIRs yet. Click "New FIR" to create one.',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return Column(
                      children: snapshot.data!.docs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        final firNumber = data['firNumber'] ?? 'FIR-${doc.id.substring(0, 8).toUpperCase()}';
                        final type = data['type'] ?? 'Unknown';
                        final description = data['description'] ?? '';
                        final status = data['status'] ?? 'Pending';
                        final priority = data['priority'] ?? 'Medium';
                        final location = data['location'] ?? 'N/A';
                        final complainantName = data['complainantName'] ?? 'N/A';
                        final assignedOfficerName = data['assignedOfficerName'];
                        final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
                        final dateStr = createdAt != null 
                            ? '${createdAt.day} ${_getMonthName(createdAt.month)} ${createdAt.year}'
                            : 'Unknown';

                        return InkWell(
                          onTap: () {
                            showDialog(
                              context: context,
                              builder: (context) => FIRDetailsDialog(
                                firId: doc.id,
                                firestore: _firestore,
                                canAssignOfficer: true, // Only enabled for Admin dashboard
                              ),
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.white,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        firNumber,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _getPriorityColor(priority).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: _getPriorityColor(priority)),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.priority_high, size: 12, color: _getPriorityColor(priority)),
                                          const SizedBox(width: 4),
                                          Text(
                                            priority,
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: _getPriorityColor(priority),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(status).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(color: _getStatusColor(status)),
                                      ),
                                      child: Text(
                                        status,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: _getStatusColor(status),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.blue[50],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        type,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.blue,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(Icons.calendar_today, size: 12, color: Colors.grey[600]),
                                    const SizedBox(width: 4),
                                    Text(
                                      dateStr,
                                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  description.length > 80 ? '${description.substring(0, 80)}...' : description,
                                  style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                                    const SizedBox(width: 4),
                                    Text(
                                      location,
                                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                    ),
                                    const Spacer(),
                                    if (assignedOfficerName != null) ...[
                                      Icon(Icons.badge, size: 14, color: Colors.green[700]),
                                      const SizedBox(width: 4),
                                      Text(
                                        assignedOfficerName,
                                        style: TextStyle(fontSize: 12, color: Colors.green[700], fontWeight: FontWeight.w500),
                                      ),
                                    ] else ...[
                                      Icon(Icons.person_off, size: 14, color: Colors.grey[500]),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Unassigned',
                                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
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

  Future<void> _updateFIRStatus(String docId, String currentStatus) async {
    final statuses = ['Pending', 'Under Investigation', 'Evidence Collected', 'Assigned', 'Closed'];
    final currentIndex = statuses.indexOf(currentStatus);
    final nextStatus = statuses[(currentIndex + 1) % statuses.length];

    await _firestore.collection('incidents').doc(docId).update({
      'status': nextStatus,
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Status updated to $nextStatus')),
      );
    }
  }

  Widget _buildMetricCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
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
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFIRCard(String id, String type, String location, String status, String date, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  id,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                    color: Color(0xFF1E40AF),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue[700],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              type,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '📍 $location',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                Text(
                  date,
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
    );
  }
}

// Crime Analytics Screen
class CrimeAnalyticsScreen extends StatefulWidget {
  const CrimeAnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<CrimeAnalyticsScreen> createState() => _CrimeAnalyticsScreenState();
}

class _CrimeAnalyticsScreenState extends State<CrimeAnalyticsScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _selectedTimeRange = '30'; // days

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.bar_chart, color: Colors.purple),
                    const SizedBox(width: 8),
                    const Text(
                      'Crime Analytics Dashboard',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.circle, size: 8, color: Colors.green),
                          SizedBox(width: 4),
                          Text(
                            'Live',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Text('Time Range: ', style: TextStyle(fontWeight: FontWeight.w600)),
                    DropdownButton<String>(
                      value: _selectedTimeRange,
                      items: const [
                        DropdownMenuItem(value: '7', child: Text('Last 7 Days')),
                        DropdownMenuItem(value: '30', child: Text('Last 30 Days')),
                        DropdownMenuItem(value: '90', child: Text('Last 90 Days')),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedTimeRange = value!);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('firs')
                      .where('createdAt', 
                        isGreaterThan: Timestamp.fromDate(
                          DateTime.now().subtract(Duration(days: int.parse(_selectedTimeRange)))
                        )
                      )
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final firs = snapshot.data!.docs;
                    
                    if (firs.isEmpty) {
                      return Center(
                        child: Column(
                          children: [
                            const SizedBox(height: 32),
                            Icon(Icons.analytics_outlined, size: 64, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text(
                              'No FIR data available for analysis',
                              style: TextStyle(color: Colors.grey[600], fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Analytics will update automatically when FIRs are registered',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey[500], fontSize: 14),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Go to Digital FIR → Create New FIR',
                              style: TextStyle(color: Colors.blue[700], fontSize: 13, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 32),
                          ],
                        ),
                      );
                    }

                    // Calculate statistics
                    final totalCases = firs.length;
                    final resolvedCases = firs.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return data['status'] == 'Closed';
                    }).length;
                    final resolutionRate = totalCases > 0 
                        ? ((resolvedCases / totalCases) * 100).toStringAsFixed(1)
                        : '0.0';

                    // Crime type distribution
                    final Map<String, int> crimeTypes = {};
                    for (var doc in firs) {
                      final data = doc.data() as Map<String, dynamic>;
                      final type = data['type'] ?? 'Other';
                      crimeTypes[type] = (crimeTypes[type] ?? 0) + 1;
                    }

                    // Sort by count
                    final sortedCrimes = crimeTypes.entries.toList()
                      ..sort((a, b) => b.value.compareTo(a.value));

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          childAspectRatio: 1.3,
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          children: [
                            _buildAnalyticsCard('Total Cases', '$totalCases', Colors.blue),
                            _buildAnalyticsCard('Resolved', '$resolvedCases', Colors.green),
                            _buildAnalyticsCard('Resolution Rate', '$resolutionRate%', Colors.purple),
                            _buildAnalyticsCard('Pending', '${totalCases - resolvedCases}', Colors.orange),
                          ],
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Crime Distribution',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (sortedCrimes.isEmpty)
                          const Text('No crime data available')
                        else
                          ...sortedCrimes.take(5).map((entry) {
                            final maxValue = sortedCrimes.first.value;
                            return _buildProgressBar(
                              entry.key,
                              entry.value,
                              maxValue,
                              _getColorForCrimeType(entry.key),
                            );
                          }),
                        const SizedBox(height: 24),
                        const Text(
                          'Status Breakdown',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildStatusBreakdown(firs),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.trending_up, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[700],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(String label, int value, int maxValue, Color color) {
    final percentage = maxValue > 0 ? (value / maxValue) : 0.0;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '$value cases',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBreakdown(List<QueryDocumentSnapshot> firs) {
    final Map<String, int> statusCounts = {};
    for (var doc in firs) {
      final data = doc.data() as Map<String, dynamic>;
      final status = data['status'] ?? 'Unknown';
      statusCounts[status] = (statusCounts[status] ?? 0) + 1;
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: statusCounts.entries.map((entry) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: _getColorForStatus(entry.key).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _getColorForStatus(entry.key)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _getColorForStatus(entry.key),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${entry.key}: ${entry.value}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Color _getColorForCrimeType(String type) {
    switch (type.toLowerCase()) {
      case 'theft':
        return Colors.red;
      case 'assault':
        return Colors.orange;
      case 'cyber crime':
        return Colors.blue;
      case 'traffic violation':
        return Colors.green;
      case 'fraud':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  Color _getColorForStatus(String status) {
    switch (status) {
      case 'Open':
        return Colors.blue;
      case 'Under Investigation':
        return Colors.orange;
      case 'Closed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}



// Officer Dashboard
class OfficerDashboard extends StatefulWidget {
  const OfficerDashboard({Key? key}) : super(key: key);

  @override
  State<OfficerDashboard> createState() => _OfficerDashboardState();
}

class _OfficerDashboardState extends State<OfficerDashboard> {
  String currentTab = 'smart-beat';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Officer Module'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/modules',
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      drawer: _buildOfficerDrawer(),
      body: _getOfficerContent(),
      floatingActionButton: SOSAlertButton(firestore: FirebaseFirestore.instance),
    );
  }

  Widget _buildOfficerDrawer() {
    return Drawer(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF1E40AF), Color(0xFF7C3AED)],
              ),
            ),
            padding: const EdgeInsets.fromLTRB(16, 48, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.people, size: 48, color: Colors.white),
                const SizedBox(height: 12),
                const Text(
                  'Officer Dashboard',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Field Operations',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(8),
              children: [
                _buildDrawerItem(Icons.location_on, 'Smart Beat Patrol', 'smart-beat'),
                _buildDrawerItem(Icons.map, 'Real-Time Operations Map', 'operations-map'),
                _buildDrawerItem(Icons.radio, 'Communication', 'communication'),
                _buildDrawerItem(Icons.description, 'Digital FIR', 'fir'),
                _buildDrawerItem(Icons.calendar_today, 'My Roster', 'roster'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem(IconData icon, String label, String id) {
    final isSelected = currentTab == id;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: ListTile(
        leading: Icon(icon, size: 20),
        title: Text(label, style: const TextStyle(fontSize: 14)),
        selected: isSelected,
        selectedTileColor: Colors.blue[50],
        selectedColor: const Color(0xFF1E40AF),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        onTap: () {
          setState(() {
            currentTab = id;
          });
          Navigator.pop(context);
        },
      ),
    );
  }

  Widget _getOfficerContent() {
    switch (currentTab) {
      case 'smart-beat':
        return const SmartBeatPatrolScreen();
      case 'operations-map':
        return const OperationsMapOfficerScreen();
      case 'communication':
        return const CommunicationHubScreen(isAdmin: false);
      case 'fir':
        return const DigitalFIROfficerScreen();
      case 'roster':
        return const OfficerRosterScreen();
      default:
        return const SmartBeatPatrolScreen();
    }
  }
}

class OfficerRosterScreen extends StatelessWidget {
  const OfficerRosterScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Expanded(child: OfficerShiftsWidget()),
          ],
        ),
      ),
    );
  }
}


// Smart Beat Patrol Screen is now in lib/features/patrol/smart_beat_patrol_screen.dart
// Comprehensive version with all advanced features


// Operations Map Officer Screen
class OperationsMapOfficerScreen extends StatelessWidget {
  const OperationsMapOfficerScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const OperationsMapScreen();
  }
}

// Communication Screen (Restored & Real-Time)
class CommunicationScreen extends StatelessWidget {
  const CommunicationScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.forum, color: Color(0xFF1E40AF)),
                    SizedBox(width: 8),
                    Text(
                      'Department Communication',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildQuickAction(context, Icons.headset_mic, 'Control Room'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildQuickAction(context, Icons.groups, 'My Team'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildQuickAction(context, Icons.campaign, 'Announcements'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Active Channels',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () => _generateTestChannels(),
                      child: const Text('Refresh / Seed'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('communication_channels')
                      .orderBy('lastActivity', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                     if (snapshot.hasError) {
                      return Text('Error: ${snapshot.error}');
                    }

                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final channels = snapshot.data!.docs;

                    if (channels.isEmpty) {
                      return const Text('No active channels. Click Refresh to seed.');
                    }

                    return Column(
                      children: channels.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return _buildChannelCard(
                          context,
                          doc.id,
                          data['name'] ?? 'Unknown Channel',
                          data['lastMessage'] ?? '',
                          _formatTime(data['lastActivity']),
                          data['isUrgent'] ?? false,
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildQuickAction(BuildContext context, IconData icon, String label) {
    return InkWell(
      onTap: () {
        // Quick actions create/go to specific channels
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              channelId: 'quick_${label.replaceAll(' ', '_').toLowerCase()}', // predictable ID
              channelName: label,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: const Color(0xFF1E40AF)),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChannelCard(BuildContext context, String id, String name, String lastMessage, String time, bool isUrgent) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ChatScreen(
              channelId: id,
              channelName: name,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isUrgent ? Colors.blue[50] : Colors.white,
          border: Border.all(color: isUrgent ? Colors.blue[200]! : Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (isUrgent) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue[700],
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'ACTIVE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              lastMessage,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return 'Just now';
    final dt = timestamp.toDate();
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return DateFormat('MM/dd').format(dt);
  }

  Future<void> _generateTestChannels() async {
    final firestore = FirebaseFirestore.instance;
    final batch = firestore.batch();
    final now = DateTime.now();

    final channels = [
      {
        'name': 'Zone-A Patrol',
        'lastMessage': 'Control: All units report status',
        'isUrgent': true,
        'lastActivity': Timestamp.fromDate(now.subtract(const Duration(minutes: 1))),
      },
      {
        'name': 'Traffic Control',
        'lastMessage': 'Heavy traffic at Linking Road',
        'isUrgent': false,
        'lastActivity': Timestamp.fromDate(now.subtract(const Duration(minutes: 5))),
      },
      {
        'name': 'Special Ops',
        'lastMessage': 'Briefing at 14:00 hours',
        'isUrgent': false,
        'lastActivity': Timestamp.fromDate(now.subtract(const Duration(minutes: 25))),
      },
    ];

    for (var ch in channels) {
      final doc = firestore.collection('communication_channels').doc();
      batch.set(doc, ch);
    }
    
    await batch.commit();
  }
}

// Digital FIR Officer Screen
class DigitalFIROfficerScreen extends StatelessWidget {
  const DigitalFIROfficerScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const DigitalFIRScreen();
  }
}