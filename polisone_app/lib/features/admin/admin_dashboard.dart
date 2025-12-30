import 'digital_fir_screen.dart';
import 'smart_roster_screen.dart';
import 'communication_screen.dart';
import 'incident_dashboard_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DashboardHomeScreen(),
    const DigitalFIRScreen(),
    const SmartRosterScreen(),
    const CommunicationScreen(),
    IncidentDashboardScreen(firestore: FirebaseFirestore.instance), 
  ];

  final List<String> _titles = [
    'Dashboard',
    'Digital FIR',
    'Smart Roster',
    'Communications',
    'Incident Reports',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        backgroundColor: const Color(0xFF1E40AF),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1E40AF), Color(0xFF7C3AED)],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.shield, size: 48, color: Colors.white),
                  SizedBox(height: 8),
                  Text(
                    'PolisOne Admin',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Dashboard'),
              selected: _selectedIndex == 0,
              onTap: () {
                setState(() => _selectedIndex = 0);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.description),
              title: const Text('Digital FIR'),
              selected: _selectedIndex == 1,
              onTap: () {
                setState(() => _selectedIndex = 1);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: const Text('Smart Roster'),
              selected: _selectedIndex == 2,
              onTap: () {
                setState(() => _selectedIndex = 2);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.chat),
              title: const Text('Communications'),
              selected: _selectedIndex == 3,
              onTap: () {
                setState(() => _selectedIndex = 3);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.report_problem),
              title: const Text('Incident Reports'),
              selected: _selectedIndex == 4,
              onTap: () {
                setState(() => _selectedIndex = 4);
                Navigator.pop(context);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ],
        ),
      ),
      body: _screens[_selectedIndex],
    );
  }
}

class DashboardHomeScreen extends StatelessWidget {
  const DashboardHomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.count(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: [
          _buildDashboardCard(
            'Digital FIR',
            Icons.description,
            Colors.blue,
            'Manage incident reports',
            () => Navigator.pushNamed(context, '/admin'),
          ),
          _buildDashboardCard(
            'Smart Roster',
            Icons.calendar_today,
            Colors.green,
            'Schedule shifts',
            () => Navigator.pushNamed(context, '/admin'),
          ),
          _buildDashboardCard(
            'Communications',
            Icons.chat,
            Colors.orange,
            'Team messaging',
            () => Navigator.pushNamed(context, '/admin'),
          ),
          _buildDashboardCard(
            'Incident Reports',
            Icons.report_problem,
            Colors.red,
            'View field reports',
            () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please use the Side Menu (Drawer) to access Incident Reports')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardCard(
    String title,
    IconData icon,
    Color color,
    String subtitle,
    VoidCallback onTap,
  ) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 48, color: color),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
