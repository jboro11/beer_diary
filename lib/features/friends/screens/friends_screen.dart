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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Přátelé'),
        backgroundColor: Colors.green[50],
      ),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Přátelé – připravujeme',
              style: TextStyle(fontSize: 20, color: Colors.grey),
            ),
            SizedBox(height: 8),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Zde budeš moci přidávat kamarády, '
                'sledovat jejich aktivitu a soutěžit.',
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
