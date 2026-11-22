// AeriS - Laboratory protocol assistant
// Copyright (C) 2026 Alejandro Pascual Hernández and contributors
// SPDX-License-Identifier: GPL-3.0-or-later
// Additional permission for app stores: see EXCEPCION_TIENDAS.md

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aeris/main.dart';
import 'package:aeris/modelos/ejemplos.dart';
import 'package:aeris/modelos/paso.dart';
import 'package:aeris/servicios/almacen.dart';
import 'package:aeris/servicios/avisos.dart';

import 'almacen_de_prueba.dart';
import 'avisos_de_prueba.dart';

void usarTabletHorizontal(WidgetTester tester) {
  tester.view.physicalSize = const Size(2560, 1600);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset);
}

Finder campo(String etiqueta) => find.widgetWithText(TextField, etiqueta);

/// El editor es largo: antes de tocar algo, hay que desplazarse hasta él.
Future<void> tocar(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> escribir(WidgetTester tester, Finder finder, String texto) async {
  await tester.ensureVisible(finder);
  await tester.enterText(finder, texto);
  await tester.pumpAndSettle();
}

void main() {
  late AlmacenEnMemoria almacenFalso;
  setUp(() {
    avisos = AvisosDePrueba();
    almacenFalso = AlmacenEnMemoria([pcrEstandar, electroforesis]);
    almacen = almacenFalso;
  });

  testWidgets('Configurar un paso de cálculo con vista previa y guardarlo', (tester) async {
    usarTabletHorizontal(tester);
    await tester.pumpWidget(const AerisApp());
    await tester.tap(find.text('Añadir protocolo nuevo'));
    await tester.pumpAndSettle();
    await tester.enterText(campo('Nombre del protocolo'), 'PCR rápida');

    await tester.tap(find.text('Añadir paso'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cálculo de reactivos'));
    await tester.pumpAndSettle();

    // Recién creado: la vista previa dice lo que falta
    expect(find.text('• Añade al menos un reactivo.'), findsOneWidget);

    await tocar(tester, find.text('Añadir reactivo'));
    await escribir(tester, campo('Reactivo'), 'Buffer');
    await escribir(tester, campo('µL / tubo'), '2,5'); // con coma, como en España

    // 3 muestras de ejemplo + 1 control negativo = 4 tubos; ×1,1 de margen = 4,4
    expect(find.text('Mastermix: 20 µL por tubo'), findsOneWidget);
    expect(find.text('• Buffer: 2.5 µL/tubo → 11.00 µL'), findsOneWidget);
    expect(find.text('• Agua: 17.50 µL/tubo → 77.00 µL'), findsOneWidget);
    // 50 ng a 50 ng/µL = 1 µL de DNA y 4 de agua para llenar el hueco de 5
    expect(find.text('Cada tubo con DNA: 1.00 µL de DNA + 4.00 µL de agua'), findsOneWidget);

    // Con volumen fijo desaparecen los campos de la normalización
    await tocar(tester, find.text('Volumen fijo'));
    expect(campo('ng de DNA por reacción'), findsNothing);
    expect(campo('DNA por tubo (µL)'), findsOneWidget);

    // No se puede añadir un segundo paso de cálculo
    await tester.tap(find.text('Añadir paso'));
    await tester.pumpAndSettle();
    expect(find.text('Ya hay un paso de cálculo en este protocolo'), findsOneWidget);
    await tester.tapAt(const Offset(20, 20)); // cerrar la hoja tocando fuera
    await tester.pumpAndSettle();

    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    final protocolos = await almacenFalso.ultimasVersiones();
    final guardado = protocolos.firstWhere((p) => p.nombre == 'PCR rápida');
    final paso = guardado.pasos.single as PasoCalculo;
    expect(paso.reactivos.single.nombre, 'Buffer');
    expect(paso.reactivos.single.volPorReaccion, 2.5);
  });

  testWidgets('Quitar un reactivo del medio no mueve los textos de los demás', (tester) async {
    usarTabletHorizontal(tester);
    await tester.pumpWidget(const AerisApp());
    await tester.tap(find.text('Mis protocolos'));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(
      of: find.widgetWithText(ListTile, pcrEstandar.nombreCompleto),
      matching: find.byTooltip('Editar'),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('2. Preparar el mastermix'));
    await tester.pumpAndSettle();

    // Reactivos de la PCR: Buffer, dNTPs, Primer F, Primer R, Taq, MgCl2
    await tocar(tester, find.byTooltip('Quitar reactivo').at(1)); // dNTPs

    expect(find.widgetWithText(TextField, 'dNTPs'), findsNothing);
    expect(find.widgetWithText(TextField, 'Buffer'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Primer F'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'MgCl2'), findsOneWidget);
  });
}
