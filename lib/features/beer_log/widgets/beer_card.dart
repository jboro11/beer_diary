import 'dart:io';

import 'package:flutter/material.dart';

/// Karta jednoho piva v seznamu – znovupoužitelný widget.
class BeerCard extends StatelessWidget {
  final Map pivo;
  final VoidCallback onDelete;
  final VoidCallback onTap;

  const BeerCard({
    super.key,
    required this.pivo,
    required this.onDelete,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.all(10),
        leading: pivo['imagePath'] != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  File(pivo['imagePath']),
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                ),
              )
            : Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.green[100],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.local_drink, color: Colors.green),
              ),
        title: Text(
          pivo['name'],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          "${'⭐' * (pivo['rating'] ?? 0).round()}\n${pivo['date']}",
        ),
        isThreeLine: true,
        trailing: IconButton(
          icon: const Icon(Icons.delete, color: Colors.grey),
          onPressed: onDelete,
        ),
        onTap: onTap,
      ),
    );
  }
}
