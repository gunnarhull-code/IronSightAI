import 'package:flutter_test/flutter_test.dart';
import 'package:ironsight_ai/domain/ai/walkaround_capture_outcome.dart';
import 'package:ironsight_ai/domain/ai/walkaround_capture_session.dart';

import '../support/fake_walkaround_video_capture.dart';

void main() {
  test('reported success survives a later empty Navigator pop', () async {
    final session = WalkaroundCaptureSession();
    session.report(WalkaroundCaptureOutcome.success(sampleWalkaroundVideo()));
    final outcome = await session.finalizeAfterRoute();
    expect(outcome.status, WalkaroundCaptureStatus.success);
    expect(outcome.video, isNotNull);
    expect(outcome.video!.framesDecodedFromLocalVideo, isTrue);
    expect(outcome.video!.representativeFrames, isNotEmpty);
    expect(
      outcome.video!.representativeFrames.every(
        (frame) => frame.originatesFrom(outcome.video!.localPath),
      ),
      isTrue,
    );
  });

  test('empty pop without a report is cancelled, not success', () async {
    final session = WalkaroundCaptureSession();
    final outcome = await session.finalizeAfterRoute();
    expect(outcome.status, WalkaroundCaptureStatus.cancelled);
    expect(outcome.video, isNull);
  });

  test('duplicate reports do not replace the first outcome', () async {
    final session = WalkaroundCaptureSession();
    session.report(WalkaroundCaptureOutcome.cancelled());
    session.report(WalkaroundCaptureOutcome.success(sampleWalkaroundVideo()));
    final outcome = await session.finalizeAfterRoute();
    expect(outcome.status, WalkaroundCaptureStatus.cancelled);
  });
}
