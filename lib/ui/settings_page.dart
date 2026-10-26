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
  Map<String, dynamic>? _update;
  bool _checking = false;

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
      if (mounted) setState(() => _update = u);
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

  Future<void> _checkUpdate() async {
    setState(() => _checking = true);
    try {
      final u = await _api.updateInfo(refresh: true);
      if (mounted) setState(() => _update = u);
      if (mounted && u == null) _toast(S.upToDate);
    } catch (_) {
      if (mounted) _toast(S.updateFailed);
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _install() async {
    try {
      final status = await _api.installUpdate();
      if (mounted && status == 'permission') _toast(S.allowInstall);
    } catch (_) {
      if (mounted) _toast(S.updateFailed);
    }
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

  Widget _updatesCard(NzPalette p) {
    final update = _update;
    return SurfaceCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  S.updatesTitle,
                  style: TextStyle(fontWeight: FontWeight.w600, color: p.text),
                ),
              ),
              if (_version.isNotEmpty) Text(S.versionLabel(_version), style: TextStyle(color: p.mute, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 6),
          if (update == null)
            Text(S.upToDate, style: TextStyle(color: p.mute, fontSize: 12.5))
          else ...[
            Text(
              S.newVersion('${update['version']}'),
              style: TextStyle(color: p.accent, fontWeight: FontWeight.w600),
            ),
            if ((update['notes'] as String? ?? '').isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(update['notes'] as String, style: TextStyle(color: p.mute, fontSize: 12.5)),
              ),
          ],
          const SizedBox(height: 12),
          ValueListenableBuilder<int?>(
            valueListenable: _api.updateProgress,
            builder: (_, pct, _) {
              if (pct != null) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: pct / 100,
                    minHeight: 6,
                    color: p.accent,
                    backgroundColor: p.raise,
                  ),
                );
              }
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (update != null)
                    SoftButton(
                      label: [
                        S.updateNow,
                        if (formatBytes(update['size'] as num?).isNotEmpty) formatBytes(update['size'] as num?),
                      ].join(' · '),
                      icon: Icons.system_update_rounded,
                      onTap: _install,
                    ),
                  SoftButton(
                    label: S.checkUpdates,
                    icon: Icons.refresh_rounded,
                    onTap: _checking ? () {} : _checkUpdate,
                  ),
                ],
              );
            },
          ),
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

  @override
  Widget build(BuildContext context) {
    final p = context.nz;
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PageHeader(title: S.settings),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              children: [
                SurfaceCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        S.defaultQuality,
                        style: TextStyle(fontWeight: FontWeight.w600, color: p.text),
                      ),
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
                const SizedBox(height: 12),
                SurfaceCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              S.askQuality,
                              style: TextStyle(fontWeight: FontWeight.w600, color: p.text),
                            ),
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
                const SizedBox(height: 12),
                SurfaceCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  child: Column(
                    children: [
                      _row(p, S.saveLocation, 'Movies/Nazzel', divider: true),
                      _row(p, S.tempCleanup, S.tempCleanupValue),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _statsCard(p),
                const SizedBox(height: 12),
                _updatesCard(p),
                const SizedBox(height: 12),
                SurfaceCard(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              S.logTitle,
                              style: TextStyle(fontWeight: FontWeight.w600, color: p.text),
                            ),
                          ),
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
              ],
            ),
          ),
        ],
      ),
    );
  }

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
