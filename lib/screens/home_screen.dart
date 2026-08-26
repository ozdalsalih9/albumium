import 'package:flutter/material.dart';

import '../models/album_models.dart';
import '../services/album_storage.dart';
import '../widgets/album_cover.dart';
import 'editor_screen.dart';
import 'theme_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<AlbumModel> _albums = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final albums = await AlbumStorage.instance.loadAlbums();
    if (!mounted) return;
    setState(() {
      _albums = albums;
      _loading = false;
    });
  }

  Future<void> _createAlbum() async {
    final album = await Navigator.of(
      context,
    ).push<AlbumModel>(MaterialPageRoute(builder: (_) => const ThemeScreen()));
    if (album == null || !mounted) return;
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => EditorScreen(album: album)));
    await _reload();
  }

  Future<void> _edit(AlbumModel album) async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => EditorScreen(album: album)));
    await _reload();
  }

  Future<void> _delete(AlbumModel album) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Albüm silinsin mi?'),
        content: Text('“${album.title}” bu cihazdan kaldırılacak.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await AlbumStorage.instance.deleteAlbum(album);
    await _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 14),
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFA95C),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.auto_stories_rounded,
                        color: Color(0xFF25170D),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ALBUMIUM',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.4,
                          ),
                        ),
                        Text(
                          'Anılarını sayfaya dönüştür',
                          style: TextStyle(
                            color: Color(0xFF9B8F84),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
                child: Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF32231B), Color(0xFF1E1A19)],
                    ),
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bir anı seç.\nBir kitaba dönüştür.',
                              style: TextStyle(
                                fontSize: 25,
                                height: 1.05,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(height: 10),
                            Text(
                              'Fotoğraflar, notlar ve küçük detaylarla tamamen sana ait.',
                              style: TextStyle(
                                color: Color(0xFFBEB1A6),
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      FilledButton.tonalIcon(
                        onPressed: _createAlbum,
                        icon: const Icon(Icons.add_rounded),
                        label: const Text('Başla'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 22),
                child: Text(
                  'Albümlerin',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                ),
              ),
            ),
            if (_loading)
              const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_albums.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: _EmptyState(onCreate: _createAlbum),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 100),
                sliver: SliverGrid.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.68,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 20,
                  ),
                  itemCount: _albums.length,
                  itemBuilder: (context, index) {
                    final album = _albums[index];
                    return GestureDetector(
                      onTap: () => _edit(album),
                      onLongPress: () => _delete(album),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: AlbumCover(album: album, compact: true),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            album.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            '${album.pages.length} sayfa',
                            style: const TextStyle(
                              color: Color(0xFF9B8F84),
                              fontSize: 12,
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
      floatingActionButton: _albums.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: _createAlbum,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Yeni albüm'),
            ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.collections_bookmark_outlined,
              size: 52,
              color: Color(0xFF8E8176),
            ),
            const SizedBox(height: 16),
            const Text(
              'İlk albümün burada yaşayacak',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 7),
            const Text(
              'Bir tema seçip fotoğraflarını sayfalara yerleştir.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF9B8F84)),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Albüm oluştur'),
            ),
          ],
        ),
      ),
    );
  }
}
