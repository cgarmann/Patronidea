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

final _myIdeasProvider = StreamProvider.autoDispose<List<IdeaModel>>((ref) {
  final demo = ref.watch(demoSessionProvider);
  if (demo.active) return Stream.value(demo.myIdeas);
  final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  return IdeaService().watchMyIdeas(uid);
});

final _incomingPitchesProvider = StreamProvider.autoDispose<List<PitchModel>>(
  (ref) {
    final demo = ref.watch(demoSessionProvider);
    if (demo.active) return Stream.value(demo.incomingPitches);
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    if (uid.isEmpty) return const Stream.empty();
    return PitchService().watchIncomingPitches(uid);
  },
);

class InnovatorDashboard extends ConsumerWidget {
  const InnovatorDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ideasAsync = ref.watch(_myIdeasProvider);
    final pitchesAsync = ref.watch(_incomingPitchesProvider);
    final demo = ref.watch(demoSessionProvider);

    return Scaffold(
      backgroundColor: AppColors.volcanic950,
      floatingActionButton: FloatingActionButton(
        tooltip: 'New idea',
        backgroundColor: AppColors.terracotta,
        foregroundColor: Colors.white,
        shape: const CircleBorder(),
        onPressed: () => context.push('/innovator/submit'),
        child: const Icon(Icons.add_rounded),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: const _InnovatorLabTabBar(),
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
                      activeMode: 'innovator',
                      onInnovator: () => context.go('/innovator'),
                      onPatron: () {
                        if (demo.active) {
                          ref
                              .read(demoSessionProvider.notifier)
                              .switchTo(DemoRole.patron);
                        }
                        context.go('/patron');
                      },
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
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Innovator Lab',
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
                            'Submit, review and move ideas toward the Vault.',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.38),
                                ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.terracotta.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: AppColors.terracotta.withValues(alpha: 0.28),
                        ),
                      ),
                      child: const Text(
                        'LAB',
                        style: TextStyle(
                          color: AppColors.ochre,
                          fontFamily: 'SpaceGrotesk',
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ideasAsync.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.ochre),
                  ),
                  error: (error, _) => _LoadError(message: error.toString()),
                  data: (ideas) => _HomeContent(
                    ideas: ideas,
                    pitches: pitchesAsync.valueOrNull ?? const <PitchModel>[],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeContent extends StatelessWidget {
  final List<IdeaModel> ideas;
  final List<PitchModel> pitches;

  const _HomeContent({
    required this.ideas,
    required this.pitches,
  });

  @override
  Widget build(BuildContext context) {
    final active =
        ideas.where((idea) => idea.status == IdeaStatus.active).length;
    final review = ideas
        .where((idea) => {
              IdeaStatus.processing,
              IdeaStatus.pendingReview,
              IdeaStatus.needsReview,
              IdeaStatus.flagged,
            }.contains(idea.status))
        .length;
    final pendingRequests =
        pitches.where((pitch) => pitch.status == PitchStatus.pending).length;
    final soldValue = ideas
        .where((idea) => idea.status == IdeaStatus.sold)
        .fold<int>(0, (total, idea) => total + idea.price);

    return ListView(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 112),
      children: [
        _CommandLine(pendingRequests: pendingRequests),
        const SizedBox(height: 34),
        const _SectionKicker(label: 'MARKET HEATMAP.'),
        const SizedBox(height: 10),
        _MetricList(
          active: active,
          review: review,
          pendingRequests: pendingRequests,
          soldValue: soldValue,
        ),
        const SizedBox(height: 38),
        const _SectionKicker(label: 'NEXT ACTIONS.'),
        const SizedBox(height: 8),
        _ActionList(
          pendingRequests: pendingRequests,
        ),
      ],
    );
  }
}

class _CommandLine extends StatelessWidget {
  final int pendingRequests;

  const _CommandLine({required this.pendingRequests});

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
                icon: Icons.add_rounded,
                label: 'ADD IDEA',
                onTap: () => context.push('/innovator/submit'),
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
                label: 'REQUESTS $pendingRequests',
                onTap: () => context.go('/notifications'),
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

class _SectionKicker extends StatelessWidget {
  final String label;

  const _SectionKicker({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        color: AppColors.patinaTeal.withValues(alpha: 0.8),
        fontFamily: 'SpaceGrotesk',
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 3.2,
      ),
    );
  }
}

class _MetricList extends StatelessWidget {
  final int active;
  final int review;
  final int pendingRequests;
  final int soldValue;

  const _MetricList({
    required this.active,
    required this.review,
    required this.pendingRequests,
    required this.soldValue,
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
          _MetricRow(label: 'LIVE IN VAULT', value: '$active'),
          const _ThinDivider(),
          _MetricRow(label: 'UNDER REVIEW', value: '$review'),
          const _ThinDivider(),
          _MetricRow(label: 'REQUESTS', value: '$pendingRequests'),
          const _ThinDivider(),
          _MetricRow(
            label: 'SOLD VALUE',
            value: '\$${(soldValue / 100).toStringAsFixed(0)}',
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

class _ActionList extends StatelessWidget {
  final int pendingRequests;

  const _ActionList({required this.pendingRequests});

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
          _ActionRow(
            title: 'ADD IDEA',
            body: 'Capture a new concept',
            onTap: () => context.push('/innovator/submit'),
          ),
          const _ThinDivider(),
          _ActionRow(
            title: 'REVIEW REQUESTS',
            body: pendingRequests > 0
                ? '$pendingRequests Patron request waiting'
                : 'No open requests',
            onTap: () => context.go('/notifications'),
          ),
          const _ThinDivider(),
          _ActionRow(
            title: 'IDEAS',
            body: 'See drafts and live ideas',
            onTap: () => context.go('/ideas'),
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final String title;
  final String body;
  final VoidCallback onTap;

  const _ActionRow({
    required this.title,
    required this.body,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 19),
        child: Row(
          children: [
            SizedBox(
              width: 132,
              child: Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.1,
                ),
              ),
            ),
            Expanded(
              child: Text(
                body,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.42),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 14),
            Icon(
              Icons.arrow_forward_rounded,
              color: AppColors.patinaTeal.withValues(alpha: 0.95),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _ThinDivider extends StatelessWidget {
  const _ThinDivider();

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      color: Colors.white.withValues(alpha: 0.06),
    );
  }
}

class _LoadError extends StatelessWidget {
  final String message;

  const _LoadError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.72)),
        ),
      ),
    );
  }
}

class _InnovatorLabTabBar extends StatelessWidget {
  const _InnovatorLabTabBar();

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: AppColors.labBlack,
      elevation: 0,
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      child: SizedBox(
        height: 68,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _LabTabButton(
              icon: Icons.home_rounded,
              label: 'Dashboard',
              selected: true,
              onTap: () => context.go('/innovator'),
            ),
            _LabTabButton(
              icon: Icons.view_agenda_outlined,
              label: 'Ideas',
              selected: false,
              onTap: () => context.go('/ideas'),
            ),
            const SizedBox(width: 52),
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
