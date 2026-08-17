import AVFoundation
import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private static let channelName = "com.example.ironsight_ai/walkaround_frames"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let messenger = engineBridge.applicationRegistrar.messenger()
    let channel = FlutterMethodChannel(
      name: AppDelegate.channelName,
      binaryMessenger: messenger
    )
    channel.setMethodCallHandler { call, result in
      guard call.method == "extractJpegFrame" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard
        let args = call.arguments as? [String: Any],
        let path = args["path"] as? String,
        !path.isEmpty
      else {
        result(
          FlutterError(code: "invalid_args", message: "path is required", details: nil)
        )
        return
      }
      let timeMs = (args["timeMs"] as? NSNumber)?.int64Value ?? 0
      let maxWidth = (args["maxWidth"] as? NSNumber)?.intValue ?? 1280
      let quality = max(1, min(100, (args["quality"] as? NSNumber)?.intValue ?? 70))
      DispatchQueue.global(qos: .userInitiated).async {
        do {
          let data = try AppDelegate.extractJpegFrame(
            path: path,
            timeMs: timeMs,
            maxWidth: maxWidth,
            quality: quality
          )
          DispatchQueue.main.async {
            result(data)
          }
        } catch {
          DispatchQueue.main.async {
            result(
              FlutterError(
                code: "extract_failed",
                message: error.localizedDescription,
                details: nil
              )
            )
          }
        }
      }
    }
  }

  private static func extractJpegFrame(
    path: String,
    timeMs: Int64,
    maxWidth: Int,
    quality: Int
  ) throws -> FlutterStandardTypedData? {
    let url = URL(fileURLWithPath: path)
    guard FileManager.default.fileExists(atPath: path) else {
      return nil
    }
    let asset = AVURLAsset(url: url)
    let generator = AVAssetImageGenerator(asset: asset)
    generator.appliesPreferredTrackTransform = true
    if maxWidth > 0 {
      generator.maximumSize = CGSize(width: maxWidth, height: maxWidth)
    }
    generator.requestedTimeToleranceBefore = .positiveInfinity
    generator.requestedTimeToleranceAfter = .positiveInfinity
    let time = CMTime(value: timeMs, timescale: 1000)
    let cgImage = try generator.copyCGImage(at: time, actualTime: nil)
    let image = UIImage(cgImage: cgImage)
    guard let jpeg = image.jpegData(compressionQuality: CGFloat(quality) / 100.0) else {
      return nil
    }
    return FlutterStandardTypedData(bytes: jpeg)
  }
}
