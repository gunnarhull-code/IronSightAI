import 'dart:async';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';

import '../../domain/ai/walkaround_capture_diagnostics.dart';
import '../../domain/ai/walkaround_capture_outcome.dart';
import '../../domain/ai/walkaround_capture_session.dart';
import '../../domain/ai/walkaround_recording_pipeline.dart';
import '../../domain/ai/ai_media_review_failure.dart';
import '../../domain/ai/walkaround_video.dart';
import '../../domain/ai/walkaround_video_capture_port.dart';
import '../../domain/ai/walkaround_video_frame_decoder.dart';
import '../../domain/equipment_id_capture/equipment_id_capture_failure.dart';
import '../../domain/equipment_id_capture/image_capture_port.dart';
import 'create_walkaround_frame_decoder.dart';

/// Full-screen walkaround recorder. Original video stays on-device.
///
/// Representative frames are decoded from the recorded MP4. Separate camera
/// stills taken before or after recording are never used for video analysis.
class WalkaroundVideoCapturePage extends StatefulWidget {
  const WalkaroundVideoCapturePage({
    super.key,
    this.title = 'Walkaround video',
    this.frameDecoder,
    this.onCompleted,
  });

  final String title;
  final WalkaroundVideoFrameDecoder? frameDecoder;
  final ValueChanged<WalkaroundCaptureOutcome>? onCompleted;

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
  bool _saving = false;
  bool _reported = false;
  Duration _elapsed = Duration.zero;
  Timer? _ticker;
  DateTime? _startedAt;

  static const Duration _limit = WalkaroundVideo.maxDuration;

  late final WalkaroundVideoFrameDecoder _frameDecoder =
      widget.frameDecoder ?? createWalkaroundVideoFrameDecoder();

  @override
  void initState() {
    super.initState();
    WalkaroundCaptureDiagnostics.emit('capture_opened');
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

  void _complete(WalkaroundCaptureOutcome outcome) {
    if (_reported) return;
    _reported = true;
    WalkaroundCaptureDiagnostics.emit('outcome_reported', {
      'outcome': outcome.status.name,
      'frameCount': outcome.video?.representativeFrames.length ?? 0,
      'durationMs': outcome.video?.duration.inMilliseconds ?? 0,
      'decodeErrorType': outcome.failure?.kind.name,
    });
    widget.onCompleted?.call(outcome);
  }

  Future<void> _popAfterReport() async {
    if (!mounted) return;
    Navigator.of(context).pop();
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
      WalkaroundCaptureDiagnostics.emit('recording_started');
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
    setState(() {
      _busy = true;
      _saving = true;
    });
    try {
      final started = _startedAt ?? DateTime.now();
      WalkaroundCaptureDiagnostics.emit('recording_stop_requested');
      final videoFile = await controller.stopVideoRecording();
      final duration = DateTime.now().difference(started);
      final videoPath = videoFile.path;
      final file = File(videoPath);
      final exists = await file.exists();
      final byteSize = exists ? await file.length() : 0;
      WalkaroundCaptureDiagnostics.emit('recording_saved', {
        'pathKind': WalkaroundCaptureDiagnostics.pathKind(videoPath),
        'looksLikeMp4': WalkaroundCaptureDiagnostics.looksLikeMp4(videoPath),
        'fileExists': exists,
        'byteSize': byteSize,
        'durationMs': duration.inMilliseconds,
      });

      if (duration > _limit + const Duration(seconds: 1)) {
        _complete(
          WalkaroundCaptureOutcome.failed(AiMediaReviewFailure.videoTooLong()),
        );
        await _popAfterReport();
        return;
      }

      final recordedDuration = duration > _limit ? _limit : duration;
      WalkaroundCaptureDiagnostics.emit('decode_started', {
        'pathKind': WalkaroundCaptureDiagnostics.pathKind(videoPath),
        'fileExists': exists,
        'byteSize': byteSize,
        'durationMs': recordedDuration.inMilliseconds,
      });
      final outcome = await WalkaroundRecordingPipeline.complete(
        decoder: _frameDecoder,
        recordedPath: videoPath,
        recordedDuration: recordedDuration,
        fileExists: exists,
        byteSize: byteSize,
      );
      WalkaroundCaptureDiagnostics.emit('decode_finished', {
        'outcome': outcome.status.name,
        'frameCount': outcome.video?.representativeFrames.length ?? 0,
        'decodeErrorType': outcome.failure?.kind.name,
      });
      _complete(outcome);
      await _popAfterReport();
    } on CameraException catch (error) {
      WalkaroundCaptureDiagnostics.emit('record_failed', {
        'decodeErrorType': error.code,
      });
      _complete(
        WalkaroundCaptureOutcome.failed(
          AiMediaReviewFailure.providerFailure(error.description ?? error.code),
        ),
      );
      await _popAfterReport();
    } catch (error) {
      WalkaroundCaptureDiagnostics.emit('record_failed', {
        'decodeErrorType': error.runtimeType.toString(),
      });
      _complete(
        WalkaroundCaptureOutcome.failed(
          AiMediaReviewFailure.videoFramesMissing(),
        ),
      );
      await _popAfterReport();
    }
  }

  Future<void> _cancel() async {
    final controller = _controller;
    if (controller != null && controller.value.isRecordingVideo) {
      try {
        await controller.stopVideoRecording();
      } catch (_) {}
    }
    _complete(WalkaroundCaptureOutcome.cancelled());
    await _popAfterReport();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _controller?.dispose();
    if (!_reported) {
      _complete(WalkaroundCaptureOutcome.cancelled());
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final remaining = _limit - _elapsed;
    final remainingLabel =
        '${remaining.inSeconds.clamp(0, _limit.inSeconds)} seconds remaining';
    return PopScope(
      canPop: !_saving,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop && !_reported) {
          _complete(WalkaroundCaptureOutcome.cancelled());
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: Text(widget.title),
          leading: IconButton(
            tooltip: 'Cancel walkaround video',
            onPressed: _saving ? null : _cancel,
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
                          label: _saving
                              ? 'Saving walkaround video and decoding frames '
                                    'from the recording. Original video stays '
                                    'on this device.'
                              : _recording
                              ? 'Recording walkaround video. $remainingLabel. '
                                    'Maximum 30 seconds. Frames will be decoded '
                                    'from the recording. Original video stays '
                                    'on this device.'
                              : 'Ready to record a walkaround video of at most '
                                    '30 seconds. Frames are decoded from the '
                                    'MP4. Original video stays on this device.',
                          child: Text(
                            _saving
                                ? 'Saving recording · decoding frames from MP4'
                                : _recording
                                ? 'Recording · $remainingLabel'
                                : 'Max 30s · frames decoded from MP4 · '
                                      'original stays on device',
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
                  if (_saving)
                    const ColoredBox(
                      color: Color(0x99000000),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            CircularProgressIndicator(),
                            SizedBox(height: 16),
                            Text(
                              'Decoding frames from the recorded video…',
                              style: TextStyle(color: Colors.white),
                              textAlign: TextAlign.center,
                            ),
                          ],
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
  NavigatorWalkaroundVideoCapture({
    required this.navigatorKey,
    this.frameDecoder,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final WalkaroundVideoFrameDecoder? frameDecoder;

  @override
  bool get isSupported => true;

  @override
  Future<WalkaroundCaptureOutcome> recordWalkaround() async {
    final nav = navigatorKey.currentState;
    if (nav == null) {
      throw EquipmentIdCaptureException(
        EquipmentIdCaptureFailure.cameraUnavailable(),
      );
    }
    final session = WalkaroundCaptureSession();
    await nav.push<void>(
      MaterialPageRoute(
        builder: (_) => WalkaroundVideoCapturePage(
          frameDecoder: frameDecoder,
          onCompleted: session.report,
        ),
      ),
    );
    return session.finalizeAfterRoute();
  }
}
