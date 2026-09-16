import 'dart:async';
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
/// The physical surface rendered by this pass of [PageCurl].
enum PageCurlSurface {
  /// Renders only the front-facing triangles (before the fold).
  front,

  /// Renders only the back-facing triangles (after wrapping around the cylinder).
  back,

  /// Renders both faces with paper wash on the back (single-page mode).
  paper,
}

/// Çevrilen yaprağı, parmağın tuttuğu noktaya çapraz tutunan bir silindirin
/// etrafına sararak kıvıran görünüm.
///
/// Sayfa önce ekranın gerçek piksel yoğunluğunda rasterleştirilir, sonra bir
/// üçgen ağa dokunup [Canvas.drawVertices] ile yeniden çizilir. Her köşe
/// noktası, kat çizgisine olan dik uzaklığına göre silindirin üzerine taşınır:
/// yarım turu tamamlayan noktalar kâğıdın arka yüzüne geçer ve dokusuyla
/// birlikte kendiliğinden aynalanır.
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

  /// Açık iki sayfalı kitapta kıvrılan yaprağın karşı sayfaya taşmasına izin verir.
  final bool allowBindingOverflow;

  /// The physical side of the page represented by [child].
  final PageCurlSurface surface;

  @override
  State<PageCurl> createState() => _PageCurlState();
}

class _PageCurlState extends State<PageCurl> {
  final _controller = SnapshotController();
  Timer? _warmupTimer;
  int _warmupTicks = 0;
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
    if (widget.progress > 0.001) {
      _startWarmupRefreshes();
    }
  }

  void _startWarmupRefreshes() {
    _warmupTimer?.cancel();
    _warmupTicks = 0;
    // Fotoğraflar diskten veya ağdan asenkron çözümlenirken snapshot'ı
    // periyodik olarak temizleyerek taze tut. Böylece ilk çevirmede parmak
    // basılı tutulsa bile resimler hazır olduğu anda ekranda anında görünür,
    // kullanıcı sayfayı geri kapatıp açmak zorunda kalmaz.
    _warmupTimer = Timer.periodic(const Duration(milliseconds: 60), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      _warmupTicks++;
      if (widget.progress > 0.001 && widget.progress < 0.999) {
        _controller.clear();
      }
      if (_warmupTicks >= 8) {
        timer.cancel();
      }
    });
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

    // Sayfa veya yüzey değiştiyse bayat snapshot'ı temizle ve warmup başlat
    if (oldWidget.child != widget.child || oldWidget.surface != widget.surface) {
      _controller.clear();
      if (widget.progress > 0.001) {
        _startWarmupRefreshes();
      }
    }
    // Dönüş yeni başladıysa warmup tazelemesi başlat
    if (oldWidget.progress <= 0.001 && widget.progress > 0.001) {
      _startWarmupRefreshes();
    }
    // Sürükleme başlangıcında (progress < 0.15) snapshot'ı taze tut
    if (widget.progress > 0.001 && widget.progress < 0.15) {
      _controller.clear();
    }
    _syncSnapshotting();
  }

  void _syncSnapshotting() {
    final turning = widget.progress > 0.001;
    if (_controller.allowSnapshotting != turning) {
      _controller.allowSnapshotting = turning;
      if (!turning) {
        _warmupTimer?.cancel();
        _controller.clear();
      }
    }
  }

  @override
  void dispose() {
    _warmupTimer?.cancel();
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

  /// Ağın çözünürlüğü. Mobil GPU'da 60 FPS akıcılık ve kusursuz eğim için dengelendi.
  static const _cols = 32;
  static const _rows = 20;

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
  bool _allowBindingOverflow;
  PageCurlSurface _surface;

  ui.Image? _shaderImage;
  ui.ImageShader? _shader;

  // Tamponlar kare başına yeniden ayrılmaz; ağın boyutu sabittir.
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
    if (_surface != PageCurlSurface.back) {
      painter(context, offset);
    }
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
    // Sayfa tamamen çevrildi: kıvrılan yaprak artık görünmez, çizme.
    // Böylece animasyon bitişinde "jump" artefaktı oluşmaz.
    if (t >= 1.0) return;

    // Kırpma sınırı yalnızca cilt tarafında dardır.
    //
    // Üstte ve altta serbest bırakılır: köşesinden tutulan yaprak, çapraz kat
    // çizgisi etrafında dönerken ucu sayfanın üst kenarını aşar ve gerçek bir
    // kitapta da masanın üzerine taşar. Burayı sayfa dikdörtgenine kırpmak
    // kâğıdı üstte düz bir çizgi hâlinde keserdi.
    //
    // Fiziksel kitapta sol sınır karşı sayfanın dış kenarına kadar açılır.
    // Tek sayfalı kullanım ise cilt kırpmasını korur.
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

    // Kıvrılma ekseninin eğimi. Sayfa tam ortadan çekildiğinde kat çizgisi
    // dikey kalır; yukarıdan tutulduğunda sola, aşağıdan tutulduğunda sağa yatar.
    final tilt = ((grab - 0.5) * 2).clamp(-1.0, 1.0) * _maxTilt;

    final radius = w * _radiusRatio;

    // Kat çizgisinin x konumu. t=0'da sayfanın en sağındadır, t=1'de soluna geçer.
    // Sol kenarın biraz ötesine taşmasına izin verilir; yaprak ancak o zaman
    // tamamen düzleşip karşı sayfaya yaslanabilir.
    final foldX = w * (1.0 - t * 1.14);
    final foldY = h * grab;

    final nx = math.cos(tilt);
    final ny = math.sin(tilt);
    final ux = -ny;
    final uy = nx;

    final reach = math.max(0.0, (w - foldX) - math.pi * radius);

    // Kalkan yaprağın altındaki sayfaya düşen kat gölgesi
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
        _texCoords[v * 2] =
            (_surface == PageCurlSurface.back ? 1 - fx : fx) * image.width;
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

        final sideMix = ((phi - math.pi * 0.48) / (math.pi * 0.04)).clamp(
          0.0,
          1.0,
        );
        _faceMix[v] = sideMix;
        _shades[v] = _grey(shade);

        // Yarım turu geçen yüzey kâğıdın arkasıdır: orada mürekkep değil
        // kâğıt görünmeli. Ön yüzün dokusu yalnızca soluk bir iz olarak
        // sızar, aynalanmış yazı okunur kalmaz.
        final back = ((phi - math.pi / 2) / (math.pi / 2)).clamp(0.0, 1.0);
        // Temanın kâğıt rengine hafif gölgeleme uygulayarak saf beyaz
        // görünmesini engelle, gerçekçi kâğıt tonunu hissettir.
        final backShade = (0.72 + 0.20 * -math.cos(phi)).clamp(0.55, 0.94);
        final tonedPaper = Color.lerp(
          Color.lerp(_paperColor, const Color(0xFFD4C7B0), 0.15)!,
          Colors.black,
          1.0 - backShade,
        )!;
        // Arka yüz kâğıdı sayfa içeriğini tam örtmeli. back*3 ile geçişi
        // hızlandır: phi=π/2'de 0, phi=π*0.83'te ~1 olsun. Max 0.97 ile
        // arka sayfadan hafif saydam iz korunur (istenilen efekt).
        _backWash[v] = tonedPaper
            .withValues(alpha: (back * 2.0).clamp(0.0, 0.70))
            .toARGB32();

        // Işık kâğıdın kıvrıldığı yeri sıyırarak vurur. Çok hafif tutulur;
        // abartılırsa kâğıt değil plastik görünür.
        final specular = math.sin(phi) * (phi < math.pi / 2 ? 1.0 : 0.20);
        _speculars[v] = _grey(specular * 0.10);

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

    // Arka yüzün kâğıt yıkaması (tek sayfa / paper modunda).
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

    // Vurgu ayrı bir geçiş: modulate yalnızca koyulaştırabilir, ışığı eklemek
    // için toplamalı karışım gerekir.
    final highlight = ui.Vertices.raw(
      ui.VertexMode.triangles,
      _positions,
      colors: _speculars,
      indices: visibleIndices,
    );
    canvas.drawVertices(
      highlight,
      BlendMode.srcOver,
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
      oldPainter._shadowOpacity != _shadowOpacity ||
      oldPainter._allowBindingOverflow != _allowBindingOverflow ||
      oldPainter._surface != _surface;
}
