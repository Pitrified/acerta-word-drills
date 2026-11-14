import 'package:flutter/material.dart';

/// How a word tile is drawn.
enum WordTileStatus { idle, selected, matched, wrong }

/// One tappable word of a round; a matched word is disabled.
class WordTile extends StatelessWidget {
  const WordTile({
    required this.text,
    required this.status,
    required this.onTap,
    super.key,
  });

  final String text;
  final WordTileStatus status;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final (background, foreground, border) = switch (status) {
      WordTileStatus.idle => (
        colors.surfaceContainerHigh,
        colors.onSurface,
        colors.outlineVariant,
      ),
      WordTileStatus.selected => (
        colors.primaryContainer,
        colors.onPrimaryContainer,
        colors.primary,
      ),
      WordTileStatus.matched => (
        colors.surfaceContainerLowest,
        colors.onSurface.withValues(alpha: 0.38),
        colors.outlineVariant,
      ),
      WordTileStatus.wrong => (
        colors.errorContainer,
        colors.onErrorContainer,
        colors.error,
      ),
    };
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: background,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: border, width: 2),
        ),
        child: InkWell(
          customBorder: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          onTap: status == WordTileStatus.matched ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: foreground,
                decoration: status == WordTileStatus.matched
                    ? TextDecoration.lineThrough
                    : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
