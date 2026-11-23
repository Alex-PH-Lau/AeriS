// AeriS - Laboratory protocol assistant
// Copyright (C) 2026 Alejandro Pascual Hernández and contributors
// SPDX-License-Identifier: GPL-3.0-or-later
// Additional permission for app stores: see EXCEPCION_TIENDAS.md

// Copia de seguridad: todos los protocolos (todas sus versiones) y todo el
// cuaderno en un único archivo JSON. Restaurar SOLO AÑADE: nunca borra ni
// sobrescribe nada de lo que ya hay en el dispositivo.

import 'dart:convert';
import 'dart:typed_data';

import 'package:aeris/modelos/ejecucion.dart';
import 'package:aeris/modelos/json.dart';
import 'package:aeris/modelos/protocolo.dart';
import 'package:aeris/servicios/almacen.dart';
import 'package:aeris/servicios/intercambio.dart';

/// Marca que distingue una copia de un protocolo suelto, que no la lleva.
const tipoCopia = 'copia';

/// Nombre del archivo: "AeriS_copia_2026-11-23.json".
String nombreArchivoCopia(DateTime fecha) {
  String dos(int numero) => numero.toString().padLeft(2, '0');
  return 'AeriS_copia_${fecha.year}-${dos(fecha.month)}-${dos(fecha.day)}.json';
}

/// Genera el texto de la copia con todo lo que hay en [almacen].
Future<String> crearCopia(Almacen almacen, {DateTime? ahora}) async {
  final protocolos = await almacen.todasLasVersiones();
  final cuaderno = await almacen.cuaderno();
  final imagenes = await imagenesDe(protocolos, almacen);

  const codificador = JsonEncoder.withIndent('  ');
  return codificador.convert({
    'aplicacion': 'AeriS',
    'tipo': tipoCopia,
    'formato': formatoNecesario(imagenes),
    'creada': (ahora ?? DateTime.now()).toIso8601String(),
    'protocolos': [for (final protocolo in protocolos) protocolo.toJson()],
    // Las más antiguas primero: al restaurar se crean en orden cronológico
    'ejecuciones': [for (final entrada in cuaderno.reversed) entrada.ejecucion.toJson()],
    if (imagenes.isNotEmpty) 'imagenes': codificarImagenes(imagenes),
  });
}

/// Lo que ha pasado al restaurar, para contárselo al usuario.
class ResumenRestauracion {
  int protocolosNuevos = 0;
  int protocolosRepetidos = 0; // ya estaban, idénticos

  /// Ya había algo distinto con el mismo id y versión. Se deja el del
  /// dispositivo, y las ejecuciones de esa versión de la copia no se
  /// restauran, porque quedarían ligadas a un protocolo que no es el suyo.
  int protocolosEnConflicto = 0;

  int ejecucionesNuevas = 0;
  int ejecucionesRepetidas = 0;

  /// Por un conflicto o porque su protocolo no está en ningún sitio.
  int ejecucionesOmitidas = 0;

  bool get sinCambios => protocolosNuevos == 0 && ejecucionesNuevas == 0;

  /// Líneas para mostrar en el diálogo; solo las que tienen algo que contar.
  List<String> get lineas => [
        if (protocolosNuevos > 0) 'Versiones de protocolos añadidas: $protocolosNuevos',
        if (ejecucionesNuevas > 0) 'Ejecuciones añadidas al cuaderno: $ejecucionesNuevas',
        if (protocolosRepetidos + ejecucionesRepetidas > 0)
          'Ya estaban y no se han duplicado: '
              '${protocolosRepetidos + ejecucionesRepetidas}',
        if (protocolosEnConflicto > 0)
          'Protocolos que no coinciden con los del dispositivo '
              '(se ha mantenido el del dispositivo): $protocolosEnConflicto',
        if (ejecucionesOmitidas > 0)
          'Ejecuciones no restauradas (sin su protocolo exacto): $ejecucionesOmitidas',
      ];
}

/// Restaura una copia en [almacen]. Lanza [FormatException] con un mensaje
/// para el usuario si el archivo no es válido; en ese caso no se guarda nada.
Future<ResumenRestauracion> restaurarCopia(String texto, Almacen almacen) async {
  // 1. Leer y comprobar TODO antes de escribir nada: si el archivo está
  //    dañado por la mitad, no queremos haber restaurado solo una parte.
  final (protocolos, ejecuciones, imagenes) = _leerCopia(texto);

  final resumen = ResumenRestauracion();

  // Las imágenes, antes que los protocolos que las usan
  for (final par in imagenes.entries) {
    if (await almacen.imagen(par.key) == null) {
      await almacen.guardarImagen(par.key, par.value);
    }
  }
  final enConflicto = <String>{}; // "id@version" que no se deben usar

  // 2. Protocolos: los que faltan se añaden; los que hay, no se tocan.
  for (final protocolo in protocolos) {
    final existente = await almacen.protocolo(protocolo.id, protocolo.version);
    if (existente == null) {
      await almacen.guardarProtocolo(protocolo);
      resumen.protocolosNuevos++;
    } else if (_mismoJson(existente.toJson(), protocolo.toJson())) {
      resumen.protocolosRepetidos++;
    } else {
      resumen.protocolosEnConflicto++;
      enConflicto.add('${protocolo.id}@${protocolo.version}');
    }
  }

  // 3. Ejecuciones: se añaden las que no estén ya, idénticas, en el cuaderno.
  final yaEnCuaderno = {
    for (final entrada in await almacen.cuaderno()) jsonEncode(entrada.ejecucion.toJson()),
  };
  for (final ejecucion in ejecuciones) {
    if (enConflicto.contains('${ejecucion.protocoloId}@${ejecucion.protocoloVersion}')) {
      resumen.ejecucionesOmitidas++;
      continue;
    }
    if (await almacen.protocolo(ejecucion.protocoloId, ejecucion.protocoloVersion) == null) {
      // Su protocolo no viene en la copia ni está en el dispositivo
      resumen.ejecucionesOmitidas++;
      continue;
    }
    final huella = jsonEncode(ejecucion.toJson());
    if (yaEnCuaderno.contains(huella)) {
      resumen.ejecucionesRepetidas++;
      continue;
    }
    await almacen.crearEjecucion(ejecucion);
    yaEnCuaderno.add(huella); // por si la copia trae la misma dos veces
    resumen.ejecucionesNuevas++;
  }
  return resumen;
}

bool _mismoJson(Map<String, dynamic> a, Map<String, dynamic> b) => jsonEncode(a) == jsonEncode(b);

/// Devuelve tres cosas a la vez con un *record*: (protocolos, ejecuciones, imágenes).
(List<Protocolo>, List<Ejecucion>, Map<String, Uint8List>) _leerCopia(String texto) {
  final Object? datos;
  try {
    datos = jsonDecode(texto);
  } on FormatException {
    throw const FormatException('El archivo no es un JSON válido.');
  }

  if (datos is! Map<String, dynamic> || datos['aplicacion'] != 'AeriS') {
    throw const FormatException('El archivo no es de AeriS.');
  }
  if (datos['tipo'] != tipoCopia) {
    throw const FormatException(
      'Este archivo es un protocolo suelto, no una copia de seguridad. '
      'Impórtalo desde "Mis protocolos".',
    );
  }
  comprobarFormato(datos['formato'], que: 'Esta copia');

  final List<Protocolo> protocolos;
  final List<Ejecucion> ejecuciones;
  try {
    protocolos = leerLista(datos['protocolos'], Protocolo.fromJson);
    ejecuciones = leerLista(datos['ejecuciones'], Ejecucion.fromJson);
  } on TypeError {
    throw const FormatException('La copia está incompleta o dañada.');
  } on ArgumentError {
    throw const FormatException('La copia contiene valores desconocidos.');
  } on FormatException {
    throw const FormatException('La copia contiene una fecha que no se entiende.');
  }

  // leerImagenes ya lanza su propio mensaje si alguna está dañada
  return (protocolos, ejecuciones, leerImagenes(datos['imagenes']));
}
