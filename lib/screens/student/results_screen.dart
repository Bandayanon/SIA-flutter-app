import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../services/api_service.dart';
import '../../services/session_manager.dart';
import '../../theme/app_theme.dart';
import '../../widgets/student_sidebar.dart';

class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  final _session = SessionManager();
  bool _isLoading = true;
  Map<String, dynamic>? _resultsData;
  String? _error;
  String? _assessmentStatus;

  @override
  void initState() {
    super.initState();
    _loadResults();
  }

  Future<void> _loadResults() async {
    setState(() => _isLoading = true);
    try {
      Map<String, dynamic> data;
      // Try by assessmentId first, fall back to studentId
      if (_session.currentAssessmentId != null) {
        data = await ApiService.getResults(_session.currentAssessmentId!);
      } else if (_session.studentId != null) {
        data = await ApiService.getResultsByStudentId(_session.studentId!);
      } else {
        setState(() { _error = 'No assessment found.'; _isLoading = false; });
        return;
      }

      if (data['status'] == 'success') {
        final asmStatus = data['assessmentStatus'] as String?;
        setState(() {
          _assessmentStatus = asmStatus;
          if (asmStatus == 'approved' || asmStatus == 'rejected') {
            _resultsData = data;
          }
          _isLoading = false;
        });
      } else {
        setState(() { _error = data['message']; _isLoading = false; });
      }
    } catch (e) {
      setState(() { _error = 'Failed to load results.'; _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: StudentSidebar(currentRoute: '/student/results'),
      appBar: AppBar(
        title: const Text('Assessment Results'),
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () => context.go('/student/dashboard'),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : _assessmentStatus == 'pending_review'
                  ? _buildPendingView()
                  : _resultsData == null
                      ? _buildNoAssessmentView()
                      : _buildResults(),
    );
  }

  Widget _buildNoAssessmentView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assessment_outlined, size: 64, color: AppTheme.textSecondary),
          const SizedBox(height: 16),
          Text('No Results Yet', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AppTheme.textSecondary)),
          const SizedBox(height: 8),
          Text('Complete your assessment to view results here.', style: TextStyle(color: AppTheme.textSecondary)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => context.go('/student/dashboard'),
            child: const Text('Go to Dashboard'),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.hourglass_top, size: 80, color: AppTheme.warning),
            const SizedBox(height: 24),
            Text(
              'Awaiting Counselor Review',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Your assessment has been submitted and is currently being reviewed by your guidance counselor. You will be able to view your results once they have been approved or rejected.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.warning, height: 1.5),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/student/dashboard'),
              child: const Text('Return to Dashboard'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResults() {
    final scores    = _resultsData!['scores'] as Map<String, dynamic>;
    final primary   = _resultsData!['primaryType'] as String;
    final secondary = _resultsData!['secondaryType'] as String;
    final tertiary  = _resultsData!['tertiaryType'] as String;
    final recs      = _resultsData!['recommendations'] as List<dynamic>;
    final status    = _resultsData!['assessmentStatus'] as String;

    final sortedScores = scores.entries.toList()
      ..sort((a, b) {
        final aVal = double.tryParse(a.value['percentage'].toString()) ?? 0.0;
        final bVal = double.tryParse(b.value['percentage'].toString()) ?? 0.0;
        return bVal.compareTo(aVal);
      });

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Icon(
                    status == 'rejected' ? Icons.cancel : Icons.celebration,
                    size: 64,
                    color: status == 'rejected' ? const Color(0xFFE53E3E) : AppTheme.success,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    status == 'rejected' ? 'Assessment Rejected' : 'Assessment Approved!',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: status == 'approved'
                          ? AppTheme.success.withOpacity(0.1)
                          : const Color(0xFFE53E3E).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      status == 'approved'
                          ? 'Your results have been approved by your counselor.'
                          : 'Your counselor has rejected this assessment. Please retake it.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: status == 'approved' ? AppTheme.success : const Color(0xFFE53E3E),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('Your Interest Profile',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _typeChip(primary, rank: 1),
                      const Padding(padding: EdgeInsets.symmetric(horizontal: 6),
                        child: Text('+', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                      _typeChip(secondary, rank: 2),
                      const Padding(padding: EdgeInsets.symmetric(horizontal: 6),
                        child: Text('+', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                      _typeChip(tertiary, rank: 3),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text('Your RIASEC Scores',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ...sortedScores.map((entry) {
            final type = entry.key;
            final percentage = double.tryParse(entry.value['percentage'].toString()) ?? 0.0;
            return _scoreCard(context, type, percentage);
          }),
          const SizedBox(height: 24),
          if (recs.isNotEmpty) ...[
            Text('Recommended Courses',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...recs.asMap().entries.map((entry) =>
              _courseCard(context, entry.key + 1, entry.value as Map<String, dynamic>)),
            const SizedBox(height: 24),
          ],
          if (status == 'rejected') ...[
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.go('/student/dashboard'),
                icon: const Icon(Icons.refresh),
                label: const Text('Retake Assessment'),
                style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryPurple),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _typeChip(String type, {required int rank}) {
    final color = AppTheme.riasecColor(type);
    return Column(
      children: [
        Text(rank == 1 ? '1st' : rank == 2 ? '2nd' : '3rd',
          style: TextStyle(fontSize: 10, color: AppTheme.textSecondary)),
        const SizedBox(height: 4),
        Chip(
          label: Text('$type - ${AppTheme.riasecName(type)}',
            style: TextStyle(fontWeight: rank == 1 ? FontWeight.bold : FontWeight.normal, fontSize: 12)),
          backgroundColor: color.withOpacity(0.15),
          labelStyle: TextStyle(color: color),
          avatar: CircleAvatar(
            backgroundColor: color,
            child: Text(type, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _scoreCard(BuildContext context, String type, double percentage) {
    final color = AppTheme.riasecColor(type);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  CircleAvatar(
                    backgroundColor: color.withOpacity(0.15),
                    child: Text(type, style: TextStyle(color: color, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(AppTheme.riasecName(type), style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(AppTheme.riasecDescriptor(type),
                      style: TextStyle(fontSize: 12, color: AppTheme.textSecondary)),
                  ]),
                ]),
                Text('${percentage.toStringAsFixed(1)}%',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: color)),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: percentage / 100,
                minHeight: 10,
                backgroundColor: AppTheme.dividerColor,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _courseCard(BuildContext context, int rank, Map<String, dynamic> rec) {
    final type  = rec['RIASECCategory'] as String;
    final color = AppTheme.riasecColor(type);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryPurple.withOpacity(0.1),
          child: Text('$rank',
            style: const TextStyle(color: AppTheme.primaryPurple, fontWeight: FontWeight.bold)),
        ),
        title: Text(rec['CourseName'] as String,
          style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Chip(
          label: Text('${rec['CourseCode']} • ${AppTheme.riasecName(type)}',
            style: const TextStyle(fontSize: 11)),
          backgroundColor: color.withOpacity(0.1),
          labelStyle: TextStyle(color: color),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(rec['Explanation'] ?? '',
              style: TextStyle(color: AppTheme.textSecondary)),
          ),
        ],
      ),
    );
  }
}