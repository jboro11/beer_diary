import 'package:flutter/material.dart';

import '../../../shared/widgets/menu_button.dart';
import '../../beer_log/screens/beer_list_screen.dart';
import '../../beer_log/screens/add_beer_screen.dart';
import '../../stats/screens/stats_screen.dart';
import '../../friends/screens/friends_screen.dart';
import '../../leaderboard/screens/leaderboard_screen.dart';

/// Hlavní obrazovka s navigačním menu.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'BeerBuddy 🍺',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 26,
            color: Colors.black,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                childAspectRatio: 1.2,
                children: [
                  MenuButton(
                    title: 'Moje piva',
                    icon: Icons.sports_bar,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const BeerListScreen(),
                      ),
                    ),
                  ),
                  MenuButton(
                    title: 'Přidat pivo',
                    icon: Icons.add,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AddBeerScreen(),
                      ),
                    ),
                  ),
                  MenuButton(
                    title: 'Statistiky',
                    icon: Icons.bar_chart,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const StatsScreen(),
                      ),
                    ),
                  ),
                  MenuButton(
                    title: 'Přátelé',
                    icon: Icons.people,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const FriendsScreen(),
                      ),
                    ),
                  ),
                  MenuButton(
                    title: 'Žebříček',
                    icon: Icons.leaderboard,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LeaderboardScreen(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
