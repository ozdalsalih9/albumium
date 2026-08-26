import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/album_models.dart';
import '../services/album_storage.dart';
import '../widgets/album_page_canvas.dart';
import '../widgets/font_selector_dialog.dart';
import '../widgets/handwriting_painter.dart';
import '../widgets/occasion_cards.dart';
import '../widgets/sticker_packs.dart';
import 'preview_screen.dart';

const _vintagePaperChoices = <({String name, Color color})>[
  (name: 'Eski fildişi', color: Color(0xFFF2E8D3)),
  (name: 'Vanilya', color: Color(0xFFF6EDD9)),
  (name: 'Keten', color: Color(0xFFE6D7BE)),
  (name: 'Pudra pembe', color: Color(0xFFE8C8CD)),
  (name: 'Gül kurusu', color: Color(0xFFD5ABB0)),
  (name: 'Şeftali', color: Color(0xFFE8C4AD)),
  (name: 'Adaçayı', color: Color(0xFFCCD2BD)),
  (name: 'Lavanta', color: Color(0xFFD8D0E1)),
  (name: 'Duman mavisi', color: Color(0xFFBCCBD0)),
  (name: 'Kraft', color: Color(0xFFCBB38E)),
  (name: 'Gece mürekkebi', color: Color(0xFF292827)),
  (name: 'Bordo', color: Color(0xFF4A292F)),
];

const _frameIcons = <IconData>[
  Icons.crop_square_rounded,
  Icons.photo_outlined,
  Icons.bookmarks_outlined,
  Icons.rounded_corner_rounded,
  Icons.filter_vintage_outlined,
  Icons.filter_frames_outlined,
  Icons.texture_rounded,
  Icons.movie_outlined,
  Icons.museum_outlined,
  Icons.grid_goldenratio_rounded,
  Icons.local_post_office_outlined,
  Icons.auto_awesome_mosaic_outlined,
];

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key, required this.album});

  final AlbumModel album;

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  final _picker = ImagePicker();
  int _pageIndex = 0;
  String? _selectedId;
  bool _importing = false;
  Timer? _saveDebounce;

  AlbumModel get album => widget.album;
  AlbumPageModel get page => album.pages[_pageIndex];
  AlbumElementModel? get selectedElement {
    if (_selectedId == null) return null;
    for (final element in page.elements) {
      if (element.id == _selectedId) return element;
    }
    return null;
  }

  int get _defaultPageColor {
    final base = themeById(album.themeId).pageColor;
    if (base.computeLuminance() < 0.82) return base.toARGB32();
    return Color.alphaBlend(const Color(0x16B47A47), base).toARGB32();
  }

  Size _stickerSize(String sticker) {
    if (!isIllustratedSticker(sticker)) return const Size(0.18, 0.13);
    if (sticker.contains('washi_') ||
        sticker.endsWith(':film_strip') ||
        sticker.contains('ribbon_') ||
        sticker.endsWith(':vintage_ticket')) {
      return const Size(0.42, 0.105);
    }
    if (sticker.contains('pressed_') ||
        sticker.endsWith(':fern') ||
        sticker.endsWith(':gold_branch')) {
      return const Size(0.21, 0.3);
    }
    if (sticker.contains('postage_')) return const Size(0.23, 0.2);
    return const Size(0.19, 0.15);
  }

  double _stickerRotation(String sticker) {
    if (sticker.contains('washi_')) return -0.055;
    if (sticker.contains('postage_')) return 0.07;
    if (sticker.endsWith(':vintage_ticket')) return -0.04;
    return 0.025;
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    unawaited(AlbumStorage.instance.saveAlbum(album));
    super.dispose();
  }

  void _changed() {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 450), () {
      unawaited(AlbumStorage.instance.saveAlbum(album));
    });
  }

  Future<void> _addPhotos() async {
    final picked = await _picker.pickMultiImage(
      limit: 20,
      imageQuality: 92,
      maxWidth: 2600,
    );
    if (picked.isEmpty || !mounted) return;
    setState(() => _importing = true);
    final paths = <String>[];
    for (final file in picked) {
      paths.add(await AlbumStorage.instance.importImage(file));
    }
    if (!mounted) return;
    setState(() {
      for (var index = 0; index < paths.length; index++) {
        final target = index == 0
            ? page
            : AlbumPageModel(id: newId(), backgroundColor: _defaultPageColor);
        if (index > 0) album.pages.insert(_pageIndex + index, target);
        final offset = target.elements
            .where((element) => element.type == AlbumElementType.photo)
            .length;
        target.elements.add(
          AlbumElementModel(
            id: newId(),
            type: AlbumElementType.photo,
            content: paths[index],
            x: 0.12 + (offset % 2) * 0.06,
            y: 0.15 + (offset % 3) * 0.06,
            width: 0.76,
            height: 0.54,
            rotation: offset.isEven ? -0.02 : 0.025,
            frameStyle: 1,
          ),
        );
      }
      _selectedId = page.elements.last.id;
      _importing = false;
    });
    _changed();
  }

  Future<void> _addText() async {
    final result = await showDialog<TextElementResult>(
      context: context,
      builder: (_) => const TextEditorDialog(),
    );
    if (result == null || result.text.isEmpty || !mounted) return;
    setState(() {
      final element = AlbumElementModel(
        id: newId(),
        type: AlbumElementType.text,
        content: result.text,
        extraData: result.fontFamily,
        fontSize: result.fontSize,
        textColor: result.textColor,
        x: 0.1,
        y: 0.72,
        width: 0.8,
        height: 0.14,
      );
      page.elements.add(element);
      _selectedId = element.id;
    });
    _changed();
  }

  Future<void> _editSelectedText(AlbumElementModel element) async {
    final result = await showDialog<TextElementResult>(
      context: context,
      builder: (_) => TextEditorDialog(
        initialText: element.content,
        initialFont: element.extraData.isNotEmpty
            ? element.extraData
            : 'Caveat',
        initialFontSize: element.fontSize,
        initialColor: element.textColor,
      ),
    );
    if (result == null || result.text.isEmpty || !mounted) return;
    setState(() {
      element.content = result.text;
      element.extraData = result.fontFamily;
      element.fontSize = result.fontSize;
      element.textColor = result.textColor;
    });
    _changed();
  }

  Future<void> _addHandwriting() async {
    final drawingData = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (_) => const HandwritingCanvasDialog(),
        fullscreenDialog: true,
      ),
    );
    if (drawingData == null || drawingData.isEmpty || !mounted) return;

    final decoded = HandwritingData.decode(drawingData);
    final ratio = decoded.aspectRatio > 0.05 ? decoded.aspectRatio : 1.0;

    // Calculate proportional width & height on the 9:14 aspect page so it NEVER stretches
    const baseHeight = 0.28;
    // Page aspect ratio is 9 / 14 = 0.643
    final baseWidth = (baseHeight * ratio * (14.0 / 9.0)).clamp(0.25, 0.85);

    setState(() {
      final element = AlbumElementModel(
        id: newId(),
        type: AlbumElementType.drawing,
        content: drawingData,
        x: (0.5 - baseWidth / 2).clamp(0.05, 0.7),
        y: 0.35,
        width: baseWidth,
        height: baseHeight,
        rotation: -0.01,
      );
      page.elements.add(element);
      _selectedId = element.id;
    });
    _changed();
  }

  Future<void> _addOccasionCard() async {
    final result = await showModalBottomSheet<OccasionCardPickerResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const OccasionCardPickerSheet(),
    );
    if (result == null || !mounted) return;
    setState(() {
      final element = AlbumElementModel(
        id: newId(),
        type: AlbumElementType.card,
        content: result.template.id,
        extraData: result.customData.encode(),
        x: 0.08,
        y: 0.22,
        width: 0.84,
        height: 0.28,
        rotation: 0.01,
      );
      page.elements.add(element);
      _selectedId = element.id;
    });
    _changed();
  }

  Future<void> _editSelectedCard(AlbumElementModel element) async {
    final customData = await showDialog<OccasionCardCustomData>(
      context: context,
      builder: (_) => EditOccasionCardDialog(
        cardId: element.content,
        initialDataRaw: element.extraData,
      ),
    );
    if (customData == null || !mounted) return;
    setState(() {
      element.extraData = customData.encode();
    });
    _changed();
  }

  Future<void> _addSticker() async {
    final sticker = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => const StickerPackPickerSheet(),
    );
    if (sticker == null || !mounted) return;
    final size = _stickerSize(sticker);
    setState(() {
      final element = AlbumElementModel(
        id: newId(),
        type: AlbumElementType.sticker,
        content: sticker,
        x: (0.5 - size.width / 2).clamp(0.04, 0.84),
        y: 0.12,
        width: size.width,
        height: size.height,
        rotation: _stickerRotation(sticker),
      );
      page.elements.add(element);
      _selectedId = element.id;
    });
    _changed();
  }

  void _addPage() {
    setState(() {
      album.pages.insert(
        _pageIndex + 1,
        AlbumPageModel(id: newId(), backgroundColor: _defaultPageColor),
      );
      _pageIndex++;
      _selectedId = null;
    });
    _changed();
  }

  void _duplicatePage() {
    final copy = AlbumPageModel(
      id: newId(),
      backgroundColor: page.backgroundColor,
      elements: page.elements
          .map(
            (e) => AlbumElementModel(
              id: newId(),
              type: e.type,
              content: e.content,
              x: e.x,
              y: e.y,
              width: e.width,
              height: e.height,
              rotation: e.rotation,
              scale: e.scale,
              frameStyle: e.frameStyle,
              textColor: e.textColor,
              fontSize: e.fontSize,
              extraData: e.extraData,
            ),
          )
          .toList(),
    );
    setState(() {
      album.pages.insert(_pageIndex + 1, copy);
      _pageIndex++;
      _selectedId = null;
    });
    _changed();
  }

  void _deletePage() {
    if (album.pages.length == 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Albümde en az bir sayfa kalmalı.')),
      );
      return;
    }
    setState(() {
      album.pages.removeAt(_pageIndex);
      _pageIndex = _pageIndex.clamp(0, album.pages.length - 1);
      _selectedId = null;
    });
    _changed();
  }

  void _changeBinding() {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Albüm Ciltleme Tipi',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 14),
              for (final binding in AlbumBindingType.values)
                ListTile(
                  leading: Icon(
                    binding.icon,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(
                    binding.title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(binding.description),
                  trailing: album.bindingType == binding
                      ? Icon(
                          Icons.check_circle_rounded,
                          color: Theme.of(context).colorScheme.primary,
                        )
                      : null,
                  onTap: () {
                    setState(() => album.bindingType = binding);
                    _changed();
                    Navigator.pop(context);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _changeBackground() {
    final theme = themeById(album.themeId);
    final seenColors = <int>{};
    final colors = <({String name, Color color})>[
      (name: 'Temaya özel', color: theme.pageColor),
      ..._vintagePaperChoices,
    ].where((choice) => seenColors.add(choice.color.toARGB32())).toList();
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.texture_rounded, size: 23),
                  SizedBox(width: 10),
                  Text(
                    'Vintage kâğıt seç',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                'Her renk ince lif, tanecik ve kenar patinasıyla uygulanır.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                spacing: 10,
                runSpacing: 12,
                children: [
                  for (final choice in colors)
                    _PaperColorTile(
                      name: choice.name,
                      color: choice.color,
                      selected: page.backgroundColor == choice.color.toARGB32(),
                      onTap: () {
                        setState(
                          () => page.backgroundColor = choice.color.toARGB32(),
                        );
                        _changed();
                        Navigator.pop(context);
                      },
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _removeSelected() {
    final selected = selectedElement;
    if (selected == null) return;
    setState(() {
      page.elements.removeWhere((element) => element.id == selected.id);
      _selectedId = null;
    });
    _changed();
  }

  void _bringForward() {
    final selected = selectedElement;
    if (selected == null) return;
    setState(() {
      page.elements.remove(selected);
      page.elements.add(selected);
    });
    _changed();
  }

  void _duplicateSelected() {
    final selected = selectedElement;
    if (selected == null) return;
    setState(() {
      final copy = AlbumElementModel(
        id: newId(),
        type: selected.type,
        content: selected.content,
        x: (selected.x + 0.035).clamp(-0.3, 0.9),
        y: (selected.y + 0.025).clamp(-0.2, 0.92),
        width: selected.width,
        height: selected.height,
        rotation: selected.rotation,
        scale: selected.scale,
        frameStyle: selected.frameStyle,
        textColor: selected.textColor,
        fontSize: selected.fontSize,
        extraData: selected.extraData,
      );
      page.elements.add(copy);
      _selectedId = copy.id;
    });
    _changed();
  }

  Future<void> _styleSelected() async {
    final selected = selectedElement;
    if (selected == null) return;

    if (selected.type == AlbumElementType.photo) {
      final frame = await showModalBottomSheet<int>(
        context: context,
        showDragHandle: true,
        isScrollControlled: true,
        builder: (context) => _PhotoFramePicker(
          selectedStyle: selected.frameStyle % albumPhotoFrameCount,
        ),
      );
      if (frame == null || !mounted) return;
      setState(() => selected.frameStyle = frame);
      _changed();
      return;
    }

    if (selected.type == AlbumElementType.text) {
      await _editSelectedText(selected);
      return;
    }
    if (selected.type == AlbumElementType.card) {
      await _editSelectedCard(selected);
      return;
    }
    if (selected.type == AlbumElementType.sticker) {
      final replacement = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (context) => const StickerPackPickerSheet(),
      );
      if (replacement == null || !mounted) return;
      final oldCenterX = selected.x + selected.width / 2;
      final oldCenterY = selected.y + selected.height / 2;
      final size = _stickerSize(replacement);
      setState(() {
        selected.content = replacement;
        selected.width = size.width;
        selected.height = size.height;
        selected.x = oldCenterX - size.width / 2;
        selected.y = oldCenterY - size.height / 2;
      });
      _changed();
      return;
    }

    setState(() => selected.rotation += 0.18);
    _changed();
  }

  Future<void> _editTitle() async {
    final controller = TextEditingController(text: album.title);
    final title = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Albüm adını değiştir'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (title == null || title.isEmpty || !mounted) return;
    setState(() => album.title = title);
    _changed();
  }

  Future<void> _preview() async {
    await AlbumStorage.instance.saveAlbum(album);
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PreviewScreen(album: album)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = themeById(album.themeId);
    return PopScope(
      onPopInvokedWithResult: (_, _) =>
          unawaited(AlbumStorage.instance.saveAlbum(album)),
      child: Scaffold(
        appBar: AppBar(
          titleSpacing: 0,
          title: GestureDetector(
            onTap: _editTitle,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: Text(album.title, overflow: TextOverflow.ellipsis),
                ),
                const SizedBox(width: 5),
                Icon(
                  Icons.edit_outlined,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
          actions: [
            IconButton(
              onPressed: _changeBinding,
              icon: Icon(album.bindingType.icon),
              tooltip: 'Cilt Tipi (${album.bindingType.title})',
            ),
            TextButton.icon(
              onPressed: _preview,
              icon: const Icon(Icons.menu_book_rounded),
              label: const Text('Kitap Aç'),
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              _PageNavigator(
                current: _pageIndex,
                total: album.pages.length,
                onPrevious: _pageIndex == 0
                    ? null
                    : () => setState(() {
                        _pageIndex--;
                        _selectedId = null;
                      }),
                onNext: _pageIndex == album.pages.length - 1
                    ? null
                    : () => setState(() {
                        _pageIndex++;
                        _selectedId = null;
                      }),
                onAdd: _addPage,
                onMore: () => _showPageMenu(context),
              ),
              Expanded(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(28, 6, 28, 10),
                    child: AspectRatio(
                      aspectRatio: 9 / 14,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Positioned.fill(
                            child: AlbumPageCanvas(
                              key: ValueKey(page.id),
                              page: page,
                              theme: theme,
                              interactive: true,
                              selectedId: _selectedId,
                              onSelect: (id) =>
                                  setState(() => _selectedId = id),
                              onChanged: _changed,
                            ),
                          ),
                          if (_importing)
                            const Positioned.fill(
                              child: ColoredBox(
                                color: Color(0x99000000),
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      CircularProgressIndicator(),
                                      SizedBox(height: 12),
                                      Text('Fotoğraflar hazırlanıyor…'),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (selectedElement != null)
                _SelectionToolbar(
                  element: selectedElement!,
                  onStyle: _styleSelected,
                  onForward: _bringForward,
                  onDuplicate: _duplicateSelected,
                  onDelete: _removeSelected,
                ),
              _MainToolbar(
                onPhoto: _addPhotos,
                onText: _addText,
                onDraw: _addHandwriting,
                onCard: _addOccasionCard,
                onSticker: _addSticker,
                onBackground: _changeBackground,
                onPage: _addPage,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPageMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                album.bindingType.icon,
                color: Theme.of(context).colorScheme.primary,
              ),
              title: const Text('Ciltleme Tipini Değiştir'),
              subtitle: Text(album.bindingType.title),
              onTap: () {
                Navigator.pop(context);
                _changeBinding();
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy_all_outlined),
              title: const Text('Sayfayı çoğalt'),
              onTap: () {
                Navigator.pop(context);
                _duplicatePage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('Sayfayı sil'),
              textColor: Colors.redAccent,
              iconColor: Colors.redAccent,
              onTap: () {
                Navigator.pop(context);
                _deletePage();
              },
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class _PageNavigator extends StatelessWidget {
  const _PageNavigator({
    required this.current,
    required this.total,
    required this.onPrevious,
    required this.onNext,
    required this.onAdd,
    required this.onMore,
  });

  final int current;
  final int total;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback onAdd;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: onPrevious,
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: colors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(99),
              border: Border.all(color: colors.outlineVariant),
            ),
            child: Text(
              'Sayfa ${current + 1} / $total',
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
            ),
          ),
          IconButton(
            onPressed: onNext,
            icon: const Icon(Icons.chevron_right_rounded),
          ),
          const Spacer(),
          IconButton(
            onPressed: onAdd,
            tooltip: 'Sayfa ekle',
            icon: const Icon(Icons.add_box_outlined),
          ),
          IconButton(
            onPressed: onMore,
            tooltip: 'Sayfa seçenekleri',
            icon: const Icon(Icons.more_horiz_rounded),
          ),
        ],
      ),
    );
  }
}

class _MainToolbar extends StatelessWidget {
  const _MainToolbar({
    required this.onPhoto,
    required this.onText,
    required this.onDraw,
    required this.onCard,
    required this.onSticker,
    required this.onBackground,
    required this.onPage,
  });

  final VoidCallback onPhoto;
  final VoidCallback onText;
  final VoidCallback onDraw;
  final VoidCallback onCard;
  final VoidCallback onSticker;
  final VoidCallback onBackground;
  final VoidCallback onPage;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
      ),
      padding: const EdgeInsets.fromLTRB(6, 8, 6, 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _Tool(
              icon: Icons.add_photo_alternate_outlined,
              label: 'Fotoğraf',
              onTap: onPhoto,
            ),
            _Tool(
              icon: Icons.text_fields_rounded,
              label: 'Yazı / Font',
              onTap: onText,
            ),
            _Tool(
              icon: Icons.gesture_rounded,
              label: 'Elle Yaz',
              onTap: onDraw,
            ),
            _Tool(
              icon: Icons.card_membership_rounded,
              label: 'Özel Kart',
              onTap: onCard,
            ),
            _Tool(
              icon: Icons.auto_awesome_outlined,
              label: 'Süsler',
              onTap: onSticker,
            ),
            _Tool(
              icon: Icons.palette_outlined,
              label: 'Sayfa',
              onTap: onBackground,
            ),
            _Tool(icon: Icons.note_add_outlined, label: 'Yeni', onTap: onPage),
          ],
        ),
      ),
    );
  }
}

class _SelectionToolbar extends StatelessWidget {
  const _SelectionToolbar({
    required this.element,
    required this.onStyle,
    required this.onForward,
    required this.onDuplicate,
    required this.onDelete,
  });

  final AlbumElementModel element;
  final VoidCallback onStyle;
  final VoidCallback onForward;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final (styleLabel, styleIcon) = switch (element.type) {
      AlbumElementType.photo => (
        'Çerçeve · ${albumPhotoFrameLabel(element.frameStyle)}',
        Icons.crop_original_rounded,
      ),
      AlbumElementType.text => (
        'Yazıyı / Fontu Düzenle',
        Icons.font_download_rounded,
      ),
      AlbumElementType.card => (
        'Kart Metnini Düzenle',
        Icons.edit_note_rounded,
      ),
      AlbumElementType.drawing => ('Döndür', Icons.rotate_right_rounded),
      AlbumElementType.sticker => ('Süsü değiştir', Icons.auto_awesome_rounded),
    };
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 0, 18, 8),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Flexible(
            flex: 3,
            child: TextButton.icon(
              onPressed: onStyle,
              icon: Icon(styleIcon, size: 18),
              label: Text(
                styleLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          IconButton(
            onPressed: onForward,
            tooltip: 'Öne al',
            icon: const Icon(Icons.flip_to_front_outlined, size: 20),
          ),
          IconButton(
            onPressed: onDuplicate,
            tooltip: 'Kopyala',
            icon: const Icon(Icons.copy_rounded, size: 20),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
          ),
        ],
      ),
    );
  }
}

class _Tool extends StatelessWidget {
  const _Tool({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 23, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: 3),
            Text(
              label,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaperColorTile extends StatelessWidget {
  const _PaperColorTile({
    required this.name,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SizedBox(
      width: 72,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Column(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 52,
                height: 52,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? colors.primary : colors.outlineVariant,
                    width: selected ? 3 : 1,
                  ),
                  boxShadow: selected
                      ? [
                          BoxShadow(
                            color: colors.primary.withValues(alpha: 0.25),
                            blurRadius: 9,
                          ),
                        ]
                      : null,
                ),
                child: ClipOval(
                  child: CustomPaint(
                    painter: _PaperSamplePainter(color),
                    child: selected
                        ? Icon(
                            Icons.check_rounded,
                            color: color.computeLuminance() > 0.48
                                ? const Color(0xFF46382E)
                                : Colors.white,
                          )
                        : const SizedBox.expand(),
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                name,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? colors.primary : colors.onSurfaceVariant,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 10,
                  height: 1.05,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaperSamplePainter extends CustomPainter {
  const _PaperSamplePainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = color);
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const RadialGradient(
          colors: [Colors.transparent, Color(0x2B65452F)],
          stops: [0.48, 1],
        ).createShader(Offset.zero & size),
    );
    final fleck = Paint()
      ..color = color.computeLuminance() > 0.4
          ? const Color(0x2470553E)
          : const Color(0x22FFFFFF);
    const points = <Offset>[
      Offset(.18, .22),
      Offset(.42, .14),
      Offset(.71, .28),
      Offset(.28, .57),
      Offset(.61, .69),
      Offset(.82, .53),
      Offset(.19, .82),
      Offset(.76, .86),
    ];
    for (final point in points) {
      canvas.drawCircle(
        Offset(point.dx * size.width, point.dy * size.height),
        0.8,
        fleck,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PaperSamplePainter oldDelegate) =>
      oldDelegate.color != color;
}

class _PhotoFramePicker extends StatelessWidget {
  const _PhotoFramePicker({required this.selectedStyle});

  final int selectedStyle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SafeArea(
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.68,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 0, 18, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.filter_frames_outlined,
                        color: colors.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const SizedBox(width: 11),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Fotoğraf Çerçeveleri',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Albümün hikâyesine yakışan bir dokunuş seç',
                          style: TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.builder(
                  padding: const EdgeInsets.only(bottom: 8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.92,
                  ),
                  itemCount: albumPhotoFrameCount,
                  itemBuilder: (context, index) => _FrameChoiceTile(
                    index: index,
                    selected: index == selectedStyle,
                    onTap: () => Navigator.pop(context, index),
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

class _FrameChoiceTile extends StatelessWidget {
  const _FrameChoiceTile({
    required this.index,
    required this.selected,
    required this.onTap,
  });

  final int index;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 170),
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 7),
        decoration: BoxDecoration(
          color: selected
              ? colors.primaryContainer.withValues(alpha: 0.62)
              : colors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? colors.primary : colors.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CustomPaint(painter: _FramePreviewPainter(index)),
                  Center(
                    child: Icon(
                      _frameIcons[index],
                      size: 22,
                      color: const Color(0xFFD9C39C),
                    ),
                  ),
                  if (selected)
                    Align(
                      alignment: Alignment.topRight,
                      child: Icon(
                        Icons.check_circle_rounded,
                        size: 17,
                        color: colors.primary,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 5),
            Text(
              albumPhotoFrameLabel(index),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: selected ? colors.primary : colors.onSurface,
                fontSize: 10,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FramePreviewPainter extends CustomPainter {
  const _FramePreviewPainter(this.style);

  final int style;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      size.width * .18,
      size.height * .08,
      size.width * .64,
      size.height * .82,
    );
    final shadowPath = Path()
      ..addRRect(RRect.fromRectAndRadius(rect, const Radius.circular(3)));
    canvas.drawShadow(shadowPath, const Color(0x55000000), 3, false);

    final outerColor = switch (style) {
      2 || 5 || 7 => const Color(0xFF29231F),
      4 || 8 => const Color(0xFFC5A357),
      9 => const Color(0xFFC59BA3),
      10 => const Color(0xFFE7D8BE),
      _ => const Color(0xFFF1E8D9),
    };
    canvas.drawRRect(
      RRect.fromRectAndRadius(rect, Radius.circular(style == 3 ? 13 : 3)),
      Paint()..color = outerColor,
    );
    final inset = style == 1
        ? const EdgeInsets.fromLTRB(5, 5, 5, 12)
        : style == 9
        ? const EdgeInsets.fromLTRB(7, 7, 7, 9)
        : const EdgeInsets.all(5);
    final inner = Rect.fromLTRB(
      rect.left + inset.left,
      rect.top + inset.top,
      rect.right - inset.right,
      rect.bottom - inset.bottom,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(inner, const Radius.circular(2)),
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6C7A6D), Color(0xFF39474A)],
        ).createShader(inner),
    );

    if (style == 7) {
      final hole = Paint()..color = const Color(0xFFE8DCC8);
      for (var y = rect.top + 5; y < rect.bottom - 2; y += 9) {
        canvas.drawRect(Rect.fromLTWH(rect.left + 1, y, 3, 4), hole);
        canvas.drawRect(Rect.fromLTWH(rect.right - 4, y, 3, 4), hole);
      }
    } else if (style == 11) {
      final tape = Paint()..color = const Color(0xB8D6A8B2);
      canvas.save();
      canvas.translate(rect.left + 2, rect.top + 4);
      canvas.rotate(-0.18);
      canvas.drawRect(const Rect.fromLTWH(0, 0, 25, 7), tape);
      canvas.restore();
    } else if (style == 4 || style == 5) {
      final corner = Paint()
        ..color = style == 4 ? const Color(0xFFE0BF6B) : const Color(0xFF191817)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;
      canvas.drawLine(
        inner.topLeft,
        inner.topLeft + const Offset(10, 0),
        corner,
      );
      canvas.drawLine(
        inner.topLeft,
        inner.topLeft + const Offset(0, 10),
        corner,
      );
      canvas.drawLine(
        inner.bottomRight,
        inner.bottomRight - const Offset(10, 0),
        corner,
      );
      canvas.drawLine(
        inner.bottomRight,
        inner.bottomRight - const Offset(0, 10),
        corner,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _FramePreviewPainter oldDelegate) =>
      oldDelegate.style != style;
}
