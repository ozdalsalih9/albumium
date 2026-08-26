import 'package:flutter/material.dart';

import '../models/album_models.dart';
import '../services/album_storage.dart';

class ThemeScreen extends StatefulWidget {
  const ThemeScreen({super.key});

  @override
  State<ThemeScreen> createState() => _ThemeScreenState();
}

class _ThemeScreenState extends State<ThemeScreen> {
  int _selected = 0;
  final _titleController = TextEditingController();

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

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).height < 720;
    return Scaffold(
      appBar: AppBar(title: const Text('Albümünü hazırla')),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(22, 8, 22, 4),
              child: Text(
                'Hangi hikâyeyi anlatıyoruz?',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.6,
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 22),
              child: Text(
                'Başlangıç stilini seç. Her ayrıntıyı sonra değiştirebilirsin.',
                style: TextStyle(color: Color(0xFF9B8F84)),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: compact ? 238 : 322,
              child: PageView.builder(
                controller: PageController(viewportFraction: 0.72),
                itemCount: albumThemes.length,
                onPageChanged: (index) => setState(() => _selected = index),
                itemBuilder: (context, index) {
                  final theme = albumThemes[index];
                  final selected = index == _selected;
                  return AnimatedPadding(
                    duration: const Duration(milliseconds: 220),
                    padding: EdgeInsets.fromLTRB(
                      7,
                      selected ? 0 : 18,
                      7,
                      selected ? 0 : 18,
                    ),
                    child: AnimatedScale(
                      duration: const Duration(milliseconds: 220),
                      scale: selected ? 1 : 0.95,
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [theme.coverStart, theme.coverEnd],
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: theme.coverEnd.withValues(alpha: 0.45),
                              blurRadius: 18,
                              offset: const Offset(6, 10),
                            ),
                          ],
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              left: 0,
                              top: 0,
                              bottom: 0,
                              width: 18,
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: Colors.black26,
                                  borderRadius: const BorderRadius.horizontal(
                                    left: Radius.circular(20),
                                  ),
                                ),
                              ),
                            ),
                            Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    theme.emoji,
                                    style: const TextStyle(fontSize: 38),
                                  ),
                                  const SizedBox(height: 18),
                                  Text(
                                    theme.name,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 23,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    theme.subtitle,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 6,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black26,
                                      borderRadius: BorderRadius.circular(99),
                                    ),
                                    child: Text(
                                      '${theme.textureLabel} kapak',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 20, 22, 8),
              child: TextField(
                controller: _titleController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  labelText: 'Albüm adı (şimdilik)',
                  hintText: 'Örn. Bizim Yazımız',
                  prefixIcon: Icon(Icons.edit_outlined),
                ),
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(22),
              child: SizedBox(
                width: double.infinity,
                height: 54,
                child: FilledButton.icon(
                  onPressed: _continue,
                  icon: const Icon(Icons.auto_stories_rounded),
                  label: const Text('Kitabı aç'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
