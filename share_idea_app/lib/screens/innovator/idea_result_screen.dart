import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../models/idea_model.dart';
import '../shared/fruma_lab_chrome.dart';

class IdeaResultScreen extends StatelessWidget {
  final IdeaModel idea;

  const IdeaResultScreen({super.key, required this.idea});

  @override
  Widget build(BuildContext context) {
    return switch (idea.status) {
      IdeaStatus.active => _ResultView(
          eyebrow: 'VAULT READY.',
          title: 'Your idea is live.',
          body:
              'No similar ideas were found. The idea is now available to Patrons in the Vault.',
          metric: '${idea.uniquenessScore}% unique',
          accent: AppColors.patinaTeal,
          primaryLabel: 'View My Ideas',
          primaryTarget: '/innovator',
        ),
      IdeaStatus.needsReview => _ResultView(
          eyebrow: 'MANUAL REVIEW.',
          title: 'Flagged for review',
          body:
              'The Smart Engine found possible overlap. Your draft is saved while it is checked.',
          metric: '${(idea.matchScore * 100).toStringAsFixed(0)}% match',
          accent: AppColors.warning,
          matchTitle: idea.matchedIdeaTitle,
          primaryLabel: 'View My Ideas',
          primaryTarget: '/innovator',
        ),
      IdeaStatus.flagged => const _ResultView(
          eyebrow: 'MANUAL REVIEW.',
          title: 'Report under review',
          body:
              'A Patron report is waiting for admin. The idea remains visible until a decision is made.',
          metric: 'Flagged',
          accent: AppColors.warning,
          primaryLabel: 'View My Ideas',
          primaryTarget: '/innovator',
        ),
      IdeaStatus.rejected => _ResultView(
          eyebrow: 'NOT ACCEPTED.',
          title: 'Similar idea found',
          body:
              'This version was not added to the Vault. Try a different angle, audience or core concept.',
          metric: '${(idea.matchScore * 100).toStringAsFixed(0)}% match',
          accent: AppColors.error,
          matchTitle: idea.matchedIdeaTitle,
          primaryLabel: 'Try Different Angle',
          primaryTarget: '/innovator/submit',
          secondaryLabel: 'Back to Dashboard',
          secondaryTarget: '/innovator',
        ),
      _ => _ResultView(
          eyebrow: 'VAULT READY.',
          title: 'Your idea is saved.',
          body: 'The idea is now in your FRUMA workflow.',
          metric: idea.statusLabel,
          accent: AppColors.ochre,
          primaryLabel: 'View My Ideas',
          primaryTarget: '/innovator',
        ),
    };
  }
}

class _ResultView extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String body;
  final String metric;
  final Color accent;
  final String? matchTitle;
  final String primaryLabel;
  final String primaryTarget;
  final String? secondaryLabel;
  final String? secondaryTarget;

  const _ResultView({
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.metric,
    required this.accent,
    this.matchTitle,
    required this.primaryLabel,
    required this.primaryTarget,
    this.secondaryLabel,
    this.secondaryTarget,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppColors.volcanic950,
      body: FrumaLabBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FrumaStatusPill(label: eyebrow, color: accent)
                    .animate()
                    .fadeIn(),
                const Spacer(),
                Text(
                  title,
                  style: theme.textTheme.displayMedium?.copyWith(
                    color: Colors.white,
                    fontFamily: 'SpaceGrotesk',
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0,
                  ),
                ).animate().fadeIn(delay: 120.ms).slideY(begin: 0.05),
                const SizedBox(height: 14),
                Text(
                  body,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.48),
                    height: 1.52,
                  ),
                ).animate().fadeIn(delay: 190.ms),
                const SizedBox(height: 26),
                DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: accent.withValues(alpha: 0.32)),
                      bottom: BorderSide(color: accent.withValues(alpha: 0.32)),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'SMART ENGINE',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.42),
                              fontFamily: 'SpaceGrotesk',
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                        Text(
                          metric.toUpperCase(),
                          style: TextStyle(
                            color: accent,
                            fontFamily: 'SpaceGrotesk',
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(delay: 260.ms),
                if (matchTitle != null && matchTitle!.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  Text(
                    'Closest match: $matchTitle',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                  ).animate().fadeIn(delay: 320.ms),
                ],
                const Spacer(),
                FrumaLabButton(
                  label: primaryLabel,
                  onPressed: () => context.go(primaryTarget),
                ).animate().fadeIn(delay: 390.ms),
                if (secondaryLabel != null && secondaryTarget != null) ...[
                  const SizedBox(height: 12),
                  FrumaLabButton(
                    label: secondaryLabel!,
                    secondary: true,
                    onPressed: () => context.go(secondaryTarget!),
                  ).animate().fadeIn(delay: 440.ms),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
