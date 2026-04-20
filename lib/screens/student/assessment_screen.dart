import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../services/api_service.dart';
import '../../services/session_manager.dart';
import '../../theme/app_theme.dart';
import '../../widgets/student_sidebar.dart';

class AssessmentScreen extends StatefulWidget {
  const AssessmentScreen({super.key});

  @override
  State<AssessmentScreen> createState() => _AssessmentScreenState();
}

class _AssessmentScreenState extends State<AssessmentScreen> {
  final _session = SessionManager();
  int _currentIndex = 0;
  // answers: questionId -> score (1-5)
  final Map<int, int> _answers = {};
  List<Map<String, dynamic>> _questions = [];
  bool _isLoading = true;
  bool _isSubmitting = false;
  DateTime? _startTime;

  // Score labels
  final List<Map<String, dynamic>> _scoreOptions = [
    {'label': 'Strongly Disagree', 'value': 1},
    {'label': 'Disagree',          'value': 2},
    {'label': 'Neutral',           'value': 3},
    {'label': 'Agree',             'value': 4},
    {'label': 'Strongly Agree',    'value': 5},
  ];

  @override
  void initState() {
    super.initState();
    _startTime = DateTime.now();
    _loadQuestions();
    _restoreProgress();
  }

  void _restoreProgress() {
    final storage = html.window.localStorage;
    final savedAnswers = storage['riasec_answers'];
    final savedIndex = storage['riasec_currentIndex'];

    if (savedAnswers != null) {
      final Map<String, dynamic> decoded = jsonDecode(savedAnswers);
      setState(() {
        decoded.forEach((key, value) {
          _answers[int.parse(key)] = value;
        });
      });
    }

    if (savedIndex != null) {
      setState(() {
        _currentIndex = int.tryParse(savedIndex) ?? 0;
      });
    }
  }

  void _saveProgress() {
    final storage = html.window.localStorage;
    final Map<String, int> encoded = {};
    _answers.forEach((key, value) => encoded[key.toString()] = value);
    storage['riasec_answers'] = jsonEncode(encoded);
    storage['riasec_currentIndex'] = _currentIndex.toString();
  }

  Future<void> _loadQuestions() async {
    try {
      final data = await ApiService.getQuestions();
      if (data['status'] == 'success') {
        setState(() {
          _questions = List<Map<String, dynamic>>.from(data['questions']);
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load questions. Please try again.')),
        );
      }
    }
  }

  Future<void> _updateLiveSession() async {
    if (_session.currentAssessmentId == null) return;
    final duration = DateTime.now().difference(_startTime!).inSeconds;
    await ApiService.updateLiveSession(
      _session.currentAssessmentId!,
      _currentIndex + 1,
      duration,
    );
  }

  void _selectScore(int score) {
    final questionId = int.tryParse(_questions[_currentIndex]['id'].toString()) ?? 0;
    setState(() => _answers[questionId] = score);
    _saveProgress();
  }

  void _next() {
    final questionId = int.tryParse(_questions[_currentIndex]['id'].toString()) ?? 0;
    if (!_answers.containsKey(questionId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an answer before continuing.')),
      );
      return;
    }
    if (_currentIndex < _questions.length - 1) {
      setState(() => _currentIndex++);
      _updateLiveSession();
    } else {
      _confirmSubmit();
    }
  }

  void _previous() {
    if (_currentIndex > 0) setState(() => _currentIndex--);
  }

  void _confirmSubmit() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Submit Assessment'),
        content: const Text(
          'Are you sure you want to submit? You cannot change your answers after submission.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Review Answers'),
          ),
          ElevatedButton(
            onPressed: _isSubmitting
                ? null
                : () {
                    Navigator.pop(ctx);
                    _submitAssessment();
                  },
            child: _isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Submit'),
          ),
        ],
      ),
    );
  }

  Future<void> _submitAssessment() async {
    if (_session.currentAssessmentId == null) return;
    setState(() => _isSubmitting = true);

    final answerList = _answers.entries
        .map((e) => {'questionId': e.key, 'score': e.value})
        .toList();

    try {
      final data = await ApiService.submitAssessment(
        _session.currentAssessmentId!,
        answerList,
      );

      if (data['status'] == 'success') {
        _session.currentResultId = int.tryParse(data['resultId'].toString());
        if (mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (ctx) => AlertDialog(
              icon: Icon(Icons.check_circle, color: AppTheme.success, size: 48),
              title: const Text('Assessment Submitted!'),
              content: const Text(
                'Your assessment has been submitted and is now pending review by your guidance counselor. '
                'You will be notified once results are available.',
                textAlign: TextAlign.center,
              ),
              actions: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    html.window.localStorage.remove('riasec_answers');
                    html.window.localStorage.remove('riasec_currentIndex');
                    context.go('/student/dashboard');
                  },
                  child: const Text('Return to Dashboard'),
                ),
              ],
            ),
          );
        }
      } else {
        throw Exception(data['message']);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Submission failed: $e')),
        );
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  Color _getScoreColor(int value) {
    switch (value) {
      case 1: return AppTheme.error;
      case 2: return AppTheme.warning;
      case 3: return AppTheme.textSecondary;
      case 4: return AppTheme.success;
      case 5: return AppTheme.primaryPurple;
      default: return AppTheme.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('RIASEC Assessment')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('RIASEC Assessment')),
        body: const Center(child: Text('No questions available.')),
      );
    }

    final current = _questions[_currentIndex];
    final questionId = int.tryParse(current['id'].toString()) ?? 0;
    final progress = (_currentIndex + 1) / _questions.length;
    final selectedScore = _answers[questionId];

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        _showExitDialog();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('RIASEC Assessment'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => _showExitDialog(),
          ),
        ),
      body: Column(
        children: [
          // Progress
          Container(
            padding: const EdgeInsets.all(16),
            color: AppTheme.backgroundWhite,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Question ${_currentIndex + 1} of ${_questions.length}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryPurple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${(progress * 100).toInt()}%',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryPurple,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),

          // Question + Options
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Text(
                    current['question'],
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Score options
                  ..._scoreOptions.map((option) {
                    final value = int.tryParse(option['value'].toString()) ?? 0;
                    final isSelected = selectedScore == value;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: GestureDetector(
                        onTap: () => _selectScore(value),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? _getScoreColor(value).withOpacity(0.1)
                                : AppTheme.backgroundWhite,
                            border: Border.all(
                              color: isSelected
                                  ? _getScoreColor(value)
                                  : AppTheme.dividerColor,
                              width: isSelected ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? _getScoreColor(value)
                                      : AppTheme.dividerColor,
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    '$value',
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : AppTheme.textSecondary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Text(
                                option['label'],
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                  color: isSelected
                                      ? _getScoreColor(value)
                                      : AppTheme.textPrimary,
                                ),
                              ),
                              if (isSelected) ...[
                                const Spacer(),
                                Icon(Icons.check_circle, color: _getScoreColor(value)),
                              ]
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),

          // Navigation
          Container(
            padding: const EdgeInsets.all(16),
            color: AppTheme.backgroundWhite,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (_currentIndex > 0)
                  OutlinedButton.icon(
                    onPressed: _previous,
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Previous'),
                  )
                else
                  const SizedBox(),
                _isSubmitting
                    ? const CircularProgressIndicator()
                    : ElevatedButton.icon(
                        onPressed: _next,
                        icon: Icon(
                          _currentIndex == _questions.length - 1
                              ? Icons.check
                              : Icons.arrow_forward,
                        ),
                        label: Text(
                          _currentIndex == _questions.length - 1 ? 'Submit' : 'Next',
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    ),
    );
  }

  void _showExitDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Leave Assessment?'),
        content: const Text(
          'Your progress will be lost if you leave. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Stay'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() => _isLoading = true);
              try {
                if (_session.currentAssessmentId != null) {
                  await ApiService.cancelAssessment(_session.currentAssessmentId!);
                  _session.currentAssessmentId = null;
                }
                // Clear local progress
                html.window.localStorage.remove('riasec_answers');
                html.window.localStorage.remove('riasec_currentIndex');
              } catch (_) {}
              
              if (mounted) {
                context.go('/student/dashboard');
              }
            },
            child: const Text('Leave & Cancel'),
          ),
        ],
      ),
    );
  }
}