import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../models/idea_model.dart';
import '../../models/pitch_model.dart';
import '../../providers/demo_session_provider.dart';
import '../../services/idea_service.dart';
import '../../services/pitch_service.dart';
import '../shared/fruma_lab_chrome.dart';

final _patronVaultHomeProvider =
    StreamProvider.autoDispose<List<IdeaModel>>((ref) {
  final demo = ref.watch(demoSessionProvider);
  if (demo.active) return Stream.value(demo.vaultIdeas);
  return IdeaService().watchVault();
});

final _patronRequestsHomeProvider =
    StreamProvider.autoDispose<List<PitchModel>>((ref) {
  final demo = ref.watch(demoSessionProvider);
  if (demo.active) return Stream.value(demo.pitches);
  final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  if (uid.isEmpty) return const Stream.empty();
  return PitchService().watchMyRequests(uid);
});

class PatronHomeScreen extends ConsumerWidget {
  const PatronHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ideas =
        ref.watch(_patronVaultHomeProvider).valueOrNull ?? const <IdeaModel>[];
    final requests = ref.watch(_patronRequestsHomeProvider).valueOrNull ??
        const <PitchModel>[];
    final demo = ref.watch(demoSessionProvider);
    final activeDeals = requests
        .where((pitch) =>
            pitch.status == PitchStatus.accepted ||
            pitch.status == PitchStatus.submitted ||
            pitch.status == PitchStatus.completed)
        .length;

    return Scaffold(
      backgroundColor: AppColors.volcanic950,
      bottomNavigationBar: const _PatronHomeTabBar(),
      body: FrumaLabBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    FrumaLabHeader(
                      activeMode: 'patron',
                      onInnovator: () {
                        if (demo.active) {
                          ref
                              .read(demoSessionProvider.notifier)
                              .switchTo(DemoRole.innovator);
                        }
                        context.go('/innovator');
                      },
                      onPatron: () => context.go('/patron'),
                    ),
                    Positioned(
                      right: 0,
                      child: IconButton(
                        tooltip: 'Profile',
                        onPressed: () => context.go('/profile'),
                        icon: Icon(
                          Icons.settings_outlined,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(22, 20, 22, 110),
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Patron Home',
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineLarge
                                    ?.copyWith(
                                      color: Colors.white,
                                      fontFamily: 'SpaceGrotesk',
                                      fontSize: 34,
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 0,
                                    ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                'Track opportunities, requests and open deal rooms.',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color:
                                          Colors.white.withValues(alpha: 0.38),
                                    ),
                              ),
                            ],
                          ),
                        ),
                        const FrumaStatusPill(
                          label: 'PATRON',
                          color: AppColors.patinaTeal,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _PatronCommandLine(
                      onVault: () => context.go('/vault'),
                      onRequests: () => context.go('/notifications'),
                    ),
                    const SizedBox(height: 34),
                    const FrumaSectionLabel(label: 'MARKET SNAPSHOT.'),
                    const SizedBox(height: 10),
                    _PatronMetricList(
                      liveIdeas: ideas.length,
                      sentRequests: requests.length,
                      activeDeals: activeDeals,
                      favorites: demo.active ? demo.favoriteIdeaIds.length : 0,
                    ),
                    const SizedBox(height: 38),
                    const FrumaSectionLabel(label: 'NEXT ACTIONS.'),
                    const SizedBox(height: 8),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                          bottom: BorderSide(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                      ),
                      child: Column(
                        children: [
                          FrumaActionRow(
                            icon: Icons.diamond_outlined,
                            title: 'Vault',
                            body: 'Search reviewed ideas',
                            onTap: () => context.go('/vault'),
                          ),
                          const FrumaThinDivider(),
                          FrumaActionRow(
                            icon: Icons.handshake_outlined,
                            title: 'Requests',
                            body: requests.isEmpty
                                ? 'No active requests'
                                : '${requests.length} request(s) sent',
                            onTap: () => context.go('/notifications'),
                          ),
                          const FrumaThinDivider(),
                          FrumaActionRow(
                            icon: Icons.card_membership_rounded,
                            title: 'Access',
                            body: 'Manage Patron subscription',
                            onTap: () => context.go('/paywall'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PatronCommandLine extends StatelessWidget {
  final VoidCallback onVault;
  final VoidCallback onRequests;

  const _PatronCommandLine({
    required this.onVault,
    required this.onRequests,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Row(
          children: [
            Expanded(
              child: _CommandButton(
                icon: Icons.search_rounded,
                label: 'OPEN VAULT',
                onTap: onVault,
              ),
            ),
            Container(
              width: 1,
              height: 32,
              color: Colors.white.withValues(alpha: 0.08),
            ),
            Expanded(
              child: _CommandButton(
                icon: Icons.notifications_none_rounded,
                label: 'REQUESTS',
                onTap: onRequests,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommandButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _CommandButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.ochre, size: 19),
            const SizedBox(width: 9),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.ochre,
                fontFamily: 'SpaceGrotesk',
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 2.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PatronMetricList extends StatelessWidget {
  final int liveIdeas;
  final int sentRequests;
  final int activeDeals;
  final int favorites;

  const _PatronMetricList({
    required this.liveIdeas,
    required this.sentRequests,
    required this.activeDeals,
    required this.favorites,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      child: Column(
        children: [
          _MetricRow(label: 'LIVE IDEAS', value: '$liveIdeas'),
          const FrumaThinDivider(),
          _MetricRow(label: 'REQUESTS SENT', value: '$sentRequests'),
          const FrumaThinDivider(),
          _MetricRow(label: 'DEAL ROOMS', value: '$activeDeals'),
          const FrumaThinDivider(),
          _MetricRow(
            label: 'FAVORITES',
            value: '$favorites',
            accent: AppColors.ochre,
          ),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  final String label;
  final String value;
  final Color accent;

  const _MetricRow({
    required this.label,
    required this.value,
    this.accent = AppColors.patinaTeal,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontFamily: 'SpaceGrotesk',
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 2.2,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: accent,
              fontFamily: 'SpaceGrotesk',
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _PatronHomeTabBar extends StatelessWidget {
  const _PatronHomeTabBar();

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: AppColors.labBlack,
      elevation: 0,
      child: SizedBox(
        height: 68,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _LabTabButton(
              icon: Icons.home_rounded,
              label: 'Home',
              selected: true,
              onTap: () => context.go('/patron'),
            ),
            _LabTabButton(
              icon: Icons.diamond_outlined,
              label: 'Vault',
              selected: false,
              onTap: () => context.go('/vault'),
            ),
            _LabTabButton(
              icon: Icons.notifications_none_rounded,
              label: 'Alerts',
              selected: false,
              onTap: () => context.go('/notifications'),
            ),
            _LabTabButton(
              icon: Icons.person_outline_rounded,
              label: 'Profile',
              selected: false,
              onTap: () => context.go('/profile'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LabTabButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _LabTabButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color =
        selected ? AppColors.ochre : Colors.white.withValues(alpha: 0.38);
    return InkResponse(
      onTap: onTap,
      radius: 32,
      child: SizedBox(
        width: 72,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontFamily: 'SpaceGrotesk',
                fontSize: 10,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                letterSpacing: 0.4,
              ),
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }
}
