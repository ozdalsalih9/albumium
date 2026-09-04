import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../l10n/albumium_localizations.dart';
import '../models/album_models.dart';
import '../services/album_storage.dart';
import '../theme/albumium_app_theme.dart';
import '../widgets/album_page_canvas.dart';
import '../widgets/font_selector_dialog.dart';
import '../widgets/handmade_craft.dart';
import '../widgets/handwriting_painter.dart';
import '../widgets/occasion_cards.dart';
import '../widgets/photo_style_picker.dart';
import '../widgets/photo_crop_editor.dart';
import '../widgets/physical_book_spread.dart';
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

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key, required this.album});

  final AlbumModel album;

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen>
    with SingleTickerProviderStateMixin {
  final _picker = ImagePicker();
  late final AnimationController _pageTurnController;
  int _pageIndex = 0;
  String? _selectedId;
  bool _importing = false;
  Timer? _saveDebounce;
  int? _nextSpreadLeftPageIndex;
  int? _nextSpreadRightPageIndex;
  bool _turningForward = true;

  AlbumModel get album => widget.album;
  AlbumPageModel get page => album.pages[_pageIndex];
  int get _spreadIndex => _pageIndex ~/ 2;
  int get _spreadCount => (album.pages.length + 1) ~/ 2;
  int get _spreadLeftPageIndex => _spreadIndex * 2;
  int get _spreadRightPageIndex {
    final index = _spreadLeftPageIndex + 1;
    return index < album.pages.length
        ? index
        : PhysicalBookSpread.blankPageIndex;
  }

  bool get _isPageTurning => _nextSpreadLeftPageIndex != null;

  bool get _usesFocusedPageLayout {
    final size = MediaQuery.sizeOf(context);
    // Dar tablet portresinde iki sayfayı yan yana sıkıştırmak yerine düzenlenen
    // sayfayı öne çıkar. Yatay tablette yeterli genişlik olduğunda gerçek
    // iki-sayfa görünümü korunur.
    return size.shortestSide < 600 || size.width < 720;
  }

  bool get _canGoPrevious {
    if (_isPageTurning) return false;
    if (_usesFocusedPageLayout && _pageIndex.isOdd) return true;
    return _spreadIndex > 0;
  }

  bool get _canGoNext {
    if (_isPageTurning) return false;
    if (_usesFocusedPageLayout &&
        _pageIndex.isEven &&
        _spreadRightPageIndex >= 0) {
      return true;
    }
    return _spreadIndex < _spreadCount - 1;
  }

  String get _spreadLabel {
    final left = _spreadLeftPageIndex + 1;
    final rightIndex = _spreadRightPageIndex;
    return rightIndex >= 0
        ? context.tr(
            'Sayfalar {first}–{last} / {total}',
            values: {
              'first': left,
              'last': rightIndex + 1,
              'total': album.pages.length,
            },
          )
        : context.tr(
            'Sayfa {page} / {total}',
            values: {'page': left, 'total': album.pages.length},
          );
  }

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
    if (isAlbumStickerAsset(sticker)) {
      if (sticker.contains('botanical_')) return const Size(0.28, 0.37);
      if (sticker.contains('romance_')) return const Size(0.34, 0.28);
      return const Size(0.32, 0.3);
    }
    Size proportional(double height, {double maxWidth = .64}) {
      final pixelAspect = albumStickerAspectRatio(sticker);
      // Page-relative coordinates live on a 9:14 canvas. Convert the desired
      // pixel aspect back to normalized width/height before storing it.
      var width = height * pixelAspect * (14 / 9);
      if (width > maxWidth) {
        height *= maxWidth / width;
        width = maxWidth;
      }
      return Size(width, height);
    }

    if (isAlbumShape(sticker)) return proportional(.2, maxWidth: .38);
    if (sticker.contains('washi_') ||
        sticker.endsWith(':film_strip') ||
        sticker.contains('ribbon_') ||
        sticker.endsWith(':vintage_ticket')) {
      return proportional(.105);
    }
    if (sticker.contains('pressed_') ||
        sticker.endsWith(':fern') ||
        sticker.endsWith(':gold_branch')) {
      return proportional(.28, maxWidth: .42);
    }
    if (sticker.contains('postage_')) return proportional(.19);
    if (sticker.contains('cat_') || sticker.contains('monkey_')) {
      return proportional(.25, maxWidth: .42);
    }
    if (sticker.contains('words_') ||
        sticker.endsWith('fabric_lace') ||
        sticker.endsWith('analog_negative')) {
      return proportional(.105);
    }
    return proportional(.18, maxWidth: .42);
  }

  double _stickerRotation(String sticker) {
    if (isAlbumShape(sticker)) return 0;
    if (isAlbumStickerAsset(sticker)) return -0.025;
    if (sticker.contains('washi_')) return -0.055;
    if (sticker.contains('postage_')) return 0.07;
    if (sticker.endsWith(':vintage_ticket')) return -0.04;
    return 0.025;
  }

  @override
  void initState() {
    super.initState();
    _pageTurnController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 780),
    );
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    _pageTurnController.dispose();
    unawaited(AlbumStorage.instance.saveAlbum(album));
    super.dispose();
  }

  void _changed() {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(const Duration(milliseconds: 450), () {
      unawaited(AlbumStorage.instance.saveAlbum(album));
    });
  }

  void _canvasChanged() {
    if (!mounted) return;
    setState(() {});
    _changed();
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
    final sizes = <Size>[];
    try {
      for (final file in picked) {
        final path = await AlbumStorage.instance.importImage(file);
        final info = await loadAlbumPhoto(path);
        sizes.add(albumPhotoSize(info.image.width / info.image.height));
        info.dispose();
        paths.add(path);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.tr('Fotoğraf açılamadı. Lütfen tekrar dene.'),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _importing = false);
    }
    if (!mounted || paths.isEmpty) return;
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
            x: (1 - sizes[index].width) / 2,
            y: (1 - sizes[index].height) / 2,
            width: sizes[index].width,
            height: sizes[index].height,
            photoCrop: fullPhotoCrop,
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

  Future<void> _addShape() async {
    final shape = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => const ShapeObjectPickerSheet(),
    );
    if (shape == null || !mounted) return;
    final size = _stickerSize(shape);
    setState(() {
      final element = AlbumElementModel(
        id: newId(),
        type: AlbumElementType.sticker,
        content: shape,
        x: 0.5 - size.width / 2,
        y: 0.28,
        width: size.width,
        height: size.height,
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

  void _selectPage(int index) {
    if (_isPageTurning) return;
    if (index < 0 || index >= album.pages.length) return;
    setState(() {
      _pageIndex = index;
      _selectedId = null;
    });
  }

  void _goToPreviousPage() {
    if (!_canGoPrevious) return;
    if (_usesFocusedPageLayout && _pageIndex.isOdd) {
      _selectPage(_pageIndex - 1);
      return;
    }
    unawaited(_turnSpread(forward: false));
  }

  void _goToNextPage() {
    if (!_canGoNext) return;
    if (_usesFocusedPageLayout &&
        _pageIndex.isEven &&
        _spreadRightPageIndex >= 0) {
      _selectPage(_spreadRightPageIndex);
      return;
    }
    unawaited(_turnSpread(forward: true));
  }

  Future<void> _turnSpread({required bool forward}) async {
    if (_isPageTurning || _pageTurnController.isAnimating) return;
    final targetSpread = _spreadIndex + (forward ? 1 : -1);
    if (targetSpread < 0 || targetSpread >= _spreadCount) return;

    final nextLeft = targetSpread * 2;
    final candidateRight = nextLeft + 1;
    final nextRight = candidateRight < album.pages.length
        ? candidateRight
        : PhysicalBookSpread.blankPageIndex;
    final targetPage = _usesFocusedPageLayout && !forward && nextRight >= 0
        ? nextRight
        : nextLeft;

    setState(() {
      _turningForward = forward;
      _nextSpreadLeftPageIndex = nextLeft;
      _nextSpreadRightPageIndex = nextRight;
      _selectedId = null;
    });

    await _pageTurnController.animateTo(
      1,
      duration: _pageTurnController.duration,
      curve: Curves.easeInOutCubic,
    );
    if (!mounted) return;
    setState(() {
      _pageIndex = targetPage;
      _nextSpreadLeftPageIndex = null;
      _nextSpreadRightPageIndex = null;
    });
    _pageTurnController.value = 0;
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
              photoShape: e.photoShape,
              photoCrop: e.photoCrop,
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
        SnackBar(content: Text(context.tr('Albümde en az bir sayfa kalmalı.'))),
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
      isScrollControlled: true,
      builder: (context) => SafeArea(
        child: FractionallySizedBox(
          heightFactor: MediaQuery.sizeOf(context).height < 700 ? .88 : .72,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.tr('Albüm Ciltleme Tipi'),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView(
                    key: const ValueKey('binding-options-list'),
                    padding: EdgeInsets.zero,
                    children: [
                      for (final binding in AlbumBindingType.values)
                        ListTile(
                          leading: Icon(
                            binding.icon,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          title: Text(
                            context.tr(binding.title),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(context.tr(binding.description)),
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _changeBackground() {
    final theme = themeById(album.themeId);
    final seenColors = <int>{};
    final colors = <({String name, Color color})>[
      (name: context.tr('Temaya özel'), color: theme.pageColor),
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
              Row(
                children: [
                  const Icon(Icons.texture_rounded, size: 23),
                  const SizedBox(width: 10),
                  Text(
                    context.tr('Vintage kâğıt seç'),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Text(
                context.tr(
                  'Her renk ince lif, tanecik ve kenar patinasıyla uygulanır.',
                ),
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
                      name: context.tr(choice.name),
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

  bool _canMoveSelectedLayer(AlbumElementLayerAction action) {
    final selected = selectedElement;
    return selected != null &&
        canMoveAlbumElementLayer(page.elements, selected.id, action);
  }

  void _moveSelectedLayer(AlbumElementLayerAction action) {
    final selected = selectedElement;
    if (selected == null) return;
    var changed = false;
    setState(() {
      changed = moveAlbumElementLayer(page.elements, selected.id, action);
    });
    if (!changed) return;
    _changed();
  }

  void _scaleSelected(double factor) {
    final selected = selectedElement;
    if (selected == null) return;
    var changed = false;
    setState(() => changed = scaleAlbumElementBy(selected, factor));
    if (!changed) return;
    _changed();
  }

  void _resetSelectedTransform() {
    final selected = selectedElement;
    if (selected == null) return;
    var changed = false;
    setState(() => changed = resetAlbumElementTransform(selected));
    if (!changed) return;
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
        photoShape: selected.photoShape,
        photoCrop: selected.photoCrop,
        textColor: selected.textColor,
        fontSize: selected.fontSize,
        extraData: selected.extraData,
      );
      page.elements.add(copy);
      _selectedId = copy.id;
    });
    _changed();
  }

  Future<void> _cropSelected() async {
    final element = selectedElement;
    if (element == null || element.type != AlbumElementType.photo) return;
    if (await editAlbumPhotoCrop(context, element) && mounted) {
      setState(() {});
      _changed();
    }
  }

  Future<void> _styleSelected() async {
    final selected = selectedElement;
    if (selected == null) return;

    if (selected.type == AlbumElementType.photo) {
      final style = await showAlbumPhotoStylePicker(
        context,
        selectedFrameStyle: selected.frameStyle,
        selectedShape: selected.photoShape,
      );
      if (style == null || !mounted) return;
      setState(() {
        selected.frameStyle = style.frameStyle;
        applyAlbumPhotoShape(selected, style.shape);
      });
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
        title: Text(context.tr('Albüm adını değiştir')),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('Vazgeç')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: Text(context.tr('Kaydet')),
          ),
        ],
      ),
    );
    controller.dispose();
    if (title == null || title.isEmpty || !mounted) return;
    setState(() => album.title = title);
    _changed();
  }

  Future<void> _preview({bool openShareOptions = false}) async {
    _saveDebounce?.cancel();
    await AlbumStorage.instance.saveAlbum(album);
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            PreviewScreen(album: album, openShareOnReady: openShareOptions),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AlbumiumAppTheme.colorsOf(context);
    return PopScope(
      onPopInvokedWithResult: (_, _) =>
          unawaited(AlbumStorage.instance.saveAlbum(album)),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: colors.background,
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
              tooltip: context.tr(
                'Cilt Tipi ({binding})',
                values: {'binding': context.tr(album.bindingType.title)},
              ),
            ),
            IconButton(
              onPressed: () => _preview(),
              icon: const Icon(Icons.menu_book_rounded),
              tooltip: context.tr('Kitap Aç'),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilledButton.icon(
                key: const ValueKey('editor-share'),
                onPressed: () => _preview(openShareOptions: true),
                icon: const Icon(Icons.ios_share_rounded, size: 18),
                label: Text(context.tr('Paylaş')),
              ),
            ),
          ],
        ),
        body: CraftBackdrop(
          variant: CraftBackdropVariant.studio,
          baseColor: colors.background,
          textureIntensity: .64,
          child: SafeArea(
            child: Column(
              children: [
                _PageNavigator(
                  label: _spreadLabel,
                  onPrevious: _canGoPrevious ? _goToPreviousPage : null,
                  onNext: _canGoNext ? _goToNextPage : null,
                  onAdd: _addPage,
                  onMore: () => _showPageMenu(context),
                ),
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 4, 8, 10),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final focusedPageLayout = _usesFocusedPageLayout;
                          return Stack(
                            children: [
                              Positioned.fill(
                                child: AnimatedBuilder(
                                  animation: _pageTurnController,
                                  builder: (context, _) => IgnorePointer(
                                    ignoring: _isPageTurning,
                                    child: PhysicalBookSpread(
                                      album: album,
                                      leftPageIndex: _spreadLeftPageIndex,
                                      rightPageIndex: _spreadRightPageIndex,
                                      nextLeftPageIndex:
                                          _nextSpreadLeftPageIndex,
                                      nextRightPageIndex:
                                          _nextSpreadRightPageIndex,
                                      turnProgress: _pageTurnController.value,
                                      turningForward: _turningForward,
                                      interactive: true,
                                      focusedPageIndex: focusedPageLayout
                                          ? _pageIndex
                                          : null,
                                      activePageIndex: _pageIndex,
                                      selectedElementId: _selectedId,
                                      onSelectPage: _selectPage,
                                      onSelectElement: (id) =>
                                          setState(() => _selectedId = id),
                                      onChanged: _canvasChanged,
                                    ),
                                  ),
                                ),
                              ),
                              if (_importing)
                                Positioned.fill(
                                  child: ColoredBox(
                                    color: const Color(0x99000000),
                                    child: Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const CircularProgressIndicator(),
                                          const SizedBox(height: 12),
                                          Text(
                                            context.tr(
                                              'Fotoğraflar hazırlanıyor…',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
                if (selectedElement != null)
                  _SelectionToolbar(
                    element: selectedElement!,
                    onStyle: _styleSelected,
                    onCrop: _cropSelected,
                    canMoveLayer: _canMoveSelectedLayer,
                    onLayerAction: _moveSelectedLayer,
                    onScaleDown:
                        selectedElement!.scale > albumElementMinScale + .000001
                        ? () => _scaleSelected(1 / albumElementScaleStep)
                        : null,
                    onScaleUp:
                        selectedElement!.scale < albumElementMaxScale - .000001
                        ? () => _scaleSelected(albumElementScaleStep)
                        : null,
                    onResetTransform:
                        (selectedElement!.scale - 1).abs() > .000001 ||
                            selectedElement!.rotation.abs() > .000001
                        ? _resetSelectedTransform
                        : null,
                    onDuplicate: _duplicateSelected,
                    onDelete: _removeSelected,
                  ),
                _MainToolbar(
                  onPhoto: _addPhotos,
                  onText: _addText,
                  onDraw: _addHandwriting,
                  onCard: _addOccasionCard,
                  onSticker: _addSticker,
                  onShape: _addShape,
                  onBackground: _changeBackground,
                  onPage: _addPage,
                ),
              ],
            ),
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
              title: Text(context.tr('Ciltleme Tipini Değiştir')),
              subtitle: Text(context.tr(album.bindingType.title)),
              onTap: () {
                Navigator.pop(context);
                _changeBinding();
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy_all_outlined),
              title: Text(context.tr('Sayfayı çoğalt')),
              onTap: () {
                Navigator.pop(context);
                _duplicatePage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: Text(context.tr('Sayfayı sil')),
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
    required this.label,
    required this.onPrevious,
    required this.onNext,
    required this.onAdd,
    required this.onMore,
  });

  final String label;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;
  final VoidCallback onAdd;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    final colors = AlbumiumAppTheme.colorsOf(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 7, 12, 5),
      child: PaperPanel(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        borderRadius: BorderRadius.circular(7),
        rotationDegrees: -.15,
        textureIntensity: .2,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              onPressed: onPrevious,
              tooltip: context.tr('Önceki sayfa'),
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            TornPaperLabel(
              color: colors.elevatedSurface,
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
              edgeDepth: 2,
              child: Text(
                label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: colors.text,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            IconButton(
              onPressed: onNext,
              tooltip: context.tr('Sonraki sayfa'),
              icon: const Icon(Icons.chevron_right_rounded),
            ),
            const Spacer(),
            IconButton(
              onPressed: onAdd,
              tooltip: context.tr('Sayfa ekle'),
              color: colors.primary,
              icon: const Icon(Icons.add_box_outlined),
            ),
            IconButton(
              onPressed: onMore,
              tooltip: context.tr('Sayfa seçenekleri'),
              icon: const Icon(Icons.more_horiz_rounded),
            ),
          ],
        ),
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
    required this.onShape,
    required this.onBackground,
    required this.onPage,
  });

  final VoidCallback onPhoto;
  final VoidCallback onText;
  final VoidCallback onDraw;
  final VoidCallback onCard;
  final VoidCallback onSticker;
  final VoidCallback onShape;
  final VoidCallback onBackground;
  final VoidCallback onPage;

  @override
  Widget build(BuildContext context) {
    final colors = AlbumiumAppTheme.colorsOf(context);
    return PaperPanel(
      color: colors.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
      padding: const EdgeInsets.fromLTRB(6, 8, 6, 10),
      textureIntensity: .24,
      showShadow: true,
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _Tool(
                  icon: Icons.add_photo_alternate_outlined,
                  label: context.tr('Fotoğraf'),
                  onTap: onPhoto,
                ),
                _Tool(
                  icon: Icons.text_fields_rounded,
                  label: context.tr('Yazı / Font'),
                  onTap: onText,
                ),
                _Tool(
                  icon: Icons.gesture_rounded,
                  label: context.tr('Elle Yaz'),
                  onTap: onDraw,
                ),
                _Tool(
                  icon: Icons.card_membership_rounded,
                  label: context.tr('Özel Kart'),
                  onTap: onCard,
                ),
                _Tool(
                  icon: Icons.auto_awesome_outlined,
                  label: context.tr('Süsler'),
                  onTap: onSticker,
                ),
                _Tool(
                  icon: Icons.interests_outlined,
                  label: context.tr('Şekiller'),
                  onTap: onShape,
                ),
                _Tool(
                  icon: Icons.palette_outlined,
                  label: context.tr('Sayfa'),
                  onTap: onBackground,
                ),
                _Tool(
                  icon: Icons.note_add_outlined,
                  label: context.tr('Yeni'),
                  onTap: onPage,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectionToolbar extends StatelessWidget {
  const _SelectionToolbar({
    required this.element,
    required this.onStyle,
    required this.onCrop,
    required this.canMoveLayer,
    required this.onLayerAction,
    required this.onScaleDown,
    required this.onScaleUp,
    required this.onResetTransform,
    required this.onDuplicate,
    required this.onDelete,
  });

  final AlbumElementModel element;
  final VoidCallback onStyle;
  final VoidCallback onCrop;
  final bool Function(AlbumElementLayerAction action) canMoveLayer;
  final ValueChanged<AlbumElementLayerAction> onLayerAction;
  final VoidCallback? onScaleDown;
  final VoidCallback? onScaleUp;
  final VoidCallback? onResetTransform;
  final VoidCallback onDuplicate;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = AlbumiumAppTheme.colorsOf(context);
    final (styleLabel, styleIcon) = switch (element.type) {
      AlbumElementType.photo => (
        '${context.tr(albumPhotoShapeLabel(element.photoShape))} · ${context.tr(albumPhotoFrameLabel(element.frameStyle))}',
        Icons.crop_original_rounded,
      ),
      AlbumElementType.text => (
        context.tr('Yazıyı / Fontu Düzenle'),
        Icons.font_download_rounded,
      ),
      AlbumElementType.card => (
        context.tr('Kart Metnini Düzenle'),
        Icons.edit_note_rounded,
      ),
      AlbumElementType.drawing => (
        context.tr('Döndür'),
        Icons.rotate_right_rounded,
      ),
      AlbumElementType.sticker => (
        context.tr('Süsü değiştir'),
        Icons.auto_awesome_rounded,
      ),
    };

    Widget styleButton() => TextButton.icon(
      onPressed: onStyle,
      icon: Icon(styleIcon, size: 18),
      label: Text(styleLabel, maxLines: 1, overflow: TextOverflow.ellipsis),
    );

    Widget scaleBadge() => Semantics(
      label: context.tr(
        'Öğe ölçeği yüzde {percent}',
        values: {'percent': (element.scale * 100).round()},
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: colors.border),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Text(
            '${(element.scale * 100).round()}%',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );

    Widget actionButtons() => Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (element.type == AlbumElementType.photo)
          _SelectionIconButton(
            onPressed: onCrop,
            tooltip: context.tr('Fotoğrafı kırp'),
            icon: Icons.crop_rounded,
          ),
        _SelectionIconButton(
          onPressed: onScaleDown,
          tooltip: context.tr('Küçült'),
          icon: Icons.zoom_out_rounded,
        ),
        _SelectionIconButton(
          onPressed: onScaleUp,
          tooltip: context.tr('Büyüt'),
          icon: Icons.zoom_in_rounded,
        ),
        _SelectionIconButton(
          onPressed: onResetTransform,
          tooltip: context.tr('Dönüş ve ölçeği sıfırla'),
          icon: Icons.restart_alt_rounded,
        ),
        SizedBox(
          width: 42,
          height: 42,
          child: PopupMenuButton<AlbumElementLayerAction>(
            key: const ValueKey('selection-layer-menu'),
            tooltip: context.tr('Katman sırası'),
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.layers_outlined, size: 20),
            onSelected: onLayerAction,
            itemBuilder: (context) => [
              for (final action in AlbumElementLayerAction.values)
                PopupMenuItem<AlbumElementLayerAction>(
                  key: ValueKey('layer-action-${action.name}'),
                  value: action,
                  enabled: canMoveLayer(action),
                  child: Row(
                    children: [
                      Icon(_layerActionIcon(action), size: 20),
                      const SizedBox(width: 12),
                      Text(context.tr(_layerActionLabel(action))),
                    ],
                  ),
                ),
            ],
          ),
        ),
        _SelectionIconButton(
          onPressed: onDuplicate,
          tooltip: context.tr('Kopyala'),
          icon: Icons.copy_rounded,
        ),
        _SelectionIconButton(
          onPressed: onDelete,
          tooltip: context.tr('Sil'),
          icon: Icons.delete_outline,
          color: Colors.redAccent,
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
      child: PaperPanel(
        color: colors.elevatedSurface,
        padding: const EdgeInsets.fromLTRB(8, 3, 8, 5),
        borderRadius: BorderRadius.circular(7),
        rotationDegrees: .2,
        textureIntensity: .2,
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth >= 680) {
              return Row(
                key: const ValueKey('selection-toolbar-wide'),
                children: [
                  Expanded(child: styleButton()),
                  scaleBadge(),
                  const SizedBox(width: 6),
                  actionButtons(),
                ],
              );
            }
            return Column(
              key: const ValueKey('selection-toolbar-stacked'),
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(child: styleButton()),
                    scaleBadge(),
                  ],
                ),
                Align(
                  alignment: Alignment.center,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: actionButtons(),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

String _layerActionLabel(AlbumElementLayerAction action) => switch (action) {
  AlbumElementLayerAction.moveDown => 'Bir alta gönder',
  AlbumElementLayerAction.moveUp => 'Bir üste getir',
  AlbumElementLayerAction.sendToBack => 'En alta gönder',
  AlbumElementLayerAction.bringToFront => 'En üste getir',
};

IconData _layerActionIcon(AlbumElementLayerAction action) => switch (action) {
  AlbumElementLayerAction.moveDown => Icons.arrow_downward_rounded,
  AlbumElementLayerAction.moveUp => Icons.arrow_upward_rounded,
  AlbumElementLayerAction.sendToBack => Icons.vertical_align_bottom_rounded,
  AlbumElementLayerAction.bringToFront => Icons.vertical_align_top_rounded,
};

class _SelectionIconButton extends StatelessWidget {
  const _SelectionIconButton({
    required this.onPressed,
    required this.tooltip,
    required this.icon,
    this.color,
  });

  final VoidCallback? onPressed;
  final String tooltip;
  final IconData icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 42,
      height: 42,
      child: IconButton(
        onPressed: onPressed,
        tooltip: tooltip,
        padding: EdgeInsets.zero,
        visualDensity: VisualDensity.compact,
        icon: Icon(icon, size: 20, color: color),
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
    final colors = AlbumiumAppTheme.colorsOf(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: StitchedBorder(
        color: colors.border,
        borderRadius: BorderRadius.circular(8),
        inset: 2,
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 23, color: colors.primary),
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
