import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../theme/app_theme.dart';
import '../../utils/api_config.dart';
import '../../services/session_manager.dart';

class AdminRegistrationTab extends StatefulWidget {
  const AdminRegistrationTab({super.key});

  @override
  State<AdminRegistrationTab> createState() => _AdminRegistrationTabState();
}

class _AdminRegistrationTabState extends State<AdminRegistrationTab> {
  final _formKey = GlobalKey<FormState>();
  final _session = SessionManager();

  String _targetType = 'counselor'; // counselor or admin
  bool _isLoading = false;

  final _firstNameCtrl  = TextEditingController();
  final _lastNameCtrl   = TextEditingController();
  final _emailCtrl      = TextEditingController();
  final _passwordCtrl   = TextEditingController();
  bool _obscurePassword = true;

  bool get _isSuperAdmin => _session.adminRole == 'super_admin';

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _createAccount() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/admin_users_v2.php'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'action':      'create',
          'reqAdminId':  _session.adminId,
          'reqRoleId':   _session.adminRole == 'super_admin' ? 4 : 3,
          'targetType':  _targetType,
          'firstName':   _firstNameCtrl.text.trim(),
          'lastName':    _lastNameCtrl.text.trim(),
          'email':       _emailCtrl.text.trim(),
          'password':    _passwordCtrl.text,
        }),
      );

      if (!mounted) return;
      final data = jsonDecode(res.body);

      if (data['status'] == 'success') {
        _formKey.currentState!.reset();
        _firstNameCtrl.clear();
        _lastNameCtrl.clear();
        _emailCtrl.clear();
        _passwordCtrl.clear();
        _showSnack(data['message'] ?? 'Account created!', isError: false);
      } else {
        _showSnack(data['message'] ?? 'Something went wrong.', isError: true);
      }
    } catch (_) {
      if (mounted) _showSnack('Connection error. Please try again.', isError: true);
    }

    if (mounted) setState(() => _isLoading = false);
  }

  void _showSnack(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppTheme.error : AppTheme.success,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Left panel: form ────────────────────────────────
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Register New Account',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('Create a new staff or admin account in the system.',
                    style: TextStyle(color: AppTheme.textSecondary)),
                const SizedBox(height: 28),

                // Account type selector
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.dividerColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Account Type', style: TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textSecondary, fontSize: 12, letterSpacing: 0.8)),
                      const SizedBox(height: 12),
                      SegmentedButton<String>(
                        segments: [
                          const ButtonSegment(value: 'counselor', label: Text('Counselor'), icon: Icon(Icons.psychology)),
                          if (_isSuperAdmin)
                            const ButtonSegment(value: 'admin', label: Text('Admin'), icon: Icon(Icons.admin_panel_settings)),
                        ],
                        selected: {_targetType},
                        onSelectionChanged: (v) => setState(() => _targetType = v.first),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Form card
                Expanded(
                  child: SingleChildScrollView(
                    child: Form(
                      key: _formKey,
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.dividerColor),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(children: [
                              Expanded(child: _buildField(_firstNameCtrl, 'First Name', Icons.person_outline,
                                  validator: (v) => v!.isEmpty ? 'Required' : null)),
                              const SizedBox(width: 16),
                              Expanded(child: _buildField(_lastNameCtrl, 'Last Name', Icons.person_outline,
                                  validator: (v) => v!.isEmpty ? 'Required' : null)),
                            ]),
                            const SizedBox(height: 16),
                            _buildField(_emailCtrl, 'Email Address', Icons.email_outlined,
                                type: TextInputType.emailAddress,
                                validator: (v) {
                                  if (v == null || v.isEmpty) return 'Required';
                                  if (!v.contains('@')) return 'Enter a valid email';
                                  return null;
                                }),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordCtrl,
                              obscureText: _obscurePassword,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon: const Icon(Icons.lock_outline),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility,
                                      color: AppTheme.textSecondary),
                                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                ),
                              ),
                              validator: (v) {
                                if (v == null || v.isEmpty) return 'Required';
                                if (v.length < 8) return 'Minimum 8 characters';
                                return null;
                              },
                            ),
                            const SizedBox(height: 28),
                            ElevatedButton.icon(
                              onPressed: _isLoading ? null : _createAccount,
                              icon: _isLoading
                                  ? const SizedBox(width: 18, height: 18,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Icon(Icons.add_circle_outline),
                              label: Text(_isLoading ? 'Creating...' : 'Create Account'),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                backgroundColor: AppTheme.primaryPurple,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 32),

          // ── Right panel: info cards ──────────────────────────
          SizedBox(
            width: 280,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Account Permissions',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                _buildRoleCard(
                  icon: Icons.psychology,
                  color: AppTheme.info,
                  title: 'Counselor',
                  points: const [
                    'Review student assessments',
                    'Approve / reject results',
                    'Send feedback emails',
                  ],
                ),
                const SizedBox(height: 12),
                if (_isSuperAdmin)
                  _buildRoleCard(
                    icon: Icons.admin_panel_settings,
                    color: AppTheme.primaryPurple,
                    title: 'Admin',
                    points: const [
                      'Full monitoring access',
                      'Register counselors',
                      'Export assessment data',
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String label, IconData icon,
      {TextInputType type = TextInputType.text, String? Function(String?)? validator}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: type,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      validator: validator,
    );
  }

  Widget _buildRoleCard({required IconData icon, required Color color, required String title, required List<String> points}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 8),
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
          ]),
          const SizedBox(height: 12),
          ...points.map((p) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.check, size: 14, color: color),
                const SizedBox(width: 6),
                Expanded(child: Text(p, style: TextStyle(fontSize: 13, color: AppTheme.textSecondary))),
              ]))),
        ],
      ),
    );
  }
}
