import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/idea_model.dart';
import '../models/idea_report_model.dart';

class IdeaService {
  final _db = FirebaseFirestore.instance;
  final _functions = FirebaseFunctions.instance;

  /// Innovator: capture a raw thought as a private draft.
  Future<String> quickCaptureIdea(String rawText) async {
    final result = await _functions.httpsCallable('quickCaptureIdea').call({
      'rawText': rawText,
    });
    return result.data['ideaId'] as String;
  }

  /// Innovator: update a draft/refinement record through server validation.
  Future<void> updateIdeaDraft({
    required String ideaId,
    String? rawCapture,
    String? title,
    String? body,
    String? category,
    int? price,
    String? problem,
    String? targetAudience,
    String? executionPlan,
  }) async {
    final data = <String, dynamic>{'ideaId': ideaId};
    if (rawCapture != null) data['rawCapture'] = rawCapture;
    if (title != null) data['title'] = title;
    if (body != null) data['body'] = body;
    if (category != null) data['category'] = category;
    if (price != null) data['price'] = price;
    if (problem != null) data['problem'] = problem;
    if (targetAudience != null) data['targetAudience'] = targetAudience;
    if (executionPlan != null) data['executionPlan'] = executionPlan;
    await _functions.httpsCallable('updateIdeaDraft').call(data);
  }

  /// Innovator: submit a mature draft into Smart Engine + admin review.
  Future<String> submitIdeaForReview(String ideaId) async {
    final result = await _functions.httpsCallable('submitIdeaForReview').call({
      'ideaId': ideaId,
    });
    return result.data['status'] as String? ?? 'processing';
  }

  /// Innovator: submit a new idea through the server-owned workflow.
  /// Legacy compatibility path. New UI should use quickCapture/update/submitForReview.
  Future<String> submitIdea({
    required String title,
    required String body,
    required String category,
    required String innovatorId,
    required int priceInCents,
  }) async {
    final result = await _functions.httpsCallable('submitIdea').call({
      'title': title,
      'body': body,
      'category': category,
      'price': priceInCents,
    });
    return result.data['ideaId'] as String;
  }

  /// Innovator: stream their own ideas, filtered by archive state.
  Stream<List<IdeaModel>> watchMyIdeas(
    String innovatorId, {
    bool showArchived = false,
  }) {
    return _db
        .collection('ideas')
        .where('innovatorId', isEqualTo: innovatorId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map(IdeaModel.fromFirestore)
            .where((i) => !i.isDeleted && i.isArchived == showArchived)
            .toList());
  }

  /// Innovator: archive or unarchive their own idea.
  Future<void> archiveIdea(String ideaId, {bool archive = true}) async {
    await _functions.httpsCallable('archiveIdea').call({
      'ideaId': ideaId,
      'archive': archive,
    });
  }

  /// Innovator: soft-delete their own idea.
  Future<void> deleteIdea(String ideaId) async {
    await _functions.httpsCallable('deleteIdea').call({
      'ideaId': ideaId,
    });
  }

  /// Patron: stream all active public ideas for The Vault.
  Stream<List<IdeaModel>> watchVault({String? category}) {
    Query<Map<String, dynamic>> q = _db
        .collection('publicIdeas')
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true);
    if (category != null && category != 'All') {
      q = q.where('category', isEqualTo: category);
    }
    return q
        .snapshots()
        .map((snap) => snap.docs.map(IdeaModel.fromFirestore).toList());
  }

  /// Patron: fetch single public idea detail.
  Future<IdeaModel> getIdea(String ideaId) async {
    final doc = await _db.collection('publicIdeas').doc(ideaId).get();
    if (!doc.exists) throw Exception('Idea not found.');
    return IdeaModel.fromFirestore(doc);
  }

  /// Innovator/admin: fetch a private idea document.
  Future<IdeaModel> getPrivateIdea(String ideaId) async {
    final doc = await _db.collection('ideas').doc(ideaId).get();
    if (!doc.exists) throw Exception('Idea not found.');
    return IdeaModel.fromFirestore(doc);
  }

  /// Admin: stream private ideas waiting for moderation.
  Stream<List<IdeaModel>> watchReviewQueue() {
    return _db
        .collection('ideas')
        .where('status', whereIn: ['pending_review', 'needs_review', 'flagged'])
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(IdeaModel.fromFirestore).toList());
  }

  Future<void> approveIdea(String ideaId) async {
    await _functions.httpsCallable('approveIdea').call({'ideaId': ideaId});
  }

  Future<void> returnIdeaForImprovement(
      String ideaId, String reviewNote) async {
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

  /// Patron: submit a required-reason report for manual admin review.
  Future<void> reportIdea({
    required String ideaId,
    required IdeaReportReason reason,
    String? details,
  }) async {
    await _functions.httpsCallable('reportIdea').call({
      'ideaId': ideaId,
      'reason': reason.code,
      if (details != null && details.trim().isNotEmpty)
        'details': details.trim(),
    });
  }

  /// Bulk client-side seeding was removed because idea writes are server-owned.
  Future<void> seedTestIdeas(
    int count, {
    void Function(double progress, int done, int total)? onProgress,
  }) async {
    onProgress?.call(0, 0, count);
    throw UnsupportedError(
      'Bulk seeding now requires an admin/server script so publicIdeas cannot be forged by clients.',
    );
  }
}
