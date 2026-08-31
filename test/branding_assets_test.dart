import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('home brand mark is a compact transparent PNG', () async {
    final data = await rootBundle.load(
      'assets/branding/albumium_brand_mark.png',
    );
    final codec = await ui.instantiateImageCodec(data.buffer.asUint8List());
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final rgba = await image.toByteData(format: ui.ImageByteFormat.rawRgba);

    expect(image.width, 512);
    expect(image.height, 512);
    expect(rgba, isNotNull);

    final pixels = rgba!.buffer.asUint8List();
    final alphaValues = <int>{};
    for (var index = 3; index < pixels.length; index += 4) {
      alphaValues.add(pixels[index]);
      if (alphaValues.contains(0) && alphaValues.contains(255)) break;
    }
    expect(alphaValues, contains(0));
    expect(alphaValues, contains(255));

    image.dispose();
    codec.dispose();
  });
}
