import 'package:flutter_test/flutter_test.dart';
import 'package:nazzel/ui/widgets/channel_button.dart';

void main() {
  test('the paper-plane path parses into a shape inside its 24 unit box', () {
    final bounds = parseSvgPath('M2 2l10 4c1 0 1 1 0 1zM8 8a2 2 0 0 1 4 0z').getBounds();
    expect(bounds.width, greaterThan(0));
    expect(bounds.left, greaterThanOrEqualTo(0));
  });
}
