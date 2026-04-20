import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../services/api_service.dart';
import '../../services/session_manager.dart';
import '../../theme/app_theme.dart';
import '../../widgets/student_sidebar.dart';

class StudentDashboard extends StatefulWidget {
  const StudentDashboard({super.key});

  @override
  State<StudentDashboard> createState() => _StudentDashboardState();
}

class _StudentDashboardState extends State<StudentDashboard> {
  final _session = SessionManager();
  String? _assessmentStatus; // null = no assessment, 'pending_review', 'approved', 'rejected'
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkAssessmentStatus();
  }

  Future<void> _checkAssessmentStatus() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.getStudentStatus(_session.studentId!);
      if (data['status'] == 'success') {
        setState(() {
          _assessmentStatus = data['assessmentStatus'];
          _session.assessmentStatus = _assessmentStatus; // Save globally
          if (data['assessmentId'] != null) {
            _session.currentAssessmentId = int.tryParse(data['assessmentId'].toString());
          }
        });
      }
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  String get _buttonLabel {
    switch (_assessmentStatus) {
      case 'in_progress':
        return 'Resume Assessment';
      case 'pending_review':
        return 'Awaiting Counselor Review...';
      case 'approved':
        return 'Assessment Completed';
      case 'rejected':
        return 'Retake Assessment';
      default:
        return 'Start RIASEC Test';
    }
  }

  bool get _buttonEnabled {
    return _assessmentStatus == null || 
           _assessmentStatus == 'rejected' || 
           _assessmentStatus == 'in_progress';
  }

  IconData get _buttonIcon {
    switch (_assessmentStatus) {
      case 'in_progress':
        return Icons.play_circle_fill;
      case 'pending_review':
        return Icons.hourglass_empty;
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.refresh;
      default:
        return Icons.quiz;
    }
  }

  Color get _buttonColor {
    switch (_assessmentStatus) {
      case 'in_progress':
        return AppTheme.primaryPurple;
      case 'pending_review':
        return Colors.grey;
      case 'approved':
        return AppTheme.success;
      case 'rejected':
        return AppTheme.warning;
      default:
        return AppTheme.primaryYellow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: StudentSidebar(currentRoute: '/student/dashboard'),
      appBar: AppBar(
        title: const Text('Student Portal'),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () {
              _session.logout();
              context.go('/login');
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              color: AppTheme.backgroundLight,
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _assessmentStatus == 'approved'
                            ? 'Assessment Complete!'
                            : _assessmentStatus == 'pending_review'
                                ? 'Assessment Under Review'
                                    : _assessmentStatus == 'rejected'
                                        ? 'Your assessment needs a retake'
                                        : 'Start your Course Assessment today!',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.displayMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryPurple,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        _assessmentStatus == 'approved'
                            ? 'Your results have been approved. Check your results in the sidebar.'
                            : _assessmentStatus == 'pending_review'
                                ? 'Your guidance counselor is reviewing your assessment. Please wait.'
                                    : _assessmentStatus == 'rejected'
                                        ? 'Your counselor has requested you to retake the assessment.'
                                    : 'Kickstart your journey by taking our Course Assessment to discover the best course path for you today!',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: AppTheme.textSecondary,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 48),
                      SizedBox(
                        width: 300,
                        height: 60,
                        child: ElevatedButton(
                          onPressed: _buttonEnabled
                              ? () {
                                  if (_assessmentStatus == 'in_progress') {
                                    context.go('/student/assessment');
                                  } else {
                                    context.go('/student/student-details');
                                  }
                                }
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _buttonEnabled ? _buttonColor : Colors.grey.shade300,
                            foregroundColor: AppTheme.primaryPurple,
                            elevation: _buttonEnabled ? 4 : 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(_buttonIcon, size: 24, color: _buttonEnabled ? AppTheme.primaryPurple : Colors.grey),
                              const SizedBox(width: 12),
                              Flexible(
                                child: Text(
                                  _buttonLabel,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: _buttonEnabled ? AppTheme.primaryPurple : Colors.grey,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_assessmentStatus == 'approved') ...[
                        const SizedBox(height: 16),
                        TextButton.icon(
                          onPressed: () => context.go('/student/results'),
                          icon: Icon(Icons.assessment, color: AppTheme.primaryPurple),
                          label: Text('View My Results', style: TextStyle(color: AppTheme.primaryPurple)),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}