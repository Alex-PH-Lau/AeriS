// AeriS - Laboratory protocol assistant
// Copyright (C) 2026 Alejandro Pascual Hernández and contributors
// SPDX-License-Identifier: GPL-3.0-or-later
// Additional permission for app stores: see EXCEPCION_TIENDAS.md

import 'package:flutter_test/flutter_test.dart';
import 'package:aeris/modelos/calculo.dart';
import 'package:aeris/modelos/ejemplos.dart';
import 'package:aeris/modelos/entradas.dart';
import 'package:aeris/modelos/paso.dart';

void main() {
  final paso = pcrEstandar.pasos[1] as PasoCalculo;
  const controlPositivo = Muestra(
    id: 'c',
    tipo: 'Control positivo',
    codigo: 'Control positivo',
    concentracion: 50,
  );

  test('leerNumero acepta coma y punto decimal', () {
    expect(leerNumero('2,5'), 2.5);
    expect(leerNumero('2.5'), 2.5);
    expect(leerNumero(' 50 '), 50);
    expect(leerNumero('abc'), isNull);
    expect(leerNumero(null), isNull);
  });

  test('La tabla empieza solo con el control positivo', () {
    final filas = muestrasIniciales(paso);

    expect(filas.length, 1);
    expect(filas.first.tipo, 'Control positivo');
    expect(filas.first.codigo, 'Control positivo');
  });

  test('Sin muestras no se puede avanzar', () {
    expect(problemaCalculo(paso, [controlPositivo], {}), contains('Añade al menos una muestra'));
  });

  test('Una muestra sin código no es válida', () {
    final muestras = [
      controlPositivo,
      const Muestra(id: 'm1', tipo: 'Muestra', concentracion: 25),
    ];
    expect(problemaCalculo(paso, muestras, {}), contains('código'));
  });

  test('Códigos repetidos no son válidos', () {
    final muestras = [
      controlPositivo,
      const Muestra(id: 'm1', tipo: 'Muestra', codigo: 'M1', concentracion: 25),
      const Muestra(id: 'm2', tipo: 'Muestra', codigo: 'M1', concentracion: 30),
    ];
    expect(problemaCalculo(paso, muestras, {}), contains('repetidos'));
  });

  test('Falta la concentración de una muestra', () {
    final muestras = [
      controlPositivo,
      const Muestra(id: 'm1', tipo: 'Muestra', codigo: 'M1'),
    ];
    expect(problemaCalculo(paso, muestras, {}), contains('concentración de M1'));
  });

  test('Con todo relleno se puede avanzar (el lote es opcional)', () {
    final muestras = [
      controlPositivo,
      const Muestra(id: 'm1', tipo: 'Muestra', codigo: 'M1', concentracion: 25),
    ];
    expect(problemaCalculo(paso, muestras, {}), isNull);
    expect(calculoCompleto(paso, muestras, {}), isTrue);
  });

  test('Etiqueta de un parámetro opcional', () {
    expect(etiquetaParametro(paso.parametros.first), 'Lote de la Taq · opcional');
  });
}
