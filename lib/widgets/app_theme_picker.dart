import 'package:flutter/material.dart';

import '../services/theme_controller.dart';
import '../theme/albumium_app_theme.dart';
import 'handmade_craft.dart';

Future<void> showAlbumiumThemePicker(
  BuildContext context,
  ThemeController controller,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
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
        final tablet = MediaQuery.sizeOf(context).shortestSide >= 600;
        return Align(
          alignment: Alignment.bottomCenter,
          widthFactor: 1,
          heightFactor: 1,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 2, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 43,
                        height: 43,
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          Icons.palette_outlined,
                          color: colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TornPaperLabel(
                          rotationDegrees: -.35,
                          padding: const EdgeInsets.fromLTRB(12, 6, 12, 7),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Uygulama görünümü',
                                style: Theme.of(
                                  context,
                                ).textTheme.titleLarge?.copyWith(fontSize: 23),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Albüm tasarımlarından bağımsızdır.',
                                style: TextStyle(fontSize: 11),
                              ),
                            ],
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: AlbumiumAppTheme.options.length,
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: tablet ? 4 : 2,
                      childAspectRatio: 1.13,
                      crossAxisSpacing: 11,
                      mainAxisSpacing: 11,
                    ),
                    itemBuilder: (context, index) {
                      final option = AlbumiumAppTheme.options[index];
                      return _ThemeChoice(
                        option: option,
                        selected: option.id == controller.themeId,
                        onTap: () => controller.setTheme(option.id),
                      );
                    },
                  ),
                  const SizedBox(height: 22),
                  const Text(
                    'Parlaklık',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 9),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<ThemeMode>(
                      segments: const [
                        ButtonSegment(
                          value: ThemeMode.dark,
                          icon: Icon(Icons.dark_mode_outlined),
                          label: Text('Koyu'),
                        ),
                        ButtonSegment(
                          value: ThemeMode.light,
                          icon: Icon(Icons.light_mode_outlined),
                          label: Text('Açık'),
                        ),
                        ButtonSegment(
                          value: ThemeMode.system,
                          icon: Icon(Icons.settings_suggest_outlined),
                          label: Text('Sistem'),
                        ),
                      ],
                      selected: {controller.themeMode},
                      onSelectionChanged: (selection) {
                        controller.setThemeMode(selection.first);
                      },
                    ),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.check_rounded),
                      label: Text(
                        '${controller.selectedOption.name} temasını kullan',
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(7),
        child: PaperPanel(
          color: colors[1],
          rotationDegrees: option.id.index.isEven ? -.35 : .35,
          borderRadius: BorderRadius.circular(7),
          padding: const EdgeInsets.all(9),
          tapePositions: selected
              ? const [CraftTapePosition.topRight]
              : const [],
          tapeColor: Color.lerp(colors.first, Colors.white, .52),
          tapeWidth: 38,
          tapeHeight: 12,
          child: StitchedBorder(
            color: selected ? colors.first : colors[2].withValues(alpha: .28),
            inset: 2,
            borderRadius: BorderRadius.circular(6),
            padding: const EdgeInsets.all(7),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(option.icon, color: colors.first, size: 24),
                    const Spacer(),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      child: selected
                          ? Icon(
                              Icons.check_circle_rounded,
                              key: const ValueKey('selected'),
                              color: colors.first,
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
                  option.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: colors[2],
                    fontSize: 20,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  option.description,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors[2].withValues(alpha: 0.72),
                    height: 1.15,
                    fontSize: 9.5,
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
