// AeriS - Laboratory protocol assistant
// Copyright (C) 2026 Alejandro Pascual Hernández and contributors
// SPDX-License-Identifier: GPL-3.0-or-later
// Additional permission for app stores: see EXCEPCION_TIENDAS.md

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:aeris/main.dart';
import 'package:aeris/modelos/ejemplos.dart';
import 'package:aeris/servicios/almacen.dart';
import 'package:aeris/servicios/avisos.dart';
import 'package:aeris/servicios/reducir_imagen.dart';
import 'package:aeris/servicios/selector_imagenes.dart';

import 'almacen_de_prueba.dart';
import 'avisos_de_prueba.dart';
import 'selector_de_prueba.dart';

void main() {
  group('Reducir imágenes (lo que en el móvil hace el plugin)', () {
    test('Una foto grande se reduce a 1600 px manteniendo la proporción', () async {
      final foto = img.encodeJpg(img.Image(width: 4000, height: 3000)); // 12 Mpx
      final reducida = img.decodeImage(await reducirImagen(foto))!;

      expect(reducida.width, 1600);
      expect(reducida.height, 1200);
    });

    test('Una foto vertical se limita por la altura', () async {
      final foto = img.encodePng(img.Image(width: 1000, height: 2400));
      final reducida = img.decodeImage(await reducirImagen(foto))!;

      expect(reducida.height, 1600);
      expect(reducida.width, closeTo(667, 1));
    });

    test('Una imagen ya pequeña se deja tal cual', () async {
      expect(await reducirImagen(pngDePrueba), pngDePrueba);
    });

    test('Un archivo que no es una imagen da un error claro', () async {
      await expectLater(
        reducirImagen(Uint8List.fromList([1, 2, 3, 4])),
        throwsA(isA<FormatException>()),
      );
    });
  });

  testWidgets('Con un solo origen (el ordenador), no se pregunta de dónde', (tester) async {
    almacen = AlmacenEnMemoria([pcrEstandar]);
    avisos = AvisosDePrueba();
    final selector = SelectorDePrueba(null)..origenes = const [OrigenImagen.galeria];
    selectorImagenes = selector;
    addTearDown(() => selectorImagenes = SelectorImagenesSistema());

    tester.view.physicalSize = const Size(2560, 1600);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const AerisApp());
    await tester.tap(find.text('Añadir protocolo nuevo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Añadir paso'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Instrucciones'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Imagen'));
    await tester.pumpAndSettle();

    expect(selector.pedidos, [OrigenImagen.galeria]); // directo, sin hoja
    expect(find.text('Hacer una foto'), findsNothing);
  });

  testWidgets('Ctrl+S guarda el protocolo en el editor', (tester) async {
    final almacenFalso = AlmacenEnMemoria([pcrEstandar]);
    almacen = almacenFalso;
    avisos = AvisosDePrueba();

    await tester.pumpWidget(const AerisApp());
    await tester.tap(find.text('Añadir protocolo nuevo'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Nombre del protocolo'), 'Atajo');
    await tester.tap(find.text('Añadir paso'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Instrucciones'));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextField, 'Título del paso'), 'Uno');
    await tester.enterText(find.widgetWithText(TextField, 'Texto del paso'), 'Hacer algo');
    await tester.pumpAndSettle();

    // En el móvil (800 px de ancho en los tests) el paso se edita en otra pantalla:
    // se guarda el paso y se vuelve a la lista, y ahí se pulsa Ctrl+S
    if (find.text('Guardar paso').evaluate().isNotEmpty) {
      await tester.tap(find.text('Guardar paso'));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.widgetWithText(TextField, 'Nombre del protocolo')); // foco dentro del editor
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyS);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pumpAndSettle();

    final protocolos = await almacenFalso.ultimasVersiones();
    expect(protocolos.map((p) => p.nombre), contains('Atajo'));
  });
}
