import 'dart:io';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/models/beer_entry.dart';
import '../../../core/services/local_database_service.dart';
import '../widgets/beer_card.dart';

/// Seznam vypitých piv s moderními kartami, Hero animací a empty state.
class BeerListScreen extends StatelessWidget {
  const BeerListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Moje piva 🍺'),
      ),
      body: ListenableBuilder(
        listenable: LocalDatabaseService.listenable,
        builder: (context, _) {
          final beers = LocalDatabaseService.getAllBeers();

          if (beers.isEmpty) {
            return _buildEmptyState(theme);
          }

          return ListView.builder(
            padding: const EdgeInsets.only(top: 8, bottom: 100),
            itemCount: beers.length,
            itemBuilder: (context, index) {
              final entry = beers[index];
              return BeerCard(
                entry: entry,
                onDelete: () {
                  if (entry.key != null) {
                    LocalDatabaseService.deleteBeer(entry.key!);
                  }
                },
                onTap: () => _showDetailSheet(context, entry),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.sports_bar_outlined,
              size: 120,
              color: theme.colorScheme.primary.withValues(alpha: 0.2),
            ),
            const SizedBox(height: 24),
            Text(
              'Tady je zatím nebezpečně\nstřízlivo.',
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Běž na jedno a přidej první pivo\npřes tlačítko + dole!',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetailSheet(BuildContext context, BeerEntry entry) {
    final theme = Theme.of(context);
    final heroTag = 'beer_image_${entry.key}';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.4,
        maxChildSize: 0.85,
        expand: false,
        builder: (_, scrollController) => SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Drag handle ──
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // ── Fotka s Hero ──
                if (entry.imagePath != null)
                  Hero(
                    tag: heroTag,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: SizedBox(
                        height: 220,
                        width: double.infinity,
                        child: Image.file(
                          File(entry.imagePath!),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: theme.colorScheme.surfaceContainerHighest,
                            child: Icon(Icons.broken_image, size: 48,
                                color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 20),

                // ── Název ──
                Text(
                  entry.name,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                // ── Hodnocení ──
                Row(
                  children: [
                    ...List.generate(5, (i) {
                      return Icon(
                        i < entry.rating.round()
                            ? Icons.star_rounded
                            : Icons.star_outline_rounded,
                        size: 28,
                        color: i < entry.rating.round()
                            ? Colors.amber
                            : theme.colorScheme.outlineVariant,
                      );
                    }),
                    const SizedBox(width: 8),
                    Text(
                      '${entry.rating.round()}/5',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ── Datum ──
                Row(
                  children: [
                    Icon(Icons.schedule, size: 18,
                        color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(width: 6),
                    Text(entry.date,
                        style: theme.textTheme.bodyMedium),
                  ],
                ),
                if (entry.isGhost) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.visibility_off, size: 18,
                          color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 6),
                      Text('Režim inkognito',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          )),
                    ],
                  ),
                ],
                const SizedBox(height: 20),

                // ── Mapa ──
                if (entry.hasLocation)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.map_outlined),
                      label: const Text('Otevřít v Google Mapách'),
                      onPressed: () async {
                        final url = Uri.parse(
                          'https://www.google.com/maps/search/?api=1&query=${entry.lat},${entry.lng}',
                        );
                        final launched = await launchUrl(
                          url,
                          mode: LaunchMode.externalApplication,
                        );
                        if (!context.mounted) return;
                        if (!launched) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Nelze otevřít mapu')),
                          );
                        }
                      },
                    ),
                  )
                else
                  Row(
                    children: [
                      Icon(Icons.location_off, size: 18,
                          color: theme.colorScheme.onSurfaceVariant),
                      const SizedBox(width: 6),
                      Text(
                        'Poloha nebyla uložena',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
