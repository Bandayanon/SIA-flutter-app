import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../theme/app_theme.dart';
import '../../utils/api_config.dart';
import '../../services/session_manager.dart';

class AdminNotificationsTab extends StatefulWidget {
  const AdminNotificationsTab({super.key});

  @override
  State<AdminNotificationsTab> createState() => _AdminNotificationsTabState();
}

class _AdminNotificationsTabState extends State<AdminNotificationsTab> {
  final _session = SessionManager();
  List<_NotifItem> _notifications = [];
  bool _isLoading = true;
  Timer? _timer;

  // We'll build notifications by polling our existing endpoints and comparing state
  int _lastStudents    = 0;
  int _lastAssessments = 0;
  int _lastCounselors  = 0;

  @override
  void initState() {
    super.initState();
    _poll();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _poll());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _poll() async {
    try {
      final res = await http.get(Uri.parse('${ApiConfig.baseUrl}/get_admin_stats.php'));
      if (!mounted) return;
      final body = jsonDecode(res.body);
      final stats = body['stats'] as Map<String, dynamic>? ?? {};

      final students    = (stats['totalStudents']         ?? 0) as int;
      final assessments = (stats['completedAssessments']  ?? 0) as int;
      final counselors  = (stats['totalCounselors']       ?? 0) as int;

      if (!_isLoading) {
        final now = DateTime.now();
        if (students > _lastStudents) {
          _addNotif(_NotifItem(
            icon: Icons.person_add,
            color: AppTheme.info,
            title: 'New Student Registered',
            body: '${students - _lastStudents} new student account(s) have been created.',
            time: now,
          ));
        }
        if (assessments > _lastAssessments) {
          _addNotif(_NotifItem(
            icon: Icons.assignment_turned_in,
            color: AppTheme.success,
            title: 'Assessment Completed',
            body: '${assessments - _lastAssessments} assessment(s) have been submitted and are awaiting review.',
            time: now,
          ));
        }
        if (counselors > _lastCounselors) {
          _addNotif(_NotifItem(
            icon: Icons.psychology,
            color: AppTheme.primaryPurple,
            title: 'New Counselor Added',
            body: '${counselors - _lastCounselors} new counselor account(s) have been registered.',
            time: now,
          ));
        }
      }

      if (mounted) {
        setState(() {
          _lastStudents    = students;
          _lastAssessments = assessments;
          _lastCounselors  = counselors;
          _isLoading       = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _addNotif(_NotifItem item) {
    if (mounted) {
      setState(() => _notifications.insert(0, item));
    }
  }

  void _clearAll() {
    setState(() => _notifications.clear());
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('System Notifications', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Live feed of system activity. Refreshes every 10 seconds.', style: TextStyle(color: AppTheme.textSecondary)),
                ]),
              ),
              if (_notifications.isNotEmpty)
                TextButton.icon(
                  onPressed: _clearAll,
                  icon: const Icon(Icons.clear_all),
                  label: const Text('Clear All'),
                  style: TextButton.styleFrom(foregroundColor: AppTheme.error),
                ),
            ],
          ),
          const SizedBox(height: 8),

          // ── Live Activity Stats ─────────────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryPurple.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.primaryPurple.withOpacity(0.15)),
            ),
            child: Row(children: [
              const Icon(Icons.sensors, color: AppTheme.primaryPurple, size: 18),
              const SizedBox(width: 10),
              Text('Live System Pulse  —  ', style: TextStyle(color: AppTheme.primaryPurple, fontWeight: FontWeight.w600)),
              _statPill('Students', '$_lastStudents', AppTheme.info),
              const SizedBox(width: 8),
              _statPill('Completed', '$_lastAssessments', AppTheme.success),
              const SizedBox(width: 8),
              _statPill('Counselors', '$_lastCounselors', AppTheme.primaryPurple),
            ]),
          ),
          const SizedBox(height: 24),

          // ── Notification Feed ────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _notifications.isEmpty
                    ? _buildEmptyState()
                    : ListView.separated(
                        itemCount: _notifications.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (ctx, i) => _buildCard(_notifications[i]),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _statPill(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: Text('$label: $value', style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildCard(_NotifItem item) {
    final timeAgo = _formatTime(item.time);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: item.color.withOpacity(0.2)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: item.color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(item.icon, color: item.color, size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 3),
          Text(item.body, style: TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
        ])),
        const SizedBox(width: 12),
        Text(timeAgo, style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
      ]),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.notifications_none, size: 80, color: AppTheme.dividerColor),
        const SizedBox(height: 20),
        const Text('All clear!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text('No new system activity detected since you logged in.',
            style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
        const SizedBox(height: 4),
        Text('This feed pollinates every 10 seconds.',
            style: TextStyle(color: AppTheme.textSecondary.withOpacity(0.6), fontSize: 12)),
      ]),
    );
  }

  String _formatTime(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours   < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

class _NotifItem {
  final IconData icon;
  final Color color;
  final String title;
  final String body;
  final DateTime time;

  _NotifItem({required this.icon, required this.color, required this.title, required this.body, required this.time});
}
