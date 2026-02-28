import 'package:flutter/material.dart';

/// Placeholder obrazovka pro žebříček (leaderboard).
///
/// Bude rozšířena o:
/// - Globální žebříček (top uživatelé)
/// - Týmový žebříček
/// - Filtr podle období (týden/měsíc/celkem)
class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Žebříček 🏆'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.leaderboard_outlined,
                size: 100,
                color: theme.colorScheme.primary.withValues(alpha: 0.2),
              ),
              const SizedBox(height: 24),
              Text(
                'Žebříček – připravujeme',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Zde uvidíš kdo z tvých přátel\nvypil nejvíc a má nejlepší hodnocení.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
