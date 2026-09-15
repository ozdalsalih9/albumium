import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Selects which physical side of the sheet is rendered by [PageCurl].
///
/// [paper] preserves the standalone, single-widget behaviour. Book spreads
/// render [front] and [back] as two synchronized snapshots so the next page is
/// already visible on the moving sheet instead of popping in after the turn.
enum PageCurlSurface { paper, front, back }

/// Çevrilen yaprağı, parmağın tuttuğu noktaya çapraz tutunan bir silindirin
/// etrafına sararak kıvıran görünüm.
///
/// Sayfa önce ekranın gerçek piksel yoğunluğunda rasterleştirilir, sonra bir
/// üçgen ağa dokunup [Canvas.drawVertices] ile yeniden çizilir. Her köşe
/// noktası, kat çizgisine olan dik uzaklığına göre silindirin üzerine taşınır:
/// yarım turu tamamlayan noktalar kâğıdın arka yüzüne geçer. Tek sayfalı
/// kullanımda arka yüz kâğıt dokusudur; kitap kullanımında sıradaki gerçek
/// sayfa ikinci, eşzamanlı bir yüz olarak aynı ağa kaplanır.
///
/// [progress] 0 iken sayfa yerinde ve dokunulmamıştır; 1 iken tamamen
/// çevrilmiştir. Durumsuz bir arayüzdür: aynı girdi her zaman aynı kareyi
/// üretir, bu yüzden ekrandaki animasyon ile MP4 dışa aktarımı aynı çizimi
/// paylaşabilir.
class PageCurl extends StatefulWidget {
  const PageCurl({
    super.key,
    required this.progress,
    required this.child,
    this.grabY = 0.5,
    this.paperColor = const Color(0xFFF1EBE1),
    this.borderRadius = 6,
    this.shadowOpacity = 0.42,
    this.allowBindingOverflow = false,
    this.surface = PageCurlSurface.paper,
  });

  final double progress;
  final Widget child;

  /// Parmağın yaprağı tuttuğu dikey nokta; 0 üst kenar, 1 alt kenar.
  ///
  /// Kat çizgisinin eğimini belirler. Sayfa ortasından tutulduğunda kat dikey,
  /// köşesinden tutulduğunda çapraz olur — köşe kıvrımını veren şey budur.
  final double grabY;

  /// Yaprağın arka yüzünde görünen kâğıt rengi.
  final Color paperColor;

  /// Sayfanın köşe yarıçapı; kıvrım bu şekle kırpılır.
  final double borderRadius;

  /// Kalkan yaprağın altındaki sayfaya düşürdüğü gölgenin koyuluğu.
  final double shadowOpacity;

  /// Lets the sheet cross its left paint bound and land on the facing page.
  /// Standalone page views keep this disabled; physical books enable it.
  final bool allowBindingOverflow;

  /// The physical side of the page represented by [child].
  final PageCurlSurface surface;

  @override
  State<PageCurl> createState() => _PageCurlState();
}

class _PageCurlState extends State<PageCurl> {
  final _controller = SnapshotController();
  late final _painter = _PageCurlPainter(
    progress: widget.progress,
    grabY: widget.grabY,
    paperColor: widget.paperColor,
    borderRadius: widget.borderRadius,
    shadowOpacity: widget.shadowOpacity,
    allowBindingOverflow: widget.allowBindingOverflow,
    surface: widget.surface,
  );

  @override
  void initState() {
    super.initState();
    _syncSnapshotting();
  }

  @override
  void didUpdateWidget(PageCurl oldWidget) {
    super.didUpdateWidget(oldWidget);
    _painter
      ..progress = widget.progress
      ..grabY = widget.grabY
      ..paperColor = widget.paperColor
      ..shadowOpacity = widget.shadowOpacity
      ..allowBindingOverflow = widget.allowBindingOverflow
      ..surface = widget.surface;
    _syncSnapshotting();
  }

  /// Yalnızca çevirme sürerken rasterleştir. Sayfa dururken canlı bileşen
  /// çizilir; böylece düzenleyicide öğe taşırken bayat bir görüntü kalmaz ve
  /// çevirme başladığında sayfa yeniden rasterleştirilir.
  void _syncSnapshotting() {
    final turning = widget.progress > 0.001;
    if (_controller.allowSnapshotting == turning) return;
    _controller.allowSnapshotting = turning;
  }

  @override
  void dispose() {
    _painter.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SnapshotWidget(
      controller: _controller,
      painter: _painter,
      child: widget.child,
    );
  }
}

class _PageCurlPainter extends SnapshotPainter {
  _PageCurlPainter({
    required double progress,
    required double grabY,
    required Color paperColor,
    required this.borderRadius,
    required double shadowOpacity,
    required bool allowBindingOverflow,
    required PageCurlSurface surface,
  }) : _progress = progress,
       _grabY = grabY,
       _paperColor = paperColor,
       _shadowOpacity = shadowOpacity,
       _allowBindingOverflow = allowBindingOverflow,
       _surface = surface;

  final double borderRadius;

  /// Ağın çözünürlüğü. Kıvrım yatayda geliştiği için sütun sayısı yüksek
  /// tutulur; satırlar yalnızca kat çizgisi eğildiğinde iş görür.
  // The front/back split follows triangle edges. A denser grid keeps that
  // physical face boundary smooth even on tall phone previews, without
  // changing the deterministic curl geometry used by exports.
  static const _cols = 64;
  static const _rows = 36;

  /// Silindirin yarıçapı (genişliğe oran). Kâğıdın sertliğini belirler.
  static const _radiusRatio = 0.10;

  /// Kat çizgisinin en büyük eğimi (radyan).
  static const _maxTilt = 0.26;

  static const _vertexCount = (_cols + 1) * (_rows + 1);

  double _progress;
  double _grabY;
  Color _paperColor;
  double _shadowOpacity;
  bool _allowBindingOverflow;
  PageCurlSurface _surface;

  ui.Image? _shaderImage;
  ui.ImageShader? _shader;

  final _positions = Float32List(_vertexCount * 2);
  final _texCoords = Float32List(_vertexCount * 2);
  final _shades = Int32List(_vertexCount);
  final _speculars = Int32List(_vertexCount);
  final _backWash = Int32List(_vertexCount);
  final _faceMix = Float32List(_vertexCount);
  late final Uint16List _indices = _buildIndices();
  late final Uint16List _visibleIndices = Uint16List(_indices.length);

  set progress(double value) {
    if (_progress == value) return;
    _progress = value;
    notifyListeners();
  }

  set grabY(double value) {
    if (_grabY == value) return;
    _grabY = value;
    notifyListeners();
  }

  set paperColor(Color value) {
    if (_paperColor == value) return;
    _paperColor = value;
    notifyListeners();
  }

  set shadowOpacity(double value) {
    if (_shadowOpacity == value) return;
    _shadowOpacity = value;
    notifyListeners();
  }

  set allowBindingOverflow(bool value) {
    if (_allowBindingOverflow == value) return;
    _allowBindingOverflow = value;
    notifyListeners();
  }

  set surface(PageCurlSurface value) {
    if (_surface == value) return;
    _surface = value;
    notifyListeners();
  }

  static Uint16List _buildIndices() {
    final indices = Uint16List(_cols * _rows * 6);
    var k = 0;
    for (var j = 0; j < _rows; j++) {
      for (var i = 0; i < _cols; i++) {
        final a = j * (_cols + 1) + i;
        final b = a + 1;
        final c = a + _cols + 1;
        final d = c + 1;
        indices[k++] = a;
        indices[k++] = b;
        indices[k++] = c;
        indices[k++] = b;
        indices[k++] = d;
        indices[k++] = c;
      }
    }
    return indices;
  }

  Uint16List _indicesForSurface() {
    if (_surface == PageCurlSurface.paper) return _indices;

    var visibleCount = 0;
    for (var index = 0; index < _indices.length; index += 3) {
      final a = _indices[index];
      final b = _indices[index + 1];
      final c = _indices[index + 2];
      final mix = (_faceMix[a] + _faceMix[b] + _faceMix[c]) / 3;
      final visible = _surface == PageCurlSurface.front
          ? mix < 0.5
          : mix >= 0.5;
      if (!visible) continue;
      _visibleIndices[visibleCount++] = a;
      _visibleIndices[visibleCount++] = b;
      _visibleIndices[visibleCount++] = c;
    }
    return Uint16List.sublistView(_visibleIndices, 0, visibleCount);
  }

  ui.ImageShader _shaderFor(ui.Image image) {
    final cached = _shader;
    if (cached != null && identical(_shaderImage, image)) return cached;
    cached?.dispose();
    final shader = ui.ImageShader(
      image,
      TileMode.clamp,
      TileMode.clamp,
      Matrix4.identity().storage,
    );
    _shader = shader;
    _shaderImage = image;
    return shader;
  }

  @override
  void paintSnapshot(
    PaintingContext context,
    Offset offset,
    Size size,
    ui.Image image,
    Size sourceSize,
    double pixelRatio,
  ) {
    _paintCurl(context.canvas, offset, size, image);
  }

  @override
  void paint(
    PaintingContext context,
    Offset offset,
    Size size,
    PaintingContextCallback painter,
  ) {
    if (_surface != PageCurlSurface.back) painter(context, offset);
  }

  void _paintCurl(Canvas canvas, Offset offset, Size size, ui.Image image) {
    final t = _progress.clamp(0.0, 1.0);
    if (t <= 0) {
      if (_surface != PageCurlSurface.back) {
        canvas.drawImageRect(
          image,
          Offset.zero & Size(image.width.toDouble(), image.height.toDouble()),
          offset & size,
          Paint()..filterQuality = FilterQuality.medium,
        );
      }
      return;
    }

    canvas.save();
    canvas.clipRect(
      Rect.fromLTRB(
        offset.dx - (_allowBindingOverflow ? size.width * 1.15 : 0),
        offset.dy - size.height * 0.3,
        offset.dx + size.width * (_allowBindingOverflow ? 1.15 : 1.06),
        offset.dy + size.height * 1.3,
      ),
    );

    final w = size.width;
    final h = size.height;
    final grab = _grabY.clamp(0.0, 1.0);

    final tilt = (grab - 0.5) * 1.5 * _maxTilt * math.sin(math.pi * t);
    final foldX = w * (1 - t);
    final foldY = h * grab;

    final curlEnvelope = math.sin(math.pi * t).clamp(0.0, 1.0);
    final radius = math.max(0.1, w * _radiusRatio * curlEnvelope);

    final nx = math.cos(tilt);
    final ny = math.sin(tilt);
    final ux = -ny;
    final uy = nx;

    final reach = math.max(0.0, (w - foldX) - math.pi * radius);

    if (_surface != PageCurlSurface.back) {
      _paintCreaseShadow(canvas, offset, size, foldX, foldY, tilt, t);
    }

    var v = 0;
    for (var j = 0; j <= _rows; j++) {
      final fy = j / _rows;
      final y = h * fy;
      for (var i = 0; i <= _cols; i++) {
        final fx = i / _cols;
        final x = w * fx;

        final relX = x - foldX;
        final relY = y - foldY;
        final d = relX * nx + relY * ny;
        final p = relX * ux + relY * uy;

        double shifted;
        double phi;
        var covered = 0.0;
        if (d <= 0) {
          shifted = d;
          phi = 0;
          if (reach > 0) covered = (1 + d / reach).clamp(0.0, 1.0);
        } else {
          if (radius <= 0.1) {
            shifted = -d;
            phi = math.pi;
          } else {
            phi = d / radius;
            if (phi <= math.pi) {
              shifted = radius * math.sin(phi);
            } else {
              shifted = -(d - math.pi * radius);
              phi = math.pi;
            }
          }
        }

        _positions[v * 2] = offset.dx + foldX + ux * p + nx * shifted;
        _positions[v * 2 + 1] = offset.dy + foldY + uy * p + ny * shifted;
        _texCoords[v * 2] =
            (_surface == PageCurlSurface.back ? 1 - fx : fx) * image.width;
        _texCoords[v * 2 + 1] = fy * image.height;

        double shade;
        if (phi <= math.pi / 2) {
          shade = 0.88 + 0.12 * math.cos(phi);
        } else {
          final unroll = ((phi - math.pi / 2) / (math.pi / 2)).clamp(0.0, 1.0);
          shade = 0.88 + 0.12 * unroll;
        }
        shade *= 1 - 0.14 * covered;

        final sideMix = ((phi - math.pi * 0.48) / (math.pi * 0.04)).clamp(
          0.0,
          1.0,
        );
        _faceMix[v] = sideMix;
        _shades[v] = _grey(shade);

        final washOpacity = switch (_surface) {
          PageCurlSurface.paper => sideMix * 0.85,
          PageCurlSurface.back => 0.0,
          PageCurlSurface.front => 0.0,
        };
        _backWash[v] = _paperColor.withValues(alpha: washOpacity).toARGB32();

        final specular = math.sin(phi) * (phi < math.pi / 2 ? 1.0 : 0.35);
        _speculars[v] = _grey(specular * 0.07);

        v++;
      }
    }

    final visibleIndices = _indicesForSurface();
    if (visibleIndices.isEmpty) {
      canvas.restore();
      return;
    }

    final sheet = ui.Vertices.raw(
      ui.VertexMode.triangles,
      _positions,
      textureCoordinates: _texCoords,
      colors: _shades,
      indices: visibleIndices,
    );
    canvas.drawVertices(
      sheet,
      BlendMode.modulate,
      Paint()
        ..shader = _shaderFor(image)
        ..filterQuality = FilterQuality.medium,
    );
    sheet.dispose();

    if (_surface == PageCurlSurface.paper) {
      final wash = ui.Vertices.raw(
        ui.VertexMode.triangles,
        _positions,
        colors: _backWash,
        indices: visibleIndices,
      );
      canvas.drawVertices(wash, BlendMode.srcOver, Paint());
      wash.dispose();
    }

    final highlight = ui.Vertices.raw(
      ui.VertexMode.triangles,
      _positions,
      colors: _speculars,
      indices: visibleIndices,
    );
    canvas.drawVertices(
      highlight,
      BlendMode.dst,
      Paint()..blendMode = BlendMode.plus,
    );
    highlight.dispose();

    canvas.restore();
  }

  void _paintCreaseShadow(
    Canvas canvas,
    Offset offset,
    Size size,
    double foldX,
    double foldY,
    double tilt,
    double t,
  ) {
    final width = size.width * 0.08;
    if (width <= 0) return;
    final fade = math.sin(math.pi * t).clamp(0.0, 1.0);
    if (fade <= 0.02) return;

    canvas.save();
    canvas.clipRRect(
      RRect.fromRectAndRadius(offset & size, Radius.circular(borderRadius)),
    );
    canvas.translate(offset.dx + foldX, offset.dy + foldY);
    canvas.rotate(tilt);
    canvas.drawRect(
      Rect.fromLTRB(0, -size.height * 1.5, width, size.height * 1.5),
      Paint()
        ..shader = ui.Gradient.linear(Offset.zero, Offset(width, 0), [
          Colors.black.withValues(alpha: _shadowOpacity * 0.45 * fade),
          Colors.black.withValues(alpha: 0),
        ]),
    );
    canvas.restore();
  }

  /// Yüz maskesi alfa kanalıyla, ışık ve gölge ise gri kanalla taşınır.
  static int _grey(double value, {double opacity = 1}) {
    final channel = (value.clamp(0.0, 1.0) * 255).round();
    final alpha = (opacity.clamp(0.0, 1.0) * 255).round();
    return (alpha << 24) | (channel << 16) | (channel << 8) | channel;
  }

  @override
  void dispose() {
    _shader?.dispose();
    _shader = null;
    _shaderImage = null;
    super.dispose();
  }

  @override
  bool shouldRepaint(covariant _PageCurlPainter oldPainter) =>
      oldPainter._progress != _progress ||
      oldPainter._grabY != _grabY ||
      oldPainter._paperColor != _paperColor ||
      oldPainter._shadowOpacity != _shadowOpacity ||
      oldPainter._allowBindingOverflow != _allowBindingOverflow ||
      oldPainter._surface != _surface;
}
