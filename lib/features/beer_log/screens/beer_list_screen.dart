import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../widgets/beer_card.dart';

/// Seznam vypitých piv (lokální Hive data + budoucí Supabase sync).
class BeerListScreen extends StatefulWidget {
  const BeerListScreen({super.key});

  @override
  State<BeerListScreen> createState() => _BeerListScreenState();
}

class _BeerListScreenState extends State<BeerListScreen> {
  final _pivaBox = Hive.box('piva_box');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Moje piva'),
        backgroundColor: Colors.green[50],
      ),
      body: ValueListenableBuilder(
        valueListenable: _pivaBox.listenable(),
        builder: (context, Box box, widget) {
          if (box.isEmpty) {
            return const Center(
              child: Text('Zatím jsi nic nepřidal.'),
            );
          }

          return ListView.builder(
            itemCount: box.length,
            itemBuilder: (context, index) {
              final key = box.keyAt(box.length - 1 - index);
              final pivo = box.get(key);

              return BeerCard(
                pivo: pivo,
                onDelete: () => box.delete(key),
                onTap: () => _showDetailDialog(context, pivo),
              );
            },
          );
        },
      ),
    );
  }

  void _showDetailDialog(BuildContext context, Map pivo) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(pivo['name']),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (pivo['imagePath'] != null)
              SizedBox(
                height: 200,
                width: double.infinity,
                child:
                    Image.file(File(pivo['imagePath']), fit: BoxFit.cover),
              ),
            const SizedBox(height: 10),
            Text("Hodnocení: ${pivo['rating']}/5"),
            const SizedBox(height: 10),
            if (pivo['lat'] != 0.0 && pivo['lng'] != 0.0)
              ElevatedButton.icon(
                icon: const Icon(Icons.map),
                label: const Text('Otevřít v Google Mapách'),
                onPressed: () async {
                  final url = Uri.parse(
                    'https://www.google.com/maps/search/?api=1&query=${pivo['lat']},${pivo['lng']}',
                  );
                  bool launched = await launchUrl(
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
              )
            else
              const Text(
                'Poloha nebyla uložena.',
                style: TextStyle(color: Colors.grey),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Zavřít'),
          ),
        ],
      ),
    );
  }
}
