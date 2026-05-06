import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/deal_room_model.dart';
import '../models/pitch_model.dart';

class PitchService {
  final _db = FirebaseFirestore.instance;
  final _functions = FirebaseFunctions.instance;

  /// Patron: request a pitch (calls Cloud Function for server-side validation)
  Future<String> requestPitch({
    required String ideaId,
    required String message,
  }) async {
    final result = await _functions.httpsCallable('requestPitch').call({
      'ideaId': ideaId,
      'message': message,
    });
    return result.data['pitchId'] as String;
  }

  /// Innovator: stream incoming pitch requests
  Stream<List<PitchModel>> watchIncomingPitches(String innovatorId) {
    return _db
        .collection('pitches')
        .where('innovatorId', isEqualTo: innovatorId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(PitchModel.fromFirestore).toList());
  }

  /// Innovator: accept a pitch request and write their pitch text
  Future<void> acceptPitch({
    required String pitchId,
    required String innovatorPitch,
    required String contactEmail,
  }) async {
    await _functions.httpsCallable('acceptPitch').call({
      'pitchId': pitchId,
    });
    await _functions.httpsCallable('submitPitch').call({
      'pitchId': pitchId,
      'pitchText': innovatorPitch,
      'contactEmail': contactEmail,
    });
  }

  /// Innovator: reject a pitch request
  Future<void> rejectPitch(String pitchId) async {
    await _functions.httpsCallable('rejectPitch').call({'pitchId': pitchId});
  }

  /// Fetch a single pitch (for Patron to view accepted details)
  Future<PitchModel> getPitch(String pitchId) async {
    final doc = await _db.collection('pitches').doc(pitchId).get();
    if (!doc.exists) throw Exception('Pitch not found.');
    return PitchModel.fromFirestore(doc);
  }

  Stream<PitchModel> watchPitch(String pitchId) {
    return _db
        .collection('pitches')
        .doc(pitchId)
        .snapshots()
        .where((doc) => doc.exists)
        .map(PitchModel.fromFirestore);
  }

  Future<void> approvePitchRequest(String pitchId) async {
    await _functions.httpsCallable('acceptPitch').call({'pitchId': pitchId});
  }

  /// Patron: stream their sent pitch requests
  Stream<List<PitchModel>> watchMyRequests(String patronId) {
    return _db
        .collection('pitches')
        .where('patronId', isEqualTo: patronId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(PitchModel.fromFirestore).toList());
  }

  Stream<List<DealMessage>> watchDealMessages(String pitchId) {
    return _db
        .collection('pitches')
        .doc(pitchId)
        .collection('messages')
        .orderBy('createdAt')
        .snapshots()
        .map((snap) => snap.docs.map(DealMessage.fromFirestore).toList());
  }

  Stream<List<DealProposal>> watchDealProposals(String pitchId) {
    return _db
        .collection('pitches')
        .doc(pitchId)
        .collection('proposals')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(DealProposal.fromFirestore).toList());
  }

  Future<void> sendDealMessage({
    required String pitchId,
    required String body,
  }) async {
    await _functions.httpsCallable('sendDealMessage').call({
      'pitchId': pitchId,
      'body': body,
    });
  }

  Future<void> submitDealProposal({
    required String pitchId,
    required int amount,
    required String currency,
    required String collaborationType,
    required String message,
  }) async {
    await _functions.httpsCallable('submitDealProposal').call({
      'pitchId': pitchId,
      'amount': amount,
      'currency': currency,
      'collaborationType': collaborationType,
      'message': message,
    });
  }

  Future<void> respondDealProposal({
    required String pitchId,
    required String proposalId,
    required String action,
  }) async {
    await _functions.httpsCallable('respondDealProposal').call({
      'pitchId': pitchId,
      'proposalId': proposalId,
      'action': action,
    });
  }

  Future<void> reportDealIssue({
    required String pitchId,
    required String reason,
  }) async {
    await _functions.httpsCallable('reportDealIssue').call({
      'pitchId': pitchId,
      'reason': reason,
    });
  }
}
