package com.example.ironsight_ai

import android.graphics.Bitmap
import android.media.MediaMetadataRetriever
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.io.File

/**
 * Extracts JPEG stills from a local walkaround MP4 via MediaMetadataRetriever.
 *
 * Lives in the app module (AGP 9 / new DSL) so we do not depend on the
 * unmaintained video_thumbnail plugin (jcenter / kotlin-android apply).
 */
class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "extractJpegFrame" -> {
                    val path = call.argument<String>("path")
                    val timeMs = call.argument<Number>("timeMs")?.toLong() ?: 0L
                    val maxWidth = call.argument<Number>("maxWidth")?.toInt() ?: 1280
                    val quality = (call.argument<Number>("quality")?.toInt() ?: 70)
                        .coerceIn(1, 100)
                    if (path.isNullOrBlank()) {
                        result.error("invalid_args", "path is required", null)
                        return@setMethodCallHandler
                    }
                    try {
                        val bytes = extractJpegFrame(path, timeMs, maxWidth, quality)
                        if (bytes == null) {
                            result.success(null)
                        } else {
                            result.success(bytes)
                        }
                    } catch (error: Exception) {
                        result.error("extract_failed", error.message, null)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun extractJpegFrame(
        path: String,
        timeMs: Long,
        maxWidth: Int,
        quality: Int,
    ): ByteArray? {
        val file = File(path)
        if (!file.isFile) return null
        val retriever = MediaMetadataRetriever()
        try {
            retriever.setDataSource(path)
            val bitmap =
                retriever.getFrameAtTime(
                    timeMs * 1000L,
                    MediaMetadataRetriever.OPTION_CLOSEST_SYNC,
                ) ?: return null
            val scaled = scaleBitmap(bitmap, maxWidth)
            if (scaled !== bitmap) {
                bitmap.recycle()
            }
            val stream = ByteArrayOutputStream()
            scaled.compress(Bitmap.CompressFormat.JPEG, quality, stream)
            scaled.recycle()
            return stream.toByteArray()
        } finally {
            try {
                retriever.release()
            } catch (_: Exception) {
                // Best-effort release.
            }
        }
    }

    private fun scaleBitmap(source: Bitmap, maxWidth: Int): Bitmap {
        if (maxWidth <= 0 || source.width <= maxWidth) return source
        val height = (source.height.toDouble() * maxWidth / source.width).toInt().coerceAtLeast(1)
        return Bitmap.createScaledBitmap(source, maxWidth, height, true)
    }

    companion object {
        private const val CHANNEL = "com.example.ironsight_ai/walkaround_frames"
    }
}
