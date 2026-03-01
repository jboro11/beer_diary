import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/models/beer_entry.dart';
import '../../../core/services/local_database_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/image_service.dart';
import '../../../core/services/supabase_service.dart';
import '../../../core/services/sync_service.dart';

/// Obrazovka pro přidání nového piva – "One-Tap" flow.
///
/// ## Pillar 2 (Offline-First) integrace:
/// 1. Lokální uložení přes LocalDatabaseService (okamžitý UI update).
/// 2. Záznam do sync fronty pro pozdější synchronizaci.
/// 3. Pokud online → okamžitý sync.
///
/// ## Pillar 5 (Ghost Mode):
/// Toggle "Inkognito" → is_ghost = true → nepropíše se do feedu/žebříčku.
class AddBeerScreen extends StatefulWidget {
  const AddBeerScreen({super.key});

  @override
  State<AddBeerScreen> createState() => _AddBeerScreenState();
}

class _AddBeerScreenState extends State<AddBeerScreen> {
  final _nameController = TextEditingController();
  double _rating = 3.0;
  File? _selectedImage;
  String _locationStatus = 'Poloha nezískána';
  double _lat = 0.0;
  double _lng = 0.0;
  bool _isGettingLocation = false;
  bool _isSaving = false;
  bool _isGhost = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _takePicture() async {
    final path = await ImageService.takePicture();
    if (path != null && mounted) {
      setState(() => _selectedImage = File(path));
    }
  }

  Future<void> _getLocation() async {
    setState(() => _isGettingLocation = true);
    try {
      final position = await LocationService.getCurrentPosition();
      if (!mounted) return;

      if (position != null) {
        setState(() {
          _lat = position.latitude;
          _lng = position.longitude;
          _locationStatus =
              'GPS: ${_lat.toStringAsFixed(4)}, ${_lng.toStringAsFixed(4)}';
          _isGettingLocation = false;
        });
      } else {
        setState(() {
          _locationStatus = 'Bez oprávnění';
          _isGettingLocation = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _locationStatus = 'Chyba GPS';
          _isGettingLocation = false;
        });
      }
    }
  }

  /// Hlavní API volání: optimistický update + sync queue.
  Future<void> _saveBeer() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Musíš zadat název piva!')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final now = DateTime.now();

    // ── 1. Lokální uložení přes LocalDatabaseService ──
    final entry = BeerEntry(
      name: _nameController.text,
      rating: _rating,
      date: DateFormat('dd.MM.yyyy HH:mm').format(now),
      imagePath: _selectedImage?.path,
      lat: _lat,
      lng: _lng,
      isGhost: _isGhost,
    );
    await LocalDatabaseService.addBeer(entry);

    // ── 2. Přidat do sync fronty (Pillar 2: Offline-First) ──
    if (SupabaseService.isAvailable) {
      // Přímý sync pokud online
      try {
        await SupabaseService.logBeer(
          beerName: _nameController.text,
          rating: _rating.round(),
          latitude: _lat != 0.0 ? _lat : null,
          longitude: _lng != 0.0 ? _lng : null,
          isGhost: _isGhost,
        );
      } catch (_) {
        // Sync selhal – data zůstávají lokálně v Hive
      }
    } else {
      // Offline → zařadit do fronty
      await SyncService.enqueue(
        operation: 'insert_beer_log',
        payload: {
          'beer_name': _nameController.text,
          'rating': _rating.round(),
          'latitude': _lat != 0.0 ? _lat : null,
          'longitude': _lng != 0.0 ? _lng : null,
          'is_ghost': _isGhost,
          'logged_at': now.toIso8601String(),
        },
      );
    }

    if (!mounted) return;
    setState(() => _isSaving = false);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nový úlovek'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Fotka ──
            GestureDetector(
              onTap: _takePicture,
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(_selectedImage!, fit: BoxFit.cover),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt, size: 50,
                              color: theme.colorScheme.onSurfaceVariant),
                          Text(
                            'Klikni a vyfoť pivo!',
                            style: TextStyle(
                                color: theme.colorScheme.onSurfaceVariant),
                          ),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 20),

            // ── Název ──
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Název piva',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.sports_bar),
              ),
            ),

            const SizedBox(height: 20),

            // ── Hodnocení ──
            Text(
              'Hodnocení:',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Slider(
              value: _rating,
              min: 1,
              max: 5,
              divisions: 4,
              label: _rating.round().toString(),
              onChanged: (val) => setState(() => _rating = val),
            ),
            Center(
              child: Text(
                '${_rating.round()} hvězd',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── GPS ──
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: _isGettingLocation
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(Icons.my_location,
                            color: theme.colorScheme.primary),
                    onPressed: _getLocation,
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(_locationStatus)),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Ghost Mode Toggle (Pillar 5) ──
            SwitchListTile(
              title: const Text('Režim inkognito 👻'),
              subtitle: const Text(
                'Pivo se nepropíše do feedu přátel a žebříčku',
              ),
              value: _isGhost,
              onChanged: (val) => setState(() => _isGhost = val),
              secondary: Icon(
                _isGhost ? Icons.visibility_off : Icons.visibility,
                color: _isGhost
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurfaceVariant,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              tileColor: _isGhost
                  ? theme.colorScheme.primaryContainer
                  : theme.colorScheme.surfaceContainerHighest,
            ),

            const SizedBox(height: 24),

            // ── Uložit ──
            ElevatedButton(
              onPressed: _isSaving ? null : _saveBeer,
              child: _isSaving
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'ULOŽIT DO DENÍČKU',
                      style: TextStyle(fontSize: 18),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
