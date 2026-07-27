import 'package:permission_handler/permission_handler.dart' as ph;

import '../../domain/equipment_id_capture/camera_permission_port.dart';

/// Maps [permission_handler] camera status into the domain port.
class PermissionHandlerCameraPermission implements CameraPermissionPort {
  const PermissionHandlerCameraPermission();

  @override
  Future<CameraPermissionStatus> check() async {
    return _map(await ph.Permission.camera.status);
  }

  @override
  Future<CameraPermissionStatus> request() async {
    final current = await ph.Permission.camera.status;
    if (current.isGranted) return CameraPermissionStatus.granted;
    if (current.isPermanentlyDenied || current.isRestricted) {
      return _map(current);
    }
    return _map(await ph.Permission.camera.request());
  }

  CameraPermissionStatus _map(ph.PermissionStatus status) {
    if (status.isGranted || status.isLimited) {
      return CameraPermissionStatus.granted;
    }
    if (status.isPermanentlyDenied) {
      return CameraPermissionStatus.permanentlyDenied;
    }
    if (status.isRestricted) {
      return CameraPermissionStatus.restricted;
    }
    if (status.isDenied) {
      return CameraPermissionStatus.denied;
    }
    return CameraPermissionStatus.unavailable;
  }
}
