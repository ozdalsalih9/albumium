import '../models/scrapbook_templates.dart';
import '../services/platform_album_services.dart';
import 'personal_stickers_screen.dart';
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import '../widgets/responsive_controls.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/photo_selection_service.dart';
import '../services/card_template_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/albumium_localizations.dart';
import '../models/album_models.dart';
import '../models/card_design_history.dart';
import '../widgets/card_color_picker.dart';
import '../widgets/card_template_thumbnail.dart';
import '../services/album_storage.dart';
import '../services/personal_sticker_storage.dart';
import '../theme/albumium_app_theme.dart';
import '../widgets/album_page_canvas.dart';
import '../widgets/export_delivery.dart';
import '../widgets/feature_unlock_sheet.dart';
import '../services/monetization_policy.dart';
import '../widgets/element_edit_panel.dart';
import '../widgets/font_selector_dialog.dart';
import '../widgets/handmade_craft.dart';
import '../widgets/handwriting_painter.dart';
import '../widgets/occasion_cards.dart';
import '../widgets/photo_style_picker.dart';
import '../widgets/photo_slot_picker.dart';
import '../services/photo_slot_service.dart';
import '../widgets/photo_crop_editor.dart';
import '../widgets/sticker_packs.dart';

const _cardRoleBadge = 'card-badge-';
const _cardRoleTitle = 'card-title-';
const _cardRoleMessage = 'card-message-';
const _cardStudioSidePanelBreakpoint = 900.0;
const _cardStudioSidePanelWidth = 360.0;

AlbumModel createSpecialCardProject({
  OccasionCardTemplate? template,
  String Function(String text)? translate,
}) {
  final selected = template ?? occasionCardTemplates.first;
  final localize = translate ?? (text) => text;
  final now = DateTime.now();
  return AlbumModel(
    id: newId(),
    title: _defaultCardTitle(selected, localize),
    themeId: 'soft_romance',
    projectType: AlbumProjectType.occasionCard,
    cardThemeId: selected.id,
    createdAt: now,
    updatedAt: now,
    pages: [
      AlbumPageModel(
        id: newId(),
        backgroundColor: selected.primaryColor.toARGB32(),
        paperPattern: scrapbookTemplateById(selected.id)?.pattern ?? 'plain',
        elements: _defaultCardElements(selected, localize),
      ),
    ],
  );
}

String _defaultCardTitle(
  OccasionCardTemplate template,
  String Function(String text) localize,
) => '${localize(template.title)} ${localize('Kartı')}';

List<AlbumElementModel> _defaultCardElements(
  OccasionCardTemplate template,
  String Function(String text) localize,
) {
  if (template.layout == 'blank') return [];
  final scrapbook = scrapbookTemplateById(template.id);
  if (scrapbook != null) {
    return createScrapbookPage(scrapbook, translate: localize).elements;
  }
  final layout = template.layout;
  final photo = ['photo', 'gallery'].contains(layout);
  final left = [
    'letterpress',
    'postcard',
    'editorial',
    'herbarium',
  ].contains(layout);
  final dark = template.primaryColor.computeLuminance() < .2;
  final titleY = switch (layout) {
    'photo' => .63,
    'gallery' => .66,
    'letterpress' => .27,
    'postcard' => .33,
    'herbarium' => .32,
    'coastal' => .30,
    'editorial' => .22,
    'ribbon' => .40,
    _ => .31,
  };
  final messageY = photo
      ? .84
      : layout == 'ribbon'
      ? .68
      : layout == 'cutout'
      ? .62
      : .58;
  return [
    if (photo) _cardPhotoSlot(template),
    AlbumElementModel(
      id: '$_cardRoleBadge${newId()}',
      type: AlbumElementType.text,
      content: localize(template.badge),
      extraData: 'Inter',
      x: .12,
      y: photo
          ? .035
          : layout == 'ribbon'
          ? .33
          : ['geometric', 'arch', 'celestial'].contains(layout)
          ? .24
          : .16,
      width: .76,
      height: .06,
      fontSize: 10,
      textAlign: left ? TextAlign.left : TextAlign.center,
      textColor: template.accentColor.toARGB32(),
    ),
    AlbumElementModel(
      id: '$_cardRoleTitle${newId()}',
      type: AlbumElementType.text,
      content: localize(template.title),
      extraData: template.fontFamily,
      x: .11,
      y: titleY,
      width: layout == 'herbarium' ? .67 : .78,
      height: photo ? .17 : .24,
      fontSize: ['letterpress', 'editorial'].contains(layout) ? 35 : 36,
      textAlign: left ? TextAlign.left : TextAlign.center,
      textColor: template.accentColor.toARGB32(),
    ),
    AlbumElementModel(
      id: '$_cardRoleMessage${newId()}',
      type: AlbumElementType.text,
      content: localize(template.subtitle),
      extraData: 'Inter',
      x: .12,
      y: messageY,
      width: layout == 'herbarium' ? .61 : .76,
      height: photo ? .08 : .13,
      fontSize: 14,
      textAlign: left ? TextAlign.left : TextAlign.center,
      textColor: (dark ? const Color(0xFFD7D5CD) : const Color(0xFF645E55))
          .toARGB32(),
    ),
  ];
}

AlbumElementModel _cardPhotoSlot(OccasionCardTemplate template) =>
    AlbumElementModel(
      id: 'card-photo-${newId()}',
      type: AlbumElementType.photo,
      content: '',
      photoSlot: true,
      photoFit: BoxFit.contain,
      x: template.layout == 'gallery' ? .168 : .172,
      y: template.layout == 'gallery' ? .144 : .216,
      width: template.layout == 'gallery' ? .664 : .656,
      height: template.layout == 'gallery' ? .397 : .323,
      rotation: template.layout == 'gallery' ? -.035 : -.04,
    );

AlbumThemePreset specialCardThemeFor(
  OccasionCardTemplate template, {
  bool artworkVisible = true,
}) => AlbumThemePreset(
  id: 'special_card_${artworkVisible ? template.id : 'blank'}',
  name: template.title,
  subtitle: template.subtitle,
  emoji: template.emoji,
  coverStart: template.secondaryColor,
  coverEnd: template.accentColor,
  pageColor: template.primaryColor,
  accent: template.accentColor,
  textureLabel: 'Kart kâğıdı',
);

class SpecialCardStudioScreen extends StatefulWidget {
  const SpecialCardStudioScreen({super.key, required this.project});

  final AlbumModel project;

  @override
  State<SpecialCardStudioScreen> createState() =>
      _SpecialCardStudioScreenState();
}

class _SpecialCardStudioScreenState extends State<SpecialCardStudioScreen> {
  final _captureKey = GlobalKey();
  Timer? _saveDebounce;
  String? _selectedId;
  bool _sharing = false;
  late final CardDesignHistory _history;

  AlbumModel get project => widget.project;
  AlbumPageModel get page => project.pages.first;
  OccasionCardTemplate get template =>
      occasionTemplateById(project.cardThemeId);

  AlbumThemePreset get cardTheme =>
      specialCardThemeFor(template, artworkVisible: project.cardArtworkVisible);

  AlbumElementModel? get selectedElement {
    if (_selectedId == null) return null;
    for (final element in page.elements) {
      if (element.id == _selectedId) return element;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    if (project.pages.isEmpty) {
      project.pages.add(
        AlbumPageModel(
          id: newId(),
          backgroundColor: template.primaryColor.toARGB32(),
          paperPattern: scrapbookTemplateById(template.id)?.pattern ?? 'plain',
          elements: _defaultCardElements(template, (text) => text),
        ),
      );
    }
    if (['photo', 'gallery'].contains(template.layout) &&
        !page.elements.any((e) => e.photoSlot)) {
      final photos = page.elements.where(
        (e) => e.type == AlbumElementType.photo,
      );
      if (photos.isEmpty) {
        page.elements.insert(0, _cardPhotoSlot(template));
      } else {
        photos.first.photoSlot = true;
      }
    }
    recoverPhotoGridGroups(page);
    _history = CardDesignHistory(project);
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    unawaited(AlbumStorage.instance.saveAlbum(project));
    super.dispose();
  }

  void _changed({bool record = true}) {
    if (record) _history.record(project);
    if (mounted) setState(() {});
    _saveDebounce?.cancel();
    _saveDebounce = Timer(
      const Duration(milliseconds: 420),
      () => unawaited(AlbumStorage.instance.saveAlbum(project)),
    );
  }

  void _selectTemplate(OccasionCardTemplate next) {
    final previous = template;
    if (previous.id == next.id) return;
    final scrapbook = scrapbookTemplateById(next.id);
    if (scrapbook != null) {
      final previousCopy =
          [
                ..._defaultCardElements(previous, (text) => text),
                ..._defaultCardElements(previous, context.tr),
              ]
              .where((e) => e.type == AlbumElementType.text)
              .map((e) => e.content)
              .toSet();
      setState(() {
        applyScrapbookToPage(
          page,
          scrapbook,
          translate: context.tr,
          replaceableTextIds: page.elements
              .where(
                (e) =>
                    e.type == AlbumElementType.text &&
                    (e.id.startsWith('scrap-text-') ||
                        e.id.startsWith('card-')) &&
                    previousCopy.contains(e.content),
              )
              .map((e) => e.id)
              .toSet(),
        );
        if (project.title == _defaultCardTitle(previous, (text) => text) ||
            project.title == _defaultCardTitle(previous, context.tr)) {
          project.title = _defaultCardTitle(next, context.tr);
        }
        project.cardThemeId = next.id;
        project.cardArtworkVisible = true;
        _selectedId = null;
      });
      _changed();
      return;
    }
    // Cards are created with untranslated copy and may be viewed in another
    // language later, so a default can be in either form.
    String raw(String text) => text;
    final previousDefaults = [
      ..._defaultCardElements(previous, raw),
      ..._defaultCardElements(previous, context.tr),
    ];
    bool untouched(String role, String content) => previousDefaults.any(
      (element) => element.id.startsWith(role) && element.content == content,
    );
    setState(() {
      if (previous.layout == 'scrapbook') {
        page.paperPattern = 'plain';
        page.elements.removeWhere(
          (e) => e.id.startsWith('scrap-decor-') && !e.locked,
        );
      }
      project.cardThemeId = next.id;
      project.cardArtworkVisible = true;
      page.backgroundColor = next.primaryColor.toARGB32();
      // Wording the user typed survives a theme change; copy that still
      // matches the previous template is replaced with the new template's.
      if (project.title == _defaultCardTitle(previous, raw) ||
          project.title == _defaultCardTitle(previous, context.tr)) {
        project.title = _defaultCardTitle(next, context.tr);
      }
      final defaults = _defaultCardElements(next, context.tr);
      for (final role in [_cardRoleBadge, _cardRoleTitle, _cardRoleMessage]) {
        final desired = defaults.where(
          (element) => element.id.startsWith(role),
        );
        if (desired.isEmpty) continue;
        final existing = page.elements.where(
          (element) => element.id.startsWith(role),
        );
        if (existing.isEmpty) {
          page.elements.add(desired.first);
        } else {
          final layout = desired.first;
          if (untouched(role, existing.first.content)) {
            existing.first.content = layout.content;
          }
          existing.first
            ..x = layout.x
            ..y = layout.y
            ..width = layout.width
            ..height = layout.height
            ..fontSize = layout.fontSize
            ..extraData = layout.extraData
            ..textAlign = layout.textAlign
            ..textColor = layout.textColor;
        }
      }
      if (['photo', 'gallery'].contains(next.layout) &&
          !page.elements.any((e) => e.photoSlot)) {
        page.elements.add(_cardPhotoSlot(next));
      }
      _selectedId = null;
    });
    _changed();
  }

  Future<void> _renameProject() async {
    final controller = TextEditingController(text: project.title);
    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('Kartın adı')),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            hintText: context.tr('Örn. Annemin Doğum Günü'),
          ),
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
    if (value == null || value.isEmpty || !mounted) return;
    setState(() => project.title = value);
    _changed();
  }

  Future<void> _addPhotoSlots() async {
    final preset = await showPhotoSlotPicker(context);
    if (preset == null || !mounted) return;
    setState(() {
      page.elements.addAll(preset.create());
      _selectedId = null;
    });
    _changed();
  }

  Future<void> _fillPhotoSlot(String id) async {
    final slots = page.elements.where((e) => e.id == id && e.photoSlot);
    if (slots.isEmpty) return;
    final slot = slots.first;
    if (await pickPhotoIntoSlot(context, slot) &&
        mounted &&
        page.elements.contains(slot)) {
      setState(() => _selectedId = id);
      _changed();
    }
  }

  void _clearPhotoSlot() {
    final slot = selectedElement;
    if (slot == null || !slot.photoSlot || slot.locked) return;
    setState(() {
      slot.content = '';
      slot.photoCrop = null;
    });
    _changed();
  }

  Future<void> _addPhoto() async {
    final photos = await PhotoSelectionService.pick(context, multiple: true);
    if (photos.isEmpty || !mounted) return;
    for (final picked in photos) {
      String path;
      Size size;
      try {
        path = await AlbumStorage.instance.importImage(picked);
        final info = await loadAlbumPhoto(path);
        size = albumPhotoSize(
          info.image.width / info.image.height,
          maxWidth: .64,
        );
        info.dispose();
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
        continue;
      }
      if (!mounted) return;
      final empty = page.elements.where(
        (e) => e.photoSlot && e.content.isEmpty && !e.locked,
      );
      if (empty.isNotEmpty) {
        final slot = empty.first;
        setState(() {
          slot.content = path;
          slot.photoCrop = null;
          _selectedId = slot.id;
        });
        _changed();
        continue;
      }
      setState(() {
        final element = AlbumElementModel(
          id: newId(),
          type: AlbumElementType.photo,
          content: path,
          x: template.layout == 'gallery'
              ? .168
              : template.layout == 'photo'
              ? .172
              : (1 - size.width) / 2,
          y: template.layout == 'gallery'
              ? .144
              : template.layout == 'photo'
              ? .216
              : (1 - size.height) / 2,
          width: template.layout == 'gallery'
              ? .664
              : template.layout == 'photo'
              ? .656
              : size.width,
          height: template.layout == 'gallery'
              ? .397
              : template.layout == 'photo'
              ? .323
              : size.height,
          photoCrop: fullPhotoCrop,
          rotation: template.layout == 'gallery' ? -.035 : -.025,
          frameStyle: template.layout == 'gallery' ? 0 : 1,
        );
        page.elements.add(element);
        _selectedId = element.id;
      });
      _changed();
    }
  }

  Future<void> _cropSelectedPhoto() async {
    final element = selectedElement;
    if (element == null ||
        element.locked ||
        element.type != AlbumElementType.photo) {
      return;
    }
    if (await editAlbumPhotoCrop(context, element) && mounted) {
      setState(() {});
      _changed();
    }
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

    // Preserve the drawing aspect on the 5:7 card.
    const baseHeight = 0.28;
    final baseWidth = (baseHeight * ratio * (7.0 / 5.0)).clamp(0.25, 0.85);

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

  Future<void> _addText() async {
    final result = await showDialog<TextElementResult>(
      context: context,
      builder: (_) => const TextEditorDialog(),
    );
    if (result == null || result.text.trim().isEmpty || !mounted) return;
    setState(() {
      final element = AlbumElementModel(
        id: newId(),
        type: AlbumElementType.text,
        content: result.text,
        extraData: result.fontFamily,
        fontSize: result.fontSize,
        textColor: result.textColor,
        x: .12,
        y: .72,
        width: .76,
        height: .12,
      );
      page.elements.add(element);
      _selectedId = element.id;
    });
    _changed();
  }

  /// A second tap on the selected text opens the editor, the way tapping
  /// twice works in most apps. Other element types keep their toolbar button.
  Future<void> _activateElement(String elementId) async {
    final element = selectedElement;
    if (element == null || element.id != elementId || element.locked) return;
    if (element.photoSlot) {
      await _fillPhotoSlot(elementId);
      return;
    }
    if (element.type != AlbumElementType.text) return;
    await _editSelected();
  }

  Future<void> _editSelected() async {
    final element = selectedElement;
    if (element == null || element.locked) return;
    if (element.type == AlbumElementType.card) {
      await _editSelectedCard(element);
      return;
    }
    if (element.type == AlbumElementType.drawing) {
      setState(() => element.rotation += .18);
      _changed();
      return;
    }
    if (element.type == AlbumElementType.sticker) {
      // Replacing the content would discard a sticker the user cut from their
      // own photo; see the same guard in the album editor.
      if (isPersonalStickerElement(element)) return;
      final replacement = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => isAlbumShape(element.content)
            ? const ShapeObjectPickerSheet()
            : const StickerPackPickerSheet(),
      );
      if (replacement == null || !mounted) return;
      setState(() => element.content = replacement);
      _changed();
      return;
    }
    if (element.type != AlbumElementType.text) return;
    final result = await showDialog<TextElementResult>(
      context: context,
      builder: (_) => TextEditorDialog(
        initialText: element.content,
        initialFont: element.extraData.isEmpty ? 'Inter' : element.extraData,
        initialFontSize: element.fontSize,
        initialColor: element.textColor,
      ),
    );
    if (result == null || !mounted) return;
    setState(() {
      element
        ..content = result.text
        ..extraData = result.fontFamily
        ..fontSize = result.fontSize
        ..textColor = result.textColor;
    });
    _changed();
  }

  bool _elementMenuOpen = false;
  Future<void> _showElementMenu(String id, Offset position) async {
    if (_elementMenuOpen) return;
    final found = page.elements.where((e) => e.id == id);
    if (found.isEmpty) return;
    final element = found.first;
    _elementMenuOpen = true;
    try {
      setState(() => _selectedId = id);
      final size = MediaQuery.sizeOf(context);
      final action = await showMenu<String>(
        context: context,
        position: RelativeRect.fromLTRB(
          position.dx,
          position.dy,
          size.width - position.dx,
          size.height - position.dy,
        ),
        items: [
          if (element.type == AlbumElementType.photo)
            PopupMenuItem(
              value: 'edit',
              enabled: !element.locked,
              child: Text(context.tr('Düzenle')),
            ),
          PopupMenuItem(
            value: 'lock',
            child: Text(context.tr(element.locked ? 'Kilidi aç' : 'Sabitle')),
          ),
        ],
      );
      if (!mounted) return;
      if (action == 'edit') await _styleSelectedPhoto();
      if (action == 'lock') {
        setState(() {
          final value = !element.locked;
          for (final e in albumElementMembers(page.elements, id)) {
            e.locked = value;
          }
        });
        _changed();
      }
    } finally {
      _elementMenuOpen = false;
    }
  }

  Future<void> _styleSelectedPhoto() async {
    final element = selectedElement;
    if (element == null ||
        element.locked ||
        element.type != AlbumElementType.photo) {
      return;
    }
    final style = await showAlbumPhotoStylePicker(
      context,
      selectedFrameStyle: element.frameStyle,
      selectedShape: element.photoShape,
      element: element,
    );
    if (style == null || !mounted) return;
    setState(() {
      final targets = style.scope == PhotoStyleScope.selected
          ? [element]
          : page.elements;
      for (final target in targets.where(
        (e) => e.type == AlbumElementType.photo && !e.locked,
      )) {
        applyPhotoStudioResult(
          target,
          style,
          includeCrop: target.id == element.id,
        );
      }
    });
    _changed();
  }

  Future<void> _addSticker({bool personal = false}) async {
    final String? sticker;
    if (personal) {
      // Making your own stickers is the paid part; see the album editor.
      if (!MonetizationPolicy.rewardedOnly &&
          !await ensureCustomStickers(context)) {
        return;
      }
      if (!mounted) return;
      sticker = await Navigator.push<String>(
        context,
        MaterialPageRoute(builder: (_) => const PersonalStickersScreen()),
      );
    } else {
      sticker = await showModalBottomSheet<String>(
        context: context,
        isScrollControlled: true,
        showDragHandle: true,
        builder: (_) => const StickerPackPickerSheet(),
      );
    }
    if (sticker != null && mounted) _insertDecoration(sticker);
  }

  Future<void> _addShape() async {
    final shape = await showShapeObjectPicker(context);
    if (shape != null && mounted) _insertDecoration(shape);
  }

  void _insertDecoration(String content) {
    final isShape = isAlbumShape(content);
    setState(() {
      final element = AlbumElementModel(
        id: newId(),
        type: AlbumElementType.sticker,
        content: content,
        x: isShape ? .37 : .34,
        y: .23,
        width: isShape ? .26 : .32,
        height: isShape ? .22 : .26,
      );
      page.elements.add(element);
      _selectedId = element.id;
    });
    _changed();
  }

  void _duplicateSelected() {
    final source = selectedElement;
    if (source == null) return;
    setState(() {
      final copies = duplicateAlbumElementSet(page.elements, source.id);
      _selectedId = copies.first.id;
    });
    _changed();
  }

  void _deleteSelected() {
    if (_selectedId == null) return;
    setState(() {
      removeAlbumElementSet(page.elements, _selectedId!);
      _selectedId = null;
    });
    _changed();
  }

  Future<void> _shareCard() async {
    if (_sharing) return;
    final localizations =
        AlbumiumLocalizations.maybeOf(context) ??
        const AlbumiumLocalizations(Locale('tr'));
    final previousSelection = _selectedId;
    setState(() {
      _sharing = true;
      _selectedId = null;
    });
    try {
      await GoogleFonts.pendingFonts();
      await WidgetsBinding.instance.endOfFrame;
      final renderObject = _captureKey.currentContext?.findRenderObject();
      if (renderObject is! RenderRepaintBoundary) {
        throw StateError(localizations.text('Kart yüzeyi hazırlanamadı'));
      }
      final image = await renderObject.toImage(pixelRatio: 3.2);
      final data = await image.toByteData(format: ui.ImageByteFormat.png);
      image.dispose();
      if (data == null) {
        throw StateError(localizations.text('PNG oluşturulamadı'));
      }
      final directory = await getTemporaryDirectory();
      final safeName = project.title
          .replaceAll(RegExp(r'[^a-zA-Z0-9ğüşöçıİĞÜŞÖÇ -]'), '')
          .trim()
          .replaceAll(RegExp(r'\s+'), '_');
      final file = File(
        '${directory.path}${Platform.pathSeparator}${safeName.isEmpty ? 'albumium_kart' : safeName}.png',
      );
      await file.writeAsBytes(data.buffer.asUint8List(), flush: true);
      if (!mounted) return;
      final shareParams = ShareParams(
        sharePositionOrigin: albumShareOrigin(context),
        files: [XFile(file.path)],
        title: project.title,
        subject: '${project.title} · Albumium',
        text: localizations.text('Özel gün kartımı Albumium ile tasarladım.'),
      );
      final choice = await showExportDeliverySheet(context, video: false);
      if (!mounted) return;
      switch (choice) {
        case ExportDelivery.saveToGallery:
          await saveExportsToGallery(
            context,
            [file.path],
            video: false,
            onShare: () => unawaited(SharePlus.instance.share(shareParams)),
          );
        case ExportDelivery.share:
          await SharePlus.instance.share(shareParams);
        case null:
          break;
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              context.tr(
                'Kart paylaşılamadı: {error}',
                values: {'error': error},
              ),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _sharing = false;
          _selectedId = previousSelection;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AlbumiumAppTheme.colorsOf(context);
    final size = MediaQuery.sizeOf(context);
    final tablet = size.shortestSide >= 600;

    return PopScope(
      onPopInvokedWithResult: (_, _) =>
          unawaited(AlbumStorage.instance.saveAlbum(project)),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: colors.background,
          toolbarHeight: 68,
          titleSpacing: 0,
          title: InkWell(
            onTap: _renameProject,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(project.title, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 3),
                        Text(
                          context.tr('Özel gün kartı'),
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: colors.mutedText,
                                letterSpacing: .2,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.edit_outlined, size: 16, color: colors.mutedText),
                ],
              ),
            ),
          ),
          actions: [
            PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'save') {
                  try {
                    await CardTemplateStorage.save(project);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(context.tr('Şablon kaydedildi')),
                        ),
                      );
                    }
                  } catch (_) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            context.tr('Kaydedilemedi. Tekrar dene.'),
                          ),
                        ),
                      );
                    }
                  }
                } else if (value == 'reset') {
                  final reset = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: Text(context.tr('Tasarımı sıfırla?')),
                      content: Text(
                        context.tr('Bu karttaki düzenlemeler silinecek.'),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: Text(context.tr('Vazgeç')),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text(context.tr('Sıfırla')),
                        ),
                      ],
                    ),
                  );
                  if (reset == true && mounted) {
                    setState(() {
                      page.elements
                        ..clear()
                        ..addAll(_defaultCardElements(template, context.tr));
                      _selectedId = null;
                    });
                    _changed();
                  }
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'save',
                  child: Text(context.tr('Şablonum olarak kaydet')),
                ),
                PopupMenuItem(
                  value: 'reset',
                  child: Text(context.tr('Tasarımı sıfırla')),
                ),
              ],
            ),
            IconButton.filledTonal(
              onPressed: _sharing ? null : _shareCard,
              tooltip: context.tr('PNG paylaş'),
              style: IconButton.styleFrom(
                minimumSize: const Size.square(48),
                backgroundColor: colors.primary.withValues(alpha: .10),
                foregroundColor: colors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: _sharing
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.ios_share_rounded),
            ),
            const SizedBox(width: 14),
          ],
        ),
        body: CraftBackdrop(
          variant: CraftBackdropVariant.studio,
          baseColor: colors.background,
          textureIntensity: .58,
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final sidePanel =
                    constraints.maxWidth >= _cardStudioSidePanelBreakpoint;
                final controls = selectedElement != null
                    ? ElementEditPanel(
                        key: ValueKey(_selectedId),
                        element: selectedElement!,
                        groupElements: albumElementMembers(
                          page.elements,
                          selectedElement!.id,
                        ),
                        onChanged: () {
                          setState(() {});
                          _changed();
                        },
                        onClose: () => setState(() => _selectedId = null),
                        onStyle: selectedElement!.type == AlbumElementType.photo
                            ? _styleSelectedPhoto
                            : _editSelected,
                        onCrop: _cropSelectedPhoto,
                        onReplacePhoto: selectedElement!.photoSlot
                            ? () => _fillPhotoSlot(selectedElement!.id)
                            : null,
                        onClearPhoto: _clearPhotoSlot,
                        onDuplicate: _duplicateSelected,
                        onDelete: _deleteSelected,
                        canMoveLayer: (action) => canMoveAlbumElementLayer(
                          page.elements,
                          _selectedId!,
                          action,
                        ),
                        onLayer: (action) {
                          setState(
                            () => moveAlbumElementLayer(
                              page.elements,
                              _selectedId!,
                              action,
                            ),
                          );
                          _changed();
                        },
                      )
                    : _CardControls(
                        sidePanel: sidePanel,
                        project: project,
                        selectedTemplate: template,
                        onTemplateSelected: _selectTemplate,
                        onPhoto: _addPhoto,
                        onPhotoSlots: _addPhotoSlots,
                        onText: _addText,
                        onSticker: _addSticker,
                        onPersonalSticker: () => _addSticker(personal: true),
                        onShape: _addShape,
                        onColor: _changeCardColor,
                        onDraw: _addHandwriting,
                        onCard: _addOccasionCard,
                        onLayers: _showLayers,
                        onToggleArtwork: () {
                          setState(
                            () => project.cardArtworkVisible =
                                !project.cardArtworkVisible,
                          );
                          _changed();
                        },
                        onTemplates: _showTemplates,
                      );
                final canvas = Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        children: [
                          IconButton(
                            key: const ValueKey('card-undo'),
                            tooltip: context.tr('Geri al'),
                            onPressed: _history.canUndo
                                ? () => _restoreHistory(false)
                                : null,
                            icon: const Icon(Icons.undo_rounded),
                          ),
                          IconButton(
                            key: const ValueKey('card-redo'),
                            tooltip: context.tr('Yinele'),
                            onPressed: _history.canRedo
                                ? () => _restoreHistory(true)
                                : null,
                            icon: const Icon(Icons.redo_rounded),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              context.tr('Taşı · Boyutlandır · Döndür'),
                              style: Theme.of(context).textTheme.labelSmall,
                              textAlign: TextAlign.end,
                              maxLines: 2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(child: _buildCanvas(tablet: tablet)),
                  ],
                );

                if (sidePanel) {
                  return Row(
                    children: [
                      Expanded(flex: 6, child: canvas),
                      SizedBox(
                        width: _cardStudioSidePanelWidth,
                        child: controls,
                      ),
                    ],
                  );
                }

                return Column(
                  children: [
                    Expanded(child: canvas),
                    BoundedControls(
                      height: constraints.maxHeight * .48,
                      child: controls,
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _restoreHistory(bool redo) {
    setState(() {
      redo ? _history.redo(project) : _history.undo(project);
      _selectedId = null;
    });
    _changed(record: false);
  }

  Future<void> _changeCardColor() async {
    final color = await showDialog<int>(
      context: context,
      builder: (_) =>
          CardColorPicker(initialColor: Color(page.backgroundColor)),
    );
    if (color == null || !mounted) return;
    setState(() => page.backgroundColor = color);
    _changed();
  }

  Future<void> _showTemplates() async {
    final catalog = [
      ...atelierCardTemplates,
      ...occasionCardTemplates.where((t) => !atelierCardTemplates.contains(t)),
      blankCardTemplate,
    ];
    final next = await showModalBottomSheet<OccasionCardTemplate>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * .78,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Column(
                  children: [
                    Text(
                      context.tr('Bir tasarımla başla'),
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      context.tr('Yazılar, renkler ve yerleşim sana ait.'),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: GridView.builder(
                  key: const ValueKey('card-template-grid'),
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 200,
                    mainAxisExtent: 248,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: catalog.length,
                  itemBuilder: (context, index) {
                    final item = catalog[index];
                    return InkWell(
                      key: ValueKey('card-template-${item.id}'),
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => Navigator.pop(context, item),
                      child: Column(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: CardTemplateThumbnail(template: item),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(
                              context.tr(item.title).replaceAll('\n', ' '),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (next != null && mounted) _selectTemplate(next);
  }

  Future<void> _showLayers() async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, refresh) {
          final sets = albumElementSets(page.elements).reversed.toList();
          return SafeArea(
            child: SizedBox(
              height: MediaQuery.sizeOf(context).height * .6,
              child: Column(
                children: [
                  Text(
                    context.tr('Katmanlar'),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      context.tr(
                        'En üstteki öğe önde görünür. Sıralamak için sürükle.',
                      ),
                    ),
                  ),
                  Expanded(
                    child: sets.isEmpty
                        ? Center(
                            child: Text(
                              context.tr(
                                'Fotoğraf, yazı veya çizim ekleyerek başla.',
                              ),
                            ),
                          )
                        : ReorderableListView.builder(
                            buildDefaultDragHandles: false,
                            itemCount: sets.length,
                            onReorder: (from, to) {
                              if (to > from) to--;
                              sets.insert(to, sets.removeAt(from));
                              setState(() {
                                page.elements
                                  ..clear()
                                  ..addAll(sets.reversed.expand((set) => set));
                              });
                              _changed();
                              refresh(() {});
                            },
                            itemBuilder: (context, index) {
                              final members = sets[index];
                              final element = members.first;
                              final label = members.length > 1
                                  ? '${context.tr('Izgara')} · ${members.length}'
                                  : switch (element.type) {
                                      AlbumElementType.text => element.content,
                                      AlbumElementType.photo => context.tr(
                                        'Fotoğraf',
                                      ),
                                      AlbumElementType.drawing => context.tr(
                                        'Çizim',
                                      ),
                                      AlbumElementType.card => context.tr(
                                        'Özel Kart',
                                      ),
                                      _ => context.tr('Süsler'),
                                    };
                              return ListTile(
                                key: ValueKey(element.groupId ?? element.id),
                                leading: ReorderableDragStartListener(
                                  index: index,
                                  child: const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: Icon(Icons.drag_indicator_rounded),
                                  ),
                                ),
                                title: Text(
                                  label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                onTap: () {
                                  setState(() => _selectedId = element.id);
                                  Navigator.pop(sheetContext);
                                },
                                trailing: IconButton(
                                  tooltip: context.tr(
                                    element.locked ? 'Kilidi aç' : 'Kilitle',
                                  ),
                                  icon: Icon(
                                    element.locked
                                        ? Icons.lock_outline_rounded
                                        : Icons.lock_open_rounded,
                                  ),
                                  onPressed: () {
                                    final value = !element.locked;
                                    setState(() {
                                      for (final cell in members) {
                                        cell.locked = value;
                                      }
                                    });
                                    _changed();
                                    refresh(() {});
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCanvas({required bool tablet}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = tablet ? 520.0 : 390.0;
        return Stack(
          children: [
            Center(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  tablet ? 24 : 18,
                  6,
                  tablet ? 24 : 18,
                  14,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: AspectRatio(
                    aspectRatio: 5 / 7,
                    child: RepaintBoundary(
                      key: _captureKey,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x52000000),
                              blurRadius: 32,
                              offset: Offset(0, 18),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: AlbumPageCanvas(
                            page: page,
                            theme: cardTheme,
                            interactive: true,
                            selectedId: _selectedId,
                            onSelect: (id) => setState(() => _selectedId = id),
                            onActivate: _activateElement,
                            onLongPressElement: _showElementMenu,
                            onChanged: _changed,
                            showPageNumber: false,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CardControls extends StatelessWidget {
  const _CardControls({
    required this.sidePanel,
    required this.project,
    required this.selectedTemplate,
    required this.onTemplateSelected,
    required this.onPhoto,
    required this.onPhotoSlots,
    required this.onText,
    required this.onSticker,
    required this.onPersonalSticker,
    required this.onShape,
    required this.onColor,
    required this.onDraw,
    required this.onCard,
    required this.onLayers,
    required this.onToggleArtwork,
    required this.onTemplates,
  });

  final bool sidePanel;
  final AlbumModel project;
  final OccasionCardTemplate selectedTemplate;
  final ValueChanged<OccasionCardTemplate> onTemplateSelected;
  final VoidCallback onPhoto;
  final VoidCallback onPhotoSlots;
  final VoidCallback onText;
  final VoidCallback onSticker;
  final VoidCallback onPersonalSticker;
  final VoidCallback onShape;
  final VoidCallback onColor;
  final VoidCallback onDraw;
  final VoidCallback onCard;
  final VoidCallback onLayers, onToggleArtwork, onTemplates;

  @override
  Widget build(BuildContext context) {
    final colors = AlbumiumAppTheme.colorsOf(context);
    return Container(
      key: ValueKey(sidePanel ? 'card-controls-side' : 'card-controls-bottom'),
      decoration: BoxDecoration(
        color: colors.elevatedSurface,
        border: Border(
          top: sidePanel ? BorderSide.none : BorderSide(color: colors.border),
          left: sidePanel ? BorderSide(color: colors.border) : BorderSide.none,
        ),
      ),
      padding: EdgeInsets.fromLTRB(16, sidePanel ? 24 : 14, 16, 12),
      child: sidePanel
          ? LayoutBuilder(
              builder: (context, constraints) {
                final content = _buildContent(context);
                if (!constraints.hasBoundedHeight) return content;
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: content,
                  ),
                );
              },
            )
          : _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final colors = AlbumiumAppTheme.colorsOf(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
              width: 30,
              height: 42,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: CardTemplateThumbnail(template: selectedTemplate),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.tr('Tasarım atölyesi'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    context.tr(selectedTemplate.title).replaceAll('\n', ' '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: colors.mutedText, fontSize: 11),
                  ),
                ],
              ),
            ),
            TextButton.icon(
              key: const ValueKey('card-choose-template'),
              onPressed: onTemplates,
              icon: const Icon(Icons.grid_view_rounded, size: 17),
              label: Text(context.tr('Temalar')),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CardTool(
                icon: Icons.add_photo_alternate_outlined,
                label: context.tr('Fotoğraf'),
                onTap: onPhoto,
              ),
              _CardTool(
                icon: Icons.text_fields_rounded,
                label: context.tr('Yazı'),
                onTap: onText,
              ),
              _CardTool(
                icon: Icons.photo_size_select_large_outlined,
                label: context.tr('Fotoğraf yuvaları'),
                onTap: onPhotoSlots,
              ),
              _CardTool(
                icon: Icons.draw_outlined,
                label: context.tr('Çizim'),
                onTap: onDraw,
              ),
              _CardTool(
                icon: Icons.palette_outlined,
                label: context.tr('Renk'),
                onTap: onColor,
              ),
              _CardTool(
                icon: Icons.layers_outlined,
                label: context.tr('Katmanlar'),
                onTap: onLayers,
              ),
              _CardTool(
                icon: Icons.interests_outlined,
                label: context.tr('Şekiller'),
                onTap: onShape,
              ),
              _CardTool(
                icon: Icons.auto_awesome_outlined,
                label: context.tr('Süsler'),
                onTap: onSticker,
              ),
              _CardTool(
                icon: Icons.add_reaction_outlined,
                label: context.tr('Sticker'),
                onTap: onPersonalSticker,
              ),
              _CardTool(
                icon: Icons.celebration_outlined,
                label: context.tr('Özel Kart'),
                onTap: onCard,
              ),
            ],
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          key: const ValueKey('card-artwork-toggle'),
          onTap: selectedTemplate.layout == 'blank' ? null : onToggleArtwork,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 9),
            child: Row(
              children: [
                Icon(
                  project.cardArtworkVisible
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  size: 18,
                  color: colors.mutedText,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    context.tr(
                      project.cardArtworkVisible
                          ? 'Tema deseni açık'
                          : 'Tema deseni kapalı',
                    ),
                    style: TextStyle(fontSize: 12, color: colors.mutedText),
                  ),
                ),
                Icon(Icons.tune_rounded, size: 16, color: colors.mutedText),
              ],
            ),
          ),
        ),
        if (sidePanel)
          Padding(
            padding: const EdgeInsets.only(top: 18),
            child: Text(
              context.tr(
                'Bir öğeye dokun; taşı, boyutlandır veya döndür. Kendi tasarımını şablon olarak da kaydedebilirsin.',
              ),
              style: TextStyle(color: colors.mutedText, height: 1.5),
            ),
          ),
      ],
    );
  }
}

class _CardTool extends StatelessWidget {
  const _CardTool({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = AlbumiumAppTheme.colorsOf(context);
    final style = Theme.of(
      context,
    ).textTheme.labelMedium!.copyWith(fontWeight: FontWeight.w500);
    final labelSize = controlLabelSize(context, label, style);
    return Tooltip(
      message: label,
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          foregroundColor: colors.text,
          backgroundColor: colors.surface,
          minimumSize: Size(
            (labelSize.width + 24).clamp(72.0, double.infinity),
            48 + labelSize.height,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          textStyle: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w500),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 22, color: colors.primary),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 1,
              softWrap: false,
              style: style,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
