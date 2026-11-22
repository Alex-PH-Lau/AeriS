// AeriS - Laboratory protocol assistant
// Copyright (C) 2026 Alejandro Pascual Hernández and contributors
// SPDX-License-Identifier: GPL-3.0-or-later
// Additional permission for app stores: see EXCEPCION_TIENDAS.md

import 'package:flutter_test/flutter_test.dart';
import 'package:aeris/modelos/calculo.dart';
import 'package:aeris/modelos/ejecucion.dart';
import 'package:aeris/modelos/ejemplos.dart';
import 'package:aeris/modelos/paso.dart';

/// Atajo para crear muestras en los tests.
Muestra muestra(String codigo, double? concentracion, {String tipo = 'Muestra'}) {
  return Muestra(id: codigo, tipo: tipo, codigo: codigo, concentracion: concentracion);
}

void main() {
  final paso = pcrEstandar.pasos[1] as PasoCalculo;

  group('Mastermix', () {
    test('Una muestra, control positivo y control negativo: 3 tubos', () {
      final resultado = paso.calcular([
        muestra('C+', 50, tipo: 'Control positivo'),
        muestra('M1', 25),
      ]);

      expect(resultado.totalTubos, 3);
      expect(resultado.factor, closeTo(3.3, 0.0001));
      expect(resultado.aguaPorTubo, closeTo(13.25, 0.0001)); // 25 − 6,75 − 5
      expect(resultado.volumenesTotales['Buffer'], closeTo(8.25, 0.0001));
      expect(resultado.volumenTotal, closeTo(66, 0.0001)); // 20 µL × 3,3
      expect(resultado.esValido, isTrue);
      expect(resultado.muestrasListas, isTrue);
    });

    test('Reactivos que no caben en la reacción dan un resultado no válido', () {
      const pasoImposible = PasoCalculo(
        titulo: 'Mastermix imposible',
        volumenReaccion: 25,
        volumenMolde: 1,
        reactivos: [Reactivo(nombre: 'Reactivo excesivo', volPorReaccion: 30)],
        tiposTubo: [TipoTubo(nombre: 'Muestra', conDna: true)],
      );
      final resultado = pasoImposible.calcular([]);

      expect(resultado.aguaPorTubo, closeTo(-6, 0.0001));
      expect(resultado.esValido, isFalse);
    });
  });

  group('Normalización de cada muestra (50 ng, hueco de 5 µL, mínimo 1 µL)', () {
    test('Concentración normal: DNA + agua hasta el hueco', () {
      final r = paso.calcularMuestra(muestra('M1', 25));

      expect(r.estado, EstadoMuestra.correcta);
      expect(r.volumenDna, closeTo(2, 0.0001));
      expect(r.volumenAgua, closeTo(3, 0.0001));
    });

    test('Muy concentrada: propone la primera dilución pipeteable', () {
      final r = paso.calcularMuestra(muestra('M4', 250)); // 0,2 µL sin diluir

      expect(r.estado, EstadoMuestra.diluir);
      expect(r.factorDilucion, 5);
      expect(r.volumenDna, closeTo(1, 0.0001));
      expect(r.volumenAgua, closeTo(4, 0.0001));
      expect(r.listo, isTrue);
    });

    test('Demasiado concentrada: ni con 1:100 basta', () {
      final r = paso.calcularMuestra(muestra('MX', 10000));

      expect(r.estado, EstadoMuestra.diluir);
      expect(r.factorDilucion, isNull);
      expect(r.listo, isFalse);
    });

    test('Poco concentrada: se usa el hueco entero y se anotan los ng reales', () {
      final r = paso.calcularMuestra(muestra('M3', 8)); // necesitaría 6,25 µL

      expect(r.estado, EstadoMuestra.huecoCompleto);
      expect(r.volumenDna, closeTo(5, 0.0001));
      expect(r.volumenAgua, closeTo(0, 0.0001));
      expect(r.ngReales, closeTo(40, 0.0001));
      expect(r.listo, isTrue);
    });

    test('Sin concentración no se puede pipetear', () {
      final r = paso.calcularMuestra(muestra('M5', null));

      expect(r.estado, EstadoMuestra.sinConcentracion);
      expect(r.listo, isFalse);
    });

    test('Modo volumen fijo: todo el hueco es DNA y no hace falta concentración', () {
      const pasoFijo = PasoCalculo(
        titulo: 'Volumen fijo',
        volumenReaccion: 25,
        volumenMolde: 1,
        modo: ModoMolde.volumenFijo,
        reactivos: [Reactivo(nombre: 'Buffer', volPorReaccion: 2.5)],
        tiposTubo: [TipoTubo(nombre: 'Muestra', conDna: true)],
      );
      final r = pasoFijo.calcularMuestra(muestra('M1', null));

      expect(r.estado, EstadoMuestra.correcta);
      expect(r.volumenDna, closeTo(1, 0.0001));
      expect(r.volumenAgua, closeTo(0, 0.0001));
    });
  });

  test('La instrucción de un tubo sin DNA usa el volumen del hueco', () {
    const tubo = TipoTubo(nombre: 'Control negativo', seAnade: 'agua', cantidadFija: 1);

    expect(tubo.instruccion(5), '5 µL de agua');
    expect(tubo.instruccion(2.5), '2.5 µL de agua');
  });

  test('Una versión nueva conserva el id y no modifica la original', () {
    final v2 = pcrEstandar.nuevaVersion();

    expect(v2.id, pcrEstandar.id);
    expect(v2.version, 2);
    expect(pcrEstandar.version, 1);
    expect(v2.nombreCompleto, 'PCR estándar (V.2)');
  });

  test('Completar pasos y terminar una ejecución', () {
    final inicio = Ejecucion(
      protocoloId: pcrEstandar.id,
      protocoloVersion: pcrEstandar.version,
      inicio: DateTime.now(),
      muestras: [muestra('M1', 25)],
    );

    final conUnPaso = inicio.completarPaso(0, nota: 'Reactivos ya descongelados');
    final terminada = conUnPaso.terminar();

    expect(inicio.registros, isEmpty); // la original no cambia
    expect(conUnPaso.registros.length, 1);
    expect(conUnPaso.registros.first.nota, 'Reactivos ya descongelados');
    expect(terminada.estado, EstadoEjecucion.completada);
    expect(terminada.estado.etiqueta, 'Completada');
    expect(terminada.fin, isNotNull);
    expect(terminada.muestras.first.codigo, 'M1'); // las muestras se conservan
  });
}
