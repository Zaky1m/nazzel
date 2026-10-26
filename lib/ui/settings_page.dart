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
  int _logCount = 0;
  Map<String, dynamic> _stats = const {};
  String _version = '';
  String _location = '';
  String? _newVersion;

  static const _choices = ['best', '720', '480', '360'];

  @override
  void didUpdateWidget(SettingsPage old) {
    super.didUpdateWidget(old);
    if (widget.active && !old.active) {
      _refreshLog();
      _refreshStats();
    }
  }

  @override
  void initState() {
    super.initState();
    _refreshLog();
    _refreshStats();
    _api.appInfo().then((i) {
      if (mounted) setState(() => _version = i['version'] as String? ?? '');
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

  Future<void> _refreshLog() async {
    final n = await _api.logCount();
    if (mounted) setState(() => _logCount = n);
  }

  void _toast(String text) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

  Future<void> _export(bool share) async {
    try {
      final path = await _api.exportLog(share: share);
      if (mounted && path != null) _toast(path);
    } catch (_) {
      if (mounted) _toast(S.logFailed);
    }
  }

  Future<void> _clear() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text(S.logClear),
        content: const Text(S.logHint),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text(S.keep)),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text(S.logClear)),
        ],
      ),
    );
    if (ok != true) return;
    await _api.clearLog();
    await _refreshLog();
    if (mounted) _toast(S.logCleared);
  }

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
    final custom = _location.isNotEmpty && _location != 'Movies/Nazzel';
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
                _section(p, S.sectionSupport),
                SurfaceCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: _title(p, S.logTitle)),
                          Text(
                            _logCount == 0 ? S.logEmpty : '$_logCount',
                            style: TextStyle(color: p.mute, fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(S.logHint, style: TextStyle(color: p.mute, fontSize: 12)),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          SoftButton(label: S.logSave, icon: Icons.save_alt_rounded, onTap: () => _export(false)),
                          SoftButton(label: S.logShare, icon: Icons.share_outlined, onTap: () => _export(true)),
                          SoftButton(label: S.logClear, icon: Icons.delete_sweep_outlined, onTap: _clear),
                        ],
                      ),
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
    padding: const EdgeInsets.fromLTRB(0, 28, 0, 8),
    child: Column(
      children: [
        if (_version.isNotEmpty) Text(S.versionLabel(_version), style: TextStyle(color: p.mute, fontSize: 12)),
        if (_newVersion != null) ...[
          const SizedBox(height: 2),
          Text(
            S.newVersion(_newVersion!),
            style: TextStyle(color: p.accent, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
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
