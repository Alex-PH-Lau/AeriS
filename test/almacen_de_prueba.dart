// AeriS - Laboratory protocol assistant
// Copyright (C) 2026 Alejandro Pascual Hernández and contributors
// SPDX-License-Identifier: GPL-3.0-or-later
// Additional permission for app stores: see EXCEPCION_TIENDAS.md

import 'dart:typed_data';

import 'package:aeris/modelos/ejecucion.dart';
import 'package:aeris/modelos/protocolo.dart';
import 'package:aeris/servicios/almacen.dart';

/// Almacén en memoria para los tests de pantallas: se comporta como la base
/// de datos, pero sin archivo ni SQL. (El SQL de verdad se prueba aparte,
/// en almacen_sqlite_test.dart.)
class AlmacenEnMemoria implements Almacen {
  final List<Protocolo> _protocolos = [];
  final Map<int, Ejecucion> ejecuciones = {};
  final Map<String, Uint8List> imagenes = {};
  int _siguienteId = 1;

  AlmacenEnMemoria([List<Protocolo> iniciales = const []]) {
    _protocolos.addAll(iniciales);
  }

  @override
  Future<void> abrir() async {}

  @override
  Future<List<Protocolo>> ultimasVersiones() async {
    final ultimas = <String, Protocolo>{};
    for (final protocolo in _protocolos) {
      final actual = ultimas[protocolo.id];
      if (actual == null || protocolo.version > actual.version) {
        ultimas[protocolo.id] = protocolo;
      }
    }
    return ultimas.values.toList()..sort((a, b) => a.nombre.compareTo(b.nombre));
  }

  @override
  Future<List<Protocolo>> todasLasVersiones() async => List.of(_protocolos);

  @override
  Future<Protocolo?> protocolo(String id, int version) async {
    for (final protocolo in _protocolos) {
      if (protocolo.id == id && protocolo.version == version) return protocolo;
    }
    return null;
  }

  @override
  Future<void> guardarProtocolo(Protocolo protocolo) async {
    _protocolos.removeWhere((p) => p.id == protocolo.id && p.version == protocolo.version);
    _protocolos.add(protocolo);
  }

  @override
  Future<int> crearEjecucion(Ejecucion ejecucion) async {
    final id = _siguienteId++;
    ejecuciones[id] = ejecucion;
    return id;
  }

  @override
  Future<void> actualizarEjecucion(int id, Ejecucion ejecucion) async {
    ejecuciones[id] = ejecucion;
  }

  @override
  Future<List<EntradaCuaderno>> cuaderno() async {
    final entradas = <EntradaCuaderno>[];
    for (final par in ejecuciones.entries) {
      final usado = await protocolo(par.value.protocoloId, par.value.protocoloVersion);
      if (usado == null) continue;
      entradas.add(EntradaCuaderno(id: par.key, ejecucion: par.value, protocolo: usado));
    }
    entradas.sort((a, b) => b.ejecucion.inicio.compareTo(a.ejecucion.inicio));
    return entradas;
  }

  @override
  Future<void> borrarEjecucion(int id) async {
    ejecuciones.remove(id);
  }

  @override
  Future<void> guardarImagen(String id, Uint8List datos) async {
    imagenes[id] = datos;
  }

  @override
  Future<Uint8List?> imagen(String id) async => imagenes[id];

  @override
  Future<Set<String>> idsImagenes() async => imagenes.keys.toSet();

  @override
  Future<void> borrarImagenes(Iterable<String> ids) async {
    ids.forEach(imagenes.remove);
  }
}
