import 'package:flutter/material.dart';

import '../themes/album_themes.dart';

enum AlbumElementType { photo, text, sticker, drawing, card }

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

  /// Optional high-resolution physical cover artwork. The artwork is kept
  /// separate from the saved album JSON, so older albums gain the richer
  /// cover automatically after an app update.
  String? get coverAsset => switch (id) {
    'soft_romance' => 'assets/covers/cover-rose-heirloom.png',
    'vintage_diary' => 'assets/covers/cover-vintage-quill.png',
    'animals' || 'dark_leather' => 'assets/covers/cover-obsidian-lion.png',
    'travel_postcard' ||
    'midnight_atlas' => 'assets/covers/cover-atlas-compass.png',
    'best_friends' => 'assets/covers/cover-emerald-friendship.png',
    'minimal_editorial' => 'assets/covers/cover-minimal-editorial.png',
    _ => null,
  };
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
  ),
];

AlbumThemePreset themeById(String id) => albumThemes.firstWhere(
  (theme) => theme.id == id,
  orElse: () => albumThemes.first,
);

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
    this.textColor = 0xFF2B2521,
    this.fontSize = 24,
    this.extraData = '',
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
  int
  frameStyle; // 0: Normal, 1: Polaroid, 2: Dark Leather, 3: Soft Pill, 4: Gold Corner Mounts, 5: Black Corner Mounts
  int textColor;
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
    'textColor': textColor,
    'fontSize': fontSize,
    'extraData': extraData,
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
        textColor: json['textColor'] as int? ?? 0xFF2B2521,
        fontSize: (json['fontSize'] as num?)?.toDouble() ?? 24,
        extraData: json['extraData'] as String? ?? '',
      );
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
    elements: (json['elements'] as List<dynamic>)
        .map(
          (element) =>
              AlbumElementModel.fromJson(element as Map<String, dynamic>),
        )
        .toList(),
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
  });

  final String id;
  String title;
  String themeId;
  AlbumBindingType bindingType;
  final DateTime createdAt;
  DateTime updatedAt;
  final List<AlbumPageModel> pages;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'themeId': themeId,
    'bindingType': bindingType.name,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'pages': pages.map((page) => page.toJson()).toList(),
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
    pages: (json['pages'] as List<dynamic>)
        .map((page) => AlbumPageModel.fromJson(page as Map<String, dynamic>))
        .toList(),
  );
}

String newId() => DateTime.now().microsecondsSinceEpoch.toString();
