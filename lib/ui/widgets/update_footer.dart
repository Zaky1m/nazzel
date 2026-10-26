import 'package:flutter/material.dart';

import '../../core/strings.dart';
import '../../core/theme.dart';
import '../../engine/engine_api.dart';

/// Version line with a round check button, pinned under the settings list. It only reports whether a newer
/// version exists; installing it is up to the user.
class UpdateFooter extends StatefulWidget {
  const UpdateFooter({super.key, required this.version, required this.onMessage});

  final String version;
  final void Function(String text) onMessage;

  @override
  State<UpdateFooter> createState() => _UpdateFooterState();
}

class _UpdateFooterState extends State<UpdateFooter> {
  final _api = EngineApi.instance;
  bool _checking = false;
  String? _newVersion;

  @override
  void initState() {
    super.initState();
    _api.updateInfo().then((u) {
      if (mounted) setState(() => _newVersion = u?['version'] as String?);
    });
  }

  Future<void> _check() async {
    if (_checking) return;
    setState(() => _checking = true);
    try {
      final u = await _api.updateInfo(refresh: true);
      if (!mounted) return;
      setState(() => _newVersion = u?['version'] as String?);
      widget.onMessage(u == null ? S.upToDate : S.newVersion('${u['version']}'));
    } catch (_) {
      if (mounted) widget.onMessage(S.updateFailed);
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.nz;
    const size = 44.0;
    final found = _newVersion != null;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            button: true,
            label: S.checkUpdates,
            child: Material(
              color: p.raise,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: _check,
                child: SizedBox(
                  width: size,
                  height: size,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      if (_checking)
                        SizedBox(
                          width: size - 4,
                          height: size - 4,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: p.accent),
                        ),
                      Icon(Icons.refresh_rounded, color: _checking ? p.mute : p.text, size: 22),
                      if (found && !_checking)
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
          ),
          const SizedBox(height: 6),
          if (widget.version.isNotEmpty)
            Text(
              found ? S.newVersion(_newVersion!) : S.versionLabel(widget.version),
              style: TextStyle(color: found ? p.accent : p.mute, fontSize: 12),
            ),
          if (found) Text(S.versionLabel(widget.version), style: TextStyle(color: p.mute, fontSize: 11.5)),
        ],
      ),
    );
  }
}
