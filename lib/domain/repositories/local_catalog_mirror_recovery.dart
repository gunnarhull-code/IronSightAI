import '../entities/equipment.dart';

/// Local-only recovery after a successful remote Equipment save whose catalog
/// mirror failed.
abstract class LocalCatalogMirrorRecovery {
  /// Retries only the local catalog upsert for [equipment].
  ///
  /// Never calls remote create or update.
  Future<Equipment> retryLocalMirror(Equipment equipment);
}
