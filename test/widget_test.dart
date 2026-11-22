// AeriS - Laboratory protocol assistant
// Copyright (C) 2026 Alejandro Pascual Hernández and contributors
// SPDX-License-Identifier: GPL-3.0-or-later
// Additional permission for app stores: see EXCEPCION_TIENDAS.md

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aeris/main.dart';

/// Abre la app y entra en la PCR.
Future<void> abrirPcr(WidgetTester tester) async {
  await tester.pumpWidget(const AerisApp());
  await tester.tap(find.text('Mis protocolos'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('PCR estándar (V.1)'));
  await tester.pumpAndSettle();
}

/// En el paso de cálculo: concentración del control positivo y una muestra M1.
/// Orden de los campos: control (código 0, conc. 1), M1 (código 2, conc. 3), lote (4).
Future<void> rellenarCalculo(WidgetTester tester) async {
  await tester.enterText(find.byType(TextField).at(1), '50');
  await tester.pump();

  await tester.ensureVisible(find.text('Añadir muestra'));
  await tester.tap(find.text('Añadir muestra'));
  await tester.pump();

  await tester.enterText(find.byType(TextField).at(2), 'M1');
  await tester.enterText(find.byType(TextField).at(3), '25');
  await tester.pump();
}

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
    await abrirPcr(tester);

    expect(find.text('Paso 1 de 5'), findsOneWidget);
    expect(find.text('Preparar los reactivos'), findsOneWidget);
  });

  testWidgets('El paso de cálculo no deja avanzar sin muestras y calcula al rellenarlas', (tester) async {
    await abrirPcr(tester);
    await tester.tap(find.text('Siguiente'));
    await tester.pump();
    expect(find.text('Paso 2 de 5'), findsOneWidget);

    // Sin muestras, "Siguiente" está desactivado
    await tester.tap(find.text('Siguiente'));
    await tester.pump();
    expect(find.text('Paso 2 de 5'), findsOneWidget);

    await rellenarCalculo(tester);

    // Normalización: 50 ng / 50 ng/µL = 1 µL; 50 ng / 25 ng/µL = 2 µL
    expect(find.text('1.00 µL de DNA + 4.00 µL de agua'), findsOneWidget);
    expect(find.text('2.00 µL de DNA + 3.00 µL de agua'), findsOneWidget);
    // Mastermix: 3 tubos × 1,1 = 3,3; 20 µL × 3,3 = 66 µL
    expect(find.text('66.00'), findsOneWidget);

    await tester.tap(find.text('Siguiente'));
    await tester.pump();
    expect(find.text('Paso 3 de 5'), findsOneWidget);
  });

  testWidgets('Recorrer la PCR hasta el final muestra el diálogo y vuelve a la lista', (tester) async {
    await abrirPcr(tester);
    await tester.tap(find.text('Siguiente'));
    await tester.pump();
    await rellenarCalculo(tester);

    // Paso 2 → 5
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('Siguiente'));
      await tester.pump();
    }
    expect(find.text('Paso 5 de 5'), findsOneWidget);

    await tester.tap(find.text('Terminar'));
    await tester.pumpAndSettle();
    expect(find.text('¡Protocolo completado!'), findsOneWidget);

    await tester.tap(find.text('Volver'));
    await tester.pumpAndSettle();
    expect(find.text('¡Protocolo completado!'), findsNothing);
    expect(find.text('PCR estándar (V.1)'), findsOneWidget);
  });

  testWidgets('Las muestras se conservan al volver atrás y adelante', (tester) async {
    await abrirPcr(tester);
    await tester.tap(find.text('Siguiente'));
    await tester.pump();
    await rellenarCalculo(tester);

    await tester.tap(find.text('Siguiente')); // al paso 3
    await tester.pump();
    await tester.tap(find.text('Anterior')); // de vuelta al 2
    await tester.pump();

    expect(find.widgetWithText(TextField, 'M1'), findsOneWidget);
    expect(find.text('2.00 µL de DNA + 3.00 µL de agua'), findsOneWidget);
  });
}
