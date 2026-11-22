// AeriS - Laboratory protocol assistant
// Copyright (C) 2026 Alejandro Pascual Hernández and contributors
// SPDX-License-Identifier: GPL-3.0-or-later
// Additional permission for app stores: see EXCEPCION_TIENDAS.md

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aeris/tema.dart';

/// Pinta [hijo] dentro de una app con el tema de AeriS.
Future<void> pintar(WidgetTester tester, Widget hijo, {Brightness brillo = Brightness.light}) {
  return tester.pumpWidget(MaterialApp(
    theme: temaAeris(brillo: brillo),
    home: Scaffold(body: Center(child: hijo)),
  ));
}

void main() {
  testWidgets('Un botón normal, sin estilo propio, ya es grande para usar con guantes',
      (tester) async {
    await pintar(tester, FilledButton(onPressed: () {}, child: const Text('OK')));

    final tamano = tester.getSize(find.byType(FilledButton));
    expect(tamano.height, greaterThanOrEqualTo(Medida.boton));
    expect(tamano.width, greaterThanOrEqualTo(120));
  });

  testWidgets('Los botones de solo icono también tienen un tamaño mínimo', (tester) async {
    await pintar(tester, IconButton(onPressed: () {}, icon: const Icon(Icons.delete)));

    final tamano = tester.getSize(find.byType(IconButton));
    expect(tamano.height, greaterThanOrEqualTo(Medida.botonIcono));
  });

  testWidgets('Un Text sin estilo usa el tamaño de texto normal de la app', (tester) async {
    await pintar(tester, const Text('Hola'));

    final estilo = DefaultTextStyle.of(tester.element(find.text('Hola'))).style;
    expect(estilo.fontSize, 18);
  });

  test('Los campos de texto llevan borde sin tener que pedirlo', () {
    expect(temaAeris().inputDecorationTheme.border, isA<OutlineInputBorder>());
  });

  test('El tema oscuro sale del mismo color semilla', () {
    final claro = temaAeris();
    final oscuro = temaAeris(brillo: Brightness.dark);

    expect(oscuro.brightness, Brightness.dark);
    expect(oscuro.colorScheme.primary, isNot(claro.colorScheme.primary));
    // Los tamaños no cambian con el modo oscuro
    expect(oscuro.textTheme.bodyMedium?.fontSize, claro.textTheme.bodyMedium?.fontSize);
  });
}
