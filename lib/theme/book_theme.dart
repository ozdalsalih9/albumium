import 'package:flutter/material.dart';

/// Okuma yüzeyinin paleti ve ölçüleri.
///
/// Uygulamanın geri kalanı koyu temalıdır; önizleme ise bir okuma yüzeyidir ve
/// kitabı taşıyan zemin bilerek açık ve sıcak tutulur. Böylece renkli kapaklar
/// ve kâğıt tonlarındaki sayfalar öne çıkar, arayüz geri çekilir.
abstract final class BookTheme {
  /// Kitabın üzerinde durduğu sıcak nötr zemin.
  static const ground = Color(0xFFEBE6DE);

  /// Zeminin kenarlara doğru koyulaşan tonu; kitabı ortada toplar.
  static const groundEdge = Color(0xFFD9D2C7);

  /// Saf beyaz yerine hafif sıcak kâğıt.
  static const paper = Color(0xFFFAF9F6);

  static const ink = Color(0xFF2A2521);
  static const inkSoft = Color(0xFF7A7169);

  /// Dokununca beliren kontrol katmanının zemini.
  static const chrome = Color(0xF7FBFAF8);

  /// Sayfa en-boy oranı.
  static const pageAspect = 9 / 14;

  /// Kitabın çevresindeki boşluğun kısa kenara oranı. Sabit piksel yerine oran
  /// kullanılır ki telefon ve tablette denge korunsun.
  static const marginRatio = 0.055;

  /// İki sayfalı görünüme geçmek için gereken en küçük genişlik. Bunun altında
  /// çift sayfa okunamayacak kadar küçülür.
  static const spreadMinWidth = 640.0;

  /// Kontrol çubuklarının yüksekliği. Kitap bu kadar pay bırakarak
  /// yerleştirilir; aksi hâlde dar yatay ekranlarda çubukların altında kalır.
  /// Pay, çubuklar gizlendiğinde de korunur ki kitap yerinden oynamasın.
  static const topChromeHeight = 56.0;
  static const bottomChromeHeight = 68.0;

  /// Sayfa köşelerinin yarıçapı.
  static const pageRadius = 5.0;

  /// Kitabın zemine düşürdüğü gölge.
  static List<BoxShadow> get bookShadow => const [
    BoxShadow(
      color: Color(0x2E000000),
      blurRadius: 34,
      spreadRadius: 2,
      offset: Offset(0, 14),
    ),
    BoxShadow(color: Color(0x14000000), blurRadius: 6, offset: Offset(0, 2)),
  ];
}
