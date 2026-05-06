import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/demo_session_provider.dart';
import '../../providers/theme_provider.dart';
import 'fruma_lab_chrome.dart';

class MainScaffold extends ConsumerWidget {
  final Widget body;
  final String title;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final bool showTabs;

  const MainScaffold({
    super.key,
    required this.body,
    this.title = '',
    this.actions,
    this.floatingActionButton,
    this.showTabs = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.volcanic950,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: title.isEmpty ? null : Text(title),
        actions: [
          ...?actions,
          const _SettingsButton(),
        ],
      ),
      body: FrumaLabBackground(child: body),
      floatingActionButton: floatingActionButton ??
          (showTabs
              ? FloatingActionButton(
                  tooltip: 'New idea',
                  backgroundColor: AppColors.terracotta,
                  foregroundColor: Colors.white,
                  shape: const CircleBorder(),
                  onPressed: () => context.go('/innovator/submit'),
                  child: const Icon(Icons.add_rounded),
                )
              : null),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: showTabs ? const _FrumaTabBar() : null,
    );
  }
}

class _FrumaTabBar extends ConsumerWidget {
  const _FrumaTabBar();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final location = GoRouterState.of(context).matchedLocation;
    final selected = _selectedIndex(location);
    final demo = ref.watch(demoSessionProvider);
    final dashboardTarget =
        demo.active && demo.role == DemoRole.patron ? '/patron' : '/innovator';
    final ideasTarget =
        demo.active && demo.role == DemoRole.patron ? '/vault' : '/ideas';

    return BottomAppBar(
      color: AppColors.labBlack,
      elevation: 0,
      shadowColor: Colors.transparent,
      shape: const CircularNotchedRectangle(),
      notchMargin: 7,
      child: SizedBox(
        height: 66,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _TabButton(
              icon: Icons.home_rounded,
              label: 'Dashboard',
              selected: selected == 0,
              onTap: () => context.go(dashboardTarget),
            ),
            _TabButton(
              icon: Icons.view_agenda_outlined,
              label: 'Ideas',
              selected: selected == 1,
              onTap: () => context.go(ideasTarget),
            ),
            const SizedBox(width: 52),
            _TabButton(
              icon: Icons.notifications_none_rounded,
              label: 'Alerts',
              selected: selected == 3,
              onTap: () => context.go('/notifications'),
            ),
            _TabButton(
              icon: Icons.person_outline_rounded,
              label: 'Profile',
              selected: selected == 4,
              onTap: () => context.go('/profile'),
            ),
          ],
        ),
      ),
    );
  }

  int _selectedIndex(String location) {
    if (location.startsWith('/notifications')) return 3;
    if (location.startsWith('/profile')) return 4;
    if (location.startsWith('/ideas')) return 1;
    if (location.startsWith('/innovator')) return 0;
    if (location.startsWith('/patron')) return 0;
    if (location.startsWith('/vault')) return 1;
    return 0;
  }
}

class _TabButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabButton({
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
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                    fontFamily: 'SpaceGrotesk',
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  ),
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsButton extends ConsumerWidget {
  const _SettingsButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      icon: const Icon(Icons.settings_outlined),
      tooltip: 'Account',
      onPressed: () => _openSheet(context),
    );
  }

  void _openSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.labPanel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      useSafeArea: true,
      builder: (_) => const _SettingsSheet(),
    );
  }
}

class _SettingsSheet extends ConsumerWidget {
  const _SettingsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(themeProvider) == ThemeMode.dark;
    final demo = ref.watch(demoSessionProvider);
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text('FRUMA', style: theme.textTheme.titleLarge),
            if (demo.active) ...[
              const SizedBox(height: 4),
              Text(
                'Demo mode: ${demo.role.label}',
                style:
                    theme.textTheme.bodySmall?.copyWith(color: AppColors.ochre),
              ),
            ],
            const SizedBox(height: 12),
            const _SheetSectionHeader('Account'),
            _SheetItem(
              icon: Icons.person_outline_rounded,
              label: 'Profile',
              onTap: () {
                Navigator.pop(context);
                context.go('/profile');
              },
            ),
            _SheetItem(
              icon: Icons.card_membership_rounded,
              label: 'Subscription',
              onTap: () {
                Navigator.pop(context);
                context.go('/paywall');
              },
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: isDark,
              onChanged: (_) => ref.read(themeProvider.notifier).toggle(),
              secondary: Icon(
                isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                size: 20,
                color: Colors.white.withValues(alpha: 0.56),
              ),
              title: Text(
                isDark ? 'Dark mode' : 'Light mode',
                style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white, fontWeight: FontWeight.w600),
              ),
              activeColor: AppColors.ochre,
            ),
            const SizedBox(height: 8),
            const _SheetSectionHeader('Navigation'),
            if (!demo.active || demo.role == DemoRole.patron)
              _SheetItem(
                icon: Icons.diamond_outlined,
                label: 'Vault',
                onTap: () {
                  Navigator.pop(context);
                  context.go('/vault');
                },
              ),
            if (demo.active)
              _SheetItem(
                icon: Icons.swap_horiz_rounded,
                label: demo.role == DemoRole.patron
                    ? 'Switch to Innovator demo'
                    : 'Switch to Patron demo',
                onTap: () {
                  final next = demo.role == DemoRole.patron
                      ? DemoRole.innovator
                      : DemoRole.patron;
                  Navigator.pop(context);
                  ref.read(demoSessionProvider.notifier).switchTo(next);
                  context
                      .go(next == DemoRole.patron ? '/patron' : '/innovator');
                },
              ),
            const SizedBox(height: 8),
            if (demo.active) ...[
              const _SheetSectionHeader('Demo'),
              _SheetItem(
                icon: Icons.logout_rounded,
                label: 'Exit demo',
                color: AppColors.error,
                onTap: () {
                  Navigator.pop(context);
                  ref.read(demoSessionProvider.notifier).exit();
                  context.go('/');
                },
              ),
            ] else ...[
              const Divider(height: 24),
              Center(
                child: TextButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    await ref.read(authServiceProvider).signOut();
                    if (context.mounted) context.go('/');
                  },
                  style: TextButton.styleFrom(foregroundColor: AppColors.error),
                  child: const Text('Sign out'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SheetItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _SheetItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, size: 20, color: color ?? AppColors.ochre),
      title: Text(
        label,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: color ?? Colors.white.withValues(alpha: 0.86),
          fontWeight: FontWeight.w600,
        ),
      ),
      onTap: onTap,
    );
  }
}

class _SheetSectionHeader extends StatelessWidget {
  final String label;

  const _SheetSectionHeader(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 2),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: AppColors.patinaTeal,
              fontWeight: FontWeight.w900,
              fontFamily: 'SpaceGrotesk',
              letterSpacing: 1.4,
            ),
      ),
    );
  }
}
