import 'package:flutter/material.dart';

/// The Nazzel mark: the letter noon drawn as a bowl with a download arrow dropping into it.
class Glyph extends StatelessWidget {
  const Glyph({super.key, required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => CustomPaint(size: Size.square(size), painter: _GlyphPainter(color));
}

class _GlyphPainter extends CustomPainter {
  _GlyphPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final k = size.width / 100;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.5 * k
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final bowl = Path()
      ..moveTo(24 * k, 48 * k)
      ..cubicTo(24 * k, 74 * k, 37 * k, 84 * k, 50 * k, 84 * k)
      ..cubicTo(63 * k, 84 * k, 76 * k, 74 * k, 76 * k, 48 * k);
    final arrow = Path()
      ..moveTo(50 * k, 15 * k)
      ..lineTo(50 * k, 57 * k)
      ..moveTo(34 * k, 41 * k)
      ..lineTo(50 * k, 57 * k)
      ..lineTo(66 * k, 41 * k);
    canvas
      ..drawPath(bowl, paint)
      ..drawPath(arrow, paint);
  }

  @override
  bool shouldRepaint(_GlyphPainter old) => old.color != color;
}

class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.size = 28});
  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(color: const Color(0xFF1F5BFF), borderRadius: BorderRadius.circular(size * 0.225)),
    child: Glyph(size: size, color: Colors.white),
  );
}
