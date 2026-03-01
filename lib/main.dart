import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/config/supabase_config.dart';
import 'core/services/connectivity_service.dart';
import 'core/services/sync_service.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lokální úložiště (offline-first)
  await Hive.initFlutter();
  await Hive.openBox('piva_box');

  // Pillar 2a: Connectivity monitoring
  await ConnectivityService.init();

  // Supabase (pokud jsou definovány --dart-define proměnné)
  await SupabaseConfig.init();

  // Pillar 2b: Sync engine (naváže se na connectivity)
  await SyncService.init();

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