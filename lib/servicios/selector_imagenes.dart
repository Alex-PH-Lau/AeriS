// AeriS - Laboratory protocol assistant
// Copyright (C) 2026 Alejandro Pascual Hernández and contributors
// SPDX-License-Identifier: GPL-3.0-or-later
// Additional permission for app stores: see EXCEPCION_TIENDAS.md

import 'dart:typed_data';

import 'package:image_picker/image_picker.dart';
import 'package:aeris/servicios/reducir_imagen.dart';

enum OrigenImagen {
  camara('Hacer una foto'),
  galeria('Elegir de la galería');

  const OrigenImagen(this.etiqueta);
  final String etiqueta;
}

/// Lo que AeriS necesita para conseguir una imagen. Mismo patrón que avisos,
/// almacén y archivos: la app usa [SelectorImagenesSistema]; los tests, uno falso.
abstract class SelectorImagenes {
  /// De dónde se pueden sacar imágenes en este dispositivo.
  List<OrigenImagen> get origenes;

  /// Devuelve la imagen ya reducida, o null si el usuario cancela.
  Future<Uint8List?> elegir(OrigenImagen origen);
}

SelectorImagenes selectorImagenes = SelectorImagenesSistema();

/// Lado máximo en píxeles. Una foto de móvil tiene 4000 o más; para ver un
/// montaje o un gel en una tablet sobra con esto, y ocupa 10-20 veces menos.
const ladoMaximo = 1600.0;

/// Calidad JPEG (0-100). Con 80 no se notan diferencias a simple vista.
const calidad = 80;

class SelectorImagenesSistema implements SelectorImagenes {
  final _picker = ImagePicker();

  @override
  List<OrigenImagen> get origenes => OrigenImagen.values;

  @override
  Future<Uint8List?> elegir(OrigenImagen origen) async {
    // El propio plugin reduce y recomprime la imagen antes de devolverla
    final archivo = await _picker.pickImage(
      source: origen == OrigenImagen.camara ? ImageSource.camera : ImageSource.gallery,
      maxWidth: ladoMaximo,
      maxHeight: ladoMaximo,
      imageQuality: calidad,
    );
    if (archivo == null) return null;
    return archivo.readAsBytes();
  }
}

/// En el ordenador no hay cámara (el plugin no la soporta) ni reducción
/// automática: solo galería (el explorador de archivos), y reducimos nosotros.
class SelectorImagenesEscritorio implements SelectorImagenes {
  final _picker = ImagePicker();

  @override
  List<OrigenImagen> get origenes => const [OrigenImagen.galeria];

  @override
  Future<Uint8List?> elegir(OrigenImagen origen) async {
    final archivo = await _picker.pickImage(source: ImageSource.gallery);
    if (archivo == null) return null;
    return reducirImagen(
      await archivo.readAsBytes(),
      ladoMaximo: ladoMaximo.round(),
      calidad: calidad,
    );
  }
}
