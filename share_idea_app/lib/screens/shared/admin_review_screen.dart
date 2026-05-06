import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../models/idea_model.dart';
import '../../models/idea_report_model.dart';
import '../../models/user_model.dart';
import '../../providers/demo_session_provider.dart';
import '../../services/admin_service.dart';
import 'loading_overlay.dart';

class AdminReviewScreen extends ConsumerStatefulWidget {
  const AdminReviewScreen({super.key});

  @override
  ConsumerState<AdminReviewScreen> createState() => _AdminReviewScreenState();
}

class _AdminReviewScreenState extends ConsumerState<AdminReviewScreen> {
  final _service = AdminService();
  late final Future<bool> _adminCheck = _isCurrentUserAdmin();
  bool _acting = false;

  Future<bool> _isCurrentUserAdmin() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    final token = await user.getIdTokenResult();
    if (token.claims?['admin'] == true) return true;
    final doc = await FirebaseFirestore.instance
        .collection('admins')
        .doc(user.uid)
        .get();
    return doc.exists && doc.data()?['active'] != false;
  }

  Future<void> _approveOrKeep(IdeaModel idea) async {
    if (_isDemoAdmin) {
      await _run(
        () async => ref.read(demoSessionProvider.notifier).resolveIdeaForAdmin(
              ideaId: idea.id,
              resolution: 'keep',
            ),
      );
      return;
    }

    await _run(() {
      if (idea.status == IdeaStatus.flagged) {
        return _service.resolveIdeaReport(
          ideaId: idea.id,
          resolution: 'keep',
        );
      }
      return _service.approveIdea(idea.id);
    });
  }

  Future<void> _requestEdit(IdeaModel idea) async {
    final ctrl = TextEditingController(text: idea.reviewNote ?? '');
    final note = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Request edit'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          minLines: 3,
          maxLines: 6,
          decoration: const InputDecoration(
            hintText: 'What should the innovator change?',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Send'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (note == null || note.isEmpty) return;

    if (_isDemoAdmin) {
      await _run(
        () async => ref.read(demoSessionProvider.notifier).resolveIdeaForAdmin(
              ideaId: idea.id,
              resolution: 'request_edit',
              reviewNote: note,
            ),
      );
      return;
    }

    await _run(() {
      if (idea.status == IdeaStatus.flagged) {
        return _service.resolveIdeaReport(
          ideaId: idea.id,
          resolution: 'request_edit',
          reviewNote: note,
        );
      }
      return _service.requestIdeaEdit(idea.id, note);
    });
  }

  Future<void> _rejectIdea(IdeaModel idea) async {
    if (_isDemoAdmin) {
      await _run(
        () async => ref.read(demoSessionProvider.notifier).resolveIdeaForAdmin(
              ideaId: idea.id,
              resolution: 'reject',
              reviewNote: 'Rejected during demo admin review.',
            ),
      );
      return;
    }

    await _run(() {
      if (idea.status == IdeaStatus.flagged) {
        return _service.resolveIdeaReport(
          ideaId: idea.id,
          resolution: 'reject',
          reviewNote: 'Rejected after patron report review.',
        );
      }
      return _service.rejectIdea(
        idea.id,
        reviewNote: 'Rejected during admin review.',
      );
    });
  }

  Future<void> _moderateUser(UserModel user, AccountStatus status) async {
    if (_isDemoAdmin) {
      await _run(
        () async => ref.read(demoSessionProvider.notifier).moderateDemoUser(
              uid: user.uid,
              accountStatus: status,
            ),
      );
      return;
    }

    await _run(() => _service.moderateUser(
          uid: user.uid,
          accountStatus: status,
        ));
  }

  bool get _isDemoAdmin {
    final demo = ref.read(demoSessionProvider);
    return demo.active && demo.role == DemoRole.admin;
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _acting = true);
    try {
      await action();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Admin action saved.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final demo = ref.watch(demoSessionProvider);
    if (demo.active && demo.role == DemoRole.admin) {
      return LoadingOverlay(
        isLoading: _acting,
        child: _buildAdminTabs(
          ideaQueueStream: Stream.value(demo.adminIdeaQueue),
          reportQueueStream: Stream.value(demo.adminReportQueue),
          usersStream: Stream.value(demo.adminUsers),
          reportStatsStream: Stream.value(demo.adminReportStats),
          title: 'Reporting & Admin Demo',
        ),
      );
    }

    return LoadingOverlay(
      isLoading: _acting,
      child: FutureBuilder<bool>(
        future: _adminCheck,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: AppColors.labAccent),
              ),
            );
          }
          if (snapshot.data != true) {
            return Scaffold(
              appBar: AppBar(
                title: const Text('Admin'),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_rounded),
                  onPressed: () =>
                      context.canPop() ? context.pop() : context.go('/'),
                ),
              ),
              body: const Center(child: Text('Admin access required.')),
            );
          }

          return _buildAdminTabs(
            ideaQueueStream: _service.watchIdeaQueue(),
            reportQueueStream: _service.watchReportQueue(),
            usersStream: _service.watchUsers(),
            reportStatsStream: _service.watchReportStats(),
          );
        },
      ),
    );
  }

  Widget _buildAdminTabs({
    required Stream<List<IdeaModel>> ideaQueueStream,
    required Stream<List<IdeaModel>> reportQueueStream,
    required Stream<List<UserModel>> usersStream,
    required Stream<List<ReportStatsModel>> reportStatsStream,
    String title = 'Reporting & Admin',
  }) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: Text(title),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_rounded),
            onPressed: () =>
                context.canPop() ? context.pop() : context.go('/admin'),
          ),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Idea queue'),
              Tab(text: 'Report queue'),
              Tab(text: 'Users'),
              Tab(text: 'Report history'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _QueueTab(
              stream: ideaQueueStream,
              emptyText: 'No ideas pending manual review.',
              onApprove: _approveOrKeep,
              onRequestEdit: _requestEdit,
              onReject: _rejectIdea,
            ),
            _QueueTab(
              stream: reportQueueStream,
              emptyText: 'No flagged ideas in the report queue.',
              onApprove: _approveOrKeep,
              onRequestEdit: _requestEdit,
              onReject: _rejectIdea,
            ),
            _UserOverviewTab(
              stream: usersStream,
              onModerate: _moderateUser,
            ),
            _ReportHistoryTab(stream: reportStatsStream),
          ],
        ),
      ),
    );
  }
}

class _QueueTab extends StatelessWidget {
  final Stream<List<IdeaModel>> stream;
  final String emptyText;
  final ValueChanged<IdeaModel> onApprove;
  final ValueChanged<IdeaModel> onRequestEdit;
  final ValueChanged<IdeaModel> onReject;

  const _QueueTab({
    required this.stream,
    required this.emptyText,
    required this.onApprove,
    required this.onRequestEdit,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<IdeaModel>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.labAccent),
          );
        }
        if (snapshot.hasError) {
          return const _AdminEmptyState(
            message: 'Queue unavailable. Admin access is required.',
          );
        }
        final ideas = snapshot.data ?? const [];
        if (ideas.isEmpty) return _AdminEmptyState(message: emptyText);
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: ideas.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, index) => _IdeaReviewCard(
            idea: ideas[index],
            onApprove: () => onApprove(ideas[index]),
            onRequestEdit: () => onRequestEdit(ideas[index]),
            onReject: () => onReject(ideas[index]),
          ),
        );
      },
    );
  }
}

class _IdeaReviewCard extends StatelessWidget {
  final IdeaModel idea;
  final VoidCallback onApprove;
  final VoidCallback onRequestEdit;
  final VoidCallback onReject;

  const _IdeaReviewCard({
    required this.idea,
    required this.onApprove,
    required this.onRequestEdit,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final duplicateScore = (idea.matchScore * 100).clamp(0, 100).round();
    final isFlagged = idea.status == IdeaStatus.flagged;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    idea.title.trim().isEmpty ? 'Untitled idea' : idea.title,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                _AdminTag(
                  label: idea.statusLabel,
                  color: isFlagged ? AppColors.warning : AppColors.patinaTeal,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              idea.body.isEmpty ? idea.rawCapture : idea.body,
              style: theme.textTheme.bodySmall,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _AdminTag(
                  label: idea.category.isEmpty ? 'No category' : idea.category,
                ),
                _AdminTag(label: 'IIAE duplicate $duplicateScore%'),
                _AdminTag(label: '${idea.uniquenessScore}% unique'),
                if (isFlagged)
                  _AdminTag(
                    label: '${idea.openReportCount} open report(s)',
                    color: AppColors.warning,
                  ),
              ],
            ),
            if (idea.lastReportReasonLabel?.isNotEmpty == true) ...[
              const SizedBox(height: 10),
              _ContextLine(
                icon: Icons.flag_outlined,
                text: idea.lastReportReasonLabel!,
                color: AppColors.warning,
              ),
            ],
            if (idea.reviewNote?.isNotEmpty == true) ...[
              const SizedBox(height: 10),
              _ContextLine(
                icon: Icons.info_outline_rounded,
                text: idea.reviewNote!,
                color: AppColors.warning,
              ),
            ],
            const SizedBox(height: 14),
            OverflowBar(
              spacing: 8,
              overflowSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: onRequestEdit,
                  icon: const Icon(Icons.edit_note_rounded, size: 18),
                  label: const Text('Request edit'),
                ),
                OutlinedButton.icon(
                  onPressed: onReject,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
                  ),
                  icon: const Icon(Icons.block_rounded, size: 18),
                  label: const Text('Reject'),
                ),
                ElevatedButton.icon(
                  onPressed: onApprove,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isFlagged ? AppColors.success : AppColors.patinaTeal,
                  ),
                  icon: Icon(
                    isFlagged ? Icons.visibility_rounded : Icons.check_rounded,
                    size: 18,
                  ),
                  label: Text(isFlagged ? 'Keep' : 'Approve'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _UserOverviewTab extends StatelessWidget {
  final Stream<List<UserModel>> stream;
  final Future<void> Function(UserModel user, AccountStatus status) onModerate;

  const _UserOverviewTab({
    required this.stream,
    required this.onModerate,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<UserModel>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.labAccent),
          );
        }
        if (snapshot.hasError) {
          return const _AdminEmptyState(
            message: 'Users unavailable. Admin access is required.',
          );
        }
        final users = snapshot.data ?? const [];
        if (users.isEmpty) {
          return const _AdminEmptyState(message: 'No users found.');
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, index) => _UserCard(
            user: users[index],
            onModerate: onModerate,
          ),
        );
      },
    );
  }
}

class _UserCard extends StatelessWidget {
  final UserModel user;
  final Future<void> Function(UserModel user, AccountStatus status) onModerate;

  const _UserCard({
    required this.user,
    required this.onModerate,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusColor = switch (user.accountStatus) {
      AccountStatus.active => AppColors.success,
      AccountStatus.suspended => AppColors.warning,
      AccountStatus.banned => AppColors.error,
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    user.displayName.isEmpty ? user.email : user.displayName,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                _AdminTag(label: user.accountStatus.name, color: statusColor),
              ],
            ),
            const SizedBox(height: 4),
            Text(user.email, style: theme.textTheme.bodySmall),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _AdminTag(label: user.role.name),
                _AdminTag(label: '${user.totalReports} reports'),
                _AdminTag(label: '${user.falseReports} false'),
                if (user.reportReviewFlag)
                  const _AdminTag(
                    label: 'review flagged',
                    color: AppColors.warning,
                  ),
              ],
            ),
            const SizedBox(height: 14),
            OverflowBar(
              spacing: 8,
              overflowSpacing: 8,
              children: [
                if (user.accountStatus != AccountStatus.active)
                  ElevatedButton.icon(
                    onPressed: () => onModerate(user, AccountStatus.active),
                    icon: const Icon(Icons.check_circle_outline_rounded,
                        size: 18),
                    label: const Text('Reactivate'),
                  ),
                if (user.accountStatus == AccountStatus.active)
                  OutlinedButton.icon(
                    onPressed: () => onModerate(user, AccountStatus.suspended),
                    icon: const Icon(Icons.pause_circle_outline_rounded,
                        size: 18),
                    label: const Text('Suspend'),
                  ),
                if (user.accountStatus != AccountStatus.banned)
                  OutlinedButton.icon(
                    onPressed: () => onModerate(user, AccountStatus.banned),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.error,
                      side: const BorderSide(color: AppColors.error),
                    ),
                    icon: const Icon(Icons.gavel_rounded, size: 18),
                    label: const Text('Ban'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ReportHistoryTab extends StatelessWidget {
  final Stream<List<ReportStatsModel>> stream;

  const _ReportHistoryTab({required this.stream});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ReportStatsModel>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.labAccent),
          );
        }
        if (snapshot.hasError) {
          return const _AdminEmptyState(message: 'Report history unavailable.');
        }
        final stats = snapshot.data ?? const [];
        if (stats.isEmpty) {
          return const _AdminEmptyState(
              message: 'No patron report history yet.');
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: stats.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (_, index) => _ReportStatsCard(stats: stats[index]),
        );
      },
    );
  }
}

class _ReportStatsCard extends StatelessWidget {
  final ReportStatsModel stats;

  const _ReportStatsCard({required this.stats});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final latest = stats.lastReportAt == null
        ? 'No date'
        : DateFormat('MMM d, yyyy').format(stats.lastReportAt!);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    stats.patronId,
                    style: theme.textTheme.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (stats.accountReviewFlag)
                  const _AdminTag(
                    label: 'admin review',
                    color: AppColors.warning,
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _AdminTag(label: '${stats.totalReports} total'),
                _AdminTag(label: '${stats.openReports} open'),
                _AdminTag(label: '${stats.validReports} valid'),
                _AdminTag(label: '${stats.falseReports} false'),
                _AdminTag(label: 'latest $latest'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ContextLine extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _ContextLine({
    required this.icon,
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style:
                Theme.of(context).textTheme.bodySmall?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}

class _AdminTag extends StatelessWidget {
  final String label;
  final Color? color;

  const _AdminTag({
    required this.label,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final resolved = color ?? AppColors.labMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: resolved.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: resolved,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

class _AdminEmptyState extends StatelessWidget {
  final String message;

  const _AdminEmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
