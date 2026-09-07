import 'package:flutter/material.dart';
import '../l10n/albumium_localizations.dart';

class ReaderZoomView extends StatefulWidget {
  const ReaderZoomView({super.key, required this.child});
  final Widget child;
  @override
  State<ReaderZoomView> createState() => _ReaderZoomViewState();
}

class _ReaderZoomViewState extends State<ReaderZoomView> {
  final _controller = TransformationController();
  bool _zoomed = false;
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _setZoom(double scale, Size size) {
    final next = scale.clamp(1.0, 4.0);
    setState(() {
      _zoomed = next > 1.01;
      _controller.value = Matrix4.identity()
        ..translateByDouble(
          size.width * (1 - next) / 2,
          size.height * (1 - next) / 2,
          0,
          1,
        )
        ..scaleByDouble(next, next, 1, 1);
    });
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final size = constraints.biggest;
      return Stack(
        fit: StackFit.expand,
        children: [
          InteractiveViewer(
            key: const ValueKey('reader-zoom-view'),
            transformationController: _controller,
            minScale: 1,
            maxScale: 4,
            panEnabled: _zoomed,
            onInteractionEnd: (_) => setState(
              () => _zoomed = _controller.value.getMaxScaleOnAxis() > 1.01,
            ),
            child: IgnorePointer(ignoring: _zoomed, child: widget.child),
          ),
          Positioned(
            top: 4,
            right: 12,
            child: Material(
              color: Theme.of(
                context,
              ).colorScheme.surface.withValues(alpha: .92),
              borderRadius: BorderRadius.circular(24),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    tooltip: context.tr('Uzaklaştır'),
                    onPressed: _zoomed
                        ? () => _setZoom(
                            _controller.value.getMaxScaleOnAxis() / 1.5,
                            size,
                          )
                        : null,
                    icon: const Icon(Icons.zoom_out),
                  ),
                  IconButton(
                    tooltip: context.tr('Yakınlaştır'),
                    onPressed: () => _setZoom(
                      _controller.value.getMaxScaleOnAxis() * 1.5,
                      size,
                    ),
                    icon: const Icon(Icons.zoom_in),
                  ),
                  if (_zoomed)
                    IconButton(
                      tooltip: context.tr('Ekrana sığdır'),
                      onPressed: () => _setZoom(1, size),
                      icon: const Icon(Icons.fit_screen),
                    ),
                ],
              ),
            ),
          ),
        ],
      );
    },
  );
}
