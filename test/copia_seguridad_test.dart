// AeriS - Laboratory protocol assistant
// Copyright (C) 2026 Alejandro Pascual Hernández and contributors
// SPDX-License-Identifier: GPL-3.0-or-later
// Additional permission for app stores: see EXCEPCION_TIENDAS.md

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:aeris/main.dart';
import 'package:aeris/modelos/ejecucion.dart';
import 'package:aeris/modelos/ejemplos.dart';
import 'package:aeris/modelos/paso.dart';
import 'package:aeris/modelos/protocolo.dart';
import 'package:aeris/servicios/almacen.dart';
import 'package:aeris/servicios/archivos.dart';
import 'package:aeris/servicios/avisos.dart';
import 'package:aeris/servicios/copia_seguridad.dart';
import 'package:aeris/servicios/intercambio.dart';

import 'almacen_de_prueba.dart';
import 'archivos_de_prueba.dart';
import 'avisos_de_prueba.dart';

// OJO: todos los datos de prueba llevan fechas FIJAS. Con DateTime.now()
// (que usan nuevaVersion y completarPaso), dos dispositivos creados en
// momentos distintos tendrían datos "distintos" y la copia no los reconocería.

Ejecucion ejecucionDe(Protocolo protocolo, DateTime inicio) => Ejecucion(
      protocoloId: protocolo.id,
      protocoloVersion: protocolo.version,
      inicio: inicio,
      registros: [
        RegistroPaso(
          indicePaso: 0,
          completadoEn: inicio.add(const Duration(minutes: 10)),
          nota: 'Todo bien',
        ),
      ],
    );

/// La PCR editada una vez, con fecha fija.
final pcrV2 = Protocolo(
  id: pcrEstandar.id,
  nombre: pcrEstandar.nombre,
  version: 2,
  creado: DateTime(2026, 11, 22, 18),
  pasos: pcrEstandar.pasos,
);

/// Un dispositivo con algo de historia: la PCR en V.1 y V.2 y dos ejecuciones.
Future<AlmacenEnMemoria> dispositivoConDatos() async {
  final almacen = AlmacenEnMemoria([pcrEstandar, pcrV2, electroforesis]);
  await almacen.crearEjecucion(ejecucionDe(pcrEstandar, DateTime(2026, 11, 20, 9)));
  await almacen.crearEjecucion(ejecucionDe(electroforesis, DateTime(2026, 11, 21, 16)));
  return almacen;
}

void main() {
  test('Nombre del archivo con la fecha', () {
    expect(nombreArchivoCopia(DateTime(2026, 3, 7)), 'AeriS_copia_2026-03-07.json');
  });

  group('Crear y restaurar', () {
    test('Una tablet nueva recupera todo, versiones antiguas incluidas', () async {
      final copia = await crearCopia(await dispositivoConDatos());
      final nueva = AlmacenEnMemoria(); // tablet recién estrenada

      final resumen = await restaurarCopia(copia, nueva);

      expect(resumen.protocolosNuevos, 3);
      expect(resumen.ejecucionesNuevas, 2);
      expect(await nueva.protocolo(pcrEstandar.id, 1), isNotNull);
      expect(await nueva.protocolo(pcrEstandar.id, 2), isNotNull);
      final cuaderno = await nueva.cuaderno();
      expect(cuaderno.first.protocolo.nombreCompleto, electroforesis.nombreCompleto); // la más reciente
      expect(cuaderno.last.ejecucion.registros.single.nota, 'Todo bien');
    });

    test('Restaurar dos veces no duplica nada', () async {
      final almacen = await dispositivoConDatos();
      final copia = await crearCopia(almacen);

      final resumen = await restaurarCopia(copia, almacen);

      expect(resumen.sinCambios, isTrue);
      expect(resumen.protocolosRepetidos, 3);
      expect(resumen.ejecucionesRepetidas, 2);
      expect(almacen.ejecuciones, hasLength(2));
    });

    test('Restaurar suma: lo que solo estaba en el dispositivo se queda', () async {
      final copia = await crearCopia(await dispositivoConDatos());
      final almacen = AlmacenEnMemoria([pcrEstandar]);
      await almacen.crearEjecucion(ejecucionDe(pcrEstandar, DateTime(2026, 11, 23, 8)));

      await restaurarCopia(copia, almacen);

      expect(almacen.ejecuciones, hasLength(3)); // la suya + las dos de la copia
    });

    test('Si un protocolo no coincide, se mantiene el del dispositivo', () async {
      final copia = await crearCopia(await dispositivoConDatos());
      // En este dispositivo, la electroforesis V.2 es otra cosa
      final distinta = Protocolo(
        id: electroforesis.id,
        nombre: 'Mi electroforesis',
        version: electroforesis.version,
        creado: DateTime(2026, 1, 1),
        pasos: const [PasoInstrucciones(titulo: 'Otra', texto: 'Otra cosa')],
      );
      final almacen = AlmacenEnMemoria([distinta]);

      final resumen = await restaurarCopia(copia, almacen);

      expect(resumen.protocolosEnConflicto, 1);
      expect((await almacen.protocolo(electroforesis.id, 2))?.nombre, 'Mi electroforesis');
      // Su ejecución no se restaura: quedaría ligada al protocolo equivocado
      expect(resumen.ejecucionesOmitidas, 1);
      expect(resumen.ejecucionesNuevas, 1); // la de la PCR, sí
    });

    test('Una ejecución sin su protocolo en ningún sitio se omite', () async {
      final copia = jsonEncode({
        'aplicacion': 'AeriS',
        'tipo': 'copia',
        'formato': 1,
        'protocolos': [],
        'ejecuciones': [ejecucionDe(pcrEstandar, DateTime(2026, 11, 1)).toJson()],
      });
      final resumen = await restaurarCopia(copia, AlmacenEnMemoria());

      expect(resumen.ejecucionesOmitidas, 1);
      expect(resumen.ejecucionesNuevas, 0);
    });
  });

  group('Archivos que no son una copia', () {
    test('Un protocolo suelto se rechaza con un consejo', () async {
      await expectLater(
        restaurarCopia(exportarProtocolo(pcrEstandar), AlmacenEnMemoria()),
        throwsA(isA<FormatException>().having(
          (e) => e.message,
          'mensaje',
          contains('Impórtalo desde "Mis protocolos"'),
        )),
      );
    });

    test('Y una copia no se puede importar como protocolo', () async {
      final copia = await crearCopia(await dispositivoConDatos());
      expect(
        () => importarProtocolo(copia),
        throwsA(isA<FormatException>().having((e) => e.message, 'mensaje', contains('copia de seguridad'))),
      );
    });

    test('Una copia dañada no guarda nada a medias', () async {
      final datos = jsonDecode(await crearCopia(await dispositivoConDatos())) as Map<String, dynamic>;
      (datos['ejecuciones'] as List).add({'esto': 'no es una ejecución'});
      final almacen = AlmacenEnMemoria();

      await expectLater(restaurarCopia(jsonEncode(datos), almacen), throwsA(isA<FormatException>()));
      expect(await almacen.todasLasVersiones(), isEmpty); // ni siquiera los protocolos
    });
  });

  group('Con la base de datos de verdad', () {
    setUpAll(sqfliteFfiInit);

    test('La copia de una base de datos se restaura en otra', () async {
      AlmacenSqlite nuevaBd(List<Protocolo> iniciales) => AlmacenSqlite(
            fabrica: databaseFactoryFfi,
            ruta: inMemoryDatabasePath,
            protocolosIniciales: iniciales,
            instanciaUnica: false,
          );

      final origen = nuevaBd([pcrEstandar, electroforesis]);
      await origen.abrir();
      await origen.crearEjecucion(ejecucionDe(pcrEstandar, DateTime(2026, 11, 22)));
      final copia = await crearCopia(origen);
      await origen.cerrar();

      final destino = nuevaBd([]); // sin ejemplos
      await destino.abrir();
      final resumen = await restaurarCopia(copia, destino);

      expect(resumen.protocolosNuevos, 2);
      expect(resumen.ejecucionesNuevas, 1);
      expect((await destino.cuaderno()).single.protocolo.id, pcrEstandar.id);
      await destino.cerrar();
    });
  });

  group('Pantalla del cuaderno', () {
    late ArchivosDePrueba archivosFalsos;

    setUp(() async {
      avisos = AvisosDePrueba();
      almacen = await dispositivoConDatos();
      archivosFalsos = ArchivosDePrueba();
      archivos = archivosFalsos;
    });

    Future<void> abrirMenu(WidgetTester tester) async {
      await tester.pumpWidget(const AerisApp());
      await tester.tap(find.text('Cuaderno de laboratorio'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Copia de seguridad'));
      await tester.pumpAndSettle();
    }

    testWidgets('Guardar una copia la comparte con la fecha en el nombre', (tester) async {
      await abrirMenu(tester);
      await tester.tap(find.text('Guardar copia de seguridad'));
      await tester.pumpAndSettle();

      final compartido = archivosFalsos.compartidos.single;
      expect(compartido.nombreArchivo, startsWith('AeriS_copia_'));
      final resumen = await restaurarCopia(compartido.contenido, AlmacenEnMemoria());
      expect(resumen.ejecucionesNuevas, 2);
    });

    testWidgets('Restaurar muestra un resumen y el cuaderno se actualiza', (tester) async {
      // La copia viene de "otra tablet" con una ejecución más
      final otra = await dispositivoConDatos();
      await otra.crearEjecucion(ejecucionDe(pcrEstandar, DateTime(2026, 11, 22, 12)));
      archivosFalsos.textoParaElegir = await crearCopia(otra);

      await abrirMenu(tester);
      await tester.tap(find.text('Restaurar una copia'));
      await tester.pumpAndSettle();

      expect(find.text('Copia restaurada'), findsOneWidget);
      expect(find.text('Ejecuciones añadidas al cuaderno: 1'), findsOneWidget);
      await tester.tap(find.text('Entendido'));
      await tester.pumpAndSettle();
      expect((almacen as AlmacenEnMemoria).ejecuciones, hasLength(3));
    });

    testWidgets('Restaurar un archivo equivocado explica el motivo', (tester) async {
      archivosFalsos.textoParaElegir = exportarProtocolo(pcrEstandar);

      await abrirMenu(tester);
      await tester.tap(find.text('Restaurar una copia'));
      await tester.pumpAndSettle();

      expect(find.text('No se pudo restaurar'), findsOneWidget);
      expect(find.textContaining('protocolo suelto'), findsOneWidget);
    });
  });
}
