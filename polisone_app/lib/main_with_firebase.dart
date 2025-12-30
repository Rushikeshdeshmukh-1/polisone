import 'package:flutter/material.dart';

void main() {
  runApp(const PolisOneApp());
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
                        builder: (context) => const AdminDashboard(),
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
                        builder: (context) => const OfficerDashboard(),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Module'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {},
          ),
        ],
      ),
      drawer: _buildAdminDrawer(),
      body: _getAdminContent(),
    );
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
                _buildDrawerItem(Icons.error, 'Alert Center', 'alert-center'),
                _buildDrawerItem(Icons.calendar_today, 'Smart Roster System', 'roster'),
                _buildDrawerItem(Icons.inventory_2, 'Digital Malkhana', 'evidence'),
                _buildDrawerItem(Icons.description, 'Digital FIR', 'fir'),
                _buildDrawerItem(Icons.bar_chart, 'Crime Analytics Dashboard', 'analytics'),
                _buildDrawerItem(Icons.message, 'Communication & Coordination', 'communication'),
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
      case 'alert-center':
        return const AlertCenterScreen();
      case 'roster':
        return const SmartRosterScreen();
      case 'evidence':
        return const DigitalMalkhanaScreen();
      case 'fir':
        return const DigitalFIRScreen();
      case 'analytics':
        return const CrimeAnalyticsScreen();
      case 'communication':
        return const CommunicationScreen();
      default:
        return const OperationsMapScreen();
    }
  }
}

// Operations Map Screen
class OperationsMapScreen extends StatelessWidget {
  const OperationsMapScreen({Key? key}) : super(key: key);

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
                    Icon(Icons.map, color: Color(0xFF1E40AF)),
                    SizedBox(width: 8),
                    Text(
                      'Real-Time Operations Map',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
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
                      const Text(
                        '24 Units Active',
                        style: TextStyle(
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
                          _buildStatusChip('On Patrol (18)', Colors.green),
                          _buildStatusChip('Responding (4)', Colors.orange),
                          _buildStatusChip('Off-Duty (2)', Colors.grey),
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
        Row(
          children: [
            Expanded(
              child: _buildStatCard('Active Units', '24', '+3 from last hour', Colors.green),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard('Avg Response Time', '4.2m', '-12% improvement', Colors.green),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Recent Activities',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildActivity('Unit-12', 'Responded to SOS', 'MG Road', '2 min ago'),
                _buildActivity('Unit-08', 'Traffic violation detected', 'Linking Road', '8 min ago'),
                _buildActivity('Unit-15', 'Completed patrol route', 'Zone A', '15 min ago'),
              ],
            ),
          ),
        ),
      ],
    );
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
          left: BorderSide(color: Colors.blue, width: 4),
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

// Alert Center Screen
class AlertCenterScreen extends StatelessWidget {
  const AlertCenterScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.error, color: Colors.red),
                        SizedBox(width: 8),
                        Text(
                          'Alert Center',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.red[100],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        '7 Active',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _buildAlert(
                  'SOS from Unit-12, Location: MG Road',
                  '2 min ago',
                  'critical',
                  Icons.error,
                ),
                _buildAlert(
                  'Evidence room access after hours detected',
                  '15 min ago',
                  'high',
                  Icons.error,
                ),
                _buildAlert(
                  'Patrol breach at Zone-C checkpoint',
                  '1 hour ago',
                  'medium',
                  Icons.error,
                ),
                _buildAlert(
                  'Vehicle speeding detected - MH-02-AB-1234',
                  '1 hour ago',
                  'low',
                  Icons.directions_car,
                ),
                _buildAlert(
                  'Officer overtime threshold exceeded - Badge 1234',
                  '2 hours ago',
                  'medium',
                  Icons.people,
                ),
              ],
            ),
          ),
        ),
      ],
    );
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

// Smart Roster Screen
class SmartRosterScreen extends StatelessWidget {
  const SmartRosterScreen({Key? key}) : super(key: key);

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
                              'Next Auto-Schedule Generation',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Tomorrow, 6:00 AM',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E40AF),
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Generate Now'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildMetricCard('Workload Balanced', '94%', Colors.green)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildMetricCard('Officers > 12hrs', '3', Colors.orange)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildMetricCard('Leave Requests', '12', Colors.blue)),
                  ],
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
                _buildShiftCard('Morning (6 AM - 2 PM)', 45, 'Active', true),
                _buildShiftCard('Afternoon (2 PM - 10 PM)', 52, 'Active', true),
                _buildShiftCard('Night (10 PM - 6 AM)', 38, 'Upcoming', false),
              ],
            ),
          ),
        ),
      ],
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

  Widget _buildShiftCard(String shift, int officers, String status, bool isActive) {
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
        ],
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

// Digital FIR Screen
class DigitalFIRScreen extends StatelessWidget {
  const DigitalFIRScreen({Key? key}) : super(key: key);

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
                      onPressed: () {},
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
                Row(
                  children: [
                    Expanded(child: _buildMetricCard('Total FIRs', '234', Colors.blue)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildMetricCard('This Month', '89', Colors.green)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildMetricCard('Pending', '12', Colors.orange)),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Recent FIRs',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildFIRCard('FIR-456/2024', 'Vehicle Theft', 'Andheri West', 'Under Investigation', '28 Dec 2024'),
                _buildFIRCard('FIR-455/2024', 'Robbery', 'Bandra', 'Evidence Collected', '27 Dec 2024'),
                _buildFIRCard('FIR-454/2024', 'Cyber Crime', 'Goregaon', 'Assigned', '27 Dec 2024'),
              ],
            ),
          ),
        ),
      ],
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

  Widget _buildFIRCard(String id, String type, String location, String status, String date) {
    return Container(
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
    );
  }
}

// Crime Analytics Screen
class CrimeAnalyticsScreen extends StatelessWidget {
  const CrimeAnalyticsScreen({Key? key}) : super(key: key);

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
                    Icon(Icons.bar_chart, color: Colors.purple),
                    SizedBox(width: 8),
                    Text(
                      'Crime Analytics Dashboard',
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
                  childAspectRatio: 1.3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  children: [
                    _buildAnalyticsCard('Total Cases', '234', '+12%'),
                    _buildAnalyticsCard('Resolved', '182', '+8%'),
                    _buildAnalyticsCard('Resolution Rate', '78%', '+5%'),
                    _buildAnalyticsCard('Avg Time', '8.5d', '-15%'),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Crime Distribution',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildProgressBar('Theft', 45, Colors.red),
                _buildProgressBar('Traffic Violations', 67, Colors.green),
                _buildProgressBar('Cyber Crime', 31, Colors.blue),
                _buildProgressBar('Assault', 23, Colors.orange),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsCard(String label, String value, String trend) {
    final isPositive = trend.startsWith('+') && !label.contains('Time');
    final isNegative = trend.startsWith('-') || (trend.startsWith('+') && label.contains('Time'));
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
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
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$trend from last month',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isNegative ? Colors.red : Colors.green,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(String label, int value, Color color) {
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
              value: value / 100,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}

// Communication Screen
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
                    Icon(Icons.message, color: Color(0xFF1E40AF)),
                    SizedBox(width: 8),
                    Text(
                      'Communication & Coordination',
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
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Column(
                          children: [
                            Text(
                              '24',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Units Online',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Column(
                          children: [
                            Text(
                              '8',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E40AF),
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Active Channels',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Active Channels',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildChannelCard('Zone-A Patrol', 12, 'Unit-08: Checkpoint clear', '1m ago'),
                _buildChannelCard('Traffic Control', 8, 'Unit-15: Diversion at Linking Road', '5m ago'),
                _buildChannelCard('Emergency Response', 15, 'Unit-12: En route to MG Road', '2m ago'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChannelCard(String name, int members, String lastMessage, String time) {
    return Container(
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
                name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.people, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    members.toString(),
                    style: const TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
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
    );
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
        ],
      ),
      drawer: _buildOfficerDrawer(),
      body: _getOfficerContent(),
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
                _buildDrawerItem(Icons.radio, 'Communication & Coordination (SOS)', 'communication'),
                _buildDrawerItem(Icons.description, 'Digital FIR', 'fir'),
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
        return const CommunicationSOSScreen();
      case 'fir':
        return const DigitalFIROfficerScreen();
      default:
        return const SmartBeatPatrolScreen();
    }
  }
}

// Smart Beat Patrol Screen
class SmartBeatPatrolScreen extends StatelessWidget {
  const SmartBeatPatrolScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const Row(
                  children: [
                    Icon(Icons.location_on, color: Color(0xFF1E40AF)),
                    SizedBox(width: 8),
                    Text(
                      'Smart Beat Patrol',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(24),
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
                      const Icon(Icons.location_on, size: 60, color: Color(0xFF1E40AF)),
                      const SizedBox(height: 16),
                      const Text(
                        'Current Route',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Zone A - Sector 3',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E40AF),
                        ),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.play_arrow),
                        label: const Text('Start Patrol'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1E40AF),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
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
}

// Operations Map Officer Screen
class OperationsMapOfficerScreen extends StatelessWidget {
  const OperationsMapOfficerScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const OperationsMapScreen();
  }
}

// Communication SOS Screen
class CommunicationSOSScreen extends StatelessWidget {
  const CommunicationSOSScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: Colors.red[50],
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Icon(Icons.emergency, size: 80, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Emergency SOS',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Send immediate alert to all units',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('SOS Alert Sent! Help is on the way.'),
                        backgroundColor: Colors.red,
                        duration: Duration(seconds: 3),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
                    minimumSize: const Size(200, 60),
                  ),
                  child: const Text(
                    'SEND SOS',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.message, color: Color(0xFF1E40AF)),
                    SizedBox(width: 8),
                    Text(
                      'Quick Communication',
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
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.radio, size: 32, color: Color(0xFF1E40AF)),
                            SizedBox(height: 8),
                            Text(
                              'Control Room',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.people, size: 32, color: Color(0xFF1E40AF)),
                            SizedBox(height: 8),
                            Text(
                              'My Team',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Active Channels',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                _buildOfficerChannelCard('Zone-A Patrol', 'Control: All units report status', '1m ago', true),
                _buildOfficerChannelCard('Traffic Control', 'Heavy traffic at Linking Road', '5m ago', false),
                _buildOfficerChannelCard('Emergency Response', 'Unit-12 needs backup at MG Road', '2m ago', true),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOfficerChannelCard(String name, String lastMessage, String time, bool isUrgent) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isUrgent ? Colors.orange[50] : Colors.white,
        border: Border.all(color: isUrgent ? Colors.orange[300]! : Colors.grey[300]!),
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
                        color: Colors.orange,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'URGENT',
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
    );
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