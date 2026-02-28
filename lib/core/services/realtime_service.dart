import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';

/// ═══════════════════════════════════════════════════════════════
/// Pillar 3: Komunikační vrstva – REST vs Real-time
/// ═══════════════════════════════════════════════════════════════
///
/// ## Rozhodovací matice: REST API vs Real-time WebSockets
///
/// | Data                  | Metoda       | Důvod                              |
/// |-----------------------|--------------|------------------------------------|
/// | Historie logů         | REST (SDK)   | Read-heavy, stránkované, cache     |
/// | Profily uživatelů     | REST (SDK)   | Mění se zřídka                     |
/// | Katalog piv           | REST (SDK)   | Read-only pro většinu users        |
/// | Achievements          | REST (SDK)   | Zjišťují se jen občas              |
/// | **Žebříček (live)**   | **Realtime** | Okamžitá aktualizace při změně     |
/// | **Activity feed**     | **Realtime** | Kamarád pije → vidíš hned          |
/// | **Friendship requests** | **Realtime** | Notifikace v UI bez pull-refresh |
///
/// ## Architektura:
///
/// ```
/// RealtimeService
///   ├── subscribeToLeaderboard()
///   │     → Supabase Realtime channel na 'leaderboard' view
///   │     → Emituje Stream<List<LeaderboardEntry>>
///   │
///   ├── subscribeToFriendActivity(friendIds)
///   │     → Supabase Realtime channel na 'beer_logs'
///   │     → Filter: user_id IN friendIds AND is_ghost = false
///   │     → Emituje Stream<BeerLogEvent>
///   │
///   └── subscribeToFriendshipRequests()
///         → Supabase Realtime channel na 'friendships'
///         → Filter: addressee_id = current_user
///         → Emituje Stream<FriendshipEvent>
/// ```
class RealtimeService {
  RealtimeService._();

  static SupabaseClient? get _client => SupabaseConfig.client;
  static final List<RealtimeChannel> _channels = [];

  // ─── LEADERBOARD (Live) ──────────────────────────────────

  /// Naslouchá změnám v žebříčku.
  ///
  /// Vrací stream událostí z materialized view `leaderboard`.
  /// Přeposlechne INSERT/UPDATE/DELETE → UI přepočítá žebříček.
  static Stream<Map<String, dynamic>> leaderboardStream() {
    final client = _client;
    if (client == null) return const Stream.empty();

    final controller = StreamController<Map<String, dynamic>>.broadcast();

    final channel = client
        .channel('public:leaderboard')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'beer_logs', // Změny v logech → refresh leaderboardu
          callback: (PostgresChangePayload payload) {
            controller.add({
              'event': payload.eventType.name,
              'new': payload.newRecord,
              'old': payload.oldRecord,
            });
          },
        )
        .subscribe();

    _channels.add(channel);

    return controller.stream;
  }

  // ─── FRIEND ACTIVITY (Live Feed) ────────────────────────

  /// Naslouchá novým pivům přátel (živý activity feed).
  ///
  /// [friendIds] – seznam UUID přátel pro filtrování.
  /// Vrací stream nových beer_log záznamů (jen ne-ghost).
  static Stream<Map<String, dynamic>> friendActivityStream(
    List<String> friendIds,
  ) {
    final client = _client;
    if (client == null || friendIds.isEmpty) return const Stream.empty();

    final controller = StreamController<Map<String, dynamic>>.broadcast();

    final channel = client
        .channel('friend-activity')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'beer_logs',
          callback: (PostgresChangePayload payload) {
            final newRecord = payload.newRecord;
            // Filtr: jen přátelé + ne-ghost
            if (friendIds.contains(newRecord['user_id']) &&
                newRecord['is_ghost'] != true) {
              controller.add(newRecord);
            }
          },
        )
        .subscribe();

    _channels.add(channel);

    return controller.stream;
  }

  // ─── FRIENDSHIP REQUESTS (Live) ─────────────────────────

  /// Naslouchá novým žádostem o přátelství.
  ///
  /// Vrací stream nových/upravených friendship záznamů
  /// kde `addressee_id` = aktuální uživatel.
  static Stream<Map<String, dynamic>> friendshipRequestStream() {
    final client = _client;
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) return const Stream.empty();

    final controller = StreamController<Map<String, dynamic>>.broadcast();

    final channel = client
        .channel('friendship-requests')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'friendships',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'addressee_id',
            value: userId,
          ),
          callback: (PostgresChangePayload payload) {
            controller.add({
              'event': payload.eventType.name,
              'new': payload.newRecord,
              'old': payload.oldRecord,
            });
          },
        )
        .subscribe();

    _channels.add(channel);

    return controller.stream;
  }

  // ─── LIFECYCLE ───────────────────────────────────────────

  /// Odpojí všechny aktivní kanály.
  static Future<void> disposeAll() async {
    for (final channel in _channels) {
      await _client?.removeChannel(channel);
    }
    _channels.clear();
    debugPrint('[Realtime] All channels disposed');
  }
}
