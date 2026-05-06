import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../shared/fruma_lab_chrome.dart';

class GatewayScreen extends StatelessWidget {
  const GatewayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.volcanic950,
      body: FrumaLabBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 26),
            children: [
              FrumaLabHeader(
                activeMode: 'innovator',
                onInnovator: () => context.go('/onboarding/innovator'),
                onPatron: () => context.go('/onboarding/patron'),
              ),
              const SizedBox(height: 96),
              const Center(child: FrumaCeramicOrb()),
              const SizedBox(height: 46),
              const _HeroTitle(),
              const SizedBox(height: 28),
              Text(
                'Where protected ideas meet patrons ready to request access and build real deals.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.42),
                      height: 1.55,
                    ),
              ),
              const SizedBox(height: 72),
              _EntryCard(
                icon: Icons.lightbulb_outline_rounded,
                eyebrow: 'INNOVATOR',
                title: 'I have ideas',
                body:
                    'Submit concepts, follow review status and respond when Patrons request access.',
                onTap: () => context.go('/onboarding/innovator'),
              ),
              const SizedBox(height: 14),
              _EntryCard(
                icon: Icons.shield_outlined,
                eyebrow: 'PATRON',
                title: 'I search for ideas',
                body:
                    'Enter the Vault, save opportunities and open controlled Deal Rooms.',
                onTap: () => context.go('/onboarding/patron'),
              ),
              const SizedBox(height: 22),
              TextButton(
                onPressed: () => context.go('/login'),
                child: const Text('Log in'),
              ),
              TextButton.icon(
                onPressed: () => context.go('/admin/demo'),
                icon: const Icon(Icons.admin_panel_settings_outlined),
                label: const Text('Admin demo'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroTitle extends StatelessWidget {
  const _HeroTitle();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'Sun-Drenched',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                color: Colors.white,
                fontFamily: 'SpaceGrotesk',
                fontSize: 52,
                fontWeight: FontWeight.w300,
                height: 0.95,
                letterSpacing: 0,
              ),
        ),
        Text(
          'Prototypes.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.displayLarge?.copyWith(
                color: AppColors.ochre,
                fontFamily: 'SpaceGrotesk',
                fontSize: 56,
                fontStyle: FontStyle.italic,
                fontWeight: FontWeight.w300,
                height: 0.95,
                letterSpacing: 0,
              ),
        ),
      ],
    );
  }
}

class _EntryCard extends StatelessWidget {
  final IconData icon;
  final String eyebrow;
  final String title;
  final String body;
  final VoidCallback onTap;

  const _EntryCard({
    required this.icon,
    required this.eyebrow,
    required this.title,
    required this.body,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
            bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Row(
            children: [
              Icon(icon, color: AppColors.ochre, size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      eyebrow,
                      style: const TextStyle(
                        color: AppColors.terracotta,
                        fontFamily: 'SpaceGrotesk',
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: Colors.white,
                            fontFamily: 'SpaceGrotesk',
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      body,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.45),
                            height: 1.45,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_rounded,
                color: AppColors.patinaTeal.withValues(alpha: 0.9),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
