import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OccasionCardTemplate {
  const OccasionCardTemplate({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.emoji,
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
    required this.icon,
  });

  final String id;
  final String title;
  final String subtitle;
  final String badge;
  final String emoji;
  final Color primaryColor;
  final Color secondaryColor;
  final Color accentColor;
  final IconData icon;
}

class OccasionCardCustomData {
  const OccasionCardCustomData({
    required this.title,
    required this.subtitle,
    required this.badge,
  });

  final String title;
  final String subtitle;
  final String badge;

  String encode() =>
      jsonEncode({'title': title, 'subtitle': subtitle, 'badge': badge});

  static OccasionCardCustomData decode(
    String raw,
    OccasionCardTemplate fallback,
  ) {
    if (raw.trim().isEmpty) {
      return OccasionCardCustomData(
        title: fallback.title,
        subtitle: fallback.subtitle,
        badge: fallback.badge,
      );
    }
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      return OccasionCardCustomData(
        title: map['title'] as String? ?? fallback.title,
        subtitle: map['subtitle'] as String? ?? fallback.subtitle,
        badge: map['badge'] as String? ?? fallback.badge,
      );
    } catch (_) {
      return OccasionCardCustomData(
        title: raw.isNotEmpty ? raw : fallback.title,
        subtitle: fallback.subtitle,
        badge: fallback.badge,
      );
    }
  }
}

const occasionCardTemplates = <OccasionCardTemplate>[
  OccasionCardTemplate(
    id: 'birthday',
    title: 'İyi ki Doğdun!',
    subtitle: 'Nice sağlıklı, mutlu ve neşeli yaşlara.',
    badge: 'DOĞUM GÜNÜ',
    emoji: '🎂',
    primaryColor: Color(0xFFFFF3E0),
    secondaryColor: Color(0xFFFFB74D),
    accentColor: Color(0xFFE65100),
    icon: Icons.cake_rounded,
  ),
  OccasionCardTemplate(
    id: 'anniversary',
    title: 'Bizim Masalımız',
    subtitle: 'İlk günkü heyecanla, sonsuza dek.',
    badge: 'YILDÖNÜMÜ',
    emoji: '❤️',
    primaryColor: Color(0xFFFCE4EC),
    secondaryColor: Color(0xFFF48FB1),
    accentColor: Color(0xFFAD1457),
    icon: Icons.favorite_rounded,
  ),
  OccasionCardTemplate(
    id: 'baby',
    title: 'İlk Adım',
    subtitle: 'Dünyaya hoş geldin minik mucizemiz.',
    badge: 'MİLESTONE',
    emoji: '👣',
    primaryColor: Color(0xFFE8F5E9),
    secondaryColor: Color(0xFFA5D6A7),
    accentColor: Color(0xFF2E7D32),
    icon: Icons.child_care_rounded,
  ),
  OccasionCardTemplate(
    id: 'wedding',
    title: 'Evet Dedik!',
    subtitle: 'Birlikte geçecek bir ömrün ilk günü.',
    badge: 'EN ÖZEL GÜN',
    emoji: '💍',
    primaryColor: Color(0xFFFAF6EE),
    secondaryColor: Color(0xFFD4AF37),
    accentColor: Color(0xFF8C6D1F),
    icon: Icons.diamond_rounded,
  ),
  OccasionCardTemplate(
    id: 'travel',
    title: 'Yolculuk Günlüğü',
    subtitle: 'Yeni rotalar, yeni manzaralar, unutulmaz anlar.',
    badge: 'KEŞİF & ROTA',
    emoji: '✈️',
    primaryColor: Color(0xFFE3F2FD),
    secondaryColor: Color(0xFF90CAF9),
    accentColor: Color(0xFF1565C0),
    icon: Icons.explore_rounded,
  ),
  OccasionCardTemplate(
    id: 'graduation',
    title: 'Mezuniyet Zamanı!',
    subtitle: 'Emeklerin meyvesi, geleceğe doğru ilk adım.',
    badge: 'BAŞARI',
    emoji: '🎓',
    primaryColor: Color(0xFFEDE7F6),
    secondaryColor: Color(0xFFB39DDB),
    accentColor: Color(0xFF4527A0),
    icon: Icons.school_rounded,
  ),
  OccasionCardTemplate(
    id: 'friendship',
    title: 'Dostlar Meclisi',
    subtitle: 'Kahkahası bol, anısı derin güzel günlerden.',
    badge: 'EN İYİ DOSTLAR',
    emoji: '🎉',
    primaryColor: Color(0xFFF3E5F5),
    secondaryColor: Color(0xFFCE93D8),
    accentColor: Color(0xFF6A1B9A),
    icon: Icons.celebration_rounded,
  ),
  OccasionCardTemplate(
    id: 'holiday',
    title: 'Yeni Yıl Dilekleri',
    subtitle: 'Sevgi, huzur ve yepyeni başlangıçlar dolu olsun.',
    badge: 'MUTLU YILLAR',
    emoji: '✨',
    primaryColor: Color(0xFFFFF8E1),
    secondaryColor: Color(0xFFFFD54F),
    accentColor: Color(0xFFF57F17),
    icon: Icons.auto_awesome_rounded,
  ),
];

OccasionCardTemplate occasionTemplateById(String id) => occasionCardTemplates
    .firstWhere((t) => t.id == id, orElse: () => occasionCardTemplates.first);

class OccasionCardView extends StatelessWidget {
  const OccasionCardView({
    super.key,
    required this.cardId,
    this.customDataRaw = '',
    this.customTitle,
    this.customSubtitle,
  });

  final String cardId;
  final String customDataRaw;
  final String? customTitle;
  final String? customSubtitle;

  @override
  Widget build(BuildContext context) {
    final t = occasionTemplateById(cardId);
    final data = OccasionCardCustomData.decode(customDataRaw, t);

    final title = customTitle ?? data.title;
    final subtitle = customSubtitle ?? data.subtitle;
    final badge = data.badge;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: t.primaryColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: t.secondaryColor, width: 1.5),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Köşe altın süsleri
          Positioned(
            top: -2,
            left: -2,
            child: Icon(Icons.circle, size: 6, color: t.accentColor),
          ),
          Positioned(
            top: -2,
            right: -2,
            child: Icon(Icons.circle, size: 6, color: t.accentColor),
          ),
          Positioned(
            bottom: -2,
            left: -2,
            child: Icon(Icons.circle, size: 6, color: t.accentColor),
          ),
          Positioned(
            bottom: -2,
            right: -2,
            child: Icon(Icons.circle, size: 6, color: t.accentColor),
          ),
          Positioned.fill(
            child: LayoutBuilder(
              builder: (context, constraints) => Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: SizedBox(
                    width: constraints.maxWidth,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Rozet
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: t.accentColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(
                              color: t.accentColor.withValues(alpha: 0.3),
                              width: 0.8,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                t.emoji,
                                style: const TextStyle(fontSize: 12),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                badge,
                                style: GoogleFonts.inter(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  color: t.accentColor,
                                  letterSpacing: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.cormorantGaramond(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF2C2520),
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.quicksand(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF6B5F54),
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Dialog to edit occasion card title, message/subtitle, and badge
class EditOccasionCardDialog extends StatefulWidget {
  const EditOccasionCardDialog({
    super.key,
    required this.cardId,
    this.initialDataRaw = '',
  });

  final String cardId;
  final String initialDataRaw;

  @override
  State<EditOccasionCardDialog> createState() => _EditOccasionCardDialogState();
}

class _EditOccasionCardDialogState extends State<EditOccasionCardDialog> {
  late OccasionCardTemplate _template;
  late TextEditingController _titleController;
  late TextEditingController _subtitleController;
  late TextEditingController _badgeController;

  @override
  void initState() {
    super.initState();
    _template = occasionTemplateById(widget.cardId);
    final data = OccasionCardCustomData.decode(
      widget.initialDataRaw,
      _template,
    );
    _titleController = TextEditingController(text: data.title);
    _subtitleController = TextEditingController(text: data.subtitle);
    _badgeController = TextEditingController(text: data.badge);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _subtitleController.dispose();
    _badgeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF1E1A18),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.card_membership_rounded,
                      color: Color(0xFFFFA95C),
                      size: 24,
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'Kart Metnini Düzenle',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Live preview
                OccasionCardView(
                  cardId: widget.cardId,
                  customTitle: _titleController.text.trim().isEmpty
                      ? _template.title
                      : _titleController.text.trim(),
                  customSubtitle: _subtitleController.text.trim().isEmpty
                      ? _template.subtitle
                      : _subtitleController.text.trim(),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _titleController,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Kart Başlığı',
                    hintText: 'Örn. İyi ki Doğdun Canım!',
                    prefixIcon: Icon(Icons.title_rounded),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _subtitleController,
                  maxLines: 2,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Alt Mesaj / Not',
                    hintText: 'Örn. Birlikte nice güzel yaşlara...',
                    prefixIcon: Icon(Icons.notes_rounded),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _badgeController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Rozet Etiketi',
                    hintText: 'Örn. 25. YAŞ GÜNÜ',
                    prefixIcon: Icon(Icons.label_outline_rounded),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: () {
                      final customData = OccasionCardCustomData(
                        title: _titleController.text.trim().isEmpty
                            ? _template.title
                            : _titleController.text.trim(),
                        subtitle: _subtitleController.text.trim().isEmpty
                            ? _template.subtitle
                            : _subtitleController.text.trim(),
                        badge: _badgeController.text.trim().isEmpty
                            ? _template.badge
                            : _badgeController.text.trim(),
                      );
                      Navigator.pop(context, customData);
                    },
                    icon: const Icon(Icons.check_rounded, size: 18),
                    label: const Text('Kaydet ve Ekle'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class OccasionCardPickerResult {
  const OccasionCardPickerResult({
    required this.template,
    required this.customData,
  });

  final OccasionCardTemplate template;
  final OccasionCardCustomData customData;
}

class OccasionCardPickerSheet extends StatelessWidget {
  const OccasionCardPickerSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.card_membership_rounded,
                  color: Color(0xFFFFA95C),
                  size: 24,
                ),
                const SizedBox(width: 10),
                const Text(
                  'Özel Gün Kartı Ekle',
                  style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Bir kart seçip üzerindeki yazıları anında özelleştirebilirsin.',
              style: TextStyle(color: Color(0xFF9B8F84), fontSize: 13),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 380,
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 1.4,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: occasionCardTemplates.length,
                itemBuilder: (context, index) {
                  final card = occasionCardTemplates[index];
                  return InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () async {
                      // Open customization dialog
                      final customData =
                          await showDialog<OccasionCardCustomData>(
                            context: context,
                            builder: (_) =>
                                EditOccasionCardDialog(cardId: card.id),
                          );
                      if (customData != null && context.mounted) {
                        Navigator.pop(
                          context,
                          OccasionCardPickerResult(
                            template: card,
                            customData: customData,
                          ),
                        );
                      }
                    },
                    child: OccasionCardView(cardId: card.id),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
