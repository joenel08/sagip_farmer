// ============================================================
// lib/screens/login_screen.dart
// ============================================================
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/models.dart';
import '../services/api_service.dart';
import '../services/fcm_service.dart';
import '../services/session.dart';
import '../theme/app_theme.dart';
import '../widgets/modern_widgets.dart';
import 'register_screen.dart';
import 'user/user_home.dart';
import 'admin/admin_home.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  bool _remember = false;
  bool _obscure = true;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadSaved();
    // Status bar light on dark gradient
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
  }

  Future<void> _loadSaved() async {
    final c = await Session.getCredentials();
    if (c != null && mounted) {
      setState(() {
        _userCtrl.text = c['username']!;
        _passCtrl.text = c['password']!;
        _remember = true;
      });
    }
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final res =
          await ApiService.login(_userCtrl.text.trim(), _passCtrl.text);
      if (!mounted) return;

      if (res['success'] == true) {
        final user = UserModel.fromJson(res['user']);
        await Session.saveUser(user);

        if (_remember) {
          await Session.saveCredentials(
              _userCtrl.text.trim(), _passCtrl.text);
        } else {
          await Session.clearCredentials();
        }

        await FcmService.registerTokenForUser(user.id);

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 500),
            pageBuilder: (_, __, ___) => user.role == 'admin'
                ? AdminHome(user: user)
                : UserHome(user: user),
            transitionsBuilder: (_, anim, __, child) =>
                FadeTransition(opacity: anim, child: child),
          ),
        );
      } else {
        _snack(res['message'] ?? 'Login failed', AppColors.danger);
      }
    } catch (_) {
      _snack('Cannot reach server. Check your connection.', AppColors.danger);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg, Color c) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: c),
    );
  }

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: const BoxDecoration(gradient: AppGradients.deep),
        child: Stack(
          children: [
            // Decorative blurs
            Positioned(
              top: -100,
              right: -80,
              child: _glow(220, AppColors.lime.withOpacity(0.14)),
            ),
            Positioned(
              bottom: -120,
              left: -100,
              child: _glow(280, AppColors.green400.withOpacity(0.1)),
            ),

            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  physics: const BouncingScrollPhysics(),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      // Logo
                      Container(
                        width: 100,
                        height: 100,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.lime.withOpacity(0.3),
                              blurRadius: 30,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/logo.png',
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.agriculture,
                              size: 52,
                              color: AppColors.green700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'SAGIPfarmer',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: -0.8,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Sign in to your farm account',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withOpacity(0.65),
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 36),

                      // Login form card
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          borderRadius:
                              BorderRadius.circular(AppRadius.xl),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 40,
                              offset: const Offset(0, 20),
                              spreadRadius: -10,
                            ),
                          ],
                        ),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.green50,
                                      borderRadius:
                                          BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.login,
                                      size: 18,
                                      color: AppColors.green700,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  const Text(
                                    'Welcome back',
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.ink,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // Username
                              TextFormField(
                                controller: _userCtrl,
                                textInputAction: TextInputAction.next,
                                keyboardType: TextInputType.text,
                                decoration: const InputDecoration(
                                  labelText: 'Username',
                                  hintText: 'Enter your username',
                                  prefixIcon: Icon(Icons.person_outline),
                                ),
                                validator: (v) => (v == null ||
                                        v.trim().isEmpty)
                                    ? 'Enter username'
                                    : null,
                              ),
                              const SizedBox(height: 16),

                              // Password
                              TextFormField(
                                controller: _passCtrl,
                                obscureText: _obscure,
                                onFieldSubmitted: (_) => _login(),
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  hintText: 'Enter your password',
                                  prefixIcon:
                                      const Icon(Icons.lock_outline),
                                  suffixIcon: IconButton(
                                    icon: Icon(_obscure
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined),
                                    onPressed: () => setState(
                                        () => _obscure = !_obscure),
                                  ),
                                ),
                                validator: (v) => (v == null || v.isEmpty)
                                    ? 'Enter password'
                                    : null,
                              ),
                              const SizedBox(height: 8),

                              // Remember me
                              Row(
                                children: [
                                  SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: Checkbox(
                                      value: _remember,
                                      onChanged: (v) => setState(
                                          () => _remember = v ?? false),
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(6),
                                      ),
                                      activeColor: AppColors.green700,
                                      side: const BorderSide(
                                          color: AppColors.line, width: 1.5),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  GestureDetector(
                                    onTap: () => setState(
                                        () => _remember = !_remember),
                                    child: Text(
                                      'Remember me',
                                      style: AppText.body.copyWith(
                                          fontWeight: FontWeight.w500),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // Login button
                              SizedBox(
                                width: double.infinity,
                                child: PillButton(
                                  label: 'LOGIN',
                                  onPressed: _login,
                                  isLoading: _loading,
                                  gradient: AppGradients.primary,
                                ),
                              ),

                              const SizedBox(height: 20),
                              const Divider(color: AppColors.line),
                              const SizedBox(height: 16),

                              // Register link
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  Text("Don't have an account? ",
                                      style: AppText.muted),
                                  GestureDetector(
                                    onTap: () => Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) =>
                                              const RegisterScreen()),
                                    ),
                                    child: const Text(
                                      'Register',
                                      style: TextStyle(
                                        color: AppColors.green700,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        '© 2026 SAGIPfarmer',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withOpacity(0.4),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _glow(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: color, blurRadius: 100, spreadRadius: 20),
        ],
      ),
    );
  }
}