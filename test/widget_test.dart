import 'package:flutter_test/flutter_test.dart';
import 'package:aeris/main.dart';

void main() {
  testWidgets('La pantalla de inicio muestra los tres botones', (tester) async {
    await tester.pumpWidget(const AerisApp());

    expect(find.text('Añadir protocolo nuevo'), findsOneWidget);
    expect(find.text('Mis protocolos'), findsOneWidget);
    expect(find.text('Ayuda'), findsOneWidget);
  });
    testWidgets('Mis protocolos muestra la lista', (tester) async {
    await tester.pumpWidget(const AerisApp());

    await tester.tap(find.text('Mis protocolos'));
    await tester.pumpAndSettle(); // espera a que termine la animación

    expect(find.text('PCR estándar (V.1)'), findsOneWidget);
  });
}