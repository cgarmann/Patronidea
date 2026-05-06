import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum IdeaStatus {
  draft,
  processing,
  pendingReview,
  active,
  flagged,
  returned,
  needsReview,
  sold,
  rejected,
  archived,
  error,
}

class MaturityChecklist extends Equatable {
  final bool problemDefinition;
  final bool targetAudience;
  final bool executionPlan;

  const MaturityChecklist({
    this.problemDefinition = false,
    this.targetAudience = false,
    this.executionPlan = false,
  });

  factory MaturityChecklist.fromMap(Map<String, dynamic>? data) {
    return MaturityChecklist(
      problemDefinition: data?['problemDefinition'] as bool? ?? false,
      targetAudience: data?['targetAudience'] as bool? ?? false,
      executionPlan: data?['executionPlan'] as bool? ?? false,
    );
  }

  int get completedCount =>
      [problemDefinition, targetAudience, executionPlan].where((v) => v).length;

  bool get isReady => completedCount == 3;

  @override
  List<Object?> get props => [problemDefinition, targetAudience, executionPlan];
}

class IdeaModel extends Equatable {
  final String id;
  final String title;
  final String body;
  final String category;
  final IdeaStatus status;
  final String visibility;
  final String rawCapture;
  final String problem;
  final String targetAudience;
  final String executionPlan;
  final String collaborationType;
  final String geographicScope;
  final String innovatorProfession;
  final String innovatorBio;
  final String linkedinUrl;
  final String githubUrl;
  final int maturityScore;
  final MaturityChecklist maturityChecklist;
  final List<String> polishHints;
  final int uniquenessScore;
  final double matchScore;
  final String? matchedIdeaId;
  final String? matchedIdeaTitle;
  final String innovatorId;
  final int price; // USD cents
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? submittedAt;
  final DateTime? reviewedAt;
  final String? reviewedBy;
  final String? reviewNote;
  final int openReportCount;
  final String? lastReportReasonCode;
  final String? lastReportReasonLabel;
  final DateTime? flaggedAt;
  final bool isArchived;
  final bool isDeleted;

  const IdeaModel({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    required this.status,
    this.visibility = 'private',
    this.rawCapture = '',
    this.problem = '',
    this.targetAudience = '',
    this.executionPlan = '',
    this.collaborationType = 'Open',
    this.geographicScope = 'Global',
    this.innovatorProfession = 'Independent innovator',
    this.innovatorBio = '',
    this.linkedinUrl = '',
    this.githubUrl = '',
    this.maturityScore = 0,
    this.maturityChecklist = const MaturityChecklist(),
    this.polishHints = const [],
    required this.uniquenessScore,
    this.matchScore = 0.0,
    this.matchedIdeaId,
    this.matchedIdeaTitle,
    required this.innovatorId,
    required this.price,
    required this.createdAt,
    required this.updatedAt,
    this.submittedAt,
    this.reviewedAt,
    this.reviewedBy,
    this.reviewNote,
    this.openReportCount = 0,
    this.lastReportReasonCode,
    this.lastReportReasonLabel,
    this.flaggedAt,
    this.isArchived = false,
    this.isDeleted = false,
  });

  IdeaModel copyWith({
    String? title,
    String? body,
    String? category,
    IdeaStatus? status,
    String? visibility,
    String? rawCapture,
    String? problem,
    String? targetAudience,
    String? executionPlan,
    String? collaborationType,
    String? geographicScope,
    String? innovatorProfession,
    String? innovatorBio,
    String? linkedinUrl,
    String? githubUrl,
    int? maturityScore,
    MaturityChecklist? maturityChecklist,
    List<String>? polishHints,
    int? uniquenessScore,
    double? matchScore,
    String? matchedIdeaId,
    String? matchedIdeaTitle,
    String? innovatorId,
    int? price,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? submittedAt,
    DateTime? reviewedAt,
    String? reviewedBy,
    String? reviewNote,
    int? openReportCount,
    String? lastReportReasonCode,
    String? lastReportReasonLabel,
    DateTime? flaggedAt,
    bool? isArchived,
    bool? isDeleted,
  }) {
    return IdeaModel(
      id: id,
      title: title ?? this.title,
      body: body ?? this.body,
      category: category ?? this.category,
      status: status ?? this.status,
      visibility: visibility ?? this.visibility,
      rawCapture: rawCapture ?? this.rawCapture,
      problem: problem ?? this.problem,
      targetAudience: targetAudience ?? this.targetAudience,
      executionPlan: executionPlan ?? this.executionPlan,
      collaborationType: collaborationType ?? this.collaborationType,
      geographicScope: geographicScope ?? this.geographicScope,
      innovatorProfession: innovatorProfession ?? this.innovatorProfession,
      innovatorBio: innovatorBio ?? this.innovatorBio,
      linkedinUrl: linkedinUrl ?? this.linkedinUrl,
      githubUrl: githubUrl ?? this.githubUrl,
      maturityScore: maturityScore ?? this.maturityScore,
      maturityChecklist: maturityChecklist ?? this.maturityChecklist,
      polishHints: polishHints ?? this.polishHints,
      uniquenessScore: uniquenessScore ?? this.uniquenessScore,
      matchScore: matchScore ?? this.matchScore,
      matchedIdeaId: matchedIdeaId ?? this.matchedIdeaId,
      matchedIdeaTitle: matchedIdeaTitle ?? this.matchedIdeaTitle,
      innovatorId: innovatorId ?? this.innovatorId,
      price: price ?? this.price,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      submittedAt: submittedAt ?? this.submittedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewNote: reviewNote ?? this.reviewNote,
      openReportCount: openReportCount ?? this.openReportCount,
      lastReportReasonCode: lastReportReasonCode ?? this.lastReportReasonCode,
      lastReportReasonLabel:
          lastReportReasonLabel ?? this.lastReportReasonLabel,
      flaggedAt: flaggedAt ?? this.flaggedAt,
      isArchived: isArchived ?? this.isArchived,
      isDeleted: isDeleted ?? this.isDeleted,
    );
  }

  factory IdeaModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;

    IdeaStatus parseStatus(String? raw) {
      switch (raw) {
        case 'draft':
          return IdeaStatus.draft;
        case 'needs_review':
          return IdeaStatus.needsReview;
        case 'pending_review':
          return IdeaStatus.pendingReview;
        default:
          return IdeaStatus.values.firstWhere(
            (s) => s.name == raw,
            orElse: () => IdeaStatus.processing,
          );
      }
    }

    return IdeaModel(
      id: doc.id,
      title: d['title'] as String? ?? '',
      body: d['body'] as String? ?? '',
      category: d['category'] as String? ?? '',
      status: parseStatus(d['status'] as String?),
      visibility: d['visibility'] as String? ?? 'private',
      rawCapture: d['rawCapture'] as String? ?? '',
      problem: d['problem'] as String? ?? '',
      targetAudience: d['targetAudience'] as String? ?? '',
      executionPlan: d['executionPlan'] as String? ?? '',
      collaborationType: d['collaborationType'] as String? ??
          d['dealType'] as String? ??
          'Open',
      geographicScope:
          d['geographicScope'] as String? ?? d['geo'] as String? ?? 'Global',
      innovatorProfession: d['innovatorProfession'] as String? ??
          d['profession'] as String? ??
          'Independent innovator',
      innovatorBio: d['innovatorBio'] as String? ?? '',
      linkedinUrl: d['linkedinUrl'] as String? ?? '',
      githubUrl: d['githubUrl'] as String? ?? '',
      maturityScore: (d['maturityScore'] as num?)?.toInt() ?? 0,
      maturityChecklist: MaturityChecklist.fromMap(
        d['maturityChecklist'] as Map<String, dynamic>?,
      ),
      polishHints: (d['polishHints'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(),
      uniquenessScore: (d['uniquenessScore'] as num?)?.toInt() ?? 0,
      matchScore: (d['matchScore'] as num?)?.toDouble() ?? 0.0,
      matchedIdeaId: d['matchedIdeaId'] as String?,
      matchedIdeaTitle: d['matchedIdeaTitle'] as String?,
      innovatorId: d['innovatorId'] as String? ?? '',
      price: (d['price'] as num?)?.toInt() ?? 0,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      submittedAt: (d['submittedAt'] as Timestamp?)?.toDate(),
      reviewedAt: (d['reviewedAt'] as Timestamp?)?.toDate(),
      reviewedBy: d['reviewedBy'] as String?,
      reviewNote: d['reviewNote'] as String?,
      openReportCount: ((d['reportSummary']
                  as Map<String, dynamic>?)?['openReportCount'] as num?)
              ?.toInt() ??
          0,
      lastReportReasonCode: (d['reportSummary']
          as Map<String, dynamic>?)?['lastReasonCode'] as String?,
      lastReportReasonLabel: (d['reportSummary']
          as Map<String, dynamic>?)?['lastReasonLabel'] as String?,
      flaggedAt: (d['flaggedAt'] as Timestamp?)?.toDate(),
      isArchived: d['isArchived'] as bool? ?? false,
      isDeleted: d['isDeleted'] as bool? ?? false,
    );
  }

  String get formattedPrice {
    if (price <= 0) return 'Not priced';
    final dollars = price / 100;
    return '\$${dollars.toStringAsFixed(0)}';
  }

  String get statusLabel {
    switch (status) {
      case IdeaStatus.draft:
        return 'Draft';
      case IdeaStatus.processing:
        return 'Analyzing...';
      case IdeaStatus.pendingReview:
        return 'Pending Review';
      case IdeaStatus.active:
        return 'Active';
      case IdeaStatus.flagged:
        return 'Flagged';
      case IdeaStatus.returned:
        return 'Returned';
      case IdeaStatus.needsReview:
        return 'Under Review';
      case IdeaStatus.sold:
        return 'Sold';
      case IdeaStatus.rejected:
        return 'Not Approved';
      case IdeaStatus.archived:
        return 'Archived';
      case IdeaStatus.error:
        return 'Needs Attention';
    }
  }

  @override
  List<Object?> get props => [
        id,
        title,
        status,
        visibility,
        maturityScore,
        uniquenessScore,
        matchScore,
        openReportCount,
        price,
        isArchived,
        isDeleted,
      ];
}
