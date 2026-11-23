// AeriS - Laboratory protocol assistant
// Copyright (C) 2026 Alejandro Pascual Hernández and contributors
// SPDX-License-Identifier: GPL-3.0-or-later
// Additional permission for app stores: see EXCEPCION_TIENDAS.md

import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as rutas;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:aeris/modelos/ejemplos.dart';
import 'package:aeris/modelos/formato.dart';
import 'package:aeris/modelos/imagenes.dart';
import 'package:aeris/modelos/paso.dart';
import 'package:aeris/modelos/protocolo.dart';
import 'package:aeris/pantallas/editor/editor_texto.dart';
import 'package:aeris/pantallas/widgets/imagen_guardada.dart';
import 'package:aeris/pantallas/widgets/texto_formato.dart';
import 'package:aeris/servicios/almacen.dart';
import 'package:aeris/servicios/copia_seguridad.dart';
import 'package:aeris/servicios/intercambio.dart';
import 'package:aeris/servicios/selector_imagenes.dart';
import 'package:aeris/tema.dart';

import 'almacen_de_prueba.dart';
import 'selector_de_prueba.dart';

/// Un protocolo con una foto en su paso.
final conFoto = Protocolo(
  id: 'gel-con-foto',
  nombre: 'Gel con foto',
  version: 1,
  creado: DateTime(2026, 11, 23),
  pasos: [
    PasoInstrucciones(
      titulo: 'Montar la cubeta',
      texto: 'Colocar el gel así:\n\n${marcaImagen('img-1', pie: 'Montaje')}\n\nY cubrir con TAE.',
    ),
  ],
);

void main() {
  group('Marcas de imagen en el texto', () {
    test('Se encuentran los ids, y solo los de AeriS', () {
      const texto = '![a](imagen:img-1) y ![b](imagen:img-2)\n![web](https://x.org/f.png)';
      expect(imagenesDelTexto(texto), {'img-1', 'img-2'});
    });

    test('Las del protocolo, de todos sus pasos', () {
      expect(imagenesDelProtocolo(conFoto), {'img-1'});
      expect(imagenesDelProtocolo(pcrEstandar), isEmpty);
    });

    test('Los ids nuevos no se repiten y se reconocen en el texto', () {
      final ids = {for (var i = 0; i < 100; i++) nuevoIdImagen()};
      expect(ids, hasLength(100));
      expect(imagenesDelTexto(marcaImagen(ids.first)), {ids.first});
    });

    test('La imagen se inserta en su propia línea', () {
      const v = TextEditingValue(
        text: 'Antes del gel. Después',
        selection: TextSelection.collapsed(offset: 15), // tras "gel. "
      );
      final r = insertarBloque(v, '![](imagen:x)');
      expect(r.text, 'Antes del gel. \n\n![](imagen:x)\n\nDespués');
    });
  });

  group('Formato del archivo', () {
    final fotos = {'img-1': pngDePrueba};

    test('Sin imágenes se sigue escribiendo la versión 1', () {
      expect(exportarProtocolo(pcrEstandar), contains('"formato": 1'));
    });

    test('Con imágenes, versión 2 y las imágenes dentro', () {
      final texto = exportarProtocolo(conFoto, imagenes: fotos);
      final datos = jsonDecode(texto) as Map<String, dynamic>;

      expect(datos['formato'], 2);
      expect((datos['imagenes'] as Map)['img-1'], base64Encode(pngDePrueba));
    });

    test('Al importar, la imagen llega al almacén', () async {
      final destino = AlmacenEnMemoria();
      await importarEnAlmacen(exportarProtocolo(conFoto, imagenes: fotos), destino);

      expect(destino.imagenes['img-1'], pngDePrueba);
      expect(await destino.protocolo('gel-con-foto', 1), isNotNull);
    });

    test('Exportar busca solo las imágenes que usa el protocolo', () async {
      final origen = AlmacenEnMemoria([conFoto])
        ..imagenes['img-1'] = pngDePrueba
        ..imagenes['img-otra'] = pngDePrueba;

      final incluidas = await imagenesDe([conFoto], origen);
      expect(incluidas.keys, ['img-1']);
    });

    test('Una imagen dañada da un mensaje claro', () {
      final datos = jsonDecode(exportarProtocolo(conFoto, imagenes: fotos)) as Map<String, dynamic>;
      datos['imagenes'] = {'img-1': '¡esto no es base64!'};
      expect(
        () => leerArchivoProtocolo(jsonEncode(datos)),
        throwsA(isA<FormatException>().having((e) => e.message, 'mensaje', contains('imágenes'))),
      );
    });

    test('La copia de seguridad también lleva las imágenes', () async {
      final origen = AlmacenEnMemoria([conFoto])..imagenes['img-1'] = pngDePrueba;
      final destino = AlmacenEnMemoria();

      await restaurarCopia(await crearCopia(origen), destino);
      expect(destino.imagenes['img-1'], pngDePrueba);
    });
  });

  group('Base de datos', () {
    setUpAll(sqfliteFfiInit);

    test('Guardar y leer una imagen (BLOB)', () async {
      final bd = AlmacenSqlite(
        fabrica: databaseFactoryFfi,
        ruta: inMemoryDatabasePath,
        instanciaUnica: false,
      );
      await bd.abrir();
      await bd.guardarImagen('img-1', pngDePrueba);

      expect(await bd.imagen('img-1'), pngDePrueba);
      expect(await bd.imagen('no-existe'), isNull);
      await bd.cerrar();
    });

    test('Migración: una base de datos de la versión 1 se actualiza sin perder nada', () async {
      final carpeta = await Directory.systemTemp.createTemp('aeris_test_');
      addTearDown(() => carpeta.delete(recursive: true));
      final ruta = rutas.join(carpeta.path, 'antigua.db');

      // 1. Una base de datos "como la del móvil antes de esta lección": sin tabla de imágenes
      final antigua = await databaseFactoryFfi.openDatabase(
        ruta,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: (db, version) async {
            await db.execute(
              'CREATE TABLE protocolos (id TEXT NOT NULL, version INTEGER NOT NULL, '
              'nombre TEXT NOT NULL, creado TEXT NOT NULL, contenido TEXT NOT NULL, '
              'PRIMARY KEY (id, version))',
            );
            await db.execute(
              'CREATE TABLE ejecuciones (id INTEGER PRIMARY KEY AUTOINCREMENT, '
              'protocolo_id TEXT NOT NULL, protocolo_version INTEGER NOT NULL, '
              'inicio TEXT NOT NULL, estado TEXT NOT NULL, contenido TEXT NOT NULL)',
            );
            await db.insert('protocolos', {
              'id': pcrEstandar.id,
              'version': 1,
              'nombre': pcrEstandar.nombre,
              'creado': pcrEstandar.creado.toIso8601String(),
              'contenido': jsonEncode(pcrEstandar.toJson()),
            });
          },
        ),
      );
      await antigua.close();

      // 2. La app nueva la abre: onUpgrade crea la tabla que falta
      final nueva = AlmacenSqlite(fabrica: databaseFactoryFfi, ruta: ruta, instanciaUnica: false);
      await nueva.abrir();

      expect((await nueva.ultimasVersiones()).single.nombre, pcrEstandar.nombre); // lo de antes sigue
      await nueva.guardarImagen('img-1', pngDePrueba); // y ya hay sitio para imágenes
      expect(await nueva.imagen('img-1'), pngDePrueba);
      await nueva.cerrar();
    });
  });

  group('Pantallas', () {
    late AlmacenEnMemoria almacenFalso;
    setUp(() {
      almacenFalso = AlmacenEnMemoria();
      almacen = almacenFalso;
    });

    Future<void> pintar(WidgetTester tester, Widget hijo) => tester.pumpWidget(MaterialApp(
          theme: temaAeris(),
          home: Scaffold(body: SingleChildScrollView(child: hijo)),
        ));

    testWidgets('Añadir una foto desde el editor', (tester) async {
      final selector = SelectorDePrueba(pngDePrueba);
      selectorImagenes = selector;
      String? texto;
      await pintar(tester, EditorTextoFormato(texto: 'Cargar el gel.', onCambio: (t) => texto = t));

      await tester.tap(find.byTooltip('Imagen'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Elegir de la galería'));
      await tester.pumpAndSettle();
      await tester.enterText(find.widgetWithText(TextField, 'Qué se ve (opcional)'), 'Gel [final]');
      await tester.tap(find.text('Añadir'));
      await tester.pumpAndSettle();

      expect(selector.pedidos, [OrigenImagen.galeria]);
      final id = almacenFalso.imagenes.keys.single;
      expect(almacenFalso.imagenes[id], pngDePrueba);
      // Los corchetes del pie se quitan: romperían el Markdown
      expect(texto, 'Cargar el gel.\n\n![Gel final](imagen:$id)\n\n');
    });

    testWidgets('Cancelar la foto no cambia nada', (tester) async {
      selectorImagenes = SelectorDePrueba(null); // el usuario cierra la cámara
      String? texto;
      await pintar(tester, EditorTextoFormato(texto: 'Hola', onCambio: (t) => texto = t));

      await tester.tap(find.byTooltip('Imagen'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hacer una foto'));
      await tester.pumpAndSettle();

      expect(texto, isNull);
      expect(almacenFalso.imagenes, isEmpty);
    });

    testWidgets('El texto muestra la imagen con su pie', (tester) async {
      almacenFalso.imagenes['img-1'] = pngDePrueba;
      final paso = conFoto.pasos.single as PasoInstrucciones;
      await pintar(tester, TextoConFormato(texto: paso.texto));
      await tester.pumpAndSettle();

      expect(find.byType(ImagenGuardada), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
      expect(find.text('Montaje'), findsOneWidget);
    });

    testWidgets('Si falta la imagen, se dice en vez de fallar', (tester) async {
      await pintar(tester, TextoConFormato(texto: marcaImagen('no-existe', pie: 'Gel')));
      await tester.pumpAndSettle();

      expect(find.text('Imagen no disponible: Gel'), findsOneWidget);
    });
  });

  // Para que ningún otro archivo de tests herede el selector falso
  tearDown(() => selectorImagenes = SelectorImagenesSistema());
}
