import 'package:flutter/foundation.dart';

/// Safe structured diagnostics for the AI Media Review provider path.
///
/// Never logs media bytes, prompts, API keys, tokens, provider content,
/// filesystem paths, or user-identifying fields.
class AiReviewDiagnostics {
  AiReviewDiagnostics._();

  static const String logPrefix = 'ironsight.ai_review';

  static void Function(String line) sink = debugPrint;

  static const Set<String> _forbiddenKeys = {
    'path',
    'file_path',
    'filepath',
    'localpath',
    'videopath',
    'bytes',
    'base64',
    'content',
    'content_base64',
    'prompt',
    'messages',
    'api_key',
    'apikey',
    'token',
    'secret',
    'authorization',
    'email',
    'user_id',
    'image_data',
    'body',
    'response',
  };

  static void reset() {
    sink = debugPrint;
  }

  static Map<String, Object?> sanitize(Map<String, Object?> fields) {
    final sanitized = <String, Object?>{};
    for (final entry in fields.entries) {
      final key = entry.key.toLowerCase();
      if (_forbiddenKeys.contains(key)) {
        continue;
      }
      if (key.contains('path') ||
          key.contains('byte') ||
          key.contains('base64') ||
          key.contains('token') ||
          key.contains('secret') ||
          key.contains('prompt') ||
          key.contains('content') ||
          key.contains('auth') ||
          key.contains('message')) {
        continue;
      }
      final value = entry.value;
      if (value is String && _looksLikePath(value)) {
        continue;
      }
      sanitized[entry.key] = value;
    }
    return sanitized;
  }

  static String formatLine({
    required String requestId,
    required String stage,
    Map<String, Object?> fields = const {},
  }) {
    final parts = <String>[logPrefix, 'request_id=$requestId', 'stage=$stage'];
    sanitize(fields).forEach((key, value) {
      parts.add('$key=$value');
    });
    return parts.join(' ');
  }

  static void emit({
    required String requestId,
    required String stage,
    Map<String, Object?> fields = const {},
  }) {
    sink(formatLine(requestId: requestId, stage: stage, fields: fields));
  }

  static bool _looksLikePath(String value) {
    return value.startsWith('/') ||
        value.startsWith('file:') ||
        value.startsWith('content:') ||
        value.contains('\\');
  }
}
