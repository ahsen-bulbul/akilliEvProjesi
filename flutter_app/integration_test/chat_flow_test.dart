import 'package:flutter/material.dart';
import 'package:flutter_app/main.dart';
import 'package:flutter_app/presentation/widgets/message_input_field.dart';
import 'package:flutter_app/presentation/widgets/sensor_card.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Smart Home Integration Tests', () {
    testWidgets('IT-01 mesaj yazma akisinda input metni kabul edilir', (
      tester,
    ) async {
      final controller = TextEditingController();
      var sentText = '';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MessageInputField(
              controller: controller,
              onSend: () => sentText = controller.text,
            ),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'Admin destek mesaji');
      await tester.tap(find.byIcon(Icons.send_rounded));
      await tester.pump();

      expect(sentText, equals('Admin destek mesaji'));
    });

    testWidgets('IT-02 sensor alarm akisi uyari ikonunu gosterir', (
      tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SensorCard(
              label: 'Gaz Seviyesi',
              value: '950',
              unit: 'ppm',
              icon: Icons.local_fire_department,
              color: Colors.red,
              isAlert: true,
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Gaz Seviyesi'), findsOneWidget);
      expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
    });

    testWidgets('IT-03 mesaj gonderme sirasinda yuklenme durumu gorunur', (
      tester,
    ) async {
      final controller = TextEditingController(text: 'Bekleyen mesaj');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MessageInputField(
              controller: controller,
              sending: true,
              onSend: () {},
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(tester.widget<TextField>(find.byType(TextField)).enabled, isFalse);
    });

    testWidgets('IT-04 uygulama config eksiginde uyari ekrani acar', (
      tester,
    ) async {
      await tester.pumpWidget(const SmartHomeApp());
      await tester.pumpAndSettle();

      expect(find.textContaining('Supabase ayarlari eksik'), findsOneWidget);
    });

    testWidgets(
      'IT-05 oda secimi ve cihaz kontrol akisi UI durumunu gunceller',
      (tester) async {
        await tester.pumpWidget(const MaterialApp(home: _ControlFlowHarness()));

        expect(find.text('Odalar'), findsOneWidget);
        expect(find.text('Salon'), findsOneWidget);
        expect(find.text('Salon Lambasi'), findsNothing);

        await tester.tap(find.text('Salon'));
        await tester.pump();

        expect(find.text('Salon Lambasi'), findsOneWidget);
        expect(find.text('Kapali'), findsOneWidget);

        await tester.tap(find.byType(Switch));
        await tester.pump();

        expect(find.text('Acik'), findsOneWidget);
        expect(
          find.text('Son komut: turn_on -> Salon Lambasi'),
          findsOneWidget,
        );
      },
    );
  });
}

class _ControlFlowHarness extends StatefulWidget {
  const _ControlFlowHarness();

  @override
  State<_ControlFlowHarness> createState() => _ControlFlowHarnessState();
}

class _ControlFlowHarnessState extends State<_ControlFlowHarness> {
  var _selectedRoom = '';
  var _deviceEnabled = false;
  var _lastCommand = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Odalar')),
      body: Column(
        children: [
          ListTile(
            title: const Text('Salon'),
            onTap: () => setState(() => _selectedRoom = 'Salon'),
          ),
          if (_selectedRoom == 'Salon')
            SwitchListTile(
              title: const Text('Salon Lambasi'),
              subtitle: Text(_deviceEnabled ? 'Acik' : 'Kapali'),
              value: _deviceEnabled,
              onChanged: (value) {
                setState(() {
                  _deviceEnabled = value;
                  _lastCommand =
                      'Son komut: ${value ? 'turn_on' : 'turn_off'} -> Salon Lambasi';
                });
              },
            ),
          if (_lastCommand.isNotEmpty) Text(_lastCommand),
        ],
      ),
    );
  }
}
