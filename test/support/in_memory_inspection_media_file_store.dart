import 'dart:io';

import 'package:ironsight_ai/data/local/inspection_media_file_store.dart';
import 'package:ironsight_ai/domain/entities/inspection_photo_slot.dart';
import 'package:path/path.dart' as p;

/// In-memory stand-in for [InspectionMediaFileStore].
///
/// Widget tests run inside a fake-async zone, where real `dart:io` file
/// completions never arrive while the binding is pumping frames. Keeping the
/// bytes in memory lets the Quick Appraisal screen be driven normally; real
/// file behaviour stays covered by the repository tests.
class InMemoryInspectionMediaFileStore extends InspectionMediaFileStore {
  InMemoryInspectionMediaFileStore({this.failWrites = false});

  final Map<String, List<int>> files = {};

  /// Simulates a local persistence failure during capture.
  bool failWrites;

  int deleteCallCount = 0;

  @override
  Future<String> absolutePathFor(String relativePath) async =>
      p.join(Directory.systemTemp.path, relativePath);

  @override
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
    if (failWrites) {
      throw const FileSystemException('simulated local storage failure');
    }
    final relativePath = p.join(
      InspectionMediaFileStore.rootFolderName,
      companyId,
      inspectionId,
      slot.storageValue,
      '$mediaId.$extension',
    );
    files[relativePath] = List<int>.unmodifiable(bytes);
    return StoredInspectionMediaFile(
      relativePath: relativePath,
      absolutePath: await absolutePathFor(relativePath),
      byteSize: bytes.length,
    );
  }

  @override
  Future<List<int>> readBytes(String relativePath) async {
    final bytes = files[relativePath];
    if (bytes == null) {
      throw StateError('Inspection media file missing: $relativePath');
    }
    return bytes;
  }

  @override
  Future<void> deleteIfExists(String relativePath) async {
    deleteCallCount += 1;
    files.remove(relativePath);
  }
}
