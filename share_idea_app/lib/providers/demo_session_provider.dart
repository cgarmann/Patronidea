import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/deal_room_model.dart';
import '../models/idea_model.dart';
import '../models/idea_report_model.dart';
import '../models/pitch_model.dart';
import '../models/user_model.dart';

const demoPatronUid = 'demo-patron';
const demoInnovatorUid = 'demo-innovator';
const demoAdminUid = 'demo-admin';

enum DemoRole { patron, innovator, admin }

extension DemoRoleLabel on DemoRole {
  String get label {
    return switch (this) {
      DemoRole.patron => 'Patron',
      DemoRole.innovator => 'Innovator',
      DemoRole.admin => 'Admin',
    };
  }
}

class DemoSession {
  final bool active;
  final DemoRole role;
  final List<IdeaModel> ideas;
  final List<PitchModel> pitches;
  final Map<String, List<DealMessage>> messages;
  final Map<String, List<DealProposal>> proposals;
  final Set<String> favoriteIdeaIds;
  final Set<String> reportedPitchIds;
  final List<UserModel> adminUsers;
  final List<ReportStatsModel> adminReportStats;

  const DemoSession({
    required this.active,
    required this.role,
    required this.ideas,
    required this.pitches,
    required this.messages,
    required this.proposals,
    required this.favoriteIdeaIds,
    required this.reportedPitchIds,
    required this.adminUsers,
    required this.adminReportStats,
  });

  factory DemoSession.inactive() {
    return const DemoSession(
      active: false,
      role: DemoRole.patron,
      ideas: [],
      pitches: [],
      messages: {},
      proposals: {},
      favoriteIdeaIds: {},
      reportedPitchIds: {},
      adminUsers: [],
      adminReportStats: [],
    );
  }

  factory DemoSession.seed(DemoRole role) {
    final now = DateTime.now();
    final ideas = _DemoFixtures.ideas(now);
    final activePitch = _DemoFixtures.pitch(
      id: 'demo-pitch-active',
      idea: ideas[0],
      status: PitchStatus.accepted,
      patronMessage:
          'We operate industrial sites in Norway and want to explore licensing this workflow for maintenance teams.',
      createdAt: now.subtract(const Duration(hours: 22)),
    );
    final pendingPitch = _DemoFixtures.pitch(
      id: 'demo-pitch-pending',
      idea: ideas[1],
      status: PitchStatus.pending,
      patronMessage:
          'Our hospital group is looking for better night-shift learning tools. Can we discuss partnership fit?',
      createdAt: now.subtract(const Duration(hours: 5)),
    );

    return DemoSession(
      active: true,
      role: role,
      ideas: ideas,
      pitches: [activePitch, pendingPitch],
      messages: {
        activePitch.id: [
          DealMessage(
            id: 'demo-message-1',
            senderId: demoInnovatorUid,
            senderRole: 'innovator',
            body:
                'Thanks for the context. The workflow is built for shift handovers, recurring faults and supplier follow-up.',
            createdAt: now.subtract(const Duration(hours: 18)),
          ),
          DealMessage(
            id: 'demo-message-2',
            senderId: demoPatronUid,
            senderRole: 'patron',
            body:
                'Good fit. We would like a 90-day pilot with an option to license across two facilities.',
            createdAt: now.subtract(const Duration(hours: 16)),
          ),
        ],
      },
      proposals: {
        activePitch.id: [
          DealProposal(
            id: 'demo-proposal-1',
            senderId: demoInnovatorUid,
            senderRole: 'innovator',
            status: DealProposalStatus.active,
            amount: 7500000,
            currency: 'NOK',
            collaborationType: 'License',
            message:
                '90-day pilot, limited site access, license option included after acceptance.',
            createdAt: now.subtract(const Duration(hours: 3)),
            updatedAt: now.subtract(const Duration(hours: 3)),
          ),
        ],
      },
      favoriteIdeaIds: {ideas[0].id},
      reportedPitchIds: const {},
      adminUsers: _DemoFixtures.users(now),
      adminReportStats: _DemoFixtures.reportStats(now),
    );
  }

  String get currentUid {
    return switch (role) {
      DemoRole.patron => demoPatronUid,
      DemoRole.innovator => demoInnovatorUid,
      DemoRole.admin => demoAdminUid,
    };
  }

  bool get isPatron => role == DemoRole.patron;

  bool get isAdmin => role == DemoRole.admin;

  List<IdeaModel> get vaultIdeas =>
      ideas.where((idea) => idea.status == IdeaStatus.active).toList();

  List<IdeaModel> get myIdeas =>
      ideas.where((idea) => idea.innovatorId == demoInnovatorUid).toList();

  List<PitchModel> get incomingPitches =>
      pitches.where((pitch) => pitch.innovatorId == demoInnovatorUid).toList();

  List<IdeaModel> get adminIdeaQueue => ideas
      .where(
        (idea) =>
            idea.status == IdeaStatus.pendingReview ||
            idea.status == IdeaStatus.needsReview ||
            idea.status == IdeaStatus.flagged,
      )
      .toList();

  List<IdeaModel> get adminReportQueue =>
      ideas.where((idea) => idea.status == IdeaStatus.flagged).toList();

  DemoSession copyWith({
    bool? active,
    DemoRole? role,
    List<IdeaModel>? ideas,
    List<PitchModel>? pitches,
    Map<String, List<DealMessage>>? messages,
    Map<String, List<DealProposal>>? proposals,
    Set<String>? favoriteIdeaIds,
    Set<String>? reportedPitchIds,
    List<UserModel>? adminUsers,
    List<ReportStatsModel>? adminReportStats,
  }) {
    return DemoSession(
      active: active ?? this.active,
      role: role ?? this.role,
      ideas: ideas ?? this.ideas,
      pitches: pitches ?? this.pitches,
      messages: messages ?? this.messages,
      proposals: proposals ?? this.proposals,
      favoriteIdeaIds: favoriteIdeaIds ?? this.favoriteIdeaIds,
      reportedPitchIds: reportedPitchIds ?? this.reportedPitchIds,
      adminUsers: adminUsers ?? this.adminUsers,
      adminReportStats: adminReportStats ?? this.adminReportStats,
    );
  }

  IdeaModel? ideaById(String ideaId) {
    for (final idea in ideas) {
      if (idea.id == ideaId) return idea;
    }
    return null;
  }

  PitchModel? pitchById(String pitchId) {
    for (final pitch in pitches) {
      if (pitch.id == pitchId) return pitch;
    }
    return null;
  }

  PitchModel? requestForIdea(String ideaId) {
    for (final pitch in pitches) {
      if (pitch.ideaId == ideaId && pitch.patronId == demoPatronUid) {
        return pitch;
      }
    }
    return null;
  }
}

class DemoSessionController extends StateNotifier<DemoSession> {
  DemoSessionController() : super(DemoSession.inactive());

  void startAs(DemoRole role) {
    state = DemoSession.seed(role);
  }

  void switchTo(DemoRole role) {
    state = state.active ? state.copyWith(role: role) : DemoSession.seed(role);
  }

  void exit() {
    state = DemoSession.inactive();
  }

  void toggleFavorite(String ideaId) {
    final next = {...state.favoriteIdeaIds};
    next.contains(ideaId) ? next.remove(ideaId) : next.add(ideaId);
    state = state.copyWith(favoriteIdeaIds: next);
  }

  String requestPitch({required String ideaId, required String message}) {
    final existing = state.requestForIdea(ideaId);
    if (existing != null) return existing.id;

    final idea = state.ideaById(ideaId);
    if (idea == null) throw StateError('Demo idea not found.');

    final now = DateTime.now();
    final pitch = _DemoFixtures.pitch(
      id: 'demo-pitch-${now.microsecondsSinceEpoch}',
      idea: idea,
      status: PitchStatus.accepted,
      patronMessage: message.trim().isEmpty
          ? 'Demo request: we want to explore this opportunity.'
          : message.trim(),
      createdAt: now,
    );

    state = state.copyWith(
      pitches: [pitch, ...state.pitches],
      messages: {
        ...state.messages,
        pitch.id: [
          DealMessage(
            id: 'demo-message-${now.microsecondsSinceEpoch}',
            senderId: demoInnovatorUid,
            senderRole: 'innovator',
            body:
                'Demo auto-approval: request accepted so you can open the Deal Room.',
            createdAt: now.add(const Duration(seconds: 1)),
          ),
        ],
      },
      proposals: {...state.proposals, pitch.id: const []},
    );
    return pitch.id;
  }

  void approvePitchRequest(String pitchId) {
    _replacePitch(
        pitchId, (pitch) => _pitchWithStatus(pitch, PitchStatus.accepted));
  }

  void rejectPitch(String pitchId) {
    _replacePitch(
        pitchId, (pitch) => _pitchWithStatus(pitch, PitchStatus.rejected));
  }

  void sendMessage({required String pitchId, required String body}) {
    final trimmed = body.trim();
    if (trimmed.isEmpty) return;
    final now = DateTime.now();
    final message = DealMessage(
      id: 'demo-message-${now.microsecondsSinceEpoch}',
      senderId: state.currentUid,
      senderRole: state.role == DemoRole.patron ? 'patron' : 'innovator',
      body: trimmed,
      createdAt: now,
    );
    state = state.copyWith(
      messages: {
        ...state.messages,
        pitchId: [...state.messagesFor(pitchId), message],
      },
    );
  }

  void submitProposal({
    required String pitchId,
    required int amount,
    required String currency,
    required String collaborationType,
    required String message,
  }) {
    final existing = state.proposalsFor(pitchId);
    final active = existing.activeProposal;
    if (active != null && active.senderId == state.currentUid) {
      throw StateError('Waiting for the other party to respond.');
    }

    final now = DateTime.now();
    final updatedExisting = existing
        .map(
          (proposal) => proposal.id == active?.id
              ? _proposalWithStatus(proposal, DealProposalStatus.countered, now)
              : proposal,
        )
        .toList();
    final proposal = DealProposal(
      id: 'demo-proposal-${now.microsecondsSinceEpoch}',
      senderId: state.currentUid,
      senderRole: state.role == DemoRole.patron ? 'patron' : 'innovator',
      status: DealProposalStatus.active,
      amount: amount,
      currency: currency,
      collaborationType: collaborationType,
      message: message,
      createdAt: now,
      updatedAt: now,
    );

    state = state.copyWith(
      proposals: {
        ...state.proposals,
        pitchId: [proposal, ...updatedExisting],
      },
    );
  }

  void respondProposal({
    required String pitchId,
    required String proposalId,
    required String action,
  }) {
    final now = DateTime.now();
    final accepted = action == 'accept';
    final next = state.proposalsFor(pitchId).map((proposal) {
      if (proposal.id != proposalId) return proposal;
      if (proposal.senderId == state.currentUid) {
        throw StateError('You cannot respond to your own proposal.');
      }
      return _proposalWithStatus(
        proposal,
        accepted ? DealProposalStatus.accepted : DealProposalStatus.declined,
        now,
      );
    }).toList();

    state = state.copyWith(
      proposals: {
        ...state.proposals,
        pitchId: next,
      },
    );
  }

  void reportIssue({required String pitchId}) {
    state = state.copyWith(
      reportedPitchIds: {...state.reportedPitchIds, pitchId},
    );
  }

  void resolveIdeaForAdmin({
    required String ideaId,
    required String resolution,
    String? reviewNote,
  }) {
    final now = DateTime.now();
    final status = switch (resolution) {
      'keep' => IdeaStatus.active,
      'reject' => IdeaStatus.rejected,
      'request_edit' => IdeaStatus.returned,
      _ => IdeaStatus.needsReview,
    };

    state = state.copyWith(
      ideas: [
        for (final idea in state.ideas)
          if (idea.id == ideaId)
            idea.copyWith(
              status: status,
              visibility: status == IdeaStatus.active ? 'public' : 'private',
              reviewNote: reviewNote ?? idea.reviewNote,
              reviewedAt: now,
              reviewedBy: demoAdminUid,
              updatedAt: now,
            )
          else
            idea,
      ],
    );
  }

  void moderateDemoUser({
    required String uid,
    required AccountStatus accountStatus,
  }) {
    state = state.copyWith(
      adminUsers: [
        for (final user in state.adminUsers)
          user.uid == uid ? user.copyWith(accountStatus: accountStatus) : user,
      ],
    );
  }

  void addDraftIdea({
    required String title,
    required String body,
    required String category,
  }) {
    final now = DateTime.now();
    final idea = IdeaModel(
      id: 'demo-idea-${now.microsecondsSinceEpoch}',
      title: title,
      body: body,
      category: category,
      status: IdeaStatus.pendingReview,
      visibility: 'private',
      collaborationType: 'Open',
      geographicScope: 'Norway',
      innovatorProfession: 'Demo innovator',
      innovatorBio: 'A demo profile used for product walkthroughs.',
      maturityScore: 64,
      uniquenessScore: 81,
      innovatorId: demoInnovatorUid,
      price: 0,
      createdAt: now,
      updatedAt: now,
      submittedAt: now,
    );
    state = state.copyWith(ideas: [idea, ...state.ideas]);
  }

  void _replacePitch(String pitchId, PitchModel Function(PitchModel) update) {
    state = state.copyWith(
      pitches: [
        for (final pitch in state.pitches)
          pitch.id == pitchId ? update(pitch) : pitch,
      ],
    );
  }
}

final demoSessionProvider =
    StateNotifierProvider<DemoSessionController, DemoSession>(
  (ref) => DemoSessionController(),
);

extension DemoSessionLists on DemoSession {
  List<DealMessage> messagesFor(String pitchId) =>
      messages[pitchId] ?? const <DealMessage>[];

  List<DealProposal> proposalsFor(String pitchId) =>
      proposals[pitchId] ?? const <DealProposal>[];
}

extension DealProposalListX on List<DealProposal> {
  DealProposal? get activeProposal {
    for (final proposal in this) {
      if (proposal.status == DealProposalStatus.active) return proposal;
    }
    return null;
  }
}

PitchModel _pitchWithStatus(PitchModel pitch, PitchStatus status) {
  return PitchModel(
    id: pitch.id,
    ideaId: pitch.ideaId,
    patronId: pitch.patronId,
    innovatorId: pitch.innovatorId,
    status: status,
    patronMessage: pitch.patronMessage,
    innovatorPitch: pitch.innovatorPitch,
    contactEmail: pitch.contactEmail,
    ideaTitle: pitch.ideaTitle,
    ideaCategory: pitch.ideaCategory,
    createdAt: pitch.createdAt,
  );
}

DealProposal _proposalWithStatus(
  DealProposal proposal,
  DealProposalStatus status,
  DateTime updatedAt,
) {
  return DealProposal(
    id: proposal.id,
    senderId: proposal.senderId,
    senderRole: proposal.senderRole,
    status: status,
    amount: proposal.amount,
    currency: proposal.currency,
    collaborationType: proposal.collaborationType,
    message: proposal.message,
    createdAt: proposal.createdAt,
    updatedAt: updatedAt,
  );
}

abstract final class _DemoFixtures {
  static List<IdeaModel> ideas(DateTime now) {
    return [
      IdeaModel(
        id: 'demo-idea-maintenance-ai',
        title: 'AI assistant for industrial maintenance logs',
        body:
            'A workflow that reads shift notes, recurring fault patterns and supplier updates, then prepares follow-up actions for maintenance managers before failures repeat.',
        category: 'Technology',
        status: IdeaStatus.active,
        visibility: 'public',
        collaborationType: 'License',
        geographicScope: 'Nordics',
        innovatorProfession: 'Process engineer',
        innovatorBio:
            'Ten years around industrial facilities, maintenance planning and field-team handovers.',
        linkedinUrl: 'https://linkedin.com',
        maturityScore: 92,
        uniquenessScore: 88,
        innovatorId: demoInnovatorUid,
        price: 0,
        createdAt: now.subtract(const Duration(days: 2)),
        updatedAt: now.subtract(const Duration(hours: 8)),
      ),
      IdeaModel(
        id: 'demo-idea-nurse-learning',
        title: 'Micro-learning for nurses during night shifts',
        body:
            'Short clinical refreshers timed around low-load moments, with unit-specific checklists and supervisor feedback loops for faster onboarding.',
        category: 'Health',
        status: IdeaStatus.active,
        visibility: 'public',
        collaborationType: 'Partnership',
        geographicScope: 'Norway',
        innovatorProfession: 'Registered nurse',
        innovatorBio:
            'Works with hospital onboarding, shift coordination and practical training for new staff.',
        linkedinUrl: 'https://linkedin.com',
        maturityScore: 86,
        uniquenessScore: 91,
        innovatorId: demoInnovatorUid,
        price: 0,
        createdAt: now.subtract(const Duration(days: 1)),
        updatedAt: now.subtract(const Duration(hours: 7)),
      ),
      IdeaModel(
        id: 'demo-idea-packaging-loop',
        title: 'Deposit layer for local food delivery packaging',
        body:
            'A lightweight deposit system for local restaurants that tracks reusable packaging, nudges returns and gives patrons measurable waste reduction.',
        category: 'Green Tech',
        status: IdeaStatus.active,
        visibility: 'public',
        collaborationType: 'Buy',
        geographicScope: 'Europe',
        innovatorProfession: 'Operations designer',
        innovatorBio:
            'Designs circular logistics pilots for food, retail and municipal service teams.',
        githubUrl: 'https://github.com',
        maturityScore: 78,
        uniquenessScore: 84,
        innovatorId: demoInnovatorUid,
        price: 0,
        createdAt: now.subtract(const Duration(days: 9)),
        updatedAt: now.subtract(const Duration(days: 1)),
      ),
      IdeaModel(
        id: 'demo-idea-solar-quotes',
        title: 'Solar quote verifier for housing associations',
        body:
            'A procurement assistant that compares solar installer quotes, warranty terms and estimated yield so housing boards can catch inflated claims before signing.',
        category: 'Green Tech',
        status: IdeaStatus.flagged,
        visibility: 'public',
        collaborationType: 'Partnership',
        geographicScope: 'Nordics',
        innovatorProfession: 'Energy analyst',
        innovatorBio:
            'Works with housing associations, solar procurement and board-level decision support.',
        maturityScore: 82,
        uniquenessScore: 73,
        matchScore: 0.64,
        matchedIdeaId: 'archive-solar-procurement-19',
        matchedIdeaTitle: 'Solar procurement benchmark for co-ops',
        innovatorId: demoInnovatorUid,
        price: 0,
        createdAt: now.subtract(const Duration(days: 5)),
        updatedAt: now.subtract(const Duration(hours: 1)),
        submittedAt: now.subtract(const Duration(days: 4, hours: 23)),
        openReportCount: 2,
        lastReportReasonCode: IdeaReportReason.duplicateFalseNegative.code,
        lastReportReasonLabel: IdeaReportReason.duplicateFalseNegative.label,
        flaggedAt: now.subtract(const Duration(hours: 4)),
      ),
      IdeaModel(
        id: 'demo-idea-finance-draft',
        title: 'Cash-flow cockpit for small contractors',
        body:
            'A draft concept for invoices, expected supplier costs and payment risk in one simple operational view.',
        category: 'Finance',
        status: IdeaStatus.pendingReview,
        visibility: 'private',
        collaborationType: 'Open',
        geographicScope: 'Norway',
        innovatorProfession: 'Construction project lead',
        innovatorBio: 'Maps everyday finance friction for small contractors.',
        maturityScore: 61,
        uniquenessScore: 79,
        innovatorId: demoInnovatorUid,
        price: 0,
        createdAt: now.subtract(const Duration(hours: 14)),
        updatedAt: now.subtract(const Duration(hours: 2)),
        submittedAt: now.subtract(const Duration(hours: 13)),
      ),
      IdeaModel(
        id: 'demo-idea-sold',
        title: 'Inventory alerts for independent pharmacies',
        body:
            'A sold demo idea that shows how revenue and status appear after an opportunity leaves the Vault.',
        category: 'Health',
        status: IdeaStatus.sold,
        visibility: 'private',
        collaborationType: 'Buy',
        geographicScope: 'Norway',
        innovatorProfession: 'Pharmacy technician',
        innovatorBio: 'Built from everyday stockroom pain in pharmacies.',
        maturityScore: 95,
        uniquenessScore: 87,
        innovatorId: demoInnovatorUid,
        price: 12900000,
        createdAt: now.subtract(const Duration(days: 21)),
        updatedAt: now.subtract(const Duration(days: 3)),
      ),
    ];
  }

  static PitchModel pitch({
    required String id,
    required IdeaModel idea,
    required PitchStatus status,
    required String patronMessage,
    required DateTime createdAt,
  }) {
    return PitchModel(
      id: id,
      ideaId: idea.id,
      patronId: demoPatronUid,
      innovatorId: demoInnovatorUid,
      status: status,
      patronMessage: patronMessage,
      innovatorPitch: '',
      contactEmail: '',
      ideaTitle: idea.title,
      ideaCategory: idea.category,
      createdAt: createdAt,
    );
  }

  static List<UserModel> users(DateTime now) {
    return [
      UserModel(
        uid: demoPatronUid,
        displayName: 'Demo Patron',
        email: 'patron.demo@fruma.local',
        role: UserRole.patron,
        isActivePatron: true,
        subscriptionExpiry: now.add(const Duration(days: 23)),
        createdAt: now.subtract(const Duration(days: 44)),
        reportReviewFlag: true,
        totalReports: 7,
        falseReports: 4,
        validReports: 1,
        openReports: 2,
      ),
      UserModel(
        uid: demoInnovatorUid,
        displayName: 'Demo Innovator',
        email: 'innovator.demo@fruma.local',
        role: UserRole.innovator,
        isActivePatron: false,
        createdAt: now.subtract(const Duration(days: 63)),
      ),
      UserModel(
        uid: 'demo-patron-clean',
        displayName: 'Clean Patron Account',
        email: 'clean.patron@fruma.local',
        role: UserRole.patron,
        isActivePatron: true,
        subscriptionExpiry: now.add(const Duration(days: 31)),
        createdAt: now.subtract(const Duration(days: 18)),
        totalReports: 2,
        validReports: 2,
      ),
      UserModel(
        uid: 'demo-patron-suspended',
        displayName: 'Suspended Reporter',
        email: 'review.flagged@fruma.local',
        role: UserRole.patron,
        isActivePatron: true,
        subscriptionExpiry: now.add(const Duration(days: 6)),
        createdAt: now.subtract(const Duration(days: 71)),
        accountStatus: AccountStatus.suspended,
        reportReviewFlag: true,
        totalReports: 12,
        falseReports: 8,
        validReports: 1,
        openReports: 3,
      ),
    ];
  }

  static List<ReportStatsModel> reportStats(DateTime now) {
    return [
      ReportStatsModel(
        patronId: 'demo-patron-suspended',
        totalReports: 12,
        openReports: 3,
        falseReports: 8,
        validReports: 1,
        resolvedReports: 9,
        accountReviewFlag: true,
        lastReportAt: now.subtract(const Duration(hours: 2)),
        lastResolvedAt: now.subtract(const Duration(days: 1)),
      ),
      ReportStatsModel(
        patronId: demoPatronUid,
        totalReports: 7,
        openReports: 2,
        falseReports: 4,
        validReports: 1,
        resolvedReports: 5,
        accountReviewFlag: true,
        lastReportAt: now.subtract(const Duration(hours: 4)),
        lastResolvedAt: now.subtract(const Duration(days: 2)),
      ),
      ReportStatsModel(
        patronId: 'demo-patron-clean',
        totalReports: 2,
        openReports: 0,
        falseReports: 0,
        validReports: 2,
        resolvedReports: 2,
        accountReviewFlag: false,
        lastReportAt: now.subtract(const Duration(days: 8)),
        lastResolvedAt: now.subtract(const Duration(days: 7)),
      ),
    ];
  }
}
