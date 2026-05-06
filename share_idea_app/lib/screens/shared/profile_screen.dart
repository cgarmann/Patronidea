import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/demo_session_provider.dart';
import 'fruma_lab_chrome.dart';
import 'main_scaffold.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = FirebaseAuth.instance.currentUser;
    final demo = ref.watch(demoSessionProvider);
    final theme = Theme.of(context);
    final name = demo.active
        ? 'FRUMA demo ${demo.role.label}'
        : user?.displayName?.trim().isNotEmpty == true
            ? user!.displayName!
            : 'FRUMA member';
    final email = demo.active
        ? 'demo-${demo.role.name}@fruma.local'
        : user?.email ?? 'No email';

    return MainScaffold(
      title: 'Profile',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 110),
        children: [
          const FrumaSectionLabel(label: 'ACCOUNT.'),
          const SizedBox(height: 12),
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.person_outline_rounded,
                    color: AppColors.ochre,
                    size: 30,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    name,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: Colors.white,
                      fontFamily: 'SpaceGrotesk',
                      fontSize: 28,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    email,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.42),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
              ),
            ),
            child: Column(
              children: [
                FrumaActionRow(
                  icon: Icons.diamond_outlined,
                  title: 'Vault',
                  body: 'Open Patron database',
                  onTap: () => context.go('/vault'),
                ),
                if (demo.active) ...[
                  const FrumaThinDivider(),
                  FrumaActionRow(
                    icon: Icons.swap_horiz_rounded,
                    title: 'Switch role',
                    body: demo.role == DemoRole.patron
                        ? 'Innovator demo'
                        : 'Patron demo',
                    onTap: () {
                      final next = demo.role == DemoRole.patron
                          ? DemoRole.innovator
                          : DemoRole.patron;
                      ref.read(demoSessionProvider.notifier).switchTo(next);
                      context.go(
                        next == DemoRole.patron ? '/patron' : '/innovator',
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
