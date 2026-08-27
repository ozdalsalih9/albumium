import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/services.dart';

import 'page_curl.dart';

const _defaultPaper = Color(0xFFF1EBE1);

/// Parmak konumu bilinmediğinde kullanılan tutma noktası. Tam orta yerine
/// hafifçe altta: okuyan bir el yaprağı sağ alt köşeye yakın tutar.
const _defaultGrabY = 0.62;

/// Sayfanın yerine oturmasını sağlayan yay. Kritik sönümlü seçilir; kâğıt
/// zıplamaz, hızlıca yerine yaslanır.
final _pageSpring = SpringDescription.withDampingRatio(mass: 1, stiffness: 190);

/// Tek bir yaprağın çevrilme anını çizen durumsuz görünüm.
///
/// [progress] 0 iken [front] tam görünür, 1 iken yaprak tamamen çevrilmiş ve
/// [back] açıkta kalmıştır. Ekrandaki etkileşimli [PageFlipView] ile MP4 dışa
/// aktarımı aynı çizimi kullanır; böylece paylaşılan video ile uygulamadaki
/// hareket birebir aynı görünür.
class FlipFrame extends StatelessWidget {
  const FlipFrame({
    super.key,
    required this.progress,
    required this.front,
    required this.back,
    this.grabY = _defaultGrabY,
    this.paperColor = _defaultPaper,
    this.borderRadius = 6,
  });

  /// Çevrilen yaprağın ön yüzü (başlangıçta üstte duran sayfa).
  final Widget front;

  /// Yaprak kalkınca açığa çıkan sayfa.
  final Widget back;

  /// 0 = kapalı, 1 = tamamen çevrilmiş.
  final double progress;

  /// Yaprağın tutulduğu dikey nokta; kat çizgisinin eğimini belirler.
  final double grabY;

  final Color paperColor;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final t = progress.clamp(0.0, 1.0);

    return Stack(
      clipBehavior: Clip.none,
      fit: StackFit.expand,
      children: [
        _sheet(back),
        if (t < 0.999)
          PageCurl(
            progress: t,
            grabY: grabY,
            paperColor: paperColor,
            borderRadius: borderRadius,
            child: _sheet(front),
          ),
      ],
    );
  }

  /// Bir sayfayı kâğıt yüzeyi gibi sarar.
  ///
  /// Zemin rengi aynı zamanda kıvrılan yaprağın şeritlerinin saydam
  /// kalmamasını güvence altına alır; saydam şeritler soyulma sırasında
  /// altındaki sayfayı sızdırıp kâğıt hissini bozardı.
  Widget _sheet(Widget child) {
    final radius = BorderRadius.circular(borderRadius);
    return ClipRRect(
      borderRadius: radius,
      child: ColoredBox(color: paperColor, child: child),
    );
  }
}

enum _FlipDirection { none, forward, backward }

/// [PageFlipView] uzerinde disaridan sayfa cevirmeyi saglar.
class PageFlipController {
  _PageFlipViewState? _state;

  int get page => _state?._index ?? 0;

  bool get isTurning => _state?._isTurning ?? false;

  /// [grabY] verilirse yaprak o dikey noktadan tutulmuş gibi kıvrılır;
  /// sayfaya dokunarak çevirirken dokunulan yer buraya aktarılır.
  void next({double? grabY}) => _state?._turnForward(grabY: grabY);

  void previous({double? grabY}) => _state?._turnBackward(grabY: grabY);

  void jumpTo(int index) => _state?._jumpTo(index);
}

/// Sayfaları gerçek bir kitap gibi cilt hattı etrafında çeviren görünüm.
///
/// Parmakla sürüklendiğinde yaprak parmağı takip eder; bırakıldığında hıza ve
/// kat edilen mesafeye göre ya çevrilmeyi tamamlar ya da geri yaslanır.
class PageFlipView extends StatefulWidget {
  const PageFlipView({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.controller,
    this.onPageChanged,
    this.paperColor = _defaultPaper,
    this.turnDuration = const Duration(milliseconds: 760),
    this.borderRadius = 6,
  });

  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final PageFlipController? controller;
  final ValueChanged<int>? onPageChanged;
  final Color paperColor;
  final Duration turnDuration;
  final double borderRadius;

  @override
  State<PageFlipView> createState() => _PageFlipViewState();
}

class _PageFlipViewState extends State<PageFlipView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _turn = AnimationController(
    vsync: this,
    duration: widget.turnDuration,
  )..addStatusListener(_handleStatus);

  int _index = 0;
  _FlipDirection _direction = _FlipDirection.none;
  double _width = 1;
  double _height = 1;
  double _grabY = _defaultGrabY;
  bool _dragging = false;

  bool get _isTurning => _direction != _FlipDirection.none;

  @override
  void initState() {
    super.initState();
    widget.controller?._state = this;
  }

  @override
  void didUpdateWidget(PageFlipView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._state = null;
      widget.controller?._state = this;
    }
    if (_index > widget.itemCount - 1) {
      _index = math.max(0, widget.itemCount - 1);
    }
  }

  @override
  void dispose() {
    if (widget.controller?._state == this) widget.controller?._state = null;
    _turn.dispose();
    super.dispose();
  }

  void _handleStatus(AnimationStatus status) {
    // Sürükleme sırasında değer uç noktaya dayandığında sayfa ilerlemesin;
    // ilerlemeye yalnızca parmak bırakıldıktan sonra karar verilir.
    if (_dragging) return;
    if (status != AnimationStatus.completed &&
        status != AnimationStatus.dismissed) {
      return;
    }
    // animateWith ile başlatılan bir yay benzetimi, hangi değerde durursa
    // dursun "completed" durumuna geçer. Bu yüzden sayfanın ilerleyip
    // ilerlemeyeceğine duruma değil, yaprağın gerçekten yerine oturup
    // oturmadığına bakılarak karar verilir; aksi hâlde geri yaslanan yaprak da
    // sayfayı çevirmiş sayılırdı.
    if (_turn.value < 0.999) {
      if (_direction != _FlipDirection.none) {
        setState(() => _direction = _FlipDirection.none);
        _turn.value = 0;
      }
      return;
    }
    final direction = _direction;
    setState(() {
      if (direction == _FlipDirection.forward) {
        _index++;
      } else if (direction == _FlipDirection.backward) {
        _index--;
      }
      _direction = _FlipDirection.none;
    });
    HapticFeedback.selectionClick();
    widget.onPageChanged?.call(_index);
    // Denetleyiciyi durum geri çağrısı içinde değil, kare sonunda sıfırla.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _direction == _FlipDirection.none) _turn.value = 0;
    });
  }

  void _turnForward({double? grabY}) {
    if (_turn.isAnimating || _dragging) return;
    if (_index >= widget.itemCount - 1) return;
    setState(() {
      _direction = _FlipDirection.forward;
      _grabY = grabY?.clamp(0.0, 1.0) ?? _defaultGrabY;
    });
    _turn.forward(from: 0);
  }

  void _turnBackward({double? grabY}) {
    if (_turn.isAnimating || _dragging) return;
    if (_index <= 0) return;
    setState(() {
      _direction = _FlipDirection.backward;
      _grabY = grabY?.clamp(0.0, 1.0) ?? _defaultGrabY;
    });
    _turn.forward(from: 0);
  }

  void _jumpTo(int index) {
    final target = index.clamp(0, widget.itemCount - 1);
    if (target == _index && !_isTurning) return;
    _turn.stop();
    setState(() {
      _index = target;
      _direction = _FlipDirection.none;
    });
    _turn.value = 0;
    widget.onPageChanged?.call(_index);
  }

  void _onDragStart(DragStartDetails details) {
    // Uçmakta olan yaprağı yakala: animasyon sırasında parmağını koyan
    // kullanıcı kaldığı yerden devam edebilmeli.
    _turn.stop();
    _dragging = true;
    // Sayfa ilerlemesi henüz sıfırlanmadıysa burada temizle; aksi hâlde yeni
    // sürükleme bitmiş bir çevirmenin değeriyle başlar.
    if (_direction == _FlipDirection.none && _turn.value != 0) {
      _turn.value = 0;
    }
    _grabY = (details.localPosition.dy / _height).clamp(0.0, 1.0);
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (!_dragging) return;
    final delta = details.primaryDelta ?? 0;
    if (_direction == _FlipDirection.none) {
      if (delta.abs() < 0.5) return;
      if (delta < 0 && _index < widget.itemCount - 1) {
        setState(() => _direction = _FlipDirection.forward);
      } else if (delta > 0 && _index > 0) {
        setState(() => _direction = _FlipDirection.backward);
      } else {
        return;
      }
    }
    final sign = _direction == _FlipDirection.forward ? -1.0 : 1.0;
    // Ust sinir tam 1.0 degil: deger uc noktaya dayaninca denetleyici
    // tamamlandi durumuna gecer ve sayfa parmak hala ekrandayken ilerlerdi.
    _turn.value = (_turn.value + sign * delta / _width).clamp(0.0, 0.995);
  }

  void _onDragEnd(DragEndDetails details) {
    if (!_dragging) return;
    _dragging = false;
    if (_direction == _FlipDirection.none) return;

    final sign = _direction == _FlipDirection.forward ? -1.0 : 1.0;
    // Birakma hizini sayfa genisligine gore normallestir: birim/saniye.
    final velocity = (details.primaryVelocity ?? 0) * sign / _width;
    // Hizli savurma mesafeye bakmadan tamamlar; yavas birakmada kat edilen
    // yol belirler. Geriye dogru guclu savurma ise yapragi geri yaslar.
    final complete = velocity > 0.9 || (_turn.value > 0.42 && velocity > -0.9);
    final target = complete ? 1.0 : 0.0;

    // Sonucu durum dinleyicisi bağlar: yay nerede durursa dursun, sayfanın
    // ilerleyip ilerlemediğine ulaşılan değere bakılarak karar verilir.
    _turn.animateWith(
      SpringSimulation(_pageSpring, _turn.value, target, velocity),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _width = constraints.maxWidth <= 0 ? 1 : constraints.maxWidth;
        _height = constraints.maxHeight <= 0 ? 1 : constraints.maxHeight;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragStart: _onDragStart,
          onHorizontalDragUpdate: _onDragUpdate,
          onHorizontalDragEnd: _onDragEnd,
          child: AnimatedBuilder(
            animation: _turn,
            builder: (context, _) => _buildContent(context),
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context) {
    if (widget.itemCount == 0) return const SizedBox.expand();

    final last = widget.itemCount - 1;
    if (_direction == _FlipDirection.none) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius),
        child: widget.itemBuilder(context, _index.clamp(0, last)),
      );
    }

    final forward = _direction == _FlipDirection.forward;
    final frontIndex = (forward ? _index : _index - 1).clamp(0, last);
    final backIndex = (forward ? _index + 1 : _index).clamp(0, last);

    return FlipFrame(
      progress: forward ? _turn.value : 1 - _turn.value,
      grabY: _grabY,
      paperColor: widget.paperColor,
      borderRadius: widget.borderRadius,
      front: widget.itemBuilder(context, frontIndex),
      back: widget.itemBuilder(context, backIndex),
    );
  }
}

/// Sayfanın etrafına cilt ve istiflenmiş yaprak kenarları çizerek elde tutulan
/// bir kitap izlenimi verir.
class BookFrame extends StatelessWidget {
  const BookFrame({
    super.key,
    required this.child,
    required this.paperColor,
    this.remainingPages = 3,
    this.borderRadius = 6,
  });

  final Widget child;
  final Color paperColor;

  /// Sağ kenarda kaç yaprak kenarının görüneceği.
  final int remainingPages;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final edges = remainingPages.clamp(0, 4);
    return Stack(
      clipBehavior: Clip.none,
      fit: StackFit.expand,
      children: [
        for (var layer = edges; layer >= 1; layer--)
          Positioned(
            left: layer * 2.0,
            right: -layer * 2.5,
            top: layer * 1.5,
            bottom: -layer * 1.5,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Color.lerp(paperColor, Colors.black, layer * 0.09),
                  borderRadius: BorderRadius.circular(borderRadius),
                ),
              ),
            ),
          ),
        child,
        // Cilt payı: sol kenarda sayfanın içine doğru sönen koyu bant.
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          width: 26,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.horizontal(
                  left: Radius.circular(borderRadius),
                ),
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.black.withValues(alpha: 0.34),
                    Colors.black.withValues(alpha: 0.10),
                    Colors.black.withValues(alpha: 0),
                  ],
                  stops: const [0, 0.45, 1],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
