import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class LoadingOverlay extends StatelessWidget {
  final bool isLoading;
  final Widget child;

  final String? label;
  const LoadingOverlay({super.key, required this.isLoading, required this.child, this.label});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Container(
            color: Colors.black.withValues(alpha: 0.55),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(color: AppColors.cyan),
                  if (label != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      label!,
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ],
              ),
            ),
          ),
      ],
    );
  }
}
