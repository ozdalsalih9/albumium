import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../l10n/albumium_localizations.dart';
import '../models/album_models.dart';
import '../models/social_video_draft.dart';
import 'album_cover.dart';
import 'album_page_canvas.dart';

({Color paper, Color ink, Color desk}) socialVideoPalette(
  SocialVideoTemplate template,
) => switch (template) {
  SocialVideoTemplate.summer => (
    paper: const Color(0xFFF7EFDF),
    ink: const Color(0xFF76523D),
    desk: const Color(0xFFE8D6BA),
  ),
  SocialVideoTemplate.together => (
    paper: const Color(0xFFF6ECE8),
    ink: const Color(0xFF854F58),
    desk: const Color(0xFFE1C5BD),
  ),
  SocialVideoTemplate.year => (
    paper: const Color(0xFF242E33),
    ink: const Color(0xFFF0DFC0),
    desk: const Color(0xFF101A20),
  ),
  SocialVideoTemplate.editorial => (
    paper: const Color(0xFFF5F3ED),
    ink: const Color(0xFF222F3B),
    desk: const Color(0xFFD9D9D2),
  ),
  SocialVideoTemplate.botanical => (
    paper: const Color(0xFFEDF0E5),
    ink: const Color(0xFF405544),
    desk: const Color(0xFFC7D2BC),
  ),
};

/// Deterministic composition: scrubbing, preview and exported frames share
/// the same perspective, paper back, lighting and page-turn timing.
class SocialVideoFrame extends StatelessWidget {
  const SocialVideoFrame({
    super.key,
    required this.album,
    required this.draft,
    required this.frame,
  });
  final AlbumModel album;
  final SocialVideoDraft draft;
  final int frame;

  Widget _leaf(String? id) => id == null
      ? AlbumCover(album: album, showTitle: false)
      : AlbumPageCanvas(
          page: draft.pageById(id),
          theme: themeById(album.themeId),
          showPageNumber: false,
        );

  @override
  Widget build(BuildContext context) {
    final palette = socialVideoPalette(draft.template);
    if (!draft.canExport) {
      return ColoredBox(
        color: palette.paper,
        child: Center(
          child: Icon(
            Icons.auto_stories_outlined,
            color: palette.ink,
            size: 48,
          ),
        ),
      );
    }
    final shot = draft.shotAt(frame);
    final ending = shot.index > draft.pageIds.length;
    final localFrame = (frame - shot.start).clamp(0, shot.frames - 1);
    final turn = Curves.easeInOutCubic.transform(
      (localFrame / SocialVideoDraft.turnFrames).clamp(0.0, 1.0),
    );
    final turning = shot.index > 0 && turn < 1;
    final previousId = shot.index == 1
        ? draft.coverPageId
        : draft.pageIds[(shot.index - 2).clamp(0, draft.pageIds.length - 1)];
    final currentId = ending || shot.index == 0
        ? draft.coverPageId
        : shot.pageId;
    // Positive Y rotation lifts the right edge toward the viewer with the
    // perspective below. Closing follows the same outward arc in reverse.
    final angle = ending ? math.pi * (1 - turn) : math.pi * turn;
    final title = ending
        ? (draft.closingNote.trim().isEmpty
              ? context.tr('Biriktirdiğimiz güzel anlar.')
              : draft.closingNote.trim())
        : album.title;
    final global = frame.clamp(0, draft.totalFrames - 1) / draft.totalFrames;
    final book = Stack(
      clipBehavior: Clip.none,
      children: [
        for (var i = 4; i >= 1; i--)
          Positioned.fill(
            left: i * 1.8,
            right: -i * 1.8,
            top: i * 1.5,
            bottom: -i * 1.5,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: Color.lerp(
                  const Color(0xFFD1C5AE),
                  const Color(0xFFFFFCF5),
                  i / 5,
                ),
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: const Color(0xFFAC9D87), width: .4),
                boxShadow: i == 4
                    ? const [
                        BoxShadow(
                          color: Color(0x45000000),
                          blurRadius: 28,
                          offset: Offset(5, 18),
                        ),
                      ]
                    : [],
              ),
            ),
          ),
        Positioned.fill(
          child: _leaf(ending && turning ? previousId : currentId),
        ),
        // The receiving page darkens beneath the lifted sheet.
        if (turning)
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(
                      alpha: .28 * math.sin(turn * math.pi),
                    ),
                    Colors.transparent,
                  ],
                  stops: const [0, .85],
                ),
              ),
            ),
          ),
        if (turning)
          Positioned.fill(
            child: Transform(
              key: const ValueKey('social-turning-leaf'),
              alignment: Alignment.centerLeft,
              transform: Matrix4.identity()
                ..setEntry(3, 2, .0015)
                ..rotateY(angle),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (angle.abs() <= math.pi / 2)
                    _leaf(ending ? currentId : previousId)
                  else
                    const ColoredBox(
                      color: Color(0xFFF1E7D3),
                      child: CustomPaint(painter: _PaperBackPainter()),
                    ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.black.withValues(alpha: .08),
                          Colors.white.withValues(
                            alpha: .35 * math.sin(turn * math.pi),
                          ),
                          Colors.black.withValues(
                            alpha: .24 * math.sin(turn * math.pi),
                          ),
                        ],
                        stops: const [0, .65, 1],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        Positioned(
          left: 0,
          top: 0,
          bottom: 0,
          width: 14,
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withValues(alpha: .16),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
    return MediaQuery.withNoTextScaling(
      child: ClipRect(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [palette.paper, palette.desk],
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _DeskLightPainter(palette.ink, draft.template),
                ),
              ),
              Positioned(
                left: 30,
                right: 30,
                top: 54,
                child: Row(
                  children: [
                    Icon(
                      Icons.auto_stories_outlined,
                      size: 14,
                      color: palette.ink,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'ALBUMIUM',
                      style: TextStyle(
                        fontFamily: 'AlbumiumSans',
                        fontSize: 10,
                        letterSpacing: 3,
                        color: palette.ink,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      ending
                          ? context.tr('SON')
                          : '${shot.index.clamp(0, draft.pageIds.length).toString().padLeft(2, '0')} / ${draft.pageIds.length.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        fontFamily: 'AlbumiumSans',
                        fontSize: 10,
                        color: palette.ink,
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 30,
                right: 30,
                top: 86,
                height: 66,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    width: 300,
                    child: Text(
                      title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'AlbumiumDisplay',
                        fontSize: ending ? 24 : 27,
                        height: 1.16,
                        color: palette.ink,
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 42,
                top: 172,
                width: 270,
                height: 378,
                child: Transform.rotate(
                  angle: draft.template == SocialVideoTemplate.editorial
                      ? 0
                      : -.018 + math.sin(global * math.pi * 2) * .009,
                  child: Transform.scale(
                    scale: .985 + math.sin(global * math.pi) * .015,
                    child: book,
                  ),
                ),
              ),
              Positioned(
                left: 36,
                right: 36,
                bottom: 47,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            ending
                                ? context.tr('Hikâyemiz burada saklı.')
                                : context.tr(draft.template.title),
                            style: TextStyle(
                              fontFamily: 'AlbumiumSans',
                              fontSize: 10,
                              letterSpacing: .8,
                              color: palette.ink,
                            ),
                          ),
                        ),
                        Icon(
                          Icons.favorite_border_rounded,
                          size: 13,
                          color: palette.ink,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: global,
                      minHeight: 1.5,
                      color: palette.ink,
                      backgroundColor: palette.ink.withValues(alpha: .14),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PaperBackPainter extends CustomPainter {
  const _PaperBackPainter();
  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(14);
    final paint = Paint()..color = const Color(0x129F8261);
    for (var i = 0; i < 450; i++) {
      canvas.drawCircle(
        Offset(
          random.nextDouble() * size.width,
          random.nextDouble() * size.height,
        ),
        .55,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _PaperBackPainter oldDelegate) => false;
}

class _DeskLightPainter extends CustomPainter {
  const _DeskLightPainter(this.ink, this.template);
  final Color ink;
  final SocialVideoTemplate template;
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = ink.withValues(alpha: .035);
    canvas.save();
    canvas.translate(size.width * .8, -40);
    canvas.rotate(.45);
    for (var i = 0; i < 4; i++) {
      canvas.drawRect(Rect.fromLTWH(i * 65, 0, 20, size.height * 1.4), paint);
    }
    canvas.restore();
    if (template == SocialVideoTemplate.botanical) {
      final stem = Paint()
        ..color = ink.withValues(alpha: .12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      canvas.drawPath(
        Path()
          ..moveTo(340, 530)
          ..quadraticBezierTo(305, 320, 370, 225),
        stem,
      );
      for (var i = 0; i < 6; i++) {
        canvas.save();
        canvas.translate(340, 290 + i * 32);
        canvas.rotate(i.isEven ? -.7 : .7);
        canvas.drawOval(
          const Rect.fromLTWH(-8, -28, 18, 43),
          Paint()..color = ink.withValues(alpha: .07),
        );
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DeskLightPainter oldDelegate) =>
      ink != oldDelegate.ink || template != oldDelegate.template;
}
