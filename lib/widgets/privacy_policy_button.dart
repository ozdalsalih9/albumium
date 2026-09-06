import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/albumium_localizations.dart';

const albumiumPrivacyUrl =
    'https://sites.google.com/view/albumium-privacy/ana-sayfa';

class PrivacyPolicyButton extends StatelessWidget {
  const PrivacyPolicyButton({super.key});

  @override
  Widget build(BuildContext context) => TextButton.icon(
    icon: const Icon(Icons.privacy_tip_outlined, size: 18),
    label: Text(context.tr('Gizlilik politikası')),
    onPressed: () async {
      try {
        await const MethodChannel(
          'com.albumium.albumium/app_support',
        ).invokeMethod<void>('openPrivacyPolicy');
      } catch (_) {
        if (!context.mounted) return;
        await showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(context.tr('Gizlilik politikası')),
            content: const SelectableText(albumiumPrivacyUrl),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(context.tr('Tamam')),
              ),
            ],
          ),
        );
      }
    },
  );
}
