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
    await tester.pumpAndSettle();

    expect(find.text('PCR estándar (V.1)'), findsOneWidget);
  });

  testWidgets('Al abrir la PCR empieza en el paso 1', (tester) async {
    await tester.pumpWidget(const AerisApp());

    await tester.tap(find.text('Mis protocolos'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('PCR estándar (V.1)'));
    await tester.pumpAndSettle();

    expect(find.text('Paso 1 de 5'), findsOneWidget);
  });

  testWidgets('Recorrer la PCR hasta el final muestra el diálogo y vuelve a la lista', (tester) async {
    await tester.pumpWidget(const AerisApp());

    await tester.tap(find.text('Mis protocolos'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('PCR estándar (V.1)'));
    await tester.pumpAndSettle();

    // Avanzar del paso 1 al 5
    for (var i = 0; i < 4; i++) {
      await tester.tap(find.text('Siguiente'));
      await tester.pump();
    }
    expect(find.text('Paso 5 de 5'), findsOneWidget);

    // Terminar abre el diálogo
    await tester.tap(find.text('Terminar'));
    await tester.pumpAndSettle();
    expect(find.text('¡Protocolo completado!'), findsOneWidget);

    // Volver cierra el diálogo y regresa a la lista
    await tester.tap(find.text('Volver'));
    await tester.pumpAndSettle();
    expect(find.text('¡Protocolo completado!'), findsNothing);
    expect(find.text('PCR estándar (V.1)'), findsOneWidget);
  });
}