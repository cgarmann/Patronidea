import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

enum DealProposalStatus { active, accepted, declined, countered }

class DealMessage extends Equatable {
  final String id;
  final String senderId;
  final String senderRole;
  final String body;
  final DateTime createdAt;

  const DealMessage({
    required this.id,
    required this.senderId,
    required this.senderRole,
    required this.body,
    required this.createdAt,
  });

  factory DealMessage.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return DealMessage(
      id: doc.id,
      senderId: d['senderId'] as String? ?? '',
      senderRole: d['senderRole'] as String? ?? '',
      body: d['body'] as String? ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [id, senderId, senderRole, body, createdAt];
}

class DealProposal extends Equatable {
  final String id;
  final String senderId;
  final String senderRole;
  final DealProposalStatus status;
  final int amount;
  final String currency;
  final String collaborationType;
  final String message;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DealProposal({
    required this.id,
    required this.senderId,
    required this.senderRole,
    required this.status,
    required this.amount,
    required this.currency,
    required this.collaborationType,
    required this.message,
    required this.createdAt,
    required this.updatedAt,
  });

  factory DealProposal.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return DealProposal(
      id: doc.id,
      senderId: d['senderId'] as String? ?? '',
      senderRole: d['senderRole'] as String? ?? '',
      status: DealProposalStatus.values.firstWhere(
        (s) => s.name == d['status'],
        orElse: () => DealProposalStatus.active,
      ),
      amount: (d['amount'] as num?)?.toInt() ?? 0,
      currency: d['currency'] as String? ?? 'NOK',
      collaborationType: d['collaborationType'] as String? ?? 'Open',
      message: d['message'] as String? ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (d['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  String get formattedAmount {
    final major = amount / 100;
    final rounded = major == major.roundToDouble()
        ? major.toStringAsFixed(0)
        : major.toStringAsFixed(2);
    return '$rounded $currency';
  }

  @override
  List<Object?> get props => [
        id,
        senderId,
        senderRole,
        status,
        amount,
        currency,
        collaborationType,
        message,
      ];
}
