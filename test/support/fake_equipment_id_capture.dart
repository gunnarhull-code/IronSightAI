import 'package:ironsight_ai/domain/equipment_id_capture/camera_permission_port.dart';
import 'package:ironsight_ai/domain/equipment_id_capture/captured_image.dart';
import 'package:ironsight_ai/domain/equipment_id_capture/image_capture_port.dart';
import 'package:ironsight_ai/domain/equipment_id_capture/recognized_text_block.dart';
import 'package:ironsight_ai/domain/equipment_id_capture/text_recognition_port.dart';

class FakeCameraPermission implements CameraPermissionPort {
  FakeCameraPermission({
    this.checkStatus = CameraPermissionStatus.granted,
    this.requestStatus = CameraPermissionStatus.granted,
  });

  CameraPermissionStatus checkStatus;
  CameraPermissionStatus requestStatus;
  int requestCallCount = 0;

  @override
  Future<CameraPermissionStatus> check() async => checkStatus;

  @override
  Future<CameraPermissionStatus> request() async {
    requestCallCount += 1;
    return requestStatus;
  }
}

class FakeImageCapture implements ImageCapturePort {
  FakeImageCapture({
    this.isSupported = true,
    this.image = const CapturedImage(bytes: [1, 2, 3], path: '/tmp/fake.jpg'),
    this.error,
  });

  @override
  bool isSupported;

  CapturedImage image;
  Object? error;
  int captureCallCount = 0;

  @override
  Future<CapturedImage> captureStill() async {
    captureCallCount += 1;
    if (error != null) {
      final err = error!;
      if (err is EquipmentIdCaptureException) throw err;
      throw err;
    }
    return image;
  }
}

class FakeTextRecognition implements TextRecognitionPort {
  FakeTextRecognition({
    this.isSupported = true,
    this.blocks = const [],
    this.error,
  });

  @override
  bool isSupported;

  List<RecognizedTextBlock> blocks;
  Object? error;
  int recognizeCallCount = 0;
  int disposeCallCount = 0;
  bool get usedNetwork => false;

  @override
  Future<List<RecognizedTextBlock>> recognize(CapturedImage image) async {
    recognizeCallCount += 1;
    if (error != null) throw error!;
    return blocks;
  }

  @override
  Future<void> dispose() async {
    disposeCallCount += 1;
  }
}
