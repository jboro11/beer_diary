import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../../../core/services/auth_service.dart';

/// ═══════════════════════════════════════════════════════════════
/// Pillar 1: Auth Screen – Frictionless One-Tap Login
/// ═══════════════════════════════════════════════════════════════
///
/// Minimalistický přihlašovací screen optimalizovaný pro rychlost:
/// - Maximálně 2 tlačítka (Google + Apple)
/// - Žádné formuláře, žádná registrace – jen SSO
/// - Apple tlačítko jen na iOS/macOS
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isLoading = true);
    final success = await AuthService.signInWithGoogle();
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Přihlášení přes Google se nezdařilo')),
      );
    }
    // Úspěch → AuthService.authStateStream emituje 'signed_in'
    // → app.dart automaticky přepne na HomeScreen
  }

  Future<void> _handleAppleSignIn() async {
    setState(() => _isLoading = true);
    final success = await AuthService.signInWithApple();
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (!success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Přihlášení přes Apple se nezdařilo')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),

              // Logo + Nadpis
              Icon(
                Icons.sports_bar,
                size: 80,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'BeerBuddy 🍺',
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Pivní deník s přáteli',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),

              const Spacer(flex: 2),

              // Loading indikátor
              if (_isLoading) ...[
                const CircularProgressIndicator(),
                const SizedBox(height: 24),
              ],

              // Google Sign-In (vždy dostupné)
              if (!_isLoading) ...[
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton.icon(
                    onPressed: _handleGoogleSignIn,
                    icon: const Icon(Icons.g_mobiledata, size: 24),
                    label: const Text(
                      'Pokračovat přes Google',
                      style: TextStyle(fontSize: 16),
                    ),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Apple Sign-In (jen iOS/macOS)
                if (!kIsWeb && (Platform.isIOS || Platform.isMacOS))
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: _handleAppleSignIn,
                      icon: const Icon(Icons.apple, size: 24),
                      label: const Text(
                        'Pokračovat přes Apple',
                        style: TextStyle(fontSize: 16),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
              ],

              const Spacer(),

              // Právní text
              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Text(
                  'Přihlášením souhlasíš s podmínkami použití\na zásadami ochrany osobních údajů.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
