import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../domain/entities/inspection_photo_slot.dart';

/// Result of persisting bytes into app-private inspection media storage.
class StoredInspectionMediaFile {
  const StoredInspectionMediaFile({
    required this.relativePath,
    required this.absolutePath,
    required this.byteSize,
  });

  final String relativePath;
  final String absolutePath;
  final int byteSize;
}

/// App-private local file storage for inspection photos.
///
/// Paths are rooted under the application documents directory so media survives
/// app restart. Relative paths are what Drift persists.
class InspectionMediaFileStore {
  InspectionMediaFileStore({this.documentsDirectoryOverride});

  /// Test override for the application documents directory.
  final Directory? Function()? documentsDirectoryOverride;

  static const String rootFolderName = 'inspection_media';

  Future<Directory> _documentsRoot() async {
    final override = documentsDirectoryOverride?.call();
    if (override != null) return override;
    return getApplicationDocumentsDirectory();
  }

  Future<String> absolutePathFor(String relativePath) async {
    final root = await _documentsRoot();
    return p.join(root.path, relativePath);
  }

  Future<StoredInspectionMediaFile> writeBytes({
    required String companyId,
    required String inspectionId,
    required InspectionPhotoSlot slot,
    required String mediaId,
    required List<int> bytes,
    String extension = 'jpg',
  }) async {
    if (bytes.isEmpty) {
      throw ArgumentError.value(bytes, 'bytes', 'must not be empty');
    }
    final relativePath = p.join(
      rootFolderName,
      companyId,
      inspectionId,
      slot.storageValue,
      '$mediaId.$extension',
    );
    final absolutePath = await absolutePathFor(relativePath);
    final file = File(absolutePath);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes, flush: true);
    return StoredInspectionMediaFile(
      relativePath: relativePath,
      absolutePath: absolutePath,
      byteSize: bytes.length,
    );
  }

  Future<List<int>> readBytes(String relativePath) async {
    final file = File(await absolutePathFor(relativePath));
    if (!await file.exists()) {
      throw StateError('Inspection media file missing: $relativePath');
    }
    return file.readAsBytes();
  }

  Future<void> deleteIfExists(String relativePath) async {
    final file = File(await absolutePathFor(relativePath));
    if (await file.exists()) {
      await file.delete();
    }
  }
}
