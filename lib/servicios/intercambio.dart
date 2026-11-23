// AeriS - Laboratory protocol assistant
// Copyright (C) 2026 Alejandro Pascual Hernández and contributors
// SPDX-License-Identifier: GPL-3.0-or-later
// Additional permission for app stores: see EXCEPCION_TIENDAS.md

// Exportar e importar protocolos como archivos JSON para compartirlos.

import 'dart:convert';
import 'dart:typed_data';

import 'package:aeris/modelos/imagenes.dart';
import 'package:aeris/modelos/protocolo.dart';
import 'package:aeris/servicios/almacen.dart';

/// Versión más moderna del formato de archivo que esta app sabe leer y escribir.
///
/// - 1: el protocolo (o la copia) en JSON.
/// - 2: además, un mapa "imagenes" con las fotos de los pasos en base64.
///
/// Al subir este número, la app tiene que seguir leyendo TODAS las anteriores:
/// hay archivos antiguos en correos y carpetas que no se van a actualizar.
const versionFormato = 2;

/// Se escribe la versión MÍNIMA que hace falta: un protocolo sin imágenes
/// sale como versión 1, y así lo puede abrir alguien con una AeriS antigua.
int formatoNecesario(Map<String, Uint8List> imagenes) => imagenes.isEmpty ? 1 : 2;

/// Imágenes → texto. JSON no admite bytes, así que se pasan a base64:
/// letras, números, + y /, unos 4 caracteres por cada 3 bytes.
Map<String, String> codificarImagenes(Map<String, Uint8List> imagenes) => {
      for (final par in imagenes.entries) par.key: base64Encode(par.value),
    };

/// Texto → imágenes. Un archivo de versión 1 no tiene el campo: mapa vacío.
Map<String, Uint8List> leerImagenes(Object? json) {
  if (json == null) return {};
  if (json is! Map<String, dynamic>) {
    throw const FormatException('Las imágenes del archivo están dañadas.');
  }
  try {
    return {for (final par in json.entries) par.key: base64Decode(par.value as String)};
  } on FormatException {
    throw const FormatException('Una de las imágenes del archivo está dañada.');
  } on TypeError {
    throw const FormatException('Una de las imágenes del archivo está dañada.');
  }
}

/// Busca en [almacen] las imágenes que usan [protocolos]. Las que no estén
/// (no debería pasar) simplemente no se incluyen.
Future<Map<String, Uint8List>> imagenesDe(Iterable<Protocolo> protocolos, Almacen almacen) async {
  final ids = {for (final protocolo in protocolos) ...imagenesDelProtocolo(protocolo)};
  final resultado = <String, Uint8List>{};
  for (final id in ids) {
    final datos = await almacen.imagen(id);
    if (datos != null) resultado[id] = datos;
  }
  return resultado;
}

/// Comprueba que el número de formato existe y que esta app lo entiende.
void comprobarFormato(Object? formato, {required String que}) {
  if (formato is! int) {
    throw const FormatException('Al archivo le falta la versión del formato.');
  }
  if (formato > versionFormato) {
    throw FormatException(
      '$que se creó con una versión más nueva de AeriS '
      '(formato $formato). Actualiza la app para abrirlo.',
    );
  }
}

// ---------------------------------------------------------------------------

/// Convierte un protocolo en el texto de un archivo .json listo para compartir.
/// [imagenes]: las que usa el protocolo (ver [imagenesDe]).
String exportarProtocolo(Protocolo protocolo, {Map<String, Uint8List> imagenes = const {}}) {
  const codificador = JsonEncoder.withIndent('  '); // con sangría: legible por personas
  return codificador.convert({
    'aplicacion': 'AeriS',
    'formato': formatoNecesario(imagenes),
    'protocolo': protocolo.toJson(),
    if (imagenes.isNotEmpty) 'imagenes': codificarImagenes(imagenes),
  });
}

/// Lo que contiene un archivo de protocolo.
typedef ArchivoProtocolo = ({Protocolo protocolo, Map<String, Uint8List> imagenes});

/// Lee el texto de un archivo exportado (de cualquier versión del formato).
/// Si no es válido, lanza una [FormatException] con un mensaje para el usuario.
ArchivoProtocolo leerArchivoProtocolo(String texto) {
  final Object? datos;
  try {
    datos = jsonDecode(texto);
  } on FormatException {
    throw const FormatException('El archivo no es un JSON válido.');
  }

  if (datos is! Map<String, dynamic> || datos['aplicacion'] != 'AeriS') {
    throw const FormatException('El archivo no es un protocolo de AeriS.');
  }
  if (datos['tipo'] == 'copia') {
    throw const FormatException(
      'Este archivo es una copia de seguridad completa. '
      'Restáurala desde el cuaderno de laboratorio.',
    );
  }
  comprobarFormato(datos['formato'], que: 'Este protocolo');

  final Protocolo protocolo;
  try {
    protocolo = Protocolo.fromJson(datos['protocolo'] as Map<String, dynamic>);
  } on TypeError {
    // Un campo falta o tiene un tipo inesperado: el archivo está dañado
    throw const FormatException('El archivo está incompleto o dañado.');
  } on ArgumentError {
    // Un valor de enum que no existe, por ejemplo "modo": "inventado"
    throw const FormatException('El archivo contiene valores desconocidos.');
  }
  return (protocolo: protocolo, imagenes: leerImagenes(datos['imagenes']));
}

/// Atajo cuando solo interesa el protocolo.
Protocolo importarProtocolo(String texto) => leerArchivoProtocolo(texto).protocolo;

/// Nombre del archivo al exportar: "PCR estándar (V.1)" → "PCR_estandar_V1.json".
/// Sin tildes, espacios ni símbolos, para que funcione en cualquier sistema.
String nombreArchivo(Protocolo protocolo) {
  const sinTilde = {
    'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u', 'ü': 'u', 'ñ': 'n',
    'Á': 'A', 'É': 'E', 'Í': 'I', 'Ó': 'O', 'Ú': 'U', 'Ü': 'U', 'Ñ': 'N',
  };
  final limpio = protocolo.nombre
      .split('')
      .map((letra) => sinTilde[letra] ?? letra)
      .join()
      .replaceAll(RegExp(r'[^A-Za-z0-9]+'), '_') // cualquier otra cosa → _
      .replaceAll(RegExp(r'^_+|_+$'), ''); // sin _ al principio ni al final
  return '${limpio.isEmpty ? 'protocolo' : limpio}_V${protocolo.version}.json';
}

// ---------------------------------------------------------------------------

/// Qué ha pasado al importar.
enum ResultadoImportacion {
  /// No lo teníamos: se guarda tal cual, con su id y su versión.
  nuevo,

  /// Ya teníamos esa misma versión, idéntica: no se guarda nada.
  yaLoTenias,

  /// Teníamos otra cosa con el mismo id y número de versión (alguien lo
  /// editó por su cuenta): se guarda como una versión nueva para no pisar
  /// la nuestra, que puede tener ejecuciones en el cuaderno.
  nuevaVersion,
}

class Importacion {
  final Protocolo protocolo; // tal como queda guardado
  final ResultadoImportacion resultado;

  const Importacion(this.protocolo, this.resultado);

  String get mensaje => switch (resultado) {
        ResultadoImportacion.nuevo => 'Importado: ${protocolo.nombreCompleto}.',
        ResultadoImportacion.yaLoTenias =>
          'Ya tenías "${protocolo.nombreCompleto}", exactamente igual.',
        ResultadoImportacion.nuevaVersion =>
          'Tenías otra versión con el mismo número; '
              'se ha guardado como "${protocolo.nombreCompleto}".',
      };
}

/// Lee [texto] y lo guarda en [almacen] sin borrar nunca nada de lo que hay.
/// Lanza [FormatException] (con mensaje para el usuario) si no es válido.
Future<Importacion> importarEnAlmacen(String texto, Almacen almacen) async {
  final (:protocolo, :imagenes) = leerArchivoProtocolo(texto);
  final importado = protocolo;

  // Las imágenes primero: así el protocolo nunca apunta a una imagen que falta.
  // Sus ids no se repiten entre dispositivos, así que no pisan nada.
  for (final par in imagenes.entries) {
    await almacen.guardarImagen(par.key, par.value);
  }

  final existente = await almacen.protocolo(importado.id, importado.version);
  if (existente == null) {
    await almacen.guardarProtocolo(importado);
    return Importacion(importado, ResultadoImportacion.nuevo);
  }

  // Mismo id y versión: ¿es el mismo contenido? Se compara el JSON, que
  // incluye nombre, fecha de creación y todos los pasos.
  if (jsonEncode(existente.toJson()) == jsonEncode(importado.toJson())) {
    return Importacion(existente, ResultadoImportacion.yaLoTenias);
  }

  // Distinto: va detrás de la versión más alta que tengamos de ese protocolo
  final ultimas = await almacen.ultimasVersiones();
  final ultima = ultimas.firstWhere((p) => p.id == importado.id);
  final guardado = Protocolo(
    id: importado.id,
    nombre: importado.nombre,
    version: ultima.version + 1,
    creado: importado.creado,
    pasos: importado.pasos,
  );
  await almacen.guardarProtocolo(guardado);
  return Importacion(guardado, ResultadoImportacion.nuevaVersion);
}
