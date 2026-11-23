// AeriS - Laboratory protocol assistant
// Copyright (C) 2026 Alejandro Pascual Hernández and contributors
// SPDX-License-Identifier: GPL-3.0-or-later
// Additional permission for app stores: see EXCEPCION_TIENDAS.md

import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

/// Reduce una imagen a [ladoMaximo] píxeles de lado como mucho y la guarda
/// como JPEG. En el móvil esto lo hace image_picker; en el ordenador, no.
///
/// Descomprimir y recomprimir una foto de 12 megapíxeles tarda un segundo o
/// más. Si se hiciera en el hilo principal, la app se congelaría ese tiempo
/// (ni animaciones ni toques). [Isolate.run] lo hace en otro hilo y espera.
Future<Uint8List> reducirImagen(
  Uint8List datos, {
  int ladoMaximo = 1600,
  int calidad = 80,
}) {
  return Isolate.run(() => _reducir(datos, ladoMaximo, calidad));
}

/// La parte pesada. Es una función normal, sin nada de Flutter: así se puede
/// ejecutar en otro isolate (que no comparte memoria con el principal).
Uint8List _reducir(Uint8List datos, int ladoMaximo, int calidad) {
  img.Image? original;
  try {
    original = img.decodeImage(datos);
  } catch (_) {
    original = null; // algunos archivos raros hacen fallar al decodificador
  }
  if (original == null) {
    throw const FormatException('El archivo no es una imagen que AeriS sepa leer.');
  }
  // Las fotos de cámara guardan "gírame 90°" aparte (EXIF): se aplica ya,
  // porque al recomprimir esa indicación se perdería
  final derecha = img.bakeOrientation(original);

  final lado = max(derecha.width, derecha.height);
  final pequena = lado <= ladoMaximo && datos.length < 1024 * 1024;
  if (pequena) return datos; // ya es razonable: tal cual, sin perder calidad

  final reducida = lado <= ladoMaximo
      ? derecha
      : img.copyResize(
          derecha,
          width: derecha.width >= derecha.height ? ladoMaximo : null,
          height: derecha.height > derecha.width ? ladoMaximo : null, // la otra, proporcional
          interpolation: img.Interpolation.average, // la mejor para reducir
        );
  return img.encodeJpg(reducida, quality: calidad);
}
