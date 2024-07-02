import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('review CLI command runs successfully', () async {
    final result = await Process.run('dart', ['bin/review.dart', '0']);

    expect(result.exitCode, equals(0));
    expect(result.stderr, isEmpty);
  });
}
