import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:watermeter/repository/security/corrupted_cache_recovery.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('cache_recovery_test');
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('returns decoded cache when content is valid', () {
    final file = File('${tempDir.path}/valid.json')
      ..writeAsStringSync('{"value": 1}');

    final result = loadRecoverableCache<Map<String, dynamic>>(
      label: 'test_valid',
      file: file,
      readRawText: file.readAsStringSync,
      decode: (rawText) => jsonDecode(rawText) as Map<String, dynamic>,
    );

    expect(result, isNotNull);
    expect(result?['value'], 1);
    expect(file.existsSync(), isTrue);
  });

  test('deletes corrupted cache and returns null', () {
    final file = File('${tempDir.path}/corrupted.json')
      ..writeAsStringSync('not-json');

    final result = loadRecoverableCache<Map<String, dynamic>>(
      label: 'test_corrupted',
      file: file,
      readRawText: file.readAsStringSync,
      decode: (rawText) => jsonDecode(rawText) as Map<String, dynamic>,
    );

    expect(result, isNull);
    expect(file.existsSync(), isFalse);
  });
}
