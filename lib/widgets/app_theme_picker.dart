import 'package:flutter/material.dart';

import '../l10n/albumium_localizations.dart';
import '../services/theme_controller.dart';
import '../theme/albumium_app_theme.dart';

Future<void> showAlbumiumThemePicker(
  BuildContext context,
  ThemeController controller,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _AppThemePicker(controller: controller),
  );
}

class _AppThemePicker extends StatelessWidget {
  const _AppThemePicker({required this.controller});

  final ThemeController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final colorScheme = Theme.of(context).colorScheme;
        return Align(
          alignment: Alignment.bottomCenter,
          widthFactor: 1,
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                24,
                0,
                24,
                28 + MediaQuery.viewPaddingOf(context).bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.tr('Uygulama görünümü'),
                              style: Theme.of(
                                context,
                              ).textTheme.headlineSmall?.copyWith(fontSize: 28),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              context.tr('Albüm tasarımlarından bağımsızdır.'),
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.4,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: context.tr('Kapat'),
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final textScale =
                          MediaQuery.textScalerOf(context).scale(14) / 14;
                      final columns =
                          constraints.maxWidth < 300 || textScale > 1.5 ? 1 : 2;
                      return GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: AlbumiumAppTheme.options.length,
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: columns,
                          mainAxisExtent:
                              170 + (textScale - 1).clamp(0, 3) * 100,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                        itemBuilder: (context, index) {
                          final option = AlbumiumAppTheme.options[index];
                          return _ThemeChoice(
                            option: option,
                            selected: option.id == controller.themeId,
                            onTap: () => controller.setTheme(option.id),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 22),
                  Text(
                    context.tr('Parlaklık'),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 9),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final textScale =
                          MediaQuery.textScalerOf(context).scale(14) / 14;
                      return SizedBox(
                        width: double.infinity,
                        child: SegmentedButton<ThemeMode>(
                          direction:
                              constraints.maxWidth < 320 || textScale > 1.25
                              ? Axis.vertical
                              : Axis.horizontal,
                          showSelectedIcon: false,
                          segments: [
                            ButtonSegment(
                              value: ThemeMode.dark,
                              icon: const Icon(Icons.dark_mode_outlined),
                              label: Text(context.tr('Koyu')),
                            ),
                            ButtonSegment(
                              value: ThemeMode.light,
                              icon: const Icon(Icons.light_mode_outlined),
                              label: Text(context.tr('Açık')),
                            ),
                            ButtonSegment(
                              value: ThemeMode.system,
                              icon: const Icon(Icons.settings_suggest_outlined),
                              label: Text(context.tr('Sistem')),
                            ),
                          ],
                          selected: {controller.themeMode},
                          onSelectionChanged: (selection) {
                            controller.setThemeMode(selection.first);
                          },
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.check_rounded),
                      label: Text(
                        context.tr(
                          '{theme} temasını kullan',
                          values: {
                            'theme': context.tr(controller.selectedOption.name),
                          },
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ThemeChoice extends StatelessWidget {
  const _ThemeChoice({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final AlbumiumThemeOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = option.previewColors;
    return Semantics(
      selected: selected,
      child: Material(
        color: colors[1],
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected
                    ? colors[2].withValues(alpha: .7)
                    : colors[2].withValues(alpha: .1),
                width: selected ? 1.5 : 1,
              ),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    for (final swatch in colors)
                      Container(
                        width: 18,
                        height: 18,
                        margin: const EdgeInsets.only(right: 5),
                        decoration: BoxDecoration(
                          color: swatch,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: colors[2].withValues(alpha: .12),
                          ),
                        ),
                      ),
                    const Spacer(),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: selected
                          ? Icon(
                              Icons.check_circle_rounded,
                              key: const ValueKey('selected'),
                              color: colors[2],
                              size: 22,
                            )
                          : const SizedBox(
                              key: ValueKey('unselected'),
                              width: 22,
                              height: 22,
                            ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  context.tr(option.name),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: colors[2],
                    fontSize: 22,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  context.tr(option.description),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors[2].withValues(alpha: 0.72),
                    height: 1.35,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
