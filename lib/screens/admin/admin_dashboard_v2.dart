import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../services/session_manager.dart';
import 'admin_monitoring.dart';
import 'admin_registration_tab.dart';
import 'admin_user_control_tab.dart';
import 'admin_archive_tab.dart';
import 'admin_notifications_tab.dart';

class AdminDashboardV2 extends StatefulWidget {
  const AdminDashboardV2({super.key});

  @override
  State<AdminDashboardV2> createState() => _AdminDashboardV2State();
}

class _AdminDashboardV2State extends State<AdminDashboardV2> {
  int _selectedIndex = 0;
  final _session = SessionManager();

  static const _navItems = [
    _NavItem(Icons.dashboard_outlined,       Icons.dashboard,          'Monitoring'),
    _NavItem(Icons.person_add_outlined,      Icons.person_add,         'Registration'),
    _NavItem(Icons.manage_accounts_outlined, Icons.manage_accounts,    'User Control'),
    _NavItem(Icons.archive_outlined,         Icons.archive,            'Archiving'),
    _NavItem(Icons.notifications_outlined,   Icons.notifications,      'Notifications'),
  ];

  @override
  Widget build(BuildContext context) {
    final firstName  = _session.adminFirstName ?? 'Admin';
    final isSuperAdmin = _session.adminRole == 'super_admin';

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      body: Row(
        children: [
          // ── Sidebar ───────────────────────────────────────
          Container(
            width: 220,
            decoration: const BoxDecoration(
              color: AppTheme.primaryPurple,
              boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Logo / Brand ─────────────────────────────
                Container(
                  padding: const EdgeInsets.fromLTRB(20, 40, 20, 24),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.15))),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.shield, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 10),
                      const Text('Citadel',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
                    ]),
                    const SizedBox(height: 6),
                    Text('Administration Panel',
                        style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11, letterSpacing: 0.5)),
                  ]),
                ),

                // ── Nav Items ────────────────────────────────
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Column(
                      children: List.generate(_navItems.length, (i) {
                        final item = _navItems[i];
                        final isSelected = _selectedIndex == i;
                        return _buildNavTile(
                          icon: isSelected ? item.activeIcon : item.icon,
                          label: item.label,
                          isSelected: isSelected,
                          onTap: () => setState(() => _selectedIndex = i),
                        );
                      }),
                    ),
                  ),
                ),

                // ── User info + logout ────────────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(top: BorderSide(color: Colors.white.withOpacity(0.15))),
                  ),
                  child: Row(children: [
                    CircleAvatar(
                      backgroundColor: Colors.white.withOpacity(0.2),
                      radius: 18,
                      child: Text(
                        firstName[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(firstName,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                            overflow: TextOverflow.ellipsis),
                        Text(isSuperAdmin ? 'Super Admin' : 'Admin',
                            style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 11)),
                      ]),
                    ),
                    IconButton(
                      icon: const Icon(Icons.logout, color: Colors.white70, size: 18),
                      tooltip: 'Logout',
                      onPressed: () {
                        _session.logout();
                        context.go('/login');
                      },
                    ),
                  ]),
                ),
              ],
            ),
          ),

          // ── Main content ──────────────────────────────────
          Expanded(
            child: Column(
              children: [
                // ── Top bar ────────────────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  color: Colors.white,
                  child: Row(
                    children: [
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(_navItems[_selectedIndex].label,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                        Text('RIASEC Career Assessment System  •  Administration',
                            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                      ]),
                      const Spacer(),
                      if (isSuperAdmin)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryYellow.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppTheme.primaryYellow.withOpacity(0.4)),
                          ),
                          child: Row(children: [
                            const Icon(Icons.star, color: AppTheme.primaryYellow, size: 14),
                            const SizedBox(width: 4),
                            Text('Super Admin', style: TextStyle(color: Colors.amber.shade800, fontSize: 12, fontWeight: FontWeight.bold)),
                          ]),
                        ),
                    ],
                  ),
                ),
                const Divider(height: 1),

                // ── Page content ───────────────────────────
                Expanded(
                  child: IndexedStack(
                    index: _selectedIndex,
                    children: const [
                      AdminMonitoring(),
                      AdminRegistrationTab(),
                      AdminUserControlTab(),
                      AdminArchiveTab(),
                      AdminNotificationsTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavTile({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: isSelected ? Colors.white.withOpacity(0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(children: [
              Icon(icon, color: isSelected ? Colors.white : Colors.white60, size: 20),
              const SizedBox(width: 12),
              Text(label,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.white60,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    fontSize: 14,
                  )),
              if (isSelected) ...[
                const Spacer(),
                Container(width: 4, height: 4, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
              ],
            ]),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const _NavItem(this.icon, this.activeIcon, this.label);
}
