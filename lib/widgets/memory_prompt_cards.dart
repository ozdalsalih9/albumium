import 'package:flutter/material.dart';
import '../l10n/albumium_localizations.dart';
import '../models/memory_period.dart';

const _rose = Color(0xFFE9A7AB);
const _ink = Color(0xFFF6E7DF);

class MemoryPromptCards extends StatelessWidget {
  const MemoryPromptCards({super.key, required this.onSelect});
  final ValueChanged<MemoryKind> onSelect;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, box) {
      final width = box.maxWidth >= 620 ? (box.maxWidth - 28) / 3 : 230.0;
      final height =
          450.0 + (MediaQuery.textScalerOf(context).scale(16) - 16) * 8;
      return SizedBox(
        height: height,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final kind in MemoryKind.values)
                Padding(
                  padding: EdgeInsets.only(
                    right: kind == MemoryKind.year ? 0 : 14,
                  ),
                  child: SizedBox(
                    width: width,
                    child: _MemoryCard(kind: kind, onTap: () => onSelect(kind)),
                  ),
                ),
            ],
          ),
        ),
      );
    },
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
    final description = switch (kind) {
      MemoryKind.weekend =>
        'Küçük kaçamaklar, güzel sofralar… Hafta sonundan sana kalanları biriktir.',
      MemoryKind.month =>
        'Bir ay, bir sürü anı. En güzel karelerini kendi hikâyene dönüştür.',
      MemoryKind.year =>
        'Yeni başlangıçlar, başarılar ve unutulmaz anlar. Bu yıl senin hikâyen.',
    };
    final heading = Text(
      context.tr(title),
      textAlign: TextAlign.center,
      style: const TextStyle(
        color: _ink,
        fontSize: 18,
        fontWeight: FontWeight.w700,
        height: 1.15,
      ),
    );
    return Material(
      color: const Color(0xFF352C30),
      borderRadius: BorderRadius.circular(24),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: ValueKey('memory-card-${kind.name}'),
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF655055)),
          ),
          child: Column(
            children: [
              if (kind != MemoryKind.weekend)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                  child: heading,
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: switch (kind) {
                    MemoryKind.weekend => const _WeekendArtwork(),
                    MemoryKind.month => const _MonthArtwork(),
                    MemoryKind.year => const _YearArtwork(),
                  },
                ),
              ),
              if (kind == MemoryKind.weekend)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: heading,
                ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                child: Text(
                  context.tr(description),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFC8B7B7),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 18),
                child: FilledButton.icon(
                  onPressed: onTap,
                  style: FilledButton.styleFrom(
                    backgroundColor: _rose,
                    foregroundColor: const Color(0xFF392E32),
                    minimumSize: const Size(110, 44),
                  ),
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(context.tr('Ekle')),
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
            color: const Color(0xFF4B393F),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.calendar_month_outlined, color: _rose, size: 24),
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
                                ? _rose
                                : const Color(0xFF897079),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
        const Positioned(
          left: 0,
          top: 2,
          child: _MiniPhoto(asset: 'travel_keepsake', angle: -.18),
        ),
        const Positioned(
          right: 0,
          top: 14,
          child: _MiniPhoto(asset: 'seaside_keepsake', angle: .17),
        ),
        const Positioned(
          left: 2,
          bottom: 4,
          child: _MiniPhoto(asset: 'cafe_keepsake', angle: -.12),
        ),
        const Positioned(
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
        color: const Color(0xFFFFF0E3),
        borderRadius: BorderRadius.circular(3),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 3)),
        ],
      ),
      child: ColoredBox(
        color: const Color(0xFFE8CCD1),
        child: Icon(
          switch (asset) {
            'travel_keepsake' => Icons.landscape_outlined,
            'seaside_keepsake' => Icons.waves,
            'cafe_keepsake' => Icons.coffee_outlined,
            'friendship_keepsake' => Icons.favorite_outline,
            _ => Icons.auto_awesome_outlined,
          },
          color: const Color(0xFF90626F),
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
              Icon(entry.$1, color: _rose, size: 27),
              const SizedBox(width: 12),
              Container(width: 1, color: _rose.withValues(alpha: .4)),
              const SizedBox(width: 12),
              _MiniPhoto(asset: entry.$2),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.tr(entry.$3),
                  style: const TextStyle(
                    color: Color(0xFFC8B7B7),
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
          border: Border.all(color: _rose.withValues(alpha: .18), width: 1),
        ),
      ),
      Transform.rotate(
        angle: -.14,
        child: Container(
          width: 112,
          height: 132,
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 24),
          decoration: BoxDecoration(
            color: const Color(0xFF94717B),
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
            color: const Color(0xFFF0D8D5),
            borderRadius: BorderRadius.circular(9),
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                blurRadius: 15,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: const ColoredBox(
            color: Color(0xFFC699A2),
            child: Icon(
              Icons.landscape_outlined,
              color: Color(0xFFF9E7DF),
              size: 64,
            ),
          ),
        ),
      ),
      const Positioned(
        right: 10,
        top: 12,
        child: Icon(Icons.auto_awesome, color: _rose, size: 24),
      ),
      const Positioned(
        left: 4,
        bottom: 12,
        child: Icon(Icons.favorite, color: _rose, size: 22),
      ),
    ],
  );
}
