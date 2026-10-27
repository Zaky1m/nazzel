import 'package:flutter/material.dart';

import '../core/format.dart';
import '../core/small_caps.dart';
import '../core/strings.dart';
import '../core/theme.dart';
import '../engine/engine_api.dart';
import 'quality.dart';
import 'widgets/common.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.active});

  /// True while the settings tab is on screen; the log count is re-read each time it becomes true.
  final bool active;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _api = EngineApi.instance;
  String _quality = 'best';
  bool _ask = true;
  Map<String, dynamic> _stats = const {};
  String _version = '';
  String _location = '';
  String? _newVersion;
  bool _store = false;
  bool _checking = false;

  static const _choices = ['best', '720', '480', '360'];

  @override
  void didUpdateWidget(SettingsPage old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) {
      _refreshStats();
    }
  }

  @override
  void initState() {
    super.initState();
    _refreshStats();
    _api.appInfo().then((i) {
      if (mounted) {
        setState(() {
          _version = i['version'] as String? ?? '';
          _store = i['store'] == true;
        });
      }
    });
    _api.updateInfo().then((u) {
      if (mounted) setState(() => _newVersion = u?['version'] as String?);
    });
    _api.saveLocation().then((l) {
      if (mounted) setState(() => _location = l);
    });
    _api.getPref('ask_quality').then((v) {
      if (mounted && v == '0') setState(() => _ask = false);
    });
    _api.getPref('default_quality').then((v) {
      if (mounted && v != null && _choices.contains(v)) setState(() => _quality = v);
    });
  }

  Future<void> _refreshStats() async {
    final st = await _api.stats();
    if (mounted) setState(() => _stats = st);
  }

  Future<void> _pickLocation() async {
    final label = await _api.pickFolder();
    if (label == null || !mounted) return;
    setState(() => _location = label);
    _toast(S.locationChanged);
  }

  Future<void> _resetLocation() async {
    final label = await _api.resetSaveLocation();
    if (mounted) setState(() => _location = label);
  }

  Widget _statsCard(NzPalette p) {
    final lifetime = (_stats['lifetime'] as num?)?.toInt() ?? 0;
    final saved = (_stats['saved'] as num?)?.toInt() ?? 0;
    final bytes = formatBytes(_stats['bytes'] as num?);
    return SurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      child: Column(
        children: [
          _row(p, S.statsLifetime, '$lifetime', divider: true),
          _row(p, S.statsSaved, bytes.isEmpty ? '$saved' : '$saved · $bytes'),
        ],
      ),
    );
  }

  Future<void> _checkVersion() async {
    if (_checking) return;
    setState(() => _checking = true);
    try {
      // The spin lasts a moment even when the answer is instant, so the tap is seen.
      final results = await Future.wait([
        _api.updateInfo(refresh: true),
        Future<void>.delayed(const Duration(milliseconds: 700)),
      ]);
      final u = results.first as Map<String, dynamic>?;
      if (!mounted) return;
      setState(() => _newVersion = u?['version'] as String?);
      _toast(u == null ? S.upToDate : S.newVersion('${u['version']}'));
    } catch (_) {
      if (mounted) _toast(S.checkFailed);
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  void _toast(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  String _label(String c) => c == 'best' ? S.bestQuality : '$c${smallCaps('p')}';

  Widget _section(NzPalette p, String title) => Padding(
    padding: const EdgeInsets.fromLTRB(6, 18, 6, 8),
    child: Text(
      title,
      style: TextStyle(color: p.mute, fontSize: 12.5, fontWeight: FontWeight.w600),
    ),
  );

  Widget _title(NzPalette p, String text) => Text(
    text,
    style: TextStyle(fontWeight: FontWeight.w600, color: p.text),
  );

  @override
  Widget build(BuildContext context) {
    final p = context.nz;
    final custom = _location.isNotEmpty && _location != 'Download/Nazzel';
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PageHeader(title: S.settings),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              children: [
                _section(p, S.sectionDownloads),
                SurfaceCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _title(p, S.defaultQuality),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                for (final c in _choices)
                                  QualityChip(
                                    label: _label(c),
                                    selected: _quality == c,
                                    onTap: () {
                                      setState(() => _quality = c);
                                      _api.setPref('default_quality', c);
                                    },
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Divider(height: 1, color: p.line),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _title(p, S.askQuality),
                                  const SizedBox(height: 2),
                                  Text(
                                    _ask ? S.askQualityOn : S.askQualityOff,
                                    style: TextStyle(color: p.mute, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: _ask,
                              activeThumbColor: p.onAccent,
                              activeTrackColor: p.accent,
                              onChanged: (v) {
                                setState(() => _ask = v);
                                _api.setPref('ask_quality', v ? '1' : '0');
                              },
                            ),
                          ],
                        ),
                      ),
                      Divider(height: 1, color: p.line),
                      InkWell(
                        onTap: _pickLocation,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _title(p, S.saveLocation),
                                    const SizedBox(height: 2),
                                    Text(
                                      _location.isEmpty ? '…' : _location,
                                      textDirection: TextDirection.ltr,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(color: p.mute, fontSize: 12),
                                    ),
                                  ],
                                ),
                              ),
                              if (custom)
                                TextButton(
                                  onPressed: _resetLocation,
                                  child: Text(S.resetLocation, style: TextStyle(color: p.accent, fontSize: 12.5)),
                                )
                              else
                                Icon(Icons.folder_open_rounded, color: p.mute, size: 20),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                _section(p, S.sectionStats),
                _statsCard(p),
                _section(p, S.sectionAbout),
                SurfaceCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(S.aboutPrivacy, style: TextStyle(color: p.text, fontSize: 13, height: 1.5)),
                      const SizedBox(height: 8),
                      Text(S.aboutRights, style: TextStyle(color: p.mute, fontSize: 12.5, height: 1.5)),
                    ],
                  ),
                ),
                _versionLine(p),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _versionLine(NzPalette p) => Padding(
    padding: const EdgeInsets.fromLTRB(0, 24, 0, 8),
    child: Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_version.isNotEmpty) Text(S.versionLabel(_version), style: TextStyle(color: p.mute, fontSize: 12)),
            if (!_store)
              Semantics(
                button: true,
                label: S.checkUpdates,
                child: InkResponse(
                  onTap: _checkVersion,
                  radius: 20,
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: _SpinIcon(spinning: _checking, color: p.mute),
                  ),
                ),
              ),
          ],
        ),
        if (_newVersion != null)
          Text(
            S.newVersion(_newVersion!),
            style: TextStyle(color: p.accent, fontSize: 12, fontWeight: FontWeight.w600),
          ),
      ],
    ),
  );

  Widget _row(NzPalette p, String label, String value, {bool divider = false}) => Container(
    padding: const EdgeInsets.symmetric(vertical: 12),
    decoration: BoxDecoration(
      border: divider ? Border(bottom: BorderSide(color: p.line)) : null,
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(label, style: TextStyle(color: p.text)),
        ),
        const SizedBox(width: 12),
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: p.mute, fontSize: 13),
            textDirection: TextDirection.ltr,
          ),
        ),
      ],
    ),
  );
}

class _SpinIcon extends StatefulWidget {
  const _SpinIcon({required this.spinning, required this.color});
  final bool spinning;
  final Color color;

  @override
  State<_SpinIcon> createState() => _SpinIconState();
}

class _SpinIconState extends State<_SpinIcon> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));

  @override
  void didUpdateWidget(_SpinIcon old) {
    super.didUpdateWidget(old);
    if (widget.spinning && !_c.isAnimating) {
      _c.repeat();
    } else if (!widget.spinning) {
      _c.stop();
      _c.value = 0;
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => RotationTransition(
    turns: _c,
    child: Icon(Icons.refresh_rounded, size: 18, color: widget.color),
  );
}
