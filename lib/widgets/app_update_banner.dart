import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/albumium_localizations.dart';
import '../services/app_update_service.dart';

/// Stays on the library screen so updates never interrupt an album edit/export.
class AppUpdateBanner extends StatefulWidget {
  const AppUpdateBanner({super.key, this.service});
  final AppUpdateService? service;
  @override
  State<AppUpdateBanner> createState() => _AppUpdateBannerState();
}

class _AppUpdateBannerState extends State<AppUpdateBanner>
    with WidgetsBindingObserver {
  AppUpdateService get service => widget.service ?? AppUpdateService.instance;
  StoreUpdate? _update;
  bool _checking = false, _opening = false, _returningFromStore = false;
  static const _dismissedId = 'albumium.update.dismissedId';
  static const _dismissedUntil = 'albumium.update.dismissedUntil';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    unawaited(_refresh());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final force = _returningFromStore;
      _returningFromStore = false;
      unawaited(_refresh(force: force));
    }
  }

  Future<void> _refresh({bool force = false}) async {
    if (_checking) return;
    _checking = true;
    try {
      var update = await service.check(force: force);
      try {
        final prefs = await SharedPreferences.getInstance();
        if (update != null &&
            prefs.getString(_dismissedId) == update.id &&
            DateTime.now().millisecondsSinceEpoch <
                (prefs.getInt(_dismissedUntil) ?? 0)) {
          update = null;
        }
      } catch (_) {
        /* Optional snooze storage must not prevent the prompt. */
      }
      if (mounted) setState(() => _update = update);
    } finally {
      _checking = false;
    }
  }

  Future<void> _later() async {
    final id = _update?.id;
    setState(() => _update = null);
    if (id == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_dismissedId, id);
      await prefs.setInt(
        _dismissedUntil,
        DateTime.now().add(const Duration(hours: 24)).millisecondsSinceEpoch,
      );
    } catch (_) {
      /* It remains dismissed for this screen session. */
    }
  }

  Future<void> _open() async {
    final update = _update;
    if (update == null || _opening) return;
    setState(() => _opening = true);
    _returningFromStore = true;
    final opened = await service.openStore(update);
    if (!mounted) return;
    setState(() => _opening = false);
    if (!opened) {
      _returningFromStore = false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.tr('Mağaza açılamadı. Biraz sonra tekrar dene.'),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final update = _update;
    if (update == null) return const SizedBox.shrink();
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      child: Card(
        key: const ValueKey('app-update-banner'),
        color: colors.primaryContainer,
        margin: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.tr('Yeni sürüm var'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                context.tr(
                  'Albumium’u güncelleyerek yeni özellikleri ve iyileştirmeleri kullanabilirsin.',
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  FilledButton.icon(
                    key: const ValueKey('app-update-open-store'),
                    onPressed: _opening ? null : _open,
                    icon: const Icon(Icons.system_update_alt),
                    label: Text(context.tr('Güncelle')),
                  ),
                  TextButton(
                    onPressed: _opening ? null : _later,
                    child: Text(context.tr('Daha sonra')),
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
