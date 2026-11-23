// AeriS - Laboratory protocol assistant
// Copyright (C) 2026 Alejandro Pascual Hernández and contributors
// SPDX-License-Identifier: GPL-3.0-or-later
// Additional permission for app stores: see EXCEPCION_TIENDAS.md

import 'dart:ui';

import 'package:aeris/servicios/archivos.dart';

/// Un archivo que la app ha intentado compartir.
class Compartido {
  final String nombreArchivo;
  final String contenido;
  final Rect? origen;
  const Compartido(this.nombreArchivo, this.contenido, this.origen);
}

/// Versión falsa para los tests: no abre menús del sistema.
/// Apunta lo que se comparte y "elige" el texto que le digamos.
class ArchivosDePrueba implements ServicioArchivos {
  final List<Compartido> compartidos = [];

  @override
  String get accionCompartir => 'Compartir';

  /// Lo que devolverá el próximo elegirTexto(); null = el usuario cancela.
  String? textoParaElegir;

  @override
  Future<void> compartirTexto({
    required String nombreArchivo,
    required String contenido,
    Rect? origen,
  }) async {
    compartidos.add(Compartido(nombreArchivo, contenido, origen));
  }

  @override
  Future<String?> elegirTexto() async => textoParaElegir;
}
