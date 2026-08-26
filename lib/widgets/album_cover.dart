import 'package:flutter/material.dart';

import '../models/album_models.dart';

class AlbumCover extends StatelessWidget {
  const AlbumCover({super.key, required this.album, this.compact = false});

  final AlbumModel album;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final theme = themeById(album.themeId);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [theme.coverStart, theme.coverEnd],
        ),
        borderRadius: BorderRadius.circular(compact ? 12 : 7),
        boxShadow: [
          BoxShadow(
            color: theme.coverEnd.withValues(alpha: 0.45),
            blurRadius: 22,
            offset: const Offset(7, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _CoverPatternPainter(
                Colors.white.withValues(alpha: 0.055),
              ),
            ),
          ),
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: compact ? 10 : 18,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.2),
                borderRadius: BorderRadius.horizontal(
                  left: Radius.circular(compact ? 12 : 7),
                ),
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: EdgeInsets.all(compact ? 14 : 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    theme.emoji,
                    style: TextStyle(fontSize: compact ? 21 : 36),
                  ),
                  SizedBox(height: compact ? 8 : 18),
                  Text(
                    album.title.trim().isEmpty ? 'İsimsiz Albüm' : album.title,
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: compact ? 15 : 28,
                      height: 1.05,
                      fontWeight: FontWeight.w800,
                      letterSpacing: compact ? -0.2 : -0.8,
                    ),
                  ),
                  if (!compact) ...[
                    const SizedBox(height: 14),
                    Container(width: 42, height: 1, color: Colors.white54),
                    const SizedBox(height: 10),
                    Text(
                      theme.name.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 9,
                        letterSpacing: 2.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CoverPatternPainter extends CustomPainter {
  const _CoverPatternPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.7;
    for (double x = -size.height; x < size.width; x += 13) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CoverPatternPainter oldDelegate) =>
      oldDelegate.color != color;
}
