import 'package:flutter/material.dart';
import 'album_models.dart';

class ScrapbookTemplate {
  const ScrapbookTemplate(
    this.id,
    this.title,
    this.subtitle,
    this.pattern,
    this.color,
  );
  final String id, title, subtitle, pattern;
  final int color;
}

const scrapbookTemplates = [
  ScrapbookTemplate(
    'denim',
    'Denim anılar',
    'Kot cebi, dantel ve film şeridi',
    'linen',
    0xFFE9E3D1,
  ),
  ScrapbookTemplate(
    'western',
    'Western hatıra',
    'Bordo, krem ve kovboy detayları',
    'linen',
    0xFFF0E7D6,
  ),
  ScrapbookTemplate(
    'fabric',
    'Kumaş pano',
    'Puantiyeler, düğmeler ve yıldızlar',
    'navydots',
    0xFF1E304A,
  ),
  ScrapbookTemplate(
    'botanical',
    'Yeşil botanik',
    'Ekose, dantel ve küçük dallar',
    'crumpled',
    0xFF76805B,
  ),
  ScrapbookTemplate(
    'ribbon',
    'Kırmızı kurdele',
    'Tartan, krem dantel ve fiyonklar',
    'redplaid',
    0xFFEAE1C9,
  ),
  ScrapbookTemplate(
    'birthday',
    'Renkli doğum günü',
    'Ekose kolaj ve neşeli hatıralar',
    'patchwork',
    0xFFEAE9D2,
  ),
  ScrapbookTemplate(
    'vinyl',
    'Plaklı anılar',
    'Keten, yeşil plak ve çiçekler',
    'linen',
    0xFFEDE5D6,
  ),
];

ScrapbookTemplate? scrapbookTemplateById(String id) {
  if (!id.startsWith('scrapbook_')) return null;
  final key = id.substring(10);
  for (final template in scrapbookTemplates) {
    if (template.id == key) return template;
  }
  return null;
}

/// All layout pieces remain ordinary editable objects, including empty photo slots.
AlbumPageModel createScrapbookPage(
  ScrapbookTemplate t, {
  String Function(String)? translate,
}) {
  final tr = translate ?? (String s) => s;
  final elements = <AlbumElementModel>[];
  void art(
    String key,
    double x,
    double y,
    double w,
    double h, [
    double rotation = 0,
  ]) {
    elements.add(
      AlbumElementModel(
        id: 'scrap-decor-${newId()}',
        type: AlbumElementType.sticker,
        content: key.startsWith('paperkit_')
            ? 'albumium:$key'
            : 'albumium:scrap_$key',
        x: x,
        y: y,
        width: w,
        height: h,
        rotation: rotation,
      ),
    );
  }

  void photo(
    double x,
    double y,
    double w,
    double h,
    int frame, [
    double rotation = 0,
  ]) {
    elements.add(
      AlbumElementModel(
        id: 'scrap-photo-${newId()}',
        type: AlbumElementType.photo,
        content: '',
        photoSlot: true,
        photoFit: BoxFit.cover,
        x: x,
        y: y,
        width: w,
        height: h,
        frameStyle: frame,
        rotation: rotation,
        frameScale: .65,
      ),
    );
  }

  void text(
    String value,
    double x,
    double y,
    double w,
    double h,
    double size,
    int color, [
    String font = 'Marcellus',
  ]) {
    elements.add(
      AlbumElementModel(
        id: 'scrap-text-${newId()}',
        type: AlbumElementType.text,
        content: tr(value),
        x: x,
        y: y,
        width: w,
        height: h,
        fontSize: size,
        textColor: color,
        extraData: font,
      ),
    );
  }

  switch (t.id) {
    case 'denim':
      art('denim_strip', -.07, -.03, .49, 1.05);
      art('lace_strip', .31, -.01, .12, 1.02);
      art('paperkit_paper_ledger', .44, .05, .51, .62, .07);
      text('HATIRA ARŞİVİ', .45, .035, .49, .065, 20, 0xFF373B3B);
      for (var i = 0; i < 3; i++) {
        photo(.22, .16 + i * .17, .50, .16, 7, -.08);
      }
      art('pocket', .21, .66, .64, .30, -.07);
      art('button_gold', .18, .64, .09, .065);
      text('Biriktirdiğim anlar', .32, .77, .40, .07, 16, 0xFFE8DBC1);
    case 'western':
      art('burgundy_strip', -.02, 0, .22, 1);
      text('WILD MEMORIES', .25, .04, .67, .06, 25, 0xFF6F3930);
      art('ticket', .23, .13, .61, .13, .04);
      art('hat', .02, .08, .35, .15, -.23);
      for (var i = 0; i < 3; i++) {
        photo(.30, .30 + i * .185, .56, .175, 10);
      }
      art('music', .01, .56, .27, .24, -.25);
      art('paperkit_corner_ledger', .02, .84, .29, .15, .12);
      art('hat', .75, .23, .21, .10, .14);
      text('Yolun hikâyesi', .30, .90, .57, .05, 19, 0xFF6F3930);
    case 'fabric':
      art('lime_panel', .09, .17, .82, .64, -.02);
      photo(.16, .23, .68, .49, 0, -.02);
      art('star_navy', .01, .08, .31, .22, -.2);
      art('button_green', .76, .11, .17, .12, .1);
      art('button_blue', .06, .75, .14, .10);
      art('button_blue', .14, .81, .10, .07);
      text('Küçük mutluluklar', .19, .74, .57, .05, 20, 0xFF283C34);
    case 'botanical':
      art('sage_strip', -.07, 0, .29, 1);
      art('lace_strip', .17, 0, .12, 1);
      photo(.34, .07, .58, .23, 18, -.10);
      photo(.31, .36, .59, .23, 18, .07);
      photo(.32, .67, .61, .24, 18, -.07);
      art('star_sage', .20, .015, .20, .13, -.1);
      art('bow_sage', .25, .53, .24, .12, -.15);
      art('tree', .05, .72, .30, .26);
      art('leaf', .78, .29, .18, .15, .5);
    case 'ribbon':
      art('paperkit_note_lace', .04, .07, .92, .85);
      photo(.19, .23, .62, .43, 0);
      text(
        'Sevgiyle sakladım',
        .19,
        .70,
        .62,
        .10,
        24,
        0xFF873C48,
        'Cormorant Garamond',
      );
      for (var i = 0; i < 4; i++) {
        art('bow_red', .03, .10 + i * .23, .17, .10, -.1);
        art('bow_red', .80, .10 + i * .23, .17, .10, .1);
      }
    case 'birthday':
      art('blue_panel', .15, .17, .70, .70);
      text('HAPPY', .16, .045, .42, .065, 29, 0xFFC5573D);
      text('BIRTHDAY', .30, .115, .56, .055, 24, 0xFF31544A);
      photo(.24, .26, .53, .22, 17);
      photo(.24, .54, .53, .22, 17);
      art('strawberry', .01, .02, .18, .13, -.2);
      art('strawberry', .78, .77, .19, .14, .3);
      art('star_gold', .02, .75, .18, .12, .3);
      art('button_green', .78, .20, .14, .10);
      art('bow_red', .03, .42, .21, .11, -.3);
      art('ticket', .18, .87, .65, .095, -.03);
    case 'vinyl':
      art('sage_strip', .58, -.01, .43, 1.02);
      art('vinyl', -.20, .30, .99, .70, -.08);
      text('SIDE A / ANILAR', .05, .06, .57, .06, 22, 0xFF5C674C);
      for (var i = 0; i < 3; i++) {
        photo(.53, .23 + i * .19, .42, .18, 7);
      }
      art('star_sage', .33, .14, .17, .13, -.2);
      art('star_pink', .01, .27, .27, .18, .12);
      art('lily', .02, .76, .48, .23, -.2);
      text('Bizim şarkımız', .08, .90, .48, .05, 18, 0xFF805A64);
  }
  return AlbumPageModel(
    id: newId(),
    backgroundColor: t.color,
    paperPattern: t.pattern,
    elements: elements,
  );
}

/// Re-theme a card without losing filled photos or user-added objects.
void applyScrapbookToPage(
  AlbumPageModel page,
  ScrapbookTemplate template, {
  String Function(String)? translate,
  Set<String> replaceableTextIds = const {},
}) {
  final next = createScrapbookPage(template, translate: translate);
  final photos = page.elements
      .where(
        (e) =>
            !e.locked &&
            e.type == AlbumElementType.photo &&
            e.content.isNotEmpty,
      )
      .toList();
  final slots = next.elements.where((e) => e.photoSlot).toList();
  for (var i = 0; i < photos.length && i < slots.length; i++) {
    slots[i]
      ..content = photos[i].content
      ..photoCrop = photos[i].photoCrop
      ..photoFit = photos[i].photoFit;
  }
  bool isCaption(AlbumElementModel e) =>
      e.id.startsWith('scrap-text-') ||
      e.id.startsWith('card-title-') ||
      e.id.startsWith('card-message-') ||
      e.id.startsWith('card-badge-');
  final extras = page.elements
      .where(
        (e) =>
            e.locked ||
            (!replaceableTextIds.contains(e.id) &&
                !isCaption(e) &&
                !e.id.startsWith('scrap-') &&
                !e.photoSlot &&
                e.type != AlbumElementType.photo),
      )
      .toList();
  // Preserve edited captions as well; generated captions have a distinct role.
  final captions = page.elements
      .where(
        (e) => !e.locked && isCaption(e) && !replaceableTextIds.contains(e.id),
      )
      .toList();
  final nextCaptions = next.elements
      .where((e) => e.id.startsWith('scrap-text-'))
      .toList();
  for (var i = 0; i < captions.length; i++) {
    if (i < nextCaptions.length) {
      nextCaptions[i].content = captions[i].content;
    } else {
      extras.add(captions[i]);
    }
  }
  page
    ..paperPattern = next.paperPattern
    ..backgroundColor = next.backgroundColor;
  page.elements
    ..clear()
    ..addAll(next.elements)
    ..addAll(photos.skip(slots.length))
    ..addAll(extras);
}
