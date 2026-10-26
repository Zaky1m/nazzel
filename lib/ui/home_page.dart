import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/format.dart';
import '../core/strings.dart';
import '../core/theme.dart';
import '../engine/engine_api.dart';
import '../engine/models.dart';
import 'playlist_picker.dart';
import 'quality.dart';
import 'widgets/common.dart';
import 'widgets/glyph.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.onStarted, required this.onOpenSettings});

  final VoidCallback onStarted;
  final VoidCallback onOpenSettings;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _controller = TextEditingController();
  final _api = EngineApi.instance;
  StreamSubscription<String>? _clipSub;
  VideoInfo? _info;
  QualityOption? _selected;
  Set<int> _picked = {};
  bool _loading = false;
  String? _error;
  String? _update;
  int _token = 0;

  @override
  void initState() {
    super.initState();
    _controller.addListener(() => setState(() {}));
    _clipSub = _api.onClipboardUrl.listen(_onClipboard);
    _api.updateInfo().then((u) {
      if (mounted && u != null) setState(() => _update = u['version'] as String?);
    });
  }

  @override
  void dispose() {
    _clipSub?.cancel();
    _controller.dispose();
    super.dispose();
  }

  // A fresh link on the clipboard fills the field, unless the user is already busy with one.
  void _onClipboard(String url) {
    if (_loading || _info != null || _controller.text.isNotEmpty) return;
    _controller.text = url;
    _load(url);
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text;
    if (text == null || text.trim().isEmpty) return;
    _submit(text);
  }

  void _clear() {
    _token++;
    setState(() {
      _controller.clear();
      _info = null;
      _selected = null;
      _error = null;
      _loading = false;
    });
  }

  void _submit(String text) {
    final url = extractUrl(text);
    if (url == null) {
      setState(() {
        _error = S.noLinkFound;
        _info = null;
      });
      return;
    }
    _controller.text = url;
    _load(url);
  }

  Future<void> _load(String url) async {
    final token = ++_token;
    setState(() {
      _loading = true;
      _error = null;
      _info = null;
      _selected = null;
    });
    try {
      final info = await _api.info(url);
      final pref = await _api.getPref('default_quality');
      if (!mounted || token != _token) return;
      setState(() {
        _info = info;
        _selected = pickQuality(info.options, pref);
        _picked = {for (var i = 0; i < info.items.length; i++) i};
        _loading = false;
      });
    } on EngineFailure catch (e) {
      if (!mounted || token != _token) return;
      setState(() {
        _error = S.error(e.code);
        _loading = false;
      });
    } catch (_) {
      if (!mounted || token != _token) return;
      setState(() {
        _error = S.error(null);
        _loading = false;
      });
    }
  }

  Future<void> _start() async {
    final info = _info;
    final option = _selected;
    if (info == null || option == null) return;
    if (info.isPlaylist && _picked.isEmpty) return;
    await _api.askNotifications();
    if (info.isPlaylist) {
      final ordered = _picked.toList()..sort();
      await _api.enqueueBatch(info, [for (final i in ordered) info.items[i]], option);
    } else {
      await _api.enqueue(info, option);
    }
    if (!mounted) return;
    _clear();
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text(S.started)));
    widget.onStarted();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.nz;
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const PageHeader(title: S.appName, leading: BrandMark()),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              children: [
                if (_update != null) ...[_updateBanner(p), const SizedBox(height: 12)],
                _field(p),
                const SizedBox(height: 14),
                if (_loading) _loadingBox(p),
                if (_error != null) _errorBox(p),
                if (_info != null) ...(_info!.isPlaylist ? _playlist(p, _info!) : _ready(p, _info!)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _updateBanner(NzPalette p) => Material(
    color: p.raise,
    borderRadius: BorderRadius.circular(14),
    child: InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: widget.onOpenSettings,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            Icon(Icons.system_update_rounded, color: p.accent, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                S.updateBanner,
                style: TextStyle(color: p.text, fontWeight: FontWeight.w500),
              ),
            ),
            Text(
              S.updateNow,
              style: TextStyle(color: p.accent, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    ),
  );

  // The field takes the full width; one trailing icon pastes when empty and clears when filled.
  Widget _field(NzPalette p) {
    final empty = _controller.text.isEmpty;
    return TextField(
      controller: _controller,
      keyboardType: TextInputType.url,
      textDirection: TextDirection.ltr,
      textInputAction: TextInputAction.go,
      onSubmitted: _submit,
      style: TextStyle(color: p.text, fontSize: 14),
      decoration: InputDecoration(
        hintText: S.pasteHint,
        hintTextDirection: TextDirection.rtl,
        hintStyle: TextStyle(color: p.mute),
        filled: true,
        fillColor: p.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: p.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: p.accent, width: 1.5),
        ),
        suffixIcon: IconButton(
          tooltip: empty ? S.paste : S.clear,
          onPressed: empty ? _paste : _clear,
          icon: Icon(empty ? Icons.content_paste_rounded : Icons.close_rounded, color: empty ? p.accent : p.mute),
        ),
      ),
    );
  }

  Widget _loadingBox(NzPalette p) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 28),
    child: Column(
      children: [
        SizedBox(width: 26, height: 26, child: CircularProgressIndicator(strokeWidth: 3, color: p.accent)),
        const SizedBox(height: 12),
        Text(S.checking, style: TextStyle(color: p.mute)),
      ],
    ),
  );

  Widget _errorBox(NzPalette p) => SurfaceCard(
    child: Row(
      children: [
        Icon(Icons.warning_amber_rounded, color: p.bad, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(_error!, style: TextStyle(color: p.bad)),
        ),
      ],
    ),
  );

  Widget _chips(VideoInfo info) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final o in info.options)
        QualityChip(
          label: qualityLabel(o),
          selected: _selected?.id == o.id,
          onTap: () => setState(() => _selected = o),
        ),
    ],
  );

  Widget _downloadButton(NzPalette p, String label) => Semantics(
    button: true,
    label: label,
    child: Material(
      color: p.accent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: _start,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.download_rounded, color: p.onAccent, size: 20),
              const SizedBox(width: 8),
              Text(label, style: display(p, 16).copyWith(color: p.onAccent)),
            ],
          ),
        ),
      ),
    ),
  );

  List<Widget> _ready(NzPalette p, VideoInfo info) {
    final size = formatBytes(_selected?.size);
    return [
      ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Container(
          color: p.surface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (info.thumbnail != null)
                      Image.network(
                        info.thumbnail!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => Container(color: p.raise),
                      )
                    else
                      Container(color: p.raise),
                    Center(
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(color: Color(0xD9FFFFFF), shape: BoxShape.circle),
                        child: const Icon(Icons.play_arrow_rounded, color: Color(0xFF1F5BFF)),
                      ),
                    ),
                    if (formatDuration(info.duration).isNotEmpty)
                      PositionedDirectional(
                        end: 8,
                        bottom: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xA6000000),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            formatDuration(info.duration),
                            style: const TextStyle(color: Colors.white, fontSize: 11),
                            textDirection: TextDirection.ltr,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      info.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontWeight: FontWeight.w600, color: p.text),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      [if (info.site != null) info.site!, if (size.isNotEmpty) size].join(' · '),
                      style: TextStyle(color: p.mute, fontSize: 12),
                      textDirection: TextDirection.ltr,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 14),
      _chips(info),
      const SizedBox(height: 18),
      _downloadButton(p, S.download),
    ];
  }

  List<Widget> _playlist(NzPalette p, VideoInfo info) => [
    SurfaceCard(
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 72,
              height: 72,
              child: info.thumbnail == null
                  ? Container(
                      color: p.raise,
                      child: Icon(Icons.queue_music_rounded, color: p.mute),
                    )
                  : Image.network(
                      info.thumbnail!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(color: p.raise),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(S.playlist, style: TextStyle(color: p.mute, fontSize: 12)),
                Text(
                  info.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.w600, color: p.text),
                ),
                Text(
                  [if (info.site != null) info.site!, S.items(info.items.length)].join(' · '),
                  style: TextStyle(color: p.mute, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
    const SizedBox(height: 14),
    _chips(info),
    const SizedBox(height: 10),
    PlaylistPicker(items: info.items, selected: _picked, onChanged: (s) => setState(() => _picked = s)),
    const SizedBox(height: 14),
    _downloadButton(p, S.downloadSelected(_picked.length)),
  ];
}
