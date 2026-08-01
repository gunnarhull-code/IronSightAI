/// Camera permission states exposed to domain / UI without plugin types.
enum CameraPermissionStatus {
  granted,
  denied,
  permanentlyDenied,
  restricted,
  unavailable,
}

/// Application-owned camera permission port.
abstract class CameraPermissionPort {
  Future<CameraPermissionStatus> check();

  Future<CameraPermissionStatus> request();
}
