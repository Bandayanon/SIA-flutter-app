import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../services/api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/counselor_sidebar.dart';

class StudentRecordsScreen extends StatefulWidget {
  const StudentRecordsScreen({super.key});

  @override
  State<StudentRecordsScreen> createState() => _StudentRecordsScreenState();
}

class _StudentRecordsScreenState extends State<StudentRecordsScreen> {
  List<Map<String, dynamic>> _records = [];
  bool _isLoading = true;

  // Filters
  String _status       = 'all';
  String _gradeLevel   = 'all';
  String _strand       = 'all';
  String _dominantType = 'all';
  String _dateFrom     = '';
  String _dateTo       = '';
  String _search       = '';

  final _searchController = TextEditingController();

  final _statusOptions = {
    'all': 'All Statuses',
    'approved': 'Approved',
    'pending_review': 'Pending Review',
    'declined': 'Declined',
  };

  final _gradeLevelOptions = {
    'all': 'All Grade Levels',
    'Grade 11': 'Grade 11',
    'Grade 12': 'Grade 12',
  };

  final _strandOptions = {
    'all': 'All Strands',
    'STEM': 'STEM',
    'ABM': 'ABM',
    'HUMSS': 'HUMSS',
    'GAS': 'GAS',
    'TVL': 'TVL',
    'ICT': 'ICT',
    'Arts and Design': 'Arts & Design',
  };

  final _typeOptions = {
    'all': 'All RIASEC Types',
    'R': 'R - Realistic',
    'I': 'I - Investigative',
    'A': 'A - Artistic',
    'S': 'S - Social',
    'E': 'E - Enterprising',
    'C': 'C - Conventional',
  };

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRecords() async {
    setState(() => _isLoading = true);
    try {
      final data = await ApiService.getStudentRecords(
        status: _status,
        gradeLevel: _gradeLevel,
        strand: _strand,
        dominantType: _dominantType,
        dateFrom: _dateFrom,
        dateTo: _dateTo,
        search: _search,
      );
      if (data['status'] == 'success') {
        setState(() => _records = List<Map<String, dynamic>>.from(data['records']));
      }
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  void _resetFilters() {
    setState(() {
      _status       = 'all';
      _gradeLevel   = 'all';
      _strand       = 'all';
      _dominantType = 'all';
      _dateFrom     = '';
      _dateTo       = '';
      _search       = '';
      _searchController.clear();
    });
    _loadRecords();
  }

  String _generateCsv() {
    final header = [
      'Assessment ID', 'Student ID', 'Student Name', 'Grade Level',
      'Strand', 'Gender', 'Age', 'Submitted At', 'Status',
      'Primary Type', 'Secondary Type', 'Tertiary Type',
      'R%', 'I%', 'A%', 'S%', 'E%', 'C%',
      'Counselor Action', 'Feedback Notes', 'Reviewed At'
    ].join(',');

    final rows = _records.map((r) {
      final scores = r['scores'] as Map<String, dynamic>;
      return [
        r['assessmentId'],
        r['studentId'],
        '"${r['studentName']}"',
        r['gradeLevel'],
        '"${r['strand']}"',
        r['gender'],
        r['age'],
        r['submittedAt'] ?? '',
        r['status'],
        r['primaryType'] ?? '',
        r['secondaryType'] ?? '',
        r['tertiaryType'] ?? '',
        scores['R'] ?? 0,
        scores['I'] ?? 0,
        scores['A'] ?? 0,
        scores['S'] ?? 0,
        scores['E'] ?? 0,
        scores['C'] ?? 0,
        r['counselorAction'] ?? '',
        '"${(r['feedbackNotes'] ?? '').toString().replaceAll('"', '""')}"',
        r['reviewedAt'] ?? '',
      ].join(',');
    });

    return '$header\n${rows.join('\n')}';
  }

  Future<void> _downloadCsv() async {
    try {
      final csv = _generateCsv();
      final uri = Uri.parse('data:text/csv;charset=utf-8,${Uri.encodeComponent(csv)}');
      
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('CSV Download Started — ${_records.length} records.'),
              backgroundColor: AppTheme.success,
            ),
          );
        }
      } else {
        throw 'Could not launch download';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e'), backgroundColor: AppTheme.error),
        );
      }
    }
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'approved':      return AppTheme.success;
      case 'pending_review': return AppTheme.warning;
      case 'declined':      return AppTheme.error;
      default:              return AppTheme.textSecondary;
    }
  }

  String _statusLabel(String? status) {
    switch (status) {
      case 'approved':      return 'Approved';
      case 'pending_review': return 'Pending Review';
      case 'declined':      return 'Declined';
      case 'in_progress':   return 'In Progress';
      default:              return status ?? 'Unknown';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: CounselorSidebar(currentRoute: '/guidance-counselor/student-records'),
      appBar: AppBar(
        title: const Text('Student Records'),
        leading: Builder(
          builder: (ctx) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(ctx).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Export CSV',
            onPressed: _records.isEmpty ? null : _downloadCsv,
          ),
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadRecords),
        ],
      ),
      body: Column(
        children: [
          // Filter panel
          Container(
            color: AppTheme.backgroundWhite,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Search
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by name or student ID...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _search.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _search = '');
                              _loadRecords();
                            },
                          )
                        : null,
                  ),
                  onChanged: (v) => setState(() => _search = v),
                  onSubmitted: (_) => _loadRecords(),
                ),
                const SizedBox(height: 12),

                // Filter dropdowns row 1
                Row(
                  children: [
                    Expanded(child: _filterDropdown('Approval Status', _statusOptions, _status,
                        (v) => setState(() => _status = v!))),
                    const SizedBox(width: 8),
                    Expanded(child: _filterDropdown('Grade Level', _gradeLevelOptions, _gradeLevel,
                        (v) => setState(() => _gradeLevel = v!))),
                  ],
                ),
                const SizedBox(height: 8),

                // Filter dropdowns row 2
                Row(
                  children: [
                    Expanded(child: _filterDropdown('Strand', _strandOptions, _strand,
                        (v) => setState(() => _strand = v!))),
                    const SizedBox(width: 8),
                    Expanded(child: _filterDropdown('Dominant Type', _typeOptions, _dominantType,
                        (v) => setState(() => _dominantType = v!))),
                  ],
                ),
                const SizedBox(height: 8),

                // Date range + buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(
                          _dateFrom.isEmpty ? 'Date From' : _dateFrom,
                          style: const TextStyle(fontSize: 12),
                        ),
                        onPressed: () async {
                          final d = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (d != null) setState(() => _dateFrom = '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}');
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.calendar_today, size: 16),
                        label: Text(
                          _dateTo.isEmpty ? 'Date To' : _dateTo,
                          style: const TextStyle(fontSize: 12),
                        ),
                        onPressed: () async {
                          final d = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (d != null) setState(() => _dateTo = '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}');
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _loadRecords,
                        icon: const Icon(Icons.filter_list),
                        label: const Text('Apply Filters'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: _resetFilters,
                      child: const Text('Reset'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Results count
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Text(
                  '${_records.length} record(s) found',
                  style: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textSecondary),
                ),
              ],
            ),
          ),

          // Records list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _records.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.folder_open, size: 64, color: AppTheme.textSecondary),
                            SizedBox(height: 16),
                            Text('No records found', style: TextStyle(color: AppTheme.textSecondary)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _records.length,
                        itemBuilder: (ctx, i) {
                          final r = _records[i];
                          final scores = r['scores'] as Map<String, dynamic>;
                          final statusColor = _statusColor(r['status']);
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ExpansionTile(
                              leading: CircleAvatar(
                                backgroundColor: AppTheme.primaryPurple.withOpacity(0.1),
                                child: Text(
                                  r['primaryType'] ?? '?',
                                  style: TextStyle(
                                    color: AppTheme.riasecColor(r['primaryType'] ?? 'R'),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                r['studentName'],
                                style: const TextStyle(fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(
                                'ID: ${r['studentId']} • ${r['gradeLevel']} • ${r['strand']}',
                                style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
                              ),
                              trailing: Chip(
                                label: Text(
                                  _statusLabel(r['status']),
                                  style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600),
                                ),
                                backgroundColor: statusColor.withOpacity(0.1),
                                side: BorderSide(color: statusColor.withOpacity(0.3)),
                              ),
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Divider(),
                                      // Basic info
                                      _infoRow('Gender', r['gender'] ?? '-'),
                                      _infoRow('Age', '${r['age'] ?? '-'}'),
                                      _infoRow('Submitted', r['submittedAt'] ?? '-'),
                                      const SizedBox(height: 12),
                                      // RIASEC profile
                                      Text('RIASEC Profile', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.primaryPurple)),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: ['R','I','A','S','E','C'].map((t) {
                                          final pct = double.tryParse((scores[t] ?? "0").toString()) ?? 0.0;
                                          return Expanded(
                                            child: Column(
                                              children: [
                                                Text(t, style: TextStyle(fontWeight: FontWeight.bold, color: AppTheme.riasecColor(t), fontSize: 12)),
                                                const SizedBox(height: 4),
                                                Text('${pct.toStringAsFixed(0)}%', style: TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                                              ],
                                            ),
                                          );
                                        }).toList(),
                                      ),
                                      const SizedBox(height: 8),
                                      // Top 3
                                      Row(
                                        children: [
                                          if (r['primaryType'] != null)
                                            _typeBadge(r['primaryType'], '1st'),
                                          if (r['secondaryType'] != null) ...[
                                            const SizedBox(width: 6),
                                            _typeBadge(r['secondaryType'], '2nd'),
                                          ],
                                          if (r['tertiaryType'] != null) ...[
                                            const SizedBox(width: 6),
                                            _typeBadge(r['tertiaryType'], '3rd'),
                                          ],
                                        ],
                                      ),
                                      if (r['feedbackNotes'] != null && (r['feedbackNotes'] as String).isNotEmpty) ...[
                                        const SizedBox(height: 12),
                                        Text('Counselor Notes', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.primaryPurple)),
                                        const SizedBox(height: 4),
                                        Text(r['feedbackNotes'], style: TextStyle(color: AppTheme.textSecondary)),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _filterDropdown(String label, Map<String, String> options, String value, void Function(String?) onChanged) {
    return DropdownButtonFormField<String>(
      value: value,
      isDense: true,
      decoration: InputDecoration(
        labelText: label,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
      items: options.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value, style: const TextStyle(fontSize: 13)))).toList(),
      onChanged: onChanged,
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(width: 80, child: Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12))),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _typeBadge(String type, String rank) {
    final color = AppTheme.riasecColor(type);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        '$rank: $type',
        style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11),
      ),
    );
  }
}