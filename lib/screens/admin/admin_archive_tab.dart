import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../theme/app_theme.dart';
import '../../utils/api_config.dart';
import '../../services/session_manager.dart';

class AdminArchiveTab extends StatefulWidget {
  const AdminArchiveTab({super.key});

  @override
  State<AdminArchiveTab> createState() => _AdminArchiveTabState();
}

class _AdminArchiveTabState extends State<AdminArchiveTab> {
  final _session = SessionManager();
  List<dynamic> _records = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _statusFilter = 'all';

  @override
  void initState() {
    super.initState();
    _fetchRecords();
  }

  Future<void> _fetchRecords() async {
    setState(() => _isLoading = true);
    try {
      final res = await http.get(Uri.parse(
        '${ApiConfig.baseUrl}/admin_archive.php?adminId=${_session.adminId}&listOnly=1',
      ));
      if (!mounted) return;
      final data = jsonDecode(res.body);
      if (data['status'] == 'success') {
        setState(() {
          _records   = data['records'] ?? [];
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _downloadCsv() {
    final url = '${ApiConfig.baseUrl}/admin_archive.php?exportCsv=1&adminId=${_session.adminId}';
    // For web, open in new tab to trigger download
    openUrl(url);
  }

  // Simple web URL opener for Flutter Web
  void openUrl(String url) {
    // ignore: avoid_web_libraries_in_flutter
    import('dart:html').then((html) {
      html.window.open(url, '_blank');
    });
  }

  List<dynamic> get _filtered {
    return _records.where((r) {
      final name = '${r['FirstName']} ${r['LastName']}'.toLowerCase();
      final matchSearch = _searchQuery.isEmpty || name.contains(_searchQuery.toLowerCase());
      final matchStatus = _statusFilter == 'all' || r['Status'] == _statusFilter;
      return matchSearch && matchStatus;
    }).toList();
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
                  Text('Data Archiving', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('View and export completed student assessment results.', style: TextStyle(color: AppTheme.textSecondary)),
                ]),
              ),
              ElevatedButton.icon(
                onPressed: _downloadCsv,
                icon: const Icon(Icons.download),
                label: const Text('Export to CSV'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.success,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // ── Summary cards ────────────────────────────────────
          Row(children: [
            _buildSummaryChip(Icons.check_circle, 'Approved',
                _records.where((r) => r['Status'] == 'approved').length, AppTheme.success),
            const SizedBox(width: 12),
            _buildSummaryChip(Icons.cancel, 'Rejected',
                _records.where((r) => r['Status'] == 'rejected').length, AppTheme.error),
            const SizedBox(width: 12),
            _buildSummaryChip(Icons.hourglass_empty, 'Pending Review',
                _records.where((r) => r['Status'] == 'pending_review').length, AppTheme.warning),
            const SizedBox(width: 12),
            _buildSummaryChip(Icons.list_alt, 'Total', _records.length, AppTheme.primaryPurple),
          ]),
          const SizedBox(height: 20),

          // ── Filter bar ───────────────────────────────────────
          Row(children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search student name…',
                  prefixIcon: const Icon(Icons.search),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              ),
            ),
            const SizedBox(width: 16),
            DropdownButton<String>(
              value: _statusFilter,
              borderRadius: BorderRadius.circular(8),
              items: const [
                DropdownMenuItem(value: 'all',           child: Text('All Statuses')),
                DropdownMenuItem(value: 'approved',      child: Text('Approved')),
                DropdownMenuItem(value: 'rejected',      child: Text('Rejected')),
                DropdownMenuItem(value: 'pending_review',child: Text('Pending')),
              ],
              onChanged: (v) => setState(() => _statusFilter = v!),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: _fetchRecords,
              icon: const Icon(Icons.refresh),
              style: IconButton.styleFrom(backgroundColor: AppTheme.primaryPurple),
            ),
          ]),
          const SizedBox(height: 16),

          // ── Table ────────────────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filtered.isEmpty
                    ? Center(child: Text('No records found.', style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)))
                    : Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.dividerColor),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: SingleChildScrollView(
                              child: DataTable(
                                headingRowColor: WidgetStateProperty.all(AppTheme.backgroundLight),
                                dataRowMinHeight: 52,
                                dataRowMaxHeight: 52,
                                columnSpacing: 24,
                                columns: const [
                                  DataColumn(label: Text('Student', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Grade', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Strand', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Top 1', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Top 2', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Top 3', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                                  DataColumn(label: Text('Submitted', style: TextStyle(fontWeight: FontWeight.bold))),
                                ],
                                rows: _filtered.map((r) {
                                  final status = r['Status'] ?? '';
                                  return DataRow(cells: [
                                    DataCell(Text('${r['FirstName']} ${r['LastName']}', style: const TextStyle(fontWeight: FontWeight.w600))),
                                    DataCell(Text(r['GradeLevel'] ?? '—')),
                                    DataCell(Text(r['Strand'] ?? '—')),
                                    DataCell(_buildRiasecBadge(r['Result_Code1'])),
                                    DataCell(_buildRiasecBadge(r['Result_Code2'])),
                                    DataCell(_buildRiasecBadge(r['Result_Code3'])),
                                    DataCell(_buildStatusBadge(status)),
                                    DataCell(Text(r['SubmittedAt'] ?? '—', style: TextStyle(fontSize: 12, color: AppTheme.textSecondary))),
                                  ]);
                                }).toList(),
                              ),
                            ),
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryChip(IconData icon, String label, int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('$count', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: TextStyle(fontSize: 11, color: color.withOpacity(0.8))),
        ]),
      ]),
    );
  }

  Widget _buildRiasecBadge(String? code) {
    if (code == null || code.isEmpty) return const Text('—');
    final color = AppTheme.riasecColor(code);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(code, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'approved':      color = AppTheme.success; break;
      case 'rejected':      color = AppTheme.error;   break;
      case 'pending_review':color = AppTheme.warning;  break;
      default:              color = AppTheme.textSecondary;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: Text(status.replaceAll('_', ' '), style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold)),
    );
  }
}
