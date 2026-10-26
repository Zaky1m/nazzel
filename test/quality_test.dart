import 'package:flutter_test/flutter_test.dart';
import 'package:nazzel/engine/models.dart';
import 'package:nazzel/ui/quality.dart';

QualityOption video(String id, int q) => QualityOption(id: id, kind: 'video', quality: q, label: '${q}p');
const audio = QualityOption(id: 'audio', kind: 'audio', quality: 0, label: 'audio');

void main() {
  group('extractUrl', () {
    test('finds the first link inside shared text', () {
      expect(extractUrl('Watch this https://www.facebook.com/share/r/1M abc'), 'https://www.facebook.com/share/r/1M');
    });
    test('drops trailing punctuation', () {
      expect(extractUrl('(https://youtu.be/x).'), 'https://youtu.be/x');
    });
    test('returns null without a link', () {
      expect(extractUrl('no link here'), isNull);
    });
  });

  group('pickQuality', () {
    final options = [video('q1080', 1080), video('q720', 720), video('q480', 480), audio];
    test('defaults to the best video', () => expect(pickQuality(options, null).id, 'q1080'));
    test('respects the saved limit', () => expect(pickQuality(options, '720').id, 'q720'));
    test('never goes above the limit', () => expect(pickQuality(options, '600').id, 'q480'));
    test('falls back to audio when there is no video', () => expect(pickQuality([audio], '720').id, 'audio'));
  });

  test('qualityLabel names options for people', () {
    expect(qualityLabel(audio), 'صوت فقط');
    expect(qualityLabel(const QualityOption(id: 'best', kind: 'video', quality: 0, label: 'best')), 'الأعلى');
    expect(qualityLabel(video('q720', 720)), '720ᴘ');
  });
}
