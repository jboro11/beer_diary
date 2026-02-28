import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

import '../../../core/services/location_service.dart';
import '../../../core/services/image_service.dart';
import '../../../core/services/supabase_service.dart';

/// Obrazovka pro přidání nového piva – "One-Tap" flow.
///
/// 1. Lokální uložení do Hive (offline-first).
/// 2. Pokud je Supabase dostupný, synchronizace do cloudu.
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

  /// Hlavní API volání: uloží pivo lokálně + do Supabase.
  Future<void> _saveBeer() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Musíš zadat název piva!')),
      );
      return;
    }

    setState(() => _isSaving = true);

    // ── 1. Lokální uložení (offline-first) ──
    final box = Hive.box('piva_box');
    box.add({
      'name': _nameController.text,
      'rating': _rating,
      'date': DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now()),
      'imagePath': _selectedImage?.path,
      'lat': _lat,
      'lng': _lng,
    });

    // ── 2. Supabase sync (pokud je dostupný) ──
    if (SupabaseService.isAvailable) {
      await SupabaseService.logBeer(
        beerName: _nameController.text,
        rating: _rating.round(),
        latitude: _lat != 0.0 ? _lat : null,
        longitude: _lng != 0.0 ? _lng : null,
      );
    }

    if (!mounted) return;
    setState(() => _isSaving = false);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nový úlovek'),
        backgroundColor: Colors.green[50],
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
                  color: Colors.grey[100],
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _selectedImage != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(_selectedImage!, fit: BoxFit.cover),
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt, size: 50, color: Colors.grey),
                          Text(
                            'Klikni a vyfoť pivo!',
                            style: TextStyle(color: Colors.grey),
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
            const Text(
              'Hodnocení:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Slider(
              value: _rating,
              min: 1,
              max: 5,
              divisions: 4,
              label: _rating.round().toString(),
              activeColor: Colors.green,
              onChanged: (val) => setState(() => _rating = val),
            ),
            Center(
              child: Text(
                '${_rating.round()} hvězd',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── GPS ──
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.green[50],
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
                        : const Icon(Icons.my_location, color: Colors.green),
                    onPressed: _getLocation,
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(_locationStatus)),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // ── Uložit ──
            ElevatedButton(
              onPressed: _isSaving ? null : _saveBeer,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E7D32),
                padding: const EdgeInsets.symmetric(vertical: 15),
                foregroundColor: Colors.white,
              ),
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
