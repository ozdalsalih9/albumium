import 'package:flutter/material.dart';

enum AlbumElementType { photo, text, sticker }

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
}

const albumThemes = <AlbumThemePreset>[
  AlbumThemePreset(
    id: 'soft_romance',
    name: 'Soft Romance',
    subtitle: 'Pastel tonlar, zarif detaylar',
    emoji: '❤️',
    coverStart: Color(0xFFD67A8B),
    coverEnd: Color(0xFF7D394F),
    pageColor: Color(0xFFFFF7F2),
    accent: Color(0xFFC75C77),
    textureLabel: 'Keten',
  ),
  AlbumThemePreset(
    id: 'vintage_diary',
    name: 'Vintage Diary',
    subtitle: 'Eskitilmiş kâğıt, sıcak anılar',
    emoji: '📜',
    coverStart: Color(0xFF9D704A),
    coverEnd: Color(0xFF4B3024),
    pageColor: Color(0xFFF4E8D1),
    accent: Color(0xFF9A613A),
    textureLabel: 'Deri',
  ),
  AlbumThemePreset(
    id: 'travel_postcard',
    name: 'Travel Postcard',
    subtitle: 'Rota, bilet ve macera hissi',
    emoji: '✈️',
    coverStart: Color(0xFF4F8F8A),
    coverEnd: Color(0xFF183F4C),
    pageColor: Color(0xFFF4F1E8),
    accent: Color(0xFFE07A4F),
    textureLabel: 'Kanvas',
  ),
  AlbumThemePreset(
    id: 'best_friends',
    name: 'Best Friends',
    subtitle: 'Renkli, enerjik ve eğlenceli',
    emoji: '🎉',
    coverStart: Color(0xFFA86EE5),
    coverEnd: Color(0xFF4D3B91),
    pageColor: Color(0xFFFFFBFF),
    accent: Color(0xFFFF8A65),
    textureLabel: 'Parlak',
  ),
  AlbumThemePreset(
    id: 'minimal_editorial',
    name: 'Minimal Editorial',
    subtitle: 'Sade, modern ve zamansız',
    emoji: '□',
    coverStart: Color(0xFF767676),
    coverEnd: Color(0xFF202020),
    pageColor: Color(0xFFFAFAF7),
    accent: Color(0xFF242424),
    textureLabel: 'Mat',
  ),
  AlbumThemePreset(
    id: 'dark_leather',
    name: 'Dark Leather',
    subtitle: 'Güçlü, klasik ve koyu',
    emoji: '🌑',
    coverStart: Color(0xFF3F5263),
    coverEnd: Color(0xFF111820),
    pageColor: Color(0xFFEFEDE8),
    accent: Color(0xFF355E7A),
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
  int frameStyle;
  int textColor;
  double fontSize;

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
    required this.createdAt,
    required this.updatedAt,
    required this.pages,
  });

  final String id;
  String title;
  String themeId;
  final DateTime createdAt;
  DateTime updatedAt;
  final List<AlbumPageModel> pages;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'themeId': themeId,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'pages': pages.map((page) => page.toJson()).toList(),
  };

  factory AlbumModel.fromJson(Map<String, dynamic> json) => AlbumModel(
    id: json['id'] as String,
    title: json['title'] as String,
    themeId: json['themeId'] as String,
    createdAt: DateTime.parse(json['createdAt'] as String),
    updatedAt: DateTime.parse(json['updatedAt'] as String),
    pages: (json['pages'] as List<dynamic>)
        .map((page) => AlbumPageModel.fromJson(page as Map<String, dynamic>))
        .toList(),
  );
}

String newId() => DateTime.now().microsecondsSinceEpoch.toString();
