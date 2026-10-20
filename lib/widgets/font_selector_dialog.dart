import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../l10n/albumium_localizations.dart';
import 'card_color_picker.dart';

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
    _selectedFont = availableFonts
        .firstWhere(
          (f) => f.name.toLowerCase() == widget.initialFont.toLowerCase(),
          orElse: () => availableFonts.first,
        )
        .name;
    _fontSize = widget.initialFontSize.isFinite
        ? widget.initialFontSize.clamp(8.0, 96.0)
        : 24;
    _selectedColor = Color(widget.initialColor);
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _submit() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;
    Navigator.pop(
      context,
      TextElementResult(
        text: text,
        fontFamily: _selectedFont,
        fontSize: _fontSize,
        textColor: _selectedColor.toARGB32(),
      ),
    );
  }

  Future<void> _pickColor() async {
    FocusManager.instance.primaryFocus?.unfocus();
    final value = await showDialog<int>(
      context: context,
      builder: (_) => CardColorPicker(initialColor: _selectedColor),
    );
    if (value != null && mounted) setState(() => _selectedColor = Color(value));
  }

  void _resize(double delta) =>
      setState(() => _fontSize = (_fontSize + delta).clamp(8.0, 96.0));

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      context.tr(text),
      style: Theme.of(
        context,
      ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final editing = widget.initialText.trim().isNotEmpty;
    final previewBackground = _selectedColor.computeLuminance() > .55
        ? const Color(0xFF303B35)
        : const Color(0xFFFFFBF2);
    return Dialog(
      key: const ValueKey('text-editor-dialog'),
      backgroundColor: colors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480, maxHeight: 720),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colors.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.text_fields_rounded,
                      color: colors.onPrimaryContainer,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      context.tr('Yazı atölyesi'),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: context.tr('Kapat'),
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      key: const ValueKey('text-editor-input'),
                      controller: _textController,
                      minLines: 2,
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        labelText: context.tr('Metnin'),
                        hintText: context.tr('Bir cümle, bir hatıra…'),
                        filled: true,
                        fillColor: colors.surfaceContainerLow,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: colors.outlineVariant),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: colors.primary,
                            width: 1.5,
                          ),
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 20),
                    _label('Önizleme'),
                    Container(
                      width: double.infinity,
                      height: 120,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: previewBackground,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: colors.outlineVariant.withValues(alpha: .6),
                        ),
                      ),
                      child: Center(
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: SizedBox(
                            width: 340,
                            child: Text(
                              _textController.text.trim().isEmpty
                                  ? context.tr('Bir cümle, bir hatıra…')
                                  : _textController.text.trim(),
                              textAlign: TextAlign.center,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: getFontTextStyle(
                                _selectedFont,
                                fontSize: _fontSize,
                                color: _selectedColor,
                              ).copyWith(height: 1.25),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _label('Yazı tipi'),
                    DropdownButtonFormField<String>(
                      key: const ValueKey('text-editor-font'),
                      initialValue: _selectedFont,
                      isExpanded: true,
                      menuMaxHeight: 340,
                      borderRadius: BorderRadius.circular(16),
                      dropdownColor: colors.surfaceContainerHigh,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: colors.surfaceContainerLow,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: colors.outlineVariant),
                        ),
                      ),
                      selectedItemBuilder: (context) => [
                        for (final font in availableFonts)
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              font.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: font.styleBuilder(
                                fontSize: 20,
                                color: colors.onSurface,
                              ),
                            ),
                          ),
                      ],
                      items: [
                        for (final font in availableFonts)
                          DropdownMenuItem(
                            value: font.name,
                            child: Text(
                              font.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: font.styleBuilder(
                                fontSize: 20,
                                color: colors.onSurface,
                              ),
                            ),
                          ),
                      ],
                      onTap: () =>
                          FocusManager.instance.primaryFocus?.unfocus(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedFont = value);
                        }
                      },
                    ),
                    const SizedBox(height: 6),
                    Text(
                      context.tr(
                        availableFonts
                            .firstWhere((f) => f.name == _selectedFont)
                            .category,
                      ),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(child: _label('Yazı boyutu')),
                        IconButton(
                          tooltip: context.tr('Küçült'),
                          onPressed: _fontSize > 8 ? () => _resize(-1) : null,
                          icon: const Icon(Icons.remove_rounded, size: 20),
                        ),
                        Text(
                          '${_fontSize.round()} pt',
                          style: Theme.of(context).textTheme.labelLarge,
                        ),
                        IconButton(
                          tooltip: context.tr('Büyüt'),
                          onPressed: _fontSize < 96 ? () => _resize(1) : null,
                          icon: const Icon(Icons.add_rounded, size: 20),
                        ),
                      ],
                    ),
                    Slider(
                      key: const ValueKey('text-editor-size'),
                      value: _fontSize,
                      min: 8,
                      max: 96,
                      divisions: 88,
                      label: '${_fontSize.round()} pt',
                      onChanged: (value) => setState(() => _fontSize = value),
                    ),
                    const SizedBox(height: 12),
                    _label('Yazı rengi'),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        for (final color in _palette)
                          Semantics(
                            selected: color == _selectedColor,
                            button: true,
                            label:
                                '#${color.toARGB32().toRadixString(16).substring(2)}',
                            child: InkWell(
                              onTap: () =>
                                  setState(() => _selectedColor = color),
                              borderRadius: BorderRadius.circular(24),
                              child: SizedBox(
                                width: 44,
                                height: 44,
                                child: Center(
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 150),
                                    width: 34,
                                    height: 34,
                                    padding: const EdgeInsets.all(3),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: color == _selectedColor
                                            ? colors.primary
                                            : colors.outlineVariant,
                                        width: color == _selectedColor ? 2 : 1,
                                      ),
                                    ),
                                    child: DecoratedBox(
                                      decoration: BoxDecoration(
                                        color: color,
                                        shape: BoxShape.circle,
                                      ),
                                      child: color == _selectedColor
                                          ? Icon(
                                              Icons.check_rounded,
                                              size: 17,
                                              color:
                                                  color.computeLuminance() > .45
                                                  ? Colors.black87
                                                  : Colors.white,
                                            )
                                          : null,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _pickColor,
                      icon: Icon(
                        Icons.colorize_rounded,
                        size: 18,
                        color: colors.primary,
                      ),
                      label: Text(context.tr('Kendi rengini seç')),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: BoxDecoration(
                color: colors.surface,
                border: Border(top: BorderSide(color: colors.outlineVariant)),
              ),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  key: const ValueKey('text-editor-apply'),
                  onPressed: _textController.text.trim().isEmpty
                      ? null
                      : _submit,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.check_rounded, size: 20),
                  label: Text(
                    context.tr(
                      editing ? 'Değişiklikleri uygula' : 'Yazıyı ekle',
                    ),
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
