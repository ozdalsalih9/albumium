import 'package:flutter/material.dart';

import '../theme/albumium_app_theme.dart';

/// A brief, branded overlay shown while Albumium opens.
///
/// [onFinished] is invoked exactly once after the one-shot sequence completes.
/// When the platform asks for reduced motion, the final frame is rendered
/// immediately and completion is reported on the following frame.
class AlbumiumLaunchScreen extends StatefulWidget {
  const AlbumiumLaunchScreen({
    super.key,
    required this.onFinished,
    this.duration = const Duration(milliseconds: 920),
  }) : assert(duration > Duration.zero);

  /// Called once when the launch overlay can be removed.
  final VoidCallback onFinished;

  /// The duration of the one-shot sequence.
  ///
  /// The production default intentionally stays below one second. A shorter
  /// duration can be supplied by focused widget tests.
  final Duration duration;

  @override
  State<AlbumiumLaunchScreen> createState() => _AlbumiumLaunchScreenState();
}

class _AlbumiumLaunchScreenState extends State<AlbumiumLaunchScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  bool _started = false;
  bool _finishScheduled = false;
  bool _finished = false;
  bool _motionDisabled = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..addStatusListener(_handleAnimationStatus);
    _fade = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.62, curve: Curves.easeOutCubic),
    );
    _scale = Tween<double>(
      begin: 0.94,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    if (!_started) {
      _started = true;
      _motionDisabled = disableAnimations;
      _startSequence();
      return;
    }

    if (!_motionDisabled && disableAnimations && !_finished) {
      _motionDisabled = true;
      _controller
        ..stop()
        ..value = 1;
      _scheduleFinishOnNextFrame();
    }
  }

  @override
  void didUpdateWidget(covariant AlbumiumLaunchScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _controller.duration = widget.duration;
    }
  }

  void _startSequence() {
    if (_motionDisabled) {
      _controller.value = 1;
      _scheduleFinishOnNextFrame();
    } else {
      _controller.forward(from: 0);
    }
  }

  void _handleAnimationStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _scheduleFinishOnNextFrame();
    }
  }

  void _scheduleFinishOnNextFrame() {
    if (_finishScheduled || _finished) return;
    _finishScheduled = true;

    WidgetsBinding.instance.scheduleFrameCallback((_) {
      if (!mounted || _finished) return;
      _finished = true;
      widget.onFinished();
    });
  }

  @override
  void dispose() {
    _controller
      ..removeStatusListener(_handleAnimationStatus)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = AlbumiumAppTheme.colorsOf(context);
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      container: true,
      liveRegion: true,
      label: 'Uygulama açılıyor. Anılar, zarafetle saklanır.',
      child: ExcludeSemantics(
        child: RepaintBoundary(
          child: ColoredBox(
            color: colors.background,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colors.heroStart,
                    Color.lerp(colors.heroStart, colors.heroEnd, 0.56)!,
                    colors.heroEnd,
                  ],
                  stops: const [0, 0.52, 1],
                ),
              ),
              child: SafeArea(
                child: Center(
                  child: AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      return FadeTransition(
                        opacity: _fade,
                        child: ScaleTransition(scale: _scale, child: child),
                      );
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _AnimatedBrandMark(
                          progress: _controller,
                          glowColor: colors.glow,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Anılar, zarafetle saklanır.',
                          textAlign: TextAlign.center,
                          style: textTheme.titleMedium?.copyWith(
                            color: colors.text,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.35,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 32,
                          height: 1,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(1),
                            color: colors.primary.withValues(alpha: 0.52),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedBrandMark extends StatelessWidget {
  const _AnimatedBrandMark({required this.progress, required this.glowColor});

  static const _assetName = 'assets/branding/albumium_brand_mark.png';

  final Animation<double> progress;
  final Color glowColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 176,
      child: Stack(
        fit: StackFit.expand,
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: progress,
            builder: (context, _) {
              final glowOpacity = 0.36 + (progress.value * 0.2);
              return DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      glowColor.withValues(alpha: glowOpacity),
                      glowColor.withValues(alpha: glowOpacity * 0.22),
                      Colors.transparent,
                    ],
                    stops: const [0, 0.52, 1],
                  ),
                ),
              );
            },
          ),
          const Padding(
            padding: EdgeInsets.all(18),
            child: Image(
              image: AssetImage(_assetName),
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: AnimatedBuilder(
              animation: progress,
              builder: (context, _) {
                final sweep = Curves.easeInOut.transform(
                  const Interval(0.18, 0.82).transform(progress.value),
                );
                final leading = -2.8 + (sweep * 5.6);
                return ShaderMask(
                  blendMode: BlendMode.srcIn,
                  shaderCallback: (bounds) => LinearGradient(
                    begin: Alignment(leading, -1),
                    end: Alignment(leading + 0.72, 1),
                    colors: const [
                      Colors.transparent,
                      Color(0x00FFFFFF),
                      Color(0x66FFFFFF),
                      Color(0x00FFFFFF),
                      Colors.transparent,
                    ],
                    stops: const [0, 0.34, 0.5, 0.66, 1],
                  ).createShader(bounds),
                  child: const Image(
                    image: AssetImage(_assetName),
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
