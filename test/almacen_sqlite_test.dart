// AeriS - Laboratory protocol assistant
// Copyright (C) 2026 Alejandro Pascual Hernández and contributors
// SPDX-License-Identifier: GPL-3.0-or-later
// Additional permission for app stores: see EXCEPCION_TIENDAS.md

// Prueba el SQL de verdad con una base de datos SQLite en memoria.

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:aeris/modelos/ejecucion.dart';
import 'package:aeris/modelos/ejemplos.dart';
import 'package:aeris/servicios/almacen.dart';

void main() {
  late AlmacenSqlite bd;

  setUpAll(() {
    sqfliteFfiInit(); // SQLite para el ordenador donde corren los tests
  });

  setUp(() async {
    bd = AlmacenSqlite(
      fabrica: databaseFactoryFfi,
      ruta: inMemoryDatabasePath, // en memoria: cada test empieza de cero
      protocolosIniciales: [pcrEstandar, electroforesis],
      instanciaUnica: false,
    );
    await bd.abrir();
  });

  tearDown(() => bd.cerrar());

  Ejecucion nuevaEjecucion(DateTime inicio) => Ejecucion(
        protocoloId: pcrEstandar.id,
        protocoloVersion: pcrEstandar.version,
        inicio: inicio,
      );

  group('Protocolos', () {
    test('Al crear la base de datos se guardan los ejemplos, ordenados por nombre', () async {
      final protocolos = await bd.ultimasVersiones();

      expect(protocolos.map((p) => p.nombre), ['Electroforesis en gel de agarosa', 'PCR estándar']);
    });

    test('Solo se muestra la última versión, pero las antiguas siguen guardadas', () async {
      await bd.guardarProtocolo(pcrEstandar.nuevaVersion());

      final protocolos = await bd.ultimasVersiones();
      final pcr = protocolos.firstWhere((p) => p.id == pcrEstandar.id);
      expect(pcr.version, 2);
      expect(protocolos.length, 2);

      final antigua = await bd.protocolo(pcrEstandar.id, 1);
      expect(antigua?.nombreCompleto, 'PCR estándar (V.1)');
    });

    test('Un protocolo que no existe devuelve null', () async {
      expect(await bd.protocolo('no-existe', 1), isNull);
    });

    test('todasLasVersiones incluye también las antiguas', () async {
      await bd.guardarProtocolo(pcrEstandar.nuevaVersion());

      final todas = await bd.todasLasVersiones();
      expect(todas.map((p) => p.nombreCompleto), unorderedEquals([
        'Electroforesis en gel de agarosa (V.2)',
        'PCR estándar (V.1)',
        'PCR estándar (V.2)',
      ]));
    });
  });

  group('Cuaderno', () {
    test('Crear, actualizar y leer una ejecución', () async {
      final id = await bd.crearEjecucion(nuevaEjecucion(DateTime(2026, 11, 22, 10)));
      final terminada =
          nuevaEjecucion(DateTime(2026, 11, 22, 10)).completarPaso(0).terminar();
      await bd.actualizarEjecucion(id, terminada);

      final cuaderno = await bd.cuaderno();
      expect(cuaderno.length, 1);
      expect(cuaderno.first.id, id);
      expect(cuaderno.first.ejecucion.estado, EstadoEjecucion.completada);
      expect(cuaderno.first.protocolo.nombreCompleto, 'PCR estándar (V.1)');
    });

    test('La ejecución más reciente aparece primero', () async {
      await bd.crearEjecucion(nuevaEjecucion(DateTime(2026, 11, 20)));
      final reciente = await bd.crearEjecucion(nuevaEjecucion(DateTime(2026, 11, 22)));
      await bd.crearEjecucion(nuevaEjecucion(DateTime(2026, 11, 21)));

      final cuaderno = await bd.cuaderno();
      expect(cuaderno.first.id, reciente);
    });

    test('Una ejecución sigue ligada a su versión aunque salga otra nueva', () async {
      await bd.crearEjecucion(nuevaEjecucion(DateTime(2026, 11, 22)));
      await bd.guardarProtocolo(pcrEstandar.nuevaVersion());

      final cuaderno = await bd.cuaderno();
      expect(cuaderno.first.protocolo.version, 1);
    });

    test('Borrar una ejecución', () async {
      final id = await bd.crearEjecucion(nuevaEjecucion(DateTime(2026, 11, 22)));
      await bd.borrarEjecucion(id);

      expect(await bd.cuaderno(), isEmpty);
    });

    test('La clave foránea impide guardar una ejecución de un protocolo que no existe', () async {
      final huerfana = Ejecucion(
        protocoloId: 'no-existe',
        protocoloVersion: 1,
        inicio: DateTime(2026, 11, 22),
      );
      await expectLater(bd.crearEjecucion(huerfana), throwsA(isA<DatabaseException>()));
    });
  });
}
