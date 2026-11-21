import 'package:flutter_test/flutter_test.dart';
import 'package:pocket_hq/core/theme/app_theme.dart';

void main() {
  test('AppTheme returns cached light and dark themes', () {
    final light1 = AppTheme.light();
    final light2 = AppTheme.light();
    final dark1 = AppTheme.dark();
    final dark2 = AppTheme.dark();

    expect(identical(light1, light2), isTrue);
    expect(identical(dark1, dark2), isTrue);
    expect(identical(light1, dark1), isFalse);
  });
}
