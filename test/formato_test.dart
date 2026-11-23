// AeriS - Laboratory protocol assistant
// Copyright (C) 2026 Alejandro Pascual Hernández and contributors
// SPDX-License-Identifier: GPL-3.0-or-later
// Additional permission for app stores: see EXCEPCION_TIENDAS.md

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aeris/modelos/formato.dart';
import 'package:aeris/pantallas/editor/editor_texto.dart';
import 'package:aeris/pantallas/widgets/texto_formato.dart';
import 'package:aeris/tema.dart';

/// Texto con una selección de [inicio] a [fin] (iguales = solo el cursor).
TextEditingValue valor(String texto, int inicio, [int? fin]) => TextEditingValue(
      text: texto,
      selection: TextSelection(baseOffset: inicio, extentOffset: fin ?? inicio),
    );

void main() {
  group('Negrita y cursiva', () {
    test('Envuelve lo seleccionado y lo deja seleccionado', () {
      final r = envolver(valor('Incubar a 37 °C', 10, 15), '**');

      expect(r.text, 'Incubar a **37 °C**');
      expect(r.selection.textInside(r.text), '37 °C');
    });

    test('Sin selección, el cursor queda entre las marcas', () {
      final r = envolver(valor('Incubar ', 8), '**');

      expect(r.text, 'Incubar ****');
      expect(r.selection.baseOffset, 10);
    });

    test('Pulsar otra vez quita el formato', () {
      final una = envolver(valor('en hielo', 0, 8), '_');
      final dos = envolver(una, '_');

      expect(una.text, '_en hielo_');
      expect(dos.text, 'en hielo');
      expect(dos.selection.textInside(dos.text), 'en hielo');
    });

    test('Un campo que nunca tuvo el foco escribe al final', () {
      const sinCursor = TextEditingValue(text: 'Hola'); // selección no válida
      expect(envolver(sinCursor, '**').text, 'Hola****');
    });
  });

  group('Formatos de línea', () {
    const tres = 'Buffer\ndNTPs\nTaq';

    test('Lista: todas las líneas seleccionadas', () {
      final r = formatearLineas(valor(tres, 2, 14), FormatoLinea.lista);
      expect(r.text, '- Buffer\n- dNTPs\n- Taq');
    });

    test('Lista numerada: cuenta las líneas', () {
      final r = formatearLineas(valor(tres, 0, tres.length), FormatoLinea.numerada);
      expect(r.text, '1. Buffer\n2. dNTPs\n3. Taq');
    });

    test('Sin selección, solo la línea del cursor', () {
      final r = formatearLineas(valor(tres, 8), FormatoLinea.importante); // en "dNTPs"
      expect(r.text, 'Buffer\n> dNTPs\nTaq');
    });

    test('Si ya la tenían todas, el botón la quita', () {
      final r = formatearLineas(valor('- a\n- b', 0, 7), FormatoLinea.lista);
      expect(r.text, 'a\nb');
    });

    test('Cambiar de lista a numerada no deja las dos marcas', () {
      final r = formatearLineas(valor('- a\n- b', 0, 7), FormatoLinea.numerada);
      expect(r.text, '1. a\n2. b');
    });

    test('El título es de nivel 2 (el 1 es el título del paso)', () {
      final r = formatearLineas(valor('Material', 0), FormatoLinea.titulo);
      expect(r.text, '## Material');
    });
  });

  group('Widgets', () {
    Future<void> pintar(WidgetTester tester, Widget hijo) => tester.pumpWidget(MaterialApp(
          theme: temaAeris(),
          home: Scaffold(body: SingleChildScrollView(child: hijo)),
        ));

    testWidgets('El texto se muestra con formato, sin los asteriscos', (tester) async {
      await pintar(tester, const TextoConFormato(texto: 'Mantener **en hielo**.\nSegunda línea'));

      expect(find.textContaining('en hielo', findRichText: true), findsOneWidget);
      expect(find.textContaining('**', findRichText: true), findsNothing);
      // El salto de línea suelto se respeta (softLineBreak)
      expect(find.textContaining('Segunda línea', findRichText: true), findsOneWidget);
    });

    testWidgets('Los botones dan formato y avisan del cambio', (tester) async {
      String? recibido;
      await pintar(
        tester,
        EditorTextoFormato(texto: '', onCambio: (t) => recibido = t),
      );

      await tester.enterText(find.byType(TextField), 'Centrifugar');
      await tester.tap(find.byTooltip('Lista'));
      await tester.pump();
      expect(recibido, '- Centrifugar');

      // La vista previa muestra el resultado, no el Markdown
      await tester.tap(find.text('Vista previa'));
      await tester.pumpAndSettle();
      expect(find.byType(TextField), findsNothing);
      expect(find.textContaining('Centrifugar', findRichText: true), findsOneWidget);
      expect(find.textContaining('- Centrifugar', findRichText: true), findsNothing);

      // Al volver a escribir, el texto sigue ahí
      await tester.tap(find.text('Escribir'));
      await tester.pumpAndSettle();
      expect(find.text('- Centrifugar'), findsOneWidget);
    });
  });
}
