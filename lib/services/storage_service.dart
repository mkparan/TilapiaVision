import 'dart:io';

import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

import '../core/constants.dart';

/// Handles saving captured photos into the app-private Visual Archive
/// and clearing anything older than [DetectionConfig.imageRetentionDays].
class StorageService {
  static const _archiveDirName = 'visual_archive';

  Future<Directory> _archiveDir() async {
    final base = await getApplicationDocumentsDirectory();
    final dir = Directory('${base.path}/$_archiveDirName');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  /// Compresses and copies [source] into the Visual Archive, returning
  /// the new file's path. Targets under
  /// [DetectionConfig.maxImageBytes] per Section 1.5.1.
  Future<String> cacheImage(File source) async {
    final dir = await _archiveDir();
    final fileName = '${DateTime.now().microsecondsSinceEpoch}.jpg';
    final outPath = '${dir.path}/$fileName';

    final bytes = await source.readAsBytes();
    final decoded = img.decodeImage(bytes);

    if (decoded == null) {
      // Not a decodable image (unexpected) — fall back to a straight
      // copy rather than losing the capture entirely.
      await source.copy(outPath);
      return outPath;
    }

    var quality = 85;
    List<int> encoded = img.encodeJpg(decoded, quality: quality);
    while (encoded.length > DetectionConfig.maxImageBytes && quality > 30) {
      quality -= 10;
      encoded = img.encodeJpg(decoded, quality: quality);
    }

    final outFile = File(outPath);
    await outFile.writeAsBytes(encoded);
    return outPath;
  }

  /// Deletes any cached photo older than the retention window. Call
  /// this once on app launch — no background service needed for the
  /// MVP (see the masterplan's rationale for keeping this simple).
  Future<void> clearExpiredImages() async {
    final dir = await _archiveDir();
    if (!await dir.exists()) return;

    final cutoff = DateTime.now().subtract(
      const Duration(days: DetectionConfig.imageRetentionDays),
    );

    await for (final entity in dir.list()) {
      if (entity is File) {
        final modified = await entity.lastModified();
        if (modified.isBefore(cutoff)) {
          await entity.delete();
        }
      }
    }
  }

  /// True if the image at [path] still exists on disk — used by the
  /// History screen to decide whether to show the real thumbnail or
  /// the "Image Expired" fallback state.
  Future<bool> imageExists(String? path) async {
    if (path == null) return false;
    return File(path).exists();
  }
}
