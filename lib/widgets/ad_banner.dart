import 'package:flutter/material.dart';

/// Builds the banner for a screen, or null where there is none to show.
///
/// The seam that keeps the ad SDK out of the widget tree: the default builds
/// nothing, so no test ever reaches it.
typedef BannerAdBuilder = Widget? Function(BuildContext context);

abstract final class BannerAds {
  static BannerAdBuilder _builder = _none;

  static Widget? _none(BuildContext context) => null;

  static BannerAdBuilder get builder => _builder;

  static void configure(BannerAdBuilder value) => _builder = value;

  static void resetForTesting() => _builder = _none;
}

/// A banner beside the navigation bar, on the screens people browse.
///
/// Deliberately absent from the editor: that screen is worked with a finger
/// all over it, and a banner within reach of those taps turns honest use into
/// accidental clicks, which Google counts as invalid traffic and charges to
/// the whole account — both platforms share it.
///
/// [padding] applies only once an ad is there, so a screen with no fill keeps
/// its navigation bar flush against the bottom instead of floating on a gap.
class AdBanner extends StatelessWidget {
  const AdBanner({super.key, this.padding = EdgeInsets.zero});

  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final banner = BannerAds.builder(context);
    if (banner == null) return const SizedBox.shrink();
    return Padding(
      padding: padding,
      child: Semantics(
        key: const ValueKey('ad-banner'),
        label: 'Reklam',
        container: true,
        child: banner,
      ),
    );
  }
}
