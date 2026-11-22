// AeriS - Laboratory protocol assistant
// Copyright (C) 2026 Alejandro Pascual Hernández and contributors
// SPDX-License-Identifier: GPL-3.0-or-later
// Additional permission for app stores: see EXCEPCION_TIENDAS.md

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aeris/main.dart';

/// Abre la app y entra en la PCR. Lo usan varios tests.
Future<void> abrirPcr(WidgetTester tester) async {
  await tester.pumpWidget(const AerisApp());
  await tester.tap(find.text('Mis protocolos'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('PCR estándar (V.1)'));
  await tester.pumpAndSettle();
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

  testWidgets('El paso de cálculo no deja avanzar sin datos y calcula al rellenarlos', (tester) async {
    await abrirPcr(tester);
    await tester.tap(find.text('Siguiente'));
    await tester.pump();
    expect(find.text('Paso 2 de 5'), findsOneWidget);

    // Sin datos, "Siguiente" está desactivado: pulsarlo no cambia de paso
    await tester.tap(find.text('Siguiente'));
    await tester.pump();
    expect(find.text('Paso 2 de 5'), findsOneWidget);

    // Rellenar muestras y concentración (el lote es opcional)
    await tester.enterText(find.byType(TextField).at(0), '12');
    await tester.enterText(find.byType(TextField).at(1), '50');
    await tester.pump();

    expect(find.text('38.50'), findsOneWidget); // Buffer: 2,5 × 14 × 1,1
    expect(find.text('369.60'), findsOneWidget); // Total: 24 × 15,4

    await tester.tap(find.text('Siguiente'));
    await tester.pump();
    expect(find.text('Paso 3 de 5'), findsOneWidget);
  });

  testWidgets('Recorrer la PCR hasta el final muestra el diálogo y vuelve a la lista', (tester) async {
    await abrirPcr(tester);

    // Paso 1 → 2 (cálculo): rellenar los datos obligatorios
    await tester.tap(find.text('Siguiente'));
    await tester.pump();
    await tester.enterText(find.byType(TextField).at(0), '12');
    await tester.enterText(find.byType(TextField).at(1), '50');
    await tester.pump();

    // Paso 2 → 5
    for (var i = 0; i < 3; i++) {
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

  testWidgets('Los datos se conservan al volver atrás y adelante', (tester) async {
    await abrirPcr(tester);
    await tester.tap(find.text('Siguiente'));
    await tester.pump();
    await tester.enterText(find.byType(TextField).at(0), '12');
    await tester.enterText(find.byType(TextField).at(1), '50');
    await tester.pump();

    await tester.tap(find.text('Siguiente')); // al paso 3
    await tester.pump();
    await tester.tap(find.text('Anterior')); // de vuelta al 2
    await tester.pump();

    expect(find.widgetWithText(TextField, '12'), findsOneWidget);
    expect(find.text('38.50'), findsOneWidget);
  });
}
