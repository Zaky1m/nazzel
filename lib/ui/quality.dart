import 'package:flutter/material.dart';

import '../core/small_caps.dart';
import '../core/strings.dart';
import '../core/theme.dart';
import '../engine/models.dart';

final _urlPattern = RegExp(r'https?://\S+');

String? extractUrl(String text) {
  final m = _urlPattern.firstMatch(text);
  if (m == null) return null;
  return m.group(0)!.replaceAll(RegExp(r'''[.,)\]}>"']+$'''), '');
}

String qualityLabel(QualityOption o) {
  if (o.isAudio) return S.audioOnly;
  if (o.id == 'best') return S.bestQuality;
  if (o.quality > 0) return '${o.quality}${smallCaps('p')}';
  final tier = RegExp(r'^tier(\d)$').firstMatch(o.label);
  if (tier != null) return S.tier(int.parse(tier.group(1)!));
  return smallCaps(o.label);
}

/// Picks the option closest to the saved default without going above it; the first video option is the best one.
QualityOption pickQuality(List<QualityOption> options, String? pref) {
  final videos = options.where((o) => !o.isAudio).toList();
  final limit = int.tryParse(pref ?? '');
  if (limit != null) {
    for (final o in videos) {
      if (o.quality > 0 && o.quality <= limit) return o;
    }
  }
  return videos.isNotEmpty ? videos.first : options.first;
}

class QualityChip extends StatelessWidget {
  const QualityChip({super.key, required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.nz;
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: selected ? p.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: selected ? p.accent : p.line),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? p.onAccent : p.mute,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }
}
