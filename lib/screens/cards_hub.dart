import 'package:flutter/material.dart';
import '../l10n/albumium_localizations.dart';
import '../models/album_models.dart';
import '../services/album_storage.dart';
import '../services/card_template_storage.dart';
import '../widgets/occasion_cards.dart';
import '../widgets/album_page_canvas.dart';
import 'special_card_studio_screen.dart';

class CardsHub extends StatefulWidget {
  const CardsHub({super.key});
  @override
  State<CardsHub> createState() => _CardsHubState();
}

class _CardsHubState extends State<CardsHub> {
  List<AlbumModel> _cards = [], _templates = [];
  String? _category;
  bool _failed = false;
  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final cards = await AlbumStorage.instance.loadAlbums();
      final templates = await CardTemplateStorage.load();
      if (mounted) {
        setState(() {
          _cards = cards
              .where((c) => c.projectType == AlbumProjectType.occasionCard)
              .toList();
          _templates = templates;
          _failed = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  Future<void> _open(AlbumModel card, {bool save = false}) async {
    try {
      if (save) await AlbumStorage.instance.saveAlbum(card);
      if (!mounted) return;
      await Navigator.push<void>(
        context,
        MaterialPageRoute(
          builder: (_) => SpecialCardStudioScreen(project: card),
        ),
      );
      await _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('Kaydedilemedi. Tekrar dene.'))),
        );
      }
    }
  }

  Future<void> _delete(AlbumModel card, bool template) async {
    final yes = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.tr('Sil?')),
        content: Text(card.title),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.tr('Vazgeç')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.tr('Sil')),
          ),
        ],
      ),
    );
    if (yes != true) return;
    try {
      if (template) {
        await CardTemplateStorage.delete(card.id);
      } else {
        await AlbumStorage.instance.deleteAlbum(card);
      }
      await _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.tr('Kaydedilemedi. Tekrar dene.'))),
        );
      }
    }
  }

  Widget _grid(
    List<AlbumModel> cards, {
    bool template = false,
    bool catalog = false,
  }) {
    if (cards.isEmpty) {
      return Center(child: Text(context.tr('İlk tasarımını oluştur')));
    }
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 240,
        mainAxisExtent: 320,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
      ),
      itemCount: cards.length,
      itemBuilder: (context, i) {
        final card = cards[i];
        return Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => _open(
              template ? cloneCard(card) : card,
              save: template || catalog,
            ),
            child: Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: AspectRatio(
                      aspectRatio: 5 / 7,
                      child: IgnorePointer(
                        child: AlbumPageCanvas(
                          page: card.pages.isEmpty
                              ? createSpecialCardProject(
                                  template: occasionTemplateById(
                                    card.cardThemeId,
                                  ),
                                ).pages.first
                              : card.pages.first,
                          theme: specialCardThemeFor(
                            occasionTemplateById(card.cardThemeId),
                          ),
                          showPageNumber: false,
                        ),
                      ),
                    ),
                  ),
                ),
                ListTile(
                  dense: true,
                  title: Text(
                    card.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: catalog
                      ? null
                      : IconButton(
                          tooltip: context.tr('Sil'),
                          onPressed: () => _delete(card, template),
                          icon: const Icon(Icons.delete_outline),
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) => DefaultTabController(
    length: 3,
    child: SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    context.tr('Kartlar'),
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                TextButton.icon(
                  onPressed: () => _open(
                    createSpecialCardProject(
                      template: blankCardTemplate,
                      translate: context.tr,
                    ),
                    save: true,
                  ),
                  icon: const Icon(Icons.add),
                  label: Text(context.tr('Boş tuval')),
                ),
              ],
            ),
          ),
          TabBar(
            tabs: [
              Tab(text: context.tr('Temalar')),
              Tab(text: context.tr('Kartlarım')),
              Tab(text: context.tr('Şablonlarım')),
            ],
          ),
          if (_failed)
            TextButton(
              onPressed: _load,
              child: Text(context.tr('Yüklenemedi. Tekrar dene.')),
            ),
          Expanded(
            child: TabBarView(
              children: [
                Column(
                  children: [
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(context.tr('Tümü')),
                              selected: _category == null,
                              onSelected: (_) =>
                                  setState(() => _category = null),
                            ),
                          ),
                          for (final category
                              in occasionCardTemplates
                                  .map((t) => t.category)
                                  .toSet())
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(context.tr(category)),
                                selected: _category == category,
                                onSelected: (_) =>
                                    setState(() => _category = category),
                              ),
                            ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _grid(
                        occasionCardTemplates
                            .where(
                              (t) =>
                                  _category == null || t.category == _category,
                            )
                            .map(
                              (t) => createSpecialCardProject(
                                template: t,
                                translate: context.tr,
                              ),
                            )
                            .toList(),
                        catalog: true,
                      ),
                    ),
                  ],
                ),
                _grid(_cards),
                _grid(_templates, template: true),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
