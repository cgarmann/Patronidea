import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/demo_session_provider.dart';
import '../../services/idea_service.dart';
import '../shared/fruma_lab_chrome.dart';
import '../shared/loading_overlay.dart';

class SubmitIdeaScreen extends ConsumerStatefulWidget {
  const SubmitIdeaScreen({super.key});

  @override
  ConsumerState<SubmitIdeaScreen> createState() => _SubmitIdeaScreenState();
}

class _SubmitIdeaScreenState extends ConsumerState<SubmitIdeaScreen> {
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  final _service = IdeaService();

  String _category = '';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl.addListener(_refreshSuggestion);
    _bodyCtrl.addListener(_refreshSuggestion);
  }

  @override
  void dispose() {
    _titleCtrl
      ..removeListener(_refreshSuggestion)
      ..dispose();
    _bodyCtrl
      ..removeListener(_refreshSuggestion)
      ..dispose();
    super.dispose();
  }

  void _refreshSuggestion() {
    if (_category.isEmpty) setState(() {});
  }

  String get _suggestedCategory {
    final text = '${_titleCtrl.text} ${_bodyCtrl.text}'.toLowerCase();
    if (text.contains('ai') ||
        text.contains('automation') ||
        text.contains('robot')) {
      return 'Technology';
    }
    if (text.contains('climate') ||
        text.contains('energy') ||
        text.contains('green')) {
      return 'Green Tech';
    }
    if (text.contains('school') ||
        text.contains('learn') ||
        text.contains('education')) {
      return 'Education';
    }
    if (text.contains('money') ||
        text.contains('payment') ||
        text.contains('finance')) {
      return 'Finance';
    }
    return 'SaaS';
  }

  Future<void> _saveDraft() async {
    final title = _titleCtrl.text.trim();
    final body = _bodyCtrl.text.trim();
    final category = _category.isEmpty ? _suggestedCategory : _category;

    if (title.length < 4 || body.length < 12) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Add a title and a short description first.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final demo = ref.read(demoSessionProvider);
      if (demo.active) {
        ref.read(demoSessionProvider.notifier).addDraftIdea(
              title: title,
              body: body,
              category: category,
            );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Demo idea saved under review.'),
            backgroundColor: AppColors.success,
          ),
        );
        context.go('/innovator');
        return;
      }

      final raw = '$title\n\n$body';
      final ideaId = await _service.quickCaptureIdea(raw);
      await _service.updateIdeaDraft(
        ideaId: ideaId,
        title: title,
        body: body,
        category: category,
        price: AppConstants.ideaMinPrice,
        rawCapture: raw,
      );
      if (!mounted) return;
      context.go('/innovator/idea/$ideaId');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final suggestion = _suggestedCategory;

    return LoadingOverlay(
      isLoading: _saving,
      label: 'Saving draft...',
      child: Scaffold(
        backgroundColor: AppColors.volcanic950,
        body: FrumaLabBackground(
          child: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 14, 24, 32),
              children: [
                FrumaBackButton(
                  onPressed: () => context.canPop()
                      ? context.pop()
                      : context.go('/innovator'),
                ),
                const SizedBox(height: 28),
                const FrumaSectionLabel(label: 'IDEA CAPTURE.'),
                const SizedBox(height: 14),
                Text(
                  'Capture the core',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: Colors.white,
                    fontFamily: 'SpaceGrotesk',
                    fontSize: 34,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Short, clear and specific. FRUMA can refine after the draft exists.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.44),
                  ),
                ),
                const SizedBox(height: 28),
                TextField(
                  controller: _titleCtrl,
                  style: const TextStyle(color: Colors.white),
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    hintText: 'What is the idea?',
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _bodyCtrl,
                  style: const TextStyle(color: Colors.white),
                  minLines: 5,
                  maxLines: 8,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Who is it for, and what problem does it solve?',
                  ),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  value: _category.isEmpty ? null : _category,
                  dropdownColor: AppColors.labPanelRaised,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: AppConstants.categories
                      .map(
                        (category) => DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _category = value ?? ''),
                ),
                const SizedBox(height: 18),
                _SuggestionChip(
                  suggestion: suggestion,
                  onTap: () => setState(() => _category = suggestion),
                ),
                const SizedBox(height: 26),
                FrumaLabButton(
                  label: 'Save draft',
                  icon: Icons.save_outlined,
                  onPressed: _saveDraft,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final String suggestion;
  final VoidCallback onTap;

  const _SuggestionChip({
    required this.suggestion,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
            bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 15),
          child: Row(
            children: [
              const Icon(Icons.auto_awesome_rounded,
                  color: AppColors.ochre, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'AI SUGGESTION: $suggestion',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.78),
                    fontFamily: 'SpaceGrotesk',
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.3,
                  ),
                ),
              ),
              const Text(
                'USE',
                style: TextStyle(
                  color: AppColors.patinaTeal,
                  fontFamily: 'SpaceGrotesk',
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.8,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
