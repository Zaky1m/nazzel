import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import '../core/format.dart';
import '../core/strings.dart';
import '../core/theme.dart';
import '../engine/engine_api.dart';
import '../engine/models.dart';
import 'playlist_picker.dart';
import 'quality.dart';
import 'widgets/glyph.dart';

/// Root of the translucent activity opened from the system share menu.
class ShareApp extends StatelessWidget {
  const ShareApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: S.appName,
    debugShowCheckedModeBanner: false,
    locale: const Locale('ar'),
    supportedLocales: const [Locale('ar')],
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    theme: buildTheme(NzPalette.light, Brightness.light),
    darkTheme: buildTheme(NzPalette.dark, Brightness.dark),
    themeMode: ThemeMode.system,
    home: const ShareSheet(),
  );
}

class ShareSheet extends StatefulWidget {
  const ShareSheet({super.key});

  @override
  State<ShareSheet> createState() => _ShareSheetState();
}

class _ShareSheetState extends State<ShareSheet> {
  final _api = EngineApi.instance;
  VideoInfo? _info;
  QualityOption? _selected;
  String? _error;
  bool _starting = false;
  Set<int> _picked = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final url = await _api.sharedUrl();
      if (url == null) {
        _fail(S.noLinkFound);
        return;
      }
      final info = await _api.info(url);
      final pref = await _api.getPref('default_quality');
      if (!mounted) return;
      setState(() {
        _info = info;
        _selected = pickQuality(info.options, pref);
        _picked = {for (var i = 0; i < info.items.length; i++) i};
      });
    } on EngineFailure catch (e) {
      _fail(S.error(e.code));
    } catch (_) {
      _fail(S.error(null));
    }
  }

  void _fail(String message) {
    if (mounted) setState(() => _error = message);
  }

  Future<void> _start() async {
    final info = _info;
    final option = _selected;
    if (info == null || option == null || _starting) return;
    if (info.isPlaylist && _picked.isEmpty) return;
    setState(() => _starting = true);
    await _api.askNotifications();
    if (info.isPlaylist) {
      final ordered = _picked.toList()..sort();
      await _api.enqueueBatch(info, [for (final i in ordered) info.items[i]], option);
    } else {
      await _api.enqueue(info, option);
    }
    await _api.closeShare();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.nz;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _api.closeShare,
              child: const ColoredBox(color: Color(0x73000000)),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Material(
              color: p.bg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 36,
                          height: 4,
                          decoration: BoxDecoration(color: p.line, borderRadius: BorderRadius.circular(2)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const BrandMark(size: 24),
                          const SizedBox(width: 8),
                          Text(S.appName, style: display(p, 17)),
                        ],
                      ),
                      const SizedBox(height: 14),
                      if (_error != null) _errorBody(p) else if (_info == null) _loading(p) else ..._ready(p, _info!),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _loading(NzPalette p) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 22),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 3, color: p.accent)),
        const SizedBox(width: 12),
        Text(S.checking, style: TextStyle(color: p.mute)),
      ],
    ),
  );

  Widget _errorBody(NzPalette p) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: p.bad, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(_error!, style: TextStyle(color: p.bad)),
          ),
        ],
      ),
      const SizedBox(height: 14),
      _button(p, S.close, Icons.close_rounded, _api.closeShare),
    ],
  );

  List<Widget> _ready(NzPalette p, VideoInfo info) {
    final duration = formatDuration(info.duration);
    return [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 96,
              height: 54,
              child: info.thumbnail == null
                  ? Container(color: p.raise)
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
                Text(
                  info.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontWeight: FontWeight.w600, color: p.text),
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    if (info.site != null) info.site!,
                    if (info.isPlaylist) S.items(info.items.length) else if (duration.isNotEmpty) duration,
                  ].join(' · '),
                  style: TextStyle(color: p.mute, fontSize: 12),
                  textDirection: TextDirection.ltr,
                ),
              ],
            ),
          ),
        ],
      ),
      const SizedBox(height: 14),
      Wrap(
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
      ),
      if (info.isPlaylist) ...[
        const SizedBox(height: 8),
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.4),
          child: PlaylistPicker(
            items: info.items,
            selected: _picked,
            scrollable: true,
            onChanged: (s) => setState(() => _picked = s),
          ),
        ),
      ],
      const SizedBox(height: 16),
      _button(
        p,
        info.isPlaylist ? S.downloadSelected(_picked.length) : S.download,
        Icons.download_rounded,
        _start,
        filled: true,
      ),
    ];
  }

  Widget _button(NzPalette p, String label, IconData icon, VoidCallback onTap, {bool filled = false}) => Semantics(
    button: true,
    label: label,
    child: Material(
      color: filled ? p.accent : p.raise,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: filled ? p.onAccent : p.text, size: 20),
              const SizedBox(width: 8),
              Text(label, style: display(p, 16).copyWith(color: filled ? p.onAccent : p.text)),
            ],
          ),
        ),
      ),
    ),
  );
}
