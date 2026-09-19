import 'package:flutter/material.dart';

import '../themes/album_themes.dart';

enum AlbumElementType { photo, text, sticker, drawing, card }

/// Paint order follows the order of [AlbumPageModel.elements]: the first item
/// is at the back and the last item is at the front.
enum AlbumElementLayerAction { moveDown, moveUp, sendToBack, bringToFront }

const albumElementMinScale = 0.35;
const albumElementMaxScale = 3.5;
const albumElementScaleStep = 1.12;

/// The crop silhouette applied to a photo independently from its decorative
/// frame. Existing albums use [free] so their saved layout stays unchanged.
enum AlbumPhotoShape { free, square, landscape, portrait, circle, arch, torn }

/// Kütüphanede albümler ile bağımsız özel gün kartlarını birlikte saklar.
enum AlbumProjectType { album, occasionCard }

enum AlbumBindingType {
  spiral(
    'Telli Spiral',
    '🔗 Metal spiral halkalar',
    Icons.radio_button_checked,
  ),
  stitched(
    'Dikişli Klasik',
    '🧵 İplik dikişli cilt',
    Icons.linear_scale_rounded,
  ),
  leatherStrap(
    'Deri Kordonlu',
    '🎗️ Tokalı deri bağlama',
    Icons.bookmark_border_rounded,
  ),
  hardcover('Sert Kapak', '📖 Lüks cilt kapağı', Icons.menu_book_rounded),
  vintageCord(
    'Nostaljik Kordon',
    '🪢 Bükümlü ip bağlama',
    Icons.all_inclusive_rounded,
  );

  const AlbumBindingType(this.title, this.description, this.icon);

  final String title;
  final String description;
  final IconData icon;
}

/// Groups covers in the picker. "Tümü" is not a member: an absent category
/// (null) means no filter, the same way the occasion card picker works.
enum AlbumThemeCategory {
  travel('Seyahat', Icons.flight_takeoff_rounded),
  family('Aile', Icons.family_restroom_rounded),
  love('Aşk', Icons.favorite_rounded),
  wedding('Düğün & Nişan', Icons.diamond_outlined),
  friendship('Arkadaşlık', Icons.groups_rounded),
  animals('Hayvanlar', Icons.pets_rounded);

  const AlbumThemeCategory(this.label, this.icon);

  final String label;
  final IconData icon;
}

class AlbumThemePreset {
  const AlbumThemePreset({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.emoji,
    required this.coverStart,
    required this.coverEnd,
    required this.pageColor,
    required this.accent,
    required this.textureLabel,
    this.category = AlbumThemeCategory.love,
    this.isPremium = false,
    this.coverAsset,
  });

  final String id;
  final String name;
  final String subtitle;
  final String emoji;
  final Color coverStart;
  final Color coverEnd;
  final Color pageColor;
  final Color accent;
  final String textureLabel;

  /// Where the cover shows up in the picker.
  final AlbumThemeCategory category;

  /// Premium covers have to be unlocked before a new album can use them.
  /// Albums already saved with the theme keep rendering it either way.
  final bool isPremium;

  /// Optional high-resolution physical cover artwork. The artwork is kept
  /// separate from the saved album JSON, so older albums gain the richer
  /// cover automatically after an app update.
  final String? coverAsset;
}

const albumThemes = <AlbumThemePreset>[
  AlbumThemePreset(
    id: 'soft_romance',
    name: 'Soft Romance',
    subtitle: 'Pudra pembesi, kalpler ve polaroid',
    emoji: '❤️',
    coverStart: SoftRomancePalette.blush,
    coverEnd: SoftRomancePalette.rose,
    pageColor: SoftRomancePalette.cream,
    accent: SoftRomancePalette.deepRose,
    textureLabel: 'Keten',
    category: AlbumThemeCategory.love,
    coverAsset: 'assets/covers/cover-rose-heirloom.webp',
  ),
  AlbumThemePreset(
    id: 'vintage_diary',
    name: 'Vintage Diary',
    subtitle: 'Eskimiş kâğıt, daktilo & bant köşeleri',
    emoji: '📜',
    coverStart: VintageDiaryPalette.paperDark,
    coverEnd: VintageDiaryPalette.ink,
    pageColor: VintageDiaryPalette.agedPaper,
    accent: VintageDiaryPalette.sepia,
    textureLabel: 'Deri',
    category: AlbumThemeCategory.family,
    isPremium: true,
    coverAsset: 'assets/covers/cover-vintage-quill.webp',
  ),
  AlbumThemePreset(
    id: 'animals',
    name: 'Animals',
    subtitle: 'Kum & adaçayı tonları, pati izleri',
    emoji: '🐾',
    coverStart: AnimalsPalette.sage,
    coverEnd: AnimalsPalette.deepSage,
    pageColor: AnimalsPalette.cream,
    accent: AnimalsPalette.deepSage,
    textureLabel: 'Pati',
    category: AlbumThemeCategory.animals,
    isPremium: true,
    coverAsset: 'assets/covers/cover-obsidian-lion.webp',
  ),
  AlbumThemePreset(
    id: 'travel_postcard',
    name: 'Travel Postcard',
    subtitle: 'Kartpostal, posta damgası & airmail',
    emoji: '✈️',
    coverStart: TravelPostcardPalette.kraft,
    coverEnd: TravelPostcardPalette.ink,
    pageColor: TravelPostcardPalette.paper,
    accent: TravelPostcardPalette.airmailRed,
    textureLabel: 'Kanvas',
    category: AlbumThemeCategory.travel,
    isPremium: true,
    coverAsset: 'assets/covers/cover-atlas-compass.webp',
  ),
  AlbumThemePreset(
    id: 'best_friends',
    name: 'Best Friends',
    subtitle: 'Mor enerji, konfeti & tombul fontlar',
    emoji: '🎉',
    coverStart: BestFriendsPalette.violet,
    coverEnd: BestFriendsPalette.deepViolet,
    pageColor: BestFriendsPalette.lilac,
    accent: BestFriendsPalette.deepViolet,
    textureLabel: 'Parlak',
    category: AlbumThemeCategory.friendship,
    isPremium: true,
    coverAsset: 'assets/covers/cover-emerald-friendship.webp',
  ),
  AlbumThemePreset(
    id: 'minimal_editorial',
    name: 'Minimal Editorial',
    subtitle: 'Dergi sadeliği, ince tipografi & boşluk',
    emoji: '□',
    coverStart: MinimalEditorialPalette.hairline,
    coverEnd: MinimalEditorialPalette.ink,
    pageColor: MinimalEditorialPalette.paper,
    accent: MinimalEditorialPalette.accent,
    textureLabel: 'Mat',
    category: AlbumThemeCategory.wedding,
    isPremium: true,
    coverAsset: 'assets/covers/cover-minimal-editorial.webp',
  ),
  AlbumThemePreset(
    id: 'midnight_atlas',
    name: 'Midnight Atlas',
    subtitle: 'Lacivert deri, göksel desenler & altın varak',
    emoji: '🌙',
    coverStart: Color(0xFF20345C),
    coverEnd: Color(0xFF07101F),
    pageColor: Color(0xFFF2EADB),
    accent: Color(0xFFD6B56F),
    textureLabel: 'Kabartma deri',
    category: AlbumThemeCategory.travel,
    isPremium: true,
    coverAsset: 'assets/covers/cover-atlas-compass.webp',
  ),
  AlbumThemePreset(
    id: 'dark_leather',
    name: 'Dark Leather',
    subtitle: 'Deri cilt, altın varak & dikiş detayı',
    emoji: '🌑',
    coverStart: DarkLeatherPalette.leatherLight,
    coverEnd: DarkLeatherPalette.leather,
    pageColor: DarkLeatherPalette.page,
    accent: DarkLeatherPalette.gold,
    textureLabel: 'Deri',
    category: AlbumThemeCategory.wedding,
    isPremium: true,
    coverAsset: 'assets/covers/cover-obsidian-lion.webp',
  ),
  // City covers. They are free: the travel set is what brings people in.
  AlbumThemePreset(
    id: 'travel_istanbul',
    name: 'İstanbul',
    subtitle: 'Boğaz, martılar ve Galata',
    emoji: '🕌',
    coverStart: Color(0xFF609090),
    coverEnd: Color(0xFF003040),
    pageColor: Color(0xFFF5EBDC),
    accent: Color(0xFF005060),
    textureLabel: 'Kanvas',
    category: AlbumThemeCategory.travel,
    coverAsset: 'assets/covers/cover-travel-istanbul.webp',
  ),
  AlbumThemePreset(
    id: 'travel_kapadokya',
    name: 'Kapadokya',
    subtitle: 'Peri bacaları ve balonlar',
    emoji: '🎈',
    coverStart: Color(0xFFE0D0C0),
    coverEnd: Color(0xFF802000),
    pageColor: Color(0xFFF5EADC),
    accent: Color(0xFF902000),
    textureLabel: 'Kanvas',
    category: AlbumThemeCategory.travel,
    coverAsset: 'assets/covers/cover-travel-kapadokya.webp',
  ),
  AlbumThemePreset(
    id: 'travel_antalya',
    name: 'Antalya',
    subtitle: 'Akdeniz mavisi ve antik taş',
    emoji: '🏖️',
    coverStart: Color(0xFF1090C0),
    coverEnd: Color(0xFF002050),
    pageColor: Color(0xFFF5EFDC),
    accent: Color(0xFF0090C0),
    textureLabel: 'Kanvas',
    category: AlbumThemeCategory.travel,
    coverAsset: 'assets/covers/cover-travel-antalya.webp',
  ),
  AlbumThemePreset(
    id: 'travel_izmir',
    name: 'İzmir',
    subtitle: 'Körfez akşamları ve saat kulesi',
    emoji: '🕰️',
    coverStart: Color(0xFFB09060),
    coverEnd: Color(0xFF002050),
    pageColor: Color(0xFFF5EFDC),
    accent: Color(0xFF005090),
    textureLabel: 'Kanvas',
    category: AlbumThemeCategory.travel,
    coverAsset: 'assets/covers/cover-travel-izmir.webp',
  ),
  AlbumThemePreset(
    id: 'travel_mugla',
    name: 'Muğla',
    subtitle: 'Koylar, çam ve turkuaz',
    emoji: '⛵',
    coverStart: Color(0xFFD0D0C0),
    coverEnd: Color(0xFF003050),
    pageColor: Color(0xFFF5EFDC),
    accent: Color(0xFF0080B0),
    textureLabel: 'Kanvas',
    category: AlbumThemeCategory.travel,
    coverAsset: 'assets/covers/cover-travel-mugla.webp',
  ),
  AlbumThemePreset(
    id: 'travel_bursa',
    name: 'Bursa',
    subtitle: 'Yeşil şehir ve Uludağ',
    emoji: '🌄',
    coverStart: Color(0xFFE0C090),
    coverEnd: Color(0xFF003020),
    pageColor: Color(0xFFF5EBDC),
    accent: Color(0xFF70C0F0),
    textureLabel: 'Kanvas',
    category: AlbumThemeCategory.travel,
    coverAsset: 'assets/covers/cover-travel-bursa.webp',
  ),
  AlbumThemePreset(
    id: 'travel_ankara',
    name: 'Ankara',
    subtitle: 'Başkentin sakin çizgileri',
    emoji: '🏛️',
    coverStart: Color(0xFFD0B070),
    coverEnd: Color(0xFF202010),
    pageColor: Color(0xFFF5EADC),
    accent: Color(0xFFF0B060),
    textureLabel: 'Kanvas',
    category: AlbumThemeCategory.travel,
    coverAsset: 'assets/covers/cover-travel-ankara.webp',
  ),
  AlbumThemePreset(
    id: 'travel_edirne',
    name: 'Edirne',
    subtitle: 'Zarif minareler ve Meriç',
    emoji: '🌉',
    coverStart: Color(0xFFC0D0D0),
    coverEnd: Color(0xFF700000),
    pageColor: Color(0xFFF5EBDC),
    accent: Color(0xFFF0D080),
    textureLabel: 'Kanvas',
    category: AlbumThemeCategory.travel,
    coverAsset: 'assets/covers/cover-travel-edirne.webp',
  ),
  AlbumThemePreset(
    id: 'travel_trabzon',
    name: 'Trabzon',
    subtitle: 'Yeşil dağlar ve Karadeniz',
    emoji: '🌿',
    coverStart: Color(0xFF408080),
    coverEnd: Color(0xFF002010),
    pageColor: Color(0xFFF5EFDC),
    accent: Color(0xFF70B0F0),
    textureLabel: 'Kanvas',
    category: AlbumThemeCategory.travel,
    coverAsset: 'assets/covers/cover-travel-trabzon.webp',
  ),
  AlbumThemePreset(
    id: 'travel_aydin',
    name: 'Aydın',
    subtitle: 'Ege kıyısı ve zeytin tonları',
    emoji: '🏺',
    coverStart: Color(0xFF40A0C0),
    coverEnd: Color(0xFF002050),
    pageColor: Color(0xFFF5EFDC),
    accent: Color(0xFF0090B0),
    textureLabel: 'Kanvas',
    category: AlbumThemeCategory.travel,
    coverAsset: 'assets/covers/cover-travel-aydin.webp',
  ),
];

AlbumThemePreset themeById(String id) => albumThemes.firstWhere(
  (theme) => theme.id == id,
  orElse: () => albumThemes.first,
);

/// Covers of one category, in catalogue order. A null category means "Tümü".
List<AlbumThemePreset> themesInCategory(AlbumThemeCategory? category) =>
    category == null
    ? albumThemes
    : albumThemes.where((theme) => theme.category == category).toList();

/// Bozuk alt kayıtları atlayarak bir listeyi kurtarır.
///
/// Kullanıcı verisinde tek bir bozuk öğe, onu içeren sayfanın ya da albümün
/// tamamının kaybedilmesine yol açmamalı. Kaybedilen tek şey okunamayan
/// kaydın kendisi olur.
List<T> _recoverList<T>(Object? raw, T Function(Map<String, dynamic>) parse) {
  if (raw is! List) return <T>[];
  final recovered = <T>[];
  for (final item in raw) {
    if (item is! Map<String, dynamic>) continue;
    try {
      recovered.add(parse(item));
    } catch (_) {
      // Okunamayan kaydı atla; listenin geri kalanı kurtarılır.
    }
  }
  return recovered;
}

class AlbumElementModel {
  AlbumElementModel({
    required this.id,
    required this.type,
    required this.content,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.rotation = 0,
    this.scale = 1,
    this.frameStyle = 0,
    this.photoShape = AlbumPhotoShape.free,
    this.photoCrop,
    this.textColor = 0xFF2B2521,
    this.textAlign = TextAlign.center,
    this.fontSize = 24,
    this.extraData = '',
    this.locked = false,
    this.cardColor,
  });

  final String id;
  final AlbumElementType type;
  String content;
  double x;
  double y;
  double width;
  double height;
  double rotation;
  double scale;
  bool locked;
  int? cardColor;

  /// Append-only index into the photo-frame catalogue. Existing numeric IDs
  /// must keep their meaning so older albums render identically.
  int frameStyle;
  AlbumPhotoShape photoShape;

  /// Normalized source-image region. Null preserves legacy cover rendering;
  /// the full unit rectangle explicitly shows the entire original image.
  Rect? photoCrop;
  int textColor;
  TextAlign textAlign;
  double fontSize;
  String
  extraData; // For card subtypes, drawing point strings, or milestone tags

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'content': content,
    'x': x,
    'y': y,
    'width': width,
    'height': height,
    'rotation': rotation,
    'scale': scale,
    'frameStyle': frameStyle,
    'photoShape': photoShape.name,
    if (photoCrop case final crop?)
      'photoCrop': [crop.left, crop.top, crop.right, crop.bottom],
    'textColor': textColor,
    'textAlign': textAlign.name,
    'fontSize': fontSize,
    'extraData': extraData,
    'locked': locked,
    if (cardColor != null) 'cardColor': cardColor,
  };

  factory AlbumElementModel.fromJson(Map<String, dynamic> json) =>
      AlbumElementModel(
        id: json['id'] as String,
        type: AlbumElementType.values.byName(json['type'] as String),
        content: json['content'] as String,
        x: (json['x'] as num).toDouble(),
        y: (json['y'] as num).toDouble(),
        width: (json['width'] as num).toDouble(),
        height: (json['height'] as num).toDouble(),
        rotation: (json['rotation'] as num?)?.toDouble() ?? 0,
        scale: (json['scale'] as num?)?.toDouble() ?? 1,
        frameStyle: json['frameStyle'] as int? ?? 0,
        photoCrop: parsePhotoCrop(json['photoCrop']),
        photoShape: AlbumPhotoShape.values.firstWhere(
          (shape) => shape.name == json['photoShape'],
          orElse: () => AlbumPhotoShape.free,
        ),
        textColor: json['textColor'] as int? ?? 0xFF2B2521,
        textAlign: TextAlign.values.firstWhere(
          (a) => a.name == json['textAlign'],
          orElse: () => TextAlign.center,
        ),
        fontSize: (json['fontSize'] as num?)?.toDouble() ?? 24,
        extraData: json['extraData'] as String? ?? '',
        locked: json['locked'] as bool? ?? false,
        cardColor: json['cardColor'] as int?,
      );
}

Rect? parsePhotoCrop(Object? raw) {
  if (raw is! List ||
      raw.length != 4 ||
      raw.any((value) => value is! num || !value.isFinite)) {
    return null;
  }
  final values = raw
      .cast<num>()
      .map((v) => v.toDouble().clamp(0.0, 1.0))
      .toList();
  final rect = Rect.fromLTRB(values[0], values[1], values[2], values[3]);
  return rect.width >= .01 && rect.height >= .01 ? rect : null;
}

bool canMoveAlbumElementLayer(
  List<AlbumElementModel> elements,
  String elementId,
  AlbumElementLayerAction action,
) {
  final index = elements.indexWhere((element) => element.id == elementId);
  if (index < 0 || elements.length < 2) return false;
  return switch (action) {
    AlbumElementLayerAction.moveDown ||
    AlbumElementLayerAction.sendToBack => index > 0,
    AlbumElementLayerAction.moveUp ||
    AlbumElementLayerAction.bringToFront => index < elements.length - 1,
  };
}

/// Reorders an element without introducing a second z-index source of truth.
/// Returns false when the requested move is already at its boundary.
bool moveAlbumElementLayer(
  List<AlbumElementModel> elements,
  String elementId,
  AlbumElementLayerAction action,
) {
  if (!canMoveAlbumElementLayer(elements, elementId, action)) return false;
  final index = elements.indexWhere((element) => element.id == elementId);
  final targetIndex = switch (action) {
    AlbumElementLayerAction.moveDown => index - 1,
    AlbumElementLayerAction.moveUp => index + 1,
    AlbumElementLayerAction.sendToBack => 0,
    AlbumElementLayerAction.bringToFront => elements.length - 1,
  };
  final element = elements.removeAt(index);
  elements.insert(targetIndex, element);
  return true;
}

bool scaleAlbumElementBy(AlbumElementModel element, double factor) {
  if (!factor.isFinite || factor <= 0) return false;
  final current = element.scale.isFinite ? element.scale : 1.0;
  final next = (current * factor).clamp(
    albumElementMinScale,
    albumElementMaxScale,
  );
  if ((next - current).abs() < 0.000001) return false;
  element.scale = next;
  return true;
}

bool resetAlbumElementTransform(AlbumElementModel element) {
  if ((element.scale - 1).abs() < 0.000001 &&
      element.rotation.abs() < 0.000001) {
    return false;
  }
  element.scale = 1;
  element.rotation = 0;
  return true;
}

class AlbumPageModel {
  AlbumPageModel({
    required this.id,
    required this.backgroundColor,
    List<AlbumElementModel>? elements,
  }) : elements = elements ?? [];

  final String id;
  int backgroundColor;
  final List<AlbumElementModel> elements;

  Map<String, dynamic> toJson() => {
    'id': id,
    'backgroundColor': backgroundColor,
    'elements': elements.map((element) => element.toJson()).toList(),
  };

  factory AlbumPageModel.fromJson(Map<String, dynamic> json) => AlbumPageModel(
    id: json['id'] as String,
    backgroundColor: json['backgroundColor'] as int,
    elements: _recoverList(json['elements'], AlbumElementModel.fromJson),
  );
}

class AlbumModel {
  AlbumModel({
    required this.id,
    required this.title,
    required this.themeId,
    this.bindingType = AlbumBindingType.spiral,
    required this.createdAt,
    required this.updatedAt,
    required this.pages,
    this.projectType = AlbumProjectType.album,
    this.cardThemeId = 'birthday',
    this.importFingerprint,
    this.memoryPeriod,
    this.coverPhotoPath,
  });

  final String id;
  String title;
  String themeId;
  AlbumBindingType bindingType;
  final DateTime createdAt;
  DateTime updatedAt;
  final List<AlbumPageModel> pages;
  AlbumProjectType projectType;
  String cardThemeId;
  String? importFingerprint;
  String? memoryPeriod;
  String? coverPhotoPath;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'themeId': themeId,
    'bindingType': bindingType.name,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'pages': pages.map((page) => page.toJson()).toList(),
    'projectType': projectType.name,
    'cardThemeId': cardThemeId,
    if (importFingerprint != null) 'importFingerprint': importFingerprint,
    if (memoryPeriod != null) 'memoryPeriod': memoryPeriod,
    if (coverPhotoPath != null) 'coverPhotoPath': coverPhotoPath,
  };

  factory AlbumModel.fromJson(Map<String, dynamic> json) => AlbumModel(
    id: json['id'] as String,
    title: json['title'] as String,
    themeId: json['themeId'] as String,
    bindingType: json['bindingType'] != null
        ? AlbumBindingType.values.firstWhere(
            (b) => b.name == json['bindingType'],
            orElse: () => AlbumBindingType.spiral,
          )
        : AlbumBindingType.spiral,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
    pages: _recoverList(json['pages'], AlbumPageModel.fromJson),
    projectType: AlbumProjectType.values.firstWhere(
      (type) => type.name == json['projectType'],
      orElse: () => AlbumProjectType.album,
    ),
    cardThemeId: json['cardThemeId'] as String? ?? 'birthday',
    importFingerprint: json['importFingerprint'] as String?,
    memoryPeriod: json['memoryPeriod'] as String?,
    coverPhotoPath: json['coverPhotoPath'] as String?,
  );
}

/// Aynı süreç içinde bir daha üretilmeyecek bir kimlik döndürür.
///
/// Yalnızca zaman damgası yetmiyor: `microsecondsSinceEpoch` tek bir senkron
/// blok boyunca ilerlemeyebiliyor. Bir sayfa çoğaltıldığında ya da çoklu
/// fotoğraf eklendiğinde tüm öğeler aynı kimliği alıyor, bu da aynı `Stack`
/// içinde özdeş `ValueKey`'lere ve Flutter assertion hatasına yol açıyordu.
/// Artan sayaç bu çakışmayı imkânsız kılar.
///
/// Eski kayıtlardaki saf sayısal kimlikler geçerli kalır; kimlikler yalnızca
/// karşılaştırılır, çözümlenmez.
String newId() {
  final sequence = (_idSequence++).toRadixString(36);
  return '${DateTime.now().microsecondsSinceEpoch}-$sequence';
}

int _idSequence = 0;
