import 'package:flutter/material.dart';

import 'core/theme/app_theme.dart';
import 'core/config/supabase_config.dart';
import 'core/services/auth_service.dart';
import 'features/auth/screens/age_gate_screen.dart';
import 'features/auth/screens/auth_screen.dart';
import 'features/home/screens/main_scaffold.dart';

/// Kořenový widget aplikace BeerBuddy.
///
/// ## Flow (Pillar 6 → Pillar 1 → Home):
/// ```
/// AgeGate (pokud poprvé) → AuthScreen (pokud Supabase) → MainScaffold
/// ```
class BeerBuddyApp extends StatelessWidget {
  const BeerBuddyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BeerBuddy',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: const _AppGate(),
    );
  }
}

/// Řídí flow: Age Gate → Auth → MainScaffold.
class _AppGate extends StatefulWidget {
  const _AppGate();

  @override
  State<_AppGate> createState() => _AppGateState();
}

class _AppGateState extends State<_AppGate> {
  bool _ageChecked = false;
  bool _ageVerified = false;

  @override
  void initState() {
    super.initState();
    _checkAge();
  }

  Future<void> _checkAge() async {
    final verified = await AgeGateScreen.isVerified();
    if (!mounted) return;
    setState(() {
      _ageChecked = true;
      _ageVerified = verified;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Čekáme na kontrolu věku
    if (!_ageChecked) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // Pillar 6: Age Gate
    if (!_ageVerified) {
      return AgeGateScreen(
        onVerified: () => setState(() => _ageVerified = true),
      );
    }

    // Pillar 1: Auth (jen pokud je Supabase nakonfigurován)
    if (SupabaseConfig.client != null && !AuthService.isLoggedIn) {
      return const AuthScreen();
    }

    // Hlavní aplikace s BottomNavigationBar
    return const MainScaffold();
  }
}
