import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// ═══════════════════════════════════════════════════════════════
/// Pillar 2a: Connectivity Monitor
/// ═══════════════════════════════════════════════════════════════
///
/// Sleduje stav internetového připojení.
/// Když se změní z offline → online, notifikuje SyncService
/// k zahájení synchronizace fronty.
///
/// ## Architektura:
/// ```
/// ConnectivityService (Stream<bool>)
///   ├── SyncService naslouchá → při online drainuje frontu
///   └── UI může zobrazit offline banner
/// ```
class ConnectivityService {
  ConnectivityService._();

  static final Connectivity _connectivity = Connectivity();
  static StreamSubscription<List<ConnectivityResult>>? _subscription;
  static final ValueNotifier<bool> isOnline = ValueNotifier<bool>(true);

  /// Inicializace – volat jednou v main().
  static Future<void> init() async {
    // Zjistit počáteční stav
    final results = await _connectivity.checkConnectivity();
    isOnline.value = !results.contains(ConnectivityResult.none);

    // Naslouchat změnám
    _subscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        final online = !results.contains(ConnectivityResult.none);
        if (online != isOnline.value) {
          isOnline.value = online;
          debugPrint('[Connectivity] ${online ? "ONLINE" : "OFFLINE"}');
        }
      },
    );
  }

  /// Uvolní resources.
  static void dispose() {
    _subscription?.cancel();
    _subscription = null;
  }
}
