import 'package:flutter_test/flutter_test.dart';
import 'package:watermeter/repository/update_build_number.dart';

void main() {
  group('normalizeBuildNumberForUpdateComparison', () {
    test('keeps non-android build numbers unchanged', () {
      final normalized = normalizeBuildNumberForUpdateComparison(
        rawBuild: 43,
        isAndroid: false,
      );

      expect(normalized, 43);
    });

    test('keeps regular android build numbers unchanged', () {
      final normalized = normalizeBuildNumberForUpdateComparison(
        rawBuild: 43,
        isAndroid: true,
      );

      expect(normalized, 43);
    });

    test('keeps three-digit non-split android build numbers unchanged', () {
      final normalized = normalizeBuildNumberForUpdateComparison(
        rawBuild: 101,
        isAndroid: true,
      );

      expect(normalized, 101);
    });

    test('normalizes split android build numbers to the base build', () {
      final normalized = normalizeBuildNumberForUpdateComparison(
        rawBuild: 433,
        isAndroid: true,
      );

      expect(normalized, 43);
    });

    test('normalizes larger split android build numbers to the base build', () {
      final normalized = normalizeBuildNumberForUpdateComparison(
        rawBuild: 1003,
        isAndroid: true,
      );

      expect(normalized, 100);
    });
  });
}
