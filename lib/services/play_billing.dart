import 'dart:async';

import 'package:in_app_purchase/in_app_purchase.dart';

import '../models/album_models.dart';
import 'cover_entitlements.dart';
import 'error_reporter.dart';
import 'feature_entitlements.dart';

/// What the app needs from a store, narrow enough to fake in a test.
///
/// The real implementation is the only place the billing plugin is used, the
/// same way the ad SDK is confined to one file.
abstract class BillingClient {
  /// Prices as the store shows them, keyed by product id. Empty when the
  /// store cannot be reached, in which case the catalogue's labels stand.
  Future<Map<String, String>> loadPrices(Set<String> productIds);

  /// Runs the store's buy flow. True once the product belongs to the user.
  Future<bool> buy(String productId);

  /// Everything the store currently considers owned.
  ///
  /// This is the whole truth, not an addition: a refunded product is simply
  /// missing from it.
  Future<Set<String>> owned();
}

/// Talks to Google Play.
class PlayBillingClient implements BillingClient {
  PlayBillingClient({InAppPurchase? store})
    : _store = store ?? InAppPurchase.instance;

  final InAppPurchase _store;
  final Map<String, ProductDetails> _products = {};
  final Map<String, Completer<bool>> _pending = {};
  final Set<String> _owned = {};
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  Completer<void>? _restoring;

  /// Starts listening before anything is bought.
  ///
  /// Play replays purchases that were finished while the app was away — a
  /// payment approved hours later, for instance — so the listener has to be
  /// running from launch, not from the moment a button is tapped.
  void start() {
    _subscription ??= _store.purchaseStream.listen(
      _onPurchases,
      onError: (Object error, StackTrace stack) =>
          ErrorReporter.report(error, stack, context: 'purchaseStream'),
    );
  }

  Future<void> dispose() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          _owned.add(purchase.productID);
          _pending.remove(purchase.productID)?.complete(true);
        case PurchaseStatus.error:
          ErrorReporter.report(
            purchase.error ?? 'purchase failed',
            null,
            context: 'purchase ${purchase.productID}',
          );
          _pending.remove(purchase.productID)?.complete(false);
        case PurchaseStatus.canceled:
          _pending.remove(purchase.productID)?.complete(false);
        case PurchaseStatus.pending:
          // Someone is paying at a shop counter or waiting for a parent to
          // approve. Nothing is owned yet and nothing is finished here.
          continue;
      }
      // Google refunds a purchase that is not acknowledged within three days,
      // so this must happen for every completed purchase, restored ones too.
      if (purchase.pendingCompletePurchase) {
        try {
          await _store.completePurchase(purchase);
        } catch (error, stack) {
          ErrorReporter.report(error, stack, context: 'completePurchase');
        }
      }
    }
  }

  @override
  Future<Map<String, String>> loadPrices(Set<String> productIds) async {
    try {
      if (!await _store.isAvailable()) return const {};
      final response = await _store.queryProductDetails(productIds);
      if (response.error != null) {
        ErrorReporter.report(
          response.error!,
          null,
          context: 'queryProductDetails',
        );
      }
      for (final product in response.productDetails) {
        _products[product.id] = product;
      }
      // A product missing here was never created in Play Console, or is still
      // a draft. Reporting it early beats a button that silently does nothing.
      if (response.notFoundIDs.isNotEmpty) {
        ErrorReporter.report(
          'Products missing from the store: ${response.notFoundIDs.join(', ')}',
          null,
          context: 'queryProductDetails',
        );
      }
      return {
        for (final product in response.productDetails)
          product.id: product.price,
      };
    } catch (error, stack) {
      ErrorReporter.report(error, stack, context: 'loadPrices');
      return const {};
    }
  }

  @override
  Future<bool> buy(String productId) async {
    start();
    final product = _products[productId] ?? await _fetch(productId);
    if (product == null) return false;
    final pending = _pending[productId];
    if (pending != null) return pending.future;

    final completer = Completer<bool>();
    _pending[productId] = completer;
    try {
      // Covers and features are owned forever, so they are never consumed.
      final started = await _store.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: product),
      );
      if (!started) {
        _pending.remove(productId);
        return false;
      }
    } catch (error, stack) {
      ErrorReporter.report(error, stack, context: 'buyNonConsumable');
      _pending.remove(productId);
      return false;
    }
    return completer.future;
  }

  Future<ProductDetails?> _fetch(String productId) async {
    await loadPrices({productId});
    return _products[productId];
  }

  @override
  Future<Set<String>> owned() async {
    start();
    // restorePurchases answers through the stream, so wait for it to go quiet
    // rather than reading a list that has not arrived yet.
    final restoring = _restoring;
    if (restoring != null) {
      await restoring.future;
      return Set.of(_owned);
    }
    final completer = _restoring = Completer<void>();
    try {
      if (!await _store.isAvailable()) return Set.of(_owned);
      await _store.restorePurchases();
      await Future<void>.delayed(const Duration(seconds: 2));
    } catch (error, stack) {
      ErrorReporter.report(error, stack, context: 'restorePurchases');
    } finally {
      _restoring = null;
      completer.complete();
    }
    return Set.of(_owned);
  }
}

/// Buys covers through the store.
class PlayCoverPurchaseSource implements CoverPurchaseSource {
  PlayCoverPurchaseSource(this._client, {Map<String, String>? prices})
    : _prices = prices ?? {};

  final BillingClient _client;
  final Map<String, String> _prices;

  /// Fills the price cache with what the store charges in the user's own
  /// currency. Until then the catalogue's labels are shown.
  void cachePrices(Map<String, String> prices) => _prices.addAll(prices);

  @override
  String priceLabelFor(String themeId) =>
      _prices[CoverEntitlements.productIdFor(themeId)] ??
      themeById(themeId).price.label ??
      '';

  @override
  Future<bool> purchase(String themeId) =>
      _client.buy(CoverEntitlements.productIdFor(themeId));

  @override
  Future<Set<String>> restore() async {
    final owned = await _client.owned();
    return {
      for (final theme in albumThemes)
        if (owned.contains(CoverEntitlements.productIdFor(theme.id))) theme.id,
    };
  }
}

/// Buys the paid features through the store.
class PlayFeaturePurchaseSource implements FeaturePurchaseSource {
  PlayFeaturePurchaseSource(this._client, {Map<String, String>? prices})
    : _prices = prices ?? {};

  final BillingClient _client;
  final Map<String, String> _prices;

  void cachePrices(Map<String, String> prices) => _prices.addAll(prices);

  @override
  String priceLabelFor(AlbumiumFeature feature) =>
      _prices[feature.productId] ?? feature.priceLabel;

  @override
  Future<bool> purchase(AlbumiumFeature feature) =>
      _client.buy(feature.productId);

  @override
  Future<Set<String>> restore() async {
    final owned = await _client.owned();
    return {
      for (final feature in AlbumiumFeature.values)
        if (owned.contains(feature.productId)) feature.id,
    };
  }
}

/// Every product the app sells, which is also what the store is asked about.
Set<String> albumiumProductIds() => {
  for (final theme in albumThemes)
    if (theme.isPremium) CoverEntitlements.productIdFor(theme.id),
  for (final feature in AlbumiumFeature.values) feature.productId,
};
