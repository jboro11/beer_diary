import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Statistiky – celkem piv, průměrné hodnocení.
class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final box = Hive.box('piva_box');
    int celkem = box.length;
    double prumer = 0;

    if (celkem > 0) {
      double soucet = 0;
      for (var i = 0; i < celkem; i++) {
        soucet += box.getAt(i)['rating'];
      }
      prumer = soucet / celkem;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistiky'),
        backgroundColor: Colors.green[50],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _statCard('Celkem vypito', '$celkem', Icons.sports_bar),
            const SizedBox(height: 20),
            _statCard(
              'Průměrné hodnocení',
              '${prumer.toStringAsFixed(1)} ⭐',
              Icons.star,
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withValues(alpha: 0.1),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, size: 40, color: Colors.green),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(fontSize: 16, color: Colors.grey),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
