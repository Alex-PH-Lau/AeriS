// AeriS - Laboratory protocol assistant
// Copyright (C) 2026 Alejandro Pascual Hernández and contributors
// SPDX-License-Identifier: GPL-3.0-or-later
// Additional permission for app stores: see EXCEPCION_TIENDAS.md

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aeris/main.dart';
import 'package:aeris/modelos/ejemplos.dart';
import 'package:aeris/pantallas/ayuda.dart';
import 'package:aeris/servicios/almacen.dart';
import 'package:aeris/servicios/avisos.dart';

import 'almacen_de_prueba.dart';
import 'avisos_de_prueba.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized(); // para poder usar rootBundle

  setUp(() {
    almacen = AlmacenEnMemoria([pcrEstandar]);
    avisos = AvisosDePrueba();
  });

  // Si se olvida declarar la carpeta en pubspec.yaml, o un archivo tiene otro
  // nombre, este test lo dice antes de que lo descubra un usuario
  for (final seccion in seccionesAyuda) {
    test('El archivo de "${seccion.titulo}" existe y tiene contenido', () async {
      final texto = await rootBundle.loadString(seccion.archivo);
      expect(texto.trim(), isNotEmpty);
      expect(texto, startsWith('## ')); // empieza con un título
    });
  }

  /// Los widget tests corren con un reloj FALSO: el tiempo solo avanza con
  /// pump(). Pero leer un archivo es trabajo REAL del sistema, que no termina
  /// mientras el reloj está parado. Resultado: la ruedecita de "cargando" gira
  /// para siempre y pumpAndSettle se cansa de esperar.
  ///
  /// Solución: leer los archivos de verdad ANTES (con tiempo real, runAsync)
  /// y darle a la pantalla una función que los devuelve ya leídos. Es el mismo
  /// truco que con el almacén y los avisos: sustituir lo que toca el sistema.
  Future<void> precargarAyuda(WidgetTester tester) async {
    final textos = <String, String>{};
    await tester.runAsync(() async {
      for (final seccion in seccionesAyuda) {
        textos[seccion.archivo] = await rootBundle.loadString(seccion.archivo);
      }
    });
    leerTextoAyuda = (archivo) async => textos[archivo]!;
    addTearDown(() => leerTextoAyuda = rootBundle.loadString);
  }

  test('No hay dos secciones con el mismo id', () {
    final ids = seccionesAyuda.map((s) => s.id).toList();
    expect(ids.toSet(), hasLength(ids.length));
  });

  testWidgets('En el móvil: lista de secciones y cada una en su pantalla', (tester) async {
    await precargarAyuda(tester);
    await tester.pumpWidget(const AerisApp());
    await tester.tap(find.text('Ayuda'));
    await tester.pumpAndSettle();

    for (final seccion in seccionesAyuda) {
      expect(find.text(seccion.titulo), findsOneWidget);
    }

    await tester.tap(find.text('El paso de cálculo'));
    await tester.pumpAndSettle();

    expect(find.textContaining('mastermix', findRichText: true), findsWidgets);
    expect(find.textContaining('**', findRichText: true), findsNothing); // con formato
  });

  testWidgets('En la tablet: lista y sección a la vez', (tester) async {
    tester.view.physicalSize = const Size(2560, 1600);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    await precargarAyuda(tester);
    await tester.pumpWidget(const AerisApp());
    await tester.tap(find.text('Ayuda'));
    await tester.pumpAndSettle();

    // Sin tocar nada, ya se ve la primera sección
    expect(find.textContaining('Qué es AeriS', findRichText: true), findsOneWidget);

    await tester.tap(find.text('Cuaderno y copias de seguridad'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Qué es AeriS', findRichText: true), findsNothing);
    expect(find.textContaining('Restaurar una copia', findRichText: true), findsWidgets);
    expect(find.byType(BackButton), findsOneWidget); // seguimos en la misma pantalla de Ayuda
  });
}
