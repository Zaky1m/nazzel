import 'package:flutter/material.dart';

import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../engine/engine_api.dart';

enum _Phase { idle, checking, downloading, done }

/// Version line with a round update button, pinned under the settings list. Tapping it checks for an update and, when
/// one exists, downloads it while the button slides to the left edge and turns into a progress ring.
class UpdateFooter extends StatefulWidget {
  const UpdateFooter({super.key, required this.version, required this.onMessage});

  final String version;
  final void Function(String text) onMessage;

  @override
  State<UpdateFooter> createState() => _UpdateFooterState();
}

class _UpdateFooterState extends State<UpdateFooter> {
  final _api = EngineApi.instance;
  _Phase _phase = _Phase.idle;
  bool _available = false;
  String _newVersion = '';

  @override
  void initState() {
    super.initState();
    _api.updateInfo().then((u) {
      if (mounted) setState(() => _available = u != null);
    });
  }

  Future<void> _tap() async {
    if (_phase != _Phase.idle) return;
    setState(() => _phase = _Phase.checking);
    Map<String, dynamic>? update;
    try {
      update = await _api.updateInfo(refresh: true);
    } catch (_) {
      if (!mounted) return;
      setState(() => _phase = _Phase.idle);
      widget.onMessage(S.updateFailed);
      return;
    }
    if (!mounted) return;
    if (update == null) {
      setState(() {
        _phase = _Phase.idle;
        _available = false;
      });
      widget.onMessage(S.upToDate);
      return;
    }
    _newVersion = '${update['version']}';
    _available = true;
    widget.onMessage(S.downloadingUpdate(_newVersion));
    setState(() => _phase = _Phase.downloading);
    try {
      final status = await _api.installUpdate();
      if (!mounted) return;
      if (status == 'permission') {
        setState(() => _phase = _Phase.idle);
        widget.onMessage(S.allowInstall);
        return;
      }
      setState(() => _phase = _Phase.done);
      await Future<void>.delayed(const Duration(milliseconds: 1600));
    } catch (_) {
      if (mounted) widget.onMessage(S.updateFailed);
    }
    if (mounted) setState(() => _phase = _Phase.idle);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.nz;
    final busy = _phase == _Phase.downloading || _phase == _Phase.done;
    // Physical left/center regardless of text direction, so the button always travels to the same edge.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 52,
              child: Stack(
                children: [
                  AnimatedAlign(
                    duration: const Duration(milliseconds: 380),
                    curve: Curves.easeInOutCubic,
                    alignment: busy ? Alignment.centerLeft : Alignment.center,
                    child: _circle(p),
                  ),
                  Positioned.fill(
                    left: 64,
                    child: IgnorePointer(
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 250),
                        opacity: busy ? 1 : 0,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: ValueListenableBuilder<int?>(
                            valueListenable: _api.updateProgress,
                            builder: (_, pct, _) => Directionality(
                              textDirection: TextDirection.rtl,
                              child: Text(
                                _phase == _Phase.done ? S.updateReady : S.updateProgress(_newVersion, pct ?? 0),
                                style: TextStyle(color: _phase == _Phase.done ? p.ok : p.text, fontSize: 13),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            if (widget.version.isNotEmpty)
              Directionality(
                textDirection: TextDirection.rtl,
                child: Text(
                  _available && !busy
                      ? '${S.versionLabel(widget.version)} · ${S.updateAvailableShort}'
                      : S.versionLabel(widget.version),
                  style: TextStyle(color: _available && !busy ? p.accent : p.mute, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _circle(NzPalette p) {
    const size = 44.0;
    final Widget inner;
    switch (_phase) {
      case _Phase.done:
        inner = Icon(Icons.check_rounded, color: p.ok, size: 22);
      case _Phase.downloading:
        inner = ValueListenableBuilder<int?>(
          valueListenable: _api.updateProgress,
          builder: (_, pct, _) => Text(
            '${pct ?? 0}',
            style: TextStyle(color: p.text, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        );
      default:
        inner = Icon(Icons.refresh_rounded, color: p.text, size: 22);
    }
    return Semantics(
      button: true,
      label: S.checkUpdates,
      child: Material(
        color: p.raise,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: _tap,
          child: SizedBox(
            width: size,
            height: size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (_phase == _Phase.checking)
                  SizedBox(
                    width: size - 4,
                    height: size - 4,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: p.accent),
                  ),
                if (_phase == _Phase.downloading)
                  ValueListenableBuilder<int?>(
                    valueListenable: _api.updateProgress,
                    builder: (_, pct, _) => SizedBox(
                      width: size - 4,
                      height: size - 4,
                      child: CircularProgressIndicator(
                        value: (pct ?? 0) / 100,
                        strokeWidth: 2.5,
                        color: p.accent,
                        backgroundColor: p.line,
                      ),
                    ),
                  ),
                if (_phase == _Phase.checking) Icon(Icons.refresh_rounded, color: p.mute, size: 20) else inner,
                if (_available && _phase == _Phase.idle)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: p.accent,
                        shape: BoxShape.circle,
                        border: Border.all(color: p.raise, width: 1.5),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
