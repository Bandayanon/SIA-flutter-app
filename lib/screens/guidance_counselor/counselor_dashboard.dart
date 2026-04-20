import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../services/session_manager.dart';
import '../../widgets/counselor_sidebar.dart';

class CounselorDashboard extends StatefulWidget {
  const CounselorDashboard({super.key});

  @override
  State<CounselorDashboard> createState() => _CounselorDashboardState();
}

class _CounselorDashboardState extends State<CounselorDashboard> {
  final _session = SessionManager();
  String _timeFilter = 'today';
  bool _isLoading = true;
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.getDashboardStats(_timeFilter);
      if (data['status'] == 'success') {
        setState(() => _stats = data);
      }
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: CounselorSidebar(currentRoute: '/guidance-counselor/dashboard'),
      appBar: AppBar(
        title: const Text('Counselor Dashboard'),
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStats,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              _session.logout();
              context.go('/login');
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadStats,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      InkWell(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Profile picture settings coming soon!')),
                          );
                        },
                        borderRadius: BorderRadius.circular(30),
                        child: CircleAvatar(
                          radius: 30,
                          backgroundColor: AppTheme.primaryPurple.withOpacity(0.15),
                          child: const Icon(Icons.psychology, size: 30, color: AppTheme.primaryPurple),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome, ${_session.counselorFirstName ?? 'Counselor'}!',
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Monitor student assessments and review recommendations.',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Time filter
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'today', label: Text('Today')),
                  ButtonSegment(value: 'week',  label: Text('This Week')),
                  ButtonSegment(value: 'month', label: Text('This Month')),
                  ButtonSegment(value: 'all',   label: Text('All Time')),
                ],
                selected: {_timeFilter},
                onSelectionChanged: (s) {
                  setState(() => _timeFilter = s.first);
                  _loadStats();
                },
              ),
              const SizedBox(height: 24),

              if (_isLoading)
                const Center(child: CircularProgressIndicator())
              else ...[
                // Stat cards
                Row(
                  children: [
                    Expanded(child: _statCard(
                      context, 'Pending Approvals',
                      '${_stats['pendingCount'] ?? 0}',
                      Icons.pending_actions, AppTheme.warning,
                      () => context.go('/guidance-counselor/pending-approvals'),
                    )),
                    const SizedBox(width: 16),
                    Expanded(child: _statCard(
                      context, 'Total Students',
                      '${_stats['totalStudents'] ?? 0}',
                      Icons.people, AppTheme.info,
                      () => context.go('/guidance-counselor/student-records'),
                    )),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _statCard(
                      context, 'Assessments Today',
                      '${_stats['assessmentsToday'] ?? 0}',
                      Icons.assessment, AppTheme.success,
                      () => context.go('/guidance-counselor/monitoring'),
                    )),
                    const SizedBox(width: 16),
                    Expanded(child: _statCard(
                      context, 'Live Now',
                      '${_stats['inProgress'] ?? 0}',
                      Icons.sensors, AppTheme.primaryPurple,
                      () => context.go('/guidance-counselor/monitoring'),
                    )),
                  ],
                ),
                const SizedBox(height: 24),

                // Approval rate card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.analytics, color: AppTheme.primaryPurple),
                            const SizedBox(width: 8),
                            Text(
                              'Analytics Overview',
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(child: _analyticItem(
                              'Approval Rate',
                              '${_stats['approvalRate'] ?? 0}%',
                              AppTheme.success,
                              Icons.trending_up,
                            )),
                            const SizedBox(width: 16),
                            Expanded(child: _analyticItem(
                              'Feedback Given',
                              '${_stats['feedbackGiven'] ?? 0}',
                              AppTheme.primaryPurple,
                              Icons.feedback,
                            )),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _showAdminPinDialog(BuildContext context) {
    final TextEditingController _pinController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Admin Access'),
        content: TextField(
          controller: _pinController,
          obscureText: true,
          keyboardType: TextInputType.number,
          maxLength: 7,
          decoration: const InputDecoration(
            labelText: 'Enter 7-Digit PIN',
            counterText: '',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_pinController.text.trim() == '1234567') {
                Navigator.pop(ctx);
                context.push('/admin/dashboard');
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Invalid PIN')),
                );
              }
            },
            child: const Text('Verify'),
          ),
        ],
      ),
    );
  }

  Widget _statCard(BuildContext context, String label, String value,
      IconData icon, Color color, VoidCallback onTap) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 12),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _analyticItem(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}