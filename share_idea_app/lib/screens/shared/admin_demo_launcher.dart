import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../providers/demo_session_provider.dart';

class AdminDemoLauncher extends ConsumerStatefulWidget {
  const AdminDemoLauncher({super.key});

  @override
  ConsumerState<AdminDemoLauncher> createState() => _AdminDemoLauncherState();
}

class _AdminDemoLauncherState extends ConsumerState<AdminDemoLauncher> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(demoSessionProvider.notifier).startAs(DemoRole.admin);
      context.go('/admin');
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.volcanic950,
      body: Center(
        child: CircularProgressIndicator(color: AppColors.ochre),
      ),
    );
  }
}
