import 'package:flutter/material.dart';

import '../../beer_log/screens/add_beer_screen.dart';
import '../../beer_log/screens/beer_list_screen.dart';
import '../../stats/screens/stats_screen.dart';
import '../../friends/screens/friends_screen.dart';
import '../../leaderboard/screens/leaderboard_screen.dart';

/// Hlavní scaffold s BottomNavigationBar a dockeným FAB.
///
/// Nahrazuje původní HomeScreen s mřížkou tlačítek.
/// FAB uprostřed spodní lišty slouží pro rychlé přidání piva.
class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _currentIndex = 0;

  static const List<Widget> _screens = [
    BeerListScreen(),
    StatsScreen(),
    FriendsScreen(),
    LeaderboardScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      floatingActionButton: FloatingActionButton.large(
        heroTag: 'add_beer_fab',
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddBeerScreen()),
        ),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 6,
        child: const Icon(Icons.add, size: 36),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // ── Levá strana ──
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _navItem(Icons.sports_bar, 'Piva', 0),
                  _navItem(Icons.bar_chart, 'Statistiky', 1),
                ],
              ),
            ),
            // ── Mezera pro FAB ──
            const SizedBox(width: 48),
            // ── Pravá strana ──
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _navItem(Icons.people, 'Přátelé', 2),
                  _navItem(Icons.leaderboard, 'Žebříček', 3),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index) {
    final theme = Theme.of(context);
    final isSelected = _currentIndex == index;

    return InkWell(
      onTap: () => setState(() => _currentIndex = index),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
              size: 24,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
