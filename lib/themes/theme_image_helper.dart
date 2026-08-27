import 'dart:io';
import 'package:flutter/material.dart';

const themeImageCacheWidth = 1600;

/// Returns the same bounded decode provider everywhere an album image is used.
/// Keeping the provider key stable lets MP4 export warm the exact image that
/// [ThemeImage] paints, while the decode cap prevents a few camera photos from
/// evicting one another from Flutter's image cache.
ImageProvider<Object> themeImageProvider(
  String url, {
  int? cacheWidth = themeImageCacheWidth,
}) {
  final ImageProvider<Object> provider;
  if (url.startsWith('http://') || url.startsWith('https://')) {
    provider = NetworkImage(url);
  } else if (url.startsWith('assets/')) {
    provider = AssetImage(url);
  } else {
    final file = File(url);
    provider = file.existsSync() || url.contains('/') || url.contains('\\')
        ? FileImage(file)
        : AssetImage(url);
  }
  return ResizeImage.resizeIfNeeded(cacheWidth, null, provider);
}

/// Helper widget to display images from local file paths, asset paths, or network URLs
/// with automatic fallbacks and graceful error handling.
class ThemeImage extends StatelessWidget {
  const ThemeImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.placeholderIcon = Icons.photo_outlined,
    this.cacheWidth = themeImageCacheWidth,
  });

  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final IconData placeholderIcon;
  final int? cacheWidth;

  @override
  Widget build(BuildContext context) {
    if (url.trim().isEmpty) {
      return _placeholder();
    }
    return Image(
      image: themeImageProvider(url, cacheWidth: cacheWidth),
      width: width,
      height: height,
      fit: fit,
      filterQuality: FilterQuality.high,
      gaplessPlayback: true,
      errorBuilder: (_, _, _) => _placeholder(),
    );
  }

  Widget _placeholder() {
    return Container(
      width: width,
      height: height,
      color: const Color(0x33888888),
      child: Center(
        child: Icon(placeholderIcon, color: const Color(0x88888888), size: 32),
      ),
    );
  }
}
