// AeriS - Laboratory protocol assistant
// Copyright (C) 2026 Alejandro Pascual Hernández and contributors
// SPDX-License-Identifier: GPL-3.0-or-later
// Additional permission for app stores: see EXCEPCION_TIENDAS.md

// Exportar e importar protocolos como archivos JSON para compartirlos.

import 'dart:convert';

import 'package:aeris/modelos/protocolo.dart';

/// Versión del formato de archivo. Si algún día cambia la estructura del JSON
/// de forma incompatible, se sube este número.
const versionFormato = 1;

/// Convierte un protocolo en el texto de un archivo .json listo para compartir.
String exportarProtocolo(Protocolo protocolo) {
  const codificador = JsonEncoder.withIndent('  '); // con sangría: legible por personas
  return codificador.convert({
    'aplicacion': 'AeriS',
    'formato': versionFormato,
    'protocolo': protocolo.toJson(),
  });
}

/// Lee el texto de un archivo exportado. Si no es válido, lanza una
/// [FormatException] con un mensaje que se puede mostrar al usuario.
Protocolo importarProtocolo(String texto) {
  final Object? datos;
  try {
    datos = jsonDecode(texto);
  } on FormatException {
    throw const FormatException('El archivo no es un JSON válido.');
  }

  if (datos is! Map<String, dynamic> || datos['aplicacion'] != 'AeriS') {
    throw const FormatException('El archivo no es un protocolo de AeriS.');
  }

  final formato = datos['formato'];
  if (formato is! int) {
    throw const FormatException('Al archivo le falta la versión del formato.');
  }
  if (formato > versionFormato) {
    throw FormatException(
      'Este protocolo se creó con una versión más nueva de AeriS '
      '(formato $formato). Actualiza la app para abrirlo.',
    );
  }

  try {
    return Protocolo.fromJson(datos['protocolo'] as Map<String, dynamic>);
  } on TypeError {
    // Un campo falta o tiene un tipo inesperado: el archivo está dañado
    throw const FormatException('El archivo está incompleto o dañado.');
  } on ArgumentError {
    // Un valor de enum que no existe, por ejemplo "modo": "inventado"
    throw const FormatException('El archivo contiene valores desconocidos.');
  }
}
