import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Flutter client sources do not contain vendor API keys', () {
    final roots = [Directory('lib'), Directory('test'), File('.env.example')];
    final forbidden = <RegExp>[
      RegExp(r'sk-[A-Za-z0-9]{10,}'),
      RegExp(r'OPENAI_API_KEY\s*='),
      RegExp(r'ANTHROPIC_API_KEY\s*='),
      RegExp(r'GEMINI_API_KEY\s*='),
    ];
    final dartFiles = <File>[
      for (final root in roots)
        if (root is File)
          root
        else
          ...Directory(root.path)
              .listSync(recursive: true)
              .whereType<File>()
              .where(
                (file) =>
                    file.path.endsWith('.dart') ||
                    file.path.endsWith('.example') ||
                    file.path.endsWith('.env.example'),
              ),
    ];

    for (final file in dartFiles) {
      final text = file.readAsStringSync();
      for (final pattern in forbidden) {
        expect(
          pattern.hasMatch(text),
          isFalse,
          reason: '${file.path} must not contain vendor API keys',
        );
      }
    }
  });
}
