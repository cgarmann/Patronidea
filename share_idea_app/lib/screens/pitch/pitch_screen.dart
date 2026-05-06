import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../models/deal_room_model.dart';
import '../../models/pitch_model.dart';
import '../../providers/demo_session_provider.dart';
import '../../services/pitch_service.dart';
import '../shared/fruma_lab_chrome.dart';
import '../shared/loading_overlay.dart';

class PitchScreen extends ConsumerStatefulWidget {
  final String pitchId;
  const PitchScreen({super.key, required this.pitchId});

  @override
  ConsumerState<PitchScreen> createState() => _PitchScreenState();
}

class _PitchScreenState extends ConsumerState<PitchScreen> {
  final _service = PitchService();
  final _messageCtrl = TextEditingController();
  bool _acting = false;

  @override
  void dispose() {
    _messageCtrl.dispose();
    super.dispose();
  }

  String get _uid {
    final demo = ref.read(demoSessionProvider);
    if (demo.active) return demo.currentUid;
    return FirebaseAuth.instance.currentUser?.uid ?? '';
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _acting = true);
    try {
      await action();
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

  Future<void> _sendMessage() async {
    final body = _messageCtrl.text.trim();
    if (body.isEmpty) return;
    _messageCtrl.clear();
    await _run(() async {
      final demo = ref.read(demoSessionProvider);
      if (demo.active) {
        ref.read(demoSessionProvider.notifier).sendMessage(
              pitchId: widget.pitchId,
              body: body,
            );
        return;
      }
      await _service.sendDealMessage(
        pitchId: widget.pitchId,
        body: body,
      );
    });
  }

  Future<void> _submitProposal() async {
    final result = await showModalBottomSheet<_ProposalInput>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.labPanel,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (_) => const _ProposalSheet(),
    );
    if (result == null) return;
    await _run(() async {
      final demo = ref.read(demoSessionProvider);
      if (demo.active) {
        ref.read(demoSessionProvider.notifier).submitProposal(
              pitchId: widget.pitchId,
              amount: result.amount,
              currency: result.currency,
              collaborationType: result.collaborationType,
              message: result.message,
            );
        return;
      }
      await _service.submitDealProposal(
        pitchId: widget.pitchId,
        amount: result.amount,
        currency: result.currency,
        collaborationType: result.collaborationType,
        message: result.message,
      );
    });
  }

  Future<void> _reportIssue() async {
    final ctrl = TextEditingController();
    final reason = await showModalBottomSheet<String>(
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
              'Report issue',
              style: Theme.of(ctx)
                  .textTheme
                  .titleLarge
                  ?.copyWith(color: Colors.white, fontFamily: 'SpaceGrotesk'),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: ctrl,
              style: const TextStyle(color: Colors.white),
              minLines: 4,
              maxLines: 6,
              decoration: const InputDecoration(
                hintText: 'Describe what needs review...',
              ),
            ),
            const SizedBox(height: 16),
            FrumaLabButton(
              label: 'Report issue',
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            ),
          ],
        ),
      ),
    );
    if (reason == null || reason.isEmpty) return;
    await _run(() async {
      final demo = ref.read(demoSessionProvider);
      if (demo.active) {
        ref
            .read(demoSessionProvider.notifier)
            .reportIssue(pitchId: widget.pitchId);
        return;
      }
      await _service.reportDealIssue(
        pitchId: widget.pitchId,
        reason: reason,
      );
    });
  }

  Future<void> _approveRequest() async {
    await _run(() async {
      final demo = ref.read(demoSessionProvider);
      if (demo.active) {
        ref
            .read(demoSessionProvider.notifier)
            .approvePitchRequest(widget.pitchId);
        return;
      }
      await _service.approvePitchRequest(widget.pitchId);
    });
  }

  Future<void> _rejectRequest() async {
    await _run(() async {
      final demo = ref.read(demoSessionProvider);
      if (demo.active) {
        ref.read(demoSessionProvider.notifier).rejectPitch(widget.pitchId);
        return;
      }
      await _service.rejectPitch(widget.pitchId);
    });
  }

  Future<void> _respondProposal(String proposalId, String action) async {
    await _run(() async {
      final demo = ref.read(demoSessionProvider);
      if (demo.active) {
        ref.read(demoSessionProvider.notifier).respondProposal(
              pitchId: widget.pitchId,
              proposalId: proposalId,
              action: action,
            );
        return;
      }
      await _service.respondDealProposal(
        pitchId: widget.pitchId,
        proposalId: proposalId,
        action: action,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final demo = ref.watch(demoSessionProvider);
    return LoadingOverlay(
      isLoading: _acting,
      child: demo.active
          ? _buildScaffold(demo.pitchById(widget.pitchId))
          : StreamBuilder<PitchModel>(
              stream: _service.watchPitch(widget.pitchId),
              builder: (context, pitchSnap) {
                return _buildScaffold(pitchSnap.data);
              },
            ),
    );
  }

  Widget _buildScaffold(PitchModel? pitch) {
    return Scaffold(
      backgroundColor: AppColors.volcanic950,
      body: FrumaLabBackground(
        intensity: 0.68,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 20, 4),
                child: Row(
                  children: [
                    FrumaBackButton(
                      onPressed: () => context.canPop()
                          ? context.pop()
                          : context.go('/vault'),
                    ),
                    const Spacer(),
                    const FrumaStatusPill(label: 'Deal Room'),
                  ],
                ),
              ),
              Expanded(
                child: pitch == null
                    ? const Center(
                        child:
                            CircularProgressIndicator(color: AppColors.ochre),
                      )
                    : _buildBody(pitch),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(PitchModel pitch) {
    final demo = ref.watch(demoSessionProvider);
    final isInnovator = pitch.innovatorId == _uid;
    final isPatron = pitch.patronId == _uid;
    final otherParty = isInnovator ? 'Patron' : 'Innovator';

    if (pitch.status == PitchStatus.pending) {
      return _PendingRequestView(
        pitch: pitch,
        isInnovator: isInnovator,
        onAccept: _approveRequest,
        onReject: _rejectRequest,
      );
    }
    if (!isInnovator && !isPatron) {
      return const Center(child: Text('Deal Room unavailable.'));
    }

    if (demo.active) {
      return _dealRoomContent(
        pitch: pitch,
        otherParty: otherParty,
        messages: demo.messagesFor(widget.pitchId),
        proposals: demo.proposalsFor(widget.pitchId),
      );
    }

    return StreamBuilder<List<DealMessage>>(
      stream: _service.watchDealMessages(widget.pitchId),
      builder: (context, messageSnap) {
        return StreamBuilder<List<DealProposal>>(
          stream: _service.watchDealProposals(widget.pitchId),
          builder: (context, proposalSnap) {
            return _dealRoomContent(
              pitch: pitch,
              otherParty: otherParty,
              messages: messageSnap.data ?? const <DealMessage>[],
              proposals: proposalSnap.data ?? const <DealProposal>[],
            );
          },
        );
      },
    );
  }

  Widget _dealRoomContent({
    required PitchModel pitch,
    required String otherParty,
    required List<DealMessage> messages,
    required List<DealProposal> proposals,
  }) {
    final activeProposal = proposals
        .where((proposal) => proposal.status == DealProposalStatus.active)
        .cast<DealProposal?>()
        .firstWhere((proposal) => proposal != null, orElse: () => null);
    final acceptedProposal = proposals
        .where((proposal) => proposal.status == DealProposalStatus.accepted)
        .cast<DealProposal?>()
        .firstWhere((proposal) => proposal != null, orElse: () => null);
    final isPatron = pitch.patronId == _uid;

    return Column(
      children: [
        DealRoomHeader(
          pitch: pitch,
          otherParty: otherParty,
          acceptedProposal: acceptedProposal,
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
            children: [
              if (pitch.patronMessage.isNotEmpty)
                _InitialRequestMessage(pitch: pitch, isMine: isPatron),
              MessageThread(messages: messages, currentUid: _uid),
              if (activeProposal != null) ...[
                const SizedBox(height: 12),
                proposals.length > 1
                    ? CounterOfferCard(
                        proposal: activeProposal,
                        isMine: activeProposal.senderId == _uid,
                        onCounter: _submitProposal,
                        onDecline: () =>
                            _respondProposal(activeProposal.id, 'decline'),
                      )
                    : ProposalCard(
                        proposal: activeProposal,
                        isMine: activeProposal.senderId == _uid,
                        onCounter: _submitProposal,
                        onDecline: () =>
                            _respondProposal(activeProposal.id, 'decline'),
                      ),
              ],
              if (acceptedProposal != null) ...[
                const SizedBox(height: 12),
                ProposalCard(
                  proposal: acceptedProposal,
                  isMine: acceptedProposal.senderId == _uid,
                  accepted: true,
                  onCounter: null,
                  onDecline: null,
                ),
              ],
              const SizedBox(height: 8),
              ReportIssueButton(onPressed: _reportIssue),
            ],
          ),
        ),
        _MessageComposer(
          controller: _messageCtrl,
          onSend: _sendMessage,
        ),
        _DealPrimaryAction(
          activeProposal: activeProposal,
          acceptedProposal: acceptedProposal,
          currentUid: _uid,
          onSubmitProposal: _submitProposal,
          onAcceptProposal: activeProposal == null
              ? null
              : () => _respondProposal(activeProposal.id, 'accept'),
        ),
      ],
    );
  }
}

class DealRoomHeader extends StatelessWidget {
  final PitchModel pitch;
  final String otherParty;
  final DealProposal? acceptedProposal;

  const DealRoomHeader({
    super.key,
    required this.pitch,
    required this.otherParty,
    required this.acceptedProposal,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusLabel = acceptedProposal == null ? 'Open' : 'Accepted';
    final color =
        acceptedProposal == null ? AppColors.patinaTeal : AppColors.ochre;

    return Container(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pitch.ideaTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontFamily: 'SpaceGrotesk',
                    fontWeight: FontWeight.w900,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  otherParty,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.42),
                  ),
                ),
              ],
            ),
          ),
          _StatusBadge(label: statusLabel, color: color),
        ],
      ),
    );
  }
}

class MessageThread extends StatelessWidget {
  final List<DealMessage> messages;
  final String currentUid;

  const MessageThread({
    super.key,
    required this.messages,
    required this.currentUid,
  });

  @override
  Widget build(BuildContext context) {
    if (messages.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        for (final message in messages)
          _MessageBubble(
            body: message.body,
            createdAt: message.createdAt,
            isMine: message.senderId == currentUid,
            senderRole: message.senderRole,
          ),
      ],
    );
  }
}

class ProposalCard extends StatelessWidget {
  final DealProposal proposal;
  final bool isMine;
  final bool accepted;
  final VoidCallback? onCounter;
  final VoidCallback? onDecline;

  const ProposalCard({
    super.key,
    required this.proposal,
    required this.isMine,
    this.accepted = false,
    this.onCounter,
    this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    return _ProposalSurface(
      title: accepted ? 'Accepted proposal' : 'Proposal',
      proposal: proposal,
      isMine: isMine,
      onCounter: onCounter,
      onDecline: onDecline,
    );
  }
}

class CounterOfferCard extends StatelessWidget {
  final DealProposal proposal;
  final bool isMine;
  final VoidCallback? onCounter;
  final VoidCallback? onDecline;

  const CounterOfferCard({
    super.key,
    required this.proposal,
    required this.isMine,
    this.onCounter,
    this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    return _ProposalSurface(
      title: 'Counter offer',
      proposal: proposal,
      isMine: isMine,
      onCounter: onCounter,
      onDecline: onDecline,
    );
  }
}

class AcceptDealButton extends StatelessWidget {
  final VoidCallback? onPressed;

  const AcceptDealButton({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return FrumaLabButton(
      label: 'Accept proposal',
      onPressed: onPressed,
    );
  }
}

class ReportIssueButton extends StatelessWidget {
  final VoidCallback onPressed;

  const ReportIssueButton({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: TextButton.icon(
        onPressed: onPressed,
        icon: const Icon(Icons.flag_outlined, size: 16),
        label: const Text('Report issue'),
        style: TextButton.styleFrom(
          foregroundColor: Colors.white.withValues(alpha: 0.32),
        ),
      ),
    );
  }
}

class _PendingRequestView extends StatelessWidget {
  final PitchModel pitch;
  final bool isInnovator;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  const _PendingRequestView({
    required this.pitch,
    required this.isInnovator,
    required this.onAccept,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(22),
      children: [
        const _StatusBadge(label: 'Pending', color: AppColors.warning),
        const SizedBox(height: 18),
        Text(
          pitch.ideaTitle,
          style: theme.textTheme.headlineSmall?.copyWith(
            color: Colors.white,
            fontFamily: 'SpaceGrotesk',
            fontSize: 30,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        _Panel(
          child: Text(
            pitch.patronMessage.isEmpty
                ? 'No message provided.'
                : pitch.patronMessage,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.74),
            ),
          ),
        ),
        const SizedBox(height: 18),
        if (isInnovator) ...[
          FrumaLabButton(
            label: 'Open Deal Room',
            onPressed: onAccept,
          ),
          const SizedBox(height: 10),
          FrumaLabButton(
            label: 'Decline request',
            secondary: true,
            onPressed: onReject,
          ),
        ] else
          _Panel(
            child: Text(
              'Waiting for the innovator to respond.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.64),
              ),
            ),
          ),
      ],
    );
  }
}

class _InitialRequestMessage extends StatelessWidget {
  final PitchModel pitch;
  final bool isMine;

  const _InitialRequestMessage({
    required this.pitch,
    required this.isMine,
  });

  @override
  Widget build(BuildContext context) {
    return _MessageBubble(
      body: pitch.patronMessage,
      createdAt: pitch.createdAt,
      isMine: isMine,
      senderRole: 'patron',
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String body;
  final DateTime createdAt;
  final bool isMine;
  final String senderRole;

  const _MessageBubble({
    required this.body,
    required this.createdAt,
    required this.isMine,
    required this.senderRole,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final time = DateFormat('MMM d, HH:mm').format(createdAt);
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 310),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: isMine
              ? AppColors.terracotta.withValues(alpha: 0.2)
              : Colors.black.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isMine
                ? AppColors.terracotta.withValues(alpha: 0.32)
                : Colors.white.withValues(alpha: 0.08),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              body,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white.withValues(alpha: 0.78),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              '${senderRole.toUpperCase()} - $time',
              style: theme.textTheme.labelSmall?.copyWith(
                color: isMine
                    ? AppColors.ochre
                    : Colors.white.withValues(alpha: 0.32),
                fontFamily: 'SpaceGrotesk',
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProposalSurface extends StatelessWidget {
  final String title;
  final DealProposal proposal;
  final bool isMine;
  final VoidCallback? onCounter;
  final VoidCallback? onDecline;

  const _ProposalSurface({
    required this.title,
    required this.proposal,
    required this.isMine,
    this.onCounter,
    this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canRespond = !isMine && proposal.status == DealProposalStatus.active;
    return _Panel(
      borderColor: AppColors.ochre.withValues(alpha: 0.32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _StatusBadge(label: title, color: AppColors.ochre),
              const Spacer(),
              Text(
                proposal.formattedAmount,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontFamily: 'SpaceGrotesk',
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            proposal.collaborationType,
            style: theme.textTheme.titleSmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.72),
            ),
          ),
          if (proposal.message.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              proposal.message,
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.44),
              ),
            ),
          ],
          if (canRespond) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                TextButton(
                  onPressed: onCounter,
                  child: const Text('Counter offer'),
                ),
                const SizedBox(width: 6),
                TextButton(
                  onPressed: onDecline,
                  style: TextButton.styleFrom(foregroundColor: AppColors.error),
                  child: const Text('Decline'),
                ),
              ],
            ),
          ],
          if (isMine && proposal.status == DealProposalStatus.active) ...[
            const SizedBox(height: 8),
            Text(
              'Waiting for response',
              style: theme.textTheme.bodySmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.4),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MessageComposer extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;

  const _MessageComposer({
    required this.controller,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      bottom: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
        decoration: BoxDecoration(
          color: AppColors.labBlack.withValues(alpha: 0.94),
          border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                style: const TextStyle(color: Colors.white),
                minLines: 1,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Message',
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: onSend,
              icon: const Icon(Icons.send_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _DealPrimaryAction extends StatelessWidget {
  final DealProposal? activeProposal;
  final DealProposal? acceptedProposal;
  final String currentUid;
  final VoidCallback onSubmitProposal;
  final VoidCallback? onAcceptProposal;

  const _DealPrimaryAction({
    required this.activeProposal,
    required this.acceptedProposal,
    required this.currentUid,
    required this.onSubmitProposal,
    required this.onAcceptProposal,
  });

  @override
  Widget build(BuildContext context) {
    final active = activeProposal;
    final accepted = acceptedProposal;
    final Widget child;

    if (accepted != null) {
      child = const FrumaLabButton(
        label: 'Deal accepted',
        onPressed: null,
      );
    } else if (active == null) {
      child = FrumaLabButton(
        label: 'Submit proposal',
        onPressed: onSubmitProposal,
      );
    } else if (active.senderId == currentUid) {
      child = const FrumaLabButton(
        label: 'Waiting for response',
        onPressed: null,
      );
    } else {
      child = AcceptDealButton(onPressed: onAcceptProposal);
    }

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 14),
        color: AppColors.labBlack.withValues(alpha: 0.94),
        child: child,
      ),
    );
  }
}

class _ProposalSheet extends StatefulWidget {
  const _ProposalSheet();

  @override
  State<_ProposalSheet> createState() => _ProposalSheetState();
}

class _ProposalSheetState extends State<_ProposalSheet> {
  final _amountCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  String _currency = 'NOK';
  String _type = 'Open';

  @override
  void dispose() {
    _amountCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    final amount = double.tryParse(_amountCtrl.text.replaceAll(',', '.'));
    if (amount == null || amount <= 0) return;
    Navigator.pop(
      context,
      _ProposalInput(
        amount: (amount * 100).round(),
        currency: _currency,
        collaborationType: _type,
        message: _messageCtrl.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Submit proposal',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontFamily: 'SpaceGrotesk',
                ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amountCtrl,
            style: const TextStyle(color: Colors.white),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Amount'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _currency,
            dropdownColor: AppColors.labPanelRaised,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(labelText: 'Currency'),
            items: const ['NOK', 'USD', 'EUR']
                .map((value) =>
                    DropdownMenuItem(value: value, child: Text(value)))
                .toList(),
            onChanged: (value) => setState(() => _currency = value ?? 'NOK'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _type,
            dropdownColor: AppColors.labPanelRaised,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(labelText: 'Collaboration type'),
            items: const ['Open', 'Buy', 'Partnership', 'License']
                .map((value) =>
                    DropdownMenuItem(value: value, child: Text(value)))
                .toList(),
            onChanged: (value) => setState(() => _type = value ?? 'Open'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _messageCtrl,
            style: const TextStyle(color: Colors.white),
            minLines: 3,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Message',
              hintText: 'Terms, scope or notes...',
            ),
          ),
          const SizedBox(height: 18),
          FrumaLabButton(
            label: 'Submit proposal',
            onPressed: _submit,
          ),
        ],
      ),
    );
  }
}

class _ProposalInput {
  final int amount;
  final String currency;
  final String collaborationType;
  final String message;

  const _ProposalInput({
    required this.amount,
    required this.currency,
    required this.collaborationType,
    required this.message,
  });
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({
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

class _Panel extends StatelessWidget {
  final Widget child;
  final Color? borderColor;

  const _Panel({
    required this.child,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: borderColor ?? Colors.white.withValues(alpha: 0.08),
          ),
          bottom: BorderSide(
            color: borderColor ?? Colors.white.withValues(alpha: 0.08),
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: child,
      ),
    );
  }
}
