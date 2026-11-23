// AeriS - Laboratory protocol assistant
// Copyright (C) 2026 Alejandro Pascual Hernández and contributors
// SPDX-License-Identifier: GPL-3.0-or-later
// Additional permission for app stores: see EXCEPCION_TIENDAS.md

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:aeris/modelos/imagenes.dart';
import 'package:aeris/modelos/paso.dart';
import 'package:aeris/modelos/protocolo.dart';
import 'package:aeris/servicios/almacen.dart';
import 'package:aeris/servicios/limpieza.dart';

import 'almacen_de_prueba.dart';
import 'selector_de_prueba.dart';

Protocolo conImagenes(int version, List<String> ids) => Protocolo(
      id: 'gel',
      nombre: 'Gel',
      version: version,
      creado: DateTime(2026, 11, version),
      pasos: [
        PasoInstrucciones(
          titulo: 'Paso',
          texto: [for (final id in ids) marcaImagen(id)].join('\n\n'),
        ),
      ],
    );

void main() {
  test('Borra solo las que no usa nadie', () async {
    final almacen = AlmacenEnMemoria([conImagenes(1, ['usada'])])
      ..imagenes['usada'] = pngDePrueba
      ..imagenes['huerfana'] = pngDePrueba;

    expect(await limpiarImagenesSinUso(almacen), 1);
    expect(almacen.imagenes.keys, ['usada']);
  });

  test('Una foto de una versión antigua se conserva', () async {
    // V.1 tenía la foto; en V.2 se quitó. La V.1 puede estar en el cuaderno.
    final almacen = AlmacenEnMemoria([conImagenes(1, ['antigua']), conImagenes(2, [])])
      ..imagenes['antigua'] = pngDePrueba;

    expect(await limpiarImagenesSinUso(almacen), 0);
    expect(almacen.imagenes, contains('antigua'));
  });

  test('Sin nada que borrar, no hace nada', () async {
    final almacen = AlmacenEnMemoria([conImagenes(1, [])]);
    expect(await limpiarImagenesSinUso(almacen), 0);
  });

  test('Con la base de datos de verdad', () async {
    sqfliteFfiInit();
    final bd = AlmacenSqlite(
      fabrica: databaseFactoryFfi,
      ruta: inMemoryDatabasePath,
      protocolosIniciales: [conImagenes(1, ['a', 'b'])],
      instanciaUnica: false,
    );
    await bd.abrir();
    for (final id in ['a', 'b', 'c', 'd']) {
      await bd.guardarImagen(id, pngDePrueba);
    }

    expect(await limpiarImagenesSinUso(bd), 2);
    expect(await bd.idsImagenes(), {'a', 'b'});
    await bd.cerrar();
  });
}
