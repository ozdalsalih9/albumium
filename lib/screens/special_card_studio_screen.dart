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
import '../services/album_storage.dart';
import '../services/personal_sticker_storage.dart';
import '../theme/albumium_app_theme.dart';
import '../widgets/album_page_canvas.dart';
import '../widgets/export_delivery.dart';
import '../widgets/feature_unlock_sheet.dart';
import '../widgets/element_edit_panel.dart';
import '../widgets/font_selector_dialog.dart';
import '../widgets/handmade_craft.dart';
import '../widgets/handwriting_painter.dart';
import '../widgets/occasion_cards.dart';
import '../widgets/photo_style_picker.dart';
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
) => template.layout == 'blank'
    ? []
    : [
        AlbumElementModel(
          id: '$_cardRoleBadge${newId()}',
          type: AlbumElementType.text,
          content: template.layout == 'classic'
              ? '${template.emoji}  ${localize(template.badge)}'
              : localize(template.badge),
          extraData: 'Inter',
          x: .16,
          y: template.layout == 'photo'
              ? .055
              : ['geometric', 'arch'].contains(template.layout)
              ? .22
              : .15,
          width: .68,
          height: .08,
          fontSize: 12,
          textColor: template.accentColor.toARGB32(),
        ),
        AlbumElementModel(
          id: '$_cardRoleTitle${newId()}',
          type: AlbumElementType.text,
          content: localize(template.title),
          extraData: 'Cormorant Garamond',
          x: .10,
          y: template.layout == 'photo'
              ? .63
              : template.layout == 'editorial'
              ? .22
              : .31,
          width: .80,
          height: .18,
          fontSize: template.layout == 'editorial' ? 37 : 31,
          textColor: const Color(0xFF2C2520).toARGB32(),
        ),
        AlbumElementModel(
          id: '$_cardRoleMessage${newId()}',
          type: AlbumElementType.text,
          content: localize(template.subtitle),
          extraData: 'Inter',
          x: .13,
          y: template.layout == 'photo'
              ? .81
              : template.layout == 'editorial'
              ? .50
              : .57,
          width: .74,
          height: template.layout == 'photo' ? .11 : .16,
          fontSize: 17,
          textColor: const Color(0xFF645850).toARGB32(),
        ),
      ];

AlbumThemePreset specialCardThemeFor(OccasionCardTemplate template) =>
    AlbumThemePreset(
      id: 'special_card_${template.id}',
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

  AlbumModel get project => widget.project;
  AlbumPageModel get page => project.pages.first;
  OccasionCardTemplate get template =>
      occasionTemplateById(project.cardThemeId);

  AlbumThemePreset get cardTheme => specialCardThemeFor(template);

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
          elements: _defaultCardElements(template, (text) => text),
        ),
      );
    }
  }

  @override
  void dispose() {
    _saveDebounce?.cancel();
    unawaited(AlbumStorage.instance.saveAlbum(project));
    super.dispose();
  }

  void _changed() {
    _saveDebounce?.cancel();
    _saveDebounce = Timer(
      const Duration(milliseconds: 420),
      () => unawaited(AlbumStorage.instance.saveAlbum(project)),
    );
  }

  void _selectTemplate(OccasionCardTemplate next) {
    final previous = template;
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
      project.cardThemeId = next.id;
      page.backgroundColor = next.primaryColor.toARGB32();
      // Wording the user typed survives a theme change; copy that still
      // matches the previous template is replaced with the new template's.
      if (project.title == _defaultCardTitle(previous, raw) ||
          project.title == _defaultCardTitle(previous, context.tr)) {
        project.title = _defaultCardTitle(next, context.tr);
      }
      for (final element in page.elements.where(
        (e) => e.type == AlbumElementType.text,
      )) {
        element.textColor = next.accentColor.toARGB32();
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
            ..fontSize = layout.fontSize;
        }
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

  Future<void> _addPhoto() async {
    final photos = await PhotoSelectionService.pick(context);
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
      setState(() {
        final element = AlbumElementModel(
          id: newId(),
          type: AlbumElementType.photo,
          content: path,
          x: template.layout == 'photo' ? .172 : (1 - size.width) / 2,
          y: template.layout == 'photo' ? .216 : (1 - size.height) / 2,
          width: template.layout == 'photo' ? .656 : size.width,
          height: template.layout == 'photo' ? .323 : size.height,
          photoCrop: fullPhotoCrop,
          rotation: -.025,
          frameStyle: 1,
        );
        page.elements.add(element);
        _selectedId = element.id;
      });
      _changed();
    }
  }

  Future<void> _cropSelectedPhoto() async {
    final element = selectedElement;
    if (element == null || element.type != AlbumElementType.photo) return;
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

  Future<void> _styleSelectedPhoto() async {
    final element = selectedElement;
    if (element == null || element.type != AlbumElementType.photo) return;
    final style = await showAlbumPhotoStylePicker(
      context,
      selectedFrameStyle: element.frameStyle,
      selectedShape: element.photoShape,
    );
    if (style == null || !mounted) return;
    setState(() {
      element.frameStyle = style.frameStyle;
      applyAlbumPhotoShape(element, style.shape);
    });
    _changed();
  }

  Future<void> _addSticker({bool personal = false}) async {
    final String? sticker;
    if (personal) {
      // Making your own stickers is the paid part; see the album editor.
      if (!await ensureCustomStickers(context)) return;
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
    final shape = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const ShapeObjectPickerSheet(),
    );
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
      final copy = AlbumElementModel(
        id: newId(),
        type: source.type,
        content: source.content,
        x: (source.x + .04).clamp(-.25, .9),
        y: (source.y + .04).clamp(-.2, .92),
        width: source.width,
        height: source.height,
        rotation: source.rotation,
        scale: source.scale,
        frameStyle: source.frameStyle,
        photoShape: source.photoShape,
        photoCrop: source.photoCrop,
        textColor: source.textColor,
        textAlign: source.textAlign,
        fontSize: source.fontSize,
        extraData: source.extraData,
        cardColor: source.cardColor,
      );
      page.elements.add(copy);
      _selectedId = copy.id;
    });
    _changed();
  }

  void _deleteSelected() {
    if (_selectedId == null) return;
    setState(() {
      page.elements.removeWhere((element) => element.id == _selectedId);
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
                        onChanged: () {
                          setState(() {});
                          _changed();
                        },
                        onClose: () => setState(() => _selectedId = null),
                        onStyle: selectedElement!.type == AlbumElementType.photo
                            ? _styleSelectedPhoto
                            : _editSelected,
                        onCrop: _cropSelectedPhoto,
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
                        onText: _addText,
                        onSticker: _addSticker,
                        onPersonalSticker: () => _addSticker(personal: true),
                        onShape: _addShape,
                        onColor: _changeCardColor,
                        onDraw: _addHandwriting,
                        onCard: _addOccasionCard,
                      );
                final canvas = _buildCanvas(tablet: tablet);

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

  Future<void> _changeCardColor() async {
    final color = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('Kart rengi')),
        content: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            for (final color in editorCardColors)
              IconButton.filledTonal(
                tooltip: '#${color.toRadixString(16).substring(2)}',
                style: IconButton.styleFrom(backgroundColor: Color(color)),
                onPressed: () => Navigator.pop(context, color),
                icon: Icon(
                  page.backgroundColor == color
                      ? Icons.check
                      : Icons.circle_outlined,
                  color: Colors.black54,
                ),
              ),
          ],
        ),
      ),
    );
    if (color == null || !mounted) return;
    setState(() => page.backgroundColor = color);
    _changed();
  }

  Widget _buildCanvas({required bool tablet}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = tablet ? 520.0 : 390.0;
        return Stack(
          children: [
            Center(
              child: Padding(
                padding: EdgeInsets.all(tablet ? 34 : 18),
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: AspectRatio(
                    aspectRatio: 5 / 7,
                    child: RepaintBoundary(
                      key: _captureKey,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x52000000),
                              blurRadius: 32,
                              offset: Offset(0, 18),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: AlbumPageCanvas(
                            page: page,
                            theme: cardTheme,
                            interactive: true,
                            selectedId: _selectedId,
                            onSelect: (id) => setState(() => _selectedId = id),
                            onActivate: _activateElement,
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
    required this.onText,
    required this.onSticker,
    required this.onPersonalSticker,
    required this.onShape,
    required this.onColor,
    required this.onDraw,
    required this.onCard,
  });

  final bool sidePanel;
  final AlbumModel project;
  final OccasionCardTemplate selectedTemplate;
  final ValueChanged<OccasionCardTemplate> onTemplateSelected;
  final VoidCallback onPhoto;
  final VoidCallback onText;
  final VoidCallback onSticker;
  final VoidCallback onPersonalSticker;
  final VoidCallback onShape;
  final VoidCallback onColor;
  final VoidCallback onDraw;
  final VoidCallback onCard;

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
    const cardTextStyle = TextStyle(fontSize: 12, fontWeight: FontWeight.w600);
    final labelSizes = [
      for (final card in occasionCardTemplates)
        controlLabelSize(context, context.tr(card.title), cardTextStyle),
    ];
    final labelHeight = labelSizes.fold<double>(
      0,
      (h, s) => h > s.height ? h : s.height,
    );
    final tileHeight = (labelHeight + 18).clamp(62.0, double.infinity);
    final tools = [
      _CardTool(
        icon: Icons.draw_outlined,
        label: context.tr('Çizim'),
        onTap: onDraw,
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
      _CardTool(
        icon: Icons.palette_outlined,
        label: context.tr('Renk'),
        onTap: onColor,
      ),
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
        icon: Icons.auto_awesome_outlined,
        label: context.tr('Süsler'),
        onTap: onSticker,
      ),
      _CardTool(
        icon: Icons.interests_outlined,
        label: context.tr('Şekiller'),
        onTap: onShape,
      ),
    ];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.tr('Kart Teması'),
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: colors.mutedText,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: sidePanel ? tileHeight * 3 + 16 : tileHeight,
          child: ListView.separated(
            scrollDirection: sidePanel ? Axis.vertical : Axis.horizontal,
            itemCount: occasionCardTemplates.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8, height: 8),
            itemBuilder: (context, index) {
              final card = occasionCardTemplates[index];
              final selected = selectedTemplate.id == card.id;
              return Semantics(
                selected: selected,
                button: true,
                child: Material(
                  color: selected
                      ? colors.primary.withValues(alpha: .08)
                      : colors.surface,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    onTap: () => onTemplateSelected(card),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: sidePanel
                          ? double.infinity
                          : (labelSizes[index].width + 91).clamp(
                              168.0,
                              double.infinity,
                            ),
                      constraints: const BoxConstraints(minHeight: 62),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selected
                              ? colors.primary.withValues(alpha: .65)
                              : Colors.transparent,
                        ),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: card.primaryColor,
                            child: Icon(
                              card.icon,
                              size: 18,
                              color: card.accentColor,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              context.tr(card.title),
                              maxLines: sidePanel ? null : 1,
                              softWrap: sidePanel,
                              style: TextStyle(
                                color: colors.text,
                                fontSize: 12,
                                fontWeight: selected
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(width: 5),
                          Opacity(
                            opacity: selected ? 1 : 0,
                            child: Icon(
                              Icons.check_circle_rounded,
                              size: 16,
                              color: colors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Divider(height: 1, color: colors.border),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [for (final tool in tools) tool],
          ),
        ),
        if (sidePanel) ...[
          const SizedBox(height: 18),
          Text(
            context.tr(
              'Nesneleri parmağınla taşı; iki parmakla büyüt, küçült ve döndür. Kart PNG olarak paylaşılabilir.',
            ),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colors.mutedText,
              height: 1.5,
            ),
          ),
        ],
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
          minimumSize: Size(
            (labelSize.width + 24).clamp(72.0, double.infinity),
            48 + labelSize.height,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
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
