// AeriS - Laboratory protocol assistant
// Copyright (C) 2026 Alejandro Pascual Hernández and contributors
// SPDX-License-Identifier: GPL-3.0-or-later
// Additional permission for app stores: see EXCEPCION_TIENDAS.md

import 'package:aeris/modelos/paso.dart';

class Protocolo {
  final String id; // común a todas las versiones del mismo protocolo
  final String nombre;
  final int version;
  final DateTime creado;
  final List<Paso> pasos;

  const Protocolo({
    required this.id,
    required this.nombre,
    required this.version,
    required this.creado,
    required this.pasos,
  });

  String get nombreCompleto => '$nombre (V.$version)';
  int get numeroPasos => pasos.length;

  /// Crea una versión nueva sin modificar la actual.
  Protocolo nuevaVersion({String? nombre, List<Paso>? pasos}) {
    return Protocolo(
      id: id,
      nombre: nombre ?? this.nombre,
      version: version + 1,
      creado: DateTime.now(),
      pasos: pasos ?? this.pasos,
    );
  }
}
