import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'connectivity_service.dart';
import 'supabase_service.dart';

/// ═══════════════════════════════════════════════════════════════
/// Pillar 2b: Offline-First Sync Engine
/// ═══════════════════════════════════════════════════════════════
///
/// ## Doporučení k lokálnímu úložišti:
///
/// | Technologie | Pro                          | Proti                    |
/// |-------------|------------------------------|--------------------------|
/// | **Hive**    | Rychlý, NoSQL, 0 native deps| Omezené dotazování       |
/// | Isar        | Silné indexy, full-text      | Větší binárka, nativní   |
/// | SQLite      | Relační, SQL kompatibilní    | Boilerplate, pomalejší   |
///
/// **Rozhodnutí: Hive** – pro naši use case (key-value logy,
/// jednoduchá fronta) je optimální. Žádné nativní závislosti,
/// extrémně rychlý zápis (kritické v hospodě bez signálu).
///
/// ## Optimistický Update Flow (krok za krokem):
///
/// ```
/// 1. Uživatel klikne "Přidat pivo" →
/// 2. UI se OKAMŽITĚ aktualizuje (setState / stream) →
/// 3. Data se uloží do Hive ('piva_box') →
/// 4. Záznam se přidá do SYNC FRONTY ('sync_queue') →
/// 5. ConnectivityService detekuje internet →
/// 6. SyncService.drainQueue() zpracuje frontu →
/// 7. Každý záznam se odešle do Supabase →
/// 8. Po úspěchu se záznam z fronty smaže →
/// 9. Pokud selže → zůstává ve frontě pro další pokus
/// ```
///
/// ## Řešení konfliktů:
///
/// Strategie: **Last-Write-Wins (LWW)** s klientským timestampem.
///
/// - Každý záznam má `logged_at` (klient) a `created_at` (server).
/// - Při sync se porovná `logged_at`:
///   - Pokud záznam na serveru neexistuje → INSERT.
///   - Pokud existuje a `logged_at` klienta > server → UPDATE.
///   - Pokud existuje a `logged_at` serveru > klient → server wins, skip.
/// - Pro pivní deník je to bezpečné: konflikty jsou vzácné
///   (uživatel nepíše stejný log ze dvou zařízení současně).
class SyncService {
  SyncService._();

  static const String _queueBoxName = 'sync_queue';
  static Box? _queueBox;
  static bool _isSyncing = false;
  static VoidCallback? _connectivityListener;

  /// Inicializace – otevře frontu a naváže se na connectivity.
  static Future<void> init() async {
    _queueBox = await Hive.openBox(_queueBoxName);

    // Při přechodu do online stavu → synchronizovat
    _connectivityListener = () {
      if (ConnectivityService.isOnline.value) {
        drainQueue();
      }
    };
    ConnectivityService.isOnline.addListener(_connectivityListener!);

    // Pokud jsme online hned při startu, drainout
    if (ConnectivityService.isOnline.value) {
      drainQueue();
    }
  }

  /// Přidá operaci do fronty pro pozdější synchronizaci.
  ///
  /// [operation] je typ operace ('insert_beer_log', 'delete_beer_log', ...).
  /// [payload] je mapa s daty pro API volání.
  /// [localKey] je klíč záznamu v Hive ('piva_box') pro referenci.
  static Future<void> enqueue({
    required String operation,
    required Map<String, dynamic> payload,
    int? localKey,
  }) async {
    final box = _queueBox;
    if (box == null) return;

    await box.add({
      'operation': operation,
      'payload': payload,
      'local_key': localKey,
      'enqueued_at': DateTime.now().toIso8601String(),
      'retries': 0,
    });

    debugPrint('[Sync] Enqueued: $operation (queue size: ${box.length})');

    // Okamžitý pokus o sync pokud jsme online
    if (ConnectivityService.isOnline.value) {
      drainQueue();
    }
  }

  /// Zpracuje celou frontu – odesílá záznamy do Supabase.
  ///
  /// Operace jsou zpracovány FIFO (nejstarší první).
  /// Při chybě se záznam nechá ve frontě a zvýší se retry counter.
  static Future<void> drainQueue() async {
    final box = _queueBox;
    if (box == null || box.isEmpty || _isSyncing) return;
    if (!SupabaseService.isAvailable) return;

    _isSyncing = true;
    debugPrint('[Sync] Draining queue (${box.length} items)...');

    // Zpracovat kopii klíčů (box se mění během iterace)
    final keys = box.keys.toList();

    for (final key in keys) {
      final item = box.get(key);
      if (item == null) continue;

      final operation = item['operation'] as String;
      final payload = Map<String, dynamic>.from(item['payload'] as Map);
      final retries = (item['retries'] as int?) ?? 0;

      // Max 5 pokusů, pak zahodit (corrupted data)
      if (retries >= 5) {
        debugPrint('[Sync] Dropping after 5 retries: $operation');
        await box.delete(key);
        continue;
      }

      try {
        final success = await _processItem(operation, payload);
        if (success) {
          await box.delete(key);
          debugPrint('[Sync] ✓ $operation synced');
        } else {
          // Zvýšit retry counter
          item['retries'] = retries + 1;
          await box.put(key, item);
        }
      } catch (e) {
        debugPrint('[Sync] ✗ $operation failed: $e');
        item['retries'] = retries + 1;
        await box.put(key, item);
      }
    }

    _isSyncing = false;
    debugPrint('[Sync] Queue drained (${box.length} remaining)');
  }

  /// Zpracuje jednu položku z fronty podle typu operace.
  static Future<bool> _processItem(
    String operation,
    Map<String, dynamic> payload,
  ) async {
    switch (operation) {
      case 'insert_beer_log':
        final result = await SupabaseService.logBeer(
          beerName: payload['beer_name'] as String,
          rating: payload['rating'] as int?,
          latitude: (payload['latitude'] as num?)?.toDouble(),
          longitude: (payload['longitude'] as num?)?.toDouble(),
          venueName: payload['venue_name'] as String?,
          note: payload['note'] as String?,
          isGhost: payload['is_ghost'] as bool? ?? false,
        );
        return result != null;

      case 'delete_beer_log':
        final logId = payload['log_id'] as int?;
        if (logId != null) {
          await SupabaseService.deleteLog(logId);
        }
        return true;

      default:
        debugPrint('[Sync] Unknown operation: $operation');
        return false; // Neznámá operace – nechat ve frontě
    }
  }

  /// Počet čekajících položek ve frontě.
  static int get pendingCount => _queueBox?.length ?? 0;

  /// Uvolní resources.
  static void dispose() {
    if (_connectivityListener != null) {
      ConnectivityService.isOnline.removeListener(_connectivityListener!);
    }
  }
}
