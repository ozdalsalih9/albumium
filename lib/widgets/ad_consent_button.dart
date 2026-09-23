import 'package:flutter/material.dart';

import '../l10n/albumium_localizations.dart';
import '../services/ad_consent.dart';

/// Reopens the ad consent form, for people who were asked for one.
///
/// Consent that cannot be withdrawn is not consent, so wherever the form was
/// shown this has to be reachable. It shows nothing at all elsewhere: outside
/// those regions nobody was asked, and a button about a choice you never made
/// would only puzzle.
class AdConsentButton extends StatefulWidget {
  const AdConsentButton({super.key, this.controller});

  final AdConsentController? controller;

  @override
  State<AdConsentButton> createState() => _AdConsentButtonState();
}

class _AdConsentButtonState extends State<AdConsentButton> {
  late final AdConsentController _consent =
      widget.controller ?? AdConsent.controller;
  bool _available = false;
  bool _working = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    final available = await _consent.canChangeChoice();
    if (!mounted || available == _available) return;
    setState(() => _available = available);
  }

  Future<void> _open() async {
    if (_working) return;
    setState(() => _working = true);
    final failure = await _consent.showChoiceForm();
    if (!mounted) return;
    setState(() => _working = false);
    if (failure == null) {
      await _check();
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.tr('Reklam izinleri şu anda açılamadı.'))),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_available) return const SizedBox.shrink();
    return TextButton.icon(
      key: const ValueKey('ad-consent-button'),
      icon: const Icon(Icons.campaign_outlined, size: 18),
      label: Text(context.tr('Reklam izinleri')),
      onPressed: _working ? null : _open,
    );
  }
}
