import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../domain/equipment_id_capture/captured_image.dart';
import '../../domain/equipment_id_capture/equipment_id_capture_failure.dart';
import '../../domain/equipment_id_capture/image_capture_port.dart';

/// Full-screen camera capture UI owned by the data/platform layer.
///
/// Presentation panels must not import `package:camera` — they open this page
/// through [ImageCapturePort] / a navigator callback instead.
class CameraCapturePage extends StatefulWidget {
  const CameraCapturePage({super.key, this.title = 'Scan equipment ID'});

  final String title;

  @override
  State<CameraCapturePage> createState() => _CameraCapturePageState();
}

class _CameraCapturePageState extends State<CameraCapturePage> {
  CameraController? _controller;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() => _error = 'No camera is available on this device.');
        return;
      }
      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() => _controller = controller);
    } on CameraException catch (error) {
      setState(() => _error = error.description ?? error.code);
    } catch (error) {
      setState(() => _error = error.toString());
    }
  }

  Future<void> _takePicture() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _busy) {
      return;
    }
    setState(() => _busy = true);
    try {
      final file = await controller.takePicture();
      final bytes = await File(file.path).readAsBytes();
      if (!mounted) return;
      Navigator.of(context).pop(
        CapturedImage(bytes: bytes, path: file.path, mimeType: 'image/jpeg'),
      );
    } on CameraException catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = error.description ?? error.code;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = error.toString();
      });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.title),
        leading: IconButton(
          tooltip: 'Cancel capture',
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close),
        ),
      ),
      body: _error != null
          ? _ErrorBody(
              message: _error!,
              onClose: () => Navigator.of(context).pop(),
            )
          : controller == null || !controller.value.isInitialized
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              fit: StackFit.expand,
              children: [
                Center(child: CameraPreview(controller)),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Semantics(
                        button: true,
                        label: 'Capture photo for text recognition',
                        child: SizedBox(
                          width: 72,
                          height: 72,
                          child: FloatingActionButton.large(
                            onPressed: _busy ? null : _takePicture,
                            child: _busy
                                ? const CircularProgressIndicator()
                                : const Icon(Icons.camera_alt, size: 36),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.message, required this.onClose});

  final String message;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onClose, child: const Text('Close')),
          ],
        ),
      ),
    );
  }
}

/// [ImageCapturePort] that pushes [CameraCapturePage] via [navigatorKey].
class NavigatorCameraImageCapture implements ImageCapturePort {
  NavigatorCameraImageCapture({
    required this.navigatorKey,
    this.pageTitle = 'Scan equipment ID',
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final String pageTitle;

  @override
  bool get isSupported => true;

  @override
  Future<CapturedImage> captureStill() async {
    final nav = navigatorKey.currentState;
    if (nav == null) {
      throw EquipmentIdCaptureException(
        EquipmentIdCaptureFailure.cameraUnavailable(),
      );
    }
    final result = await nav.push<CapturedImage>(
      MaterialPageRoute(
        builder: (_) => CameraCapturePage(title: pageTitle),
      ),
    );
    if (result == null) {
      throw EquipmentIdCaptureException(
        EquipmentIdCaptureFailure.captureCancelled(),
      );
    }
    return result;
  }
}
