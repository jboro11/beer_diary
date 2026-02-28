import 'package:hive_flutter/hive_flutter.dart';

import '../models/beer_entry.dart';

/// Zapouzdřuje veškerou logiku Hive databáze.
///
/// UI obrazovky NIKDY nesmí volat `Hive.box()` přímo – vždy jen
/// přes tuto službu. To umožní snadné nahrazení backendem.
class LocalDatabaseService {
  LocalDatabaseService._();

  static const String _boxName = 'piva_box';

  static Box get _box => Hive.box(_boxName);

  /// Listenable pro ValueListenableBuilder (reaktivní UI).
  static Listenable get listenable => _box.listenable();

  // ─── CRUD ──────────────────────────────────────────────────

  /// Přidá nový pivní záznam. Vrací přidělený klíč.
  static Future<int> addBeer(BeerEntry entry) async {
    return await _box.add(entry.toMap());
  }

  /// Vrací všechna piva (nejnovější první).
  static List<BeerEntry> getAllBeers() {
    final entries = <BeerEntry>[];
    for (var i = _box.length - 1; i >= 0; i--) {
      final key = _box.keyAt(i);
      final data = _box.get(key);
      if (data != null) {
        entries.add(BeerEntry.fromMap(data as Map, key: key as int));
      }
    }
    return entries;
  }

  /// Smaže pivo podle klíče.
  static Future<void> deleteBeer(int key) async {
    await _box.delete(key);
  }

  /// Vrací pivo podle klíče.
  static BeerEntry? getBeer(int key) {
    final data = _box.get(key);
    if (data == null) return null;
    return BeerEntry.fromMap(data as Map, key: key);
  }

  // ─── STATISTIKY ────────────────────────────────────────────

  /// Celkový počet záznamů.
  static int get totalCount => _box.length;

  /// Průměrné hodnocení. Vrací 0.0 pokud jsou data prázdná.
  static double get averageRating {
    if (_box.isEmpty) return 0.0;
    double sum = 0;
    for (var i = 0; i < _box.length; i++) {
      sum += (((_box.getAt(i) as Map)['rating'] as num?) ?? 0).toDouble();
    }
    return sum / _box.length;
  }

  /// Vrací true pokud databáze nemá žádné záznamy.
  static bool get isEmpty => _box.isEmpty;
}
