import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/album_models.dart';
import '../services/album_storage.dart';
import '../services/theme_controller.dart';
import '../theme/albumium_app_theme.dart';
import '../widgets/album_cover_3d.dart';
import '../widgets/app_theme_picker.dart';
import '../widgets/cinematic_album_opening.dart';
import 'editor_screen.dart';
import 'theme_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.themeController});

  final ThemeController themeController;

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
    HapticFeedback.selectionClick();
    final album = await Navigator.of(
      context,
    ).push<AlbumModel>(MaterialPageRoute(builder: (_) => const ThemeScreen()));
    if (album == null || !mounted) return;
    await _openAlbum(album);
  }

  Future<void> _openAlbum(AlbumModel album) async {
    HapticFeedback.lightImpact();
    await Navigator.of(context).push<void>(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 430),
        reverseTransitionDuration: const Duration(milliseconds: 320),
        pageBuilder: (_, _, _) => _CinematicOpeningScreen(album: album),
        transitionsBuilder: (_, animation, _, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween(begin: 0.985, end: 1.0).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
    await _reload();
  }

  Future<void> _delete(AlbumModel album) async {
    HapticFeedback.mediumImpact();
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
    final colors = Theme.of(context).extension<AlbumiumThemeColors>()!;
    final viewportWidth = MediaQuery.sizeOf(context).width;
    final horizontalInset = viewportWidth > 1244
        ? (viewportWidth - 1200) / 2 + 22
        : 22.0;
    final albumColumns = viewportWidth >= 1100
        ? 4
        : viewportWidth >= 700
        ? 3
        : 2;
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  horizontalInset,
                  18,
                  horizontalInset,
                  10,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 47,
                      height: 47,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [colors.primary, colors.secondary],
                        ),
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: colors.glow,
                            blurRadius: 18,
                            offset: const Offset(0, 7),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.auto_stories_rounded,
                        color: colors.onPrimary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ALBUMIUM',
                            style: TextStyle(
                              color: colors.text,
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                            ),
                          ),
                          Text(
                            'Anılarını yaşayan kitaplara dönüştür',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colors.mutedText,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _PaletteButton(
                      controller: widget.themeController,
                      onTap: () => showAlbumiumThemePicker(
                        context,
                        widget.themeController,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  horizontalInset,
                  13,
                  horizontalInset,
                  27,
                ),
                child: _HeroPanel(onCreate: _createAlbum),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalInset),
                child: Row(
                  children: [
                    Text(
                      'Albümlerin',
                      style: TextStyle(
                        color: colors.text,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    if (_albums.isNotEmpty) ...[
                      const SizedBox(width: 9),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 9,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colors.glow,
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          '${_albums.length}',
                          style: TextStyle(
                            color: colors.primary,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                    const Spacer(),
                    if (_albums.isNotEmpty)
                      Text(
                        'Silmek için basılı tut',
                        style: TextStyle(
                          color: colors.mutedText,
                          fontSize: 10.5,
                        ),
                      ),
                  ],
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
                padding: EdgeInsets.fromLTRB(
                  horizontalInset,
                  19,
                  horizontalInset,
                  112,
                ),
                sliver: SliverGrid.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: albumColumns,
                    childAspectRatio: 0.61,
                    crossAxisSpacing: 17,
                    mainAxisSpacing: 23,
                  ),
                  itemCount: _albums.length,
                  itemBuilder: (context, index) {
                    final album = _albums[index];
                    return _AlbumGridItem(
                      album: album,
                      index: index,
                      onTap: () => _openAlbum(album),
                      onLongPress: () => _delete(album),
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

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AlbumiumThemeColors>()!;
    return Container(
      constraints: const BoxConstraints(minHeight: 174),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.heroStart, colors.heroEnd],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: colors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -37,
            top: -46,
            child: Container(
              width: 165,
              height: 165,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.primary.withValues(alpha: 0.11),
                boxShadow: [
                  BoxShadow(
                    color: colors.glow,
                    blurRadius: 46,
                    spreadRadius: 8,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            right: 23,
            top: 26,
            child: Transform.rotate(
              angle: 0.10,
              child: Container(
                width: 62,
                height: 86,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [colors.primary, colors.secondary],
                  ),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.22),
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x66000000),
                      blurRadius: 15,
                      offset: Offset(7, 9),
                    ),
                  ],
                ),
                child: Icon(
                  Icons.auto_awesome_rounded,
                  color: colors.onPrimary.withValues(alpha: 0.86),
                  size: 25,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(21, 21, 86, 21),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bir anı seç.\nBir kitaba dönüştür.',
                  style: TextStyle(
                    color: colors.text,
                    fontSize: 24,
                    height: 1.04,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.75,
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  'Fotoğraf, not ve küçük detaylarla tamamen sana ait.',
                  maxLines: 2,
                  style: TextStyle(
                    color: colors.mutedText,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 14),
                FilledButton.icon(
                  onPressed: onCreate,
                  icon: const Icon(Icons.add_rounded, size: 19),
                  label: const Text('Yeni hikâye'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PaletteButton extends StatelessWidget {
  const _PaletteButton({required this.controller, required this.onTap});

  final ThemeController controller;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final option = controller.selectedOption;
    return Tooltip(
      message: 'Uygulama temasını değiştir',
      child: IconButton.filledTonal(
        onPressed: onTap,
        icon: Stack(
          clipBehavior: Clip.none,
          children: [
            const Icon(Icons.palette_outlined),
            Positioned(
              right: -3,
              bottom: -3,
              child: Container(
                width: 11,
                height: 11,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: option.previewColors.first,
                  border: Border.all(
                    color: Theme.of(context).colorScheme.surface,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlbumGridItem extends StatelessWidget {
  const _AlbumGridItem({
    required this.album,
    required this.index,
    required this.onTap,
    required this.onLongPress,
  });

  final AlbumModel album;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AlbumiumThemeColors>()!;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 460 + (index.clamp(0, 5) * 75)),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Opacity(
          opacity: value.clamp(0, 1),
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 22),
            child: Transform.scale(scale: 0.94 + value * 0.06, child: child),
          ),
        );
      },
      child: Semantics(
        button: true,
        label: '${album.title}, ${album.pages.length} sayfa',
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 5, bottom: 3),
                  child: AlbumCover3D(album: album, compact: true),
                ),
              ),
              const SizedBox(height: 9),
              Text(
                album.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.text,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${album.pages.length} sayfa · ${album.bindingType.title}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: colors.mutedText, fontSize: 10.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AlbumiumThemeColors>()!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(40, 28, 40, 55),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: colors.glow,
                shape: BoxShape.circle,
                border: Border.all(color: colors.border),
              ),
              child: Icon(
                Icons.collections_bookmark_outlined,
                size: 34,
                color: colors.primary,
              ),
            ),
            const SizedBox(height: 17),
            Text(
              'İlk albümün burada yaşayacak',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.text,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              'Bir kapak seç; fotoğraflarını gerçek bir kitabın sayfalarına yerleştir.',
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.mutedText, height: 1.35),
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

class _CinematicOpeningScreen extends StatefulWidget {
  const _CinematicOpeningScreen({required this.album});

  final AlbumModel album;

  @override
  State<_CinematicOpeningScreen> createState() =>
      _CinematicOpeningScreenState();
}

class _CinematicOpeningScreenState extends State<_CinematicOpeningScreen> {
  bool _enteringEditor = false;

  void _enterEditor() {
    if (_enteringEditor || !mounted) return;
    _enteringEditor = true;
    HapticFeedback.selectionClick();
    Navigator.of(context).pushReplacement<void, void>(
      PageRouteBuilder<void>(
        transitionDuration: const Duration(milliseconds: 520),
        pageBuilder: (_, _, _) => EditorScreen(album: widget.album),
        transitionsBuilder: (_, animation, _, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween(begin: 1.018, end: 1.0).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AlbumiumThemeColors>()!;
    return Scaffold(
      backgroundColor: colors.background,
      body: Stack(
        children: [
          Positioned.fill(
            child: CinematicAlbumOpening(
              album: widget.album,
              backgroundColor: colors.background,
              onCompleted: _enterEditor,
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton.filledTonal(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded),
                        tooltip: 'Kapat',
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: _enterEditor,
                        child: const Text('Geç'),
                      ),
                    ],
                  ),
                  const Spacer(),
                  AnimatedOpacity(
                    opacity: _enteringEditor ? 0 : 1,
                    duration: const Duration(milliseconds: 180),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: colors.surface.withValues(alpha: 0.76),
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(color: colors.border),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 13,
                            height: 13,
                            child: CircularProgressIndicator(
                              strokeWidth: 1.6,
                              color: colors.primary,
                            ),
                          ),
                          const SizedBox(width: 9),
                          Text(
                            'Hikâyen açılıyor',
                            style: TextStyle(
                              color: colors.text,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
