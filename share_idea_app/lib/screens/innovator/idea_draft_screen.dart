import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../models/idea_model.dart';
import '../../services/idea_service.dart';
import '../shared/fruma_lab_chrome.dart';
import '../shared/loading_overlay.dart';

class IdeaDraftScreen extends StatefulWidget {
  final String ideaId;
  const IdeaDraftScreen({super.key, required this.ideaId});

  @override
  State<IdeaDraftScreen> createState() => _IdeaDraftScreenState();
}

class _IdeaDraftScreenState extends State<IdeaDraftScreen> {
  final _service = IdeaService();
  final _titleCtrl = TextEditingController();
  final _bodyCtrl = TextEditingController();
  final _rawCtrl = TextEditingController();
  final _problemCtrl = TextEditingController();
  final _audienceCtrl = TextEditingController();
  final _executionCtrl = TextEditingController();

  IdeaModel? _idea;
  String _category = '';
  double _price = AppConstants.ideaMinPrice.toDouble();
  bool _loading = true;
  bool _saving = false;
  bool _autoSaving = false;
  Timer? _autoSaveTimer;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_canEdit && !_saving && !_autoSaving && !_loading) {
        _save(silent: true);
      }
    });
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _titleCtrl.dispose();
    _bodyCtrl.dispose();
    _rawCtrl.dispose();
    _problemCtrl.dispose();
    _audienceCtrl.dispose();
    _executionCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final idea = await _service.getPrivateIdea(widget.ideaId);
      if (!mounted) return;
      _idea = idea;
      _titleCtrl.text = idea.title;
      _bodyCtrl.text = idea.body;
      _rawCtrl.text = idea.rawCapture;
      _problemCtrl.text = idea.problem;
      _audienceCtrl.text = idea.targetAudience;
      _executionCtrl.text = idea.executionPlan;
      _category = idea.category;
      _price = idea.price > 0
          ? idea.price.toDouble()
          : AppConstants.ideaMinPrice.toDouble();
      setState(() => _loading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  int _wordCount(String value) =>
      value.trim().isEmpty ? 0 : value.trim().split(RegExp(r'\s+')).length;

  ({bool problem, bool audience, bool execution, int score}) get _readiness {
    final problem = _wordCount(_problemCtrl.text) >= 8;
    final audience = _wordCount(_audienceCtrl.text) >= 5;
    final execution = _wordCount(_executionCtrl.text) >= 10;
    final count = [problem, audience, execution].where((v) => v).length;
    return (
      problem: problem,
      audience: audience,
      execution: execution,
      score: (count / 3 * 100).round()
    );
  }

  bool get _canEdit {
    final status = _idea?.status;
    return status == IdeaStatus.draft ||
        status == IdeaStatus.returned ||
        status == IdeaStatus.error;
  }

  bool get _canSubmit {
    final ready = _readiness;
    return _canEdit &&
        ready.score == 100 &&
        _titleCtrl.text.trim().isNotEmpty &&
        _bodyCtrl.text.trim().isNotEmpty &&
        _category.isNotEmpty &&
        _price >= AppConstants.ideaMinPrice;
  }

  String get _payoutPreview => '\$${(_price / 100).toStringAsFixed(0)}';

  List<String> get _localHints {
    final hints = <String>[];
    if (_wordCount(_problemCtrl.text) < 8) {
      hints.add('Clarify the business problem in concrete terms.');
    }
    if (_wordCount(_audienceCtrl.text) < 5) {
      hints.add('Name who needs this badly enough to care.');
    }
    if (_wordCount(_executionCtrl.text) < 10) {
      hints.add('Describe the first usable version and how it would work.');
    }
    if (_category.isEmpty) {
      hints.add('Choose a category before review.');
    }
    if (hints.isEmpty) {
      hints.add(
          'This is ready for review. Keep the wording sharp and specific.');
    }
    return hints;
  }

  InputDecoration _softDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.black.withValues(alpha: 0.2),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: AppColors.ochre, width: 1.2),
      ),
    );
  }

  Future<void> _save({bool silent = false}) async {
    if (silent) {
      _autoSaving = true;
    } else {
      setState(() => _saving = true);
    }
    try {
      await _service.updateIdeaDraft(
        ideaId: widget.ideaId,
        rawCapture: _rawCtrl.text.trim(),
        title: _titleCtrl.text.trim(),
        body: _bodyCtrl.text.trim(),
        category: _category,
        price: _price.round(),
        problem: _problemCtrl.text.trim(),
        targetAudience: _audienceCtrl.text.trim(),
        executionPlan: _executionCtrl.text.trim(),
      );
      if (!silent) {
        await _load();
      }
      if (!mounted) return;
      if (!silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Draft saved.'),
              behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      if (!mounted) return;
      if (!silent) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (silent) {
        _autoSaving = false;
      } else if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _submitForReview() async {
    if (!_canSubmit) return;
    setState(() => _saving = true);
    try {
      await _save(silent: true);
      final status = await _service.submitIdeaForReview(widget.ideaId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(status == 'rejected'
              ? 'Smart Engine found a close duplicate.'
              : 'Submitted for review.'),
          backgroundColor:
              status == 'rejected' ? AppColors.error : AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.go('/innovator');
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

    return LoadingOverlay(
      isLoading: _saving,
      label: _saving ? 'Saving...' : null,
      child: Scaffold(
        backgroundColor: AppColors.volcanic950,
        bottomNavigationBar: _canEdit
            ? _DraftActionBar(
                canSubmit: _canSubmit,
                onSave: _save,
                onSubmit: _submitForReview,
              )
            : null,
        body: _loading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.ochre))
            : _error != null
                ? Center(child: Text(_error!, textAlign: TextAlign.center))
                : FrumaLabBackground(
                    intensity: 0.76,
                    child: SafeArea(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(24, 14, 24, 28),
                        children: [
                          FrumaBackButton(
                            onPressed: () => context.canPop()
                                ? context.pop()
                                : context.go('/innovator'),
                          ),
                          const SizedBox(height: 24),
                          const FrumaSectionLabel(label: 'IDEA DRAFT.'),
                          const SizedBox(height: 12),
                          Text(
                            'Idea Lab',
                            style: theme.textTheme.headlineMedium?.copyWith(
                              color: Colors.white,
                              fontFamily: 'SpaceGrotesk',
                              fontSize: 34,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0,
                            ),
                          ),
                          const SizedBox(height: 18),
                          _ReadinessCard(idea: _idea!, readiness: _readiness),
                          const SizedBox(height: 12),
                          _MotivationPanel(price: _payoutPreview),
                          const SizedBox(height: 12),
                          _CoachPanel(hints: _localHints),
                          const SizedBox(height: 14),
                          Column(
                            children: [
                              _FieldBlock(
                                label: 'Raw capture',
                                child: TextField(
                                  controller: _rawCtrl,
                                  enabled: _canEdit,
                                  style: const TextStyle(color: Colors.white),
                                  minLines: 2,
                                  maxLines: 4,
                                  decoration: _softDecoration(
                                      'Keep the messy original thought here.'),
                                ),
                              ),
                              _FieldBlock(
                                label: 'Title',
                                child: TextField(
                                  controller: _titleCtrl,
                                  enabled: _canEdit,
                                  style: const TextStyle(color: Colors.white),
                                  maxLines: 2,
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                  decoration: _softDecoration(
                                      'Give the idea a working title.'),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                              _FieldBlock(
                                label: 'Description',
                                child: TextField(
                                  controller: _bodyCtrl,
                                  enabled: _canEdit,
                                  style: const TextStyle(color: Colors.white),
                                  minLines: 4,
                                  maxLines: 8,
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                  decoration: _softDecoration(
                                      'Describe the idea in plain language.'),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                              _FieldBlock(
                                label: 'Problem Definition',
                                child: TextField(
                                  controller: _problemCtrl,
                                  enabled: _canEdit,
                                  style: const TextStyle(color: Colors.white),
                                  minLines: 3,
                                  maxLines: 6,
                                  decoration: _softDecoration(
                                      'What painful problem does this solve?'),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                              _FieldBlock(
                                label: 'Target Audience',
                                child: TextField(
                                  controller: _audienceCtrl,
                                  enabled: _canEdit,
                                  style: const TextStyle(color: Colors.white),
                                  minLines: 2,
                                  maxLines: 4,
                                  decoration: _softDecoration(
                                      'Who is this for? Be specific.'),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                              _FieldBlock(
                                label: 'Execution Plan',
                                child: TextField(
                                  controller: _executionCtrl,
                                  enabled: _canEdit,
                                  style: const TextStyle(color: Colors.white),
                                  minLines: 3,
                                  maxLines: 6,
                                  decoration: _softDecoration(
                                      'What would the first usable version include?'),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                              _FieldBlock(
                                label: 'Category',
                                child: DropdownButtonFormField<String>(
                                  value: _category.isEmpty ? null : _category,
                                  dropdownColor: AppColors.labPanelRaised,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: const InputDecoration(
                                      hintText: 'Choose category'),
                                  items:
                                      AppConstants.categories.map((category) {
                                    final priority = {
                                      'SaaS',
                                      'Green Tech',
                                      'Local Solutions'
                                    }.contains(category);
                                    return DropdownMenuItem(
                                      value: category,
                                      child: Text(priority
                                          ? '$category - priority'
                                          : category),
                                    );
                                  }).toList(),
                                  onChanged: _canEdit
                                      ? (value) => setState(
                                          () => _category = value ?? '')
                                      : null,
                                ),
                              ),
                              _FieldBlock(
                                label: 'Asking Price',
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _payoutPreview,
                                      style:
                                          theme.textTheme.titleMedium?.copyWith(
                                        color: Colors.white,
                                        fontFamily: 'SpaceGrotesk',
                                      ),
                                    ),
                                    Slider(
                                      value: _price,
                                      min: AppConstants.ideaMinPrice.toDouble(),
                                      max: AppConstants.ideaMaxPrice.toDouble(),
                                      divisions: 99,
                                      activeColor: AppColors.ochre,
                                      onChanged: _canEdit
                                          ? (value) =>
                                              setState(() => _price = value)
                                          : null,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          if (_idea?.reviewNote?.isNotEmpty == true) ...[
                            const SizedBox(height: 4),
                            _ReviewNote(note: _idea!.reviewNote!),
                            const SizedBox(height: 20),
                          ],
                          const SizedBox(height: 84),
                        ],
                      ),
                    ),
                  ),
      ),
    );
  }
}

class _DraftActionBar extends StatelessWidget {
  final bool canSubmit;
  final VoidCallback onSave;
  final VoidCallback onSubmit;

  const _DraftActionBar({
    required this.canSubmit,
    required this.onSave,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
        decoration: BoxDecoration(
          color: AppColors.labBlack.withValues(alpha: 0.96),
          border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.08))),
        ),
        child: Row(
          children: [
            Expanded(
              child: FrumaLabButton(
                label: 'Save Draft',
                secondary: true,
                onPressed: onSave,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FrumaLabButton(
                label: 'Submit',
                onPressed: canSubmit ? onSubmit : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MotivationPanel extends StatelessWidget {
  final String price;
  const _MotivationPanel({required this.price});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.patinaTeal.withValues(alpha: 0.24)),
          bottom:
              BorderSide(color: AppColors.patinaTeal.withValues(alpha: 0.24)),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.payments_outlined,
                color: AppColors.ochre, size: 21),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'When this reaches the Vault, a Patron can buy it for $price or request a partnership pitch. Your identity stays hidden until you accept collaboration.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.72),
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReadinessCard extends StatelessWidget {
  final IdeaModel idea;
  final ({bool problem, bool audience, bool execution, int score}) readiness;

  const _ReadinessCard({
    required this.idea,
    required this.readiness,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          children: [
            Row(
              children: [
                SizedBox(
                  width: 48,
                  height: 48,
                  child: CircularProgressIndicator(
                    value: readiness.score / 100,
                    strokeWidth: 5,
                    color: AppColors.ochre,
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Vault Ready',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontFamily: 'SpaceGrotesk',
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${readiness.score}% - ${idea.statusLabel}',
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.42)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _Checklist(readiness: readiness),
          ],
        ),
      ),
    );
  }
}

class _Checklist extends StatelessWidget {
  final ({bool problem, bool audience, bool execution, int score}) readiness;
  const _Checklist({required this.readiness});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _CheckRow(label: 'Problem Definition', done: readiness.problem),
        _CheckRow(label: 'Target Audience', done: readiness.audience),
        _CheckRow(label: 'Execution Plan', done: readiness.execution),
      ],
    );
  }
}

class _CheckRow extends StatelessWidget {
  final String label;
  final bool done;
  const _CheckRow({required this.label, required this.done});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          Icon(
            done
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            size: 18,
            color: done
                ? AppColors.patinaTeal
                : Colors.white.withValues(alpha: 0.24),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: done
                    ? Colors.white.withValues(alpha: 0.78)
                    : Colors.white.withValues(alpha: 0.38),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CoachPanel extends StatelessWidget {
  final List<String> hints;
  const _CoachPanel({required this.hints});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_fix_high_rounded,
                    size: 18, color: AppColors.ochre),
                const SizedBox(width: 8),
                Text(
                  'Next Steps',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontFamily: 'SpaceGrotesk',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...hints.map((hint) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    '- $hint',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.45),
                    ),
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

class _FieldBlock extends StatelessWidget {
  final String label;
  final Widget child;
  const _FieldBlock({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.78),
                  fontFamily: 'SpaceGrotesk',
                ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _ReviewNote extends StatelessWidget {
  final String note;
  const _ReviewNote({required this.note});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: AppColors.warning.withValues(alpha: 0.28)),
          bottom: BorderSide(color: AppColors.warning.withValues(alpha: 0.28)),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Text(
          note,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.58),
              ),
        ),
      ),
    );
  }
}
