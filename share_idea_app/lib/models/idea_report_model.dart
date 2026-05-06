import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum IdeaReportReason {
  duplicateFalseNegative,
  misleadingOrFalseDescription,
  tosViolation,
  illegalContent,
}

extension IdeaReportReasonX on IdeaReportReason {
  String get code {
    return switch (this) {
      IdeaReportReason.duplicateFalseNegative => 'duplicate_false_negative',
      IdeaReportReason.misleadingOrFalseDescription =>
        'misleading_or_false_description',
      IdeaReportReason.tosViolation => 'tos_violation',
      IdeaReportReason.illegalContent => 'illegal_content',
    };
  }

  String get label {
    return switch (this) {
      IdeaReportReason.duplicateFalseNegative =>
        'Duplicate of existing idea (IIAE false negative)',
      IdeaReportReason.misleadingOrFalseDescription =>
        'Misleading or false description',
      IdeaReportReason.tosViolation => 'Violation of ToS',
      IdeaReportReason.illegalContent => 'Illegal content',
    };
  }
}

IdeaReportReason? ideaReportReasonFromCode(String? code) {
  for (final reason in IdeaReportReason.values) {
    if (reason.code == code) return reason;
  }
  return null;
}

class IdeaReportModel extends Equatable {
  final String id;
  final String ideaId;
  final String reporterId;
  final String innovatorId;
  final String reasonCode;
  final String reasonLabel;
  final String details;
  final String status;
  final String? resolution;
  final bool? falseReport;
  final String ideaTitle;
  final String ideaCategory;
  final int uniquenessScore;
  final double matchScore;
  final DateTime createdAt;
  final DateTime? resolvedAt;

  const IdeaReportModel({
    required this.id,
    required this.ideaId,
    required this.reporterId,
    required this.innovatorId,
    required this.reasonCode,
    required this.reasonLabel,
    required this.details,
    required this.status,
    required this.resolution,
    required this.falseReport,
    required this.ideaTitle,
    required this.ideaCategory,
    required this.uniquenessScore,
    required this.matchScore,
    required this.createdAt,
    required this.resolvedAt,
  });

  factory IdeaReportModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final snapshot = d['ideaSnapshot'] as Map<String, dynamic>? ?? const {};
    return IdeaReportModel(
      id: doc.id,
      ideaId: d['ideaId'] as String? ?? '',
      reporterId: d['reporterId'] as String? ?? d['patronId'] as String? ?? '',
      innovatorId: d['innovatorId'] as String? ?? '',
      reasonCode: d['reasonCode'] as String? ?? '',
      reasonLabel: d['reasonLabel'] as String? ??
          ideaReportReasonFromCode(d['reasonCode'] as String?)?.label ??
          'Unknown reason',
      details: d['details'] as String? ?? '',
      status: d['status'] as String? ?? 'open',
      resolution: d['resolution'] as String?,
      falseReport: d['falseReport'] as bool?,
      ideaTitle: snapshot['title'] as String? ?? '',
      ideaCategory: snapshot['category'] as String? ?? '',
      uniquenessScore: (snapshot['uniquenessScore'] as num?)?.toInt() ?? 0,
      matchScore: (snapshot['matchScore'] as num?)?.toDouble() ?? 0,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      resolvedAt: (d['resolvedAt'] as Timestamp?)?.toDate(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        ideaId,
        reporterId,
        reasonCode,
        status,
        resolution,
        falseReport,
        createdAt,
      ];
}

class ReportStatsModel extends Equatable {
  final String patronId;
  final int totalReports;
  final int openReports;
  final int falseReports;
  final int validReports;
  final int resolvedReports;
  final bool accountReviewFlag;
  final DateTime? lastReportAt;
  final DateTime? lastResolvedAt;

  const ReportStatsModel({
    required this.patronId,
    required this.totalReports,
    required this.openReports,
    required this.falseReports,
    required this.validReports,
    required this.resolvedReports,
    required this.accountReviewFlag,
    required this.lastReportAt,
    required this.lastResolvedAt,
  });

  factory ReportStatsModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return ReportStatsModel(
      patronId: d['patronId'] as String? ?? d['uid'] as String? ?? doc.id,
      totalReports: (d['totalReports'] as num?)?.toInt() ?? 0,
      openReports: (d['openReports'] as num?)?.toInt() ?? 0,
      falseReports: (d['falseReports'] as num?)?.toInt() ?? 0,
      validReports: (d['validReports'] as num?)?.toInt() ?? 0,
      resolvedReports: (d['resolvedReports'] as num?)?.toInt() ?? 0,
      accountReviewFlag: d['accountReviewFlag'] as bool? ?? false,
      lastReportAt: (d['lastReportAt'] as Timestamp?)?.toDate(),
      lastResolvedAt: (d['lastResolvedAt'] as Timestamp?)?.toDate(),
    );
  }

  @override
  List<Object?> get props => [
        patronId,
        totalReports,
        openReports,
        falseReports,
        validReports,
        resolvedReports,
        accountReviewFlag,
        lastReportAt,
        lastResolvedAt,
      ];
}
