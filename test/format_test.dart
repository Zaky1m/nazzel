import 'package:flutter_test/flutter_test.dart';
import 'package:nazzel/core/format.dart';
import 'package:nazzel/core/small_caps.dart';

void main() {
  test('smallCaps maps latin letters and leaves the rest', () {
    expect(smallCaps('MB/s'), 'ᴍʙ/ѕ');
    expect(smallCaps('720p'), '720ᴘ');
    expect(smallCaps('نزّل'), 'نزّل');
  });

  test('formatBytes picks a unit and keeps one decimal below 100', () {
    expect(formatBytes(null), '');
    expect(formatBytes(512), '512 ʙ');
    expect(formatBytes(19293798), '18.4 ᴍʙ');
    expect(formatBytes(734003200), '700 ᴍʙ');
  });

  test('formatDuration uses hours only when needed', () {
    expect(formatDuration(59), '00:59');
    expect(formatDuration(161.4), '02:41');
    expect(formatDuration(3725), '1:02:05');
    expect(formatDuration(0), '');
  });
}
