import 'dart:math' as math;

import 'package:flutter/material.dart';

const _illustratedPrefix = 'albumium:';
const _assetPrefix = 'albumium_asset:';
const _shapePrefix = 'albumium_shape:';

bool isIllustratedSticker(String value) =>
    value.startsWith(_illustratedPrefix) ||
    value.startsWith(_assetPrefix) ||
    value.startsWith(_shapePrefix);

bool isAlbumStickerAsset(String value) => value.startsWith(_assetPrefix);
bool isAlbumShape(String value) => value.startsWith(_shapePrefix);

String albumStickerAssetPath(String value) =>
    value.substring(_assetPrefix.length);

/// The intended on-page pixel ratio of sticker artwork. Album element
/// bounds are stored as page-relative fractions, so their raw width/height
/// cannot be used as a visual aspect ratio on a 9:14 page.
double albumStickerAspectRatio(String value) {
  if (isAlbumStickerAsset(value)) {
    return switch (albumStickerAssetPath(value)) {
      'assets/stickers/botanical_keepsake.png' => .67,
      'assets/stickers/celestial_keepsake.png' => .96,
      'assets/stickers/romance_keepsake.png' => 1.16,
      'assets/stickers/photo_keepsake.png' => 1.09,
      'assets/stickers/cafe_keepsake.png' => 1.16,
      'assets/stickers/friendship_keepsake.png' => 1.09,
      'assets/stickers/cozy_reading_keepsake.png' => 1.08,
      _ => 1,
    };
  }
  if (isAlbumShape(value)) return value.contains(':heart_') ? 1.08 : 1;
  if (value.contains('washi_') ||
      value.endsWith(':film_strip') ||
      value.contains('ribbon_')) {
    return 3.6;
  }
  if (value.endsWith(':vintage_ticket')) return 2.2;
  if (value.contains('pressed_') ||
      value.endsWith(':fern') ||
      value.endsWith(':gold_branch')) {
    return .68;
  }
  if (value.contains('postage_')) return .9;
  if (value.contains('frame_') || value.contains('camera_')) return 1;
  if (value.contains('corner_') ||
      value.contains('disco_') ||
      value.contains('button_')) {
    return 1;
  }
  if (value.endsWith('fabric_lace')) return 2.5;
  if (value.endsWith('fabric_bow')) return 1.45;
  if (value.endsWith('fabric_safety_pin')) return .82;
  if (value.contains('fabric_')) return 1.1;
  if (value.endsWith('analog_polaroid')) return .82;
  if (value.endsWith('analog_film_roll')) return 1.08;
  if (value.endsWith('analog_negative')) return 2.25;
  if (value.endsWith('analog_camcorder') || value.endsWith('analog_cassette')) {
    return 1.35;
  }
  if (value.contains('words_')) return 2.15;
  if (value.contains('travel_passport')) return .72;
  if (value.contains('travel_suitcase') ||
      value.contains('travel_airplane_tag') ||
      value.contains('travel_map')) {
    return 1.25;
  }
  if (value.contains('cat_') || value.contains('monkey_')) return .82;
  return 1;
}

String albumStickerLabel(String value) => switch (value) {
  'albumium:washi_blush' => 'Pudra washi bant',
  'albumium:washi_sage' => 'Adaçayı washi bant',
  'albumium:washi_script' => 'El yazılı washi bant',
  'albumium:film_strip' => 'Analog film şeridi',
  'albumium:ribbon_blush' => 'Pudra kurdele',
  'albumium:ribbon_navy' => 'Lacivert kurdele',
  'albumium:pressed_lavender' => 'Preslenmiş lavanta',
  'albumium:pressed_daisy' => 'Preslenmiş papatya',
  'albumium:pressed_rose' => 'Preslenmiş gül',
  'albumium:fern' => 'Botanik eğrelti',
  'albumium:gold_branch' => 'Altın dal',
  'albumium:postage_rose' => 'Gül posta pulu',
  'albumium:postage_airmail' => 'Hava postası pulu',
  'albumium:wax_burgundy' => 'Bordo mum mühür',
  'albumium:wax_gold' => 'Altın mum mühür',
  'albumium:vintage_ticket' => 'Vintage bilet',
  'albumium:star_doodle' => 'Yıldız çizimi',
  'albumium:frame_gold_rect' => 'Altın işlemeli çerçeve',
  'albumium:frame_gold_oval' => 'Altın oval çerçeve',
  'albumium:frame_silver_heart' => 'Gümüş kalp çerçeve',
  'albumium:frame_blue_oval' => 'Bebek mavisi oval çerçeve',
  'albumium:camera_pink' => 'Pembe retro kamera çerçevesi',
  'albumium:camera_silver' => 'Gümüş retro kamera çerçevesi',
  'albumium:corner_hearts' => 'Kalpli yırtık kâğıt köşesi',
  'albumium:corner_botanical' => 'Botanik yırtık kâğıt köşesi',
  'albumium:corner_porcelain' => 'Mavi porselen kâğıt köşesi',
  'albumium:corner_meadow' => 'Kır çiçekli kâğıt köşesi',
  'albumium:corner_navy' => 'Gece yıldızlı kâğıt köşesi',
  'albumium:disco_silver' => 'Gümüş disko topu',
  'albumium:disco_pink' => 'Pembe disko topu',
  'albumium:disco_heart' => 'Disko kalp',
  'albumium:disco_planet' => 'Disko gezegen',
  'albumium:disco_cherries' => 'Disko kirazlar',
  'albumium:button_star' => 'Pastel yıldız düğme',
  'albumium:button_flower' => 'Çiçek düğme',
  'albumium:button_heart' => 'Kalp düğme',
  'albumium:button_round' => 'Renkli klasik düğme',
  'albumium:fabric_denim' => 'Dikişli kot yama',
  'albumium:fabric_gingham' => 'Pötikare kumaş yama',
  'albumium:fabric_lace' => 'Krem dantel şerit',
  'albumium:fabric_bow' => 'Kumaş fiyonk',
  'albumium:fabric_crochet' => 'Örgü çiçek',
  'albumium:fabric_safety_pin' => 'Çengelli iğne',
  'albumium:analog_polaroid' => 'Boş polaroid',
  'albumium:analog_film_roll' => 'Film rulosu',
  'albumium:analog_cassette' => 'Retro kaset',
  'albumium:analog_vinyl' => 'Renkli plak',
  'albumium:analog_camcorder' => 'Mini video kamera',
  'albumium:analog_negative' => 'Fotoğraf negatifi',
  'albumium:sky_moon' => 'Altın hilal',
  'albumium:sky_cloud' => 'Pastel bulut',
  'albumium:sky_rainbow' => 'Soluk gökkuşağı',
  'albumium:sky_sun' => 'Gülen güneş',
  'albumium:sky_comet' => 'Kuyruklu yıldız',
  'albumium:sky_constellation' => 'Yıldız haritası',
  'albumium:travel_passport' => 'Hatıra pasaportu',
  'albumium:travel_suitcase' => 'Vintage bavul',
  'albumium:travel_compass' => 'Pirinç pusula',
  'albumium:travel_motel_key' => 'Motel anahtarlığı',
  'albumium:travel_airplane_tag' => 'Uçuş etiketi',
  'albumium:travel_map' => 'Katlanmış rota haritası',
  'albumium:cafe_coffee' => 'Sıcak kahve',
  'albumium:cafe_cake' => 'Çilekli pasta',
  'albumium:cafe_strawberry' => 'Tatlı çilek',
  'albumium:cafe_teacup' => 'Çiçekli çay fincanı',
  'albumium:cafe_croissant' => 'Tereyağlı kruvasan',
  'albumium:cafe_candy' => 'Paketli şeker',
  'albumium:words_today' => 'Bugün etiketi',
  'albumium:words_us' => 'Biz etiketi',
  'albumium:words_memory' => 'Anı etiketi',
  'albumium:words_goodday' => 'Güzel gün etiketi',
  'albumium:words_lucky' => 'İyi ki etiketi',
  'albumium:words_journey' => 'Yolculuk etiketi',
  'albumium:cat_glasses' => 'Gözlüklü kedi',
  'albumium:cat_bow' => 'Fiyonklu kedi',
  'albumium:cat_flowers' => 'Çiçekli kedi',
  'albumium:cat_hat' => 'Şapkalı kedi',
  'albumium:cat_tie' => 'Kravatlı kedi',
  'albumium:cat_camera' => 'Kameralı kedi',
  'albumium:monkey_crown' => 'Taçlı maymun',
  'albumium:monkey_party' => 'Parti maymunu',
  'albumium:monkey_balloons' => 'Balonlu maymun',
  'albumium:monkey_glasses' => 'Gözlüklü maymun',
  'albumium:monkey_flowers' => 'Çiçekli maymun',
  'albumium:monkey_dance' => 'Dans eden maymun',
  'albumium_asset:assets/stickers/botanical_keepsake.png' =>
    'Botanik hatıra buketi',
  'albumium_asset:assets/stickers/celestial_keepsake.png' =>
    'Gece göğü hatırası',
  'albumium_asset:assets/stickers/travel_keepsake.png' =>
    'Vintage seyahat hatırası',
  'albumium_asset:assets/stickers/romance_keepsake.png' =>
    'Kadife romantik hatıra',
  'albumium_asset:assets/stickers/photo_keepsake.png' =>
    'Analog fotoğraf hatırası',
  'albumium_asset:assets/stickers/music_keepsake.png' => 'Retro müzik hatırası',
  'albumium_asset:assets/stickers/sewing_keepsake.png' =>
    'Dikiş sepeti hatırası',
  'albumium_asset:assets/stickers/celebration_keepsake.png' =>
    'Diskolu kutlama hatırası',
  'albumium_asset:assets/stickers/seaside_keepsake.png' => 'Sahil hatırası',
  'albumium_asset:assets/stickers/cafe_keepsake.png' =>
    'Nostaljik kafe hatırası',
  'albumium_asset:assets/stickers/friendship_keepsake.png' =>
    'Arkadaşlık bilekliği hatırası',
  'albumium_asset:assets/stickers/cozy_reading_keepsake.png' =>
    'Sıcak okuma hatırası',
  'albumium_shape:circle_blush' => 'Pudra daire',
  'albumium_shape:circle_navy' => 'Lacivert daire',
  'albumium_shape:circle_gold' => 'Altın daire',
  'albumium_shape:square_blush' => 'Pudra kare',
  'albumium_shape:square_navy' => 'Lacivert kare',
  'albumium_shape:square_obsidian' => 'Obsidyen kare',
  'albumium_shape:heart_rose' => 'Gül kalp',
  'albumium_shape:heart_blue' => 'Mavi kalp',
  'albumium_shape:heart_gold' => 'Altın kalp',
  _ => value,
};

const albumShapeObjects = <String>[
  'albumium_shape:circle_blush',
  'albumium_shape:circle_navy',
  'albumium_shape:circle_gold',
  'albumium_shape:square_blush',
  'albumium_shape:square_navy',
  'albumium_shape:square_obsidian',
  'albumium_shape:heart_rose',
  'albumium_shape:heart_blue',
  'albumium_shape:heart_gold',
];

class StickerCategory {
  const StickerCategory({
    required this.name,
    required this.icon,
    required this.stickers,
  });

  final String name;
  final IconData icon;
  final List<String> stickers;

  bool get illustrated =>
      stickers.isNotEmpty && isIllustratedSticker(stickers.first);
}

const stickerPacks = <StickerCategory>[
  StickerCategory(
    name: 'Hatıra Koleksiyonu',
    icon: Icons.diamond_outlined,
    stickers: [
      'albumium_asset:assets/stickers/botanical_keepsake.png',
      'albumium_asset:assets/stickers/celestial_keepsake.png',
      'albumium_asset:assets/stickers/travel_keepsake.png',
      'albumium_asset:assets/stickers/romance_keepsake.png',
      'albumium_asset:assets/stickers/photo_keepsake.png',
      'albumium_asset:assets/stickers/music_keepsake.png',
      'albumium_asset:assets/stickers/sewing_keepsake.png',
      'albumium_asset:assets/stickers/celebration_keepsake.png',
      'albumium_asset:assets/stickers/seaside_keepsake.png',
      'albumium_asset:assets/stickers/cafe_keepsake.png',
      'albumium_asset:assets/stickers/friendship_keepsake.png',
      'albumium_asset:assets/stickers/cozy_reading_keepsake.png',
    ],
  ),
  StickerCategory(
    name: 'Kolaj Kiti',
    icon: Icons.auto_awesome_mosaic_outlined,
    stickers: [
      'albumium:washi_blush',
      'albumium:washi_sage',
      'albumium:washi_script',
      'albumium:film_strip',
      'albumium:ribbon_blush',
      'albumium:ribbon_navy',
    ],
  ),
  StickerCategory(
    name: 'Botanik Arşiv',
    icon: Icons.local_florist_outlined,
    stickers: [
      'albumium:pressed_lavender',
      'albumium:pressed_daisy',
      'albumium:pressed_rose',
      'albumium:fern',
      'albumium:gold_branch',
      'albumium:star_doodle',
    ],
  ),
  StickerCategory(
    name: 'Posta & Mühür',
    icon: Icons.local_post_office_outlined,
    stickers: [
      'albumium:postage_rose',
      'albumium:postage_airmail',
      'albumium:wax_burgundy',
      'albumium:wax_gold',
      'albumium:vintage_ticket',
      'albumium:star_doodle',
    ],
  ),
  StickerCategory(
    name: 'Retro Çerçeve',
    icon: Icons.photo_size_select_large_outlined,
    stickers: [
      'albumium:frame_gold_rect',
      'albumium:frame_gold_oval',
      'albumium:frame_silver_heart',
      'albumium:frame_blue_oval',
      'albumium:camera_pink',
      'albumium:camera_silver',
    ],
  ),
  StickerCategory(
    name: 'Kâğıt Köşeleri',
    icon: Icons.change_history_rounded,
    stickers: [
      'albumium:corner_hearts',
      'albumium:corner_botanical',
      'albumium:corner_porcelain',
      'albumium:corner_meadow',
      'albumium:corner_navy',
    ],
  ),
  StickerCategory(
    name: 'Disko Kolaj',
    icon: Icons.blur_circular_rounded,
    stickers: [
      'albumium:disco_silver',
      'albumium:disco_pink',
      'albumium:disco_heart',
      'albumium:disco_planet',
      'albumium:disco_cherries',
    ],
  ),
  StickerCategory(
    name: 'Düğme Kutusu',
    icon: Icons.radio_button_checked_rounded,
    stickers: [
      'albumium:button_star',
      'albumium:button_flower',
      'albumium:button_heart',
      'albumium:button_round',
    ],
  ),
  StickerCategory(
    name: 'Dikiş Sepeti',
    icon: Icons.content_cut_rounded,
    stickers: [
      'albumium:fabric_denim',
      'albumium:fabric_gingham',
      'albumium:fabric_lace',
      'albumium:fabric_bow',
      'albumium:fabric_crochet',
      'albumium:fabric_safety_pin',
    ],
  ),
  StickerCategory(
    name: 'Analog Oda',
    icon: Icons.photo_camera_back_outlined,
    stickers: [
      'albumium:analog_polaroid',
      'albumium:analog_film_roll',
      'albumium:analog_cassette',
      'albumium:analog_vinyl',
      'albumium:analog_camcorder',
      'albumium:analog_negative',
    ],
  ),
  StickerCategory(
    name: 'Gökyüzü',
    icon: Icons.auto_awesome_rounded,
    stickers: [
      'albumium:sky_moon',
      'albumium:sky_cloud',
      'albumium:sky_rainbow',
      'albumium:sky_sun',
      'albumium:sky_comet',
      'albumium:sky_constellation',
    ],
  ),
  StickerCategory(
    name: 'Yolculuk Masası',
    icon: Icons.explore_outlined,
    stickers: [
      'albumium:travel_passport',
      'albumium:travel_suitcase',
      'albumium:travel_compass',
      'albumium:travel_motel_key',
      'albumium:travel_airplane_tag',
      'albumium:travel_map',
    ],
  ),
  StickerCategory(
    name: 'Tatlı Mola',
    icon: Icons.local_cafe_outlined,
    stickers: [
      'albumium:cafe_coffee',
      'albumium:cafe_cake',
      'albumium:cafe_strawberry',
      'albumium:cafe_teacup',
      'albumium:cafe_croissant',
      'albumium:cafe_candy',
    ],
  ),
  StickerCategory(
    name: 'Kelime Etiketleri',
    icon: Icons.sell_outlined,
    stickers: [
      'albumium:words_today',
      'albumium:words_us',
      'albumium:words_memory',
      'albumium:words_goodday',
      'albumium:words_lucky',
      'albumium:words_journey',
    ],
  ),
  StickerCategory(
    name: 'Kedi Kulübü',
    icon: Icons.pets_outlined,
    stickers: [
      'albumium:cat_glasses',
      'albumium:cat_bow',
      'albumium:cat_flowers',
      'albumium:cat_hat',
      'albumium:cat_tie',
      'albumium:cat_camera',
    ],
  ),
  StickerCategory(
    name: 'Parti Maymunları',
    icon: Icons.celebration_outlined,
    stickers: [
      'albumium:monkey_crown',
      'albumium:monkey_party',
      'albumium:monkey_balloons',
      'albumium:monkey_glasses',
      'albumium:monkey_flowers',
      'albumium:monkey_dance',
    ],
  ),
  StickerCategory(
    name: 'Aşk',
    icon: Icons.favorite_border_rounded,
    stickers: [
      '❤️',
      '💕',
      '💖',
      '💍',
      '💌',
      '🌹',
      '🕊️',
      '🥂',
      '💐',
      '💝',
      '💘',
      '🧸',
    ],
  ),
  StickerCategory(
    name: 'Kutlama',
    icon: Icons.celebration_outlined,
    stickers: [
      '🎂',
      '🎉',
      '🎈',
      '🥳',
      '🍾',
      '🎁',
      '🪩',
      '👑',
      '🎊',
      '🍰',
      '🧁',
      '🏆',
    ],
  ),
  StickerCategory(
    name: 'Seyahat',
    icon: Icons.flight_takeoff_rounded,
    stickers: [
      '✈️',
      '🗺️',
      '🧭',
      '🏖️',
      '🏔️',
      '📸',
      '🧳',
      '🚂',
      '🌴',
      '⛺',
      '🌅',
      '🎒',
    ],
  ),
  StickerCategory(
    name: 'Doğa',
    icon: Icons.eco_outlined,
    stickers: [
      '🌿',
      '🌸',
      '🌻',
      '🌺',
      '🍀',
      '🌵',
      '🍄',
      '🍃',
      '🌷',
      '🌼',
      '🌾',
      '🍁',
    ],
  ),
];

/// Renders both legacy emoji stickers and Albumium's code-native illustrated
/// collage motifs. The same asset-free drawing is used in the editor, book
/// preview and exported frames.
class AlbumStickerView extends StatelessWidget {
  const AlbumStickerView({
    super.key,
    required this.content,
    this.preview = false,
  });

  final String content;
  final bool preview;

  @override
  Widget build(BuildContext context) {
    if (isAlbumStickerAsset(content)) {
      return Semantics(
        image: true,
        label: albumStickerLabel(content),
        child: Center(
          child: AspectRatio(
            key: ValueKey('sticker-art-$content'),
            aspectRatio: albumStickerAspectRatio(content),
            child: Image.asset(
              albumStickerAssetPath(content),
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              gaplessPlayback: true,
            ),
          ),
        ),
      );
    }

    if (!isIllustratedSticker(content)) {
      return FittedBox(
        fit: BoxFit.contain,
        child: Text(content, textAlign: TextAlign.center),
      );
    }

    if (isAlbumShape(content)) {
      return Semantics(
        image: true,
        label: albumStickerLabel(content),
        child: Center(
          child: AspectRatio(
            key: ValueKey('sticker-art-$content'),
            aspectRatio: albumStickerAspectRatio(content),
            child: CustomPaint(
              painter: _ShapeObjectPainter(content),
              child: const SizedBox.expand(),
            ),
          ),
        ),
      );
    }

    return Semantics(
      image: true,
      label: albumStickerLabel(content),
      child: Center(
        child: AspectRatio(
          key: ValueKey('sticker-art-$content'),
          aspectRatio: albumStickerAspectRatio(content),
          child: CustomPaint(
            painter: _IllustratedStickerPainter(content),
            child: preview ? const SizedBox.expand() : null,
          ),
        ),
      ),
    );
  }
}

/// Albüm sayfasına fotoğraf ve yazılarla aynı hareket/ölçek davranışını
/// paylaşan, emojiden bağımsız geometrik nesneler ekler.
class ShapeObjectPickerSheet extends StatelessWidget {
  const ShapeObjectPickerSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final tablet = MediaQuery.sizeOf(context).shortestSide >= 600;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 4, 18, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.interests_outlined, color: colors.primary),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Şekil Nesneleri',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        'Daire, kare ve kalpleri büyüt, döndür ve katmanla',
                        style: TextStyle(fontSize: 11.5),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: tablet ? 270 : 236,
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: tablet ? 6 : 3,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.88,
                ),
                itemCount: albumShapeObjects.length,
                itemBuilder: (context, index) {
                  final shape = albumShapeObjects[index];
                  return InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => Navigator.pop(context, shape),
                    child: Ink(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: colors.outlineVariant),
                      ),
                      child: Column(
                        children: [
                          Expanded(
                            child: AlbumStickerView(
                              content: shape,
                              preview: true,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            albumStickerLabel(shape),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShapeObjectPainter extends CustomPainter {
  const _ShapeObjectPainter(this.id);

  final String id;

  Color get _base => switch (id) {
    String value when value.endsWith('_blush') => const Color(0xFFD994A8),
    String value when value.endsWith('_rose') => const Color(0xFFB83F68),
    String value when value.endsWith('_navy') => const Color(0xFF294F83),
    String value when value.endsWith('_blue') => const Color(0xFF5B8FCB),
    String value when value.endsWith('_gold') => const Color(0xFFC7A45A),
    _ => const Color(0xFF292A2E),
  };

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final inset = math.min(size.width, size.height) * 0.08;
    final target = rect.deflate(inset);
    final base = _base;
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color.lerp(base, Colors.white, 0.28)!,
          base,
          Color.lerp(base, Colors.black, 0.20)!,
        ],
      ).createShader(target);
    final highlight = Paint()
      ..color = Colors.white.withValues(alpha: 0.34)
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(1.2, inset * 0.22);

    Path path;
    if (id.contains(':circle_')) {
      path = Path()..addOval(target);
    } else if (id.contains(':square_')) {
      path = Path()
        ..addRRect(
          RRect.fromRectAndRadius(
            target,
            Radius.circular(math.min(target.width, target.height) * 0.16),
          ),
        );
    } else {
      final x = target.left;
      final y = target.top;
      final w = target.width;
      final h = target.height;
      path = Path()
        ..moveTo(x + w * .5, y + h * .91)
        ..cubicTo(
          x + w * .43,
          y + h * .82,
          x + w * .06,
          y + h * .59,
          x + w * .06,
          y + h * .31,
        )
        ..cubicTo(
          x + w * .06,
          y + h * .08,
          x + w * .34,
          y + h * .02,
          x + w * .5,
          y + h * .24,
        )
        ..cubicTo(
          x + w * .66,
          y + h * .02,
          x + w * .94,
          y + h * .08,
          x + w * .94,
          y + h * .31,
        )
        ..cubicTo(
          x + w * .94,
          y + h * .59,
          x + w * .57,
          y + h * .82,
          x + w * .5,
          y + h * .91,
        )
        ..close();
    }
    canvas.drawShadow(path, const Color(0x55000000), inset * .65, true);
    canvas.drawPath(path, paint);
    canvas.drawPath(path, highlight);
  }

  @override
  bool shouldRepaint(covariant _ShapeObjectPainter oldDelegate) =>
      oldDelegate.id != id;
}

class StickerPackPickerSheet extends StatefulWidget {
  const StickerPackPickerSheet({super.key});

  @override
  State<StickerPackPickerSheet> createState() => _StickerPackPickerSheetState();
}

class _StickerPackPickerSheetState extends State<StickerPackPickerSheet> {
  String _query = '';
  String? _selectedCategory;

  void _pickSurpriseSticker() {
    final choices = stickerPacks
        .expand((pack) => pack.stickers)
        .where(isIllustratedSticker)
        .toList(growable: false);
    if (choices.isEmpty) return;
    Navigator.pop(context, choices[math.Random().nextInt(choices.length)]);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final mediaSize = MediaQuery.sizeOf(context);
    final tablet = mediaSize.shortestSide >= 600;
    final query = _query.trim().toLowerCase();
    final entries = <({String sticker, String category, bool illustrated})>[];
    for (final pack in stickerPacks) {
      if (_selectedCategory != null && pack.name != _selectedCategory) continue;
      for (final sticker in pack.stickers) {
        final label = albumStickerLabel(sticker);
        if (query.isNotEmpty &&
            !label.toLowerCase().contains(query) &&
            !pack.name.toLowerCase().contains(query)) {
          continue;
        }
        entries.add((
          sticker: sticker,
          category: pack.name,
          illustrated: isIllustratedSticker(sticker),
        ));
      }
    }
    return SafeArea(
      child: SizedBox(
        height: math.min(mediaSize.height * .8, 720),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(
                        Icons.auto_awesome_outlined,
                        color: colors.onPrimaryContainer,
                        size: 21,
                      ),
                    ),
                  ),
                  const SizedBox(width: 11),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tüm Süsler',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Ara, filtrele veya sürpriz bir parça seç',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  IconButton.filledTonal(
                    onPressed: _pickSurpriseSticker,
                    tooltip: 'Rastgele sürpriz süs',
                    icon: const Icon(Icons.casino_outlined),
                  ),
                  const SizedBox(width: 2),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      onChanged: (value) => setState(() => _query = value),
                      decoration: const InputDecoration(
                        isDense: true,
                        hintText: 'Süs ara…',
                        prefixIcon: Icon(Icons.search_rounded, size: 20),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    tooltip: 'Kategori seç',
                    onSelected: (value) => setState(
                      () => _selectedCategory = value.isEmpty ? null : value,
                    ),
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: '', child: Text('Tümü')),
                      for (final pack in stickerPacks)
                        PopupMenuItem(
                          value: pack.name,
                          child: Row(
                            children: [
                              Icon(pack.icon, size: 18),
                              const SizedBox(width: 9),
                              Text(pack.name),
                            ],
                          ),
                        ),
                    ],
                    child: Container(
                      height: 48,
                      constraints: const BoxConstraints(maxWidth: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 11),
                      decoration: BoxDecoration(
                        color: colors.surfaceContainerHigh,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: colors.outlineVariant),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.filter_list_rounded, size: 19),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              _selectedCategory ?? 'Tümü',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 9),
              Text(
                '${entries.length} yaratıcı parça',
                style: TextStyle(
                  color: colors.onSurfaceVariant,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 7),
              Expanded(
                child: entries.isEmpty
                    ? const Center(child: Text('Bu aramaya uygun süs yok.'))
                    : GridView.builder(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: const EdgeInsets.only(top: 2, bottom: 8),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: tablet ? 5 : 3,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: .82,
                        ),
                        itemCount: entries.length,
                        itemBuilder: (context, index) {
                          final entry = entries[index];
                          return InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () => Navigator.pop(context, entry.sticker),
                            child: Ink(
                              decoration: BoxDecoration(
                                color: colors.surfaceContainerHigh,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: colors.outlineVariant,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(7, 7, 7, 6),
                                child: Column(
                                  children: [
                                    Expanded(
                                      child: entry.illustrated
                                          ? AlbumStickerView(
                                              content: entry.sticker,
                                              preview: true,
                                            )
                                          : Center(
                                              child: Text(
                                                entry.sticker,
                                                style: const TextStyle(
                                                  fontSize: 29,
                                                ),
                                              ),
                                            ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      albumStickerLabel(entry.sticker),
                                      maxLines: 2,
                                      textAlign: TextAlign.center,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 9.5,
                                        fontWeight: FontWeight.w600,
                                        height: 1.05,
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
            ],
          ),
        ),
      ),
    );
  }
}

class _IllustratedStickerPainter extends CustomPainter {
  const _IllustratedStickerPainter(this.id);

  final String id;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    canvas.save();
    canvas.scale(size.width / 100, size.height / 100);

    if (id.contains('washi_')) {
      _paintWashi(canvas);
    } else if (id == 'albumium:film_strip') {
      _paintFilmStrip(canvas);
    } else if (id.contains('ribbon_')) {
      _paintRibbon(canvas);
    } else if (id.contains('pressed_') || id.endsWith(':fern')) {
      _paintBotanical(canvas);
    } else if (id.endsWith(':gold_branch')) {
      _paintGoldBranch(canvas);
    } else if (id.contains('postage_')) {
      _paintPostage(canvas);
    } else if (id.contains('wax_')) {
      _paintWaxSeal(canvas);
    } else if (id.endsWith(':vintage_ticket')) {
      _paintTicket(canvas);
    } else if (id.contains('frame_') || id.contains('camera_')) {
      _paintVintageFrame(canvas);
    } else if (id.contains('corner_')) {
      _paintPaperCorner(canvas);
    } else if (id.contains('disco_')) {
      _paintDiscoSticker(canvas);
    } else if (id.contains('button_')) {
      _paintButton(canvas);
    } else if (id.contains('fabric_')) {
      _paintFabricSticker(canvas);
    } else if (id.contains('analog_')) {
      _paintAnalogSticker(canvas);
    } else if (id.contains('sky_')) {
      _paintSkySticker(canvas);
    } else if (id.contains('travel_')) {
      _paintTravelSticker(canvas);
    } else if (id.contains('cafe_')) {
      _paintCafeSticker(canvas);
    } else if (id.contains('words_')) {
      _paintWordLabel(canvas);
    } else if (id.contains('cat_')) {
      _paintCatSticker(canvas);
    } else if (id.contains('monkey_')) {
      _paintMonkeySticker(canvas);
    } else {
      _paintStarDoodle(canvas);
    }

    canvas.restore();
  }

  void _paintWashi(Canvas canvas) {
    final base = switch (id) {
      'albumium:washi_sage' => const Color(0xFFC1C8A9),
      'albumium:washi_script' => const Color(0xFFD7C9AF),
      _ => const Color(0xFFDDAEB8),
    };
    final path = Path()
      ..moveTo(1, 14)
      ..lineTo(5, 8)
      ..lineTo(2, 3)
      ..lineTo(97, 6)
      ..lineTo(94, 12)
      ..lineTo(99, 18)
      ..lineTo(96, 88)
      ..lineTo(91, 94)
      ..lineTo(96, 98)
      ..lineTo(4, 95)
      ..lineTo(7, 88)
      ..lineTo(2, 82)
      ..close();
    canvas.drawShadow(path, const Color(0x55000000), 3, false);
    canvas.drawPath(path, Paint()..color = base.withValues(alpha: 0.88));

    final ink = Paint()
      ..color = const Color(0xFF5C4A45).withValues(alpha: 0.34)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    if (id == 'albumium:washi_script') {
      final script = Path()
        ..moveTo(8, 58)
        ..cubicTo(18, 25, 30, 78, 43, 45)
        ..cubicTo(54, 20, 64, 75, 74, 44)
        ..cubicTo(81, 26, 88, 42, 94, 30);
      canvas.drawPath(script, ink..strokeWidth = 2.2);
      for (var x = 12.0; x < 92; x += 18) {
        canvas.drawLine(Offset(x, 70), Offset(x + 12, 70), ink);
      }
    } else if (id == 'albumium:washi_sage') {
      for (var x = 10.0; x < 96; x += 21) {
        canvas.drawLine(Offset(x, 18), Offset(x + 8, 82), ink);
        canvas.drawCircle(Offset(x + 8, 41), 4, ink);
      }
    } else {
      for (var x = 11.0; x < 96; x += 18) {
        canvas.drawCircle(Offset(x, 34), 2.5, ink);
        canvas.drawCircle(Offset(x + 8, 64), 1.8, ink);
      }
    }
  }

  void _paintFilmStrip(Canvas canvas) {
    final body = RRect.fromRectAndRadius(
      const Rect.fromLTWH(1, 5, 98, 90),
      const Radius.circular(5),
    );
    canvas.drawShadow(
      Path()..addRRect(body),
      const Color(0x66000000),
      4,
      false,
    );
    canvas.drawRRect(body, Paint()..color = const Color(0xFF24201E));
    final holePaint = Paint()..color = const Color(0xFFE8DCC8);
    for (var x = 7.0; x < 97; x += 11) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, 10, 6, 9),
          const Radius.circular(1.5),
        ),
        holePaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, 81, 6, 9),
          const Radius.circular(1.5),
        ),
        holePaint,
      );
    }
    final framePaint = Paint()
      ..color = const Color(0xFF7F6957)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (var x = 6.0; x < 94; x += 30) {
      canvas.drawRect(Rect.fromLTWH(x, 25, 25, 50), framePaint);
      canvas.drawLine(Offset(x + 3, 68), Offset(x + 21, 31), framePaint);
    }
  }

  void _paintRibbon(Canvas canvas) {
    final base = id.endsWith('navy')
        ? const Color(0xFF2F4058)
        : const Color(0xFFB87483);
    final dark = Color.lerp(base, Colors.black, 0.28)!;
    final tails = Path()
      ..moveTo(2, 30)
      ..lineTo(21, 30)
      ..lineTo(21, 75)
      ..lineTo(2, 88)
      ..lineTo(9, 58)
      ..close()
      ..moveTo(98, 30)
      ..lineTo(79, 30)
      ..lineTo(79, 75)
      ..lineTo(98, 88)
      ..lineTo(91, 58)
      ..close();
    canvas.drawPath(tails, Paint()..color = dark);
    final center = RRect.fromRectAndRadius(
      const Rect.fromLTWH(14, 20, 72, 58),
      const Radius.circular(5),
    );
    canvas.drawShadow(
      Path()..addRRect(center),
      const Color(0x55000000),
      3,
      false,
    );
    canvas.drawRRect(center, Paint()..color = base);
    canvas.drawLine(
      const Offset(20, 30),
      const Offset(80, 30),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.28)
        ..strokeWidth = 2,
    );
  }

  void _paintBotanical(Canvas canvas) {
    final stemColor = id.endsWith('lavender')
        ? const Color(0xFF6D7051)
        : const Color(0xFF657052);
    final stem = Paint()
      ..color = stemColor
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final mainStem = Path()
      ..moveTo(50, 96)
      ..cubicTo(45, 67, 57, 38, 49, 6);
    canvas.drawPath(mainStem, stem);

    if (id.endsWith(':fern')) {
      for (var i = 0; i < 9; i++) {
        final y = 18.0 + i * 7.8;
        final spread = 28.0 - i * 1.5;
        canvas.drawLine(Offset(49, y), Offset(49 - spread, y - 10), stem);
        canvas.drawLine(Offset(50, y + 2), Offset(50 + spread, y - 7), stem);
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(49 - spread, y - 10),
            width: 8,
            height: 4,
          ),
          Paint()..color = const Color(0xFF879276).withValues(alpha: 0.72),
        );
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(50 + spread, y - 7),
            width: 8,
            height: 4,
          ),
          Paint()..color = const Color(0xFF879276).withValues(alpha: 0.72),
        );
      }
      return;
    }

    final petalColor = switch (id) {
      'albumium:pressed_lavender' => const Color(0xFF8A769A),
      'albumium:pressed_rose' => const Color(0xFFA8646D),
      _ => const Color(0xFFE0C987),
    };
    for (var i = 0; i < 6; i++) {
      final y = 16.0 + i * 11;
      final side = i.isEven ? -1.0 : 1.0;
      canvas.drawLine(
        Offset(50, y + 8),
        Offset(50 + side * 22, y),
        stem..strokeWidth = 1.4,
      );
      _drawFlower(canvas, Offset(50 + side * 24, y), petalColor, i * 0.7);
    }
    _drawFlower(canvas, const Offset(49, 10), petalColor, 0.2);
  }

  void _drawFlower(Canvas canvas, Offset center, Color color, double phase) {
    final petal = Paint()..color = color.withValues(alpha: 0.76);
    for (var i = 0; i < 6; i++) {
      final angle = i * math.pi / 3 + phase;
      final offset = Offset(math.cos(angle) * 6, math.sin(angle) * 6);
      canvas.drawOval(
        Rect.fromCenter(center: center + offset, width: 9, height: 4),
        petal,
      );
    }
    canvas.drawCircle(center, 2.4, Paint()..color = const Color(0xFF745E42));
  }

  void _paintGoldBranch(Canvas canvas) {
    final gold = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF8E6A2D), Color(0xFFE5C980), Color(0xFF9D7535)],
      ).createShader(const Rect.fromLTWH(0, 0, 100, 100))
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final branch = Path()
      ..moveTo(10, 91)
      ..cubicTo(36, 75, 48, 49, 88, 10);
    canvas.drawPath(branch, gold);
    for (var i = 0; i < 8; i++) {
      final t = i / 8;
      final x = 22 + t * 58;
      final y = 81 - t * 61;
      final side = i.isEven ? -1.0 : 1.0;
      canvas.drawLine(Offset(x, y), Offset(x + side * 17, y - 8), gold);
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x + side * 19, y - 9),
          width: 13,
          height: 6,
        ),
        Paint()
          ..shader = gold.shader
          ..style = PaintingStyle.fill,
      );
    }
  }

  void _paintPostage(Canvas canvas) {
    final paper = id.endsWith('airmail')
        ? const Color(0xFFD8E0DC)
        : const Color(0xFFE9D1C2);
    final ink = id.endsWith('airmail')
        ? const Color(0xFF345B65)
        : const Color(0xFF8B4A56);
    final stamp = RRect.fromRectAndRadius(
      const Rect.fromLTWH(7, 5, 86, 90),
      const Radius.circular(3),
    );
    canvas.drawShadow(
      Path()..addRRect(stamp),
      const Color(0x55000000),
      3,
      false,
    );
    canvas.drawRRect(stamp, Paint()..color = paper);
    final edge = Paint()
      ..color = const Color(0xFF9E8875).withValues(alpha: 0.7);
    for (var i = 0; i < 10; i++) {
      final p = 9.0 + i * 9;
      canvas.drawCircle(Offset(p, 5), 1.7, edge);
      canvas.drawCircle(Offset(p, 95), 1.7, edge);
      canvas.drawCircle(Offset(7, p), 1.7, edge);
      canvas.drawCircle(Offset(93, p), 1.7, edge);
    }
    final border = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRect(const Rect.fromLTWH(16, 14, 68, 70), border);
    if (id.endsWith('airmail')) {
      canvas.drawCircle(const Offset(50, 47), 18, border);
      canvas.drawLine(const Offset(32, 47), const Offset(68, 47), border);
      canvas.drawLine(const Offset(50, 29), const Offset(50, 65), border);
      canvas.drawLine(const Offset(23, 74), const Offset(77, 20), border);
    } else {
      final stem = Paint()
        ..color = ink
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      canvas.drawLine(const Offset(50, 72), const Offset(50, 47), stem);
      _drawFlower(canvas, const Offset(50, 38), ink, 0);
      canvas.drawOval(const Rect.fromLTWH(35, 51, 16, 8), stem);
      canvas.drawOval(const Rect.fromLTWH(49, 58, 16, 8), stem);
    }
  }

  void _paintWaxSeal(Canvas canvas) {
    final base = id.endsWith('gold')
        ? const Color(0xFFB99245)
        : const Color(0xFF8C3742);
    final path = Path();
    for (var i = 0; i < 32; i++) {
      final angle = i * math.pi * 2 / 32;
      final radius = i.isEven ? 42.0 : 38.0;
      final point = Offset(
        50 + math.cos(angle) * radius,
        51 + math.sin(angle) * radius,
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawShadow(path, const Color(0x77000000), 5, false);
    canvas.drawPath(
      path,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-0.25, -0.3),
          colors: [
            Color.lerp(base, Colors.white, 0.24)!,
            base,
            Color.lerp(base, Colors.black, 0.3)!,
          ],
        ).createShader(const Rect.fromLTWH(8, 9, 84, 84)),
    );
    final emboss = Paint()
      ..color = Color.lerp(base, Colors.black, 0.32)!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    canvas.drawCircle(const Offset(50, 51), 27, emboss);
    final monogram = Path()
      ..moveTo(36, 65)
      ..lineTo(50, 31)
      ..lineTo(64, 65)
      ..moveTo(41, 54)
      ..lineTo(59, 54);
    canvas.drawPath(monogram, emboss..strokeWidth = 4);
  }

  void _paintTicket(Canvas canvas) {
    final ticket = RRect.fromRectAndRadius(
      const Rect.fromLTWH(3, 16, 94, 68),
      const Radius.circular(7),
    );
    canvas.drawShadow(
      Path()..addRRect(ticket),
      const Color(0x44000000),
      3,
      false,
    );
    canvas.drawRRect(ticket, Paint()..color = const Color(0xFFD8C2A0));
    final ink = Paint()
      ..color = const Color(0xFF735849)
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(9, 22, 82, 56),
        const Radius.circular(4),
      ),
      ink,
    );
    for (var y = 27.0; y < 76; y += 8) {
      canvas.drawLine(Offset(68, y), Offset(68, y + 4), ink);
    }
    for (var x = 18.0; x < 61; x += 9) {
      canvas.drawLine(Offset(x, 42), Offset(x + 5, 42), ink);
      canvas.drawLine(Offset(x, 58), Offset(x + 5, 58), ink);
    }
    canvas.drawCircle(const Offset(80, 50), 8, ink);
  }

  void _paintVintageFrame(Canvas canvas) {
    if (id.contains('camera_')) {
      _paintCameraFrame(canvas);
      return;
    }

    final isSilver = id.contains('silver');
    final isBlue = id.contains('blue');
    final colors = isSilver
        ? const [Color(0xFF776F67), Color(0xFFE9E1D3), Color(0xFF918474)]
        : isBlue
        ? const [Color(0xFF668E96), Color(0xFFD0E4DE), Color(0xFF72949A)]
        : const [Color(0xFF8B5C1F), Color(0xFFE2BE66), Color(0xFF9B6A27)];
    final outer = id.contains('heart')
        ? _heartPath(const Rect.fromLTWH(4, 4, 92, 91))
        : id.contains('oval')
        ? (Path()..addOval(const Rect.fromLTWH(8, 3, 84, 94)))
        : (Path()..addRRect(
            RRect.fromRectAndRadius(
              const Rect.fromLTWH(4, 5, 92, 90),
              const Radius.circular(7),
            ),
          ));
    final inner = id.contains('heart')
        ? _heartPath(const Rect.fromLTWH(22, 24, 56, 55))
        : id.contains('oval')
        ? (Path()..addOval(const Rect.fromLTWH(25, 19, 50, 64)))
        : (Path()..addRRect(
            RRect.fromRectAndRadius(
              const Rect.fromLTWH(20, 20, 60, 60),
              const Radius.circular(3),
            ),
          ));
    final frame = Path.combine(PathOperation.difference, outer, inner);
    canvas.drawShadow(outer, const Color(0x66000000), 4, false);
    canvas.drawPath(
      frame,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ).createShader(const Rect.fromLTWH(0, 0, 100, 100)),
    );

    final engraving = Paint()
      ..color = colors.first.withValues(alpha: 0.72)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6;
    if (id.contains('oval') || id.contains('heart')) {
      for (var angle = 0.0; angle < math.pi * 2; angle += math.pi / 8) {
        final center = Offset(
          50 + math.cos(angle) * 43,
          51 + math.sin(angle) * 45,
        );
        canvas.drawOval(
          Rect.fromCenter(center: center, width: 8, height: 4),
          engraving,
        );
      }
    } else {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(10, 11, 80, 78),
          const Radius.circular(4),
        ),
        engraving,
      );
      for (final center in const [
        Offset(9, 10),
        Offset(91, 10),
        Offset(9, 90),
        Offset(91, 90),
      ]) {
        canvas.drawCircle(center, 6, engraving);
        canvas.drawCircle(center, 2.5, engraving);
      }
    }
  }

  void _paintCameraFrame(Canvas canvas) {
    final pink = id.endsWith('pink');
    final base = pink ? const Color(0xFFD47A9B) : const Color(0xFFC9C6BE);
    final dark = pink ? const Color(0xFF8E3D60) : const Color(0xFF615F5A);
    final body = RRect.fromRectAndRadius(
      const Rect.fromLTWH(3, 17, 94, 71),
      const Radius.circular(10),
    );
    final screen = RRect.fromRectAndRadius(
      const Rect.fromLTWH(18, 29, 59, 47),
      const Radius.circular(4),
    );
    final frame = Path.combine(
      PathOperation.difference,
      Path()..addRRect(body),
      Path()..addRRect(screen),
    );
    canvas.drawShadow(
      Path()..addRRect(body),
      const Color(0x66000000),
      4,
      false,
    );
    canvas.drawPath(
      frame,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(base, Colors.white, .56)!,
            base,
            dark,
            Color.lerp(base, Colors.white, .22)!,
          ],
          stops: const [0, .34, .72, 1],
        ).createShader(const Rect.fromLTWH(0, 18, 100, 70)),
    );
    final top = RRect.fromRectAndRadius(
      const Rect.fromLTWH(17, 12, 28, 12),
      const Radius.circular(3),
    );
    canvas.drawRRect(top, Paint()..color = base);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(13, 14, 68, 8),
        const Radius.circular(4),
      ),
      Paint()..color = Colors.white.withValues(alpha: .23),
    );
    canvas.drawCircle(const Offset(87, 31), 7, Paint()..color = dark);
    canvas.drawCircle(
      const Offset(85, 29),
      2.4,
      Paint()..color = Colors.white.withValues(alpha: .7),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(22, 33, 51, 39),
        const Radius.circular(2),
      ),
      Paint()
        ..color = Colors.white.withValues(alpha: .46)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    for (final center in const [
      Offset(10, 25),
      Offset(89, 79),
      Offset(10, 79),
    ]) {
      canvas.drawCircle(center, 3, Paint()..color = dark);
      canvas.drawLine(
        center.translate(-1.5, 0),
        center.translate(1.5, 0),
        Paint()
          ..color = Colors.white.withValues(alpha: .55)
          ..strokeWidth = .8,
      );
    }
    for (var i = 0; i < 4; i++) {
      canvas.drawCircle(
        Offset(84 + (i % 2) * 7, 50 + (i ~/ 2) * 8),
        2.2,
        Paint()..color = dark,
      );
    }
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(83, 67, 10, 6),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFFD36A68),
    );
  }

  void _paintPaperCorner(Canvas canvas) {
    final paper = switch (id) {
      'albumium:corner_hearts' => const Color(0xFFF1D8D7),
      'albumium:corner_botanical' => const Color(0xFFE4E1CB),
      'albumium:corner_porcelain' => const Color(0xFFE4E7DE),
      'albumium:corner_meadow' => const Color(0xFFD9DEC7),
      _ => const Color(0xFF34435E),
    };
    final corner = Path()
      ..moveTo(1, 2)
      ..lineTo(98, 2)
      ..lineTo(94, 10)
      ..lineTo(88, 13)
      ..lineTo(84, 23)
      ..lineTo(77, 25)
      ..lineTo(71, 37)
      ..lineTo(61, 39)
      ..lineTo(55, 49)
      ..lineTo(45, 54)
      ..lineTo(39, 65)
      ..lineTo(27, 69)
      ..lineTo(24, 80)
      ..lineTo(15, 83)
      ..lineTo(10, 95)
      ..lineTo(1, 98)
      ..close();
    canvas.drawShadow(corner, const Color(0x55000000), 3, false);
    canvas.drawPath(corner, Paint()..color = paper);
    canvas.save();
    canvas.clipPath(corner);

    if (id.endsWith('hearts')) {
      for (var y = 14.0; y < 82; y += 20) {
        for (var x = 12.0; x < 91; x += 22) {
          canvas.save();
          canvas.translate(x, y);
          canvas.scale(.09, .09);
          canvas.drawPath(
            _heartPath(const Rect.fromLTWH(0, 0, 100, 90)),
            Paint()..color = const Color(0xFFB94E5F),
          );
          canvas.restore();
        }
      }
    } else if (id.endsWith('botanical')) {
      final stem = Paint()
        ..color = const Color(0xFF5E7353)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      for (var x = 9.0; x < 100; x += 25) {
        final branch = Path()
          ..moveTo(x, 85)
          ..cubicTo(x - 2, 60, x + 11, 35, x + 6, 7);
        canvas.drawPath(branch, stem);
        for (var y = 21.0; y < 79; y += 14) {
          canvas.drawOval(
            Rect.fromCenter(center: Offset(x + 4, y), width: 11, height: 5),
            Paint()..color = const Color(0xFF829274).withValues(alpha: .8),
          );
        }
      }
    } else if (id.endsWith('porcelain')) {
      final blue = Paint()
        ..color = const Color(0xFF557B9A)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      for (var y = 8.0; y < 90; y += 24) {
        for (var x = 8.0; x < 96; x += 25) {
          canvas.drawArc(
            Rect.fromLTWH(x, y, 16, 16),
            .2,
            math.pi * 1.5,
            false,
            blue,
          );
          canvas.drawCircle(Offset(x + 8, y + 8), 2.5, blue);
        }
      }
    } else if (id.endsWith('meadow')) {
      for (var i = 0; i < 20; i++) {
        final x = 8.0 + (i * 19) % 88;
        final y = 10.0 + (i * 31) % 76;
        final color = i.isEven
            ? const Color(0xFF476D4D)
            : const Color(0xFFE2A64B);
        canvas.drawCircle(
          Offset(x, y),
          i.isEven ? 2.0 : 3.3,
          Paint()..color = color,
        );
        canvas.drawLine(
          Offset(x, y + 2),
          Offset(x - 3, y + 10),
          Paint()
            ..color = const Color(0xFF627552)
            ..strokeWidth = 1.2,
        );
      }
    } else {
      for (var y = 14.0; y < 85; y += 21) {
        for (var x = 13.0; x < 94; x += 24) {
          canvas.drawPath(
            _starPath(Offset(x, y), 5, 2.2),
            Paint()..color = const Color(0xFFD6C17F),
          );
        }
      }
    }
    canvas.restore();

    canvas.drawPath(
      corner,
      Paint()
        ..color = Colors.white.withValues(alpha: .38)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.1,
    );
  }

  void _paintDiscoSticker(Canvas canvas) {
    if (id.endsWith('cherries')) {
      final stem = Paint()
        ..color = const Color(0xFF456548)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.2
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(
        Path()
          ..moveTo(49, 28)
          ..cubicTo(40, 40, 31, 43, 28, 59)
          ..moveTo(50, 28)
          ..cubicTo(60, 40, 68, 47, 71, 61),
        stem,
      );
      canvas.drawOval(
        const Rect.fromLTWH(47, 24, 24, 10),
        Paint()..color = const Color(0xFF567A52),
      );
      _paintMosaicShape(
        canvas,
        Path()..addOval(const Rect.fromLTWH(10, 53, 40, 40)),
        const [Color(0xFF7E254D), Color(0xFFCD5E86), Color(0xFFF1B5C8)],
      );
      _paintMosaicShape(
        canvas,
        Path()..addOval(const Rect.fromLTWH(51, 57, 39, 38)),
        const [Color(0xFF8D244F), Color(0xFFD55F90), Color(0xFFF5C2D2)],
      );
      return;
    }

    if (id.endsWith('planet')) {
      final ring = Paint()
        ..color = const Color(0xFFB58B55)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 8;
      canvas.save();
      canvas.translate(50, 52);
      canvas.rotate(-.28);
      canvas.drawOval(const Rect.fromLTWH(-47, -17, 94, 34), ring);
      canvas.restore();
      _paintMosaicShape(
        canvas,
        Path()..addOval(const Rect.fromLTWH(23, 21, 54, 59)),
        const [Color(0xFF3E6177), Color(0xFF84A6AE), Color(0xFFC3D6D2)],
      );
      return;
    }

    final shape = id.endsWith('heart')
        ? _heartPath(const Rect.fromLTWH(8, 9, 84, 82))
        : (Path()..addOval(const Rect.fromLTWH(8, 7, 84, 86)));
    final colors = id.endsWith('pink') || id.endsWith('heart')
        ? const [Color(0xFF8E315E), Color(0xFFD7709A), Color(0xFFF1C3D5)]
        : const [Color(0xFF777779), Color(0xFFC7C7C5), Color(0xFFF5F2E9)];
    _paintMosaicShape(canvas, shape, colors);
    if (!id.endsWith('heart')) {
      final bow = Paint()
        ..color = id.endsWith('pink')
            ? const Color(0xFFC83F74)
            : const Color(0xFFB287A2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(
        Path()
          ..moveTo(50, 10)
          ..cubicTo(32, 0, 28, 19, 48, 22)
          ..cubicTo(70, 18, 69, 0, 50, 10)
          ..lineTo(50, 3),
        bow,
      );
    }
  }

  void _paintMosaicShape(Canvas canvas, Path shape, List<Color> colors) {
    canvas.drawShadow(shape, const Color(0x66000000), 4, false);
    canvas.drawPath(
      shape,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-.35, -.42),
          radius: .95,
          colors: [
            Color.lerp(colors.last, Colors.white, .55)!,
            colors[1],
            Color.lerp(colors.first, Colors.black, .42)!,
          ],
          stops: const [0, .52, 1],
        ).createShader(const Rect.fromLTWH(4, 4, 92, 92)),
    );
    canvas.save();
    canvas.clipPath(shape);
    var index = 0;
    for (var y = 4.0; y < 98; y += 10) {
      for (var x = 4.0; x < 98; x += 10) {
        final base = colors[index % colors.length];
        final distance = (Offset(x, y) - const Offset(28, 25)).distance;
        final color = Color.lerp(
          base,
          distance < 25 ? Colors.white : Colors.black,
          distance < 25 ? .34 : .08,
        )!;
        canvas.drawRect(
          Rect.fromLTWH(x, y, 8.4, 8.4),
          Paint()
            ..shader = LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color.lerp(color, Colors.white, .32)!, color],
            ).createShader(Rect.fromLTWH(x, y, 8.4, 8.4)),
        );
        if (index % 4 == 0) {
          canvas.drawRect(
            Rect.fromLTWH(x + 1, y + 1, 3.5, 3.5),
            Paint()..color = Colors.white.withValues(alpha: .68),
          );
        }
        index++;
      }
    }
    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 100, 100),
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-.42, -.5),
          radius: 1.05,
          colors: [Color(0xAFFFFFFF), Color(0x00FFFFFF), Color(0x59000000)],
          stops: [0, .38, 1],
        ).createShader(const Rect.fromLTWH(0, 0, 100, 100)),
    );
    final globeLines = Paint()
      ..color = Colors.white.withValues(alpha: .2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawOval(const Rect.fromLTWH(22, 7, 56, 86), globeLines);
    canvas.drawArc(
      const Rect.fromLTWH(7, 25, 86, 48),
      0,
      math.pi * 2,
      false,
      globeLines,
    );
    canvas.restore();
    canvas.drawPath(
      shape,
      Paint()
        ..color = colors.first.withValues(alpha: .82)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.2,
    );
  }

  void _paintButton(Canvas canvas) {
    final color = switch (id) {
      'albumium:button_star' => const Color(0xFFE9C458),
      'albumium:button_flower' => const Color(0xFFB787C4),
      'albumium:button_heart' => const Color(0xFFE7809E),
      _ => const Color(0xFF7AB0A2),
    };
    final shape = switch (id) {
      'albumium:button_star' => _starPath(const Offset(50, 50), 44, 24),
      'albumium:button_flower' => _flowerPath(const Offset(50, 50), 44, 31),
      'albumium:button_heart' => _heartPath(const Rect.fromLTWH(8, 9, 84, 82)),
      _ => Path()..addOval(const Rect.fromLTWH(8, 8, 84, 84)),
    };
    canvas.drawShadow(shape, const Color(0x66000000), 5, false);
    canvas.drawPath(
      shape,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-.38, -.44),
          radius: .95,
          colors: [
            Color.lerp(color, Colors.white, .7)!,
            color,
            Color.lerp(color, Colors.black, .38)!,
          ],
          stops: const [0, .58, 1],
        ).createShader(const Rect.fromLTWH(5, 5, 90, 90)),
    );
    canvas.save();
    canvas.clipPath(shape);
    for (var i = 0; i < 22; i++) {
      final x = 12.0 + (i * 23) % 77;
      final y = 11.0 + (i * 31) % 78;
      canvas.drawCircle(
        Offset(x, y),
        i.isEven ? 1.2 : .7,
        Paint()
          ..color = (i % 3 == 0 ? Colors.white : Colors.black).withValues(
            alpha: .12,
          ),
      );
    }
    canvas.drawOval(
      const Rect.fromLTWH(19, 14, 45, 22),
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0x99FFFFFF), Color(0x00FFFFFF)],
        ).createShader(const Rect.fromLTWH(19, 14, 45, 22)),
    );
    canvas.restore();
    canvas.drawPath(
      shape,
      Paint()
        ..color = Color.lerp(color, Colors.black, .28)!
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.6,
    );
    final inset = Paint()
      ..color = Colors.white.withValues(alpha: .5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2;
    canvas.drawCircle(const Offset(50, 51), 23, inset);

    final holePaint = Paint()
      ..shader = const RadialGradient(
        colors: [Color(0xFF342A28), Color(0xFF826B60)],
      ).createShader(const Rect.fromLTWH(38, 39, 25, 25));
    final thread = Paint()
      ..color = const Color(0xFFF7EBD7)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    for (final hole in const [
      Offset(43, 44),
      Offset(57, 44),
      Offset(43, 58),
      Offset(57, 58),
    ]) {
      canvas.drawCircle(
        hole.translate(1.5, 1.7),
        4.5,
        Paint()..color = Colors.black.withValues(alpha: .32),
      );
      canvas.drawCircle(hole, 3.8, holePaint);
      canvas.drawArc(
        Rect.fromCircle(center: hole, radius: 3.2),
        math.pi,
        math.pi,
        false,
        Paint()
          ..color = Colors.white.withValues(alpha: .4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = .8,
      );
    }
    canvas.drawLine(const Offset(43, 44), const Offset(57, 58), thread);
    canvas.drawLine(const Offset(57, 44), const Offset(43, 58), thread);
  }

  void _paintFabricSticker(Canvas canvas) {
    const thread = Color(0xFFF5E6CE);
    if (id.endsWith('safety_pin')) {
      final metal = Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xFF6F706F), Color(0xFFE8E2D8), Color(0xFF77746D)],
        ).createShader(const Rect.fromLTWH(10, 5, 80, 90))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round;
      final pin = Path()
        ..moveTo(25, 18)
        ..cubicTo(7, 32, 12, 84, 43, 87)
        ..cubicTo(68, 89, 83, 65, 74, 47)
        ..lineTo(31, 18)
        ..cubicTo(24, 13, 22, 11, 25, 18);
      canvas.drawShadow(pin, const Color(0x55000000), 3, false);
      canvas.drawPath(pin, metal);
      canvas.drawLine(
        const Offset(31, 18),
        const Offset(88, 12),
        metal..strokeWidth = 2.3,
      );
      return;
    }
    if (id.endsWith('lace')) {
      final lace = Paint()..color = const Color(0xFFF2E5D0);
      final band = RRect.fromRectAndRadius(
        const Rect.fromLTWH(4, 30, 92, 39),
        const Radius.circular(5),
      );
      canvas.drawShadow(
        Path()..addRRect(band),
        const Color(0x44000000),
        3,
        false,
      );
      canvas.drawRRect(band, lace);
      for (var x = 8.0; x < 96; x += 11) {
        canvas.drawCircle(Offset(x, 28), 5.5, lace);
        canvas.drawCircle(Offset(x, 71), 5.5, lace);
        canvas.drawCircle(
          Offset(x, 50),
          3,
          Paint()..color = const Color(0xFFBE9F82),
        );
      }
      for (final y in [40.0, 60.0]) {
        canvas.drawLine(
          Offset(7, y),
          Offset(93, y),
          Paint()
            ..color = const Color(0xFFC8AA8B)
            ..strokeWidth = 1.5,
        );
      }
      return;
    }
    if (id.endsWith('bow')) {
      final bow = Path()
        ..moveTo(48, 40)
        ..cubicTo(24, 12, 4, 22, 12, 53)
        ..cubicTo(18, 72, 35, 65, 49, 53)
        ..cubicTo(65, 67, 85, 73, 91, 51)
        ..cubicTo(97, 25, 73, 13, 52, 40)
        ..close();
      canvas.drawShadow(bow, const Color(0x55000000), 4, false);
      canvas.drawPath(
        bow,
        Paint()
          ..shader = const LinearGradient(
            colors: [Color(0xFFF0B9C0), Color(0xFFC66F80), Color(0xFFF4CED0)],
          ).createShader(const Rect.fromLTWH(7, 18, 88, 55)),
      );
      canvas.drawOval(
        const Rect.fromLTWH(39, 35, 23, 28),
        Paint()..color = const Color(0xFFB85E73),
      );
      return;
    }
    if (id.endsWith('crochet')) {
      final flower = _flowerPath(const Offset(50, 50), 45, 24);
      canvas.drawShadow(flower, const Color(0x44000000), 3, false);
      canvas.drawPath(flower, Paint()..color = const Color(0xFFB98BC5));
      final yarn = Paint()
        ..color = const Color(0xFFE6D5EA)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      for (var i = 0; i < 8; i++) {
        final angle = i * math.pi / 4;
        canvas.drawLine(
          const Offset(50, 50),
          Offset(50 + math.cos(angle) * 38, 50 + math.sin(angle) * 38),
          yarn,
        );
      }
      canvas.drawCircle(
        const Offset(50, 50),
        14,
        Paint()..color = const Color(0xFFE89B61),
      );
      canvas.drawCircle(const Offset(50, 50), 7, yarn);
      return;
    }

    final denim = id.endsWith('denim');
    final patch = RRect.fromRectAndRadius(
      const Rect.fromLTWH(7, 12, 86, 76),
      const Radius.circular(7),
    );
    canvas.drawShadow(
      Path()..addRRect(patch),
      const Color(0x55000000),
      4,
      false,
    );
    canvas.drawRRect(
      patch,
      Paint()
        ..color = denim ? const Color(0xFF4D7189) : const Color(0xFFE5A9A7),
    );
    canvas.save();
    canvas.clipRRect(patch);
    final pattern = Paint()
      ..color = Colors.white.withValues(alpha: denim ? .18 : .55)
      ..strokeWidth = denim ? 1 : 7;
    for (var p = -20.0; p < 120; p += denim ? 9 : 17) {
      canvas.drawLine(Offset(p, 4), Offset(p + 70, 98), pattern);
      if (!denim) canvas.drawLine(Offset(0, p), Offset(100, p), pattern);
    }
    canvas.restore();
    _drawStitches(canvas, const Rect.fromLTWH(12, 17, 76, 66), thread);
  }

  void _drawStitches(Canvas canvas, Rect rect, Color color) {
    final stitch = Paint()
      ..color = color
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    for (var x = rect.left; x < rect.right; x += 9) {
      canvas.drawLine(Offset(x, rect.top), Offset(x + 5, rect.top), stitch);
      canvas.drawLine(
        Offset(x, rect.bottom),
        Offset(x + 5, rect.bottom),
        stitch,
      );
    }
    for (var y = rect.top; y < rect.bottom; y += 9) {
      canvas.drawLine(Offset(rect.left, y), Offset(rect.left, y + 5), stitch);
      canvas.drawLine(Offset(rect.right, y), Offset(rect.right, y + 5), stitch);
    }
  }

  void _paintAnalogSticker(Canvas canvas) {
    const ink = Color(0xFF3E3834);
    if (id.endsWith('polaroid')) {
      final outer = RRect.fromRectAndRadius(
        const Rect.fromLTWH(11, 3, 78, 94),
        const Radius.circular(3),
      );
      final window = RRect.fromRectAndRadius(
        const Rect.fromLTWH(20, 13, 60, 57),
        const Radius.circular(2),
      );
      final frame = Path.combine(
        PathOperation.difference,
        Path()..addRRect(outer),
        Path()..addRRect(window),
      );
      canvas.drawShadow(
        Path()..addRRect(outer),
        const Color(0x55000000),
        4,
        false,
      );
      canvas.drawPath(frame, Paint()..color = const Color(0xFFF5E8D3));
      canvas.drawLine(
        const Offset(30, 84),
        const Offset(70, 84),
        Paint()
          ..color = const Color(0xFFB76E78)
          ..strokeWidth = 2,
      );
      return;
    }
    if (id.endsWith('film_roll')) {
      canvas.drawCircle(const Offset(39, 43), 33, Paint()..color = ink);
      canvas.drawCircle(
        const Offset(39, 43),
        27,
        Paint()..color = const Color(0xFFB5A899),
      );
      for (var i = 0; i < 6; i++) {
        final angle = i * math.pi / 3;
        canvas.drawCircle(
          Offset(39 + math.cos(angle) * 17, 43 + math.sin(angle) * 17),
          6,
          Paint()..color = ink,
        );
      }
      final tail = Path()
        ..moveTo(54, 71)
        ..cubicTo(67, 78, 85, 69, 95, 87);
      canvas.drawPath(
        tail,
        Paint()
          ..color = ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8,
      );
      return;
    }
    if (id.endsWith('vinyl')) {
      final disc = Path()..addOval(const Rect.fromLTWH(7, 7, 86, 86));
      canvas.drawShadow(disc, const Color(0x55000000), 4, false);
      canvas.drawCircle(
        const Offset(50, 50),
        43,
        Paint()..color = const Color(0xFF272526),
      );
      for (var radius = 15.0; radius < 42; radius += 7) {
        canvas.drawCircle(
          const Offset(50, 50),
          radius,
          Paint()
            ..color = const Color(0xFF6C6562)
            ..style = PaintingStyle.stroke
            ..strokeWidth = .8,
        );
      }
      canvas.drawCircle(
        const Offset(50, 50),
        15,
        Paint()..color = const Color(0xFFD87682),
      );
      canvas.drawCircle(
        const Offset(50, 50),
        3,
        Paint()..color = const Color(0xFFF3E5CF),
      );
      return;
    }
    if (id.endsWith('cassette')) {
      final body = RRect.fromRectAndRadius(
        const Rect.fromLTWH(4, 17, 92, 66),
        const Radius.circular(8),
      );
      canvas.drawShadow(
        Path()..addRRect(body),
        const Color(0x55000000),
        4,
        false,
      );
      canvas.drawRRect(body, Paint()..color = const Color(0xFF77A6A9));
      canvas.drawRect(
        const Rect.fromLTWH(14, 26, 72, 34),
        Paint()..color = const Color(0xFFF1DFC4),
      );
      for (final x in [34.0, 66.0]) {
        canvas.drawCircle(Offset(x, 43), 11, Paint()..color = ink);
        canvas.drawCircle(
          Offset(x, 43),
          5,
          Paint()..color = const Color(0xFFE8C38A),
        );
      }
      final base = Path()
        ..moveTo(25, 66)
        ..lineTo(75, 66)
        ..lineTo(83, 78)
        ..lineTo(17, 78)
        ..close();
      canvas.drawPath(base, Paint()..color = const Color(0xFF555052));
      return;
    }
    if (id.endsWith('camcorder')) {
      final body = RRect.fromRectAndRadius(
        const Rect.fromLTWH(20, 24, 68, 52),
        const Radius.circular(8),
      );
      canvas.drawShadow(
        Path()..addRRect(body),
        const Color(0x55000000),
        4,
        false,
      );
      canvas.drawRRect(body, Paint()..color = const Color(0xFFC8B7A3));
      canvas.drawRect(
        const Rect.fromLTWH(7, 35, 20, 31),
        Paint()..color = const Color(0xFF6C6761),
      );
      canvas.drawCircle(const Offset(25, 50), 18, Paint()..color = ink);
      canvas.drawCircle(
        const Offset(25, 50),
        10,
        Paint()..color = const Color(0xFF66859A),
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(41, 13, 35, 14),
          const Radius.circular(5),
        ),
        Paint()..color = ink,
      );
      canvas.drawCircle(
        const Offset(76, 39),
        4,
        Paint()..color = const Color(0xFFD16A69),
      );
      return;
    }

    final strip = RRect.fromRectAndRadius(
      const Rect.fromLTWH(2, 24, 96, 52),
      const Radius.circular(4),
    );
    canvas.drawRRect(strip, Paint()..color = ink);
    for (var x = 7.0; x < 97; x += 12) {
      for (final y in [29.0, 63.0]) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, y, 7, 8),
            const Radius.circular(1),
          ),
          Paint()..color = const Color(0xFFE8D8BD),
        );
      }
    }
    for (var x = 9.0; x < 92; x += 23) {
      canvas.drawRect(
        Rect.fromLTWH(x, 41, 18, 18),
        Paint()..color = const Color(0xFF855C53),
      );
    }
  }

  void _paintSkySticker(Canvas canvas) {
    const gold = Color(0xFFE5BB5F);
    const blue = Color(0xFF607F9A);
    if (id.endsWith('moon')) {
      final moon = Path.combine(
        PathOperation.difference,
        Path()..addOval(const Rect.fromLTWH(14, 7, 73, 86)),
        Path()..addOval(const Rect.fromLTWH(38, 0, 65, 74)),
      );
      canvas.drawShadow(moon, const Color(0x55000000), 4, false);
      canvas.drawPath(moon, Paint()..color = gold);
      canvas.drawPath(
        _starPath(const Offset(73, 24), 9, 4),
        Paint()..color = const Color(0xFFD88A9C),
      );
      return;
    }
    if (id.endsWith('cloud')) {
      final cloud = Path()
        ..addOval(const Rect.fromLTWH(7, 43, 42, 33))
        ..addOval(const Rect.fromLTWH(27, 22, 46, 54))
        ..addOval(const Rect.fromLTWH(57, 40, 36, 36))
        ..addRect(const Rect.fromLTWH(24, 50, 54, 27));
      canvas.drawShadow(cloud, const Color(0x44000000), 4, false);
      canvas.drawPath(cloud, Paint()..color = const Color(0xFFD8E1E4));
      for (final x in [30.0, 50.0, 70.0]) {
        canvas.drawLine(
          Offset(x, 82),
          Offset(x - 5, 94),
          Paint()
            ..color = blue
            ..strokeWidth = 3
            ..strokeCap = StrokeCap.round,
        );
      }
      return;
    }
    if (id.endsWith('rainbow')) {
      final colors = [
        const Color(0xFFC96E78),
        const Color(0xFFE4B268),
        const Color(0xFF7DA59A),
        const Color(0xFF8294AE),
      ];
      for (var i = 0; i < colors.length; i++) {
        canvas.drawArc(
          Rect.fromLTWH(8 + i * 8, 20 + i * 8, 84 - i * 16, 84 - i * 16),
          math.pi,
          math.pi,
          false,
          Paint()
            ..color = colors[i]
            ..style = PaintingStyle.stroke
            ..strokeWidth = 8,
        );
      }
      return;
    }
    if (id.endsWith('sun')) {
      final rays = Paint()
        ..color = gold
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round;
      for (var i = 0; i < 12; i++) {
        final angle = i * math.pi / 6;
        canvas.drawLine(
          Offset(50 + math.cos(angle) * 34, 50 + math.sin(angle) * 34),
          Offset(50 + math.cos(angle) * 46, 50 + math.sin(angle) * 46),
          rays,
        );
      }
      canvas.drawCircle(const Offset(50, 50), 28, Paint()..color = gold);
      final face = Paint()..color = const Color(0xFF665043);
      canvas.drawCircle(const Offset(41, 47), 2.5, face);
      canvas.drawCircle(const Offset(59, 47), 2.5, face);
      canvas.drawArc(
        const Rect.fromLTWH(39, 47, 22, 17),
        .25,
        math.pi - .5,
        false,
        face
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      return;
    }
    if (id.endsWith('comet')) {
      final colors = [
        blue,
        const Color(0xFFD28B9C),
        gold,
        const Color(0xFF7FA47F),
      ];
      for (var i = 0; i < 4; i++) {
        canvas.drawLine(
          Offset(11, 77 - i * 10),
          Offset(58, 42 - i * 4),
          Paint()
            ..color = colors[i]
            ..strokeWidth = 4
            ..strokeCap = StrokeCap.round,
        );
      }
      canvas.drawPath(
        _starPath(const Offset(70, 31), 26, 12),
        Paint()..color = gold,
      );
      return;
    }

    const stars = [
      Offset(13, 75),
      Offset(28, 33),
      Offset(49, 53),
      Offset(67, 20),
      Offset(87, 39),
      Offset(76, 80),
    ];
    final line = Paint()
      ..color = blue.withValues(alpha: .7)
      ..strokeWidth = 1.5;
    for (var i = 0; i < stars.length - 1; i++) {
      canvas.drawLine(stars[i], stars[i + 1], line);
    }
    for (final star in stars) {
      canvas.drawCircle(star, 4, Paint()..color = gold);
      canvas.drawCircle(star, 8, Paint()..color = gold.withValues(alpha: .18));
    }
  }

  void _paintTravelSticker(Canvas canvas) {
    const leather = Color(0xFF8D5B47);
    const brass = Color(0xFFD2AA58);
    const paper = Color(0xFFF1E3CA);
    if (id.endsWith('passport')) {
      final cover = RRect.fromRectAndRadius(
        const Rect.fromLTWH(20, 5, 61, 90),
        const Radius.circular(6),
      );
      canvas.drawShadow(
        Path()..addRRect(cover),
        const Color(0x55000000),
        4,
        false,
      );
      canvas.drawRRect(cover, Paint()..color = const Color(0xFF466A73));
      canvas.drawCircle(
        const Offset(50, 48),
        19,
        Paint()
          ..color = brass
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      canvas.drawLine(
        const Offset(31, 48),
        const Offset(69, 48),
        Paint()
          ..color = brass
          ..strokeWidth = 1.5,
      );
      canvas.drawOval(
        const Rect.fromLTWH(40, 29, 20, 38),
        Paint()
          ..color = brass
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
      _drawLabel(
        canvas,
        'PASAPORT',
        const Rect.fromLTWH(26, 72, 49, 13),
        brass,
        8,
      );
      return;
    }
    if (id.endsWith('suitcase')) {
      final bag = RRect.fromRectAndRadius(
        const Rect.fromLTWH(9, 25, 82, 65),
        const Radius.circular(8),
      );
      canvas.drawShadow(
        Path()..addRRect(bag),
        const Color(0x55000000),
        4,
        false,
      );
      canvas.drawRRect(bag, Paint()..color = leather);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(35, 9, 30, 24),
          const Radius.circular(5),
        ),
        Paint()
          ..color = leather
          ..style = PaintingStyle.stroke
          ..strokeWidth = 7,
      );
      for (final x in [25.0, 70.0]) {
        canvas.drawRect(Rect.fromLTWH(x, 26, 7, 63), Paint()..color = brass);
      }
      canvas.drawCircle(const Offset(50, 57), 12, Paint()..color = paper);
      _drawLabel(canvas, 'A', const Rect.fromLTWH(42, 48, 16, 18), leather, 13);
      return;
    }
    if (id.endsWith('compass')) {
      final compass = Path()..addOval(const Rect.fromLTWH(7, 7, 86, 86));
      canvas.drawShadow(compass, const Color(0x55000000), 4, false);
      canvas.drawCircle(const Offset(50, 50), 43, Paint()..color = brass);
      canvas.drawCircle(const Offset(50, 50), 34, Paint()..color = paper);
      final needle = Path()
        ..moveTo(50, 16)
        ..lineTo(60, 54)
        ..lineTo(50, 84)
        ..lineTo(40, 46)
        ..close();
      canvas.drawPath(needle, Paint()..color = const Color(0xFFB8494E));
      canvas.drawLine(
        const Offset(16, 50),
        const Offset(84, 50),
        Paint()
          ..color = leather
          ..strokeWidth = 1,
      );
      canvas.drawCircle(const Offset(50, 50), 4, Paint()..color = leather);
      return;
    }
    if (id.endsWith('motel_key')) {
      final tag = Path()
        ..moveTo(50, 5)
        ..lineTo(90, 49)
        ..lineTo(50, 94)
        ..lineTo(10, 49)
        ..close();
      canvas.drawShadow(tag, const Color(0x55000000), 4, false);
      canvas.drawPath(tag, Paint()..color = const Color(0xFFD57D81));
      canvas.drawCircle(const Offset(50, 20), 5, Paint()..color = paper);
      _drawLabel(
        canvas,
        'ROOM',
        const Rect.fromLTWH(27, 37, 46, 16),
        paper,
        10,
      );
      _drawLabel(canvas, '24', const Rect.fromLTWH(31, 54, 38, 23), paper, 19);
      return;
    }
    if (id.endsWith('airplane_tag')) {
      final tag = Path()
        ..moveTo(5, 22)
        ..lineTo(75, 22)
        ..lineTo(96, 50)
        ..lineTo(75, 78)
        ..lineTo(5, 78)
        ..close();
      canvas.drawShadow(tag, const Color(0x44000000), 3, false);
      canvas.drawPath(tag, Paint()..color = paper);
      canvas.drawCircle(const Offset(79, 50), 6, Paint()..color = leather);
      final plane = Path()
        ..moveTo(20, 57)
        ..lineTo(62, 36)
        ..moveTo(38, 48)
        ..lineTo(29, 34)
        ..moveTo(48, 43)
        ..lineTo(51, 62);
      canvas.drawPath(
        plane,
        Paint()
          ..color = const Color(0xFF4F7382)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 4
          ..strokeCap = StrokeCap.round,
      );
      return;
    }

    final map = Path()
      ..moveTo(3, 17)
      ..lineTo(34, 8)
      ..lineTo(65, 18)
      ..lineTo(97, 8)
      ..lineTo(97, 82)
      ..lineTo(66, 92)
      ..lineTo(35, 82)
      ..lineTo(3, 92)
      ..close();
    canvas.drawShadow(map, const Color(0x44000000), 3, false);
    canvas.drawPath(map, Paint()..color = paper);
    final fold = Paint()
      ..color = const Color(0xFFB7A489)
      ..strokeWidth = 2;
    canvas.drawLine(const Offset(34, 9), const Offset(35, 82), fold);
    canvas.drawLine(const Offset(65, 18), const Offset(66, 92), fold);
    final route = Path()
      ..moveTo(17, 69)
      ..cubicTo(34, 29, 58, 78, 82, 29);
    canvas.drawPath(
      route,
      Paint()
        ..color = const Color(0xFFC4585B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
    canvas.drawCircle(
      const Offset(17, 69),
      5,
      Paint()..color = const Color(0xFFC4585B),
    );
    canvas.drawPath(
      _starPath(const Offset(82, 29), 7, 3),
      Paint()..color = brass,
    );
  }

  void _paintCafeSticker(Canvas canvas) {
    const pink = Color(0xFFD77E91);
    const cream = Color(0xFFF2DDBB);
    const brown = Color(0xFF785342);
    if (id.endsWith('coffee') || id.endsWith('teacup')) {
      final floral = id.endsWith('teacup');
      final cupColor = floral
          ? const Color(0xFFBFD3C3)
          : const Color(0xFFE3B18B);
      final cup = Path()
        ..moveTo(15, 32)
        ..lineTo(74, 32)
        ..lineTo(68, 72)
        ..quadraticBezierTo(45, 87, 21, 72)
        ..close();
      canvas.drawShadow(cup, const Color(0x44000000), 3, false);
      canvas.drawPath(cup, Paint()..color = cupColor);
      canvas.drawOval(
        const Rect.fromLTWH(15, 26, 59, 14),
        Paint()..color = brown,
      );
      canvas.drawArc(
        const Rect.fromLTWH(63, 37, 30, 31),
        -math.pi / 2,
        math.pi,
        false,
        Paint()
          ..color = cupColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8,
      );
      canvas.drawOval(
        const Rect.fromLTWH(8, 74, 75, 13),
        Paint()..color = cream,
      );
      if (floral) {
        for (final center in const [
          Offset(31, 57),
          Offset(48, 65),
          Offset(58, 49),
        ]) {
          canvas.drawCircle(center, 4, Paint()..color = pink);
        }
      } else {
        for (final x in [32.0, 47.0, 62.0]) {
          canvas.drawPath(
            Path()
              ..moveTo(x, 21)
              ..cubicTo(x - 6, 13, x + 7, 9, x, 2),
            Paint()
              ..color = brown.withValues(alpha: .55)
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2,
          );
        }
      }
      return;
    }
    if (id.endsWith('cake')) {
      final slice = Path()
        ..moveTo(13, 77)
        ..lineTo(82, 77)
        ..lineTo(68, 25)
        ..lineTo(28, 25)
        ..close();
      canvas.drawShadow(slice, const Color(0x44000000), 3, false);
      canvas.drawPath(slice, Paint()..color = cream);
      canvas.drawRect(
        const Rect.fromLTWH(18, 52, 58, 11),
        Paint()..color = pink,
      );
      canvas.drawPath(
        Path()
          ..moveTo(24, 30)
          ..quadraticBezierTo(36, 17, 47, 29)
          ..quadraticBezierTo(59, 16, 72, 30),
        Paint()
          ..color = const Color(0xFFF5E7D4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 11,
      );
      canvas.drawCircle(
        const Offset(49, 16),
        8,
        Paint()..color = const Color(0xFFC54855),
      );
      return;
    }
    if (id.endsWith('strawberry')) {
      final berry = Path()
        ..moveTo(50, 92)
        ..cubicTo(30, 71, 13, 43, 23, 22)
        ..cubicTo(33, 7, 66, 7, 77, 22)
        ..cubicTo(88, 44, 70, 72, 50, 92)
        ..close();
      canvas.drawShadow(berry, const Color(0x44000000), 3, false);
      canvas.drawPath(berry, Paint()..color = const Color(0xFFD65261));
      for (var i = 0; i < 12; i++) {
        canvas.drawOval(
          Rect.fromCenter(
            center: Offset(31.0 + (i * 17) % 42, 30.0 + (i * 23) % 45),
            width: 3,
            height: 6,
          ),
          Paint()..color = cream,
        );
      }
      for (var i = 0; i < 5; i++) {
        canvas.drawPath(
          Path()
            ..moveTo(50, 20)
            ..lineTo(24 + i * 13, 6)
            ..lineTo(31 + i * 9, 27)
            ..close(),
          Paint()..color = const Color(0xFF5A8052),
        );
      }
      return;
    }
    if (id.endsWith('croissant')) {
      final pastry = Path()
        ..moveTo(8, 61)
        ..cubicTo(12, 24, 37, 11, 50, 36)
        ..cubicTo(65, 10, 91, 27, 92, 61)
        ..cubicTo(73, 92, 29, 92, 8, 61)
        ..close();
      canvas.drawShadow(pastry, const Color(0x44000000), 4, false);
      canvas.drawPath(pastry, Paint()..color = const Color(0xFFDFA154));
      for (var x = 25.0; x < 82; x += 15) {
        canvas.drawArc(
          Rect.fromLTWH(x - 12, 25, 25, 53),
          -.8,
          1.7,
          false,
          Paint()
            ..color = const Color(0xFFB97836)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3,
        );
      }
      return;
    }

    final wrapper = Path()
      ..moveTo(4, 36)
      ..lineTo(24, 25)
      ..lineTo(33, 38)
      ..lineTo(67, 38)
      ..lineTo(76, 25)
      ..lineTo(96, 36)
      ..lineTo(82, 51)
      ..lineTo(96, 66)
      ..lineTo(76, 76)
      ..lineTo(67, 63)
      ..lineTo(33, 63)
      ..lineTo(24, 76)
      ..lineTo(4, 66)
      ..lineTo(18, 51)
      ..close();
    canvas.drawShadow(wrapper, const Color(0x44000000), 3, false);
    canvas.drawPath(wrapper, Paint()..color = pink);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(26, 34, 48, 34),
        const Radius.circular(12),
      ),
      Paint()..color = cream,
    );
    canvas.drawPath(
      _heartPath(const Rect.fromLTWH(40, 41, 20, 20)),
      Paint()..color = pink,
    );
  }

  void _paintWordLabel(Canvas canvas) {
    final data = switch (id) {
      'albumium:words_today' => (
        'BUGÜN',
        const Color(0xFFE5B5B8),
        const Color(0xFF6F3E46),
      ),
      'albumium:words_us' => (
        'BİZ',
        const Color(0xFF9BB8B7),
        const Color(0xFF35545A),
      ),
      'albumium:words_memory' => (
        'ANI',
        const Color(0xFFE4C879),
        const Color(0xFF6C5228),
      ),
      'albumium:words_goodday' => (
        'GÜZEL\u00A0GÜN',
        const Color(0xFFD4C4E1),
        const Color(0xFF5B496A),
      ),
      'albumium:words_lucky' => (
        'İYİ Kİ',
        const Color(0xFFC4D3A6),
        const Color(0xFF4A5D39),
      ),
      _ => ('YOLCULUK', const Color(0xFFB9C9DC), const Color(0xFF3D5269)),
    };
    final label = Path()
      ..moveTo(4, 25)
      ..lineTo(88, 20)
      ..lineTo(97, 48)
      ..lineTo(90, 77)
      ..lineTo(8, 82)
      ..lineTo(1, 53)
      ..close();
    canvas.drawShadow(label, const Color(0x44000000), 3, false);
    canvas.drawPath(label, Paint()..color = data.$2);
    _drawStitches(
      canvas,
      const Rect.fromLTWH(10, 30, 79, 43),
      Colors.white.withValues(alpha: .65),
    );
    _drawLabel(
      canvas,
      data.$1,
      const Rect.fromLTWH(11, 37, 78, 28),
      data.$3,
      data.$1.length > 8 ? 11.5 : (data.$1.length > 7 ? 14 : 18),
    );
  }

  void _drawLabel(
    Canvas canvas,
    String text,
    Rect bounds,
    Color color,
    double fontSize,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: fontSize,
          fontWeight: FontWeight.w800,
          fontFamily: 'CraftQuicksand',
          letterSpacing: .5,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
      maxLines: 1,
    )..layout(maxWidth: bounds.width);
    painter.paint(
      canvas,
      Offset(
        bounds.left + (bounds.width - painter.width) / 2,
        bounds.top + (bounds.height - painter.height) / 2,
      ),
    );
  }

  void _paintCatSticker(Canvas canvas) {
    final warm = id.endsWith('bow') || id.endsWith('flowers');
    final fur = warm ? const Color(0xFFC98B62) : const Color(0xFF77736D);
    final dark = Color.lerp(fur, Colors.black, .42)!;
    final silhouette = Path()
      ..addOval(const Rect.fromLTWH(18, 50, 64, 47))
      ..addOval(const Rect.fromLTWH(12, 15, 76, 64))
      ..moveTo(20, 33)
      ..lineTo(22, 4)
      ..lineTo(43, 21)
      ..close()
      ..moveTo(57, 21)
      ..lineTo(79, 4)
      ..lineTo(82, 34)
      ..close();
    canvas.drawShadow(silhouette, const Color(0x66000000), 5, false);
    canvas.drawPath(
      silhouette,
      Paint()
        ..color = const Color(0xFFF8F1E6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9
        ..strokeJoin = StrokeJoin.round,
    );
    canvas.drawPath(
      silhouette,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-.25, -.35),
          colors: [Color.lerp(fur, Colors.white, .38)!, fur, dark],
        ).createShader(const Rect.fromLTWH(10, 4, 80, 94)),
    );

    final innerEar = Paint()..color = const Color(0xFFD99A9A);
    canvas.drawPath(
      Path()
        ..moveTo(24, 26)
        ..lineTo(25, 11)
        ..lineTo(37, 23)
        ..close(),
      innerEar,
    );
    canvas.drawPath(
      Path()
        ..moveTo(63, 23)
        ..lineTo(76, 11)
        ..lineTo(78, 27)
        ..close(),
      innerEar,
    );

    final eye = Paint()..color = const Color(0xFF2A2523);
    for (final x in [35.0, 65.0]) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, 43), width: 13, height: 16),
        eye,
      );
      canvas.drawCircle(
        Offset(x - 2, 40),
        3,
        Paint()..color = const Color(0xFFFFFFFF),
      );
      canvas.drawCircle(
        Offset(x + 2, 46),
        2,
        Paint()..color = const Color(0xFFB6C794),
      );
    }
    canvas.drawOval(
      const Rect.fromLTWH(40, 51, 20, 15),
      Paint()..color = const Color(0xFFE4C0A8),
    );
    canvas.drawPath(
      Path()
        ..moveTo(45, 54)
        ..quadraticBezierTo(50, 50, 55, 54)
        ..quadraticBezierTo(50, 61, 45, 54),
      Paint()..color = const Color(0xFF9D6267),
    );
    final whisker = Paint()
      ..color = const Color(0xFF4E4641)
      ..strokeWidth = 1.2;
    for (final y in [56.0, 61.0]) {
      canvas.drawLine(Offset(17, y), Offset(42, y + 2), whisker);
      canvas.drawLine(Offset(58, y + 2), Offset(84, y), whisker);
    }
    final furStroke = Paint()
      ..color = dark.withValues(alpha: .45)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    for (var i = 0; i < 18; i++) {
      final x = 23.0 + (i * 17) % 56;
      final y = 24.0 + (i * 23) % 59;
      canvas.drawLine(
        Offset(x, y),
        Offset(x + (i.isEven ? 4 : -4), y + 5),
        furStroke,
      );
    }

    if (id.endsWith('glasses')) {
      final glasses = Paint()
        ..color = const Color(0xFF242121)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(22, 33, 25, 22),
          const Radius.circular(6),
        ),
        glasses,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(53, 33, 25, 22),
          const Radius.circular(6),
        ),
        glasses,
      );
      canvas.drawLine(const Offset(47, 42), const Offset(53, 42), glasses);
    } else if (id.endsWith('bow')) {
      _paintMiniBow(canvas, const Offset(74, 19), const Color(0xFFE18DA7));
    } else if (id.endsWith('flowers')) {
      for (var i = 0; i < 4; i++) {
        _drawFlower(
          canvas,
          Offset(28 + i * 15, 84 - (i.isEven ? 4 : 0)),
          i.isEven ? const Color(0xFFD8788B) : const Color(0xFFE4BC5A),
          i * .3,
        );
      }
    } else if (id.endsWith('hat')) {
      final hat = Path()
        ..moveTo(33, 23)
        ..lineTo(50, -3)
        ..lineTo(67, 23)
        ..close();
      canvas.drawPath(hat, Paint()..color = const Color(0xFFD77791));
      canvas.drawCircle(
        const Offset(50, 0),
        5,
        Paint()..color = const Color(0xFFF0D08A),
      );
    } else if (id.endsWith('tie')) {
      final tie = Path()
        ..moveTo(44, 73)
        ..lineTo(56, 73)
        ..lineTo(61, 88)
        ..lineTo(50, 97)
        ..lineTo(39, 88)
        ..close();
      canvas.drawPath(tie, Paint()..color = const Color(0xFF5A7790));
    } else {
      final camera = RRect.fromRectAndRadius(
        const Rect.fromLTWH(31, 75, 38, 22),
        const Radius.circular(4),
      );
      canvas.drawRRect(camera, Paint()..color = const Color(0xFF3D3937));
      canvas.drawCircle(
        const Offset(50, 86),
        8,
        Paint()..color = const Color(0xFF7BA1AD),
      );
    }
  }

  void _paintMonkeySticker(Canvas canvas) {
    const fur = Color(0xFF806047);
    const face = Color(0xFFD1A67D);
    final silhouette = Path()
      ..addOval(const Rect.fromLTWH(20, 48, 60, 49))
      ..addOval(const Rect.fromLTWH(14, 9, 72, 70))
      ..addOval(const Rect.fromLTWH(3, 31, 27, 30))
      ..addOval(const Rect.fromLTWH(70, 31, 27, 30));
    canvas.drawShadow(silhouette, const Color(0x66000000), 5, false);
    canvas.drawPath(
      silhouette,
      Paint()
        ..color = const Color(0xFFF8F1E6)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9,
    );
    canvas.drawPath(
      silhouette,
      Paint()
        ..shader = const RadialGradient(
          center: Alignment(-.2, -.25),
          colors: [Color(0xFFB18A68), fur, Color(0xFF4B382B)],
        ).createShader(const Rect.fromLTWH(2, 8, 96, 90)),
    );
    canvas.drawOval(const Rect.fromLTWH(22, 22, 56, 49), Paint()..color = face);
    canvas.drawOval(
      const Rect.fromLTWH(32, 45, 36, 31),
      Paint()..color = const Color(0xFFE0BE99),
    );
    for (final x in [38.0, 62.0]) {
      canvas.drawCircle(
        Offset(x, 40),
        7,
        Paint()..color = const Color(0xFF251F1C),
      );
      canvas.drawCircle(Offset(x - 2, 37), 2.4, Paint()..color = Colors.white);
    }
    for (final x in [45.0, 55.0]) {
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, 55), width: 4, height: 6),
        Paint()..color = const Color(0xFF5A4032),
      );
    }
    canvas.drawArc(
      const Rect.fromLTWH(39, 55, 22, 14),
      .15,
      math.pi - .3,
      false,
      Paint()
        ..color = const Color(0xFF6F3E38)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
    final furLine = Paint()
      ..color = const Color(0xFF3E2D24).withValues(alpha: .45)
      ..strokeWidth = 1.3;
    for (var i = 0; i < 20; i++) {
      final x = 20.0 + (i * 19) % 62;
      final y = 14.0 + (i * 29) % 78;
      canvas.drawLine(Offset(x, y), Offset(x + 3, y + 5), furLine);
    }

    if (id.endsWith('crown')) {
      final crown = Path()
        ..moveTo(28, 22)
        ..lineTo(25, 1)
        ..lineTo(39, 11)
        ..lineTo(50, -1)
        ..lineTo(61, 11)
        ..lineTo(75, 1)
        ..lineTo(72, 23)
        ..close();
      canvas.drawPath(crown, Paint()..color = const Color(0xFFE2B752));
    } else if (id.endsWith('party')) {
      final hat = Path()
        ..moveTo(32, 22)
        ..lineTo(51, -4)
        ..lineTo(69, 23)
        ..close();
      canvas.drawPath(hat, Paint()..color = const Color(0xFFCF799A));
      for (var y = 4.0; y < 20; y += 7) {
        canvas.drawCircle(
          Offset(49, y),
          2.2,
          Paint()..color = const Color(0xFFF0CE66),
        );
      }
    } else if (id.endsWith('balloons')) {
      for (var i = 0; i < 3; i++) {
        final color = [
          const Color(0xFFD87D91),
          const Color(0xFF7EA6A2),
          const Color(0xFFE5BA5C),
        ][i];
        canvas.drawOval(
          Rect.fromLTWH(4 + i * 32, 0 + i * 5, 22, 31),
          Paint()..color = color,
        );
        canvas.drawLine(
          Offset(15 + i * 32, 30 + i * 5),
          const Offset(50, 90),
          Paint()
            ..color = color
            ..strokeWidth = 1.2,
        );
      }
    } else if (id.endsWith('glasses')) {
      final glasses = Paint()
        ..color = const Color(0xFF2E3030)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5;
      canvas.drawCircle(const Offset(37, 40), 12, glasses);
      canvas.drawCircle(const Offset(63, 40), 12, glasses);
      canvas.drawLine(const Offset(49, 40), const Offset(51, 40), glasses);
    } else if (id.endsWith('flowers')) {
      for (var i = 0; i < 5; i++) {
        _drawFlower(
          canvas,
          Offset(20 + i * 15, 82 - (i.isEven ? 3 : 0)),
          i.isEven ? const Color(0xFFD37C8C) : const Color(0xFFE1B758),
          i * .2,
        );
      }
    } else {
      final arms = Paint()
        ..color = fur
        ..strokeWidth = 10
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(const Offset(25, 70), const Offset(7, 46), arms);
      canvas.drawLine(const Offset(75, 70), const Offset(94, 42), arms);
    }
  }

  void _paintMiniBow(Canvas canvas, Offset center, Color color) {
    canvas.drawOval(
      Rect.fromCenter(center: center.translate(-9, 0), width: 19, height: 14),
      Paint()..color = color,
    );
    canvas.drawOval(
      Rect.fromCenter(center: center.translate(9, 0), width: 19, height: 14),
      Paint()..color = color,
    );
    canvas.drawCircle(
      center,
      6,
      Paint()..color = Color.lerp(color, Colors.black, .18)!,
    );
  }

  Path _heartPath(Rect rect) {
    final path = Path();
    path.moveTo(rect.center.dx, rect.bottom);
    path.cubicTo(
      rect.left + rect.width * .08,
      rect.top + rect.height * .63,
      rect.left - rect.width * .02,
      rect.top + rect.height * .28,
      rect.left + rect.width * .24,
      rect.top + rect.height * .16,
    );
    path.cubicTo(
      rect.left + rect.width * .39,
      rect.top + rect.height * .08,
      rect.center.dx,
      rect.top + rect.height * .22,
      rect.center.dx,
      rect.top + rect.height * .34,
    );
    path.cubicTo(
      rect.center.dx,
      rect.top + rect.height * .22,
      rect.left + rect.width * .61,
      rect.top + rect.height * .08,
      rect.left + rect.width * .76,
      rect.top + rect.height * .16,
    );
    path.cubicTo(
      rect.right + rect.width * .02,
      rect.top + rect.height * .28,
      rect.right - rect.width * .08,
      rect.top + rect.height * .63,
      rect.center.dx,
      rect.bottom,
    );
    path.close();
    return path;
  }

  Path _starPath(Offset center, double outerRadius, double innerRadius) {
    final path = Path();
    for (var i = 0; i < 10; i++) {
      final radius = i.isEven ? outerRadius : innerRadius;
      final angle = -math.pi / 2 + i * math.pi / 5;
      final point = center + Offset(math.cos(angle), math.sin(angle)) * radius;
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    return path;
  }

  Path _flowerPath(Offset center, double outerRadius, double innerRadius) {
    final path = Path();
    for (var i = 0; i < 16; i++) {
      final radius = i.isEven ? outerRadius : innerRadius;
      final angle = -math.pi / 2 + i * math.pi / 8;
      final point = center + Offset(math.cos(angle), math.sin(angle)) * radius;
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    return path;
  }

  void _paintStarDoodle(Canvas canvas) {
    final ink = Paint()
      ..color = const Color(0xFFB88B45)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    final stars = <Offset>[
      const Offset(22, 27),
      const Offset(52, 48),
      const Offset(81, 22),
      const Offset(77, 78),
      const Offset(25, 76),
    ];
    for (var i = 0; i < stars.length; i++) {
      final c = stars[i];
      final r = i == 1 ? 15.0 : 8.0;
      canvas.drawLine(c - Offset(r, 0), c + Offset(r, 0), ink);
      canvas.drawLine(c - Offset(0, r), c + Offset(0, r), ink);
      canvas.drawLine(
        c - Offset(r * .45, r * .45),
        c + Offset(r * .45, r * .45),
        ink,
      );
      canvas.drawLine(
        c + Offset(-r * .45, r * .45),
        c + Offset(r * .45, -r * .45),
        ink,
      );
    }
    canvas.drawCircle(const Offset(52, 48), 24, ink..strokeWidth = 1.2);
  }

  @override
  bool shouldRepaint(covariant _IllustratedStickerPainter oldDelegate) =>
      oldDelegate.id != id;
}
