import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../services/idea_service.dart';

class DevMenuScreen extends StatefulWidget {
  const DevMenuScreen({super.key});

  @override
  State<DevMenuScreen> createState() => _DevMenuScreenState();
}

class _DevMenuScreenState extends State<DevMenuScreen> {
  final _ideaService = IdeaService();

  bool _running = false;
  double _progress = 0.0;
  int _done = 0;
  int _total = 0;
  String? _resultMessage;
  bool _isError = false;

  Future<void> _generate(int count) async {
    setState(() {
      _running = true;
      _progress = 0.0;
      _done = 0;
      _total = count;
      _resultMessage = null;
      _isError = false;
    });

    try {
      await _ideaService.seedTestIdeas(
        count,
        onProgress: (p, done, total) {
          if (mounted) {
            setState(() {
              _progress = p;
              _done = done;
              _total = total;
            });
          }
        },
      );
      if (mounted) {
        setState(() {
          _resultMessage = 'Done! $count ideas seeded successfully.';
          _isError = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _resultMessage = 'Error: $e';
          _isError = true;
        });
      }
    } finally {
      if (mounted) setState(() => _running = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Dev Menu')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'DEV ONLY - bulk client seeding is disabled. Use an admin script.',
                      style: TextStyle(color: AppColors.warning, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            Text('Bulk Idea Generator', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Server-owned idea writes prevent client-side seed data from forging public ideas.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ),
            const SizedBox(height: 32),

            if (_running) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: _progress,
                  backgroundColor: AppColors.darkBorder,
                  color: AppColors.cyan,
                  minHeight: 6,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Writing $_done / $_total ideas...',
                style: theme.textTheme.bodySmall?.copyWith(color: AppColors.cyan),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
            ],

            if (_resultMessage != null && !_running) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: (_isError ? AppColors.error : AppColors.success)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: (_isError ? AppColors.error : AppColors.success)
                        .withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  _resultMessage!,
                  style: TextStyle(
                    color: _isError ? AppColors.error : AppColors.success,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],

            FilledButton.icon(
              onPressed: _running ? null : () => _generate(1000),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.cyan,
                foregroundColor: AppColors.darkBg,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: _running
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.darkBg,
                      ),
                    )
                  : const Icon(Icons.bolt_rounded),
              label: Text(
                _running ? 'Generating...' : 'GENERATE 1000 IDEAS',
                style: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.5),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => context.go('/admin/review'),
              icon: const Icon(Icons.fact_check_outlined),
              label: const Text('OPEN ADMIN REVIEW'),
            ),
          ],
        ),
      ),
    );
  }
}
