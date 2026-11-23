// AeriS - Laboratory protocol assistant
// Copyright (C) 2026 Alejandro Pascual Hernández and contributors
// SPDX-License-Identifier: GPL-3.0-or-later
// Additional permission for app stores: see EXCEPCION_TIENDAS.md

import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';

/// Lo que AeriS necesita para intercambiar archivos con el exterior,
/// sin detalles de ningún plugin. La app usa [ArchivosSistema]; los tests,
/// una versión falsa (igual que con los avisos y el almacén).
abstract class ServicioArchivos {
  /// Abre el menú de compartir del sistema (correo, Drive, mensajería…)
  /// con un archivo de texto llamado [nombreArchivo].
  ///
  /// [origen] es el rectángulo del botón pulsado: en iPad el menú sale
  /// como una burbuja que apunta ahí, y sin él la app se cierra con error.
  Future<void> compartirTexto({
    required String nombreArchivo,
    required String contenido,
    Rect? origen,
  });

  /// Texto del botón: en el móvil se comparte; en el ordenador se guarda.
  String get accionCompartir;

  /// Deja elegir un archivo y devuelve su texto, o null si se cancela.
  /// Lanza [FormatException] si el archivo no se puede leer como texto.
  Future<String?> elegirTexto();
}

/// Servicio que usa toda la app. Los tests lo sustituyen antes de empezar.
ServicioArchivos archivos = ArchivosSistema();

/// Un protocolo con fotos ocupa unos cientos de KB por foto; una copia de
/// seguridad, unos MB. Más de esto no es un archivo de AeriS, y leerlo entero
/// en memoria podría colgar la app.
const tamanoMaximo = 50 * 1024 * 1024; // 50 MB

class ArchivosSistema implements ServicioArchivos {
  @override
  String get accionCompartir => 'Compartir';

  @override
  Future<void> compartirTexto({
    required String nombreArchivo,
    required String contenido,
    Rect? origen,
  }) async {
    // El archivo se crea en memoria: no hace falta escribirlo antes en disco
    final archivo = XFile.fromData(utf8.encode(contenido), mimeType: 'application/json');
    await SharePlus.instance.share(ShareParams(
      files: [archivo],
      fileNameOverrides: [nombreArchivo], // el nombre de XFile.fromData se ignora
      subject: nombreArchivo, // asunto si se comparte por correo
      sharePositionOrigin: origen,
    ));
  }

  @override
  Future<String?> elegirTexto() async {
    // Sin filtro de extensión a propósito: en Android, ".json" no siempre
    // se reconoce y el archivo sale gris. Se comprueba después el contenido,
    // que es lo que de verdad importa.
    final archivo = await FilePicker.pickFile();
    if (archivo == null) return null; // el usuario ha cancelado

    final tamano = await archivo.length();
    if (tamano != null && tamano > tamanoMaximo) {
      throw const FormatException('El archivo es demasiado grande para ser un protocolo.');
    }

    final bytes = await archivo.readAsBytes();
    try {
      return utf8.decode(bytes);
    } on FormatException {
      throw const FormatException('El archivo no es de texto (¿es una imagen o un PDF?).');
    }
  }
}

/// En el ordenador no hay "menú de compartir" como en el móvil: lo natural es
/// el diálogo de "Guardar como". Elegir un archivo funciona igual (se hereda).
class ArchivosEscritorio extends ArchivosSistema {
  @override
  String get accionCompartir => 'Guardar archivo';

  @override
  Future<void> compartirTexto({
    required String nombreArchivo,
    required String contenido,
    Rect? origen,
  }) async {
    final bytes = utf8.encode(contenido);
    final destino = await FilePicker.saveFile(
      dialogTitle: 'Guardar como',
      fileName: nombreArchivo,
      bytes: bytes,
    );
    if (destino == null) return; // cancelado

    // Según la plataforma, el plugin escribe los bytes o solo devuelve la ruta
    // elegida. Si el archivo no está, lo escribimos nosotros.
    final archivo = File.fromUri(destino);
    if (!await archivo.exists() || await archivo.length() == 0) {
      await archivo.writeAsBytes(bytes, flush: true);
    }
  }
}
