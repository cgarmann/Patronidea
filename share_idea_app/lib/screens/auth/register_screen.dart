import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_model.dart';
import '../shared/fruma_lab_chrome.dart';
import '../shared/loading_overlay.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  final String role; // 'innovator' | 'patron'
  const RegisterScreen({super.key, required this.role});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  bool _obscure = true;
  String? _error;

  UserRole get _role =>
      widget.role == 'patron' ? UserRole.patron : UserRole.innovator;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await ref.read(authServiceProvider).signUpWithEmail(
            email: _emailCtrl.text.trim(),
            password: _passCtrl.text,
            displayName: _nameCtrl.text.trim(),
            role: _role,
          );
      if (!mounted) return;
      if (_role == UserRole.patron) {
        context.go('/paywall');
      } else {
        context.go('/innovator');
      }
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

  Future<void> _googleRegister() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final user =
          await ref.read(authServiceProvider).signInWithGoogle(role: _role);
      if (!mounted) return;
      if (user.role == UserRole.patron && !user.isActivePatron) {
        context.go('/paywall');
      } else {
        context.go('/innovator');
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
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
    if (raw.contains('email-already-in-use')) {
      return 'An account with this email already exists.';
    }
    if (raw.contains('weak-password')) {
      return 'Password must be at least 6 characters.';
    }
    return 'Something went wrong. Try again.';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPatron = _role == UserRole.patron;

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
                    const SizedBox(height: 32),
                    FrumaStatusPill(
                      label: isPatron ? 'Patron access' : 'Innovator',
                      color: isPatron
                          ? AppColors.patinaTeal
                          : AppColors.terracotta,
                    ).animate().fadeIn(),
                    const SizedBox(height: 16),
                    Text(
                      'Create your account.',
                      style: theme.textTheme.displayMedium?.copyWith(
                        color: Colors.white,
                        fontFamily: 'SpaceGrotesk',
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0,
                      ),
                    ).animate().fadeIn(delay: 100.ms),
                    const SizedBox(height: 34),
                    TextFormField(
                      controller: _nameCtrl,
                      textCapitalization: TextCapitalization.words,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Name required'
                          : null,
                    ).animate().fadeIn(delay: 150.ms),
                    const SizedBox(height: 14),
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
                    ).animate().fadeIn(delay: 200.ms),
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
                    ).animate().fadeIn(delay: 250.ms),
                    const SizedBox(height: 22),
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
                          child: Text(
                            _error!,
                            style: const TextStyle(
                              color: AppColors.error,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    FrumaLabButton(
                      label: isPatron
                          ? 'Continue to membership'
                          : 'Create account',
                      onPressed: _register,
                    ).animate().fadeIn(delay: 300.ms),
                    const SizedBox(height: 18),
                    const FrumaThinDivider(),
                    const SizedBox(height: 18),
                    FrumaLabButton(
                      label: 'Continue with Google',
                      icon: Icons.g_mobiledata_rounded,
                      secondary: true,
                      onPressed: _googleRegister,
                    ).animate().fadeIn(delay: 350.ms),
                    const SizedBox(height: 30),
                    Center(
                      child: TextButton(
                        onPressed: () => context.go('/login'),
                        child: const Text('Log in'),
                      ),
                    ).animate().fadeIn(delay: 400.ms),
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
