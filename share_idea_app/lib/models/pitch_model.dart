import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum PitchStatus { pending, accepted, rejected, submitted, completed }

class PitchModel extends Equatable {
  final String id;
  final String ideaId;
  final String patronId;
  final String innovatorId;
  final PitchStatus status;
  final String patronMessage;
  final String innovatorPitch;
  final String contactEmail;
  final String ideaTitle;
  final String ideaCategory;
  final DateTime createdAt;

  const PitchModel({
    required this.id,
    required this.ideaId,
    required this.patronId,
    required this.innovatorId,
    required this.status,
    required this.patronMessage,
    required this.innovatorPitch,
    required this.contactEmail,
    this.ideaTitle = 'Deal Room',
    this.ideaCategory = '',
    required this.createdAt,
  });

  factory PitchModel.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    final ideaSnapshot = d['publicIdeaSnapshot'] as Map<String, dynamic>? ?? {};
    return PitchModel(
      id: doc.id,
      ideaId: d['ideaId'] as String? ?? '',
      patronId: d['patronId'] as String? ?? '',
      innovatorId: d['innovatorId'] as String? ?? '',
      status: PitchStatus.values.firstWhere(
        (s) => s.name == d['status'],
        orElse: () => PitchStatus.pending,
      ),
      patronMessage: d['patronMessage'] as String? ?? '',
      innovatorPitch: d['innovatorPitch'] as String? ?? '',
      contactEmail: d['contactEmail'] as String? ?? '',
      ideaTitle: ideaSnapshot['title'] as String? ??
          d['ideaTitle'] as String? ??
          'Deal Room',
      ideaCategory: ideaSnapshot['category'] as String? ??
          d['ideaCategory'] as String? ??
          '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [id, ideaId, patronId, status];
}
