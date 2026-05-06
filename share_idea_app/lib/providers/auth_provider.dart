import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authStateProvider = StreamProvider<User?>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

final currentUserProvider = FutureProvider<UserModel?>((ref) async {
  final firebaseUser = ref.watch(authStateProvider).valueOrNull;
  if (firebaseUser == null) return null;

  await firebaseUser.reload();
  final refreshed = FirebaseAuth.instance.currentUser;
  if (refreshed == null) return null;

  // Fetched in screens via Firestore stream — stub returns null here.
  return null;
});
