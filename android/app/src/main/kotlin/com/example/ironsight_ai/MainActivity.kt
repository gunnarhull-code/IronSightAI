package com.example.ironsight_ai

import android.graphics.Bitmap
import android.media.MediaMetadataRetriever
import android.net.Uri
import android.os.Handler
import android.os.Looper
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.ByteArrayOutputStream
import java.io.File
import java.io.FileInputStream

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
                    Thread {
                        try {
                            val bytes = extractJpegFrame(path, timeMs, maxWidth, quality)
                            MAIN.post {
                                result.success(bytes)
                            }
                        } catch (error: Exception) {
                            Log.i(
                                TAG,
                                "extract_failed type=${error.javaClass.simpleName} timeMs=$timeMs",
                            )
                            MAIN.post {
                                result.error(
                                    "extract_failed",
                                    error.javaClass.simpleName,
                                    null,
                                )
                            }
                        }
                    }.start()
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun extractJpegFrame(
        rawPath: String,
        timeMs: Long,
        maxWidth: Int,
        quality: Int,
    ): ByteArray? {
        val path = normalizePath(rawPath)
        val file = File(path)
        val exists = file.isFile
        val size = if (exists) file.length() else 0L
        Log.i(TAG, "extract exists=$exists byteSize=$size looksLikeMp4=${path.lowercase().contains(".mp4")} timeMs=$timeMs")
        if (!exists || size <= 0L) return null

        val retriever = MediaMetadataRetriever()
        var stream: FileInputStream? = null
        try {
            stream = openRetriever(retriever, file, rawPath)
            val micros = timeMs.coerceAtLeast(0L) * 1000L
            val bitmap =
                retriever.getFrameAtTime(micros, MediaMetadataRetriever.OPTION_CLOSEST_SYNC)
                    ?: retriever.getFrameAtTime(micros, MediaMetadataRetriever.OPTION_CLOSEST)
                    ?: retriever.getFrameAtTime(0L, MediaMetadataRetriever.OPTION_CLOSEST)
                    ?: return null
            val scaled = scaleBitmap(bitmap, maxWidth)
            if (scaled !== bitmap) {
                bitmap.recycle()
            }
            val jpegStream = ByteArrayOutputStream()
            scaled.compress(Bitmap.CompressFormat.JPEG, quality, jpegStream)
            scaled.recycle()
            val jpeg = jpegStream.toByteArray()
            Log.i(TAG, "extract_ok jpegBytes=${jpeg.size} timeMs=$timeMs")
            return jpeg
        } finally {
            try {
                retriever.release()
            } catch (_: Exception) {
                // Best-effort release.
            }
            try {
                stream?.close()
            } catch (_: Exception) {
                // Best-effort close after retriever.release().
            }
        }
    }

    private fun openRetriever(
        retriever: MediaMetadataRetriever,
        file: File,
        rawPath: String,
    ): FileInputStream? {
        var lastError: Exception? = null
        repeat(3) { attempt ->
            val stream = FileInputStream(file)
            try {
                retriever.setDataSource(stream.fd)
                return stream
            } catch (error: Exception) {
                lastError = error
                Log.i(TAG, "setDataSource_fd_failed attempt=$attempt type=${error.javaClass.simpleName}")
                try {
                    stream.close()
                } catch (_: Exception) {
                }
                try {
                    retriever.setDataSource(file.absolutePath)
                    return null
                } catch (pathError: Exception) {
                    lastError = pathError
                }
                if (rawPath.startsWith("content:", ignoreCase = true)) {
                    retriever.setDataSource(this, Uri.parse(rawPath))
                    return null
                }
                Thread.sleep(150L * (attempt + 1))
            }
        }
        throw lastError ?: IllegalStateException("retriever_unopened")
    }

    private fun normalizePath(path: String): String {
        return if (path.startsWith("file:", ignoreCase = true)) {
            Uri.parse(path).path ?: path
        } else {
            path
        }
    }

    private fun scaleBitmap(source: Bitmap, maxWidth: Int): Bitmap {
        if (maxWidth <= 0 || source.width <= maxWidth) return source
        val height = (source.height.toDouble() * maxWidth / source.width).toInt().coerceAtLeast(1)
        return Bitmap.createScaledBitmap(source, maxWidth, height, true)
    }

    companion object {
        private const val CHANNEL = "com.example.ironsight_ai/walkaround_frames"
        private const val TAG = "IronsightWalkaround"
        private val MAIN = Handler(Looper.getMainLooper())
    }
}
