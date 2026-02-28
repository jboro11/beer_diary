import 'package:flutter/material.dart';

/// Placeholder obrazovka pro správu přátel.
///
/// Bude rozšířena o:
/// - Vyhledávání uživatelů
/// - Odesílání/přijímání žádostí o přátelství
/// - Seznam přátel s aktivitou
class FriendsScreen extends StatelessWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Přátelé 👥'),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.people_outline,
                size: 100,
                color: theme.colorScheme.primary.withValues(alpha: 0.2),
              ),
              const SizedBox(height: 24),
              Text(
                'Přátelé – připravujeme',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Zde budeš moci přidávat kamarády,\nsledovat jejich aktivitu a soutěžit.',
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
