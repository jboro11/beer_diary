// Smoke tests for BeerBuddy app.
//
// Verifies key UI elements and models.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:beer_diary/features/home/screens/home_screen.dart';
import 'package:beer_diary/features/auth/screens/age_gate_screen.dart';

void main() {
  testWidgets('HomeScreen renders menu buttons', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: HomeScreen()),
    );

    // Hlavní nadpis
    expect(find.text('BeerBuddy 🍺'), findsOneWidget);

    // Menu tlačítka
    expect(find.text('Moje piva'), findsOneWidget);
    expect(find.text('Přidat pivo'), findsOneWidget);
    expect(find.text('Statistiky'), findsOneWidget);
    expect(find.text('Přátelé'), findsOneWidget);
    expect(find.text('Žebříček'), findsOneWidget);
  });

  testWidgets('AgeGateScreen renders year picker', (WidgetTester tester) async {
    bool verified = false;
    await tester.pumpWidget(
      MaterialApp(
        home: AgeGateScreen(onVerified: () => verified = true),
      ),
    );

    expect(find.text('Ověření věku'), findsOneWidget);
    expect(find.text('Vyber rok narození'), findsOneWidget);
    expect(find.text('Potvrdit'), findsOneWidget);

    // Potvrdit button should be disabled without selection
    final button = tester.widget<ElevatedButton>(
      find.widgetWithText(ElevatedButton, 'Potvrdit'),
    );
    expect(button.onPressed, isNull);
    expect(verified, isFalse);
  });
}
