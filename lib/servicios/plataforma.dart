// AeriS - Laboratory protocol assistant
// Copyright (C) 2026 Alejandro Pascual Hernández and contributors
// SPDX-License-Identifier: GPL-3.0-or-later
// Additional permission for app stores: see EXCEPCION_TIENDAS.md

import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as rutas;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:aeris/modelos/ejemplos.dart';
import 'package:aeris/servicios/almacen.dart';
import 'package:aeris/servicios/archivos.dart';
import 'package:aeris/servicios/avisos.dart';
import 'package:aeris/servicios/selector_imagenes.dart';

/// Windows o Linux. (macOS se parece más a iOS y se verá aparte.)
bool get esEscritorio => !kIsWeb && (Platform.isWindows || Platform.isLinux);

/// Cambia los servicios que no funcionan igual en el ordenador.
///
/// Esta es la recompensa de haber escondido cada plugin detrás de una clase
/// abstracta (avisos, almacén, archivos, imágenes): las pantallas no se tocan,
/// solo se elige aquí qué implementación usar. Es lo mismo que hacen los
/// tests con sus versiones falsas.
Future<void> prepararPlataforma() async {
  if (!esEscritorio) return; // Android e iOS: lo de siempre

  // sqflite no existe para Windows; su "hermano" ffi usa SQLite directamente.
  // Es el mismo que ya usaban los tests en tu ordenador.
  sqfliteFfiInit();
  // La carpeta de datos de la app (en Windows, dentro de AppData\Roaming)
  final carpeta = await getApplicationSupportDirectory();
  almacen = AlmacenSqlite(
    fabrica: databaseFactoryFfi,
    ruta: rutas.join(carpeta.path, 'aeris.db'),
    protocolosIniciales: protocolosDeEjemplo,
  );

  avisos = AvisosSoloEnApp();
  archivos = ArchivosEscritorio();
  selectorImagenes = SelectorImagenesEscritorio();
}
