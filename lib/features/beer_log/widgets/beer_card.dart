import 'dart:io';

import 'package:flutter/material.dart';

import '../../../core/models/beer_entry.dart';

/// Moderní karta jednoho piva – zaoblené rohy, stín, Hero animace.
class BeerCard extends StatelessWidget {
  final BeerEntry entry;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const BeerCard({
    super.key,
    required this.entry,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final heroTag = 'beer_image_${entry.key}';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 3,
      shadowColor: theme.colorScheme.shadow.withValues(alpha: 0.3),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // ── Fotka s Hero animací ──
              Hero(
                tag: heroTag,
                child: _buildThumbnail(theme),
              ),
              const SizedBox(width: 14),
              // ── Textový obsah ──
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        ...List.generate(5, (i) {
                          return Icon(
                            i < entry.rating.round()
                                ? Icons.star_rounded
                                : Icons.star_outline_rounded,
                            size: 18,
                            color: i < entry.rating.round()
                                ? Colors.amber
                                : theme.colorScheme.outlineVariant,
                          );
                        }),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.schedule, size: 14,
                            color: theme.colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          entry.date,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (entry.isGhost) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.visibility_off, size: 14,
                              color: theme.colorScheme.onSurfaceVariant),
                        ],
                        if (entry.hasLocation) ...[
                          const SizedBox(width: 8),
                          Icon(Icons.location_on, size: 14,
                              color: theme.colorScheme.onSurfaceVariant),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              // ── Smazat ──
              IconButton(
                icon: Icon(Icons.delete_outline,
                    color: theme.colorScheme.error.withValues(alpha: 0.7)),
                onPressed: () => _confirmDelete(context),
                tooltip: 'Smazat',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThumbnail(ThemeData theme) {
    if (entry.imagePath != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(
          File(entry.imagePath!),
          width: 68,
          height: 68,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholderIcon(theme),
        ),
      );
    }
    return _placeholderIcon(theme);
  }

  Widget _placeholderIcon(ThemeData theme) {
    return Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(Icons.sports_bar,
          color: theme.colorScheme.onPrimaryContainer, size: 32),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Smazat pivo?'),
        content: Text('Opravdu chceš smazat „${entry.name}" z deníčku?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Zrušit'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onDelete();
            },
            child: const Text('Smazat'),
          ),
        ],
      ),
    );
  }
}
