// AeriS - Laboratory protocol assistant
// Copyright (C) 2026 Alejandro Pascual Hernández and contributors
// SPDX-License-Identifier: GPL-3.0-or-later
// Additional permission for app stores: see EXCEPCION_TIENDAS.md

// Botones de formato del editor. El texto de los pasos se guarda en Markdown:
//
//   **negrita**   _cursiva_   # Título   - lista   1. lista   > Importante
//
// Estas funciones son "puras": reciben el texto y la selección y devuelven
// el texto y la selección nuevos. No tocan ningún widget, así que se prueban
// con tests normales, sin pantalla.

import 'package:flutter/services.dart' show TextEditingValue, TextSelection;

/// Formatos de línea: se ponen al principio de cada línea seleccionada.
enum FormatoLinea {
  titulo(r'^#{1,6} '),
  lista(r'^[-*+] '),
  numerada(r'^\d+\. '),
  importante(r'^> ');

  const FormatoLinea(this._patron);
  final String _patron;

  RegExp get patron => RegExp(_patron);

  String prefijo(int numero) => switch (this) {
        FormatoLinea.titulo => '## ', // un nivel por debajo del título del paso
        FormatoLinea.lista => '- ',
        FormatoLinea.numerada => '$numero. ',
        FormatoLinea.importante => '> ',
      };
}

/// La selección, o el cursor al final si el campo nunca ha tenido el foco.
TextSelection _seleccion(TextEditingValue valor) => valor.selection.isValid
    ? valor.selection
    : TextSelection.collapsed(offset: valor.text.length);

/// Pone [marca] a ambos lados de la selección (`**así**`), o la quita si ya
/// estaba. Sin selección, deja el cursor entre las dos marcas para escribir.
TextEditingValue envolver(TextEditingValue valor, String marca) {
  final texto = valor.text;
  final seleccion = _seleccion(valor);
  final antes = seleccion.textBefore(texto);
  final dentro = seleccion.textInside(texto);
  final despues = seleccion.textAfter(texto);
  final n = marca.length;

  // Ya estaba envuelto: pulsar otra vez el botón lo quita
  if (antes.endsWith(marca) && despues.startsWith(marca)) {
    return TextEditingValue(
      text: antes.substring(0, antes.length - n) + dentro + despues.substring(n),
      selection: TextSelection(
        baseOffset: seleccion.start - n,
        extentOffset: seleccion.end - n,
      ),
    );
  }

  return TextEditingValue(
    text: '$antes$marca$dentro$marca$despues',
    // Lo que estaba seleccionado sigue seleccionado, ahora entre las marcas
    selection: TextSelection(
      baseOffset: seleccion.start + n,
      extentOffset: seleccion.end + n,
    ),
  );
}

/// Aplica [formato] a todas las líneas que toca la selección. Si ya lo
/// tenían todas, se lo quita (el botón funciona como un interruptor).
TextEditingValue formatearLineas(TextEditingValue valor, FormatoLinea formato) {
  final texto = valor.text;
  final seleccion = _seleccion(valor);

  // Desde el principio de la primera línea hasta el final de la última
  final inicio = seleccion.start == 0 ? 0 : texto.lastIndexOf('\n', seleccion.start - 1) + 1;
  var fin = texto.indexOf('\n', seleccion.end);
  if (fin == -1) fin = texto.length;

  final lineas = texto.substring(inicio, fin).split('\n');
  final patron = formato.patron;
  final quitar = lineas.every(patron.hasMatch);

  final nuevas = [
    for (var i = 0; i < lineas.length; i++)
      quitar
          ? lineas[i].replaceFirst(patron, '')
          : formato.prefijo(i + 1) + _sinFormatoDeLinea(lineas[i]),
  ];
  final bloque = nuevas.join('\n');

  return TextEditingValue(
    text: texto.substring(0, inicio) + bloque + texto.substring(fin),
    selection: TextSelection.collapsed(offset: inicio + bloque.length),
  );
}

/// Quita cualquier otro formato de línea: una lista no puede ser a la vez título.
String _sinFormatoDeLinea(String linea) {
  var resultado = linea;
  for (final formato in FormatoLinea.values) {
    resultado = resultado.replaceFirst(formato.patron, '');
  }
  return resultado;
}

/// Inserta [bloque] (por ejemplo, la marca de una imagen) en su propia línea,
/// donde está el cursor, y deja el cursor justo después.
TextEditingValue insertarBloque(TextEditingValue valor, String bloque) {
  final texto = valor.text;
  final seleccion = _seleccion(valor);
  final antes = seleccion.textBefore(texto);
  final despues = seleccion.textAfter(texto); // lo seleccionado se sustituye

  // Líneas en blanco alrededor: en Markdown, una imagen suelta es un bloque
  final separadorAntes = antes.isEmpty || antes.endsWith('\n\n')
      ? ''
      : (antes.endsWith('\n') ? '\n' : '\n\n');
  final separadorDespues = despues.startsWith('\n') ? '\n' : '\n\n';

  final nuevoAntes = '$antes$separadorAntes$bloque$separadorDespues';
  return TextEditingValue(
    text: nuevoAntes + despues,
    selection: TextSelection.collapsed(offset: nuevoAntes.length),
  );
}
