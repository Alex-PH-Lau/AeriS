// AeriS - Laboratory protocol assistant
// Copyright (C) 2026 Alejandro Pascual Hernández and contributors
// SPDX-License-Identifier: GPL-3.0-or-later
// Additional permission for app stores: see EXCEPCION_TIENDAS.md

import 'package:flutter_test/flutter_test.dart';
import 'package:aeris/modelos/calculo.dart';
import 'package:aeris/modelos/ejecucion.dart';
import 'package:aeris/modelos/ejemplos.dart';
import 'package:aeris/modelos/paso.dart';

void main() {
  test('Mastermix de la PCR con 12 muestras y 2 controles', () {
    final paso = pcrEstandar.pasos[1] as PasoCalculo;
    final resultado = paso.calcular({'Muestra': 12});

    expect(resultado.totalTubos, 14);
    expect(resultado.factor, closeTo(15.4, 0.0001));
    expect(resultado.volumenesTotales['Buffer'], closeTo(38.5, 0.0001));
    expect(resultado.aguaPorTubo, closeTo(17.25, 0.0001));
    expect(resultado.volumenesTotales['Agua'], closeTo(265.65, 0.0001));
    expect(resultado.esValido, isTrue);
  });

  test('Solo se pregunta la cantidad de muestras', () {
    final paso = pcrEstandar.pasos[1] as PasoCalculo;

    expect(paso.tubosQueSePreguntan.length, 1);
    expect(paso.tubosQueSePreguntan.first.nombre, 'Muestra');
  });

  // Ejercicio 3
  test('Reactivos que no caben en la reacción dan un resultado no válido', () {
    const paso = PasoCalculo(
      titulo: 'Mastermix imposible',
      volumenReaccion: 25,
      volumenMolde: 1,
      reactivos: [
        Reactivo(nombre: 'Reactivo excesivo', volPorReaccion: 30),
      ],
      tiposTubo: [
        TipoTubo(nombre: 'Muestra', seAnade: 'su DNA', cantidadFija: 1),
      ],
    );
    final resultado = paso.calcular({});

    expect(resultado.aguaPorTubo, closeTo(-6, 0.0001));
    expect(resultado.esValido, isFalse);
  });

  test('La instrucción del tubo usa el volumen del molde', () {
    const tubo = TipoTubo(nombre: 'Control negativo', seAnade: 'agua', cantidadFija: 1);

    expect(tubo.instruccion(1), '1 µL de agua');
    expect(tubo.instruccion(2.5), '2.5 µL de agua');
  });

  test('Una versión nueva conserva el id y no modifica la original', () {
    final v2 = pcrEstandar.nuevaVersion();

    expect(v2.id, pcrEstandar.id);
    expect(v2.version, 2);
    expect(pcrEstandar.version, 1);
    expect(v2.nombreCompleto, 'PCR estándar (V.2)');
  });

  // Ejercicio 2
  test('Completar pasos y terminar una ejecución', () {
    final inicio = Ejecucion(
      protocoloId: pcrEstandar.id,
      protocoloVersion: pcrEstandar.version,
      inicio: DateTime.now(),
    );

    final conUnPaso = inicio.completarPaso(0, nota: 'Reactivos ya descongelados');
    final terminada = conUnPaso.terminar();

    expect(inicio.registros, isEmpty); // la original no cambia
    expect(conUnPaso.registros.length, 1);
    expect(conUnPaso.registros.first.nota, 'Reactivos ya descongelados');
    expect(terminada.estado, EstadoEjecucion.completada);
    expect(terminada.fin, isNotNull);
    expect(terminada.estado.etiqueta, 'Completada');
  });
}
