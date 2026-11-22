// AeriS - Laboratory protocol assistant
// Copyright (C) 2026 Alejandro Pascual Hernández and contributors
// SPDX-License-Identifier: GPL-3.0-or-later
// Additional permission for app stores: see EXCEPCION_TIENDAS.md

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:aeris/modelos/calculo.dart';
import 'package:aeris/modelos/ejecucion.dart';
import 'package:aeris/modelos/ejemplos.dart';
import 'package:aeris/modelos/paso.dart';
import 'package:aeris/modelos/protocolo.dart';
import 'package:aeris/servicios/intercambio.dart';

/// Simula guardar y volver a leer: objeto → JSON → texto → JSON → objeto.
Map<String, dynamic> idaYVuelta(Map<String, dynamic> json) =>
    jsonDecode(jsonEncode(json)) as Map<String, dynamic>;

void main() {
  group('Ida y vuelta: nada se pierde al guardar y leer', () {
    test('La PCR (pasos de instrucciones y de cálculo)', () {
      final copia = Protocolo.fromJson(idaYVuelta(pcrEstandar.toJson()));

      expect(copia.toJson(), pcrEstandar.toJson());
      expect(copia.nombreCompleto, 'PCR estándar (V.1)');
      expect(copia.pasos[1], isA<PasoCalculo>());
      expect(copia.pasos[1].alerta?.mensaje, contains('Taq'));
    });

    test('La copia de la PCR calcula igual que la original', () {
      final copia = Protocolo.fromJson(idaYVuelta(pcrEstandar.toJson()));
      final paso = copia.pasos[1] as PasoCalculo;
      final resultado = paso.calcular(const [
        Muestra(id: 'c', tipo: 'Control positivo', codigo: 'C+', concentracion: 50),
        Muestra(id: 'm', tipo: 'Muestra', codigo: 'M1', concentracion: 25),
      ]);

      expect(resultado.volumenTotal, closeTo(66, 0.0001));
      expect(resultado.muestras[1].volumenDna, closeTo(2, 0.0001));
    });

    test('La electroforesis conserva su temporizador', () {
      final copia = Protocolo.fromJson(idaYVuelta(electroforesis.toJson()));

      expect(copia.toJson(), electroforesis.toJson());
      expect(copia.pasos[3].temporizador?.duracion, const Duration(minutes: 30));
    });

    test('Una ejecución terminada, con muestras, valores y notas', () {
      final original = Ejecucion(
        protocoloId: 'pcr-estandar',
        protocoloVersion: 1,
        inicio: DateTime(2026, 11, 22, 10, 30),
        valoresIntroducidos: const {'Lote de la Taq': 'A123'},
        muestras: const [
          Muestra(id: 'm1', tipo: 'Muestra', codigo: 'Vid-23', concentracion: 37.5),
        ],
      ).completarPaso(0, nota: 'Reactivos descongelados').terminar();

      final copia = Ejecucion.fromJson(idaYVuelta(original.toJson()));

      expect(copia.toJson(), original.toJson());
      expect(copia.estado, EstadoEjecucion.completada);
      expect(copia.muestras.first.concentracion, 37.5);
      expect(copia.registros.first.nota, 'Reactivos descongelados');
    });
  });

  group('Detalles de la lectura', () {
    test('Un número entero en el JSON se lee como double', () {
      final reactivo = Reactivo.fromJson({'nombre': 'Buffer', 'volPorReaccion': 2});
      expect(reactivo.volPorReaccion, 2.0);
    });

    test('Los campos opcionales vacíos no se escriben', () {
      const taq = Reactivo(nombre: 'Taq polimerasa', volPorReaccion: 0.25);
      expect(taq.toJson().containsKey('concentracion'), isFalse);
    });

    test('Un tipo de paso desconocido da un error claro', () {
      expect(
        () => Paso.fromJson({'tipo': 'centrifuga', 'titulo': 'Centrifugar'}),
        throwsFormatException,
      );
    });
  });

  group('Exportar e importar archivos', () {
    test('Lo exportado se importa igual', () {
      final texto = exportarProtocolo(pcrEstandar);

      expect(texto, contains('"aplicacion": "AeriS"'));
      expect(texto, contains('"formato": 1'));
      expect(importarProtocolo(texto).toJson(), pcrEstandar.toJson());
    });

    test('Un texto que no es JSON', () {
      expect(() => importarProtocolo('esto no es json'), throwsFormatException);
    });

    test('Un JSON que no es de AeriS', () {
      expect(() => importarProtocolo('{"hola": 1}'), throwsFormatException);
    });

    test('Un archivo de una versión más nueva de AeriS', () {
      expect(
        () => importarProtocolo('{"aplicacion": "AeriS", "formato": 99, "protocolo": {}}'),
        throwsA(isA<FormatException>().having(
          (error) => error.message,
          'mensaje',
          contains('versión más nueva'),
        )),
      );
    });

    test('Un archivo dañado', () {
      expect(
        () => importarProtocolo('{"aplicacion": "AeriS", "formato": 1, "protocolo": {"id": 5}}'),
        throwsFormatException,
      );
    });
  });
}
