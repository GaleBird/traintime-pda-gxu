import 'package:flutter_test/flutter_test.dart';
import 'package:watermeter/repository/update_download_tracker.dart';

void main() {
  group('resolveAndroidDownloadRouteId', () {
    test('matches arm64 assets', () {
      expect(
        resolveAndroidDownloadRouteId('app-arm64-v8a-release.apk'),
        'arm64-v8a',
      );
    });

    test('returns null for unknown assets', () {
      expect(
        resolveAndroidDownloadRouteId('app-universal-release.apk'),
        isNull,
      );
    });

    test('does not treat x86_64 assets as x86', () {
      expect(resolveAndroidDownloadRouteId('app-x86_64-release.apk'), 'x86_64');
    });
  });

  group('buildAndroidDownloadCountUri', () {
    test('builds the official count endpoint', () {
      expect(
        buildAndroidDownloadCountUri('arm64-v8a').toString(),
        'https://gxu.app/api/downloads/arm64-v8a/count',
      );
    });

    test('rejects unsupported route ids', () {
      expect(
        () => buildAndroidDownloadCountUri('android'),
        throwsArgumentError,
      );
    });
  });
}
