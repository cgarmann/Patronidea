import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../services/subscription_service.dart';
import '../shared/fruma_lab_chrome.dart';

class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  late final SubscriptionService _subscriptionService;
  List<ProductDetails> _products = const [];
  ProductDetails? _selectedProduct;
  bool _loadingProducts = true;
  bool _activating = false;
  bool _restoring = false;
  String _billingNote = 'Checking Google Play...';
  String? _billingIssue;

  @override
  void initState() {
    super.initState();
    _subscriptionService = SubscriptionService(
      onStatus: (message) {
        if (mounted) setState(() => _billingNote = message);
      },
    );
    _loadProducts();
  }

  @override
  void dispose() {
    _subscriptionService.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _loadingProducts = true;
      _billingIssue = null;
      _billingNote = 'Checking Google Play...';
    });
    try {
      final products = await _subscriptionService.loadProducts();
      if (!mounted) return;
      setState(() {
        _products = products;
        _selectedProduct = products.firstWhere(
          (product) => product.id == AppConstants.patronMonthlyProductId,
          orElse: () => products.first,
        );
        _billingNote = 'Google Play ready.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _billingIssue = e.toString();
        _billingNote = 'Google Play unavailable.';
      });
    } finally {
      if (mounted) setState(() => _loadingProducts = false);
    }
  }

  Future<void> _startAccess() async {
    final product = _selectedProduct;
    if (product == null) return;

    setState(() => _activating = true);
    try {
      await _subscriptionService.buy(product);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Patron access activated.'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.go('/patron');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not activate access: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _activating = false);
    }
  }

  Future<void> _restoreAccess() async {
    setState(() => _restoring = true);
    try {
      await _subscriptionService.restore();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Patron access restored.'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.go('/patron');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not restore access: $e'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _restoring = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.volcanic950,
      body: FrumaLabBackground(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 18, 24, 32),
            children: [
              Row(
                children: [
                  const FrumaStatusPill(
                    label: 'Patron Access',
                    color: AppColors.patinaTeal,
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () async {
                      await ref.read(authServiceProvider).signOut();
                      if (context.mounted) context.go('/');
                    },
                    child: const Text('Sign out'),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Text(
                'Opportunity Desk',
                style: theme.textTheme.displayMedium?.copyWith(
                  color: Colors.white,
                  fontFamily: 'SpaceGrotesk',
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Access reviewed ideas, save opportunities and open controlled Deal Rooms when the fit is real.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.46),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 34),
              _AccessStatusPanel(
                isLoading: _activating || _loadingProducts || _restoring,
                selectedProduct: _selectedProduct,
                billingNote: _billingNote,
                billingIssue: _billingIssue,
              ),
              if (_products.isNotEmpty) ...[
                const SizedBox(height: 24),
                _ProductSelector(
                  products: _products,
                  selectedProductId: _selectedProduct?.id,
                  onSelect: (product) {
                    setState(() {
                      _selectedProduct = product;
                      _billingIssue = null;
                    });
                  },
                ),
              ],
              const SizedBox(height: 30),
              const FrumaSectionLabel(label: 'WHAT PATRONS GET.'),
              const SizedBox(height: 8),
              DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(
                    top:
                        BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                    bottom:
                        BorderSide(color: Colors.white.withValues(alpha: 0.08)),
                  ),
                ),
                child: const Column(
                  children: [
                    FrumaActionRow(
                      icon: Icons.storage_outlined,
                      title: 'Live vault',
                      body: 'Reviewed ideas ready for request',
                    ),
                    FrumaThinDivider(),
                    FrumaActionRow(
                      icon: Icons.handshake_outlined,
                      title: 'Deal room',
                      body: 'Chat, proposal, counter and acceptance',
                    ),
                    FrumaThinDivider(),
                    FrumaActionRow(
                      icon: Icons.privacy_tip_outlined,
                      title: 'Protected',
                      body: 'No direct contact info before approval',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              const _PipelinePreview(),
              const SizedBox(height: 24),
              FrumaLabButton(
                label: _activating
                    ? _billingNote
                    : _selectedProduct == null
                        ? 'Google Play unavailable'
                        : 'Start Patron Access',
                icon: Icons.lock_open_rounded,
                onPressed: _activating || _selectedProduct == null
                    ? null
                    : _startAccess,
              ),
              const SizedBox(height: 12),
              FrumaLabButton(
                label: _restoring ? 'Checking...' : 'Restore access',
                icon: Icons.refresh_rounded,
                secondary: true,
                onPressed: _activating || _restoring ? null : _restoreAccess,
              ),
              const SizedBox(height: 12),
              FrumaLabButton(
                label: 'Preview Vault',
                icon: Icons.visibility_outlined,
                secondary: true,
                onPressed: () => context.go('/vault'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccessStatusPanel extends StatelessWidget {
  final bool isLoading;
  final ProductDetails? selectedProduct;
  final String billingNote;
  final String? billingIssue;

  const _AccessStatusPanel({
    required this.isLoading,
    required this.selectedProduct,
    required this.billingNote,
    required this.billingIssue,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final body = billingIssue ??
        (selectedProduct == null
            ? 'Google Play products are loading. Use demo preview if you only want to inspect the Vault.'
            : '${selectedProduct!.price} via Google Play. Server receipt validation is required before Vault access opens.');
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _StatusDot(
                  color: billingIssue != null
                      ? AppColors.error
                      : isLoading
                          ? AppColors.warning
                          : AppColors.ochre,
                ),
                const SizedBox(width: 8),
                Text(
                  billingNote,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontFamily: 'SpaceGrotesk',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 9),
            Text(
              body,
              style: theme.textTheme.bodySmall?.copyWith(
                color: billingIssue != null
                    ? AppColors.error
                    : Colors.white.withValues(alpha: 0.44),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductSelector extends StatelessWidget {
  final List<ProductDetails> products;
  final String? selectedProductId;
  final ValueChanged<ProductDetails> onSelect;

  const _ProductSelector({
    required this.products,
    required this.selectedProductId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FrumaSectionLabel(label: 'PLAN.'),
        const SizedBox(height: 8),
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
              bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
            ),
          ),
          child: Column(
            children: [
              for (var i = 0; i < products.length; i++) ...[
                _ProductRow(
                  product: products[i],
                  selected: products[i].id == selectedProductId,
                  onTap: () => onSelect(products[i]),
                ),
                if (i != products.length - 1) const FrumaThinDivider(),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ProductRow extends StatelessWidget {
  final ProductDetails product;
  final bool selected;
  final VoidCallback onTap;

  const _ProductRow({
    required this.product,
    required this.selected,
    required this.onTap,
  });

  String get _label {
    if (product.id == AppConstants.patronMonthlyProductId) return 'Monthly';
    if (product.id == AppConstants.patronYearlyProductId) return 'Yearly';
    return product.title.replaceAll(RegExp(r'\s*\(.*\)$'), '').trim();
  }

  String get _body {
    if (product.id == AppConstants.patronYearlyProductId) {
      return 'Best for continuous Vault access';
    }
    return 'Flexible Patron access';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 15),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: selected ? AppColors.ochre : Colors.white38,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _body,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.42),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              product.price,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: selected ? AppColors.ochre : Colors.white70,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PipelinePreview extends StatelessWidget {
  const _PipelinePreview();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = [
      ('SaaS', 'Reviewed', 'Request open'),
      ('Green Tech', 'Reviewed', 'Partnership'),
      ('Local Solutions', 'Fresh', 'New supply'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FrumaSectionLabel(label: 'PRIORITY CATEGORIES.'),
        const SizedBox(height: 8),
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
              bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
            ),
          ),
          child: Column(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          items[i].$1,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          items[i].$2,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.patinaTeal,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 3,
                        child: Text(
                          items[i].$3,
                          textAlign: TextAlign.end,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.44),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (i != items.length - 1) const FrumaThinDivider(),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusDot extends StatelessWidget {
  final Color color;

  const _StatusDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
