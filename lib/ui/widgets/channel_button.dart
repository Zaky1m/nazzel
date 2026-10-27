import 'package:flutter/material.dart';

import '../../core/strings.dart';
import '../../engine/engine_api.dart';

const _tgBlue = Color(0xFF229ED9);
const _iconSize = 52.0;
const _openWidth = 252.0;
const _total = Duration(seconds: 5);

// Shared by every button, so the one on the other tab is in the same moment of the animation.
final _epoch = DateTime.now();

/// Round Telegram button at the bottom right. For five seconds after the app opens it grows to the left into a pill
/// with a line of text, then folds back into the icon and stays.
class ChannelButton extends StatefulWidget {
  const ChannelButton({super.key});

  @override
  State<ChannelButton> createState() => _ChannelButtonState();
}

class _ChannelButtonState extends State<ChannelButton> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: _total);
  static const _ease = Cubic(.65, 0, .25, 1);

  @override
  void initState() {
    super.initState();
    final done = DateTime.now().difference(_epoch).inMilliseconds / _total.inMilliseconds;
    _c.value = done.clamp(0.0, 1.0);
    if (done < 1) _c.forward();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  double _width(double t) {
    if (t <= .05) return _iconSize;
    if (t <= .18) return _iconSize + (_openWidth - _iconSize) * _ease.transform((t - .05) / .13);
    if (t <= .78) return _openWidth;
    return _openWidth - (_openWidth - _iconSize) * _ease.transform((t - .78) / .22);
  }

  double _labelOpacity(double t) {
    if (t <= .12) return 0;
    if (t <= .22) return (t - .12) / .10;
    if (t <= .76) return 1;
    if (t <= .87) return 1 - (t - .76) / .11;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.of(context).disableAnimations;
    return Semantics(
      button: true,
      label: S.channelJoin,
      child: GestureDetector(
        onTap: () => EngineApi.instance.openLink(S.channelUrl),
        child: SizedBox(
          width: _openWidth,
          height: _iconSize,
          child: Directionality(
            textDirection: TextDirection.ltr,
            child: AnimatedBuilder(
              animation: _c,
              builder: (_, _) {
                final t = reduce ? 1.0 : _c.value;
                final opacity = _labelOpacity(t);
                return Stack(
                  children: [
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: _width(t),
                        height: _iconSize,
                        clipBehavior: Clip.hardEdge,
                        decoration: BoxDecoration(color: _tgBlue, borderRadius: BorderRadius.circular(_iconSize / 2)),
                        child: Stack(
                          children: [
                            Positioned(
                              right: 60,
                              top: 0,
                              bottom: 0,
                              child: Opacity(
                                opacity: opacity,
                                child: Transform.translate(
                                  offset: Offset(12 * (1 - opacity), 0),
                                  child: const Center(
                                    child: Text(
                                      S.channelJoin,
                                      textDirection: TextDirection.rtl,
                                      softWrap: false,
                                      style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Positioned(right: 0, top: 0, child: _PlaneIcon()),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _PlaneIcon extends StatelessWidget {
  const _PlaneIcon();

  @override
  Widget build(BuildContext context) => const SizedBox(
    width: _iconSize,
    height: _iconSize,
    child: DecoratedBox(
      decoration: BoxDecoration(color: _tgBlue, shape: BoxShape.circle),
      child: Center(
        child: CustomPaint(size: Size(25, 25), painter: _PlanePainter()),
      ),
    ),
  );
}

// The 24x24 paper-plane outline as an SVG path, drawn without an SVG package.
const _planePath =
    'M21.944 4.585a1.52 1.52 0 0 0-2.1-1.72L2.45 9.65c-1.25.49-1.23 1.18-.23 1.49l4.46 1.39 1.73 5.43c.21.59.11.83.73.83.48 0 '
    '.69-.22.96-.49l2.32-2.25 4.82 3.56c.89.49 1.53.24 1.75-.83l2.95-14.2ZM8.1 12.21l10.53-6.64c.53-.32 1.02-.15.62.21l-8.99 '
    '8.11-.35 3.75-1.81-5.43Z';

class _PlanePainter extends CustomPainter {
  const _PlanePainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 24, size.height / 24);
    canvas.drawPath(parseSvgPath(_planePath), Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_PlanePainter old) => false;
}

/// Minimal SVG path reader: M, L, C and A (absolute or relative) and Z, which is all the icon above uses.
Path parseSvgPath(String d) {
  final path = Path();
  final tokens = RegExp(r'[MmLlCcAaZz]|-?(?:\d+\.?\d*|\.\d+)').allMatches(d).map((m) => m.group(0)!).toList();
  var i = 0;
  var cmd = 'M';
  double x = 0, y = 0, startX = 0, startY = 0;
  double num() => double.parse(tokens[i++]);
  bool isCmd(String t) => RegExp(r'^[A-Za-z]$').hasMatch(t);
  while (i < tokens.length) {
    if (isCmd(tokens[i])) cmd = tokens[i++];
    final rel = cmd == cmd.toLowerCase();
    switch (cmd.toUpperCase()) {
      case 'M':
        final nx = num() + (rel ? x : 0), ny = num() + (rel ? y : 0);
        path.moveTo(nx, ny);
        x = startX = nx;
        y = startY = ny;
        cmd = rel ? 'l' : 'L';
      case 'L':
        final nx = num() + (rel ? x : 0), ny = num() + (rel ? y : 0);
        path.lineTo(nx, ny);
        x = nx;
        y = ny;
      case 'C':
        final ox = rel ? x : 0.0, oy = rel ? y : 0.0;
        final x1 = num() + ox, y1 = num() + oy, x2 = num() + ox, y2 = num() + oy, nx = num() + ox, ny = num() + oy;
        path.cubicTo(x1, y1, x2, y2, nx, ny);
        x = nx;
        y = ny;
      case 'A':
        final rx = num(), ry = num(), rot = num(), large = num(), sweep = num();
        final nx = num() + (rel ? x : 0), ny = num() + (rel ? y : 0);
        path.arcToPoint(
          Offset(nx, ny),
          radius: Radius.elliptical(rx, ry),
          rotation: rot,
          largeArc: large != 0,
          clockwise: sweep != 0,
        );
        x = nx;
        y = ny;
      case 'Z':
        path.close();
        x = startX;
        y = startY;
    }
  }
  return path;
}
