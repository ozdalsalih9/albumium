import 'package:flutter/material.dart';
import 'font_selector_dialog.dart';
import '../l10n/albumium_localizations.dart';
import 'card_artwork.dart';
import 'occasion_cards.dart';

class CardTemplateThumbnail extends StatelessWidget {
  const CardTemplateThumbnail({super.key, required this.template});
  final OccasionCardTemplate template;
  @override
  Widget build(BuildContext context) => template.layout == 'scrapbook'
      ? AspectRatio(
          aspectRatio: 5 / 7,
          child: Image.asset(
            'assets/scrapbook/template_${template.id.substring(10)}.webp',
            fit: BoxFit.contain,
            cacheWidth: 240,
          ),
        )
      : AspectRatio(
          aspectRatio: 5 / 7,
          child: FittedBox(
            child: SizedBox(
              width: 150,
              height: 210,
              child: ColoredBox(
                color: template.primaryColor,
                child: CustomPaint(
                  painter: CardArtwork(template),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      18,
                      ['photo', 'gallery'].contains(template.layout) ? 134 : 68,
                      18,
                      18,
                    ),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Text(
                        context.tr(template.title),
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        style: getFontTextStyle(
                          template.fontFamily,
                          fontSize: 16,
                          color: template.accentColor,
                        ).copyWith(height: 1.1),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
}
