import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kReleaseMode, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'firebase_options.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (AppConstants.stripePublishableKey.isNotEmpty) {
    Stripe.publishableKey = AppConstants.stripePublishableKey;
    await Stripe.instance.applySettings();
  }

  if (kReleaseMode && defaultTargetPlatform == TargetPlatform.android) {
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.playIntegrity,
    );
  } else if (kReleaseMode && defaultTargetPlatform == TargetPlatform.iOS) {
    await FirebaseAppCheck.instance.activate(
      appleProvider: AppleProvider.appAttest,
    );
  }

  runApp(const ProviderScope(child: ShareYourIdeaApp()));
}

class ShareYourIdeaApp extends ConsumerWidget {
  const ShareYourIdeaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      routerConfig: router,
    );
  }
}
