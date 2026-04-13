import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../theme/app_theme.dart';
import '../../utils/api_config.dart';
import '../../services/session_manager.dart';

class AdminUserControlTab extends StatefulWidget {
  const AdminUserControlTab({super.key});

  @override
  State<AdminUserControlTab> createState() => _AdminUserControlTabState();
}

class _AdminUserControlTabState extends State<AdminUserControlTab> with SingleTickerProviderStateMixin {
  final _session = SessionManager();
  late TabController _tabController;

  List<dynamic> _admins     = [];
  List<dynamic> _counselors = [];
  bool _isLoading = true;
  String _searchQuery = '';

  bool get _isSuperAdmin => _session.adminRole == 'super_admin';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _isSuperAdmin ? 2 : 1, vsync: this);
    _fetchUsers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchUsers() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final res = await http.get(Uri.parse(
        '${ApiConfig.baseUrl}/admin_users_v2.php?adminId=${_session.adminId}&roleId=${_isSuperAdmin ? 4 : 3}',
      ));
      if (!mounted) return;
      final data = jsonDecode(res.body);
      if (data['status'] == 'success') {
        setState(() {
          _admins     = data['data']['admins'] ?? [];
          _counselors = data['data']['counselors'] ?? [];
          _isLoading  = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleBlock(int id, int currentStatus, String type) async {
    final newStatus = currentStatus == 1 ? 0 : 1;
    final label = newStatus == 1 ? 'block' : 'unblock';
    final confirmed = await _confirm('${label[0].toUpperCase()}${label.substring(1)} this account?',
        'The user will ${newStatus == 1 ? "no longer be able to log in." : "regain access to the system."}');
    if (!confirmed || !mounted) return;

    await http.post(
      Uri.parse('${ApiConfig.baseUrl}/admin_users_v2.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'action':     'toggle_block',
        'reqAdminId': _session.adminId,
        'reqRoleId':  _isSuperAdmin ? 4 : 3,
        'targetType': type,
        'targetId':   id,
        'isBlocked':  newStatus,
      }),
    );
    if (mounted) _fetchUsers();
  }

  Future<void> _deleteUser(int id, String name, String type) async {
    final confirmed = await _confirm('Delete "$name"?',
        'This action is permanent and cannot be undone.');
    if (!confirmed || !mounted) return;

    await http.post(
      Uri.parse('${ApiConfig.baseUrl}/admin_users_v2.php'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'action':     'delete',
        'reqAdminId': _session.adminId,
        'reqRoleId':  _isSuperAdmin ? 4 : 3,
        'targetType': type,
        'targetId':   id,
      }),
    );
    if (mounted) {
      _showSnack('Account deleted.', isError: false);
      _fetchUsers();
    }
  }

  Future<bool> _confirm(String title, String body) async {
    return await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            child: const Text('Confirm'),
          ),
        ],
      ),
    ) ?? false;
  }

  void _showSnack(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppTheme.error : AppTheme.success,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Header ───────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 32, 32, 0),
          child: Row(
            children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('User Control', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Manage, suspend, or remove system accounts.', style: TextStyle(color: AppTheme.textSecondary)),
                ]),
              ),
              SizedBox(
                width: 260,
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search by name or email…',
                    prefixIcon: const Icon(Icons.search),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
                ),
              ),
              const SizedBox(width: 12),
              IconButton.filled(
                tooltip: 'Refresh',
                onPressed: _fetchUsers,
                icon: const Icon(Icons.refresh),
                style: IconButton.styleFrom(backgroundColor: AppTheme.primaryPurple),
              ),
            ],
          ),
        ),

        // ── Tabs ─────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(32, 16, 32, 0),
          child: TabBar(
            controller: _tabController,
            labelColor: AppTheme.primaryPurple,
            unselectedLabelColor: AppTheme.textSecondary,
            indicatorColor: AppTheme.primaryPurple,
            tabs: [
              const Tab(text: 'Counselors', icon: Icon(Icons.psychology)),
              if (_isSuperAdmin), const Tab(text: 'Admins', icon: Icon(Icons.admin_panel_settings)),
            ],
          ),
        ),
        const Divider(height: 1),

        // ── Content ───────────────────────────────────────────
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildUserList(_counselors, 'counselor', Icons.psychology, AppTheme.info),
                    if (_isSuperAdmin)
                      _buildUserList(_admins, 'admin', Icons.admin_panel_settings, AppTheme.primaryPurple),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildUserList(List<dynamic> users, String type, IconData icon, Color color) {
    final filtered = users.where((u) {
      if (_searchQuery.isEmpty) return true;
      final name = '${u['firstName']} ${u['lastName']}'.toLowerCase();
      final email = (u['email'] ?? '').toLowerCase();
      return name.contains(_searchQuery) || email.contains(_searchQuery);
    }).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 64, color: AppTheme.dividerColor),
          const SizedBox(height: 16),
          Text('No accounts found.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
        ]),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(32),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final u = filtered[i];
        final isBlocked = (u['isBlocked'] ?? 0) == 1;
        final fullName = '${u['firstName']} ${u['lastName']}';
        final isSelf = u['id'] == _session.adminId;

        return Container(
          decoration: BoxDecoration(
            color: isBlocked ? AppTheme.error.withOpacity(0.04) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isBlocked ? AppTheme.error.withOpacity(0.2) : AppTheme.dividerColor,
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: color.withOpacity(0.1),
              child: Text(
                '${u['firstName'][0]}${u['lastName'][0]}'.toUpperCase(),
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
            ),
            title: Row(children: [
              Text(fullName, style: const TextStyle(fontWeight: FontWeight.bold)),
              if (isSelf) ...[
                const SizedBox(width: 8),
                Chip(
                  label: const Text('You', style: TextStyle(fontSize: 11)),
                  backgroundColor: AppTheme.primaryYellow.withOpacity(0.3),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
              if (isBlocked) ...[
                const SizedBox(width: 8),
                const Chip(
                  label: Text('Blocked', style: TextStyle(fontSize: 11, color: AppTheme.error)),
                  backgroundColor: Color(0xFFFFEBEB),
                  padding: EdgeInsets.zero,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ]),
            subtitle: Text(u['email'] ?? '', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
            trailing: isSelf
                ? null
                : Row(mainAxisSize: MainAxisSize.min, children: [
                    IconButton(
                      tooltip: isBlocked ? 'Unblock' : 'Block',
                      icon: Icon(isBlocked ? Icons.lock_open : Icons.block,
                          color: isBlocked ? AppTheme.success : AppTheme.warning),
                      onPressed: () => _toggleBlock(u['id'], isBlocked ? 1 : 0, type),
                    ),
                    IconButton(
                      tooltip: 'Delete',
                      icon: const Icon(Icons.delete_outline, color: AppTheme.error),
                      onPressed: () => _deleteUser(u['id'], fullName, type),
                    ),
                  ]),
          ),
        );
      },
    );
  }
}
