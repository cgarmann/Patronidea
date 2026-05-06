import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

import '../core/constants/app_constants.dart';

class SubscriptionException implements Exception {
  final String message;

  const SubscriptionException(this.message);

  @override
  String toString() => message;
}

class SubscriptionService {
  SubscriptionService({void Function(String message)? onStatus})
      : _onStatus = onStatus;

  final InAppPurchase _iap = InAppPurchase.instance;
  final void Function(String message)? _onStatus;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  Completer<void>? _purchaseCompleter;
  String? _activeProductId;

  static const productIds = {
    AppConstants.patronMonthlyProductId,
    AppConstants.patronYearlyProductId,
  };

  Future<List<ProductDetails>> loadProducts() async {
    final available = await _iap.isAvailable();
    if (!available) {
      throw const SubscriptionException(
        'Google Play Billing is not available on this device.',
      );
    }

    final response = await _iap.queryProductDetails(productIds);
    if (response.error != null) {
      throw SubscriptionException(response.error!.message);
    }
    if (response.productDetails.isEmpty) {
      throw const SubscriptionException(
        'No Patron subscription products were returned from Google Play.',
      );
    }

    final products = [...response.productDetails];
    products.sort((a, b) {
      if (a.id == AppConstants.patronMonthlyProductId) return -1;
      if (b.id == AppConstants.patronMonthlyProductId) return 1;
      return a.rawPrice.compareTo(b.rawPrice);
    });
    return products;
  }

  Future<void> buy(ProductDetails product) async {
    if (_purchaseCompleter != null && !_purchaseCompleter!.isCompleted) {
      throw const SubscriptionException('A purchase is already in progress.');
    }

    _listen();
    _activeProductId = product.id;
    _purchaseCompleter = Completer<void>();
    _onStatus?.call('Opening Google Play...');

    final started = await _iap.buyNonConsumable(
      purchaseParam: PurchaseParam(productDetails: product),
    );
    if (!started) {
      _finishWithError('Google Play could not start the purchase.');
    }

    return _purchaseCompleter!.future.timeout(
      const Duration(minutes: 3),
      onTimeout: () {
        const message = 'Google Play purchase timed out.';
        _finishWithError(message);
        throw const SubscriptionException(message);
      },
    );
  }

  Future<void> restore() async {
    _listen();
    _purchaseCompleter = Completer<void>();
    _onStatus?.call('Checking Google Play...');
    await _iap.restorePurchases();
    return _purchaseCompleter!.future.timeout(
      const Duration(seconds: 45),
      onTimeout: () {
        const message = 'No active Google Play subscription was restored.';
        _finishWithError(message);
        throw const SubscriptionException(message);
      },
    );
  }

  void dispose() {
    _purchaseSubscription?.cancel();
  }

  void _listen() {
    _purchaseSubscription ??= _iap.purchaseStream.listen(
      _handlePurchaseUpdates,
      onError: (Object error) => _finishWithError(error.toString()),
    );
  }

  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (!productIds.contains(purchase.productID)) continue;
      if (_activeProductId != null && purchase.productID != _activeProductId) {
        continue;
      }

      switch (purchase.status) {
        case PurchaseStatus.pending:
          _onStatus?.call('Waiting for Google Play...');
          break;
        case PurchaseStatus.error:
          _finishWithError(
            purchase.error?.message ?? 'Google Play purchase failed.',
          );
          break;
        case PurchaseStatus.canceled:
          _finishWithError('Purchase cancelled.');
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _activateFromPurchase(purchase);
          break;
      }
    }
  }

  Future<void> _activateFromPurchase(PurchaseDetails purchase) async {
    try {
      _onStatus?.call('Validating receipt...');
      final receiptToken = purchase.verificationData.serverVerificationData;
      if (receiptToken.trim().isEmpty) {
        throw const SubscriptionException(
          'Google Play did not return a server verification token.',
        );
      }

      await FirebaseFunctions.instance.httpsCallable('activateSubscription').call({
        'planId': purchase.productID,
        'provider': 'google_play',
        'receiptToken': receiptToken,
        'purchaseId': purchase.purchaseID,
        'verificationSource': purchase.verificationData.source,
      });

      if (purchase.pendingCompletePurchase) {
        await _iap.completePurchase(purchase);
      }

      _onStatus?.call('Access activated.');
      if (_purchaseCompleter != null && !_purchaseCompleter!.isCompleted) {
        _purchaseCompleter!.complete();
      }
      _purchaseCompleter = null;
      _activeProductId = null;
    } catch (error) {
      _finishWithError(error.toString());
    }
  }

  void _finishWithError(String message) {
    if (_purchaseCompleter != null && !_purchaseCompleter!.isCompleted) {
      _purchaseCompleter!.completeError(SubscriptionException(message));
    }
    _purchaseCompleter = null;
    _activeProductId = null;
  }
}
