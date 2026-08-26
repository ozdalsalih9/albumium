import 'dart:async';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/album_models.dart';
import '../services/album_storage.dart';
import '../widgets/album_page_canvas.dart';
import 'preview_screen.dart';

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
            : AlbumPageModel(
                id: newId(),
                backgroundColor: themeById(album.themeId).pageColor.toARGB32(),
              );
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
    final controller = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sayfaya not ekle'),
        content: TextField(
          controller: controller,
          autofocus: true,
          minLines: 2,
          maxLines: 5,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(hintText: 'Bu anı neden özeldi?'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Ekle'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (text == null || text.isEmpty || !mounted) return;
    setState(() {
      final element = AlbumElementModel(
        id: newId(),
        type: AlbumElementType.text,
        content: text,
        x: 0.1,
        y: 0.72,
        width: 0.8,
        height: 0.14,
        fontSize: 21,
        textColor: themeById(album.themeId).accent.toARGB32(),
      );
      page.elements.add(element);
      _selectedId = element.id;
    });
    _changed();
  }

  Future<void> _addSticker() async {
    const stickers = [
      '❤️',
      '✨',
      '🌟',
      '🌸',
      '📍',
      '🎉',
      '🌈',
      '💫',
      '📸',
      '🌿',
      '🌞',
      '🪩',
      '🎂',
      '🐾',
      '🎮',
      '✈️',
    ];
    final sticker = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sticker seç',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              GridView.count(
                shrinkWrap: true,
                crossAxisCount: 8,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                children: [
                  for (final item in stickers)
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => Navigator.pop(context, item),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            item,
                            style: const TextStyle(fontSize: 27),
                          ),
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
    if (sticker == null || !mounted) return;
    setState(() {
      final element = AlbumElementModel(
        id: newId(),
        type: AlbumElementType.sticker,
        content: sticker,
        x: 0.66,
        y: 0.08,
        width: 0.18,
        height: 0.13,
        rotation: 0.08,
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
        AlbumPageModel(
          id: newId(),
          backgroundColor: themeById(album.themeId).pageColor.toARGB32(),
        ),
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

  void _changeBackground() {
    final theme = themeById(album.themeId);
    final colors = [
      theme.pageColor,
      const Color(0xFFFFFFFF),
      const Color(0xFFF3E4D4),
      const Color(0xFFE9ECE8),
      const Color(0xFFE9E3F2),
      const Color(0xFF292625),
    ];
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Sayfa rengi',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (final color in colors)
                    GestureDetector(
                      onTap: () {
                        setState(() => page.backgroundColor = color.toARGB32());
                        _changed();
                        Navigator.pop(context);
                      },
                      child: Container(
                        width: 43,
                        height: 43,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: page.backgroundColor == color.toARGB32()
                                ? const Color(0xFFFFA95C)
                                : Colors.white24,
                            width: 3,
                          ),
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

  void _styleSelected() {
    final selected = selectedElement;
    if (selected == null) return;
    setState(() {
      if (selected.type == AlbumElementType.photo) {
        selected.frameStyle = (selected.frameStyle + 1) % 4;
      } else if (selected.type == AlbumElementType.text) {
        const colors = [0xFF2B2521, 0xFFC75C77, 0xFF355E7A, 0xFFFFFFFF];
        final current = colors.indexOf(selected.textColor);
        selected.textColor = colors[(current + 1) % colors.length];
      } else {
        selected.rotation += 0.18;
      }
    });
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
                const Icon(
                  Icons.edit_outlined,
                  size: 16,
                  color: Color(0xFF9B8F84),
                ),
              ],
            ),
          ),
          actions: [
            TextButton.icon(
              onPressed: _preview,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Önizle'),
            ),
            const SizedBox(width: 8),
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
                    padding: const EdgeInsets.fromLTRB(28, 8, 28, 14),
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
                  onDelete: _removeSelected,
                ),
              _MainToolbar(
                onPhoto: _addPhotos,
                onText: _addText,
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
              color: Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(99),
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
    required this.onSticker,
    required this.onBackground,
    required this.onPage,
  });

  final VoidCallback onPhoto;
  final VoidCallback onText;
  final VoidCallback onSticker;
  final VoidCallback onBackground;
  final VoidCallback onPage;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF221F1D),
        border: Border(top: BorderSide(color: Colors.white10)),
      ),
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _Tool(
            icon: Icons.add_photo_alternate_outlined,
            label: 'Fotoğraf',
            onTap: onPhoto,
          ),
          _Tool(icon: Icons.text_fields_rounded, label: 'Yazı', onTap: onText),
          _Tool(
            icon: Icons.emoji_emotions_outlined,
            label: 'Sticker',
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
    );
  }
}

class _SelectionToolbar extends StatelessWidget {
  const _SelectionToolbar({
    required this.element,
    required this.onStyle,
    required this.onForward,
    required this.onDelete,
  });

  final AlbumElementModel element;
  final VoidCallback onStyle;
  final VoidCallback onForward;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final styleLabel = switch (element.type) {
      AlbumElementType.photo => 'Çerçeve',
      AlbumElementType.text => 'Renk',
      AlbumElementType.sticker => 'Döndür',
    };
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 0, 18, 8),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF312B27),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextButton.icon(
              onPressed: onStyle,
              icon: const Icon(Icons.auto_fix_high_outlined),
              label: Text(styleLabel),
            ),
          ),
          Expanded(
            child: TextButton.icon(
              onPressed: onForward,
              icon: const Icon(Icons.flip_to_front_outlined),
              label: const Text('Öne al'),
            ),
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 23),
            const SizedBox(height: 3),
            Text(label, style: const TextStyle(fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
