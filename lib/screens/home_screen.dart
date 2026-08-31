import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/album_models.dart';
import '../services/album_storage.dart';
import '../services/theme_controller.dart';
import '../theme/albumium_app_theme.dart';
import '../widgets/album_cover_3d.dart';
import '../widgets/album_page_canvas.dart';
import '../widgets/app_theme_picker.dart';
import '../widgets/cinematic_album_opening.dart';
import '../widgets/handmade_craft.dart';
import '../widgets/occasion_cards.dart';
import 'editor_screen.dart';
import 'special_card_studio_screen.dart';
import 'theme_screen.dart';

enum _CreationKind { album, occasionCard }

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

  Future<void> _createProject() async {
    HapticFeedback.selectionClick();
    final kind = await showModalBottomSheet<_CreationKind>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _CreationPickerSheet(),
    );
    if (kind == null || !mounted) return;
    if (kind == _CreationKind.album) {
      await _createAlbum();
      return;
    }
    final project = createSpecialCardProject();
    await AlbumStorage.instance.saveAlbum(project);
    if (!mounted) return;
    await _openAlbum(project);
  }

  Future<void> _openAlbum(AlbumModel album) async {
    HapticFeedback.lightImpact();
    if (album.projectType == AlbumProjectType.occasionCard) {
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => SpecialCardStudioScreen(project: album),
        ),
      );
      await _reload();
      return;
    }
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
        title: Text(
          album.projectType == AlbumProjectType.occasionCard
              ? 'Kart silinsin mi?'
              : 'Albüm silinsin mi?',
        ),
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
    final colors = AlbumiumAppTheme.colorsOf(context);
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
      backgroundColor: Colors.transparent,
      body: CraftBackdrop(
        variant: CraftBackdropVariant.cork,
        baseColor: colors.background,
        textureIntensity: .78,
        child: SafeArea(
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
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: PaperPanel(
                          rotationDegrees: -.7,
                          borderRadius: BorderRadius.circular(6),
                          padding: const EdgeInsets.fromLTRB(13, 11, 13, 10),
                          tapePositions: const [CraftTapePosition.topLeft],
                          tapeWidth: 43,
                          tapeHeight: 15,
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF8EC),
                                  border: Border.all(color: colors.border),
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x26000000),
                                      blurRadius: 5,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                clipBehavior: Clip.antiAlias,
                                child: Image.asset(
                                  'assets/branding/albumium_app_icon.png',
                                  fit: BoxFit.cover,
                                  filterQuality: FilterQuality.high,
                                ),
                              ),
                              const SizedBox(width: 11),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'ALBUMIUM',
                                      style: TextStyle(
                                        color: colors.text,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 1.8,
                                      ),
                                    ),
                                    Text(
                                      'Anılarını elle tutulur hikâyelere dönüştür',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: colors.mutedText,
                                        fontSize: 10.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
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
                  child: _HeroPanel(onCreate: _createProject),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: horizontalInset),
                  child: Row(
                    children: [
                      TornPaperLabel(
                        rotationDegrees: -.6,
                        padding: const EdgeInsets.fromLTRB(15, 7, 15, 8),
                        child: Text(
                          'Tasarımların',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(color: colors.text, fontSize: 25),
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
                  child: _EmptyState(onCreate: _createProject),
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
      ),
      floatingActionButton: _albums.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: _createProject,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Yeni tasarım'),
            ),
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final colors = AlbumiumAppTheme.colorsOf(context);
    return PaperPanel(
      color: colors.heroEnd,
      rotationDegrees: .45,
      borderRadius: BorderRadius.circular(7),
      padding: EdgeInsets.zero,
      tapePositions: const [
        CraftTapePosition.topRight,
        CraftTapePosition.bottomLeft,
      ],
      tapeColor: Color.lerp(colors.secondary, colors.elevatedSurface, .55),
      tapeWidth: 55,
      tapeHeight: 17,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 190),
        child: Stack(
          children: [
            Positioned(
              top: 16,
              right: 12,
              bottom: 12,
              width: 92,
              child: _MemoryScraps(colors: colors),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 21, 104, 21),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bugün hangi\nhikâyeyi anlatalım?',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: colors.text,
                      fontSize: 30,
                    ),
                  ),
                  const SizedBox(height: 9),
                  Text(
                    'Fotoğraflarını, notlarını ve küçük hatıralarını kendi albümünde bir araya getir.',
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.mutedText,
                      fontSize: 11.5,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 13),
                  StitchedBorder(
                    color: colors.onPrimary.withValues(alpha: .78),
                    inset: 3,
                    padding: EdgeInsets.zero,
                    borderRadius: BorderRadius.circular(9),
                    child: FilledButton.icon(
                      onPressed: onCreate,
                      icon: const Icon(Icons.add_rounded, size: 19),
                      label: const Text('Yeni tasarım'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MemoryScraps extends StatelessWidget {
  const _MemoryScraps({required this.colors});

  final AlbumiumThemeColors colors;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: 10,
          top: 17,
          child: Transform.rotate(
            angle: -.12,
            child: Container(
              width: 62,
              height: 80,
              padding: const EdgeInsets.fromLTRB(6, 6, 6, 18),
              decoration: BoxDecoration(
                color: colors.elevatedSurface,
                border: Border.all(color: colors.border),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33000000),
                    blurRadius: 6,
                    offset: Offset(3, 5),
                  ),
                ],
              ),
              child: ColoredBox(
                color: colors.primary.withValues(alpha: .17),
                child: Icon(
                  Icons.photo_camera_back_outlined,
                  color: colors.primary,
                  size: 23,
                ),
              ),
            ),
          ),
        ),
        Positioned(
          right: 0,
          bottom: 7,
          child: Transform.rotate(
            angle: .10,
            child: TornPaperLabel(
              color: Color.lerp(colors.surface, colors.secondary, .12),
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
              edgeDepth: 2.3,
              child: Text(
                'anı\ndefteri',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: colors.text,
                  fontSize: 18,
                  height: .86,
                ),
              ),
            ),
          ),
        ),
        Positioned(
          right: 10,
          top: 0,
          child: Icon(
            Icons.push_pin_rounded,
            color: colors.primary,
            size: 23,
            shadows: const [Shadow(color: Colors.black38, blurRadius: 3)],
          ),
        ),
      ],
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
      child: PaperPanel(
        rotationDegrees: .9,
        padding: EdgeInsets.zero,
        borderRadius: BorderRadius.circular(9),
        textureIntensity: .18,
        child: IconButton(
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
    final colors = AlbumiumAppTheme.colorsOf(context);
    final isCard = album.projectType == AlbumProjectType.occasionCard;
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
      child: PaperPanel(
        rotationDegrees: index.isEven ? -.8 : .75,
        borderRadius: BorderRadius.circular(5),
        padding: const EdgeInsets.fromLTRB(8, 13, 8, 9),
        tapePositions: const [CraftTapePosition.topCenter],
        tapeWidth: 44,
        tapeHeight: 14,
        textureIntensity: .2,
        child: Semantics(
          button: true,
          label: isCard
              ? '${album.title}, özel gün kartı'
              : '${album.title}, ${album.pages.length} sayfa',
          child: InkWell(
            onTap: onTap,
            onLongPress: onLongPress,
            borderRadius: BorderRadius.circular(4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 3, bottom: 2),
                    child: isCard
                        ? _SpecialCardThumbnail(project: album)
                        : AlbumCover3D(album: album, compact: true),
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  album.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: colors.text,
                    fontSize: 19,
                    height: .95,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  isCard
                      ? 'Özel gün kartı · ${occasionTemplateById(album.cardThemeId).badge}'
                      : '${album.pages.length} sayfa · ${album.bindingType.title}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: colors.mutedText, fontSize: 9.5),
                ),
              ],
            ),
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
    final colors = AlbumiumAppTheme.colorsOf(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(34, 28, 34, 55),
        child: PaperPanel(
          rotationDegrees: -.65,
          borderRadius: BorderRadius.circular(6),
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 17),
          tapePositions: const [
            CraftTapePosition.topLeft,
            CraftTapePosition.bottomRight,
          ],
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 68,
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 15),
                decoration: BoxDecoration(
                  color: colors.elevatedSurface,
                  border: Border.all(color: colors.border),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x29000000),
                      blurRadius: 6,
                      offset: Offset(3, 5),
                    ),
                  ],
                ),
                child: ColoredBox(
                  color: colors.glow,
                  child: Icon(
                    Icons.collections_bookmark_outlined,
                    size: 31,
                    color: colors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 11),
              Text(
                'İlk tasarımın burada yaşayacak',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: colors.text,
                  fontSize: 24,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: onCreate,
                icon: const Icon(Icons.auto_awesome),
                label: const Text('Tasarım oluştur'),
              ),
              const StitchedDivider(height: 12),
              Text(
                'Gerçek bir albüm oluştur veya temalı bir özel gün kartı tasarla.',
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.mutedText, height: 1.35),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreationPickerSheet extends StatelessWidget {
  const _CreationPickerSheet();

  @override
  Widget build(BuildContext context) {
    final colors = AlbumiumAppTheme.colorsOf(context);
    final tablet = MediaQuery.sizeOf(context).shortestSide >= 600;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TornPaperLabel(
                rotationDegrees: -.45,
                padding: const EdgeInsets.fromLTRB(14, 7, 14, 8),
                child: Text(
                  'Ne tasarlamak istersin?',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: colors.text,
                    fontSize: 28,
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Her iki tasarım da kaydedilir; fotoğraf, yazı, süs ve şekillerle kişiselleştirilebilir.',
                style: TextStyle(color: colors.mutedText, height: 1.35),
              ),
              const SizedBox(height: 17),
              if (tablet)
                Row(
                  children: [
                    Expanded(
                      child: _CreationChoice(
                        icon: Icons.auto_stories_rounded,
                        title: 'Fiziksel Albüm',
                        subtitle: 'Kapak, cilt ve gerçekçi çevrilen sayfalar',
                        colors: [colors.primary, colors.secondary],
                        onTap: () =>
                            Navigator.pop(context, _CreationKind.album),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _CreationChoice(
                        icon: Icons.mark_email_read_rounded,
                        title: 'Özel Gün Kartı',
                        subtitle: 'Tema seç, özgürce tasarla ve PNG paylaş',
                        colors: const [Color(0xFFE9A4B5), Color(0xFF9C5270)],
                        onTap: () =>
                            Navigator.pop(context, _CreationKind.occasionCard),
                      ),
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    _CreationChoice(
                      icon: Icons.auto_stories_rounded,
                      title: 'Fiziksel Albüm',
                      subtitle: 'Kapak, cilt ve gerçekçi çevrilen sayfalar',
                      colors: [colors.primary, colors.secondary],
                      onTap: () => Navigator.pop(context, _CreationKind.album),
                    ),
                    const SizedBox(height: 11),
                    _CreationChoice(
                      icon: Icons.mark_email_read_rounded,
                      title: 'Özel Gün Kartı',
                      subtitle: 'Tema seç, özgürce tasarla ve PNG paylaş',
                      colors: const [Color(0xFFE9A4B5), Color(0xFF9C5270)],
                      onTap: () =>
                          Navigator.pop(context, _CreationKind.occasionCard),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CreationChoice extends StatelessWidget {
  const _CreationChoice({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.colors,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<Color> colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PaperPanel(
      borderRadius: BorderRadius.circular(7),
      padding: EdgeInsets.zero,
      rotationDegrees: title == 'Fiziksel Albüm' ? -.35 : .35,
      tapePositions: const [CraftTapePosition.topRight],
      tapeColor: Color.lerp(colors.first, Colors.white, .52),
      tapeWidth: 45,
      tapeHeight: 14,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(7),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 112),
          child: Padding(
            padding: const EdgeInsets.all(17),
            child: Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: colors.first.withValues(alpha: .18),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: colors.first.withValues(alpha: .52),
                    ),
                  ),
                  child: Icon(icon, color: colors.first, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 21,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(fontSize: 11.5, height: 1.25),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: colors.first,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SpecialCardThumbnail extends StatelessWidget {
  const _SpecialCardThumbnail({required this.project});

  final AlbumModel project;

  @override
  Widget build(BuildContext context) {
    final template = occasionTemplateById(project.cardThemeId);
    if (project.pages.isEmpty) {
      return OccasionCardView(cardId: template.id);
    }
    return Center(
      child: AspectRatio(
        aspectRatio: 5 / 7,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: const [
              BoxShadow(
                color: Color(0x55000000),
                blurRadius: 18,
                offset: Offset(7, 12),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: IgnorePointer(
              child: AlbumPageCanvas(
                page: project.pages.first,
                theme: specialCardThemeFor(template),
                showPageNumber: false,
              ),
            ),
          ),
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
    final colors = AlbumiumAppTheme.colorsOf(context);
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
