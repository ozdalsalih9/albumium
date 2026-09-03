import 'dart:io';

const albumiumExportFilePrefix = 'albumium_export_';
const albumiumExportRetention = Duration(hours: 24);

class VideoExportProgressEstimate {
  const VideoExportProgressEstimate({
    required this.progress,
    required this.elapsed,
    required this.estimatedRemaining,
  });

  final double progress;
  final Duration elapsed;
  final Duration? estimatedRemaining;

  String get label {
    final percent = (progress.clamp(0.0, 1.0) * 100).round();
    final remaining = estimatedRemaining;
    return '$percent% · Geçen ${formatExportDuration(elapsed)} · '
        'Tahmini kalan ${remaining == null ? '—' : formatExportDuration(remaining)}';
  }
}

VideoExportProgressEstimate estimateVideoExportProgress({
  required int completedFrames,
  required int totalFrames,
  required Duration elapsed,
  double renderingWeight = 0.97,
}) {
  final safeTotal = totalFrames <= 0 ? 1 : totalFrames;
  final safeCompleted = completedFrames.clamp(0, safeTotal);
  final frameProgress = safeCompleted / safeTotal;
  Duration? remaining;
  if (safeCompleted > 0 && safeCompleted < safeTotal) {
    final remainingMilliseconds =
        (elapsed.inMilliseconds / safeCompleted * (safeTotal - safeCompleted))
            .ceil();
    remaining = Duration(milliseconds: remainingMilliseconds);
  } else if (safeCompleted == safeTotal) {
    remaining = Duration.zero;
  }

  return VideoExportProgressEstimate(
    progress: (frameProgress * renderingWeight).clamp(0.0, 1.0),
    elapsed: elapsed,
    estimatedRemaining: remaining,
  );
}

String formatExportDuration(Duration duration) {
  final seconds = duration.inSeconds.clamp(0, 359999);
  final hours = seconds ~/ 3600;
  final minutes = (seconds % 3600) ~/ 60;
  final remainingSeconds = seconds % 60;
  final minuteText = minutes.toString().padLeft(2, '0');
  final secondText = remainingSeconds.toString().padLeft(2, '0');
  if (hours > 0) return '$hours:$minuteText:$secondText';
  return '$minuteText:$secondText';
}

String safeAlbumiumExportTitle(String value) {
  final normalized = value
      .replaceAll(RegExp(r'[^a-zA-Z0-9\-_]+'), '_')
      .replaceAll(RegExp(r'_+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
  return normalized.isEmpty ? 'albumium_album' : normalized;
}

String albumiumExportFilename({
  required String title,
  required DateTime createdAt,
  required String extension,
  String? suffix,
}) {
  final normalizedExtension = extension.toLowerCase().replaceFirst('.', '');
  if (normalizedExtension != 'mp4' && normalizedExtension != 'png') {
    throw ArgumentError.value(extension, 'extension', 'MP4 veya PNG olmalı.');
  }
  final suffixPart = suffix == null || suffix.isEmpty ? '' : '_$suffix';
  return '$albumiumExportFilePrefix${safeAlbumiumExportTitle(title)}_'
      '${createdAt.millisecondsSinceEpoch}$suffixPart.$normalizedExtension';
}

bool isStaleAlbumiumExportFile({
  required String path,
  required DateTime modifiedAt,
  required DateTime now,
  Duration retention = albumiumExportRetention,
  Set<String> protectedPaths = const <String>{},
}) {
  final normalizedPath = _normalizedPath(path);
  if (protectedPaths.any(
    (protectedPath) => _normalizedPath(protectedPath) == normalizedPath,
  )) {
    return false;
  }

  final filename = _basename(path);
  final extension = filename.toLowerCase();
  if (!filename.startsWith(albumiumExportFilePrefix) ||
      (!extension.endsWith('.mp4') && !extension.endsWith('.png'))) {
    return false;
  }
  return modifiedAt.isBefore(now.subtract(retention));
}

Future<List<String>> cleanupStaleAlbumiumExports(
  Directory temporaryDirectory, {
  DateTime? now,
  Duration retention = albumiumExportRetention,
  Set<String> protectedPaths = const <String>{},
}) async {
  final deletedPaths = <String>[];
  final referenceTime = now ?? DateTime.now();

  try {
    await for (final entity in temporaryDirectory.list(
      recursive: false,
      followLinks: false,
    )) {
      if (entity is! File) continue;
      try {
        final stat = await entity.stat();
        if (!isStaleAlbumiumExportFile(
          path: entity.path,
          modifiedAt: stat.modified,
          now: referenceTime,
          retention: retention,
          protectedPaths: protectedPaths,
        )) {
          continue;
        }
        await entity.delete();
        deletedPaths.add(entity.path);
      } on FileSystemException {
        // Temp cleanup is best effort and must never block a new export.
      }
    }
  } on FileSystemException {
    // The OS may clean or lock its temp directory while it is being listed.
  }
  return deletedPaths;
}

Future<File> requireNonEmptyVideoExport(String path) async {
  final file = File(path);
  if (!await file.exists()) {
    throw StateError('Video dosyası oluşturulamadı.');
  }
  if (await file.length() <= 0) {
    throw StateError('Video dosyası boş oluşturuldu.');
  }
  return file;
}

String _basename(String path) {
  final slash = path.lastIndexOf('/');
  final backslash = path.lastIndexOf('\\');
  final separator = slash > backslash ? slash : backslash;
  return separator < 0 ? path : path.substring(separator + 1);
}

String _normalizedPath(String path) {
  final absolute = File(path).absolute.path.replaceAll('\\', '/');
  return Platform.isWindows ? absolute.toLowerCase() : absolute;
}
