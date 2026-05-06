import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../models/idea_model.dart';
import '../models/idea_report_model.dart';
import '../models/user_model.dart';

class AdminService {
  final _db = FirebaseFirestore.instance;
  final _functions = FirebaseFunctions.instance;

  Stream<List<IdeaModel>> watchIdeaQueue() {
    return _db
        .collection('ideas')
        .where('status', whereIn: ['pending_review', 'needs_review', 'flagged'])
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(IdeaModel.fromFirestore).toList());
  }

  Stream<List<IdeaModel>> watchReportQueue() {
    return _db
        .collection('ideas')
        .where('status', isEqualTo: 'flagged')
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(IdeaModel.fromFirestore).toList());
  }

  Stream<List<IdeaReportModel>> watchOpenReports() {
    return _db
        .collection('ideaReports')
        .where('status', isEqualTo: 'open')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(IdeaReportModel.fromFirestore).toList());
  }

  Stream<List<UserModel>> watchUsers() {
    return _db
        .collection('users')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(UserModel.fromFirestore).toList());
  }

  Stream<List<ReportStatsModel>> watchReportStats() {
    return _db
        .collection('reportStats')
        .orderBy('totalReports', descending: true)
        .orderBy('lastReportAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(ReportStatsModel.fromFirestore).toList());
  }

  Future<void> approveIdea(String ideaId) async {
    await _functions.httpsCallable('approveIdea').call({'ideaId': ideaId});
  }

  Future<void> requestIdeaEdit(String ideaId, String reviewNote) async {
    await _functions.httpsCallable('returnIdeaForImprovement').call({
      'ideaId': ideaId,
      'reviewNote': reviewNote,
    });
  }

  Future<void> rejectIdea(String ideaId, {String? reviewNote}) async {
    await _functions.httpsCallable('rejectIdea').call({
      'ideaId': ideaId,
      if (reviewNote != null) 'reviewNote': reviewNote,
    });
  }

  Future<void> resolveIdeaReport({
    required String ideaId,
    required String resolution,
    String? reviewNote,
  }) async {
    await _functions.httpsCallable('resolveIdeaReport').call({
      'ideaId': ideaId,
      'resolution': resolution,
      if (reviewNote != null) 'reviewNote': reviewNote,
    });
  }

  Future<void> moderateUser({
    required String uid,
    required AccountStatus accountStatus,
    String? moderationNote,
  }) async {
    await _functions.httpsCallable('moderateUser').call({
      'uid': uid,
      'accountStatus': accountStatus.name,
      if (moderationNote != null) 'moderationNote': moderationNote,
    });
  }
}
