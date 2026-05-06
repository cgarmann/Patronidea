import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../models/idea_model.dart';
import '../../providers/demo_session_provider.dart';
import '../../services/idea_service.dart';
import '../shared/fruma_lab_chrome.dart';

final _ideasScreenProvider = StreamProvider.autoDispose<List<IdeaModel>>((ref) {
  final demo = ref.watch(demoSessionProvider);
  if (demo.active) return Stream.value(demo.myIdeas);
  final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  if (uid.isEmpty) return const Stream.empty();
  return IdeaService().watchMyIdeas(uid);
});

class IdeasScreen extends ConsumerWidget {
  const IdeasScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ideasAsync = ref.watch(_ideasScreenProvider);
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
      bottomNavigationBar: const _IdeasLabTabBar(),
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
                      child: Text(
                        'Ideas',
                        style:
                            Theme.of(context).textTheme.headlineLarge?.copyWith(
                                  color: Colors.white,
                                  fontFamily: 'SpaceGrotesk',
                                  fontSize: 34,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0,
                                ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => context.push('/innovator/submit'),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Add idea'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.ochre,
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
                  error: (error, _) => Center(
                    child: Text(
                      error.toString(),
                      style:
                          TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                    ),
                  ),
                  data: (ideas) {
                    if (ideas.isEmpty) {
                      return const _EmptyIdeasList();
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(22, 0, 22, 112),
                      itemCount: ideas.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 0),
                      itemBuilder: (_, index) =>
                          _IdeaListCard(idea: ideas[index]),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IdeaListCard extends ConsumerWidget {
  final IdeaModel idea;

  const _IdeaListCard({required this.idea});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final demo = ref.watch(demoSessionProvider);
    final date = DateFormat('MMM d').format(idea.createdAt);
    final color = _statusColor(idea.status);

    return InkWell(
      onTap: () {
        if (demo.active && idea.status == IdeaStatus.active) {
          context.go('/vault/idea/${idea.id}');
          return;
        }
        if (demo.active) {
          context.go('/innovator/submit');
          return;
        }
        context.go('/innovator/idea/${idea.id}');
      },
      child: DecoratedBox(
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
              SizedBox(
                width: 82,
                child: Text(
                  idea.statusLabel.toUpperCase(),
                  style: TextStyle(
                    color: color,
                    fontFamily: 'SpaceGrotesk',
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.7,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      idea.title.trim().isEmpty ? 'Untitled idea' : idea.title,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontFamily: 'SpaceGrotesk',
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${idea.category} - $date',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.42),
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_rounded,
                color: AppColors.patinaTeal.withValues(alpha: 0.95),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyIdeasList extends StatelessWidget {
  const _EmptyIdeasList();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.lightbulb_outline_rounded,
                size: 38, color: AppColors.ochre),
            const SizedBox(height: 12),
            Text(
              'No ideas yet',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 180,
              child: FrumaLabButton(
                label: 'New idea',
                onPressed: () => context.push('/innovator/submit'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IdeasLabTabBar extends StatelessWidget {
  const _IdeasLabTabBar();

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
              selected: false,
              onTap: () => context.go('/innovator'),
            ),
            _LabTabButton(
              icon: Icons.view_agenda_outlined,
              label: 'Ideas',
              selected: true,
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

Color _statusColor(IdeaStatus status) {
  return switch (status) {
    IdeaStatus.active => AppColors.patinaTeal,
    IdeaStatus.flagged => AppColors.warning,
    IdeaStatus.sold => AppColors.ochre,
    IdeaStatus.rejected || IdeaStatus.error => AppColors.error,
    IdeaStatus.archived => AppColors.labMuted,
    _ => AppColors.terracotta,
  };
}
