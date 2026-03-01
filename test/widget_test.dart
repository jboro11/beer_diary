// Smoke tests for BeerBuddy app.
//
// Verifies key UI elements and models.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:beer_diary/features/home/screens/main_scaffold.dart';
import 'package:beer_diary/features/auth/screens/age_gate_screen.dart';
import 'package:beer_diary/core/models/beer_entry.dart';

void main() {
  setUpAll(() async {
    // Hive musí být inicializován pro MainScaffold (BeerListScreen + StatsScreen)
    await Hive.initFlutter();
    if (!Hive.isBoxOpen('piva_box')) {
      await Hive.openBox('piva_box');
    }
  });

  testWidgets('MainScaffold renders bottom navigation', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: MainScaffold()),
    );
    await tester.pumpAndSettle();

    // Bottom navigation labels
    expect(find.text('Piva'), findsOneWidget);
    expect(find.text('Statistiky'), findsOneWidget);
    expect(find.text('Přátelé'), findsOneWidget);
    expect(find.text('Žebříček'), findsOneWidget);

    // FAB
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });

  testWidgets('MainScaffold switches tabs on tap', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: MainScaffold()),
    );
    await tester.pumpAndSettle();

    // Default tab is Piva (BeerListScreen)
    expect(find.text('Moje piva 🍺'), findsOneWidget);

    // Tap Statistiky
    await tester.tap(find.text('Statistiky'));
    await tester.pumpAndSettle();
    expect(find.text('Statistiky 📊'), findsOneWidget);

    // Tap Přátelé
    await tester.tap(find.text('Přátelé'));
    await tester.pumpAndSettle();
    expect(find.text('Přátelé 👥'), findsOneWidget);

    // Tap Žebříček
    await tester.tap(find.text('Žebříček'));
    await tester.pumpAndSettle();
    expect(find.text('Žebříček 🏆'), findsOneWidget);
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

  group('BeerEntry model', () {
    test('fromMap creates correct instance', () {
      final map = {
        'name': 'Pilsner Urquell',
        'rating': 4.0,
        'date': '15.06.2025 20:30',
        'imagePath': '/path/to/image.jpg',
        'lat': 49.7477,
        'lng': 13.3776,
        'is_ghost': false,
      };

      final entry = BeerEntry.fromMap(map, key: 42);

      expect(entry.key, 42);
      expect(entry.name, 'Pilsner Urquell');
      expect(entry.rating, 4.0);
      expect(entry.imagePath, '/path/to/image.jpg');
      expect(entry.lat, 49.7477);
      expect(entry.lng, 13.3776);
      expect(entry.isGhost, false);
      expect(entry.hasLocation, true);
    });

    test('toMap produces correct map', () {
      const entry = BeerEntry(
        name: 'Kozel',
        rating: 3.0,
        date: '15.06.2025 20:30',
        isGhost: true,
      );

      final map = entry.toMap();

      expect(map['name'], 'Kozel');
      expect(map['rating'], 3.0);
      expect(map['is_ghost'], true);
      expect(map['lat'], 0.0);
      expect(map['lng'], 0.0);
    });

    test('hasLocation returns false for zero coordinates', () {
      const entry = BeerEntry(
        name: 'Test',
        rating: 3.0,
        date: '15.06.2025',
        lat: 0.0,
        lng: 0.0,
      );

      expect(entry.hasLocation, false);
    });

    test('fromMap handles missing fields gracefully', () {
      final entry = BeerEntry.fromMap({});

      expect(entry.name, '');
      expect(entry.rating, 0.0);
      expect(entry.date, '');
      expect(entry.imagePath, isNull);
      expect(entry.isGhost, false);
    });
  });
}
