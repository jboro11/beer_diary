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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Žebříček'),
        backgroundColor: Colors.green[50],
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.leaderboard, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Žebříček – připravujeme',
              style: TextStyle(fontSize: 20, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Zde uvidíš kdo z tvých přátel '
                'vypil nejvíc, nejlépe hodnocená piva a další.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
