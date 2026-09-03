import 'package:flutter/material.dart';

import '../models/album_models.dart';
import 'album_cover.dart';

/// Renders a tangible 3D physical photobook with realistic spine thickness,
/// stacked paper block edges, hardcover bevel, and ambient floor shadow.
class AlbumCover3D extends StatelessWidget {
  const AlbumCover3D({
    super.key,
    required this.album,
    this.compact = false,
    this.perspective = true,
    this.onTap,
  });

  final AlbumModel album;
  final bool compact;
  final bool perspective;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;

          // 3D Perspective Book container
          return Center(
            child: SizedBox(
              width: width,
              height: height,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  // 1. Zemin Yumuşak Derinlik Gölgesi (Ambient floor drop shadow)
                  if (!compact)
                    Positioned(
                      bottom: 6,
                      left: 24,
                      right: 14,
                      height: 28,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.6),
                              blurRadius: 26,
                              offset: const Offset(12, 14),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // 2. 3D Açılı Kitap Gövdesi (3D Tilted Book Body)
                  Transform(
                    alignment: Alignment.center,
                    transform: perspective
                        ? (Matrix4.identity()
                            ..setEntry(3, 2, 0.0016)
                            ..rotateY(-0.12)
                            ..rotateX(0.035))
                        : Matrix4.identity(),
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Ana kapak. Kapalı kitap kartında sağa ek bir sayfa
                        // şeridi çizilmez; bu detay kapaktan kopuk görünüyordu.
                        Container(
                          margin: EdgeInsets.only(
                            right: 0,
                            top: compact ? 0 : 4,
                            bottom: compact ? 0 : 4,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(
                              compact ? 10 : 16,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(
                                  alpha: compact ? 0.24 : 0.45,
                                ),
                                blurRadius: compact ? 5 : 20,
                                offset: Offset(
                                  compact ? 2 : 6,
                                  compact ? 3 : 8,
                                ),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(
                              compact ? 10 : 16,
                            ),
                            child: AlbumCover(
                              album: album,
                              compact: compact,
                              onTap: onTap,
                            ),
                          ),
                        ),

                        // C. Sol 3D Cilt Sırtı Kalınlığı & Kıvrımı (3D Spine Crease & Shimmer)
                        Positioned(
                          left: 0,
                          top: compact ? 2 : 4,
                          bottom: compact ? 2 : 4,
                          width: compact ? 16 : 26,
                          child: IgnorePointer(
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.only(
                                  topLeft: Radius.circular(compact ? 10 : 16),
                                  bottomLeft: Radius.circular(
                                    compact ? 10 : 16,
                                  ),
                                ),
                                gradient: LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [
                                    Colors.black.withValues(alpha: 0.45),
                                    Colors.white.withValues(alpha: 0.18),
                                    Colors.black.withValues(alpha: 0.25),
                                    Colors.transparent,
                                  ],
                                  stops: const [0.0, 0.35, 0.7, 1.0],
                                ),
                              ),
                            ),
                          ),
                        ),

                        // D. Cilt Tipi Rozeti / Detayı (Binding Type Badge/Stitch on Spine)
                        if (!compact)
                          Positioned(
                            left: 10,
                            top: 20,
                            bottom: 20,
                            width: 3,
                            child: IgnorePointer(
                              child: CustomPaint(
                                painter: _SpineStitchPainter(album.bindingType),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SpineStitchPainter extends CustomPainter {
  const _SpineStitchPainter(this.binding);

  final AlbumBindingType binding;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x66FFFFFF)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    for (double y = 10; y < size.height - 10; y += 14) {
      canvas.drawLine(Offset(0, y), Offset(0, y + 6), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _SpineStitchPainter oldDelegate) =>
      oldDelegate.binding != binding;
}
