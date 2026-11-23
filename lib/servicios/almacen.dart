// AeriS - Laboratory protocol assistant
// Copyright (C) 2026 Alejandro Pascual Hernández and contributors
// SPDX-License-Identifier: GPL-3.0-or-later
// Additional permission for app stores: see EXCEPCION_TIENDAS.md

import 'dart:convert';
import 'dart:typed_data';

import 'package:path/path.dart' as rutas;
import 'package:sqflite/sqflite.dart';
import 'package:aeris/modelos/ejecucion.dart';
import 'package:aeris/modelos/ejemplos.dart';
import 'package:aeris/modelos/protocolo.dart';

/// Una ejecución guardada en el cuaderno, con su id y el protocolo que usó.
class EntradaCuaderno {
  final int id;
  final Ejecucion ejecucion;
  final Protocolo protocolo; // la versión exacta con la que se ejecutó

  const EntradaCuaderno({
    required this.id,
    required this.ejecucion,
    required this.protocolo,
  });
}

/// Lo que AeriS necesita guardar y leer, sin detalles de ninguna base de datos.
/// La app usa [AlmacenSqlite]; los tests de pantallas, una versión en memoria.
abstract class Almacen {
  Future<void> abrir();

  /// La versión más reciente de cada protocolo, ordenados por nombre.
  Future<List<Protocolo>> ultimasVersiones();

  /// Una versión concreta de un protocolo, o null si no existe.
  Future<Protocolo?> protocolo(String id, int version);

  /// Todas las versiones de todos los protocolos (para la copia de seguridad).
  Future<List<Protocolo>> todasLasVersiones();

  Future<void> guardarProtocolo(Protocolo protocolo);

  /// Guarda una ejecución nueva y devuelve su id.
  Future<int> crearEjecucion(Ejecucion ejecucion);

  Future<void> actualizarEjecucion(int id, Ejecucion ejecucion);

  /// Todas las ejecuciones, la más reciente primero.
  Future<List<EntradaCuaderno>> cuaderno();

  Future<void> borrarEjecucion(int id);

  /// Guarda una imagen (bytes de un JPEG o PNG). Si el id ya existe, la reemplaza.
  Future<void> guardarImagen(String id, Uint8List datos);

  /// Los bytes de una imagen, o null si no existe.
  Future<Uint8List?> imagen(String id);

  /// Los ids de todas las imágenes guardadas (sin leer sus bytes).
  Future<Set<String>> idsImagenes();

  Future<void> borrarImagenes(Iterable<String> ids);
}

/// Almacén que usa toda la app. Los tests lo sustituyen antes de empezar.
Almacen almacen = AlmacenSqlite(protocolosIniciales: protocolosDeEjemplo);

/// Base de datos SQLite en el propio dispositivo.
///
/// Columnas normales para lo que se busca u ordena; el resto, en JSON
/// en la columna 'contenido' (lección 11).
class AlmacenSqlite implements Almacen {
  final DatabaseFactory? _fabrica; // null = la normal del móvil; los tests usan otra
  final String? _ruta; // null = el archivo aeris.db en la carpeta de la app
  final List<Protocolo> protocolosIniciales; // se guardan al crear la base de datos
  final bool _instanciaUnica;
  Database? _db;

  AlmacenSqlite({
    DatabaseFactory? fabrica,
    String? ruta,
    this.protocolosIniciales = const [],
    bool instanciaUnica = true,
  })  : _fabrica = fabrica,
        _ruta = ruta,
        _instanciaUnica = instanciaUnica;

  Database get _bd {
    final db = _db;
    if (db == null) throw StateError('Llama a abrir() antes de usar el almacén.');
    return db;
  }

  @override
  Future<void> abrir() async {
    final fabrica = _fabrica ?? databaseFactory;
    final ruta = _ruta ?? rutas.join(await getDatabasesPath(), 'aeris.db');

    _db = await fabrica.openDatabase(
      ruta,
      options: OpenDatabaseOptions(
        // Versión del ESQUEMA (las tablas). Al subirla, onUpgrade adapta
        // las bases de datos que ya existen en los dispositivos.
        version: 2,
        singleInstance: _instanciaUnica,
        // SQLite no comprueba las claves foráneas si no se le pide
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: _crearTablas,
        onUpgrade: _migrar,
      ),
    );
  }

  /// Se ejecuta solo la primera vez, cuando el archivo de la base de datos no existe.
  Future<void> _crearTablas(Database db, int version) async {
    await db.execute('''
      CREATE TABLE protocolos (
        id        TEXT    NOT NULL,
        version   INTEGER NOT NULL,
        nombre    TEXT    NOT NULL,
        creado    TEXT    NOT NULL,
        contenido TEXT    NOT NULL,
        PRIMARY KEY (id, version)
      )
    ''');

    await db.execute('''
      CREATE TABLE ejecuciones (
        id                INTEGER PRIMARY KEY AUTOINCREMENT,
        protocolo_id      TEXT    NOT NULL,
        protocolo_version INTEGER NOT NULL,
        inicio            TEXT    NOT NULL,
        estado            TEXT    NOT NULL,
        contenido         TEXT    NOT NULL,
        FOREIGN KEY (protocolo_id, protocolo_version)
          REFERENCES protocolos (id, version)
      )
    ''');

    await _crearTablaImagenes(db);

    for (final protocolo in protocolosIniciales) {
      await db.insert('protocolos', _filaProtocolo(protocolo));
    }
  }

  /// Se ejecuta al abrir una base de datos creada con una versión anterior.
  /// Cada bloque lleva la base de datos un escalón más arriba, así que
  /// funciona desde cualquier versión antigua.
  Future<void> _migrar(Database db, int versionAntigua, int versionNueva) async {
    if (versionAntigua < 2) {
      await _crearTablaImagenes(db); // lección 18: imágenes en los pasos
    }
    // if (versionAntigua < 3) { ... } cuando haga falta
  }

  /// Las imágenes van en su propia tabla, una fila por imagen: Android no puede
  /// leer filas de más de ~2 MB, y un protocolo con varias fotos dentro de su
  /// JSON las superaría. El protocolo solo guarda el id de cada imagen.
  Future<void> _crearTablaImagenes(Database db) async {
    await db.execute('''
      CREATE TABLE imagenes (
        id    TEXT PRIMARY KEY,
        datos BLOB NOT NULL
      )
    ''');
  }

  Future<void> cerrar() async {
    await _db?.close();
    _db = null;
  }

  // ---------- Protocolos ----------

  Map<String, Object?> _filaProtocolo(Protocolo protocolo) => {
        'id': protocolo.id,
        'version': protocolo.version,
        'nombre': protocolo.nombre,
        'creado': protocolo.creado.toIso8601String(),
        'contenido': jsonEncode(protocolo.toJson()),
      };

  Protocolo _leerProtocolo(Object? contenido) =>
      Protocolo.fromJson(jsonDecode(contenido as String) as Map<String, dynamic>);

  @override
  Future<List<Protocolo>> ultimasVersiones() async {
    // Para cada protocolo, solo la fila cuya versión es la mayor de su id
    final filas = await _bd.rawQuery('''
      SELECT contenido
      FROM protocolos p
      WHERE version = (SELECT MAX(version) FROM protocolos WHERE id = p.id)
      ORDER BY nombre COLLATE NOCASE
    ''');
    return [for (final fila in filas) _leerProtocolo(fila['contenido'])];
  }

  @override
  Future<List<Protocolo>> todasLasVersiones() async {
    final filas = await _bd.query(
      'protocolos',
      columns: ['contenido'],
      orderBy: 'id, version',
    );
    return [for (final fila in filas) _leerProtocolo(fila['contenido'])];
  }

  @override
  Future<Protocolo?> protocolo(String id, int version) async {
    final filas = await _bd.query(
      'protocolos',
      columns: ['contenido'],
      where: 'id = ? AND version = ?',
      whereArgs: [id, version],
    );
    if (filas.isEmpty) return null;
    return _leerProtocolo(filas.first['contenido']);
  }

  @override
  Future<void> guardarProtocolo(Protocolo protocolo) async {
    await _bd.insert(
      'protocolos',
      _filaProtocolo(protocolo),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ---------- Ejecuciones ----------

  Map<String, Object?> _filaEjecucion(Ejecucion ejecucion) => {
        'protocolo_id': ejecucion.protocoloId,
        'protocolo_version': ejecucion.protocoloVersion,
        'inicio': ejecucion.inicio.toIso8601String(),
        'estado': ejecucion.estado.name,
        'contenido': jsonEncode(ejecucion.toJson()),
      };

  @override
  Future<int> crearEjecucion(Ejecucion ejecucion) {
    return _bd.insert('ejecuciones', _filaEjecucion(ejecucion));
  }

  @override
  Future<void> actualizarEjecucion(int id, Ejecucion ejecucion) async {
    await _bd.update(
      'ejecuciones',
      _filaEjecucion(ejecucion),
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<List<EntradaCuaderno>> cuaderno() async {
    // JOIN: cada ejecución junto al protocolo (versión exacta) que usó
    final filas = await _bd.rawQuery('''
      SELECT e.id, e.contenido, p.contenido AS protocolo
      FROM ejecuciones e
      JOIN protocolos p
        ON p.id = e.protocolo_id AND p.version = e.protocolo_version
      ORDER BY e.inicio DESC
    ''');
    return [
      for (final fila in filas)
        EntradaCuaderno(
          id: fila['id'] as int,
          ejecucion: Ejecucion.fromJson(
            jsonDecode(fila['contenido'] as String) as Map<String, dynamic>,
          ),
          protocolo: _leerProtocolo(fila['protocolo']),
        ),
    ];
  }

  @override
  Future<void> borrarEjecucion(int id) async {
    await _bd.delete('ejecuciones', where: 'id = ?', whereArgs: [id]);
  }

  // ---------- Imágenes ----------

  @override
  Future<void> guardarImagen(String id, Uint8List datos) async {
    await _bd.insert(
      'imagenes',
      {'id': id, 'datos': datos}, // BLOB: bytes tal cual, sin pasar a texto
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<Uint8List?> imagen(String id) async {
    final filas = await _bd.query('imagenes', columns: ['datos'], where: 'id = ?', whereArgs: [id]);
    if (filas.isEmpty) return null;
    return filas.first['datos'] as Uint8List;
  }

  @override
  Future<Set<String>> idsImagenes() async {
    // Solo la columna id: pedir también 'datos' cargaría todas las fotos en memoria
    final filas = await _bd.query('imagenes', columns: ['id']);
    return {for (final fila in filas) fila['id'] as String};
  }

  @override
  Future<void> borrarImagenes(Iterable<String> ids) async {
    // Una transacción: o se borran todas, o ninguna (si algo falla a medias)
    await _bd.transaction((txn) async {
      for (final id in ids) {
        await txn.delete('imagenes', where: 'id = ?', whereArgs: [id]);
      }
    });
  }
}
