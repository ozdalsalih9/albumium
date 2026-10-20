import 'package:flutter/material.dart';
import '../l10n/albumium_localizations.dart';
import '../models/scrapbook_templates.dart';

Future<ScrapbookTemplate?> showScrapbookTemplatePicker(
  BuildContext context,
) => showModalBottomSheet<ScrapbookTemplate>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  useSafeArea: true,
  builder: (context) => SizedBox(
    height: MediaQuery.sizeOf(context).height * .82,
    child: Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Column(
            children: [
              Text(
                context.tr('Kolaj şablonları'),
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 6),
              Text(
                context.tr(
                  'Yeni bir sayfa eklenir. Fotoğraflar, yazılar ve süsler ayrı ayrı düzenlenebilir.',
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(18),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: MediaQuery.sizeOf(context).width > 600 ? 4 : 2,
              childAspectRatio: .61,
              crossAxisSpacing: 12,
              mainAxisSpacing: 16,
            ),
            itemCount: scrapbookTemplates.length,
            itemBuilder: (context, index) {
              final t = scrapbookTemplates[index];
              return InkWell(
                key: ValueKey('scrapbook-template-${t.id}'),
                onTap: () => Navigator.pop(context, t),
                borderRadius: BorderRadius.circular(14),
                child: Column(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.asset(
                          'assets/scrapbook/template_${t.id}.png',
                          fit: BoxFit.contain,
                          cacheWidth: 240,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      context.tr(t.title),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    ),
  ),
);
