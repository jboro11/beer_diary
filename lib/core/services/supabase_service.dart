import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';
import '../models/beer_log.dart';
import '../models/beer.dart';

/// Služba pro komunikaci se Supabase backendem.
///
/// Zapouzdřuje všechny CRUD operace nad databází.
/// Pokud Supabase není nakonfigurován (dev/offline mód), metody
/// vrací null a UI spadne na lokální Hive úložiště.
class SupabaseService {
  SupabaseService._();

  static SupabaseClient? get _client => SupabaseConfig.client;

  /// Vrací true pokud je Supabase nakonfigurován a uživatel přihlášen.
  static bool get isAvailable =>
      _client != null && _client!.auth.currentUser != null;

  /// ID aktuálně přihlášeného uživatele.
  static String? get currentUserId => _client?.auth.currentUser?.id;

  // ─── BEER LOG ──────────────────────────────────────────────

  /// Odešle záznam o vypitém pivu do Supabase.
  ///
  /// Toto je nejdůležitější API volání aplikace – "One-Tap" log.
  /// Vrací vložený [BeerLog] s přiřazeným ID, nebo null při chybě.
  static Future<BeerLog?> logBeer({
    required String beerName,
    int? beerId,
    int? rating,
    String? note,
    String? imageUrl,
    double? latitude,
    double? longitude,
    String? venueName,
    bool isGhost = false,
  }) async {
    final client = _client;
    final userId = currentUserId;
    if (client == null || userId == null) return null;

    final log = BeerLog(
      userId: userId,
      beerId: beerId,
      beerName: beerName,
      rating: rating,
      note: note,
      imageUrl: imageUrl,
      latitude: latitude,
      longitude: longitude,
      venueName: venueName,
      isGhost: isGhost,
      loggedAt: DateTime.now(),
    );

    try {
      final response = await client
          .from('beer_logs')
          .insert(log.toJson())
          .select()
          .single();

      return BeerLog.fromJson(response);
    } catch (_) {
      return null;
    }
  }

  /// Načte záznamy přihlášeného uživatele (stránkované).
  static Future<List<BeerLog>> getMyLogs({
    int limit = 50,
    int offset = 0,
  }) async {
    final client = _client;
    final userId = currentUserId;
    if (client == null || userId == null) return [];

    final response = await client
        .from('beer_logs')
        .select()
        .eq('user_id', userId)
        .order('logged_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (response as List)
        .map((json) => BeerLog.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Smaže záznam.
  static Future<void> deleteLog(int logId) async {
    final client = _client;
    if (client == null) return;

    await client.from('beer_logs').delete().eq('id', logId);
  }

  // ─── BEER CATALOG ─────────────────────────────────────────

  /// Vyhledá piva v katalogu podle názvu (autocomplete).
  static Future<List<Beer>> searchBeers(String query) async {
    final client = _client;
    if (client == null || query.isEmpty) return [];

    // Escape LIKE special characters
    final sanitized = query
        .replaceAll(r'\', r'\\')
        .replaceAll('%', r'\%')
        .replaceAll('_', r'\_');

    final response = await client
        .from('beers')
        .select()
        .ilike('name', '%$sanitized%')
        .limit(20);

    return (response as List)
        .map((json) => Beer.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Přidá nové pivo do katalogu.
  static Future<Beer?> addBeer(Beer beer) async {
    final client = _client;
    if (client == null) return null;

    final response = await client
        .from('beers')
        .insert(beer.toJson())
        .select()
        .single();

    return Beer.fromJson(response);
  }

  // ─── LEADERBOARD ──────────────────────────────────────────

  /// Načte žebříček (materialized view).
  static Future<List<Map<String, dynamic>>> getLeaderboard({
    int limit = 50,
  }) async {
    final client = _client;
    if (client == null) return [];

    final response = await client
        .from('leaderboard')
        .select()
        .order('total_beers', ascending: false)
        .limit(limit);

    return List<Map<String, dynamic>>.from(response as List);
  }
}
