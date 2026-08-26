import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FontOption {
  const FontOption({
    required this.name,
    required this.displayName,
    required this.category,
    required this.styleBuilder,
  });

  final String name;
  final String displayName;
  final String category;
  final TextStyle Function({
    double? fontSize,
    Color? color,
    FontWeight? fontWeight,
  })
  styleBuilder;
}

final List<FontOption> availableFonts = [
  FontOption(
    name: 'Caveat',
    displayName: 'Caveat',
    category: 'Samimi El Yazısı',
    styleBuilder: ({fontSize, color, fontWeight}) => GoogleFonts.caveat(
      fontSize: fontSize,
      color: color,
      fontWeight: fontWeight ?? FontWeight.w600,
    ),
  ),
  FontOption(
    name: 'Dancing Script',
    displayName: 'Dancing Script',
    category: 'Akıcı Kaligrafi',
    styleBuilder: ({fontSize, color, fontWeight}) => GoogleFonts.dancingScript(
      fontSize: fontSize,
      color: color,
      fontWeight: fontWeight ?? FontWeight.w700,
    ),
  ),
  FontOption(
    name: 'Special Elite',
    displayName: 'Special Elite',
    category: 'Nostaljik Daktilo',
    styleBuilder: ({fontSize, color, fontWeight}) =>
        GoogleFonts.specialElite(fontSize: fontSize, color: color),
  ),
  FontOption(
    name: 'Cormorant Garamond',
    displayName: 'Cormorant',
    category: 'Zarif Klasik Roman',
    styleBuilder: ({fontSize, color, fontWeight}) =>
        GoogleFonts.cormorantGaramond(
          fontSize: fontSize,
          color: color,
          fontWeight: fontWeight ?? FontWeight.w600,
          fontStyle: FontStyle.italic,
        ),
  ),
  FontOption(
    name: 'Fredoka',
    displayName: 'Fredoka',
    category: 'Neşeli & Tombul',
    styleBuilder: ({fontSize, color, fontWeight}) => GoogleFonts.fredoka(
      fontSize: fontSize,
      color: color,
      fontWeight: fontWeight ?? FontWeight.w600,
    ),
  ),
  FontOption(
    name: 'Baloo 2',
    displayName: 'Baloo 2',
    category: 'Sevimli & Kalın',
    styleBuilder: ({fontSize, color, fontWeight}) => GoogleFonts.baloo2(
      fontSize: fontSize,
      color: color,
      fontWeight: fontWeight ?? FontWeight.w700,
    ),
  ),
  FontOption(
    name: 'Marcellus',
    displayName: 'Marcellus',
    category: 'Asil & Lüks Roma',
    styleBuilder: ({fontSize, color, fontWeight}) => GoogleFonts.marcellus(
      fontSize: fontSize,
      color: color,
      letterSpacing: 1.5,
    ),
  ),
  FontOption(
    name: 'Libre Baskerville',
    displayName: 'Baskerville',
    category: 'Prestijli Kitap',
    styleBuilder: ({fontSize, color, fontWeight}) =>
        GoogleFonts.libreBaskerville(
          fontSize: fontSize,
          color: color,
          fontWeight: fontWeight ?? FontWeight.w700,
        ),
  ),
  FontOption(
    name: 'Cinzel',
    displayName: 'Cinzel',
    category: 'Altın Varak Klasiği',
    styleBuilder: ({fontSize, color, fontWeight}) => GoogleFonts.cinzel(
      fontSize: fontSize,
      color: color,
      fontWeight: fontWeight ?? FontWeight.w700,
      letterSpacing: 2.0,
    ),
  ),
  FontOption(
    name: 'Pacifico',
    displayName: 'Pacifico',
    category: 'Retro Tatil Kaligrafisi',
    styleBuilder: ({fontSize, color, fontWeight}) =>
        GoogleFonts.pacifico(fontSize: fontSize, color: color),
  ),
  FontOption(
    name: 'Inter',
    displayName: 'Inter',
    category: 'Modern & Sade',
    styleBuilder: ({fontSize, color, fontWeight}) => GoogleFonts.inter(
      fontSize: fontSize,
      color: color,
      fontWeight: fontWeight ?? FontWeight.w500,
      letterSpacing: 0.4,
    ),
  ),
];

TextStyle getFontTextStyle(
  String fontFamily, {
  double fontSize = 22,
  Color color = const Color(0xFF2B2521),
}) {
  final font = availableFonts.firstWhere(
    (f) => f.name.toLowerCase() == fontFamily.toLowerCase(),
    orElse: () => availableFonts.first,
  );
  return font.styleBuilder(fontSize: fontSize, color: color);
}

class TextElementResult {
  const TextElementResult({
    required this.text,
    required this.fontFamily,
    required this.fontSize,
    required this.textColor,
  });

  final String text;
  final String fontFamily;
  final double fontSize;
  final int textColor;
}

class TextEditorDialog extends StatefulWidget {
  const TextEditorDialog({
    super.key,
    this.initialText = '',
    this.initialFont = 'Caveat',
    this.initialFontSize = 24.0,
    this.initialColor = 0xFF2B2521,
  });

  final String initialText;
  final String initialFont;
  final double initialFontSize;
  final int initialColor;

  @override
  State<TextEditorDialog> createState() => _TextEditorDialogState();
}

class _TextEditorDialogState extends State<TextEditorDialog> {
  late TextEditingController _textController;
  late String _selectedFont;
  late double _fontSize;
  late Color _selectedColor;

  static const List<Color> _palette = [
    Color(0xFF2B2521), // Mürekkep siyah
    Color(0xFFC9A45C), // Altın varak
    Color(0xFFC26B7A), // Gül kurusu
    Color(0xFF6B8A5A), // Adaçayı
    Color(0xFF3E5C76), // Gece mavisi
    Color(0xFFD97724), // Sıcak amber
    Color(0xFF6D3FD1), // Mor
    Color(0xFFFFFFFF), // Beyaz
  ];

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.initialText);
    _selectedFont = widget.initialFont;
    _fontSize = widget.initialFontSize.clamp(14.0, 42.0);
    _selectedColor = Color(widget.initialColor);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1E1A18),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 680),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.text_fields_rounded,
                    color: Color(0xFFFFA95C),
                    size: 24,
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Yazı & Font Seçimi',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Input field
              TextField(
                controller: _textController,
                autofocus: widget.initialText.isEmpty,
                maxLines: 3,
                minLines: 2,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(fontSize: 15),
                decoration: const InputDecoration(
                  hintText: 'Albümüne eklemek istediğin notu yaz…',
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 14),
              // Live Preview Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAF6EE),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    _textController.text.trim().isEmpty
                        ? 'Önizleme Metni'
                        : _textController.text.trim(),
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: getFontTextStyle(
                      _selectedFont,
                      fontSize: _fontSize,
                      color: _selectedColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              // Font Gallery List
              const Text(
                'Yazı Tipi (Font)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white70,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.separated(
                  itemCount: availableFonts.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final font = availableFonts[index];
                    final isSelected =
                        _selectedFont.toLowerCase() == font.name.toLowerCase();
                    return InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => setState(() => _selectedFont = font.name),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFFFA95C).withValues(alpha: 0.18)
                              : Colors.white.withValues(alpha: 0.04),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFFFFA95C)
                                : Colors.white10,
                            width: isSelected ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  font.displayName,
                                  style: font.styleBuilder(
                                    fontSize: 18,
                                    color: isSelected
                                        ? const Color(0xFFFFA95C)
                                        : Colors.white,
                                  ),
                                ),
                                Text(
                                  font.category,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF9B8F84),
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            if (isSelected)
                              const Icon(
                                Icons.check_circle_rounded,
                                color: Color(0xFFFFA95C),
                                size: 20,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              // Color Palette & Size Slider
              Row(
                children: [
                  for (final color in _palette)
                    GestureDetector(
                      onTap: () => setState(() => _selectedColor = color),
                      child: Container(
                        width: 26,
                        height: 26,
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _selectedColor == color
                                ? const Color(0xFFFFA95C)
                                : Colors.white24,
                            width: _selectedColor == color ? 2.5 : 1,
                          ),
                        ),
                      ),
                    ),
                  const Spacer(),
                  // Size Slider Icon
                  Text(
                    '${_fontSize.round()} pt',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.icon(
                  onPressed: () {
                    final text = _textController.text.trim();
                    if (text.isEmpty) {
                      Navigator.pop(context);
                      return;
                    }
                    Navigator.pop(
                      context,
                      TextElementResult(
                        text: text,
                        fontFamily: _selectedFont,
                        fontSize: _fontSize,
                        textColor: _selectedColor.toARGB32(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text('Sayfaya Ekle'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
