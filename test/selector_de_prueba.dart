// AeriS - Laboratory protocol assistant
// Copyright (C) 2026 Alejandro Pascual Hernández and contributors
// SPDX-License-Identifier: GPL-3.0-or-later
// Additional permission for app stores: see EXCEPCION_TIENDAS.md

import 'dart:convert';
import 'dart:typed_data';

import 'package:aeris/servicios/selector_imagenes.dart';

/// Un PNG de verdad de 1×1 píxel: lo más pequeño que Flutter sabe pintar.
final pngDePrueba = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=',
);

/// Selector falso: no abre la cámara; devuelve [siguiente] y apunta el origen.
class SelectorDePrueba implements SelectorImagenes {
  Uint8List? siguiente;
  final List<OrigenImagen> pedidos = [];

  SelectorDePrueba([this.siguiente]);

  @override
  List<OrigenImagen> origenes = OrigenImagen.values;

  @override
  Future<Uint8List?> elegir(OrigenImagen origen) async {
    pedidos.add(origen);
    return siguiente;
  }
}
