import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/demo_session_provider.dart';
import '../shared/fruma_lab_chrome.dart';

class RoleOnboardingScreen extends ConsumerWidget {
  final String role;

  const RoleOnboardingScreen({
    super.key,
    required this.role,
  });

  bool get _isPatron => role == 'patron';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final demoRole = _isPatron ? DemoRole.patron : DemoRole.innovator;

    return Scaffold(
      backgroundColor: AppColors.volcanic950,
      body: FrumaLabBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 14, 24, 28),
            children: [
              FrumaBackButton(onPressed: () => context.go('/')),
              const SizedBox(height: 36),
              FrumaStatusPill(
                label: _isPatron ? 'Patron' : 'Innovator',
                color: _isPatron ? AppColors.patinaTeal : AppColors.ochre,
              ),
              const SizedBox(height: 18),
              Text(
                _isPatron
                    ? 'Find ideas worth backing'
                    : 'Turn ideas into deals',
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 34,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _isPatron
                    ? 'Browse curated opportunities, request access and continue inside a Deal Room.'
                    : 'Capture ideas, pass review and respond when Patrons show interest.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.46),
                ),
              ),
              const SizedBox(height: 34),
              DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(
                    top:
                        BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                    bottom:
                        BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                ),
                child: Column(
                  children: [
                    FrumaActionRow(
                      icon: _isPatron
                          ? Icons.search_rounded
                          : Icons.lightbulb_outline_rounded,
                      title: _isPatron ? 'Create Patron account' : 'Create',
                      body:
                          _isPatron ? 'Unlock the Vault' : 'Start saving ideas',
                      onTap: () => context.go('/register/$role'),
                    ),
                    const FrumaThinDivider(),
                    FrumaActionRow(
                      icon: Icons.play_circle_outline_rounded,
                      title: 'Demo mode',
                      body: _isPatron
                          ? 'Preview Patron flow'
                          : 'Preview Innovator flow',
                      onTap: () {
                        ref
                            .read(demoSessionProvider.notifier)
                            .startAs(demoRole);
                        context.go(_isPatron ? '/vault' : '/innovator');
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: TextButton(
                  onPressed: () => context.go('/login'),
                  child: const Text('Log in'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
