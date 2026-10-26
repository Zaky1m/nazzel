import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/format.dart';
import '../core/strings.dart';
import '../core/theme.dart';
import '../engine/engine_api.dart';
import '../engine/models.dart';
import 'widgets/common.dart';

class DownloadsPage extends StatefulWidget {
  const DownloadsPage({super.key});

  @override
  State<DownloadsPage> createState() => _DownloadsPageState();
}

class _DownloadsPageState extends State<DownloadsPage> {
  final _api = EngineApi.instance;
  List<DownloadItem> _items = const [];
  int _tab = 0;

  @override
  void initState() {
    super.initState();
    _api.changes.addListener(_reload);
    _reload();
  }

  @override
  void dispose() {
    _api.changes.removeListener(_reload);
    super.dispose();
  }

  Future<void> _reload() async {
    final items = await _api.list();
    if (mounted) setState(() => _items = items);
  }

  List<DownloadItem> get _visible => switch (_tab) {
    1 => _items.where((i) => i.isRunning).toList(),
    2 => _items.where((i) => i.isDone).toList(),
    _ => _items,
  };

  Future<void> _delete(DownloadItem item) async {
    if (item.isDone) {
      final ok = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text(S.deleteTitle),
          content: const Text(S.deleteBody),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text(S.keep)),
            TextButton(onPressed: () => Navigator.pop(c, true), child: const Text(S.delete)),
          ],
        ),
      );
      if (ok != true) return;
    }
    await _api.delete(item.id);
  }

  Future<void> _copy(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(S.copied)));
  }

  Future<void> _open(Future<bool> action) async {
    if (!await action && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(S.openFailed)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.nz;
    final items = _visible;
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PageHeader(title: S.downloads),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: Row(
              children: [
                for (final (i, label) in [S.all, S.running, S.done].indexed) ...[
                  _tabChip(p, i, label),
                  const SizedBox(width: 6),
                ],
              ],
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? _empty(p)
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    children: [
                      for (final entry in _grouped(items)) ...[
                        if (entry.batchId == null) _tile(p, entry.items.first) else _batch(p, entry),
                        const SizedBox(height: 10),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  // Rows are newest first; a playlist shows once, where its newest row would be, with items in playlist order.
  List<_Entry> _grouped(List<DownloadItem> items) {
    final out = <_Entry>[];
    final batches = <String, _Entry>{};
    for (final item in items) {
      final id = item.batchId;
      if (id == null) {
        out.add(_Entry(null, '', [item]));
        continue;
      }
      final entry = batches.putIfAbsent(id, () {
        final e = _Entry(id, item.batchTitle ?? '', []);
        out.add(e);
        return e;
      });
      entry.items.add(item);
    }
    for (final e in batches.values) {
      e.items.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    }
    return out;
  }

  Widget _batch(NzPalette p, _Entry entry) {
    final all = _items.where((i) => i.batchId == entry.batchId).toList();
    final done = all.where((i) => i.isDone).length;
    final active = all.any((i) => i.isRunning);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
          child: Row(
            children: [
              Icon(Icons.playlist_play_rounded, color: p.accent, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.title.isEmpty ? S.playlist : entry.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontWeight: FontWeight.w600, color: p.text),
                    ),
                    Text(S.batchProgress(done, all.length), style: TextStyle(color: p.mute, fontSize: 11.5)),
                  ],
                ),
              ),
              if (active)
                SoftButton(
                  label: S.cancelAll,
                  icon: Icons.close_rounded,
                  onTap: () => _api.cancelBatch(entry.batchId!),
                ),
            ],
          ),
        ),
        for (final (i, item) in entry.items.indexed) ...[if (i > 0) const SizedBox(height: 8), _tile(p, item)],
      ],
    );
  }

  Widget _tabChip(NzPalette p, int i, String label) {
    final on = _tab == i;
    return Semantics(
      button: true,
      selected: on,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () => setState(() => _tab = i),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(color: on ? p.raise : Colors.transparent, borderRadius: BorderRadius.circular(999)),
          child: Text(
            label,
            style: TextStyle(color: on ? p.text : p.mute, fontWeight: on ? FontWeight.w600 : FontWeight.w400),
          ),
        ),
      ),
    );
  }

  Widget _empty(NzPalette p) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.download_for_offline_outlined, size: 44, color: p.mute),
          const SizedBox(height: 12),
          Text(S.emptyDownloads, style: display(p, 16)),
          const SizedBox(height: 4),
          Text(
            S.emptyHint,
            textAlign: TextAlign.center,
            style: TextStyle(color: p.mute),
          ),
        ],
      ),
    ),
  );

  Widget _tile(NzPalette p, DownloadItem item) {
    return SurfaceCard(
      padding: const EdgeInsets.all(10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _thumb(p, item),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title.isEmpty ? S.appName : item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.w600, color: p.text),
                ),
                const SizedBox(height: 2),
                _status(p, item),
                if (item.status == 'running') ...[
                  const SizedBox(height: 7),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: item.percent <= 0 ? null : item.percent / 100,
                      minHeight: 5,
                      color: p.accent,
                      backgroundColor: p.raise,
                    ),
                  ),
                ],
                if (item.isFailed && (item.detail ?? '').isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    item.detail!,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    textDirection: TextDirection.ltr,
                    style: TextStyle(color: p.mute, fontSize: 10.5, height: 1.3),
                  ),
                ],
                const SizedBox(height: 7),
                Wrap(spacing: 6, runSpacing: 6, children: _actions(item)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _thumb(NzPalette p, DownloadItem item) => ClipRRect(
    borderRadius: BorderRadius.circular(10),
    child: SizedBox(
      width: 50,
      height: 50,
      child: item.thumb == null
          ? Container(color: p.raise)
          : Image.network(
              item.thumb!,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(color: p.raise),
            ),
    ),
  );

  Widget _status(NzPalette p, DownloadItem item) {
    Widget line(IconData? icon, Color color, String text, {bool ltr = false}) => Row(
      children: [
        if (icon != null) ...[Icon(icon, size: 14, color: color), const SizedBox(width: 5)],
        Flexible(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textDirection: ltr ? TextDirection.ltr : null,
            style: TextStyle(color: color, fontSize: 11.5),
          ),
        ),
      ],
    );
    switch (item.status) {
      case 'running':
        final speed = formatSpeed(item.speed);
        return line(null, p.mute, [if (speed.isNotEmpty) speed, '${item.percent.round()}%'].join(' · '), ltr: true);
      case 'queued':
        return line(Icons.schedule_rounded, p.mute, S.waiting);
      case 'done':
        return line(Icons.check_rounded, p.ok, S.savedToGallery);
      case 'canceled':
        return line(Icons.block_rounded, p.mute, S.canceled);
      default:
        return line(Icons.warning_amber_rounded, p.bad, S.error(item.error));
    }
  }

  List<Widget> _actions(DownloadItem item) {
    final del = SoftButton(label: null, icon: Icons.delete_outline_rounded, onTap: () => _delete(item));
    if (item.isDone) {
      return [
        SoftButton(label: S.play, icon: Icons.play_arrow_rounded, onTap: () => _open(_api.open(item.id))),
        SoftButton(label: null, icon: Icons.share_outlined, onTap: () => _open(_api.share(item.id))),
        del,
      ];
    }
    if (item.isFailed) {
      return [
        SoftButton(label: S.retry, icon: Icons.refresh_rounded, onTap: () => _api.retry(item.id)),
        if ((item.detail ?? '').isNotEmpty)
          SoftButton(label: null, icon: Icons.copy_rounded, onTap: () => _copy(item.detail!)),
        del,
      ];
    }
    return [SoftButton(label: S.cancel, icon: Icons.close_rounded, onTap: () => _api.cancel(item.id))];
  }
}

class _Entry {
  _Entry(this.batchId, this.title, this.items);
  final String? batchId;
  final String title;
  final List<DownloadItem> items;
}
