import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Çevrilen yaprağı, parmağın tuttuğu noktaya çapraz tutunan bir silindirin
/// etrafına sararak kıvıran görünüm.
///
/// Sayfa önce ekranın gerçek piksel yoğunluğunda rasterleştirilir, sonra bir
/// üçgen ağa dokunup [Canvas.drawVertices] ile yeniden çizilir. Her köşe
/// noktası, kat çizgisine olan dik uzaklığına göre silindirin üzerine taşınır:
/// yarım turu tamamlayan noktalar kâğıdın arka yüzüne geçer ve dokusuyla
/// birlikte kendiliğinden aynalanır. Bu yüzden yaprağın arkası ayrı bir katman
/// olarak çizilmez.
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
      ..shadowOpacity = widget.shadowOpacity;
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
  }) : _progress = progress,
       _grabY = grabY,
       _paperColor = paperColor,
       _shadowOpacity = shadowOpacity;

  final double borderRadius;

  /// Ağın çözünürlüğü. Kıvrım yatayda geliştiği için sütun sayısı yüksek
  /// tutulur; satırlar yalnızca kat çizgisi eğildiğinde iş görür.
  static const _cols = 44;
  static const _rows = 26;

  /// Silindirin yarıçapı (genişliğe oran). Kâğıdın sertliğini belirler:
  /// büyüdükçe kıvrım yayvan, küçüldükçe keskin olur.
  static const _radiusRatio = 0.085;

  /// Kat çizgisinin, köşeden tutulduğunda alabileceği en büyük eğim (radyan).
  static const _maxTilt = 0.38;

  static const _vertexCount = (_cols + 1) * (_rows + 1);

  double _progress;
  double _grabY;
  Color _paperColor;
  double _shadowOpacity;

  ui.Image? _shaderImage;
  ui.ImageShader? _shader;

  // Tamponlar kare başına yeniden ayrılmaz; ağın boyutu sabittir.
  final _positions = Float32List(_vertexCount * 2);
  final _texCoords = Float32List(_vertexCount * 2);
  final _shades = Int32List(_vertexCount);
  final _speculars = Int32List(_vertexCount);
  final _backWash = Int32List(_vertexCount);
  late final Uint16List _indices = _buildIndices();

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

  /// Rasterleştirilmiş sayfayı doku olarak bağlar. Gölgelendirici kare başına
  /// değil, yalnızca görüntü değiştiğinde yeniden kurulur.
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
    // Rasterleştirme yapılamadığında (ör. içeride bir platform görünümü varsa)
    // sayfayı kıvırmadan olduğu gibi çiz; hareket kaybolur ama içerik doğru
    // kalır.
    painter(context, offset);
  }

  void _paintCurl(Canvas canvas, Offset offset, Size size, ui.Image image) {
    final t = _progress.clamp(0.0, 1.0);
    if (t <= 0) {
      canvas.drawImageRect(
        image,
        Offset.zero & Size(image.width.toDouble(), image.height.toDouble()),
        offset & size,
        Paint()..filterQuality = FilterQuality.medium,
      );
      return;
    }

    // Kırpma sınırı yalnızca cilt tarafında dardır.
    //
    // Üstte ve altta serbest bırakılır: köşesinden tutulan yaprak, çapraz kat
    // çizgisi etrafında dönerken ucu sayfanın üst kenarını aşar ve gerçek bir
    // kitapta da masanın üzerine taşar. Burayı sayfa dikdörtgenine kırpmak
    // kâğıdı üstte düz bir çizgi hâlinde keserdi.
    //
    // Solda ise cilt hattında kesilir: yaprak oranın soluna geçtiğinde artık
    // karşı sayfanın üzerindedir ve tek sayfalı görünümde görünmemelidir.
    canvas.save();
    canvas.clipRect(
      Rect.fromLTRB(
        offset.dx,
        offset.dy - size.height * 0.3,
        offset.dx + size.width * 1.06,
        offset.dy + size.height * 1.3,
      ),
    );

    final w = size.width;
    final h = size.height;
    final grab = _grabY.clamp(0.0, 1.0);

    // Kat çizgisi sağ kenardan cilde doğru süpürür. Eğimi, parmağın sayfanın
    // ortasından ne kadar uzakta tuttuğuyla orantılıdır ve çevirmenin ortasında
    // tepe yapıp sonunda yeniden dikleşir.
    final tilt = (grab - 0.5) * 2 * _maxTilt * math.sin(math.pi * t);
    final foldX = w * (1 - t);
    final foldY = h * grab;
    // Yarıçap ilk anda kademeli açılır, yoksa kâğıt daha ilk pikselde
    // katlanmış görünür.
    final radius = math.max(4.0, w * _radiusRatio * math.min(1.0, t * 6));

    // Kat çizgisinin birim normali (katlanan tarafa bakar) ve doğrultusu.
    final nx = math.cos(tilt);
    final ny = math.sin(tilt);
    final ux = -ny;
    final uy = nx;

    // Kalkan kapağın sola ne kadar uzandığı; altında kalan düz bölgeyi
    // gölgelemek için kullanılır.
    final reach = math.max(0.0, (w - foldX) - math.pi * radius);

    _paintCreaseShadow(canvas, offset, size, foldX, foldY, tilt, t);

    var v = 0;
    for (var j = 0; j <= _rows; j++) {
      final fy = j / _rows;
      final y = h * fy;
      for (var i = 0; i <= _cols; i++) {
        final fx = i / _cols;
        final x = w * fx;

        final relX = x - foldX;
        final relY = y - foldY;
        // Kat çizgisine dik uzaklık ve çizgi boyunca konum.
        final d = relX * nx + relY * ny;
        final p = relX * ux + relY * uy;

        double shifted;
        double phi;
        var covered = 0.0;
        if (d <= 0) {
          // Kâğıdın hâlâ düz duran kısmı; dönüşüm birim dönüşümdür.
          shifted = d;
          phi = 0;
          if (reach > 0) covered = (1 + d / reach).clamp(0.0, 1.0);
        } else {
          phi = d / radius;
          if (phi <= math.pi) {
            // Silindirin üzerine sarılan kısım.
            shifted = radius * math.sin(phi);
          } else {
            // Yarım turu tamamlayıp öbür yana düz uzanan kapak.
            shifted = -(d - math.pi * radius);
            phi = math.pi;
          }
        }

        _positions[v * 2] = offset.dx + foldX + ux * p + nx * shifted;
        _positions[v * 2 + 1] = offset.dy + foldY + uy * p + ny * shifted;
        _texCoords[v * 2] = fx * image.width;
        _texCoords[v * 2 + 1] = fy * image.height;

        // Yüzeyin ışığa göre eğimi. phi büyüdükçe kâğıt okuyucudan uzaklaşır;
        // yarım turdan sonrası kâğıdın arka yüzüdür ve belirgin biçimde daha
        // koyu olur.
        double shade;
        if (phi <= math.pi / 2) {
          shade = 0.55 + 0.45 * math.cos(phi);
        } else {
          shade = 0.50 + 0.20 * -math.cos(phi);
        }
        // Kapağın altında kalan düz bölge gölgede kalır.
        shade *= 1 - 0.34 * covered;
        _shades[v] = _grey(shade);

        // Yarım turu geçen yüzey kâğıdın arkasıdır: orada mürekkep değil
        // kâğıt görünmeli. Ön yüzün dokusu yalnızca soluk bir iz olarak
        // sızar, aynalanmış yazı okunur kalmaz.
        final back = ((phi - math.pi / 2) / (math.pi / 2)).clamp(0.0, 1.0);
        _backWash[v] = _paperColor
            .withValues(alpha: 0.90 * math.min(1.0, back * 2.4))
            .toARGB32();

        // Işık kâğıdın kıvrıldığı yeri sıyırarak vurur. Çok hafif tutulur;
        // abartılırsa kâğıt değil plastik görünür.
        final specular = math.sin(phi) * (phi < math.pi / 2 ? 1.0 : 0.25);
        _speculars[v] = _grey(specular * 0.12);

        v++;
      }
    }

    final sheet = ui.Vertices.raw(
      ui.VertexMode.triangles,
      _positions,
      textureCoordinates: _texCoords,
      colors: _shades,
      indices: _indices,
    );
    canvas.drawVertices(
      sheet,
      BlendMode.modulate,
      Paint()
        ..shader = _shaderFor(image)
        ..filterQuality = FilterQuality.medium,
    );
    sheet.dispose();

    // Arka yüzün kâğıt yıkaması. BlendMode.dst yalnızca köşe renklerini
    // kullanır; kâğıt, dokunun üzerine normal biçimde bindirilir.
    final wash = ui.Vertices.raw(
      ui.VertexMode.triangles,
      _positions,
      colors: _backWash,
      indices: _indices,
    );
    canvas.drawVertices(wash, BlendMode.dst, Paint());
    wash.dispose();

    // Vurgu ayrı bir geçiş: modulate yalnızca koyulaştırabilir, ışığı eklemek
    // için toplamalı karışım gerekir.
    final highlight = ui.Vertices.raw(
      ui.VertexMode.triangles,
      _positions,
      colors: _speculars,
      indices: _indices,
    );
    canvas.drawVertices(
      highlight,
      BlendMode.dst,
      Paint()..blendMode = BlendMode.plus,
    );
    highlight.dispose();

    canvas.restore();
  }

  /// Kalkan yaprağın kat hattında bıraktığı koyu iz. Kıvrımın hemen sağındaki,
  /// yeni açığa çıkan sayfaya düşer ve yaprak uzaklaştıkça yumuşayarak çekilir.
  void _paintCreaseShadow(
    Canvas canvas,
    Offset offset,
    Size size,
    double foldX,
    double foldY,
    double tilt,
    double t,
  ) {
    final width = size.width * 0.16;
    if (width <= 0) return;
    final fade = math.sin(math.pi * t).clamp(0.0, 1.0);
    canvas.save();
    // Gölge, açığa çıkan sayfanın üzerine düşer; sayfanın dışına taşmamalı.
    canvas.clipRRect(
      RRect.fromRectAndRadius(offset & size, Radius.circular(borderRadius)),
    );
    canvas.translate(offset.dx + foldX, offset.dy + foldY);
    canvas.rotate(tilt);
    canvas.drawRect(
      Rect.fromLTRB(0, -size.height, width, size.height),
      Paint()
        ..shader = ui.Gradient.linear(Offset.zero, Offset(width, 0), [
          Colors.black.withValues(alpha: _shadowOpacity * fade),
          Colors.black.withValues(alpha: 0),
        ]),
    );
    canvas.restore();
  }

  /// Toplamalı karışımın da doğru çalışması için renkler her zaman tam
  /// opaktır; saydam bir köşe rengi eklenecek ışığı sıfırlardı.
  static int _grey(double value) {
    final channel = (value.clamp(0.0, 1.0) * 255).round();
    return 0xFF000000 | (channel << 16) | (channel << 8) | channel;
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
      oldPainter._shadowOpacity != _shadowOpacity;
}
