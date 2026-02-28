import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/supabase_config.dart';

/// ═══════════════════════════════════════════════════════════════
/// Pillar 1: Autentizace – Frictionless Login
/// ═══════════════════════════════════════════════════════════════
///
/// ## Architektura:
///
/// 1. **Google SSO (Native):**
///    - Použijeme `supabase.auth.signInWithOAuth(OAuthProvider.google)`
///      pro web-based flow, nebo nativní ID token flow.
///    - Supabase automaticky vytvoří `auth.users` záznam.
///    - Trigger `handle_new_user()` vytvoří `profiles` záznam.
///
/// 2. **Apple SSO (Native):**
///    - Použijeme `supabase.auth.signInWithApple()` (built-in v Supabase).
///    - Apple vrátí `id_token`, Supabase ho verifikuje.
///
/// 3. **Account Linking (propojení účtů):**
///    - Supabase auth automaticky propojí účty se stejným emailem
///      (konfigurovatelné v Supabase Dashboard → Auth → Settings →
///      "Enable automatic account linking").
///    - Pokud se uživatel přihlásí přes Google (jan@email.cz) a poté
///      přes Apple (jan@email.cz), Supabase je AUTOMATICKY propojí
///      pod jedním auth.users ID.
///    - Pro případ jiného emailu nabídneme manuální linking přes
///      `supabase.auth.linkIdentity()`.
///
/// ## Flow:
/// ```
/// [Uživatel klikne "Přihlásit se přes Google"]
///   → signInWithGoogle()
///   → Supabase Auth verifikuje Google ID token
///   → auth.users INSERT (nebo match existující)
///   → Trigger → profiles INSERT (pokud nový)
///   → AuthService.authStateStream emituje 'signed_in'
///   → UI přejde na HomeScreen
/// ```
class AuthService {
  AuthService._();

  static SupabaseClient? get _client => SupabaseConfig.client;

  /// Stream změn autentizačního stavu.
  /// UI naslouchá a reaguje na login/logout.
  static Stream<AuthState>? get authStateStream =>
      _client?.auth.onAuthStateChange;

  /// Aktuální session (null = nepřihlášen).
  static Session? get currentSession => _client?.auth.currentSession;

  /// Aktuální uživatel (null = nepřihlášen).
  static User? get currentUser => _client?.auth.currentUser;

  /// Je uživatel přihlášen?
  static bool get isLoggedIn => currentUser != null;

  // ─── GOOGLE SSO ──────────────────────────────────────────

  /// Přihlášení přes Google OAuth.
  ///
  /// Na mobilních platformách otevře nativní Google Sign-In dialog.
  /// Na webu přesměruje na Google login stránku.
  static Future<bool> signInWithGoogle() async {
    final client = _client;
    if (client == null) return false;

    try {
      // Supabase OAuth flow – otevře webview / browser
      final result = await client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: _redirectUrl,
      );
      return result;
    } catch (e) {
      debugPrint('Google SSO error: $e');
      return false;
    }
  }

  // ─── APPLE SSO ───────────────────────────────────────────

  /// Přihlášení přes Apple Sign-In.
  ///
  /// Dostupné jen na iOS/macOS. Na Androidu se nabídne Google.
  /// Apple vrátí `authorization_code`, Supabase ho vymění za session.
  static Future<bool> signInWithApple() async {
    final client = _client;
    if (client == null) return false;

    try {
      final result = await client.auth.signInWithOAuth(
        OAuthProvider.apple,
        redirectTo: _redirectUrl,
      );
      return result;
    } catch (e) {
      debugPrint('Apple SSO error: $e');
      return false;
    }
  }

  // ─── ACCOUNT LINKING ─────────────────────────────────────

  /// Propojí další OAuth provider k existujícímu účtu.
  ///
  /// Použití: Uživatel je přihlášen přes Google a chce přidat Apple.
  /// Toto umožní přihlášení oběma poskytovateli na stejný účet.
  static Future<bool> linkIdentity(OAuthProvider provider) async {
    final client = _client;
    if (client == null || !isLoggedIn) return false;

    try {
      await client.auth.linkIdentity(provider);
      return true;
    } catch (e) {
      debugPrint('Link identity error: $e');
      return false;
    }
  }

  // ─── ODHLÁŠENÍ ───────────────────────────────────────────

  /// Odhlásí uživatele (lokálně i ze serveru).
  static Future<void> signOut() async {
    final client = _client;
    if (client == null) return;

    await client.auth.signOut();
  }

  // ─── GDPR: Smazání účtu ──────────────────────────────────

  /// Kompletní smazání účtu (GDPR hard-delete).
  ///
  /// Volá PostgreSQL funkci `gdpr_delete_user()`, která kaskádově
  /// smaže profil, beer_logs, friendships, team_members, achievements
  /// a nakonec auth.users záznam.
  static Future<bool> deleteAccount() async {
    final client = _client;
    final userId = currentUser?.id;
    if (client == null || userId == null) return false;

    try {
      await client.rpc('gdpr_delete_user', params: {
        'target_user_id': userId,
      });
      await client.auth.signOut();
      return true;
    } catch (e) {
      debugPrint('GDPR delete error: $e');
      return false;
    }
  }

  // ─── HELPERS ─────────────────────────────────────────────

  /// Deep link redirect URL pro OAuth callback.
  static String get _redirectUrl {
    if (kIsWeb) return Uri.base.origin;
    // Na mobilech: custom URL scheme definovaný v AndroidManifest / Info.plist
    return 'io.supabase.beerbuddy://login-callback/';
  }

  /// Zda je Apple Sign-In k dispozici (jen iOS/macOS).
  static bool get isAppleAvailable {
    if (kIsWeb) return false;
    return Platform.isIOS || Platform.isMacOS;
  }
}
