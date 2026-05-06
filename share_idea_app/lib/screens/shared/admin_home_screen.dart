import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../models/idea_model.dart';
import '../../models/idea_report_model.dart';
import '../../models/user_model.dart';
import '../../providers/demo_session_provider.dart';
import '../../services/admin_service.dart';
import 'fruma_lab_chrome.dart';

final _adminHomeAccessProvider = FutureProvider.autoDispose<bool>((ref) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return false;
  final token = await user.getIdTokenResult();
  if (token.claims?['admin'] == true) return true;
  final doc =
      await FirebaseFirestore.instance.collection('admins').doc(user.uid).get();
  return doc.exists && doc.data()?['active'] != false;
});

final _adminIdeaQueueProvider =
    StreamProvider.autoDispose<List<IdeaModel>>((ref) {
  return AdminService().watchIdeaQueue();
});

final _adminReportQueueProvider =
    StreamProvider.autoDispose<List<IdeaModel>>((ref) {
  return AdminService().watchReportQueue();
});

final _adminUsersProvider = StreamProvider.autoDispose<List<UserModel>>((ref) {
  return AdminService().watchUsers();
});

final _adminReportStatsProvider =
    StreamProvider.autoDispose<List<ReportStatsModel>>((ref) {
  return AdminService().watchReportStats();
});

class AdminHomeScreen extends ConsumerWidget {
  const AdminHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final demo = ref.watch(demoSessionProvider);
    if (demo.active && demo.role == DemoRole.admin) {
      return _AdminHomeBody(
        ideaQueue: demo.adminIdeaQueue,
        reportQueue: demo.adminReportQueue,
        users: demo.adminUsers,
        reportStats: demo.adminReportStats,
        demoMode: true,
      );
    }

    final access = ref.watch(_adminHomeAccessProvider);

    return access.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.volcanic950,
        body: Center(child: CircularProgressIndicator(color: AppColors.ochre)),
      ),
      error: (_, __) => const _AdminAccessDenied(),
      data: (allowed) {
        if (!allowed) return const _AdminAccessDenied();

        final ideaQueue = ref.watch(_adminIdeaQueueProvider).valueOrNull ??
            const <IdeaModel>[];
        final reportQueue = ref.watch(_adminReportQueueProvider).valueOrNull ??
            const <IdeaModel>[];
        final users =
            ref.watch(_adminUsersProvider).valueOrNull ?? const <UserModel>[];
        final reportStats = ref.watch(_adminReportStatsProvider).valueOrNull ??
            const <ReportStatsModel>[];
        return _AdminHomeBody(
          ideaQueue: ideaQueue,
          reportQueue: reportQueue,
          users: users,
          reportStats: reportStats,
        );
      },
    );
  }
}

class _AdminHomeBody extends StatelessWidget {
  final List<IdeaModel> ideaQueue;
  final List<IdeaModel> reportQueue;
  final List<UserModel> users;
  final List<ReportStatsModel> reportStats;
  final bool demoMode;

  const _AdminHomeBody({
    required this.ideaQueue,
    required this.reportQueue,
    required this.users,
    required this.reportStats,
    this.demoMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final flaggedUsers = users
        .where((user) =>
            user.reportReviewFlag ||
            user.accountStatus == AccountStatus.suspended ||
            user.accountStatus == AccountStatus.banned)
        .length;
    final falseReports = reportStats.fold<int>(
      0,
      (total, stats) => total + stats.falseReports,
    );

    return Scaffold(
      backgroundColor: AppColors.volcanic950,
      body: FrumaLabBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 34),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Admin Home',
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
                  if (demoMode) ...[
                    const _DemoAdminTag(),
                    const SizedBox(width: 6),
                  ],
                  if (!demoMode)
                    IconButton(
                      tooltip: 'Profile',
                      onPressed: () => context.go('/profile'),
                      icon: Icon(
                        Icons.settings_outlined,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                'Manual review, reports and account risk in one place.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.38),
                    ),
              ),
              const SizedBox(height: 24),
              _AdminCommandLine(
                onReview: () => context.go('/admin/review'),
                onUsers: () => context.go('/admin/review'),
              ),
              const SizedBox(height: 34),
              const FrumaSectionLabel(label: 'CONTROL ROOM.'),
              const SizedBox(height: 10),
              _AdminMetricList(
                ideaQueue: ideaQueue.length,
                reportQueue: reportQueue.length,
                users: users.length,
                flaggedUsers: flaggedUsers,
                falseReports: falseReports,
              ),
              const SizedBox(height: 38),
              const FrumaSectionLabel(label: 'ADMIN ACTIONS.'),
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
                      icon: Icons.fact_check_outlined,
                      title: 'Review',
                      body: 'Open idea and report queues',
                      onTap: () => context.go('/admin/review'),
                    ),
                    const FrumaThinDivider(),
                    FrumaActionRow(
                      icon: Icons.flag_outlined,
                      title: 'Reports',
                      body: '${reportQueue.length} flagged idea(s)',
                      onTap: () => context.go('/admin/review'),
                    ),
                    const FrumaThinDivider(),
                    FrumaActionRow(
                      icon: Icons.manage_accounts_outlined,
                      title: 'Users',
                      body: '$flaggedUsers account(s) need attention',
                      onTap: () => context.go('/admin/review'),
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

class _DemoAdminTag extends StatelessWidget {
  const _DemoAdminTag();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.ochre.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.ochre.withValues(alpha: 0.42)),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        child: Text(
          'DEMO',
          style: TextStyle(
            color: AppColors.ochre,
            fontFamily: 'SpaceGrotesk',
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.8,
          ),
        ),
      ),
    );
  }
}

class _AdminAccessDenied extends StatelessWidget {
  const _AdminAccessDenied();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Admin access required.'),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => context.go('/admin/demo'),
              icon: const Icon(Icons.admin_panel_settings_outlined),
              label: const Text('Open admin demo'),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminCommandLine extends StatelessWidget {
  final VoidCallback onReview;
  final VoidCallback onUsers;

  const _AdminCommandLine({
    required this.onReview,
    required this.onUsers,
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
                icon: Icons.fact_check_outlined,
                label: 'REVIEW',
                onTap: onReview,
              ),
            ),
            Container(
              width: 1,
              height: 32,
              color: Colors.white.withValues(alpha: 0.08),
            ),
            Expanded(
              child: _CommandButton(
                icon: Icons.manage_accounts_outlined,
                label: 'USERS',
                onTap: onUsers,
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

class _AdminMetricList extends StatelessWidget {
  final int ideaQueue;
  final int reportQueue;
  final int users;
  final int flaggedUsers;
  final int falseReports;

  const _AdminMetricList({
    required this.ideaQueue,
    required this.reportQueue,
    required this.users,
    required this.flaggedUsers,
    required this.falseReports,
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
          _MetricRow(label: 'IDEA QUEUE', value: '$ideaQueue'),
          const FrumaThinDivider(),
          _MetricRow(
            label: 'REPORT QUEUE',
            value: '$reportQueue',
            accent: AppColors.warning,
          ),
          const FrumaThinDivider(),
          _MetricRow(label: 'USERS', value: '$users'),
          const FrumaThinDivider(),
          _MetricRow(
            label: 'ACCOUNT RISK',
            value: '$flaggedUsers',
            accent: flaggedUsers > 0 ? AppColors.error : AppColors.patinaTeal,
          ),
          const FrumaThinDivider(),
          _MetricRow(
            label: 'FALSE REPORTS',
            value: '$falseReports',
            accent: falseReports > 0 ? AppColors.warning : AppColors.patinaTeal,
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
