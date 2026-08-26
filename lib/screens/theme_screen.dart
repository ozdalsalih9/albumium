import 'package:flutter/material.dart';

import '../models/album_models.dart';
import '../services/album_storage.dart';
import '../widgets/album_cover_3d.dart';

class ThemeScreen extends StatefulWidget {
  const ThemeScreen({super.key});

  @override
  State<ThemeScreen> createState() => _ThemeScreenState();
}

class _ThemeScreenState extends State<ThemeScreen> {
  int _selected = 0;
  AlbumBindingType _selectedBinding = AlbumBindingType.spiral;
  final _titleController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _titleController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    final theme = albumThemes[_selected];
    final now = DateTime.now();
    final album = AlbumModel(
      id: newId(),
      title: _titleController.text.trim().isEmpty
          ? 'Benim Albümüm'
          : _titleController.text.trim(),
      themeId: theme.id,
      bindingType: _selectedBinding,
      createdAt: now,
      updatedAt: now,
      pages: [
        AlbumPageModel(
          id: newId(),
          backgroundColor: theme.pageColor.toARGB32(),
        ),
      ],
    );
    await AlbumStorage.instance.saveAlbum(album);
    if (mounted) Navigator.pop(context, album);
  }

  Widget _buildThemedCover(AlbumThemePreset theme, String title) {
    final displayTitle = title.isEmpty ? theme.name : title;
    final previewDate = DateTime(2026);
    final previewAlbum = AlbumModel(
      id: 'preview-${theme.id}',
      title: displayTitle,
      themeId: theme.id,
      bindingType: _selectedBinding,
      createdAt: previewDate,
      updatedAt: previewDate,
      pages: [
        AlbumPageModel(
          id: 'preview-page-${theme.id}',
          backgroundColor: theme.pageColor.toARGB32(),
        ),
      ],
    );

    return FittedBox(
      fit: BoxFit.contain,
      child: SizedBox(
        width: 300,
        height: 440,
        child: AlbumCover3D(album: previewAlbum),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).height < 740;
    final currentTitle = _titleController.text.trim();
    final selectedTheme = albumThemes[_selected];

    return Scaffold(
      appBar: AppBar(title: const Text('Albümünü Hazırla')),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(22, 6, 22, 2),
                child: Text(
                  'Hangi hikâyeyi anlatıyoruz?',
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Text(
                  '${selectedTheme.name} · ${selectedTheme.subtitle}',
                  style: TextStyle(
                    color: selectedTheme.accent,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: compact ? 220 : 280,
                child: PageView.builder(
                  controller: PageController(viewportFraction: 0.70),
                  itemCount: albumThemes.length,
                  onPageChanged: (index) => setState(() => _selected = index),
                  itemBuilder: (context, index) {
                    final theme = albumThemes[index];
                    final selected = index == _selected;
                    return AnimatedPadding(
                      duration: const Duration(milliseconds: 220),
                      padding: EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: selected ? 0 : 14,
                      ),
                      child: AnimatedScale(
                        duration: const Duration(milliseconds: 220),
                        scale: selected ? 1 : 0.94,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: _buildThemedCover(theme, currentTitle),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < albumThemes.length; i++)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        width: i == _selected ? 18 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: i == _selected
                              ? selectedTheme.accent
                              : Theme.of(context).colorScheme.outlineVariant,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              // Ciltleme Seçenekleri (Binding Styles)
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 22),
                child: Text(
                  'Ciltleme Türü',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 40,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  scrollDirection: Axis.horizontal,
                  itemCount: AlbumBindingType.values.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final binding = AlbumBindingType.values[index];
                    final isSelected = _selectedBinding == binding;
                    return ChoiceChip(
                      selected: isSelected,
                      onSelected: (_) =>
                          setState(() => _selectedBinding = binding),
                      avatar: Icon(
                        binding.icon,
                        size: 16,
                        color: isSelected
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      label: Text(binding.title),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.w800
                            : FontWeight.w500,
                        color: isSelected
                            ? Theme.of(context).colorScheme.onPrimary
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                      selectedColor: Theme.of(context).colorScheme.primary,
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 14, 22, 8),
                child: TextField(
                  controller: _titleController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    labelText: 'Albüm adı (isteğe bağlı)',
                    hintText: 'Örn. Bizim Yazımız',
                    prefixIcon: const Icon(Icons.edit_outlined),
                    suffixText: selectedTheme.emoji,
                    suffixStyle: const TextStyle(fontSize: 18),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 18),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton.icon(
                    onPressed: _continue,
                    icon: const Icon(Icons.auto_stories_rounded),
                    label: Text('${selectedTheme.name} ile Başla'),
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
