import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/album_models.dart';

Path photoSlotPath(AlbumPhotoShape shape, Size size) {
  final w = size.width, h = size.height;
  switch (shape) {
    case AlbumPhotoShape.circle:
      return Path()..addOval(Offset.zero & size);
    case AlbumPhotoShape.heart:
      return Path()
        ..moveTo(w * .5, h * .94)
        ..cubicTo(w * .38, h * .82, 0, h * .53, 0, h * .27)
        ..cubicTo(0, -h * .02, w * .35, -h * .06, w * .5, h * .19)
        ..cubicTo(w * .65, -h * .06, w, -h * .02, w, h * .27)
        ..cubicTo(w, h * .53, w * .62, h * .82, w * .5, h * .94)
        ..close();
    case AlbumPhotoShape.diamond:
      return Path()
        ..moveTo(w / 2, 0)
        ..lineTo(w, h / 2)
        ..lineTo(w / 2, h)
        ..lineTo(0, h / 2)
        ..close();
    case AlbumPhotoShape.hexagon:
      return Path()
        ..moveTo(w * .25, 0)
        ..lineTo(w * .75, 0)
        ..lineTo(w, h / 2)
        ..lineTo(w * .75, h)
        ..lineTo(w * .25, h)
        ..lineTo(0, h / 2)
        ..close();
    case AlbumPhotoShape.arch:
      final r = math.min(w / 2, h);
      return Path()
        ..moveTo(0, r)
        ..arcToPoint(Offset(w, r), radius: Radius.elliptical(w / 2, r))
        ..lineTo(w, h)
        ..lineTo(0, h)
        ..close();
    case AlbumPhotoShape.torn:
      final p = Path()..moveTo(0, 3);
      for (var i = 1; i <= 20; i++) {
        p.lineTo(w * i / 20, i.isEven ? 0 : 4);
      }
      p.lineTo(w, h - 3);
      for (var i = 19; i >= 0; i--) {
        p.lineTo(w * i / 20, h - (i.isEven ? 0 : 4));
      }
      return p..close();
    default:
      return Path()..addRRect(
        RRect.fromRectAndRadius(
          Offset.zero & size,
          Radius.circular(
            shape == AlbumPhotoShape.rounded ? size.shortestSide * .16 : 2,
          ),
        ),
      );
  }
}

class PhotoSlotClipper extends CustomClipper<Path> {
  const PhotoSlotClipper(this.shape);
  final AlbumPhotoShape shape;
  @override
  Path getClip(Size size) => photoSlotPath(shape, size);
  @override
  bool shouldReclip(PhotoSlotClipper oldClipper) => shape != oldClipper.shape;
}

class PhotoSlotOutline extends CustomPainter {
  const PhotoSlotOutline(this.shape, this.color);
  final AlbumPhotoShape shape;
  final Color color;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawPath(
      photoSlotPath(shape, size),
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
  }

  @override
  bool shouldRepaint(PhotoSlotOutline oldDelegate) =>
      shape != oldDelegate.shape || color != oldDelegate.color;
}

/// Uses page pixels so rotated and scaled slots have the same hit region as
/// their visible silhouette, including inside a transformed book spread.
bool photoSlotContains(AlbumElementModel slot, Offset point, Size page) {
  final center = Offset(
    (slot.x + slot.width / 2) * page.width,
    (slot.y + slot.height / 2) * page.height,
  );
  final d = (point - center) / slot.scale;
  final cosine = math.cos(slot.rotation), sine = math.sin(slot.rotation);
  final size = Size(slot.width * page.width, slot.height * page.height);
  final local =
      Offset(d.dx * cosine + d.dy * sine, -d.dx * sine + d.dy * cosine) +
      Offset(size.width / 2, size.height / 2);
  return photoSlotPath(slot.photoShape, size).contains(local);
}

class PhotoSlotArtwork extends CustomPainter {
  const PhotoSlotArtwork({this.highlight = false});
  final bool highlight;
  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Offset.zero & size,
      Paint()..color = const Color(0xFFECE4D7),
    );
    canvas.drawCircle(
      Offset(size.width * .73, size.height * .23),
      size.shortestSide * .11,
      Paint()..color = const Color(0xFFD1B07E),
    );
    canvas.drawPath(
      Path()
        ..moveTo(0, size.height * .78)
        ..cubicTo(
          size.width * .24,
          size.height * .43,
          size.width * .56,
          size.height * .96,
          size.width,
          size.height * .56,
        )
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close(),
      Paint()..color = const Color(0xFFAEBBA8),
    );
    canvas.drawPath(
      Path()
        ..moveTo(0, size.height * .89)
        ..quadraticBezierTo(
          size.width * .55,
          size.height * .60,
          size.width,
          size.height * .85,
        )
        ..lineTo(size.width, size.height)
        ..lineTo(0, size.height)
        ..close(),
      Paint()..color = const Color(0xFF748A7A),
    );
  }

  @override
  bool shouldRepaint(PhotoSlotArtwork oldDelegate) => false;
}
