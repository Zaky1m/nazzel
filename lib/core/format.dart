import 'small_caps.dart';

String formatBytes(num? bytes) {
  if (bytes == null || bytes <= 0) return '';
  const units = ['B', 'KB', 'MB', 'GB'];
  var value = bytes.toDouble();
  var i = 0;
  while (value >= 1024 && i < units.length - 1) {
    value /= 1024;
    i++;
  }
  final text = value >= 100 || i == 0 ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
  return '$text ${smallCaps(units[i])}';
}

String formatSpeed(double bytesPerSecond) =>
    bytesPerSecond <= 0 ? '' : '${formatBytes(bytesPerSecond)}${smallCaps('/s')}';

String formatDuration(num? seconds) {
  if (seconds == null || seconds <= 0) return '';
  final s = seconds.round();
  final h = s ~/ 3600;
  final m = (s % 3600) ~/ 60;
  final sec = s % 60;
  String two(int v) => v.toString().padLeft(2, '0');
  return h > 0 ? '$h:${two(m)}:${two(sec)}' : '${two(m)}:${two(sec)}';
}
