import 'package:flutter/foundation.dart';

/// Safe diagnostics for walkaround capture. Never logs media bytes, API keys,
/// user content, or filesystem paths.
typedef WalkaroundLogSink =
    void Function(String event, Map<String, Object?> fields);

abstract final class WalkaroundCaptureDiagnostics {
  static const String prefix = 'ironsight.walkaround';

  static WalkaroundLogSink sink = debugPrintSink;

  static void debugPrintSink(String event, Map<String, Object?> fields) {
    final parts = <String>[
      prefix,
      event,
      for (final entry in fields.entries) '${entry.key}=${entry.value}',
    ];
    debugPrint(parts.join(' '));
  }

  static void reset() {
    sink = debugPrintSink;
  }

  static void emit(String event, [Map<String, Object?> fields = const {}]) {
    final safe = <String, Object?>{};
    for (final entry in fields.entries) {
      if (_forbiddenKeys.contains(entry.key)) continue;
      safe[entry.key] = _sanitize(entry.value);
    }
    sink(event, safe);
  }

  static String pathKind(String path) {
    final lower = path.toLowerCase();
    if (lower.startsWith('content:')) return 'content_uri';
    if (lower.startsWith('file:')) return 'file_uri';
    if (path.startsWith('/')) return 'absolute_file';
    return 'other';
  }

  static bool looksLikeMp4(String path) {
    return path.toLowerCase().contains('.mp4');
  }

  static const Set<String> _forbiddenKeys = {
    'path',
    'localPath',
    'videoPath',
    'recordedPath',
    'sourceVideoPath',
    'bytes',
    'base64',
    'content_base64',
    'apiKey',
    'api_key',
    'token',
    'secret',
    'authorization',
    'email',
  };

  static Object? _sanitize(Object? value) {
    if (value == null || value is num || value is bool) return value;
    final text = value.toString();
    if (text.startsWith('/') ||
        text.contains('\\') ||
        text.startsWith('file:') ||
        text.startsWith('content:')) {
      return pathKind(text);
    }
    return text;
  }
}
