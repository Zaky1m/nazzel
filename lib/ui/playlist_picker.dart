import 'package:flutter/material.dart';

import '../core/format.dart';
import '../core/strings.dart';
import '../core/theme.dart';
import '../engine/models.dart';

/// Checkbox list of a playlist's items; everything starts selected.
class PlaylistPicker extends StatelessWidget {
  const PlaylistPicker({
    super.key,
    required this.items,
    required this.selected,
    required this.onChanged,
    this.scrollable = false,
  });

  final List<PlaylistItem> items;
  final Set<int> selected;
  final ValueChanged<Set<int>> onChanged;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final p = context.nz;
    final all = selected.length == items.length;
    final header = Row(
      children: [
        Expanded(
          child: Text(S.selected(selected.length, items.length), style: TextStyle(color: p.mute, fontSize: 12.5)),
        ),
        TextButton(
          onPressed: () => onChanged(all ? <int>{} : {for (var i = 0; i < items.length; i++) i}),
          child: Text(all ? S.selectNone : S.selectAll),
        ),
      ],
    );
    Widget row(int i) {
      final item = items[i];
      final on = selected.contains(i);
      final duration = formatDuration(item.duration);
      return InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => onChanged(on ? ({...selected}..remove(i)) : ({...selected, i})),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Icon(
                on ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                color: on ? p.accent : p.line,
                size: 22,
              ),
              const SizedBox(width: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 64,
                  height: 36,
                  child: item.thumbnail == null
                      ? Container(color: p.raise)
                      : Image.network(
                          item.thumbnail!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => Container(color: p.raise),
                        ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: p.text, fontSize: 13),
                ),
              ),
              if (duration.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text(
                  duration,
                  style: TextStyle(color: p.mute, fontSize: 11.5),
                  textDirection: TextDirection.ltr,
                ),
              ],
            ],
          ),
        ),
      );
    }

    if (scrollable) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          header,
          Flexible(
            child: ListView.builder(shrinkWrap: true, itemCount: items.length, itemBuilder: (_, i) => row(i)),
          ),
        ],
      );
    }
    return Column(children: [header, for (var i = 0; i < items.length; i++) row(i)]);
  }
}
