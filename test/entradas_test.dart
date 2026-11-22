// AeriS - Laboratory protocol assistant
// Copyright (C) 2026 Alejandro Pascual Hernández and contributors
// SPDX-License-Identifier: GPL-3.0-or-later
// Additional permission for app stores: see EXCEPCION_TIENDAS.md

import 'package:flutter_test/flutter_test.dart';
import 'package:aeris/modelos/ejemplos.dart';
import 'package:aeris/modelos/entradas.dart';
import 'package:aeris/modelos/paso.dart';

void main() {
  final pasoPcr = pcrEstandar.pasos[1] as PasoCalculo;

  test('leerNumero acepta coma y punto decimal', () {
    expect(leerNumero('2,5'), 2.5);
    expect(leerNumero('2.5'), 2.5);
    expect(leerNumero(' 50 '), 50);
    expect(leerNumero('abc'), isNull);
    expect(leerNumero(null), isNull);
  });

  test('Sin datos el cálculo no está completo', () {
    expect(calculoCompleto(pasoPcr, {}), isFalse);
  });

  test('Con 0 muestras el cálculo no está completo', () {
    expect(calculoCompleto(pasoPcr, {'Muestra': '0', 'Concentración del DNA': '50'}), isFalse);
  });

  test('Falta un parámetro obligatorio', () {
    expect(calculoCompleto(pasoPcr, {'Muestra': '12'}), isFalse);
  });

  test('Un parámetro numérico con letras no es válido', () {
    expect(calculoCompleto(pasoPcr, {'Muestra': '12', 'Concentración del DNA': 'mucho'}), isFalse);
  });

  test('Con los datos obligatorios el cálculo está completo (el lote es opcional)', () {
    expect(calculoCompleto(pasoPcr, {'Muestra': '12', 'Concentración del DNA': '50'}), isTrue);
  });

  test('Etiquetas de los campos', () {
    expect(etiquetaParametro(pasoPcr.parametros[0]), 'Concentración del DNA (ng/µL)');
    expect(etiquetaParametro(pasoPcr.parametros[1]), 'Lote de la Taq · opcional');
  });
}
