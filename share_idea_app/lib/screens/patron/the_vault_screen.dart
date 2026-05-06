import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../models/idea_model.dart';
import '../../providers/demo_session_provider.dart';
import '../../services/idea_service.dart';
import '../shared/fruma_lab_chrome.dart';
import '../shared/main_scaffold.dart';

enum VaultStatusFilter { all, live, fresh }

enum VaultDateFilter { newest, oldest }

class VaultFilters {
  final String category;
  final String profession;
  final String geo;
  final VaultStatusFilter status;
  final VaultDateFilter date;
  final bool expanded;

  const VaultFilters({
    this.category = 'All',
    this.profession = 'All',
    this.geo = 'All',
    this.status = VaultStatusFilter.all,
    this.date = VaultDateFilter.newest,
    this.expanded = false,
  });

  VaultFilters copyWith({
    String? category,
    String? profession,
    String? geo,
    VaultStatusFilter? status,
    VaultDateFilter? date,
    bool? expanded,
  }) {
    return VaultFilters(
      category: category ?? this.category,
      profession: profession ?? this.profession,
      geo: geo ?? this.geo,
      status: status ?? this.status,
      date: date ?? this.date,
      expanded: expanded ?? this.expanded,
    );
  }

  bool get hasActiveFilters =>
      category != 'All' ||
      profession != 'All' ||
      geo != 'All' ||
      status != VaultStatusFilter.all ||
      date != VaultDateFilter.newest;
}

final vaultFiltersProvider =
    StateProvider.autoDispose<VaultFilters>((_) => const VaultFilters());

final _vaultProvider = StreamProvider.autoDispose<List<IdeaModel>>((ref) {
  final demo = ref.watch(demoSessionProvider);
  if (demo.active) return Stream.value(demo.vaultIdeas);
  return IdeaService().watchVault();
});

final _patronStatusProvider = FutureProvider.autoDispose<bool>((ref) async {
  final demo = ref.watch(demoSessionProvider);
  if (demo.active) return true;
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return false;
  final doc = await FirebaseFirestore.instance
      .collection('subscriptions')
      .doc(uid)
      .get();
  final data = doc.data();
  final endDate = (data?['endDate'] as Timestamp?)?.toDate();
  return data?['status'] == 'active' &&
      endDate != null &&
      endDate.isAfter(DateTime.now());
});

class TheVaultScreen extends ConsumerWidget {
  const TheVaultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patronAsync = ref.watch(_patronStatusProvider);

    return patronAsync.when(
      loading: () => const Scaffold(
        body: _EmptyVaultState.loading(),
      ),
      error: (_, __) => const Scaffold(
        body: _EmptyVaultState(
          title: 'Vault unavailable',
          body: 'We could not verify access right now.',
          icon: Icons.error_outline_rounded,
        ),
      ),
      data: (isPatron) {
        if (!isPatron) return const _VaultPreview();
        return const _VaultContent();
      },
    );
  }
}

class _VaultContent extends ConsumerStatefulWidget {
  const _VaultContent();

  @override
  ConsumerState<_VaultContent> createState() => _VaultContentState();
}

class _VaultContentState extends ConsumerState<_VaultContent> {
  final _searchCtrl = TextEditingController();
  final _searchFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _searchFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filters = ref.watch(vaultFiltersProvider);
    final ideasAsync = ref.watch(_vaultProvider);
    final demo = ref.watch(demoSessionProvider);

    return Scaffold(
      backgroundColor: AppColors.volcanic950,
      body: FrumaLabBackground(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    FrumaLabHeader(
                      activeMode: 'patron',
                      onInnovator: () {
                        if (demo.active) {
                          ref
                              .read(demoSessionProvider.notifier)
                              .switchTo(DemoRole.innovator);
                        }
                        context.go('/innovator');
                      },
                      onPatron: () => context.go('/patron'),
                    ),
                    Positioned(
                      right: 0,
                      child: IconButton(
                        tooltip: 'Profile',
                        onPressed: () => context.go('/profile'),
                        icon: Icon(
                          Icons.settings_outlined,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Vault',
                            style: Theme.of(context)
                                .textTheme
                                .headlineLarge
                                ?.copyWith(
                                  color: Colors.white,
                                  fontFamily: 'SpaceGrotesk',
                                  fontSize: 34,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0,
                                ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'Curated opportunities for controlled requests.',
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.38),
                                ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.patinaTeal.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: AppColors.patinaTeal.withValues(alpha: 0.22),
                        ),
                      ),
                      child: const Text(
                        'PATRON',
                        style: TextStyle(
                          color: AppColors.patinaTeal,
                          fontFamily: 'SpaceGrotesk',
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              _VaultControls(
                controller: _searchCtrl,
                focusNode: _searchFocus,
                filters: filters,
                onFiltersChanged: (value) =>
                    ref.read(vaultFiltersProvider.notifier).state = value,
              ),
              Expanded(
                child: ideasAsync.when(
                  loading: () => const _EmptyVaultState.loading(dark: true),
                  error: (error, _) => _EmptyVaultState(
                    title: 'Vault unavailable',
                    body: error.toString(),
                    icon: Icons.error_outline_rounded,
                    dark: true,
                  ),
                  data: (ideas) {
                    final visible = _filterIdeas(
                      ideas,
                      _searchCtrl.text,
                      filters,
                    );
                    if (ideas.isEmpty) {
                      return const _EmptyVaultState(
                        title: 'Vault is being curated',
                        body:
                            'Approved ideas will appear here after review. Patrons get access to searchable deal flow.',
                        icon: Icons.inventory_2_outlined,
                        dark: true,
                      );
                    }
                    if (visible.isEmpty) {
                      return const _EmptyVaultState(
                        title: 'No matches',
                        body:
                            'Adjust search or remove a filter to widen the opportunity set.',
                        icon: Icons.search_off_rounded,
                        dark: true,
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(22, 8, 22, 34),
                      itemCount: visible.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (_, index) => IdeaOpportunityCard(
                        idea: visible[index],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<IdeaModel> _filterIdeas(
    List<IdeaModel> ideas,
    String search,
    VaultFilters filters,
  ) {
    final query = search.trim().toLowerCase();
    final filtered = ideas.where((idea) {
      if (query.isNotEmpty) {
        final haystack = [
          idea.title,
          idea.category,
          idea.body,
          idea.innovatorProfession,
          idea.collaborationType,
          idea.geographicScope,
        ].join(' ').toLowerCase();
        if (!haystack.contains(query)) return false;
      }
      if (filters.category != 'All' && idea.category != filters.category) {
        return false;
      }
      if (filters.profession != 'All' &&
          idea.innovatorProfession != filters.profession) {
        return false;
      }
      if (filters.geo != 'All' && idea.geographicScope != filters.geo) {
        return false;
      }
      if (filters.status == VaultStatusFilter.fresh && !_isFresh(idea)) {
        return false;
      }
      return true;
    }).toList();

    filtered.sort((a, b) {
      return switch (filters.date) {
        VaultDateFilter.newest => b.createdAt.compareTo(a.createdAt),
        VaultDateFilter.oldest => a.createdAt.compareTo(b.createdAt),
      };
    });
    return filtered;
  }
}

class _VaultControls extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VaultFilters filters;
  final ValueChanged<VaultFilters> onFiltersChanged;

  const _VaultControls({
    required this.controller,
    required this.focusNode,
    required this.filters,
    required this.onFiltersChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 22, 10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.12),
          border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
            bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              SearchField(controller: controller, focusNode: focusNode),
              const SizedBox(height: 10),
              FilterSummaryBar(
                filters: filters,
                onFiltersChanged: onFiltersChanged,
              ),
              CollapsibleFilterPanel(
                filters: filters,
                onFiltersChanged: onFiltersChanged,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SearchField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;

  const SearchField({
    super.key,
    required this.controller,
    required this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      cursorColor: AppColors.ochre,
      style: const TextStyle(color: Colors.white),
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Search ideas, categories, industries',
        hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3)),
        prefixIcon: Icon(
          Icons.search_rounded,
          color: Colors.white.withValues(alpha: 0.76),
        ),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                icon: Icon(
                  Icons.close_rounded,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
                onPressed: controller.clear,
              ),
        filled: true,
        fillColor: Colors.black.withValues(alpha: 0.3),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.07)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: AppColors.terracotta, width: 1.4),
        ),
      ),
    );
  }
}

class FilterSummaryBar extends StatelessWidget {
  final VaultFilters filters;
  final ValueChanged<VaultFilters> onFiltersChanged;

  const FilterSummaryBar({
    super.key,
    required this.filters,
    required this.onFiltersChanged,
  });

  @override
  Widget build(BuildContext context) {
    final chips = <Widget>[
      _FilterToggleChip(
        label: filters.expanded ? 'Hide filters' : 'Filters',
        icon: filters.expanded
            ? Icons.keyboard_arrow_up_rounded
            : Icons.tune_rounded,
        onTap: () => onFiltersChanged(
          filters.copyWith(expanded: !filters.expanded),
        ),
      ),
      if (filters.category != 'All')
        _RemovableFilterChip(
          label: filters.category,
          onDeleted: () => onFiltersChanged(filters.copyWith(category: 'All')),
        ),
      if (filters.profession != 'All')
        _RemovableFilterChip(
          label: filters.profession,
          onDeleted: () =>
              onFiltersChanged(filters.copyWith(profession: 'All')),
        ),
      if (filters.status != VaultStatusFilter.all)
        _RemovableFilterChip(
          label: filters.status == VaultStatusFilter.fresh ? 'New' : 'Live',
          onDeleted: () =>
              onFiltersChanged(filters.copyWith(status: VaultStatusFilter.all)),
        ),
      if (filters.geo != 'All')
        _RemovableFilterChip(
          label: filters.geo,
          onDeleted: () => onFiltersChanged(filters.copyWith(geo: 'All')),
        ),
    ];

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, index) => chips[index],
      ),
    );
  }
}

class CollapsibleFilterPanel extends StatelessWidget {
  final VaultFilters filters;
  final ValueChanged<VaultFilters> onFiltersChanged;

  const CollapsibleFilterPanel({
    super.key,
    required this.filters,
    required this.onFiltersChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (!filters.expanded) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.24),
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      child: Column(
        children: [
          _FilterDropdown(
            label: 'Category',
            value: filters.category,
            values: const ['All', ...AppConstants.categories],
            onChanged: (value) =>
                onFiltersChanged(filters.copyWith(category: value)),
          ),
          _FilterDropdown(
            label: 'Innovator profession',
            value: filters.profession,
            values: const [
              'All',
              'Independent innovator',
              'Technology',
              'Health',
              'Finance',
              'Education',
              'Design',
            ],
            onChanged: (value) =>
                onFiltersChanged(filters.copyWith(profession: value)),
          ),
          _FilterDropdown(
            label: 'Status',
            value: filters.status.name,
            values: const ['all', 'live', 'fresh'],
            labelFor: (value) => switch (value) {
              'fresh' => 'New',
              'live' => 'Live',
              _ => 'All',
            },
            onChanged: (value) => onFiltersChanged(
              filters.copyWith(
                status:
                    VaultStatusFilter.values.firstWhere((s) => s.name == value),
              ),
            ),
          ),
          _FilterDropdown(
            label: 'Date added',
            value: filters.date.name,
            values: const ['newest', 'oldest'],
            labelFor: (value) => switch (value) {
              'newest' => 'Newest',
              'oldest' => 'Oldest',
              _ => 'Newest',
            },
            onChanged: (value) => onFiltersChanged(
              filters.copyWith(
                date: VaultDateFilter.values.firstWhere((d) => d.name == value),
              ),
            ),
          ),
          _FilterDropdown(
            label: 'Geographic scope (Pro+)',
            value: filters.geo,
            values: const ['All', 'Norway', 'Nordics', 'Europe', 'Global'],
            onChanged: (value) =>
                onFiltersChanged(filters.copyWith(geo: value)),
          ),
        ],
      ),
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<String> values;
  final String Function(String value)? labelFor;
  final ValueChanged<String> onChanged;

  const _FilterDropdown({
    required this.label,
    required this.value,
    required this.values,
    required this.onChanged,
    this.labelFor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: DropdownButtonFormField<String>(
        value: value,
        dropdownColor: AppColors.labPanelRaised,
        iconEnabledColor: AppColors.ochre,
        style: const TextStyle(
          color: Colors.white,
          fontFamily: 'SpaceGrotesk',
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.42)),
          filled: true,
          fillColor: Colors.black.withValues(alpha: 0.2),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: AppColors.ochre, width: 1.2),
          ),
        ),
        items: values
            .map((item) => DropdownMenuItem(
                  value: item,
                  child: Text(labelFor?.call(item) ?? item),
                ))
            .toList(),
        onChanged: (value) {
          if (value != null) onChanged(value);
        },
      ),
    );
  }
}

class IdeaOpportunityCard extends StatelessWidget {
  final IdeaModel idea;

  const IdeaOpportunityCard({
    super.key,
    required this.idea,
  });

  @override
  Widget build(BuildContext context) {
    final date = DateFormat('MMM d').format(idea.createdAt);
    final fresh = _isFresh(idea);

    return InkWell(
      onTap: () => context.push('/vault/idea/${idea.id}'),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
            bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: 9,
                      runSpacing: 9,
                      children: [
                        _Badge(
                            label: idea.category, color: AppColors.terracotta),
                        _Badge(
                            label: _typeFor(idea), color: AppColors.patinaTeal),
                      ],
                    ),
                  ),
                  Text(
                    fresh ? 'NEW' : 'LIVE',
                    style: TextStyle(
                      color: fresh
                          ? AppColors.patinaTeal
                          : Colors.white.withValues(alpha: 0.42),
                      fontFamily: 'SpaceGrotesk',
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                idea.title,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontFamily: 'SpaceGrotesk',
                      fontSize: 25,
                      fontWeight: FontWeight.w500,
                      height: 1.08,
                      letterSpacing: 0,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _MetaLine(
                      icon: Icons.work_outline_rounded,
                      text: idea.innovatorProfession,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MetaLine(
                      icon: Icons.public_rounded,
                      text: idea.geographicScope,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _MetaLine(
                      icon: Icons.calendar_today_outlined,
                      text: date,
                    ),
                  ),
                  Text(
                    'ENTER VAULT',
                    style: TextStyle(
                      color: AppColors.patinaTeal.withValues(alpha: 0.95),
                      fontFamily: 'SpaceGrotesk',
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2.4,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 16,
                    color: AppColors.patinaTeal.withValues(alpha: 0.95),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.12)),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: color,
          fontFamily: 'SpaceGrotesk',
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.7,
        ),
      ),
    );
  }
}

class _MetaLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MetaLine({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: Colors.white.withValues(alpha: 0.42)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.46),
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _EmptyVaultState extends StatelessWidget {
  final String title;
  final String body;
  final IconData icon;
  final bool loading;
  final bool dark;

  const _EmptyVaultState({
    required this.title,
    required this.body,
    required this.icon,
    this.dark = true,
  }) : loading = false;

  const _EmptyVaultState.loading({this.dark = true})
      : title = 'Loading Vault',
        body = 'Finding curated opportunities.',
        icon = Icons.hourglass_top_rounded,
        loading = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final titleColor = dark ? Colors.white : AppColors.ink;
    final bodyColor =
        dark ? Colors.white.withValues(alpha: 0.42) : AppColors.graphite;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (loading)
              const CircularProgressIndicator(color: AppColors.ochre)
            else
              Icon(
                icon,
                color: dark ? AppColors.ochre : AppColors.green,
                size: 38,
              ),
            const SizedBox(height: 18),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(color: titleColor),
            ),
            const SizedBox(height: 6),
            Text(
              body,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(color: bodyColor),
            ),
          ],
        ),
      ),
    );
  }
}

class _VaultPreview extends StatelessWidget {
  const _VaultPreview();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return MainScaffold(
      title: 'Vault',
      showTabs: false,
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
        children: [
          const FrumaSectionLabel(label: 'PATRON ACCESS.'),
          const SizedBox(height: 12),
          Text(
            'Curated deal flow',
            style: theme.textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontFamily: 'SpaceGrotesk',
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Patron access unlocks full idea details, favorites and request workflows.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.white.withValues(alpha: 0.44),
            ),
          ),
          const SizedBox(height: 18),
          const _EmptyVaultState(
            title: 'Access required',
            body:
                'Subscribe to search reviewed ideas and send controlled requests.',
            icon: Icons.lock_outline_rounded,
          ),
          const SizedBox(height: 18),
          FrumaLabButton(
            label: 'Start Patron Access',
            onPressed: () => context.go('/paywall'),
          ),
        ],
      ),
    );
  }
}

class _FilterToggleChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _FilterToggleChip({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.terracotta.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: AppColors.terracotta.withValues(alpha: 0.35),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppColors.ochre),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: AppColors.ochre,
                fontFamily: 'SpaceGrotesk',
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RemovableFilterChip extends StatelessWidget {
  final String label;
  final VoidCallback onDeleted;

  const _RemovableFilterChip({
    required this.label,
    required this.onDeleted,
  });

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontFamily: 'SpaceGrotesk',
          fontWeight: FontWeight.w700,
        ),
      ),
      deleteIcon: Icon(
        Icons.close_rounded,
        size: 16,
        color: Colors.white.withValues(alpha: 0.72),
      ),
      onDeleted: onDeleted,
      backgroundColor: Colors.black.withValues(alpha: 0.24),
      side: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
    );
  }
}

String _typeFor(IdeaModel idea) {
  final raw = idea.collaborationType.trim();
  if (raw.isEmpty) return 'Open';
  final lower = raw.toLowerCase();
  if (lower.contains('buy') || lower.contains('kjøp')) return 'Buy';
  if (lower.contains('partner')) return 'Partnership';
  if (lower.contains('license') || lower.contains('lisens')) return 'License';
  return raw;
}

bool _isFresh(IdeaModel idea) {
  return DateTime.now().difference(idea.createdAt).inDays < 7;
}
