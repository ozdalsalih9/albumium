import 'dart:async';

import 'package:flutter/material.dart';

/// Uygulama genelinde kullanılan hareket süreleri ve eğrileri.
///
/// Tek yerde toplanmaları, farklı ekranlardaki animasyonların aynı ritimde
/// hissettirmesini sağlar.
abstract final class Motion {
  static const fast = Duration(milliseconds: 180);
  static const medium = Duration(milliseconds: 320);
  static const slow = Duration(milliseconds: 620);

  /// Yumuşak başlayıp yumuşak biten genel amaçlı eğri.
  static const curve = Curves.easeOutCubic;

  /// Hafif yaylanma; beliren öğeler için.
  static const entrance = Curves.easeOutBack;
}

/// Dokunulduğunda hafifçe küçülerek fiziksel bir basma hissi veren sarmalayıcı.
class PressableScale extends StatefulWidget {
  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.pressedScale = 0.96,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double pressedScale;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      onTapDown: (_) => _setPressed(true),
      onTapUp: (_) => _setPressed(false),
      onTapCancel: () => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? widget.pressedScale : 1,
        duration: Motion.fast,
        curve: Motion.curve,
        child: widget.child,
      ),
    );
  }
}

/// İlk kez göründüğünde aşağıdan yukarı süzülerek beliren öğe.
///
/// [delay] ile bir liste içindeki öğelere kademeli gecikme verilebilir; bu da
/// ekranın tek parça yerine sırayla dizilmesini sağlar.
class EntranceFade extends StatefulWidget {
  const EntranceFade({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offset = 24,
    this.duration = Motion.slow,
  });

  final Widget child;
  final Duration delay;

  /// Başlangıçta kaç piksel aşağıdan geleceği.
  final double offset;
  final Duration duration;

  @override
  State<EntranceFade> createState() => _EntranceFadeState();
}

class _EntranceFadeState extends State<EntranceFade>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: widget.duration,
  );
  Timer? _delayTimer;

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      // Zamanlayıcı alanda tutulur; ekran gecikme dolmadan kapanırsa iptal
      // edilebilsin diye.
      _delayTimer = Timer(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _delayTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: _controller, curve: Motion.curve);
    return AnimatedBuilder(
      animation: curved,
      builder: (context, child) => Opacity(
        opacity: curved.value,
        child: Transform.translate(
          offset: Offset(0, widget.offset * (1 - curved.value)),
          child: child,
        ),
      ),
      child: widget.child,
    );
  }
}

/// Ekranlar arasında kitap sayfası açılıyormuş hissi veren geçiş.
///
/// Yeni ekran hafifçe büyüyerek ve sağdan kayarak gelir, eski ekran ise
/// arkada biraz küçülüp soluklaşır.
Route<T> albumRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 420),
    reverseTransitionDuration: const Duration(milliseconds: 320),
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final enter = CurvedAnimation(parent: animation, curve: Motion.curve);
      final exit = CurvedAnimation(
        parent: secondaryAnimation,
        curve: Motion.curve,
      );
      return FadeTransition(
        opacity: enter,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.06, 0),
            end: Offset.zero,
          ).animate(enter),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.97, end: 1).animate(enter),
            child: ScaleTransition(
              scale: Tween<double>(begin: 1, end: 0.96).animate(exit),
              child: child,
            ),
          ),
        ),
      );
    },
  );
}
