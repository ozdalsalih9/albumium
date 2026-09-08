import 'package:flutter/material.dart';
import '../l10n/albumium_localizations.dart';
import '../models/memory_period.dart';

class MemoryPromptCards extends StatelessWidget {
  const MemoryPromptCards({super.key, required this.onSelect});
  final ValueChanged<MemoryKind> onSelect;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (final kind in MemoryKind.values) ...[
        if (kind != MemoryKind.weekend) const SizedBox(width: 8),
        Expanded(
          child: _MemoryCard(kind: kind, onTap: () => onSelect(kind)),
        ),
      ],
    ],
  );
}

class _MemoryCard extends StatelessWidget {
  const _MemoryCard({required this.kind, required this.onTap});
  final MemoryKind kind;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final title = switch (kind) {
      MemoryKind.weekend => 'HAFTA SONUNU HATIRLA',
      MemoryKind.month => 'BU AYIN HİKÂYESİ',
      MemoryKind.year => 'YILLIK KİLOMETRE TAŞLARI',
    };
    final textScale = MediaQuery.textScalerOf(context);
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainer,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: ValueKey('memory-card-${kind.name}'),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
          ),
          child: Column(
            children: [
              SizedBox(
                height: 76,
                width: double.infinity,
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: SizedBox(
                    width: 210,
                    height: 190,
                    child: switch (kind) {
                      MemoryKind.weekend => const _WeekendArtwork(),
                      MemoryKind.month => const _MonthArtwork(),
                      MemoryKind.year => const _YearArtwork(),
                    },
                  ),
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: textScale.scale(11) * 1.25 * 4,
                child: Center(
                  child: Text(
                    context.tr(title),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onTap,
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    minimumSize: const Size(0, 40),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 8,
                    ),
                    textStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: Text(
                    '+ ${context.tr('Ekle')}',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MonthArtwork extends StatelessWidget {
  const _MonthArtwork();
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) => Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: box.maxWidth * .66,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.calendar_month_outlined,
                color: Theme.of(context).colorScheme.primary,
                size: 24,
              ),
              const SizedBox(height: 8),
              for (var row = 0; row < 4; row++)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (var col = 0; col < 7; col++)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Container(
                          width: 9,
                          height: 9,
                          decoration: BoxDecoration(
                            color: row == 1 && col == 4
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context)
                                      .colorScheme
                                      .onSecondaryContainer
                                      .withValues(alpha: .4),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
        Positioned(
          left: 0,
          top: 2,
          child: _MiniPhoto(asset: 'travel_keepsake', angle: -.18),
        ),
        Positioned(
          right: 0,
          top: 14,
          child: _MiniPhoto(asset: 'seaside_keepsake', angle: .17),
        ),
        Positioned(
          left: 2,
          bottom: 4,
          child: _MiniPhoto(asset: 'cafe_keepsake', angle: -.12),
        ),
        Positioned(
          right: 0,
          bottom: 0,
          child: _MiniPhoto(asset: 'celebration_keepsake', angle: .16),
        ),
      ],
    ),
  );
}

class _MiniPhoto extends StatelessWidget {
  const _MiniPhoto({required this.asset, this.angle = 0});
  final String asset;
  final double angle;
  @override
  Widget build(BuildContext context) => Transform.rotate(
    angle: angle,
    child: Container(
      width: 46,
      height: 55,
      padding: const EdgeInsets.fromLTRB(3, 3, 3, 9),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(3),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 3)),
        ],
      ),
      child: ColoredBox(
        color: Theme.of(context).colorScheme.primaryContainer,
        child: Icon(
          switch (asset) {
            'travel_keepsake' => Icons.landscape_outlined,
            'seaside_keepsake' => Icons.waves,
            'cafe_keepsake' => Icons.coffee_outlined,
            'friendship_keepsake' => Icons.favorite_outline,
            _ => Icons.auto_awesome_outlined,
          },
          color: Theme.of(context).colorScheme.onPrimaryContainer,
          size: 24,
        ),
      ),
    ),
  );
}

class _YearArtwork extends StatelessWidget {
  const _YearArtwork();
  @override
  Widget build(BuildContext context) => Column(
    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
    children: [
      for (final entry in [
        (Icons.key_rounded, 'travel_keepsake', 'Yeni başlangıçlar'),
        (
          Icons.workspace_premium_outlined,
          'celebration_keepsake',
          'Gurur duyduğun anlar',
        ),
        (Icons.school_outlined, 'friendship_keepsake', 'Birlikte büyüdük'),
      ])
        Expanded(
          child: Row(
            children: [
              Icon(
                entry.$1,
                color: Theme.of(context).colorScheme.primary,
                size: 27,
              ),
              const SizedBox(width: 12),
              Container(
                width: 1,
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: .4),
              ),
              const SizedBox(width: 12),
              _MiniPhoto(asset: entry.$2),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.tr(entry.$3),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
    ],
  );
}

class _WeekendArtwork extends StatelessWidget {
  const _WeekendArtwork();
  @override
  Widget build(BuildContext context) => Stack(
    alignment: Alignment.center,
    children: [
      Container(
        width: 145,
        height: 145,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: .18),
            width: 1,
          ),
        ),
      ),
      Transform.rotate(
        angle: -.14,
        child: Container(
          width: 112,
          height: 132,
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondaryContainer,
            borderRadius: BorderRadius.circular(9),
          ),
        ),
      ),
      Transform.rotate(
        angle: .12,
        child: Container(
          width: 112,
          height: 132,
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(9),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 15,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: ColoredBox(
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Icon(
              Icons.landscape_outlined,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
              size: 64,
            ),
          ),
        ),
      ),
      Positioned(
        right: 10,
        top: 12,
        child: Icon(
          Icons.auto_awesome,
          color: Theme.of(context).colorScheme.primary,
          size: 24,
        ),
      ),
      Positioned(
        left: 4,
        bottom: 12,
        child: Icon(
          Icons.favorite,
          color: Theme.of(context).colorScheme.primary,
          size: 22,
        ),
      ),
    ],
  );
}
