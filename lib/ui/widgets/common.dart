import 'package:flutter/material.dart';

import '../../core/theme.dart';

class PageHeader extends StatelessWidget {
  const PageHeader({super.key, required this.title, this.leading});
  final String title;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final p = context.nz;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: 10)],
          Expanded(child: Text(title, style: display(p, 22))),
        ],
      ),
    );
  }
}

class SurfaceCard extends StatelessWidget {
  const SurfaceCard({super.key, required this.child, this.padding = const EdgeInsets.all(12)});
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) => Container(
    padding: padding,
    decoration: BoxDecoration(color: context.nz.surface, borderRadius: BorderRadius.circular(16)),
    child: child,
  );
}

class SoftButton extends StatelessWidget {
  const SoftButton({super.key, required this.label, required this.onTap, this.icon});
  final String? label;
  final IconData? icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.nz;
    return Semantics(
      button: true,
      label: label,
      child: Material(
        color: p.raise,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 36, minWidth: 36),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: label == null ? 8 : 12, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) Icon(icon, size: 16, color: p.text),
                  if (icon != null && label != null) const SizedBox(width: 5),
                  if (label != null)
                    Text(
                      label!,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: p.text),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
