import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../providers/demo_session_provider.dart';
import '../../screens/gateway/gateway_screen.dart';
import '../../screens/gateway/role_onboarding_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/register_screen.dart';
import '../../screens/innovator/innovator_dashboard.dart';
import '../../screens/innovator/ideas_screen.dart';
import '../../screens/innovator/submit_idea_screen.dart';
import '../../screens/patron/patron_home_screen.dart';
import '../../screens/patron/the_vault_screen.dart';
import '../../screens/patron/idea_detail_screen.dart';
import '../../screens/patron/paywall_screen.dart';
import '../../screens/pitch/pitch_screen.dart';
import '../../screens/shared/admin_home_screen.dart';
import '../../screens/shared/admin_demo_launcher.dart';
import '../../screens/shared/admin_review_screen.dart';
import '../../screens/shared/notifications_screen.dart';
import '../../screens/shared/profile_screen.dart';
import '../../screens/innovator/idea_result_screen.dart';
import '../../screens/innovator/idea_draft_screen.dart';
import '../../models/idea_model.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final demoActive = ref.watch(demoSessionProvider.select((s) => s.active));
  final demoRole = ref.watch(demoSessionProvider.select((s) => s.role));

  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: false,
    redirect: (context, state) async {
      final user = authState.valueOrNull;
      final isLoggedIn = user != null || demoActive;
      final isAdminDemo = state.matchedLocation == '/admin/demo';
      final isAdminRoute = state.matchedLocation == '/admin' ||
          state.matchedLocation.startsWith('/admin/');
      final isOnAuth = state.matchedLocation.startsWith('/login') ||
          state.matchedLocation.startsWith('/register') ||
          state.matchedLocation.startsWith('/onboarding') ||
          isAdminDemo ||
          state.matchedLocation == '/';

      if (!isLoggedIn && kDebugMode && isAdminRoute && !isAdminDemo) {
        return '/admin/demo';
      }
      if (!isLoggedIn && !isOnAuth) return '/';
      if (isAdminDemo) return null;
      if (!isLoggedIn) return null;
      if (demoActive && isOnAuth) {
        return _landingForDemo(demoRole);
      }
      if (user == null) return null;

      final landing = await _landingForUser(user);
      if (isOnAuth) return landing;
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, __) => const GatewayScreen()),
      GoRoute(
        path: '/onboarding/:role',
        builder: (_, state) =>
            RoleOnboardingScreen(role: state.pathParameters['role']!),
      ),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(
          path: '/register/:role',
          builder: (_, state) =>
              RegisterScreen(role: state.pathParameters['role']!)),

      // Innovator
      GoRoute(
          path: '/innovator', builder: (_, __) => const InnovatorDashboard()),
      GoRoute(path: '/ideas', builder: (_, __) => const IdeasScreen()),
      GoRoute(
          path: '/innovator/submit',
          builder: (_, __) => const SubmitIdeaScreen()),
      GoRoute(
        path: '/innovator/idea/:id',
        builder: (_, state) =>
            IdeaDraftScreen(ideaId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/innovator/result',
        builder: (_, state) => IdeaResultScreen(idea: state.extra as IdeaModel),
      ),

      // Patron
      GoRoute(path: '/patron', builder: (_, __) => const PatronHomeScreen()),
      GoRoute(path: '/vault', builder: (_, __) => const TheVaultScreen()),
      GoRoute(
        path: '/vault/idea/:id',
        builder: (_, state) =>
            IdeaDetailScreen(ideaId: state.pathParameters['id']!),
      ),
      GoRoute(path: '/paywall', builder: (_, __) => const PaywallScreen()),

      // Pitch
      GoRoute(
        path: '/pitch/:id',
        builder: (_, state) =>
            PitchScreen(pitchId: state.pathParameters['id']!),
      ),

      GoRoute(
          path: '/notifications',
          builder: (_, __) => const NotificationsScreen()),
      GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
      GoRoute(
          path: '/admin/demo', builder: (_, __) => const AdminDemoLauncher()),
      GoRoute(path: '/admin', builder: (_, __) => const AdminHomeScreen()),
      GoRoute(
          path: '/admin/review', builder: (_, __) => const AdminReviewScreen()),
    ],
    errorBuilder: (_, state) => Scaffold(
      body: Center(child: Text('Page not found: ${state.uri}')),
    ),
  );
});

String _landingForDemo(DemoRole role) {
  return switch (role) {
    DemoRole.patron => '/patron',
    DemoRole.innovator => '/innovator',
    DemoRole.admin => '/admin',
  };
}

Future<String> _landingForUser(User user) async {
  final db = FirebaseFirestore.instance;
  final token = await user.getIdTokenResult();
  if (token.claims?['admin'] == true) return '/admin';

  final adminDoc = await db.collection('admins').doc(user.uid).get();
  if (adminDoc.exists && adminDoc.data()?['active'] != false) return '/admin';

  final uid = user.uid;
  final userDoc = await db.collection('users').doc(uid).get();
  final role = userDoc.data()?['role'] as String? ?? 'innovator';
  if (role == 'innovator' || role == 'both') return '/innovator';

  final subDoc = await db.collection('subscriptions').doc(uid).get();
  final data = subDoc.data();
  final endDate = (data?['endDate'] as Timestamp?)?.toDate();
  final isActive = data?['status'] == 'active' &&
      endDate != null &&
      endDate.isAfter(DateTime.now());
  return isActive ? '/patron' : '/paywall';
}
