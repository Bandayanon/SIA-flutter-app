import 'package:flutter/material.dart';
import 'dart:html' as html;
import '../../services/api_service.dart';
import '../../services/session_manager.dart';
import '../../theme/app_theme.dart';

class AdminArchiveV2 extends StatefulWidget {
  const AdminArchiveV2({super.key});

  @override
  State<AdminArchiveV2> createState() => _AdminArchiveV2State();
}

class _AdminArchiveV2State extends State<AdminArchiveV2> {
  final _session = SessionManager();
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
      final res = await ApiService.getAdminStats();
      if (res['status'] == 'success') {
        setState(() => _stats = res['data']);
      }
    } catch (e) {
      debugPrint('Error loading stats: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _exportCsv() {
    final url = ApiService.getExportUrl(_session.adminId ?? 0);
    html.window.open(url, '_blank');
    
    _showSnackBar('Preparing CSV export. The download will begin shortly.', AppTheme.info);
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 32),
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else
            _buildArchiveControls(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Data Archiving',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppTheme.primaryPurple,
          ),
        ),
        const Text('Export and maintain system records for backup and analysis.'),
      ],
    );
  }

  Widget _buildArchiveControls() {
    return Column(
      children: [
        Row(
          children: [
            _buildStatCard('Completed Assessments', _stats['completed_assessments']?.toString() ?? '0', Icons.assignment_turned_in),
            const SizedBox(width: 16),
            _buildStatCard('Total Students', _stats['total_students']?.toString() ?? '0', Icons.people),
            const SizedBox(width: 16),
            _buildStatCard('Total Results', _stats['total_results']?.toString() ?? '0', Icons.analytics),
          ],
        ),
        const SizedBox(height: 48),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: AppTheme.dividerColor.withOpacity(0.5)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(40.0),
            child: Column(
              children: [
                const Icon(Icons.download_for_offline, size: 80, color: AppTheme.primaryPurple),
                const SizedBox(height: 24),
                const Text(
                  'Assessment Result Export',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                const Text(
                  'This will generate a CSV file containing all Student assessment results, school strands, grade levels, and top career match codes.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: _exportCsv,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.file_download),
                  label: const Text('Export System Records (.CSV)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Confidentiality Warning: Ensure exported data is handled according to school privacy policies.',
                  style: TextStyle(fontSize: 12, color: AppTheme.error, fontStyle: FontStyle.italic),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppTheme.primaryPurple.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.primaryPurple.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppTheme.primaryPurple, size: 28),
            const SizedBox(height: 16),
            Text(value, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.primaryPurple)),
            Text(title, style: TextStyle(color: AppTheme.textSecondary, fontSize: 14)),
          ],
        ),
      ),
    );
  }
}
