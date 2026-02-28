import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/config/supabase_config.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lokální úložiště (offline-first)
  await Hive.initFlutter();
  await Hive.openBox('piva_box');

  // Supabase (pokud jsou definovány --dart-define proměnné)
  await SupabaseConfig.init();

  runApp(const BeerBuddyApp());
}

// ─────────────────────────────────────────────────────────────
// Zpětná kompatibilita: původní BeerDiaryApp se zachovává jako
// alias, aby existující testy a reference fungovaly.
// ─────────────────────────────────────────────────────────────
class BeerDiaryApp extends StatelessWidget {
  const BeerDiaryApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const BeerBuddyApp();
  }
}