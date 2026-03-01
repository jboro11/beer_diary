import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ═══════════════════════════════════════════════════════════════
/// Pillar 6: Age Gate – Ověření 18+ let
/// ═══════════════════════════════════════════════════════════════
///
/// ## UX/UI Design pro App Store/Google Play compliance:
///
/// 1. Zobrazí se JEN při prvním spuštění (persistent flag).
/// 2. Jednoduchý rok narození → výpočet věku.
/// 3. Pokud < 18 → blokující obrazovka, nelze pokračovat.
/// 4. Pokud ≥ 18 → uloží se flag a nikdy se nezobrazí znovu.
///
/// ## Proč rok narození místo checkboxu "jsem 18+":
///
/// - Apple/Google ODMÍTAJÍ prosté checkboxy jako "age verification".
/// - Rok narození je minimální akceptovatelný standard.
/// - Datum se NEUKLÁDÁ na server (GDPR) – jen boolean flag.
///
/// ## Flow:
/// ```
/// Splash → AgeGate (pokud poprvé) → Auth → Home
///               ↓
///     Picker "Rok narození"
///               ↓
///     Výpočet: DateTime.now().year - rok ≥ 18?
///               ↓
///     ANO → SharedPreferences 'age_verified' = true → pokračovat
///     NE  → "Omlouváme se, aplikace je jen pro 18+"
/// ```
class AgeGateScreen extends StatefulWidget {
  final VoidCallback onVerified;

  const AgeGateScreen({super.key, required this.onVerified});

  @override
  State<AgeGateScreen> createState() => _AgeGateScreenState();
}

class _AgeGateScreenState extends State<AgeGateScreen> {
  int? _selectedYear;
  bool _isUnderage = false;

  static const String _prefKey = 'age_verified';

  /// Zkontroluje, zda už byl věk ověřen.
  static Future<bool> isVerified() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_prefKey) ?? false;
  }

  Future<void> _verify() async {
    if (_selectedYear == null) return;

    final age = DateTime.now().year - _selectedYear!;

    if (age >= 18) {
      // Uložit flag – NEUKLADÁME rok narození (GDPR).
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKey, true);
      widget.onVerified();
    } else {
      setState(() => _isUnderage = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentYear = DateTime.now().year;

    if (_isUnderage) {
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.block,
                  size: 80,
                  color: theme.colorScheme.error,
                ),
                const SizedBox(height: 24),
                Text(
                  'Omlouváme se',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'BeerBuddy je určen pouze pro osoby\nstarší 18 let.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              const Spacer(flex: 2),

              Icon(
                Icons.verified_user,
                size: 64,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Ověření věku',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'BeerBuddy obsahuje obsah pro dospělé.\nZadej prosím svůj rok narození.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),

              const Spacer(),

              // Year picker – DropdownButton je jednodušší UX než DatePicker
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: theme.colorScheme.outline,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    isExpanded: true,
                    hint: const Text('Vyber rok narození'),
                    value: _selectedYear,
                    items: List.generate(
                      80, // roky zpět
                      (i) => currentYear - i - 10, // od 10 do 90 let
                    )
                        .map(
                          (year) => DropdownMenuItem(
                            value: year,
                            child: Text('$year'),
                          ),
                        )
                        .toList(),
                    onChanged: (year) => setState(() {
                      _selectedYear = year;
                      _isUnderage = false;
                    }),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _selectedYear != null ? _verify : null,
                  child: const Text('Potvrdit'),
                ),
              ),

              const Spacer(flex: 2),

              Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Text(
                  'Datum narození neukládáme.\nSlouží pouze k ověření věku.',
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
