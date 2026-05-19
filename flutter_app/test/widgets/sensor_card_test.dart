import 'package:flutter/material.dart';
import 'package:flutter_app/presentation/widgets/sensor_card.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SensorCard Widget Tests', () {
    testWidgets('WT-05 sensor karti etiket, deger ve birimi gosterir', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SensorCard(
              label: 'Sicaklik',
              value: '24.5',
              unit: 'C',
              icon: Icons.thermostat,
              color: Colors.orange,
            ),
          ),
        ),
      );

      expect(find.text('Sicaklik'), findsOneWidget);
      expect(find.text('24.5'), findsOneWidget);
      expect(find.text('C'), findsOneWidget);
      expect(find.byIcon(Icons.thermostat), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsNothing);
    });

    testWidgets('WT-06 alarm durumunda uyari ikonu gosterir', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SensorCard(
              label: 'Gaz',
              value: '900',
              unit: 'ppm',
              icon: Icons.local_fire_department,
              color: Colors.red,
              isAlert: true,
            ),
          ),
        ),
      );

      expect(find.text('Gaz'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });
  });
}
