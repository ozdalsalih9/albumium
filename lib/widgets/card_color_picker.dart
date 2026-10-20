import 'package:flutter/material.dart';
import '../l10n/albumium_localizations.dart';

class CardColorPicker extends StatefulWidget {
  const CardColorPicker({super.key, required this.initialColor});
  final Color initialColor;
  @override
  State<CardColorPicker> createState() => _CardColorPickerState();
}

class _CardColorPickerState extends State<CardColorPicker> {
  late HSVColor _hsv = HSVColor.fromColor(widget.initialColor);
  late final _hex = TextEditingController(text: _hexValue);
  String? _error;
  String get _hexValue =>
      _hsv.toColor().toARGB32().toRadixString(16).substring(2).toUpperCase();
  void _update(HSVColor color) => setState(() {
    _hsv = color;
    _hex.text = _hexValue;
    _error = null;
  });
  @override
  void dispose() {
    _hex.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(context.tr('Kendi rengini seç')),
    content: SizedBox(
      width: 320,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 170,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  void pick(Offset position) => _update(
                    _hsv
                        .withSaturation(
                          (position.dx / constraints.maxWidth).clamp(0.0, 1.0),
                        )
                        .withValue((1 - position.dy / 170).clamp(0.0, 1.0)),
                  );
                  return GestureDetector(
                    onPanDown: (d) => pick(d.localPosition),
                    onPanUpdate: (d) => pick(d.localPosition),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  Colors.white,
                                  HSVColor.fromAHSV(
                                    1,
                                    _hsv.hue,
                                    1,
                                    1,
                                  ).toColor(),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const Positioned.fill(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [Colors.transparent, Colors.black],
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: (_hsv.saturation * constraints.maxWidth - 9)
                              .clamp(0.0, constraints.maxWidth - 18),
                          top: ((1 - _hsv.value) * 170 - 9).clamp(0.0, 152.0),
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              boxShadow: const [
                                BoxShadow(color: Colors.black38, blurRadius: 2),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            Slider(
              value: _hsv.hue,
              max: 360,
              label: context.tr('Renk tonu'),
              onChanged: (v) => _update(_hsv.withHue(v)),
            ),
            Slider(
              value: _hsv.saturation,
              label: context.tr('Doygunluk'),
              onChanged: (v) => _update(_hsv.withSaturation(v)),
            ),
            Slider(
              value: _hsv.value,
              label: context.tr('Parlaklık'),
              onChanged: (v) => _update(_hsv.withValue(v)),
            ),
            const SizedBox(height: 8),
            TextField(
              key: const ValueKey('card-color-hex'),
              controller: _hex,
              maxLength: 6,
              decoration: InputDecoration(
                prefixText: '#',
                labelText: context.tr('Renk kodu'),
                errorText: _error,
                suffixIcon: Padding(
                  padding: const EdgeInsets.all(10),
                  child: CircleAvatar(
                    backgroundColor: _hsv.toColor(),
                    radius: 12,
                  ),
                ),
              ),
              onChanged: (text) {
                if (RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(text)) {
                  setState(() {
                    _hsv = HSVColor.fromColor(
                      Color(int.parse('FF$text', radix: 16)),
                    );
                    _error = null;
                  });
                }
              },
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(context.tr('Vazgeç')),
      ),
      FilledButton(
        onPressed: () {
          if (!RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(_hex.text)) {
            setState(() => _error = context.tr('6 haneli bir renk kodu gir.'));
            return;
          }
          Navigator.pop(context, int.parse('FF${_hex.text}', radix: 16));
        },
        child: Text(context.tr('Uygula')),
      ),
    ],
  );
}
