import 'package:supabase_flutter/supabase_flutter.dart';

/// Centrální konfigurace a inicializace Supabase klienta.
///
/// Hodnoty [supabaseUrl] a [supabaseAnonKey] se nastavují
/// přes --dart-define při buildu:
/// ```
/// flutter run \
///   --dart-define=SUPABASE_URL=https://xxx.supabase.co \
///   --dart-define=SUPABASE_ANON_KEY=eyJ...
/// ```
class SupabaseConfig {
  SupabaseConfig._();

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: '',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: '',
  );

  /// Inicializuje Supabase SDK. Volat jednou v main().
  static Future<void> init() async {
    if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      // V offline / dev režimu se Supabase nepřipojí – aplikace
      // funguje s lokálním Hive úložištěm.
      return;
    }

    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
    _initialized = true;
  }

  static bool _initialized = false;

  /// Vrací Supabase klienta, nebo null pokud není nakonfigurován.
  static SupabaseClient? get client {
    if (!_initialized || supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
      return null;
    }
    return Supabase.instance.client;
  }
}
