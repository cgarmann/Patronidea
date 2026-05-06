import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;
  final _googleSignIn = GoogleSignIn();

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserModel> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
    required UserRole role,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
    await cred.user!.updateDisplayName(displayName);
    final userModel = UserModel(
      uid: cred.user!.uid,
      displayName: displayName,
      email: email,
      role: role,
      isActivePatron: false,
      createdAt: DateTime.now(),
    );
    await _db.collection('users').doc(cred.user!.uid).set(userModel.toFirestore());
    return userModel;
  }

  Future<UserModel> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
    return _fetchUser(cred.user!.uid);
  }

  Future<UserModel> signInWithGoogle({required UserRole role}) async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) throw Exception('Google sign-in cancelled.');

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final cred = await _auth.signInWithCredential(credential);
    final uid = cred.user!.uid;

    final existing = await _db.collection('users').doc(uid).get();
    if (!existing.exists) {
      final userModel = UserModel(
        uid: uid,
        displayName: cred.user!.displayName ?? googleUser.displayName ?? 'User',
        email: cred.user!.email ?? '',
        role: role,
        isActivePatron: false,
        createdAt: DateTime.now(),
      );
      await _db.collection('users').doc(uid).set(userModel.toFirestore());
      return userModel;
    }
    return UserModel.fromFirestore(existing);
  }

  Future<UserModel> _fetchUser(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) throw Exception('User record not found.');
    return UserModel.fromFirestore(doc);
  }

  Future<void> signOut() async {
    await Future.wait([_auth.signOut(), _googleSignIn.signOut()]);
  }

  Future<void> sendPasswordReset(String email) =>
      _auth.sendPasswordResetEmail(email: email);
}
