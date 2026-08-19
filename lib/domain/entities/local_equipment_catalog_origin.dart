/// Provenance of a row in the local equipment catalog cache.
enum LocalEquipmentCatalogOrigin {
  /// Mirrored from the remote equipment list during a catalog refresh.
  remoteCache,

  /// Created locally by guided New-machine completion (offline-safe).
  localCreated;

  String get storageValue => switch (this) {
    LocalEquipmentCatalogOrigin.remoteCache => 'remote_cache',
    LocalEquipmentCatalogOrigin.localCreated => 'local_created',
  };

  static LocalEquipmentCatalogOrigin fromStorage(String value) {
    return switch (value) {
      'remote_cache' => LocalEquipmentCatalogOrigin.remoteCache,
      'local_created' => LocalEquipmentCatalogOrigin.localCreated,
      _ => throw FormatException(
        'Unknown local equipment catalog origin: $value',
      ),
    };
  }
}
