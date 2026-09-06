import 'package:flutter/material.dart';

import '../l10n/albumium_localizations.dart';
import '../services/language_controller.dart';
import '../widgets/privacy_policy_button.dart';

/// A local introduction, not a permission or consent dialog.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    required this.onComplete,
    required this.languageController,
  });

  final Future<void> Function() onComplete;
  final LanguageController languageController;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;
  bool _saving = false;

  static const _steps = [
    (
      Icons.auto_stories_rounded,
      'Anıların için yeni bir sayfa',
      'Bir kapak seç, albümünü oluştur. Fotoğraflarını sana özel bir hikâyede bir araya getir.',
    ),
    (
      Icons.draw_rounded,
      'Her sayfada senin dokunuşun',
      'Fotoğraflarını kırp ve döndür; yazılar, çizimler ve süslemelerle albümünü kişiselleştir.',
    ),
    (
      Icons.celebration_rounded,
      'Güzel anları birlikte yaşa',
      'Özel gün kartları tasarla. Albümlerini video veya Albumium dosyası olarak sevdiklerinle paylaş.',
    ),
    (
      Icons.photo_library_outlined,
      'Fotoğrafların, senin seçimin',
      'Fotoğraf eklediğinde sistem seçicisi açılır. Yalnızca seçtiğin fotoğraflar kullanılır; tüm galerine erişim gerekmez. Tasarımların cihazında saklanır.',
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_saving) return;
    if (_index < _steps.length - 1) {
      await _controller.nextPage(
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await widget.onComplete();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.tr('Kaydedilemedi. Lütfen tekrar dene.')),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _index > 0 && !_saving) {
          _controller.previousPage(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      },
      child: Scaffold(
        body: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colors.surface,
                colors.primaryContainer.withValues(alpha: .5),
              ],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Image.asset(
                        'assets/branding/albumium_brand_mark.png',
                        width: 36,
                        height: 42,
                      ),
                      const SizedBox(width: 6),
                      const Expanded(
                        child: Text(
                          'lbumium',
                          style: TextStyle(
                            fontFamily: 'AlbumiumDisplay',
                            fontSize: 26,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _saving
                            ? null
                            : () => widget.languageController.setLanguage(
                                widget.languageController.language ==
                                        AppLanguage.turkish
                                    ? AppLanguage.english
                                    : AppLanguage.turkish,
                              ),
                        child: Text(
                          widget.languageController.language ==
                                  AppLanguage.turkish
                              ? 'English'
                              : 'Türkçe',
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: _steps.length,
                    onPageChanged: (value) => setState(() => _index = value),
                    itemBuilder: (context, index) {
                      final step = _steps[index];
                      return LayoutBuilder(
                        builder: (context, constraints) {
                          return SingleChildScrollView(
                            padding: const EdgeInsets.all(28),
                            child: ConstrainedBox(
                              constraints: BoxConstraints(
                                minHeight: (constraints.maxHeight - 56).clamp(
                                  0,
                                  double.infinity,
                                ),
                              ),
                              child: Center(
                                child: ConstrainedBox(
                                  constraints: const BoxConstraints(
                                    maxWidth: 620,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(30),
                                        decoration: BoxDecoration(
                                          color: colors.primaryContainer,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          step.$1,
                                          size: constraints.maxHeight < 400
                                              ? 52
                                              : 88,
                                          color: colors.onPrimaryContainer,
                                        ),
                                      ),
                                      const SizedBox(height: 32),
                                      Text(
                                        context.tr(step.$2),
                                        textAlign: TextAlign.center,
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineMedium
                                            ?.copyWith(
                                              fontFamily: 'AlbumiumDisplay',
                                            ),
                                      ),
                                      const SizedBox(height: 18),
                                      Text(
                                        context.tr(step.$3),
                                        textAlign: TextAlign.center,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyLarge
                                            ?.copyWith(height: 1.6),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 620),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Semantics(
                            label: '${_index + 1} / ${_steps.length}',
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                _steps.length,
                                (i) => Container(
                                  margin: const EdgeInsets.all(4),
                                  height: 7,
                                  width: i == _index ? 28 : 7,
                                  decoration: BoxDecoration(
                                    color: i == _index
                                        ? colors.primary
                                        : colors.outlineVariant,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (_index == 3) const PrivacyPolicyButton(),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              if (_index > 0)
                                TextButton(
                                  onPressed: _saving
                                      ? null
                                      : () => _controller.previousPage(
                                          duration: const Duration(
                                            milliseconds: 200,
                                          ),
                                          curve: Curves.easeOut,
                                        ),
                                  child: Text(context.tr('Geri')),
                                ),
                              const Spacer(),
                              FilledButton.icon(
                                key: const ValueKey('onboarding-next'),
                                onPressed: _saving ? null : _next,
                                icon: Icon(
                                  _index == 3
                                      ? Icons.check_rounded
                                      : Icons.arrow_forward_rounded,
                                ),
                                label: Text(
                                  context.tr(_index == 3 ? 'Tamam' : 'İleri'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
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
