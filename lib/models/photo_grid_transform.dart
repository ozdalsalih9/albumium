import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'album_models.dart';

Offset _rotate(Offset p, double a) => Offset(
  p.dx * math.cos(a) - p.dy * math.sin(a),
  p.dx * math.sin(a) + p.dy * math.cos(a),
);
Offset _center(AlbumElementModel e, Size page) => Offset(
  (e.x + e.width / 2) * page.width,
  (e.y + e.height / 2) * page.height,
);

AlbumElementModel photoGridFrame(List<AlbumElementModel> members, Size page) {
  final angle = members.first.rotation;
  Rect? bounds;
  for (final cell in members) {
    final center = _rotate(_center(cell, page), -angle);
    final rect = Rect.fromCenter(
      center: center,
      width: cell.width * page.width * cell.scale,
      height: cell.height * page.height * cell.scale,
    );
    bounds = bounds == null ? rect : bounds.expandToInclude(rect);
  }
  final box = bounds!;
  final center = _rotate(box.center, angle);
  return AlbumElementModel.fromJson({
    ...members.first.toJson(),
    'x': (center.dx - box.width / 2) / page.width,
    'y': (center.dy - box.height / 2) / page.height,
    'width': box.width / page.width,
    'height': box.height / page.height,
    'scale': 1.0,
    'rotation': angle,
  });
}

/// A gesture always starts from one snapshot, so every cell follows the same
/// transform without changing the spacing or accumulating rounding drift.
class PhotoGridTransform {
  PhotoGridTransform(this.members, this.page)
    : frame = photoGridFrame(members, page),
      _cells = members
          .map((e) => AlbumElementModel.fromJson(e.toJson()))
          .toList() {
    _origin = AlbumElementModel.fromJson(frame.toJson());
  }
  final List<AlbumElementModel> members;
  final Size page;
  final AlbumElementModel frame;
  final List<AlbumElementModel> _cells;
  late final AlbumElementModel _origin;

  void apply(AlbumElementModel target) {
    final before = _center(_origin, page), after = _center(target, page);
    final ratio = target.scale / _origin.scale;
    final angle = target.rotation - _origin.rotation;
    for (var i = 0; i < members.length; i++) {
      final cell = _cells[i];
      final center =
          after + _rotate((_center(cell, page) - before) * ratio, angle);
      members[i]
        ..x = center.dx / page.width - cell.width / 2
        ..y = center.dy / page.height - cell.height / 2
        ..scale = cell.scale * ratio
        ..rotation = cell.rotation + angle;
    }
  }

  void followCellChange(AlbumElementModel before, AlbumElementModel after) {
    frame
      ..x += after.x - before.x
      ..y += after.y - before.y
      ..scale *= after.scale / before.scale
      ..rotation += after.rotation - before.rotation;
    apply(frame);
  }
}
