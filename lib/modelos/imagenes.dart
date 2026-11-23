// AeriS - Laboratory protocol assistant
// Copyright (C) 2026 Alejandro Pascual Hernández and contributors
// SPDX-License-Identifier: GPL-3.0-or-later
// Additional permission for app stores: see EXCEPCION_TIENDAS.md

// Imágenes dentro del texto de un paso. En el Markdown se escriben así:
//
//   ![Montaje de la cubeta](imagen:img-1732370000000-42)
//
// "imagen:" no es una dirección de internet: es un "esquema" propio de AeriS
// que significa "busca este id en la tabla de imágenes del almacén".

import 'dart:math';

import 'package:aeris/modelos/paso.dart';
import 'package:aeris/modelos/protocolo.dart';

const esquemaImagen = 'imagen';

final _patronImagen = RegExp(r'!\[[^\]]*\]\(' '$esquemaImagen' r':([A-Za-z0-9_-]+)\)');
final _aleatorio = Random();

/// Un id que no se repite, ni en este dispositivo ni (en la práctica) en otro:
/// la hora en microsegundos más un número aleatorio.
String nuevoIdImagen() =>
    'img-${DateTime.now().microsecondsSinceEpoch}-${_aleatorio.nextInt(1 << 32)}';

/// El Markdown que muestra la imagen [id] con un [pie] de foto.
String marcaImagen(String id, {String pie = ''}) => '![$pie]($esquemaImagen:$id)';

/// Los ids de las imágenes que aparecen en un texto.
Set<String> imagenesDelTexto(String texto) => {
      for (final coincidencia in _patronImagen.allMatches(texto)) coincidencia.group(1)!,
    };

/// Las imágenes que usa un protocolo: las de todos sus pasos de instrucciones.
Set<String> imagenesDelProtocolo(Protocolo protocolo) => {
      for (final paso in protocolo.pasos)
        if (paso is PasoInstrucciones) ...imagenesDelTexto(paso.texto),
    };
