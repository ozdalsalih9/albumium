import 'package:flutter/material.dart';
import '../l10n/albumium_localizations.dart';
import '../models/album_models.dart';
import 'photo_slot_shapes.dart';
import 'photo_style_picker.dart';

class PhotoSlotPreset {
  const PhotoSlotPreset(
    this.title,
    this.cells, {
    this.shape = AlbumPhotoShape.free,
  });
  final String title;
  final List<Rect> cells;
  final AlbumPhotoShape shape;
  List<AlbumElementModel> create() {
    final group = cells.length > 1 ? newId() : null;
    return [
      for (final r in cells)
        AlbumElementModel(
          id: newId(),
          type: AlbumElementType.photo,
          content: '',
          x: r.left,
          y: r.top,
          width: r.width,
          height: r.height,
          photoShape: shape,
          photoSlot: true,
          photoFit: BoxFit.contain,
          groupId: group,
        ),
    ];
  }
}

/// Recover grids created before grouping was saved. Only complete untouched
/// preset layouts qualify; independently positioned frames remain independent.
void recoverPhotoGridGroups(AlbumPageModel page) {
  for (final preset in photoGridPresets.reversed) {
    final matches = <AlbumElementModel>[];
    for (final rect in preset.cells) {
      final candidates = page.elements
          .where(
            (e) =>
                e.photoSlot &&
                e.groupId == null &&
                e.rotation.abs() < .001 &&
                (e.scale - 1).abs() < .001 &&
                (e.x - rect.left).abs() < .003 &&
                (e.y - rect.top).abs() < .003 &&
                (e.width - rect.width).abs() < .003 &&
                (e.height - rect.height).abs() < .003,
          )
          .toList();
      if (candidates.isEmpty) break;
      matches.add(candidates.first);
    }
    if (matches.length == preset.cells.length) {
      final group = newId();
      for (final cell in matches) {
        cell.groupId = group;
      }
    }
  }
}

const photoGridPresets = [
  PhotoSlotPreset('Yan yana', [
    Rect.fromLTWH(.08, .20, .41, .60),
    Rect.fromLTWH(.51, .20, .41, .60),
  ]),
  PhotoSlotPreset('Alt alta', [
    Rect.fromLTWH(.08, .18, .84, .31),
    Rect.fromLTWH(.08, .51, .84, .31),
  ]),
  PhotoSlotPreset('Üçlü şerit', [
    Rect.fromLTWH(.08, .20, .267, .60),
    Rect.fromLTWH(.367, .20, .266, .60),
    Rect.fromLTWH(.653, .20, .267, .60),
  ]),
  PhotoSlotPreset('Dört an', [
    Rect.fromLTWH(.08, .18, .41, .31),
    Rect.fromLTWH(.51, .18, .41, .31),
    Rect.fromLTWH(.08, .51, .41, .31),
    Rect.fromLTWH(.51, .51, .41, .31),
  ]),
  PhotoSlotPreset('Bir büyük, iki küçük', [
    Rect.fromLTWH(.08, .18, .52, .64),
    Rect.fromLTWH(.62, .18, .30, .31),
    Rect.fromLTWH(.62, .51, .30, .31),
  ]),
  PhotoSlotPreset('Başlık karesi', [
    Rect.fromLTWH(.08, .18, .84, .36),
    Rect.fromLTWH(.08, .56, .41, .26),
    Rect.fromLTWH(.51, .56, .41, .26),
  ]),
  PhotoSlotPreset('Altı an', [
    Rect.fromLTWH(.08, .14, .41, .227),
    Rect.fromLTWH(.51, .14, .41, .227),
    Rect.fromLTWH(.08, .387, .41, .226),
    Rect.fromLTWH(.51, .387, .41, .226),
    Rect.fromLTWH(.08, .633, .41, .227),
    Rect.fromLTWH(.51, .633, .41, .227),
  ]),
];

PhotoSlotPreset photoShapePreset(AlbumPhotoShape shape) {
  final aspect = switch (shape) {
    AlbumPhotoShape.landscape || AlbumPhotoShape.torn => 4 / 3,
    AlbumPhotoShape.portrait || AlbumPhotoShape.arch => 4 / 5,
    _ => 1.0,
  };
  final h = .64 * 5 / 7 / aspect;
  return PhotoSlotPreset(albumPhotoShapeLabel(shape), [
    Rect.fromLTWH(.18, (1 - h) / 2, .64, h),
  ], shape: shape);
}

Future<PhotoSlotPreset?> showPhotoSlotPicker(BuildContext context) =>
    showModalBottomSheet<PhotoSlotPreset>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => const _PhotoSlotPicker(),
    );

class _PhotoSlotPicker extends StatelessWidget {
  const _PhotoSlotPicker();
  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 2,
    child: SizedBox(
      height: MediaQuery.sizeOf(context).height * .75,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
            child: Column(
              children: [
                Text(
                  context.tr('Fotoğraf yuvaları'),
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 6),
                Text(
                  context.tr(
                    'Bir şekil seç. Dokunarak veya fotoğraf sürükleyerek doldur.',
                  ),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          TabBar(
            tabs: [
              Tab(text: context.tr('Şekiller')),
              Tab(text: context.tr('Izgaralar')),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _grid(context, [
                  for (final shape in AlbumPhotoShape.values.where(
                    (s) => s != AlbumPhotoShape.free,
                  ))
                    photoShapePreset(shape),
                ]),
                _grid(context, photoGridPresets),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _grid(BuildContext context, List<PhotoSlotPreset> presets) =>
      GridView.builder(
        padding: const EdgeInsets.all(18),
        itemCount: presets.length,
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 180,
          mainAxisExtent: 180,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemBuilder: (context, i) {
          final p = presets[i];
          return Material(
            color: Theme.of(context).colorScheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => Navigator.pop(context, p),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Expanded(
                      child: AspectRatio(
                        aspectRatio: 5 / 7,
                        child: LayoutBuilder(
                          builder: (context, constraints) => Stack(
                            children: [
                              for (final r in p.cells)
                                Positioned(
                                  left: r.left * constraints.maxWidth,
                                  top: r.top * constraints.maxHeight,
                                  width: r.width * constraints.maxWidth,
                                  height: r.height * constraints.maxHeight,
                                  child: ClipPath(
                                    clipper: PhotoSlotClipper(p.shape),
                                    child: const CustomPaint(
                                      painter: PhotoSlotArtwork(),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      context.tr(p.title),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
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
