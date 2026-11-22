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

/// Abre la app y entra en un protocolo de la lista.
Future<void> abrirProtocolo(WidgetTester tester, String nombre) async {
  await tester.pumpWidget(const AerisApp());
  await tester.tap(find.text('Mis protocolos'));
  await tester.pumpAndSettle();
  await tester.tap(find.text(nombre));
  await tester.pumpAndSettle();
}

Future<void> abrirPcr(WidgetTester tester) => abrirProtocolo(tester, 'PCR estándar (V.1)');

/// Del paso 1 de la PCR al paso 2 (cálculo), confirmando su alerta.
Future<void> irAlCalculo(WidgetTester tester) async {
  await tester.tap(find.text('Siguiente'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Entendido'));
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

/// De la lista al paso 4 de la electroforesis ("Correr el gel", 30 min).
Future<void> irAlTemporizador(WidgetTester tester) async {
  await abrirProtocolo(tester, 'Electroforesis en gel de agarosa (V.2)');
  for (var i = 0; i < 3; i++) {
    await tester.tap(find.text('Siguiente'));
    await tester.pump();
  }
}

void main() {
  // Los tests no pueden usar las notificaciones reales del sistema
  late AvisosDePrueba avisosFalsos;
  late AlmacenEnMemoria almacenFalso;
  setUp(() {
    avisosFalsos = AvisosDePrueba();
    avisos = avisosFalsos;
    almacenFalso = AlmacenEnMemoria([pcrEstandar, electroforesis]);
    almacen = almacenFalso;
  });

  testWidgets('La pantalla de inicio muestra sus botones', (tester) async {
    await tester.pumpWidget(const AerisApp());

    expect(find.text('Añadir protocolo nuevo'), findsOneWidget);
    expect(find.text('Mis protocolos'), findsOneWidget);
    expect(find.text('Cuaderno de laboratorio'), findsOneWidget);
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

  testWidgets('La alerta bloquea hasta pulsar Entendido y queda como recordatorio', (tester) async {
    await abrirPcr(tester);
    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();

    // La ventana de alerta está abierta
    expect(find.text('¡Atención!'), findsOneWidget);

    // Tocar fuera no la cierra
    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();
    expect(find.text('¡Atención!'), findsOneWidget);

    await tester.tap(find.text('Entendido'));
    await tester.pumpAndSettle();
    expect(find.text('¡Atención!'), findsNothing);

    // El recordatorio sigue en el paso
    expect(find.text('Mantén la Taq polimerasa en hielo en todo momento.'), findsOneWidget);

    // Al volver a este paso no se repite la ventana
    await tester.tap(find.text('Anterior'));
    await tester.pump();
    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();
    expect(find.text('¡Atención!'), findsNothing);
  });

  testWidgets('El paso de cálculo no deja avanzar sin muestras y calcula al rellenarlas', (tester) async {
    await abrirPcr(tester);
    await irAlCalculo(tester);
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
    await irAlCalculo(tester);
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
    await irAlCalculo(tester);
    await rellenarCalculo(tester);

    await tester.tap(find.text('Siguiente')); // al paso 3
    await tester.pump();
    await tester.tap(find.text('Anterior')); // de vuelta al 2
    await tester.pump();

    expect(find.widgetWithText(TextField, 'M1'), findsOneWidget);
    expect(find.text('2.00 µL de DNA + 3.00 µL de agua'), findsOneWidget);
  });

  testWidgets('Iniciar el temporizador programa el aviso del sistema y pausarlo lo cancela', (tester) async {
    await irAlTemporizador(tester);

    await tester.ensureVisible(find.text('Iniciar'));
    await tester.tap(find.text('Iniciar'));
    await tester.pump();

    // El paso 4 tiene índice 3; el aviso queda programado para dentro de ~30 min
    expect(avisosFalsos.programados.containsKey(3), isTrue);
    final quedan = avisosFalsos.programados[3]!.difference(DateTime.now());
    expect(quedan.inMinutes, inInclusiveRange(29, 30));

    await tester.tap(find.text('Pausar'));
    await tester.pump();
    expect(avisosFalsos.programados, isEmpty);
  });

  testWidgets('Sin permiso de notificaciones avisa al usuario', (tester) async {
    avisosFalsos.permiso = false;
    await irAlTemporizador(tester);

    await tester.ensureVisible(find.text('Iniciar'));
    await tester.tap(find.text('Iniciar'));
    await tester.pump();

    expect(avisosFalsos.programados, isEmpty);
    expect(find.textContaining('Sin permiso de notificaciones'), findsOneWidget);
  });

  testWidgets('Con el temporizador en marcha pide confirmación para avanzar', (tester) async {
    await irAlTemporizador(tester);
    expect(find.text('Paso 4 de 5'), findsOneWidget);
    expect(find.text('30:00'), findsOneWidget);

    await tester.ensureVisible(find.text('Iniciar'));
    await tester.tap(find.text('Iniciar'));
    await tester.pump();
    expect(find.text('Pausar'), findsOneWidget);

    // "Quedarme" no avanza
    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();
    expect(find.text('El temporizador sigue en marcha'), findsOneWidget);
    await tester.tap(find.text('Quedarme'));
    await tester.pumpAndSettle();
    expect(find.text('Paso 4 de 5'), findsOneWidget);

    // "Avanzar igualmente" sí
    await tester.tap(find.text('Siguiente'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Avanzar igualmente'));
    await tester.pumpAndSettle();
    expect(find.text('Paso 5 de 5'), findsOneWidget);
  });

  testWidgets('Una ejecución terminada queda en el cuaderno como Completada', (tester) async {
    await abrirPcr(tester);
    await irAlCalculo(tester);
    await rellenarCalculo(tester);
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('Siguiente'));
      await tester.pump();
    }
    await tester.tap(find.text('Terminar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Volver'));
    await tester.pumpAndSettle();

    // Guardada con sus muestras y sus pasos
    final guardada = almacenFalso.ejecuciones.values.single;
    expect(guardada.estado.name, 'completada');
    expect(guardada.muestras.map((m) => m.codigo), contains('M1'));
    expect(guardada.registros.length, 5);

    // Lista de protocolos → inicio → cuaderno
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cuaderno de laboratorio'));
    await tester.pumpAndSettle();

    expect(find.text('PCR estándar (V.1)'), findsOneWidget);
    expect(find.textContaining('Completada'), findsOneWidget);
  });

  testWidgets('Una ejecución a medias se puede reanudar desde el cuaderno', (tester) async {
    await abrirPcr(tester);
    await irAlCalculo(tester);
    await rellenarCalculo(tester);
    await tester.tap(find.text('Siguiente')); // al paso 3
    await tester.pump();

    // Salir sin terminar: ejecución → lista → inicio
    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cuaderno de laboratorio'));
    await tester.pumpAndSettle();
    expect(find.textContaining('En proceso'), findsOneWidget);

    // Continuar: vuelve al paso 3 con las muestras guardadas
    await tester.tap(find.text('PCR estándar (V.1)'));
    await tester.pumpAndSettle();
    expect(find.text('Paso 3 de 5'), findsOneWidget);
    expect(find.text('¡Atención!'), findsNothing); // la alerta ya se vio

    await tester.tap(find.text('Anterior'));
    await tester.pump();
    expect(find.widgetWithText(TextField, 'M1'), findsOneWidget);
  });

  testWidgets('Descartar una ejecución a medias la borra del cuaderno', (tester) async {
    await abrirPcr(tester);
    await tester.pageBack(); // salir enseguida: queda "En proceso"
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cuaderno de laboratorio'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Descartar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Descartar'));
    await tester.pumpAndSettle();

    expect(almacenFalso.ejecuciones, isEmpty);
    expect(find.textContaining('Todavía no hay ejecuciones'), findsOneWidget);
  });
}
