import 'package:flutter/material.dart';

import '../l10n/albumium_localizations.dart';
import '../models/album_models.dart';
import '../services/cover_entitlements.dart';
import '../services/monetization_policy.dart';
import '../services/rewarded_ads.dart';
import '../theme/albumium_app_theme.dart';
import 'album_cover_3d.dart';

/// Offers a locked cover for sale. Returns true once it belongs to the user.
Future<bool> showCoverPurchaseSheet(
  BuildContext context, {
  required AlbumThemePreset theme,
  required CoverEntitlements entitlements,
}) async {
  final bought = await showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) =>
        _CoverPurchaseSheet(theme: theme, entitlements: entitlements),
  );
  return bought ?? false;
}

class _CoverPurchaseSheet extends StatefulWidget {
  const _CoverPurchaseSheet({required this.theme, required this.entitlements});

  final AlbumThemePreset theme;
  final CoverEntitlements entitlements;

  @override
  State<_CoverPurchaseSheet> createState() => _CoverPurchaseSheetState();
}

class _CoverPurchaseSheetState extends State<_CoverPurchaseSheet> {
  bool _working = false;
  String? _error;

  Future<void> _watchAd() async {
    if (_working) return;
    setState(() {
      _working = true;
      _error = null;
    });
    RewardedAdOutcome outcome;
    try {
      outcome = await RewardedAds.source.show(RewardedAdPlacement.cover);
    } catch (_) {
      outcome = RewardedAdOutcome.failed;
    }
    if (!mounted) return;
    if (outcome == RewardedAdOutcome.earned) {
      widget.entitlements.grant(widget.theme.id);
      Navigator.pop(context, true);
      return;
    }
    setState(() {
      _working = false;
      _error = context.tr(switch (outcome) {
        RewardedAdOutcome.dismissed =>
          'Ödülü kazanmak için reklamı sonuna kadar izlemelisin.',
        RewardedAdOutcome.unavailable =>
          'Şu anda gösterilecek reklam yok. Daha sonra tekrar dene.',
        _ => 'Reklam açılamadı. Tekrar deneyebilirsin.',
      });
    });
  }

  AlbumModel get _preview {
    final date = DateTime(2026);
    return AlbumModel(
      id: 'purchase-${widget.theme.id}',
      title: widget.theme.name,
      themeId: widget.theme.id,
      createdAt: date,
      updatedAt: date,
      pages: [
        AlbumPageModel(
          id: 'purchase-page-${widget.theme.id}',
          backgroundColor: widget.theme.pageColor.toARGB32(),
        ),
      ],
    );
  }

  /// Runs one store action, guarding against a second tap while it is in
  /// flight, and reports failure in that action's own words.
  Future<void> _run(Future<bool> Function() action, String failure) async {
    if (_working) return;
    setState(() {
      _working = true;
      _error = null;
    });
    final unlocked = await action();
    if (!mounted) return;
    if (unlocked) {
      Navigator.pop(context, true);
      return;
    }
    setState(() {
      _working = false;
      _error = context.tr(failure);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = AlbumiumAppTheme.colorsOf(context);
    final theme = widget.theme;
    final rewardedOnly = MonetizationPolicy.rewardedOnly;
    final price = rewardedOnly
        ? ''
        : widget.entitlements.priceLabelFor(theme.id);

    Widget bullet(IconData icon, String text) => Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colors.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(context.tr(text))),
        ],
      ),
    );

    return SafeArea(
      key: const ValueKey('cover-purchase-sheet'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 92,
                  child: AspectRatio(
                    aspectRatio: 15 / 22,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: AlbumCover3D(
                        album: _preview,
                        compact: true,
                        perspective: false,
                        showTitle: false,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.tr(theme.name),
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        context.tr(theme.subtitle),
                        style: TextStyle(color: colors.mutedText, height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            bullet(
              Icons.auto_stories_outlined,
              rewardedOnly
                  ? 'Bir reklam izle, bu kapakla bir albüm oluştur.'
                  : 'Bu kapağı tüm albümlerinde kullanabilirsin.',
            ),
            if (!rewardedOnly)
              bullet(Icons.sell_outlined, 'Tek seferlik satın alma.'),
            if (rewardedOnly)
              bullet(
                Icons.check_circle_outline,
                'Oluşturduğun albümün kapağı sende kalır.',
              ),
            bullet(Icons.cloud_off_outlined, 'Çevrimdışı çalışır.'),
            if (_error != null)
              Padding(
                key: const ValueKey('cover-purchase-error'),
                padding: const EdgeInsets.only(top: 4, bottom: 8),
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: ValueKey(
                  rewardedOnly
                      ? 'cover-unlock-watch-ad'
                      : 'cover-purchase-confirm',
                ),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                onPressed: _working
                    ? null
                    : rewardedOnly
                    ? _watchAd
                    : () => _run(
                        () => widget.entitlements.purchase(theme.id),
                        'Satın alma tamamlanamadı. Tekrar deneyebilirsin.',
                      ),
                icon: _working
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(
                        rewardedOnly
                            ? Icons.play_circle_outline_rounded
                            : Icons.lock_open_rounded,
                      ),
                label: Text(
                  rewardedOnly
                      ? context.tr('Reklam izle, bir kez kullan')
                      : context.tr(
                          '{price} · Satın al',
                          values: {'price': price},
                        ),
                ),
              ),
            ),
            // Side by side these two labels do not fit a narrow phone, and
            // "Satın alımları geri yükle" must not be truncated.
            if (!rewardedOnly)
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  key: const ValueKey('cover-purchase-restore'),
                  onPressed: _working
                      ? null
                      : () => _run(() async {
                          await widget.entitlements.restore();
                          return widget.entitlements.isUnlocked(theme.id);
                        }, 'Geri yüklenecek satın alma bulunamadı.'),
                  child: Text(context.tr('Satın alımları geri yükle')),
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: _working ? null : () => Navigator.pop(context),
                child: Text(context.tr('Vazgeç')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
