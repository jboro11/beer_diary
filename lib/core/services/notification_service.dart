import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';

/// ═══════════════════════════════════════════════════════════════
/// Pillar 4: Push Notifikace – Event-Driven Backend
/// ═══════════════════════════════════════════════════════════════
///
/// ## Architektura (end-to-end flow):
///
/// ```
/// [Uživatel přidá pivo]
///   → INSERT INTO beer_logs
///   → Supabase Database Webhook (na INSERT)
///   → Zavolá Edge Function 'on-beer-logged'
///   → Edge Function:
///       1. Zavolá check_leaderboard_overtakes(user_id)
///       2. Pokud user předběhl přítele:
///          a. Načte FCM tokeny předběhnutého uživatele
///          b. Odešle push notifikaci přes FCM HTTP API v2
///   → FCM/APNs doručí notifikaci na zařízení
///   → Flutter NotificationService zobrazí notifikaci
/// ```
///
/// ## Supabase Dashboard konfigurace:
///
/// 1. Database → Webhooks → New webhook:
///    - Name: `on_beer_logged`
///    - Table: `beer_logs`
///    - Events: INSERT
///    - Type: Supabase Edge Function
///    - Function: `on-beer-logged`
///
/// 2. Edge Function (viz `supabase/functions/on-beer-logged/index.ts`)
///
/// ## Flutter strana:
///
/// Tento service zapouzdřuje registraci FCM tokenu a jeho uložení
/// do Supabase tabulky `push_tokens`.
/// Samotné zpracování příchozích notifikací závisí na
/// firebase_messaging (FCM) balíčku, který musí být nakonfigurován
/// v Firebase Console a propojený s Supabase.
class NotificationService {
  NotificationService._();

  static SupabaseClient? get _client => SupabaseConfig.client;

  /// Registruje push token do databáze.
  ///
  /// Volat po získání FCM/APNs tokenu z firebase_messaging:
  /// ```dart
  /// final token = await FirebaseMessaging.instance.getToken();
  /// if (token != null) {
  ///   await NotificationService.registerToken(token, 'android');
  /// }
  /// ```
  static Future<void> registerToken(String token, String platform) async {
    final client = _client;
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) return;

    try {
      await client.from('push_tokens').upsert(
        {
          'user_id': userId,
          'token': token,
          'platform': platform,
        },
        onConflict: 'token',
      );
      debugPrint('[Notification] Token registered for $platform');
    } catch (e) {
      debugPrint('[Notification] Token registration failed: $e');
    }
  }

  /// Odregistruje token (při logout).
  static Future<void> unregisterToken(String token) async {
    final client = _client;
    if (client == null) return;

    try {
      await client.from('push_tokens').delete().eq('token', token);
    } catch (e) {
      debugPrint('[Notification] Token unregistration failed: $e');
    }
  }

  /// Aktualizuje ghost mode v profilu uživatele.
  ///
  /// Ghost mode = pivo se loguje jen pro osobní statistiky,
  /// nepropíše se do feedu přátel ani žebříčku.
  static Future<void> setGhostMode(bool enabled) async {
    final client = _client;
    final userId = client?.auth.currentUser?.id;
    if (client == null || userId == null) return;

    try {
      await client.from('profiles').update({
        'ghost_mode': enabled,
      }).eq('id', userId);
    } catch (e) {
      debugPrint('[Notification] Ghost mode update failed: $e');
    }
  }
}
