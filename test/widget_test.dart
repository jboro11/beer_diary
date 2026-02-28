// Basic smoke test for BeerBuddy app.
//
// Verifies that the app launches and shows key UI elements.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:beer_diary/app.dart';
import 'package:beer_diary/main.dart';

void main() {
  testWidgets('BeerBuddyApp renders home screen with menu', (WidgetTester tester) async {
    await tester.pumpWidget(const BeerBuddyApp());

    // Hlavní nadpis
    expect(find.text('BeerBuddy 🍺'), findsOneWidget);

    // Menu tlačítka
    expect(find.text('Moje piva'), findsOneWidget);
    expect(find.text('Přidat pivo'), findsOneWidget);
    expect(find.text('Statistiky'), findsOneWidget);
    expect(find.text('Přátelé'), findsOneWidget);
    expect(find.text('Žebříček'), findsOneWidget);
  });

  testWidgets('BeerDiaryApp backward compat renders same UI', (WidgetTester tester) async {
    await tester.pumpWidget(const BeerDiaryApp());

    expect(find.text('BeerBuddy 🍺'), findsOneWidget);
    expect(find.text('Moje piva'), findsOneWidget);
  });
}
