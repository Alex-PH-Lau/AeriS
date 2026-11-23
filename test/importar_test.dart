// AeriS - Laboratory protocol assistant
// Copyright (C) 2026 Alejandro Pascual Hernández and contributors
// SPDX-License-Identifier: GPL-3.0-or-later
// Additional permission for app stores: see EXCEPCION_TIENDAS.md

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:aeris/main.dart';
import 'package:aeris/modelos/ejemplos.dart';
import 'package:aeris/modelos/paso.dart';
import 'package:aeris/modelos/protocolo.dart';
import 'package:aeris/servicios/almacen.dart';
import 'package:aeris/servicios/archivos.dart';
import 'package:aeris/servicios/avisos.dart';
import 'package:aeris/servicios/intercambio.dart';

import 'almacen_de_prueba.dart';
import 'archivos_de_prueba.dart';
import 'avisos_de_prueba.dart';

/// Un protocolo que nadie tiene todavía.
final western = Protocolo(
  id: 'western-blot',
  nombre: 'Western blot',
  version: 1,
  creado: DateTime(2026, 11, 23),
  pasos: const [PasoInstrucciones(titulo: 'Bloquear', texto: 'Leche al 5 % durante 1 h.')],
);

/// La misma electroforesis (mismo id y V.2) pero editada por otra persona.
Protocolo electroforesisDeOtro() => Protocolo(
      id: electroforesis.id,
      nombre: electroforesis.nombre,
      version: electroforesis.version,
      creado: DateTime(2026, 11, 20),
      pasos: [
        ...electroforesis.pasos,
        const PasoInstrucciones(titulo: 'Fotografiar', texto: 'Con el transiluminador.'),
      ],
    );

void main() {
  group('Nombre del archivo', () {
    test('Sin tildes, espacios ni paréntesis', () {
      expect(nombreArchivo(pcrEstandar), 'PCR_estandar_V1.json');
      expect(nombreArchivo(electroforesis), 'Electroforesis_en_gel_de_agarosa_V2.json');
    });

    test('Un nombre solo con símbolos no deja el archivo sin nombre', () {
      final raro = Protocolo(id: 'x', nombre: '¿?', version: 3, creado: DateTime(2026), pasos: const []);
      expect(nombreArchivo(raro), 'protocolo_V3.json');
    });
  });

  group('Importar en el almacén', () {
    late AlmacenEnMemoria almacenFalso;
    setUp(() => almacenFalso = AlmacenEnMemoria([pcrEstandar, electroforesis]));

    test('Un protocolo nuevo se guarda con su id y su versión', () async {
      final importacion = await importarEnAlmacen(exportarProtocolo(western), almacenFalso);

      expect(importacion.resultado, ResultadoImportacion.nuevo);
      final guardado = await almacenFalso.protocolo('western-blot', 1);
      expect(guardado?.nombre, 'Western blot');
    });

    test('Importar lo que ya tienes no duplica nada', () async {
      final importacion = await importarEnAlmacen(exportarProtocolo(pcrEstandar), almacenFalso);

      expect(importacion.resultado, ResultadoImportacion.yaLoTenias);
      expect(await almacenFalso.protocolo(pcrEstandar.id, 2), isNull);
    });

    test('Una versión distinta con el mismo número no pisa la tuya', () async {
      final importacion = await importarEnAlmacen(
        exportarProtocolo(electroforesisDeOtro()),
        almacenFalso,
      );

      expect(importacion.resultado, ResultadoImportacion.nuevaVersion);
      expect(importacion.protocolo.version, 3); // detrás de nuestra V.2
      // La nuestra sigue intacta
      final nuestra = await almacenFalso.protocolo(electroforesis.id, 2);
      expect(nuestra?.numeroPasos, electroforesis.numeroPasos);
      final suya = await almacenFalso.protocolo(electroforesis.id, 3);
      expect(suya?.numeroPasos, electroforesis.numeroPasos + 1);
    });

    test('Un archivo no válido no guarda nada', () async {
      await expectLater(
        importarEnAlmacen('esto no es json', almacenFalso),
        throwsA(isA<FormatException>()),
      );
      expect(await almacenFalso.ultimasVersiones(), hasLength(2));
    });
  });

  group('Pantalla "Mis protocolos"', () {
    late AlmacenEnMemoria almacenFalso;
    late ArchivosDePrueba archivosFalsos;

    setUp(() {
      avisos = AvisosDePrueba();
      almacenFalso = AlmacenEnMemoria([pcrEstandar, electroforesis]);
      almacen = almacenFalso;
      archivosFalsos = ArchivosDePrueba();
      archivos = archivosFalsos;
    });

    Future<void> abrirMisProtocolos(WidgetTester tester) async {
      await tester.pumpWidget(const AerisApp());
      await tester.tap(find.text('Mis protocolos'));
      await tester.pumpAndSettle();
    }

    testWidgets('Compartir manda el JSON del protocolo con su nombre de archivo', (tester) async {
      await abrirMisProtocolos(tester);

      await tester.tap(find.descendant(
        of: find.widgetWithText(ListTile, pcrEstandar.nombreCompleto),
        matching: find.byTooltip('Compartir'),
      ));
      await tester.pumpAndSettle();

      final compartido = archivosFalsos.compartidos.single;
      expect(compartido.nombreArchivo, 'PCR_estandar_V1.json');
      expect(compartido.origen, isNotNull); // la posición del botón, para el iPad
      // Lo compartido se puede volver a importar y es el mismo protocolo
      final leido = importarProtocolo(compartido.contenido);
      expect(leido.nombreCompleto, pcrEstandar.nombreCompleto);
      expect(leido.pasos[1], isA<PasoCalculo>());
    });

    testWidgets('Importar un protocolo nuevo lo añade a la lista', (tester) async {
      await abrirMisProtocolos(tester);
      archivosFalsos.textoParaElegir = exportarProtocolo(western);

      await tester.tap(find.text('Importar'));
      await tester.pumpAndSettle();

      expect(find.text('Importado: Western blot (V.1).'), findsOneWidget); // SnackBar
      expect(find.widgetWithText(ListTile, 'Western blot (V.1)'), findsOneWidget);
    });

    testWidgets('Un archivo que no es de AeriS muestra el motivo', (tester) async {
      await abrirMisProtocolos(tester);
      archivosFalsos.textoParaElegir = '{"hola": "mundo"}';

      await tester.tap(find.text('Importar'));
      await tester.pumpAndSettle();

      expect(find.text('No se pudo importar'), findsOneWidget);
      expect(find.text('El archivo no es un protocolo de AeriS.'), findsOneWidget);
      await tester.tap(find.text('Entendido'));
      await tester.pumpAndSettle();
      expect(find.text('No se pudo importar'), findsNothing);
    });

    testWidgets('Cancelar la elección de archivo no hace nada', (tester) async {
      await abrirMisProtocolos(tester);
      archivosFalsos.textoParaElegir = null;

      await tester.tap(find.text('Importar'));
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsNothing);
      expect(find.byType(AlertDialog), findsNothing);
    });
  });
}
