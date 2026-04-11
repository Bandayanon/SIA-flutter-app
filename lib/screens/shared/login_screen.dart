import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import '../../services/session_manager.dart';
import '../../theme/app_theme.dart';
import '../../utils/api_config.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _primaryController = TextEditingController();
  final _passwordController = TextEditingController();
  String _userType = 'student';
  bool _isLoading = false;
  bool _obscurePassword = true;
  String _errorMessage = '';

  final String apiUrl = ApiConfig.login;

  @override
  void initState() {
    super.initState();
    // Auto-login logic: If a session exists, teleport to the dashboard!
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final session = SessionManager();
      if (session.studentId != null && session.role == 'student') {
        context.go('/student/dashboard');
      } else if (session.counselorId != null && session.role == 'guidance_counselor') {
        context.go('/guidance-counselor/dashboard');
      }
    });
  }

  @override
  void dispose() {
    _primaryController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final Map<String, String> body = {
        "role":     _userType,
        "password": _passwordController.text.trim(),
      };

      if (_userType == 'student') {
        body['student_id'] = _primaryController.text.trim();
      } else {
        body['email'] = _primaryController.text.trim();
      }

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      final data = jsonDecode(response.body);

      if (data['status'] == 'success') {
        if (!mounted) return;

        final session = SessionManager();

        if (_userType == 'student') {
          session.setStudent({
            'studentId':        data['studentId']?.toString(),
            'firstName':        data['firstName'],
            'lastName':         data['lastName'],
            'assessmentStatus': data['assessmentStatus'],
          });
          context.go('/student/dashboard');
        } else {
          session.setCounselor({
            'counselorId': data['counselorId'],
            'firstName':   data['firstName'],
            'lastName':    data['lastName'],
          });
          context.go('/guidance-counselor/dashboard');
        }
      } else {
        setState(() => _errorMessage = data['message'] ?? 'Login failed');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = 'Error: $e');
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Background Image ──────────────────────────────
          Image.asset(
            'assets/images/JMC_Background.jpg',
            fit: BoxFit.cover,
          ),

          // ── Dark overlay for readability ──────────────────
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.45),
                  AppTheme.primaryPurple.withOpacity(0.75),
                ],
              ),
            ),
          ),

          // ── Login Card ────────────────────────────────────
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Card(
                  elevation: 24,
                  shadowColor: Colors.black45,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 32.0, vertical: 36.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // School icon
                          CircleAvatar(
                            radius: 36,
                            backgroundColor:
                                AppTheme.primaryPurple.withOpacity(0.12),
                            child: const Icon(
                              Icons.school,
                              size: 40,
                              color: AppTheme.primaryPurple,
                            ),
                          ),
                          const SizedBox(height: 18),

                          // ── Title with Montserrat (STRICTLY login screen only) ──
                          Text(
                            'RIASEC Assessment',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.montserrat(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.textPrimary,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 6),

                          // Subtitle keeps the default theme font
                          Text(
                            'Career Assessment System',
                            textAlign: TextAlign.center,
                            style:
                                Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: AppTheme.textSecondary,
                                    ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'v2.0 - Security Hardened',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 10,
                              color: AppTheme.primaryPurple.withOpacity(0.5),
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 28),

                          // ── Role Toggle ───────────────────────────────────────
                          SegmentedButton<String>(
                            segments: const [
                              ButtonSegment(
                                value: 'student',
                                label: Text('Student'),
                                icon: Icon(Icons.person),
                              ),
                              ButtonSegment(
                                value: 'guidance_counselor',
                                label: Text('Counselor'),
                                icon: Icon(Icons.psychology),
                              ),
                            ],
                            selected: {_userType},
                            onSelectionChanged: (Set<String> newSelection) {
                              setState(() {
                                _userType = newSelection.first;
                                _primaryController.clear();
                                _errorMessage = '';
                              });
                            },
                          ),
                          const SizedBox(height: 24),

                          // ── ID / Email field ──────────────────────────────────
                          TextFormField(
                            controller: _primaryController,
                            decoration: InputDecoration(
                              labelText: _userType == 'student'
                                  ? 'Student ID'
                                  : 'Email',
                              prefixIcon: Icon(
                                _userType == 'student'
                                    ? Icons.badge
                                    : Icons.email,
                              ),
                            ),
                            keyboardType: _userType == 'student'
                                ? TextInputType.text
                                : TextInputType.emailAddress,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return _userType == 'student'
                                    ? 'Please enter your Student ID'
                                    : 'Please enter your email';
                              }
                              if (_userType == 'guidance_counselor' &&
                                  !value.contains('@')) {
                                return 'Please enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),

                          // ── Password field ────────────────────────────────────
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            decoration: InputDecoration(
                              labelText: 'Password',
                              prefixIcon: const Icon(Icons.lock),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: AppTheme.textSecondary,
                                ),
                                onPressed: () => setState(
                                    () => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Please enter your password';
                              }
                              return null;
                            },
                          ),

                          // ── Error message ─────────────────────────────────────
                          if (_errorMessage.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppTheme.error.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: AppTheme.error.withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline,
                                      color: AppTheme.error, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _errorMessage,
                                      style: const TextStyle(
                                          color: AppTheme.error, fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          const SizedBox(height: 24),

                          // ── Login Button ──────────────────────────────────────
                          _isLoading
                              ? const Center(
                                  child: CircularProgressIndicator())
                              : ElevatedButton(
                                  onPressed: _handleLogin,
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 16),
                                  ),
                                  child: const Text(
                                    'Login',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ),

                          // ── Register Button (Student only) ────────────────────
                          if (_userType == 'student') ...[
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: () => context.go('/register'),
                              child: Text(
                                "Don't have an account? Register",
                                style: TextStyle(
                                  color: AppTheme.primaryPurple.withOpacity(0.8),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
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
}