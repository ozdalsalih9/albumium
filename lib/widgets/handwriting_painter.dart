import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../l10n/albumium_localizations.dart';

class StrokePoint {
  const StrokePoint(this.x, this.y);

  final double x;
  final double y;

  Map<String, dynamic> toJson() => {'x': x, 'y': y};

  factory StrokePoint.fromJson(Map<String, dynamic> json) =>
      StrokePoint((json['x'] as num).toDouble(), (json['y'] as num).toDouble());
}

class DrawingStroke {
  DrawingStroke({
    required this.points,
    required this.color,
    required this.width,
  });

  final List<StrokePoint> points;
  final int color;
  final double width;

  Map<String, dynamic> toJson() => {
    'points': points.map((p) => p.toJson()).toList(),
    'color': color,
    'width': width,
  };

  factory DrawingStroke.fromJson(Map<String, dynamic> json) => DrawingStroke(
    points: (json['points'] as List<dynamic>)
        .map((p) => StrokePoint.fromJson(p as Map<String, dynamic>))
        .toList(),
    color: json['color'] as int,
    width: (json['width'] as num).toDouble(),
  );
}

class HandwritingData {
  HandwritingData({required this.strokes, this.aspectRatio = 1.0});

  final List<DrawingStroke> strokes;
  final double aspectRatio;

  String encode() => jsonEncode({
    'aspectRatio': aspectRatio,
    'strokes': strokes.map((s) => s.toJson()).toList(),
  });

  static HandwritingData decode(String raw) {
    if (raw.trim().isEmpty) return HandwritingData(strokes: []);
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return HandwritingData(
          strokes: decoded
              .map((s) => DrawingStroke.fromJson(s as Map<String, dynamic>))
              .toList(),
          aspectRatio: 1.0,
        );
      }
      final map = decoded as Map<String, dynamic>;
      final list = map['strokes'] as List<dynamic>? ?? [];
      return HandwritingData(
        strokes: list
            .map((s) => DrawingStroke.fromJson(s as Map<String, dynamic>))
            .toList(),
        aspectRatio: (map['aspectRatio'] as num?)?.toDouble() ?? 1.0,
      );
    } catch (_) {
      return HandwritingData(strokes: []);
    }
  }
}

/// Renders handwriting with 1:1 preserved aspect ratio without stretching
class HandwritingView extends StatelessWidget {
  const HandwritingView({super.key, required this.data, this.overrideColor});

  final String data;
  final Color? overrideColor;

  @override
  Widget build(BuildContext context) {
    final parsed = HandwritingData.decode(data);
    if (parsed.strokes.isEmpty) return const SizedBox();

    return Center(
      child: AspectRatio(
        aspectRatio: parsed.aspectRatio > 0.05 ? parsed.aspectRatio : 1.0,
        child: CustomPaint(
          size: Size.infinite,
          painter: _HandwritingPainter(parsed.strokes, overrideColor),
        ),
      ),
    );
  }
}

class _HandwritingPainter extends CustomPainter {
  const _HandwritingPainter(this.strokes, this.overrideColor);

  final List<DrawingStroke> strokes;
  final Color? overrideColor;

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      if (stroke.points.isEmpty) continue;
      final paint = Paint()
        ..color = overrideColor ?? Color(stroke.color)
        ..strokeWidth = stroke.width * (size.shortestSide / 240)
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      final path = Path();
      final first = stroke.points.first;
      path.moveTo(first.x * size.width, first.y * size.height);

      if (stroke.points.length == 1) {
        canvas.drawCircle(
          Offset(first.x * size.width, first.y * size.height),
          paint.strokeWidth / 2,
          paint..style = PaintingStyle.fill,
        );
        continue;
      }

      for (var i = 1; i < stroke.points.length; i++) {
        final p = stroke.points[i];
        final prev = stroke.points[i - 1];
        final midX = (prev.x + p.x) / 2 * size.width;
        final midY = (prev.y + p.y) / 2 * size.height;
        path.quadraticBezierTo(
          prev.x * size.width,
          prev.y * size.height,
          midX,
          midY,
        );
      }
      final last = stroke.points.last;
      path.lineTo(last.x * size.width, last.y * size.height);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _HandwritingPainter oldDelegate) => true;
}

/// Full interactive drawing & handwriting canvas modal with auto-bounding box normalization
class HandwritingCanvasDialog extends StatefulWidget {
  const HandwritingCanvasDialog({super.key, this.initialData});

  final String? initialData;

  @override
  State<HandwritingCanvasDialog> createState() =>
      _HandwritingCanvasDialogState();
}

class _HandwritingCanvasDialogState extends State<HandwritingCanvasDialog> {
  final List<DrawingStroke> _strokes = [];
  final List<DrawingStroke> _redoStack = [];

  // This screen deliberately uses a dark drawing-desk chrome. Keep its
  // controls independent from the user-selected application palette: light
  // palettes otherwise supply dark AppBar/icon foregrounds on this surface.
  static const _toolbarBackground = Color(0xFF241F1C);
  static const _toolbarForeground = Color(0xFFFFF8EC);
  static const _toolbarDisabledForeground = Color(0x6BFFF8EC);
  static const _toolbarAccent = Color(0xFFFFA95C);

  static final ButtonStyle _toolbarIconButtonStyle = IconButton.styleFrom(
    foregroundColor: _toolbarForeground,
    disabledForegroundColor: _toolbarDisabledForeground,
  );

  static final ButtonStyle _saveIconButtonStyle = IconButton.styleFrom(
    backgroundColor: _toolbarAccent,
    foregroundColor: const Color(0xFF2C190F),
  );

  static final ButtonStyle _saveButtonStyle = FilledButton.styleFrom(
    backgroundColor: _toolbarAccent,
    foregroundColor: const Color(0xFF2C190F),
  );

  static const List<Color> _palette = [
    Color(0xFF1E1E1E), // Mürekkep siyah
    Color(0xFFC9A45C), // Altın varak
    Color(0xFFC26B7A), // Gül kurusu
    Color(0xFF6B8A5A), // Adaçayı yeşil
    Color(0xFF3E5C76), // Gece mavisi
    Color(0xFFD97724), // Sıcak amber
    Color(0xFF8B5CF6), // Mor enerji
    Color(0xFFFFFFFF), // Beyaz
  ];

  Color _selectedColor = const Color(0xFF1E1E1E);
  double _selectedWidth = 4.0;
  bool _isEraser = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null && widget.initialData!.isNotEmpty) {
      _strokes.addAll(HandwritingData.decode(widget.initialData!).strokes);
    }
  }

  void _onPanStart(DragStartDetails details) {
    _redoStack.clear();
    final x = details.localPosition.dx;
    final y = details.localPosition.dy;

    setState(() {
      _strokes.add(
        DrawingStroke(
          points: [StrokePoint(x, y)],
          color: _isEraser ? 0x00000000 : _selectedColor.toARGB32(),
          width: _isEraser ? 24.0 : _selectedWidth,
        ),
      );
    });
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (_strokes.isEmpty) return;
    final x = details.localPosition.dx;
    final y = details.localPosition.dy;

    setState(() {
      _strokes.last.points.add(StrokePoint(x, y));
    });
  }

  void _undo() {
    if (_strokes.isEmpty) return;
    setState(() {
      _redoStack.add(_strokes.removeLast());
    });
  }

  void _redo() {
    if (_redoStack.isEmpty) return;
    setState(() {
      _strokes.add(_redoStack.removeLast());
    });
  }

  void _clear() {
    if (_strokes.isEmpty) return;
    setState(() {
      _redoStack.addAll(_strokes);
      _strokes.clear();
    });
  }

  void _save() {
    final validStrokes = _strokes
        .where((s) => s.color != 0x00000000 && s.points.isNotEmpty)
        .toList();
    if (validStrokes.isEmpty) {
      Navigator.pop(context);
      return;
    }

    // 1. Calculate the exact tight bounding box of all strokes
    double minX = double.infinity;
    double maxX = -double.infinity;
    double minY = double.infinity;
    double maxY = -double.infinity;

    for (final s in validStrokes) {
      for (final p in s.points) {
        if (p.x < minX) minX = p.x;
        if (p.x > maxX) maxX = p.x;
        if (p.y < minY) minY = p.y;
        if (p.y > maxY) maxY = p.y;
      }
    }

    // Add safe padding around strokes
    const padding = 16.0;
    minX = math.max(0, minX - padding);
    minY = math.max(0, minY - padding);
    maxX += padding;
    maxY += padding;

    final boxWidth = math.max(10.0, maxX - minX);
    final boxHeight = math.max(10.0, maxY - minY);
    final naturalAspectRatio = boxWidth / boxHeight;

    // 2. Normalize all stroke points relative to the bounding box [0..1]
    final normalizedStrokes = <DrawingStroke>[];
    for (final s in validStrokes) {
      final normalizedPoints = s.points
          .map(
            (p) => StrokePoint(
              ((p.x - minX) / boxWidth).clamp(0.0, 1.0),
              ((p.y - minY) / boxHeight).clamp(0.0, 1.0),
            ),
          )
          .toList();
      normalizedStrokes.add(
        DrawingStroke(points: normalizedPoints, color: s.color, width: s.width),
      );
    }

    final encoded = HandwritingData(
      strokes: normalizedStrokes,
      aspectRatio: naturalAspectRatio,
    ).encode();

    Navigator.pop(context, encoded);
  }

  @override
  Widget build(BuildContext context) {
    final useCompactAppBar = MediaQuery.sizeOf(context).width < 430;

    return Dialog.fullscreen(
      child: Scaffold(
        backgroundColor: const Color(0xFF1B1816),
        appBar: AppBar(
          backgroundColor: _toolbarBackground,
          foregroundColor: _toolbarForeground,
          iconTheme: const IconThemeData(color: _toolbarForeground),
          actionsIconTheme: const IconThemeData(color: _toolbarForeground),
          surfaceTintColor: Colors.transparent,
          title: Text(
            context.tr('Elle Yaz & Çiz'),
            style: const TextStyle(
              color: _toolbarForeground,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          actions: [
            IconButton(
              key: const ValueKey('handwriting-undo'),
              onPressed: _strokes.isNotEmpty ? _undo : null,
              style: _toolbarIconButtonStyle,
              icon: const Icon(Icons.undo_rounded),
              tooltip: context.tr('Geri Al'),
            ),
            IconButton(
              key: const ValueKey('handwriting-redo'),
              onPressed: _redoStack.isNotEmpty ? _redo : null,
              style: _toolbarIconButtonStyle,
              icon: const Icon(Icons.redo_rounded),
              tooltip: context.tr('İleri Al'),
            ),
            IconButton(
              key: const ValueKey('handwriting-clear'),
              onPressed: _strokes.isNotEmpty ? _clear : null,
              style: _toolbarIconButtonStyle,
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: context.tr('Temizle'),
            ),
            if (useCompactAppBar)
              IconButton.filled(
                key: const ValueKey('handwriting-save-compact'),
                onPressed: _save,
                style: _saveIconButtonStyle,
                icon: const Icon(Icons.check_rounded),
                tooltip: context.tr('Çizimi Ekle'),
              )
            else
              FilledButton.icon(
                key: const ValueKey('handwriting-save'),
                onPressed: _save,
                style: _saveButtonStyle,
                icon: const Icon(Icons.check_rounded, size: 18),
                label: Text(context.tr('Ekle')),
              ),
            SizedBox(width: useCompactAppBar ? 6 : 14),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF9F6F0),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black45,
                          blurRadius: 18,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: GestureDetector(
                        key: const ValueKey('handwriting-drawing-area'),
                        behavior: HitTestBehavior.opaque,
                        onPanStart: _onPanStart,
                        onPanUpdate: _onPanUpdate,
                        child: Stack(
                          children: [
                            // Hafif defter çizgisi deseni
                            Positioned.fill(
                              child: CustomPaint(
                                painter: _DrawingGridPainter(),
                              ),
                            ),
                            Positioned.fill(
                              child: CustomPaint(
                                painter: _CanvasPixelPainter(_strokes),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              // Controls bar: Colors & Brush Width
              Container(
                color: _toolbarBackground,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Color Palette & Eraser
                    Row(
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                for (final color in _palette)
                                  GestureDetector(
                                    onTap: () => setState(() {
                                      _selectedColor = color;
                                      _isEraser = false;
                                    }),
                                    child: Container(
                                      width: 32,
                                      height: 32,
                                      margin: const EdgeInsets.only(right: 8),
                                      decoration: BoxDecoration(
                                        color: color,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color:
                                              !_isEraser &&
                                                  _selectedColor == color
                                              ? _toolbarAccent
                                              : Colors.white24,
                                          width:
                                              !_isEraser &&
                                                  _selectedColor == color
                                              ? 3
                                              : 1.2,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton.filledTonal(
                          onPressed: () =>
                              setState(() => _isEraser = !_isEraser),
                          icon: Icon(
                            Icons.cleaning_services_rounded,
                            color: _isEraser ? _toolbarAccent : Colors.white70,
                          ),
                          tooltip: context.tr('Silgi'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Thickness Selector
                    Row(
                      children: [
                        Text(
                          context.tr('Fırça:'),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 12),
                        for (final width in [2.0, 4.0, 7.0, 12.0])
                          GestureDetector(
                            onTap: () => setState(() => _selectedWidth = width),
                            child: Container(
                              margin: const EdgeInsets.only(right: 12),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: _selectedWidth == width
                                    ? const Color(
                                        0xFFFFA95C,
                                      ).withValues(alpha: 0.25)
                                    : Colors.white.withValues(alpha: 0.05),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: _selectedWidth == width
                                      ? const Color(0xFFFFA95C)
                                      : Colors.white12,
                                ),
                              ),
                              child: Center(
                                child: Container(
                                  width: width * 2,
                                  height: width * 2,
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CanvasPixelPainter extends CustomPainter {
  const _CanvasPixelPainter(this.strokes);

  final List<DrawingStroke> strokes;

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      if (stroke.points.isEmpty) continue;
      final isClear = stroke.color == 0x00000000;
      final paint = Paint()
        ..color = isClear ? const Color(0xFFF9F6F0) : Color(stroke.color)
        ..strokeWidth = stroke.width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      final path = Path();
      final first = stroke.points.first;
      path.moveTo(first.x, first.y);

      for (var i = 1; i < stroke.points.length; i++) {
        final p = stroke.points[i];
        final prev = stroke.points[i - 1];
        final midX = (prev.x + p.x) / 2;
        final midY = (prev.y + p.y) / 2;
        path.quadraticBezierTo(prev.x, prev.y, midX, midY);
      }
      final last = stroke.points.last;
      path.lineTo(last.x, last.y);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _CanvasPixelPainter oldDelegate) => true;
}

class _DrawingGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x184A3B2A)
      ..strokeWidth = 0.8;
    for (double y = 40; y < size.height; y += 32) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
