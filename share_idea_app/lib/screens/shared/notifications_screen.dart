import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../models/pitch_model.dart';
import '../../providers/demo_session_provider.dart';
import 'fruma_lab_chrome.dart';
import 'main_scaffold.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final demo = ref.watch(demoSessionProvider);
    if (demo.active) {
      final pitches =
          demo.role == DemoRole.innovator ? demo.incomingPitches : demo.pitches;
      return MainScaffold(
        title: 'Notifications',
        body: ListView(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 110),
          children: [
            const FrumaSectionLabel(label: 'ALERTS.'),
            const SizedBox(height: 10),
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                  bottom:
                      BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                ),
              ),
              child: Column(
                children: [
                  for (var index = 0; index < pitches.length; index++) ...[
                    _ActionCard(
                      icon: pitches[index].status == PitchStatus.pending
                          ? Icons.hourglass_top_rounded
                          : Icons.handshake_outlined,
                      title: pitches[index].status == PitchStatus.pending
                          ? 'Contact request'
                          : 'Deal Room open',
                      body: pitches[index].ideaTitle,
                      color: pitches[index].status == PitchStatus.pending
                          ? AppColors.warning
                          : AppColors.green,
                      onTap: () => context.go('/pitch/${pitches[index].id}'),
                    ),
                    if (index != pitches.length - 1) const FrumaThinDivider(),
                  ],
                ],
              ),
            ),
          ],
        ),
      );
    }

    return MainScaffold(
      title: 'Notifications',
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 18, 24, 110),
        children: const [
          FrumaSectionLabel(label: 'ALERTS.'),
          SizedBox(height: 10),
          _ActionCard(
            icon: Icons.hourglass_top_rounded,
            title: 'No pending actions',
            body:
                'Contact requests, review results and deal updates will appear here.',
            color: AppColors.green,
            onTap: null,
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final Color color;
  final VoidCallback? onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.body,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 21),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontFamily: 'SpaceGrotesk',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    body,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.44),
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.patinaTeal),
          ],
        ),
      ),
    );
  }
}
