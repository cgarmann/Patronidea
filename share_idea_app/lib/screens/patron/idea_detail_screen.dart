import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../models/idea_model.dart';
import '../../models/idea_report_model.dart';
import '../../models/pitch_model.dart';
import '../../providers/demo_session_provider.dart';
import '../../services/idea_service.dart';
import '../../services/pitch_service.dart';
import '../shared/fruma_lab_chrome.dart';
import '../shared/loading_overlay.dart';

class IdeaDetailScreen extends ConsumerStatefulWidget {
  final String ideaId;
  const IdeaDetailScreen({super.key, required this.ideaId});

  @override
  ConsumerState<IdeaDetailScreen> createState() => _IdeaDetailScreenState();
}

class _IdeaDetailScreenState extends ConsumerState<IdeaDetailScreen> {
  final _pitchService = PitchService();
  final _ideaService = IdeaService();

  IdeaModel? _idea;
  PitchModel? _existingRequest;
  bool _loading = true;
  bool _acting = false;
  bool _favorite = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final demo = ref.read(demoSessionProvider);
      if (demo.active) {
        final idea = demo.ideaById(widget.ideaId);
        if (!mounted) return;
        setState(() {
          _idea = idea;
          _existingRequest = demo.requestForIdea(widget.ideaId);
          _favorite = demo.favoriteIdeaIds.contains(widget.ideaId);
          _loading = false;
          _error = idea == null ? 'Demo idea not found.' : null;
        });
        return;
      }

      final results = await Future.wait([
        _ideaService.getIdea(widget.ideaId),
        _findExistingRequest(),
      ]);
      if (!mounted) return;
      setState(() {
        _idea = results[0] as IdeaModel;
        _existingRequest = results[1] as PitchModel?;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<PitchModel?> _findExistingRequest() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    final snap = await FirebaseFirestore.instance
        .collection('pitches')
        .where('ideaId', isEqualTo: widget.ideaId)
        .where('patronId', isEqualTo: uid)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return PitchModel.fromFirestore(snap.docs.first);
  }

  Future<void> _sendRequest() async {
    final messageCtrl = TextEditingController();
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.labPanel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          24,
          24,
          MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Send request',
              style: Theme.of(ctx)
                  .textTheme
                  .titleLarge
                  ?.copyWith(color: Colors.white, fontFamily: 'SpaceGrotesk'),
            ),
            const SizedBox(height: 6),
            Text(
              'The innovator has 7 days to accept, decline or ask for more info.',
              style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.45),
                  ),
            ),
            const SizedBox(height: 18),
            TextField(
              controller: messageCtrl,
              style: const TextStyle(color: Colors.white),
              minLines: 4,
              maxLines: 6,
              decoration: const InputDecoration(
                hintText: 'Company, intent and why this idea is relevant...',
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FrumaLabButton(
                label: 'Send request',
                onPressed: () => Navigator.pop(ctx, true),
              ),
            ),
          ],
        ),
      ),
    );

    if (confirmed != true) return;
    setState(() => _acting = true);
    try {
      final demo = ref.read(demoSessionProvider);
      if (demo.active) {
        ref.read(demoSessionProvider.notifier).requestPitch(
              ideaId: widget.ideaId,
              message: messageCtrl.text.trim(),
            );
        await _load();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Demo request accepted. Deal Room is open.'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      await _pitchService.requestPitch(
        ideaId: widget.ideaId,
        message: messageCtrl.text.trim(),
      );
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Request sent.'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  Future<void> _reportIdea() async {
    final input = await showModalBottomSheet<_IdeaReportInput>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.labPanel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (_) => const _ReportIdeaSheet(),
    );
    if (input == null) return;

    setState(() => _acting = true);
    try {
      final demo = ref.read(demoSessionProvider);
      if (!demo.active) {
        await _ideaService.reportIdea(
          ideaId: widget.ideaId,
          reason: input.reason,
          details: input.details,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Report sent for manual review.'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _acting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final idea = _idea;
    final demo = ref.watch(demoSessionProvider);
    final favorite = demo.active && idea != null
        ? demo.favoriteIdeaIds.contains(idea.id)
        : _favorite;
    return LoadingOverlay(
      isLoading: _acting,
      child: Scaffold(
        backgroundColor: AppColors.volcanic950,
        body: _loading
            ? const FrumaLabBackground(
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.ochre),
                ),
              )
            : _error != null
                ? FrumaLabBackground(child: _ErrorView(message: _error!))
                : idea == null
                    ? const SizedBox.shrink()
                    : FrumaLabBackground(
                        intensity: 0.78,
                        child: SafeArea(
                          child: Column(
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(12, 8, 12, 4),
                                child: Row(
                                  children: [
                                    FrumaBackButton(
                                      onPressed: () => context.canPop()
                                          ? context.pop()
                                          : context.go('/vault'),
                                    ),
                                    const Spacer(),
                                    IconButton(
                                      tooltip: 'Report idea',
                                      onPressed: _reportIdea,
                                      icon: Icon(
                                        Icons.flag_outlined,
                                        color: Colors.white
                                            .withValues(alpha: 0.78),
                                      ),
                                    ),
                                    FavoriteButton(
                                      selected: favorite,
                                      onTap: () {
                                        if (demo.active) {
                                          ref
                                              .read(
                                                  demoSessionProvider.notifier)
                                              .toggleFavorite(idea.id);
                                          return;
                                        }
                                        setState(() => _favorite = !_favorite);
                                      },
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(child: _DetailBody(idea: idea)),
                            ],
                          ),
                        ),
                      ),
        bottomNavigationBar: idea == null || _loading || _error != null
            ? null
            : StickyBottomCTA(
                request: _existingRequest,
                onSendRequest: _sendRequest,
              ),
      ),
    );
  }
}

class _IdeaReportInput {
  final IdeaReportReason reason;
  final String details;

  const _IdeaReportInput({
    required this.reason,
    required this.details,
  });
}

class _ReportIdeaSheet extends StatefulWidget {
  const _ReportIdeaSheet();

  @override
  State<_ReportIdeaSheet> createState() => _ReportIdeaSheetState();
}

class _ReportIdeaSheetState extends State<_ReportIdeaSheet> {
  final _detailsCtrl = TextEditingController();
  IdeaReportReason? _reason;

  @override
  void dispose() {
    _detailsCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        18,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Report idea',
              style: theme.textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontFamily: 'SpaceGrotesk',
              ),
            ),
            const SizedBox(height: 14),
            for (final reason in IdeaReportReason.values)
              RadioListTile<IdeaReportReason>(
                contentPadding: EdgeInsets.zero,
                activeColor: AppColors.ochre,
                value: reason,
                groupValue: _reason,
                onChanged: (value) => setState(() => _reason = value),
                title: Text(
                  reason.label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.86),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            TextField(
              controller: _detailsCtrl,
              style: const TextStyle(color: Colors.white),
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Optional context for admin review',
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FrumaLabButton(
                label: 'Submit report',
                onPressed: _reason == null
                    ? null
                    : () => Navigator.pop(
                          context,
                          _IdeaReportInput(
                            reason: _reason!,
                            details: _detailsCtrl.text.trim(),
                          ),
                        ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FavoriteButton extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;

  const FavoriteButton({
    super.key,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: selected ? 'Remove favorite' : 'Favorite',
      onPressed: onTap,
      icon: Icon(
        selected ? Icons.favorite_rounded : Icons.favorite_border_rounded,
        color:
            selected ? AppColors.error : Colors.white.withValues(alpha: 0.78),
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  final IdeaModel idea;

  const _DetailBody({required this.idea});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 116),
      children: [
        const FrumaSectionLabel(label: 'OPPORTUNITY.'),
        const SizedBox(height: 12),
        IdeaHeader(title: idea.title),
        const SizedBox(height: 14),
        IdeaMetadataChips(idea: idea),
        const SizedBox(height: 24),
        DescriptionSection(description: idea.body),
        const SizedBox(height: 22),
        InnovatorProfileSection(idea: idea),
        const SizedBox(height: 18),
        MetadataSection(idea: idea),
      ],
    );
  }
}

class IdeaHeader extends StatelessWidget {
  final String title;

  const IdeaHeader({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      title.trim().isEmpty ? 'Untitled idea' : title,
      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            color: Colors.white,
            fontFamily: 'SpaceGrotesk',
            fontSize: 36,
            fontWeight: FontWeight.w500,
            height: 1.14,
            letterSpacing: 0,
          ),
    );
  }
}

class IdeaMetadataChips extends StatelessWidget {
  final IdeaModel idea;

  const IdeaMetadataChips({
    super.key,
    required this.idea,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _Chip(label: idea.category, color: AppColors.green),
        _Chip(label: _typeFor(idea), color: AppColors.blue),
        _Chip(label: idea.geographicScope, color: AppColors.teal),
      ],
    );
  }
}

class DescriptionSection extends StatelessWidget {
  final String description;

  const DescriptionSection({
    super.key,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return _Section(
      title: 'Description',
      child: Text(
        description.trim().isEmpty ? 'No description provided.' : description,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: Colors.white.withValues(alpha: 0.74),
          height: 1.55,
        ),
      ),
    );
  }
}

class InnovatorProfileSection extends StatelessWidget {
  final IdeaModel idea;

  const InnovatorProfileSection({
    super.key,
    required this.idea,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initial = idea.innovatorProfession.trim().isEmpty
        ? 'I'
        : idea.innovatorProfession.trim()[0].toUpperCase();
    final links = [
      if (idea.linkedinUrl.trim().isNotEmpty) ('LinkedIn', idea.linkedinUrl),
      if (idea.githubUrl.trim().isNotEmpty) ('GitHub', idea.githubUrl),
    ];

    return _Section(
      title: 'About the innovator',
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.terracotta.withValues(alpha: 0.16),
            child: Text(
              initial,
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppColors.ochre,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  idea.innovatorProfession,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  idea.innovatorBio.trim().isEmpty
                      ? 'Profile details are shared only through the platform request flow.'
                      : idea.innovatorBio,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.44),
                  ),
                ),
                if (links.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final link in links)
                        _Chip(label: link.$1, color: AppColors.graphite),
                    ],
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

class MetadataSection extends StatelessWidget {
  final IdeaModel idea;

  const MetadataSection({
    super.key,
    required this.idea,
  });

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('MMM d, yyyy').format(idea.createdAt);
    return _Section(
      title: 'Details',
      child: Column(
        children: [
          _MetadataRow(
            icon: Icons.calendar_today_outlined,
            label: 'Date added',
            value: date,
          ),
          _MetadataRow(
            icon: Icons.public_rounded,
            label: 'Geographic scope',
            value: idea.geographicScope,
          ),
        ],
      ),
    );
  }
}

class StickyBottomCTA extends StatelessWidget {
  final PitchModel? request;
  final VoidCallback onSendRequest;

  const StickyBottomCTA({
    super.key,
    required this.request,
    required this.onSendRequest,
  });

  @override
  Widget build(BuildContext context) {
    final status = request?.status;
    final opensDealRoom = status == PitchStatus.accepted ||
        status == PitchStatus.submitted ||
        status == PitchStatus.completed;
    final disabled = request != null && !opensDealRoom;
    final label = opensDealRoom
        ? 'Open Deal Room'
        : request == null
            ? 'Send request'
            : status == PitchStatus.pending
                ? 'Request sent'
                : 'Request closed';

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
        decoration: BoxDecoration(
          color: AppColors.labBlack.withValues(alpha: 0.96),
          border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          ),
        ),
        child: FrumaLabButton(
          label: label,
          onPressed: disabled
              ? null
              : opensDealRoom
                  ? () => context.go('/pitch/${request!.id}')
                  : onSendRequest,
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
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
            Text(
              title,
              style: theme.textTheme.labelLarge?.copyWith(
                color: AppColors.patinaTeal,
                fontFamily: 'SpaceGrotesk',
                fontWeight: FontWeight.w800,
                letterSpacing: 1.8,
              ),
            ),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

class _MetadataRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MetadataRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.ochre),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.42),
              ),
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;

  const _Chip({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontFamily: 'SpaceGrotesk',
              fontWeight: FontWeight.w900,
            ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
        ),
      ),
    );
  }
}

String _typeFor(IdeaModel idea) {
  final raw = idea.collaborationType.trim();
  if (raw.isEmpty) return 'Open';
  final lower = raw.toLowerCase();
  if (lower.contains('buy') || lower.contains('kjøp')) return 'Buy';
  if (lower.contains('partner')) return 'Partnership';
  if (lower.contains('license') || lower.contains('lisens')) return 'License';
  return raw;
}
