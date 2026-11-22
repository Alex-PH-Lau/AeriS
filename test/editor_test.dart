// AeriS - Laboratory protocol assistant
// Copyright (C) 2026 Alejandro Pascual Hernández and contributors
// SPDX-License-Identifier: GPL-3.0-or-later
// Additional permission for app stores: see EXCEPCION_TIENDAS.md

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aeris/main.dart';
import 'package:aeris/modelos/ejemplos.dart';
import 'package:aeris/servicios/almacen.dart';
import 'package:aeris/servicios/avisos.dart';

import 'almacen_de_prueba.dart';
import 'avisos_de_prueba.dart';

/// Pantalla de tablet en horizontal: 1280 × 800 píxeles lógicos (dos paneles).
void usarTabletHorizontal(WidgetTester tester) {
  tester.view.physicalSize = const Size(2560, 1600);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(tester.view.reset); // al acabar el test, volver al tamaño normal
}

Future<void> abrirEditorNuevo(WidgetTester tester) async {
  await tester.pumpWidget(const AerisApp());
  await tester.tap(find.text('Añadir protocolo nuevo'));
  await tester.pumpAndSettle();
}

/// "Añadir paso" → "Instrucciones" en la hoja que aparece abajo.
Future<void> anadirPasoInstrucciones(WidgetTester tester) async {
  await tester.tap(find.text('Añadir paso'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Instrucciones'));
  await tester.pumpAndSettle();
}

Finder campo(String etiqueta) => find.widgetWithText(TextField, etiqueta);

void main() {
  late AlmacenEnMemoria almacenFalso;
  setUp(() {
    avisos = AvisosDePrueba();
    almacenFalso = AlmacenEnMemoria([pcrEstandar, electroforesis]);
    almacen = almacenFalso;
  });

  testWidgets('Crear un protocolo nuevo (un panel) y verlo en Mis protocolos', (tester) async {
    await abrirEditorNuevo(tester);
    await tester.enterText(campo('Nombre del protocolo'), 'Extracción de DNA');

    // En pantalla estrecha, el paso se abre en su propia pantalla
    await anadirPasoInstrucciones(tester);
    expect(find.text('Paso 1'), findsOneWidget);
    await tester.enterText(campo('Título del paso'), 'Moler el tejido');
    await tester.enterText(campo('Texto del paso'), 'Moler 100 mg de hoja en nitrógeno líquido.');
    await tester.tap(find.text('Guardar paso'));
    await tester.pumpAndSettle();

    expect(find.text('1. Moler el tejido'), findsOneWidget);

    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    // De vuelta en el inicio; el protocolo está guardado como V.1
    final protocolos = await almacenFalso.ultimasVersiones();
    expect(protocolos.map((p) => p.nombreCompleto), contains('Extracción de DNA (V.1)'));

    await tester.tap(find.text('Mis protocolos'));
    await tester.pumpAndSettle();
    expect(find.text('Extracción de DNA (V.1)'), findsOneWidget);
  });

  testWidgets('En una tablet horizontal se ven la lista y el paso a la vez', (tester) async {
    usarTabletHorizontal(tester);
    await abrirEditorNuevo(tester);

    await anadirPasoInstrucciones(tester);

    // No se ha abierto otra pantalla: lista y formulario juntos
    expect(find.text('Añadir paso'), findsOneWidget);
    expect(campo('Título del paso'), findsOneWidget);

    await tester.enterText(campo('Título del paso'), 'Centrifugar');
    await tester.pump();
    expect(find.text('1. Centrifugar'), findsOneWidget); // la lista se actualiza al escribir
  });

  testWidgets('Guardar con datos incompletos explica qué falta', (tester) async {
    await abrirEditorNuevo(tester);

    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(find.text('• El protocolo necesita un nombre.'), findsOneWidget);
    expect(find.text('• Añade al menos un paso.'), findsOneWidget);
    expect(await almacenFalso.ultimasVersiones(), hasLength(2)); // no se ha guardado nada
  });

  testWidgets('Salir con cambios sin guardar pide confirmación', (tester) async {
    await abrirEditorNuevo(tester);
    await tester.enterText(campo('Nombre del protocolo'), 'Algo');
    await tester.pump();

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Hay cambios sin guardar'), findsOneWidget);

    await tester.tap(find.text('Seguir editando'));
    await tester.pumpAndSettle();
    expect(find.text('Nuevo protocolo'), findsOneWidget); // seguimos en el editor

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Salir sin guardar'));
    await tester.pumpAndSettle();
    expect(find.text('Mis protocolos'), findsOneWidget); // en el inicio
  });

  testWidgets('Editar un protocolo crea una versión nueva y conserva la anterior', (tester) async {
    await tester.pumpWidget(const AerisApp());
    await tester.tap(find.text('Mis protocolos'));
    await tester.pumpAndSettle();

    // Lista ordenada por nombre: Electroforesis, PCR. Editar la PCR (la segunda)
    await tester.tap(find.byTooltip('Editar').at(1));
    await tester.pumpAndSettle();
    expect(find.text('Editar PCR estándar (V.1)'), findsOneWidget);

    await tester.enterText(campo('Nombre del protocolo'), 'PCR rápida');
    await tester.tap(find.text('Guardar'));
    await tester.pumpAndSettle();

    expect(find.text('PCR rápida (V.2)'), findsOneWidget); // la lista ya muestra la V.2
    expect(await almacenFalso.protocolo('pcr-estandar', 1), isNotNull); // la V.1 sigue
  });

  testWidgets('Volver sin tocar un paso nuevo lo quita de la lista', (tester) async {
    await abrirEditorNuevo(tester);
    await anadirPasoInstrucciones(tester);

    await tester.pageBack(); // sin cambios: sale sin preguntar
    await tester.pumpAndSettle();

    expect(find.text('Todavía no hay pasos.'), findsOneWidget);
  });

  testWidgets('Volver con cambios en un paso pregunta antes de descartarlos', (tester) async {
    await abrirEditorNuevo(tester);
    await anadirPasoInstrucciones(tester);
    await tester.enterText(campo('Título del paso'), 'Incubar');
    await tester.pump();

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('¿Descartar los cambios de este paso?'), findsOneWidget);

    // "Seguir editando": el texto sigue ahí
    await tester.tap(find.text('Seguir editando'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(TextField, 'Incubar'), findsOneWidget);

    // "Descartar": vuelve a la lista y el paso nuevo no se queda
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Descartar'));
    await tester.pumpAndSettle();
    expect(find.text('Todavía no hay pasos.'), findsOneWidget);
  });

  testWidgets('Guardar paso aplica los cambios a un paso existente', (tester) async {
    await tester.pumpWidget(const AerisApp());
    await tester.tap(find.text('Mis protocolos'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Editar').at(0)); // la electroforesis
    await tester.pumpAndSettle();

    await tester.tap(find.text('1. Preparar el gel'));
    await tester.pumpAndSettle();
    await tester.enterText(campo('Título del paso'), 'Preparar el gel al 2 %');
    await tester.tap(find.text('Guardar paso'));
    await tester.pumpAndSettle();

    expect(find.text('1. Preparar el gel al 2 %'), findsOneWidget);
  });
}
