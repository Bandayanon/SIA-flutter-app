import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'package:go_router/go_router.dart';
import 'admin_monitoring.dart';
// Note: These tabs will be fully flushed out in the subsequent commit, 
// for now we set up the core structure of Citadel V2.
// import 'admin_registration_v2.dart';
// import 'admin_user_manage_v2.dart';
// import 'admin_archive_v2.dart';
// import 'admin_notifications.dart';

class AdminDashboardV2 extends StatefulWidget {
  const AdminDashboardV2({super.key});

  @override
  State<AdminDashboardV2> createState() => _AdminDashboardV2State();
}

class _AdminDashboardV2State extends State<AdminDashboardV2> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Citadel Command Center (V2)', style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.error)),
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.logout, color: AppTheme.error),
          onPressed: () {
            // Log out
            context.go('/login');
          },
        ),
      ),
      body: Row(
        children: [
          Container(
            color: const Color(0xFF1E1E2C), // Dark secure background
            width: 200,
            child: NavigationRail(
              backgroundColor: Colors.transparent,
              extended: true,
              selectedIndex: _selectedIndex,
              onDestinationSelected: (int index) {
                setState(() => _selectedIndex = index);
              },
              unselectedIconTheme: const IconThemeData(color: Colors.white54),
              selectedIconTheme: const IconThemeData(color: Colors.white, size: 28),
              unselectedLabelTextStyle: const TextStyle(color: Colors.white54),
              selectedLabelTextStyle: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              destinations: const [
                NavigationRailDestination(icon: Icon(Icons.dashboard), label: Text('Monitoring')),
                NavigationRailDestination(icon: Icon(Icons.person_add), label: Text('Registration')),
                NavigationRailDestination(icon: Icon(Icons.manage_accounts), label: Text('User Control')),
                NavigationRailDestination(icon: Icon(Icons.archive), label: Text('Archiving')),
                NavigationRailDestination(icon: Icon(Icons.notifications), label: Text('Notifications')),
              ],
            ),
          ),
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: [
                const AdminMonitoring(), // Re-using our previous live monitor
                _buildPlaceholder('Registration System', 'Create new students, counselors, and admins.'),
                _buildPlaceholder('User Control', 'Manage, block, and delete existing accounts.'),
                _buildPlaceholder('Data Archiving', 'Download and invalidate system records (.csv export).'),
                _buildPlaceholder('System Notifications', 'Live feed of system modifications and tasks.'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.construction, size: 80, color: AppTheme.error.withOpacity(0.5)),
          const SizedBox(height: 24),
          Text(title, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
          const SizedBox(height: 12),
          Text(subtitle, style: const TextStyle(fontSize: 18, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }
}
