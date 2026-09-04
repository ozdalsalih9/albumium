import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../l10n/albumium_localizations.dart';
import '../models/album_models.dart';
import '../services/album_storage.dart';
import '../theme/albumium_app_theme.dart';
import '../widgets/album_page_canvas.dart';
import '../widgets/font_selector_dialog.dart';
import '../widgets/handmade_craft.dart';
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
    title: '${localize(selected.title)} ${localize('Kartı')}',
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

List<AlbumElementModel> _defaultCardElements(
  OccasionCardTemplate template,
  String Function(String text) localize,
) => [
  AlbumElementModel(
    id: '$_cardRoleBadge${newId()}',
    type: AlbumElementType.text,
    content: '${template.emoji}  ${localize(template.badge)}',
    extraData: 'Inter',
    x: .16,
    y: .15,
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
    y: .31,
    width: .80,
    height: .18,
    fontSize: 31,
    textColor: const Color(0xFF2C2520).toARGB32(),
  ),
  AlbumElementModel(
    id: '$_cardRoleMessage${newId()}',
    type: AlbumElementType.text,
    content: localize(template.subtitle),
    extraData: 'Inter',
    x: .13,
    y: .57,
    width: .74,
    height: .16,
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
  final _imagePicker = ImagePicker();
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
    setState(() {
      project.cardThemeId = next.id;
      page.backgroundColor = next.primaryColor.toARGB32();
      final badge = page.elements.where((e) => e.id.startsWith(_cardRoleBadge));
      final title = page.elements.where((e) => e.id.startsWith(_cardRoleTitle));
      final message = page.elements.where(
        (e) => e.id.startsWith(_cardRoleMessage),
      );
      if (badge.isNotEmpty) {
        badge.first
          ..content = '${next.emoji}  ${context.tr(next.badge)}'
          ..textColor = next.accentColor.toARGB32();
      }
      if (title.isNotEmpty) title.first.content = context.tr(next.title);
      if (message.isNotEmpty) message.first.content = context.tr(next.subtitle);
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
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 94,
      maxWidth: 2800,
    );
    if (picked == null || !mounted) return;
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
      return;
    }
    if (!mounted) return;
    setState(() {
      final element = AlbumElementModel(
        id: newId(),
        type: AlbumElementType.photo,
        content: path,
        x: (1 - size.width) / 2,
        y: (1 - size.height) / 2,
        width: size.width,
        height: size.height,
        photoCrop: fullPhotoCrop,
        rotation: -.025,
        frameStyle: 1,
      );
      page.elements.add(element);
      _selectedId = element.id;
    });
    _changed();
  }

  Future<void> _cropSelectedPhoto() async {
    final element = selectedElement;
    if (element == null || element.type != AlbumElementType.photo) return;
    if (await editAlbumPhotoCrop(context, element) && mounted) {
      setState(() {});
      _changed();
    }
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

  Future<void> _editSelected() async {
    final element = selectedElement;
    if (element == null || element.type != AlbumElementType.text) return;
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

  Future<void> _addSticker() async {
    final sticker = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => const StickerPackPickerSheet(),
    );
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
        fontSize: source.fontSize,
        extraData: source.extraData,
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
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          title: project.title,
          subject: '${project.title} · Albumium',
          text: localizations.text('Özel gün kartımı Albumium ile tasarladım.'),
        ),
      );
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
          titleSpacing: 4,
          title: InkWell(
            onTap: _renameProject,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: Text(project.title, overflow: TextOverflow.ellipsis),
                  ),
                  const SizedBox(width: 6),
                  const Icon(Icons.edit_outlined, size: 17),
                ],
              ),
            ),
          ),
          actions: [
            IconButton(
              onPressed: _sharing ? null : _shareCard,
              tooltip: context.tr('PNG paylaş'),
              icon: _sharing
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.ios_share_rounded),
            ),
            const SizedBox(width: 6),
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
                final controls = _CardControls(
                  sidePanel: sidePanel,
                  project: project,
                  selectedTemplate: template,
                  onTemplateSelected: _selectTemplate,
                  onPhoto: _addPhoto,
                  onText: _addText,
                  onSticker: _addSticker,
                  onShape: _addShape,
                );
                final canvas = _buildCanvas(tablet: tablet);

                if (sidePanel) {
                  return Row(
                    children: [
                      Expanded(flex: 6, child: canvas),
                      VerticalDivider(
                        width: 1,
                        color: Theme.of(context).dividerColor,
                      ),
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
                    controls,
                  ],
                );
              },
            ),
          ),
        ),
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
            if (selectedElement != null)
              Positioned(
                left: 16,
                right: 16,
                bottom: 9,
                child: Center(
                  child: Material(
                    elevation: 8,
                    borderRadius: BorderRadius.circular(18),
                    color: Theme.of(context).colorScheme.surfaceContainerHigh,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (selectedElement!.type == AlbumElementType.photo)
                            IconButton(
                              key: const ValueKey('style-card-photo'),
                              onPressed: _styleSelectedPhoto,
                              tooltip: context.tr(
                                'Fotoğraf biçimi ve çerçevesi',
                              ),
                              icon: const Icon(Icons.filter_frames_outlined),
                            ),
                          if (selectedElement!.type == AlbumElementType.text)
                            IconButton(
                              onPressed: _editSelected,
                              tooltip: context.tr('Metni düzenle'),
                              icon: const Icon(Icons.edit_rounded),
                            ),
                          if (selectedElement!.type == AlbumElementType.photo)
                            IconButton(
                              onPressed: _cropSelectedPhoto,
                              tooltip: context.tr('Fotoğrafı kırp'),
                              icon: const Icon(Icons.crop_rounded),
                            ),
                          IconButton(
                            onPressed: _duplicateSelected,
                            tooltip: context.tr('Çoğalt'),
                            icon: const Icon(Icons.copy_rounded),
                          ),
                          IconButton(
                            onPressed: _deleteSelected,
                            tooltip: context.tr('Sil'),
                            color: Theme.of(context).colorScheme.error,
                            icon: const Icon(Icons.delete_outline_rounded),
                          ),
                        ],
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
    required this.onShape,
  });

  final bool sidePanel;
  final AlbumModel project;
  final OccasionCardTemplate selectedTemplate;
  final ValueChanged<OccasionCardTemplate> onTemplateSelected;
  final VoidCallback onPhoto;
  final VoidCallback onText;
  final VoidCallback onSticker;
  final VoidCallback onShape;

  @override
  Widget build(BuildContext context) {
    final colors = AlbumiumAppTheme.colorsOf(context);
    return PaperPanel(
      key: ValueKey(sidePanel ? 'card-controls-side' : 'card-controls-bottom'),
      color: colors.surface,
      borderRadius: sidePanel
          ? const BorderRadius.horizontal(left: Radius.circular(10))
          : const BorderRadius.vertical(top: Radius.circular(10)),
      padding: EdgeInsets.fromLTRB(14, sidePanel ? 24 : 11, 14, 13),
      textureIntensity: .22,
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TornPaperLabel(
          rotationDegrees: -.3,
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
          child: Text(
            context.tr('Kart Teması'),
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontSize: 20),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: sidePanel ? 232 : 78,
          child: ListView.separated(
            scrollDirection: sidePanel ? Axis.vertical : Axis.horizontal,
            itemCount: occasionCardTemplates.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8, height: 8),
            itemBuilder: (context, index) {
              final card = occasionCardTemplates[index];
              final selected = selectedTemplate.id == card.id;
              return InkWell(
                onTap: () => onTemplateSelected(card),
                borderRadius: BorderRadius.circular(15),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: sidePanel ? double.infinity : 146,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: card.primaryColor,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: selected ? card.accentColor : card.secondaryColor,
                      width: selected ? 2.2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 17,
                        backgroundColor: card.secondaryColor,
                        child: Icon(
                          card.icon,
                          size: 18,
                          color: card.accentColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          context.tr(card.badge),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: card.accentColor,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
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
                icon: Icons.auto_awesome_outlined,
                label: context.tr('Süsler'),
                onTap: onSticker,
              ),
              _CardTool(
                icon: Icons.interests_outlined,
                label: context.tr('Şekiller'),
                onTap: onShape,
              ),
            ],
          ),
        ),
        if (sidePanel) ...[
          const SizedBox(height: 18),
          Text(
            context.tr(
              'Nesneleri parmağınla taşı; iki parmakla büyüt, küçült ve döndür. Kart PNG olarak paylaşılabilir.',
            ),
            style: Theme.of(context).textTheme.bodySmall,
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
    return Padding(
      padding: const EdgeInsets.only(right: 7),
      child: FilledButton.tonalIcon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 43),
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
      ),
    );
  }
}
