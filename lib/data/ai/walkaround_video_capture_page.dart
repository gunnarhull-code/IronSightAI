import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../domain/ai/walkaround_video.dart';
import '../../domain/ai/walkaround_video_capture_port.dart';
import '../../domain/equipment_id_capture/captured_image.dart';
import '../../domain/equipment_id_capture/equipment_id_capture_failure.dart';
import '../../domain/equipment_id_capture/image_capture_port.dart';

/// Full-screen walkaround recorder. Original video stays on-device.
class WalkaroundVideoCapturePage extends StatefulWidget {
  const WalkaroundVideoCapturePage({
    super.key,
    this.title = 'Walkaround video',
  });

  final String title;

  @override
  State<WalkaroundVideoCapturePage> createState() =>
      _WalkaroundVideoCapturePageState();
}

class _WalkaroundVideoCapturePageState
    extends State<WalkaroundVideoCapturePage> {
  CameraController? _controller;
  String? _error;
  bool _busy = false;
  bool _recording = false;
  Duration _elapsed = Duration.zero;
  Timer? _ticker;
  DateTime? _startedAt;
  String? _startStillPath;

  static const Duration _limit = WalkaroundVideo.maxDuration;

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

  Future<void> _toggleRecording() async {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized || _busy) {
      return;
    }
    if (_recording) {
      await _stopRecording();
      return;
    }
    setState(() => _busy = true);
    try {
      final startStill = await controller.takePicture();
      _startStillPath = startStill.path;
      await controller.startVideoRecording();
      _startedAt = DateTime.now();
      _ticker?.cancel();
      _ticker = Timer.periodic(const Duration(milliseconds: 200), (_) {
        final started = _startedAt;
        if (started == null || !mounted) return;
        final elapsed = DateTime.now().difference(started);
        if (elapsed >= _limit) {
          _stopRecording();
          return;
        }
        setState(() => _elapsed = elapsed);
      });
      if (!mounted) return;
      setState(() {
        _recording = true;
        _busy = false;
        _elapsed = Duration.zero;
      });
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

  Future<void> _stopRecording() async {
    final controller = _controller;
    if (controller == null || !_recording || _busy) return;
    _ticker?.cancel();
    setState(() => _busy = true);
    try {
      final started = _startedAt ?? DateTime.now();
      final videoFile = await controller.stopVideoRecording();
      CapturedImage? endFrame;
      try {
        final endStill = await controller.takePicture();
        endFrame = CapturedImage(
          bytes: await File(endStill.path).readAsBytes(),
          path: endStill.path,
          mimeType: 'image/jpeg',
        );
      } catch (_) {
        // End still is best-effort; start frame plus the local video remain.
      }
      final startPath = _startStillPath;
      final frames = <CapturedImage>[];
      if (startPath != null) {
        frames.add(
          CapturedImage(
            bytes: await File(startPath).readAsBytes(),
            path: startPath,
            mimeType: 'image/jpeg',
          ),
        );
      }
      if (endFrame != null && endFrame.path != startPath) {
        frames.add(endFrame);
      }
      final duration = DateTime.now().difference(started);
      if (duration > _limit + const Duration(seconds: 1)) {
        if (!mounted) return;
        setState(() {
          _busy = false;
          _recording = false;
          _error = 'Walkaround video must be 30 seconds or less.';
        });
        return;
      }
      final recordedDuration = duration > _limit ? _limit : duration;
      final videoPath = videoFile.path;
      final byteSize = await File(videoPath).length();
      if (!mounted) return;
      Navigator.of(context).pop(
        WalkaroundVideo(
          localPath: videoPath,
          duration: recordedDuration,
          representativeFrames: List<CapturedImage>.unmodifiable(frames),
          byteSize: byteSize,
        ),
      );
    } on CameraException catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _recording = false;
        _error = error.description ?? error.code;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _recording = false;
        _error = error.toString();
      });
    }
  }

  Future<void> _cancel() async {
    final controller = _controller;
    if (controller != null && controller.value.isRecordingVideo) {
      try {
        await controller.stopVideoRecording();
      } catch (_) {}
    }
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final remaining = _limit - _elapsed;
    final remainingLabel =
        '${remaining.inSeconds.clamp(0, _limit.inSeconds)} seconds remaining';
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(widget.title),
        leading: IconButton(
          tooltip: 'Cancel walkaround video',
          onPressed: _cancel,
          icon: const Icon(Icons.close),
        ),
      ),
      body: _error != null
          ? _ErrorBody(message: _error!, onClose: _cancel)
          : controller == null || !controller.value.isInitialized
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              fit: StackFit.expand,
              children: [
                Center(child: CameraPreview(controller)),
                Align(
                  alignment: Alignment.topCenter,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Semantics(
                        liveRegion: true,
                        label: _recording
                            ? 'Recording walkaround video. $remainingLabel. '
                                  'Maximum 30 seconds. Original video stays '
                                  'on this device.'
                            : 'Ready to record a walkaround video of at most '
                                  '30 seconds. Original video stays on this device.',
                        child: Text(
                          _recording
                              ? 'Recording · $remainingLabel'
                              : 'Max 30 seconds · original video stays on device',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Semantics(
                        button: true,
                        label: _recording
                            ? 'Stop walkaround video'
                            : 'Start walkaround video, maximum 30 seconds',
                        child: SizedBox(
                          width: 72,
                          height: 72,
                          child: FloatingActionButton.large(
                            onPressed: _busy ? null : _toggleRecording,
                            backgroundColor: _recording
                                ? Colors.red
                                : Colors.white,
                            child: _busy
                                ? const CircularProgressIndicator()
                                : Icon(
                                    _recording ? Icons.stop : Icons.videocam,
                                    size: 36,
                                    color: _recording
                                        ? Colors.white
                                        : Colors.black,
                                  ),
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

/// [WalkaroundVideoCapturePort] that pushes [WalkaroundVideoCapturePage].
class NavigatorWalkaroundVideoCapture implements WalkaroundVideoCapturePort {
  NavigatorWalkaroundVideoCapture({required this.navigatorKey});

  final GlobalKey<NavigatorState> navigatorKey;

  @override
  bool get isSupported => true;

  @override
  Future<WalkaroundVideo> recordWalkaround() async {
    final nav = navigatorKey.currentState;
    if (nav == null) {
      throw EquipmentIdCaptureException(
        EquipmentIdCaptureFailure.cameraUnavailable(),
      );
    }
    final result = await nav.push<WalkaroundVideo>(
      MaterialPageRoute(builder: (_) => const WalkaroundVideoCapturePage()),
    );
    if (result == null) {
      throw EquipmentIdCaptureException(
        EquipmentIdCaptureFailure.captureCancelled(),
      );
    }
    return result;
  }
}
