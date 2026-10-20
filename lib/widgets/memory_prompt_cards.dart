import 'package:flutter/material.dart';
import '../l10n/albumium_localizations.dart';
import '../models/album_models.dart';
import '../models/memory_period.dart';
import '../themes/theme_image_helper.dart';

class MemoryPromptCards extends StatelessWidget {
  const MemoryPromptCards({
    super.key,
    required this.onSelect,
    this.albums = const [],
    this.onContinue,
    this.onComplete,
  });
  final ValueChanged<MemoryKind> onSelect;
  final List<AlbumModel> albums;
  final ValueChanged<AlbumModel>? onContinue, onComplete;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final ongoing =
        albums
            .where(
              (a) =>
                  MemoryPeriod.fromKey(a.memoryPeriod) != null &&
                  !a.memoryCompleted,
            )
            .toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    final kinds = <MemoryKind>{};
    final recent = ongoing
        .where((a) => kinds.add(MemoryPeriod.fromKey(a.memoryPeriod)!.kind))
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr(
            'Büyük olaylar gerekmez. Bir fotoğraf, küçük bir not, senin hikâyen.',
          ),
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: colors.onSurfaceVariant,
            height: 1.45,
          ),
        ),
        if (ongoing.isNotEmpty && onContinue != null) ...[
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.bookmark_outline_rounded,
                size: 18,
                color: colors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  context.tr('Kaldığın yerden, küçük bir an daha.'),
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          for (final album in recent)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ContinueMemoryCard(
                album: album,
                onTap: () => onContinue!(album),
                onComplete: onComplete == null
                    ? null
                    : () => onComplete!(album),
              ),
            ),
          const SizedBox(height: 10),
          Text(
            context.tr('Yeni bir sayfa aç'),
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 10),
        ] else
          const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final stack =
                constraints.maxWidth < 330 ||
                MediaQuery.textScalerOf(context).scale(12) > 19;
            final cards = [
              for (final kind in MemoryKind.values)
                _StartMemoryCard(
                  kind: kind,
                  horizontal: stack,
                  exists: albums.any(
                    (a) =>
                        a.memoryPeriod ==
                            MemoryPeriod.current(kind, DateTime.now()).key &&
                        !a.memoryCompleted,
                  ),
                  onTap: () => onSelect(kind),
                ),
            ];
            return stack
                ? Column(
                    children: [
                      for (final card in cards)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: card,
                        ),
                    ],
                  )
                : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < cards.length; i++) ...[
                        if (i > 0) const SizedBox(width: 10),
                        Expanded(child: cards[i]),
                      ],
                    ],
                  );
          },
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.favorite_border_rounded,
              color: colors.primary,
              size: 15,
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                context.tr(
                  'Az az biriktir. Günün geldiğinde hepsi bir hikâye olur.',
                ),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colors.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ContinueMemoryCard extends StatelessWidget {
  const _ContinueMemoryCard({
    required this.album,
    required this.onTap,
    this.onComplete,
  });
  final AlbumModel album;
  final VoidCallback onTap;
  final VoidCallback? onComplete;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final photos = album.pages
        .expand((p) => p.elements)
        .where((e) => e.type == AlbumElementType.photo && e.content.isNotEmpty)
        .length;
    return Material(
      color: colors.surfaceContainerLow,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: colors.primary.withValues(alpha: .16)),
          ),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Transform.rotate(
                    angle: -.035,
                    child: Container(
                      width: 61,
                      height: 78,
                      padding: const EdgeInsets.fromLTRB(4, 4, 4, 10),
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: colors.shadow.withValues(alpha: .10),
                            blurRadius: 8,
                            offset: const Offset(1, 3),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: album.coverPhotoPath != null
                            ? ThemeImage(
                                url: album.coverPhotoPath!,
                                cacheWidth: 240,
                              )
                            : ColoredBox(
                                color: colors.primaryContainer,
                                child: Icon(
                                  Icons.auto_stories_outlined,
                                  color: colors.onPrimaryContainer,
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.tr('DEVAM EDEN HİKÂYEN'),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: .8,
                            color: colors.primary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          album.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(
                                fontFamily: 'AlbumiumDisplay',
                                height: 1.2,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          context.tr(
                            '{photos} fotoğraf · {pages} sayfa',
                            values: {
                              'photos': photos,
                              'pages': album.pages.length,
                            },
                          ),
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  if (onComplete != null)
                    PopupMenuButton<String>(
                      tooltip: context.tr('Albüm seçenekleri'),
                      onSelected: (_) => onComplete!(),
                      itemBuilder: (_) => [
                        PopupMenuItem(
                          value: 'complete',
                          child: Text(context.tr('Şimdilik tamamlandı')),
                        ),
                      ],
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      context.tr('Bir kare daha eklemek ister misin?'),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton.tonalIcon(
                    onPressed: onTap,
                    icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                    label: Text(context.tr('Devam et')),
                    style: FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
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

class _StartMemoryCard extends StatelessWidget {
  const _StartMemoryCard({
    required this.kind,
    required this.onTap,
    required this.exists,
    required this.horizontal,
  });
  final MemoryKind kind;
  final VoidCallback onTap;
  final bool exists, horizontal;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final title = switch (kind) {
      MemoryKind.weekend => 'Haftam',
      MemoryKind.month => 'Ayım',
      MemoryKind.year => 'Yılım',
    };
    final caption = switch (kind) {
      MemoryKind.weekend => 'Küçük güzel anlar',
      MemoryKind.month => 'Bir ayın hikâyesi',
      MemoryKind.year => 'Geriye kalan güzellikler',
    };
    final icon = switch (kind) {
      MemoryKind.weekend => Icons.wb_sunny_outlined,
      MemoryKind.month => Icons.calendar_month_outlined,
      MemoryKind.year => Icons.auto_awesome_outlined,
    };
    final tint = switch (kind) {
      MemoryKind.weekend => const Color(0xFFD8B883),
      MemoryKind.month => const Color(0xFFB1BFA8),
      MemoryKind.year => const Color(0xFFC7ADBD),
    };
    final art = SizedBox(
      width: horizontal ? 56 : 62,
      height: horizontal ? 62 : 72,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Transform.rotate(
            angle: -.13,
            child: Container(
              width: 41,
              height: 53,
              decoration: BoxDecoration(
                color: tint.withValues(alpha: .45),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
          ),
          Transform.rotate(
            angle: .06,
            child: Container(
              width: 41,
              height: 53,
              padding: const EdgeInsets.fromLTRB(4, 4, 4, 10),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(5),
                boxShadow: [
                  BoxShadow(
                    color: colors.shadow.withValues(alpha: .10),
                    blurRadius: 6,
                    offset: const Offset(1, 3),
                  ),
                ],
              ),
              child: ColoredBox(
                color: tint.withValues(alpha: .3),
                child: Icon(icon, color: colors.primary, size: 24),
              ),
            ),
          ),
        ],
      ),
    );
    final text = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: horizontal
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        Text(
          context.tr(title),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontFamily: 'AlbumiumDisplay',
            fontSize: 20,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          context.tr(caption),
          textAlign: horizontal ? TextAlign.start : TextAlign.center,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontSize: 11,
            height: 1.3,
            color: colors.onSurfaceVariant,
          ),
        ),
      ],
    );
    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        key: ValueKey('memory-card-${kind.name}'),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: horizontal
              ? Row(
                  children: [
                    art,
                    const SizedBox(width: 12),
                    Expanded(child: text),
                    Icon(Icons.arrow_forward_rounded, color: colors.primary),
                  ],
                )
              : Column(
                  children: [
                    art,
                    text,
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      decoration: BoxDecoration(
                        color: colors.primaryContainer.withValues(alpha: .55),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        context.tr(exists ? 'Devam' : 'Başla'),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: colors.onPrimaryContainer,
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
