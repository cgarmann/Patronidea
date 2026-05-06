import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';
import '../shared/fruma_lab_chrome.dart';
import '../shared/loading_overlay.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await ref.read(authServiceProvider).signInWithEmail(
            email: _emailCtrl.text.trim(),
            password: _passCtrl.text,
          );
      if (mounted) context.go('/');
    } catch (e) {
      setState(() {
        _error = _friendlyError(e.toString());
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _googleLogin() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await ref
          .read(authServiceProvider)
          .signInWithGoogle(role: UserRole.innovator);
      if (mounted) context.go('/');
    } catch (e) {
      setState(() {
        _error = _friendlyError(e.toString());
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  String _friendlyError(String raw) {
    if (raw.contains('wrong-password') || raw.contains('user-not-found')) {
      return 'Incorrect email or password.';
    }
    if (raw.contains('network')) return 'Check your internet connection.';
    return 'Something went wrong. Try again.';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LoadingOverlay(
      isLoading: _loading,
      child: Scaffold(
        backgroundColor: AppColors.volcanic950,
        body: FrumaLabBackground(
          child: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 28),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    FrumaBackButton(onPressed: () => context.go('/')),
                    const SizedBox(height: 34),
                    const FrumaSectionLabel(label: 'SECURE ACCESS.'),
                    const SizedBox(height: 14),
                    Text(
                      'Welcome back.',
                      style: theme.textTheme.displayMedium?.copyWith(
                        color: Colors.white,
                        fontFamily: 'SpaceGrotesk',
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0,
                      ),
                    ).animate().fadeIn().slideY(begin: -0.06),
                    const SizedBox(height: 8),
                    Text(
                      'Sign in to continue into FRUMA.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.44),
                      ),
                    ).animate().fadeIn(delay: 100.ms),
                    const SizedBox(height: 34),
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.mail_outline_rounded),
                      ),
                      validator: (v) => v == null || !v.contains('@')
                          ? 'Enter a valid email'
                          : null,
                    ).animate().fadeIn(delay: 180.ms),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _passCtrl,
                      obscureText: _obscure,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscure
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                          ),
                          onPressed: () => setState(() => _obscure = !_obscure),
                        ),
                      ),
                      validator: (v) =>
                          v == null || v.length < 6 ? 'Min 6 characters' : null,
                    ).animate().fadeIn(delay: 230.ms),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          if (_emailCtrl.text.isNotEmpty) {
                            ref
                                .read(authServiceProvider)
                                .sendPasswordReset(_emailCtrl.text.trim());
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Password reset email sent.'),
                              ),
                            );
                          }
                        },
                        child: const Text('Forgot password?'),
                      ),
                    ).animate().fadeIn(delay: 260.ms),
                    if (_error != null) ...[
                      DecoratedBox(
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: AppColors.error.withValues(alpha: 0.32),
                            ),
                            bottom: BorderSide(
                              color: AppColors.error.withValues(alpha: 0.32),
                            ),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline_rounded,
                                  color: AppColors.error, size: 18),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _error!,
                                  style: const TextStyle(
                                    color: AppColors.error,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    const SizedBox(height: 8),
                    FrumaLabButton(label: 'Sign in', onPressed: _login)
                        .animate()
                        .fadeIn(delay: 320.ms),
                    const SizedBox(height: 18),
                    const FrumaThinDivider(),
                    const SizedBox(height: 18),
                    FrumaLabButton(
                      label: 'Continue with Google',
                      icon: Icons.g_mobiledata_rounded,
                      secondary: true,
                      onPressed: _googleLogin,
                    ).animate().fadeIn(delay: 370.ms),
                    const SizedBox(height: 30),
                    Center(
                      child: TextButton(
                        onPressed: () => context.go('/'),
                        child: const Text('Create account'),
                      ),
                    ).animate().fadeIn(delay: 420.ms),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
