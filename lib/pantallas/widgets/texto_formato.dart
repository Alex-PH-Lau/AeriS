// AeriS - Laboratory protocol assistant
// Copyright (C) 2026 Alejandro Pascual Hernández and contributors
// SPDX-License-Identifier: GPL-3.0-or-later
// Additional permission for app stores: see EXCEPCION_TIENDAS.md

import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:aeris/modelos/imagenes.dart';
import 'package:aeris/pantallas/widgets/imagen_guardada.dart';
import 'package:aeris/tema.dart';

/// Muestra el texto de un paso (Markdown) con su formato.
/// Se usa al ejecutar y en la vista previa del editor, así se ven igual.
class TextoConFormato extends StatelessWidget {
  final String texto;

  /// Estilo del texto normal; títulos y avisos se calculan a partir de él.
  final TextStyle? estilo;

  const TextoConFormato({super.key, required this.texto, this.estilo});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final colores = tema.colorScheme;
    // merge: coge tamaño (y altura de línea) de [estilo], y color y fuente del tema
    final base = tema.textTheme.bodyLarge!.merge(estilo);
    final tamano = base.fontSize ?? 20;

    final hoja = MarkdownStyleSheet.fromTheme(tema).copyWith(
      p: base,
      listBullet: base,
      h1: base.copyWith(fontSize: tamano * 1.3, fontWeight: FontWeight.bold),
      h2: base.copyWith(fontSize: tamano * 1.2, fontWeight: FontWeight.bold),
      h3: base.copyWith(fontSize: tamano * 1.1, fontWeight: FontWeight.bold),
      strong: const TextStyle(fontWeight: FontWeight.bold),
      em: const TextStyle(fontStyle: FontStyle.italic),
      blockSpacing: Espacio.medio,
      // "> Importante": recuadro de aviso, como el recordatorio de las alertas
      blockquote: base.copyWith(color: colores.onErrorContainer, fontWeight: FontWeight.w600),
      blockquotePadding: const EdgeInsets.all(Espacio.normal),
      blockquoteDecoration: BoxDecoration(
        color: colores.errorContainer,
        border: Border(left: BorderSide(color: colores.error, width: 6)),
      ),
    );

    return MarkdownBody(
      data: texto,
      styleSheet: hoja,
      // En Markdown estricto, un salto de línea suelto no cuenta. En AeriS sí:
      // así los textos escritos antes de tener formato se siguen viendo igual.
      softLineBreak: true,
      // Para cada ![pie](dirección) del texto, Markdown pregunta qué pintar
      imageBuilder: (Uri uri, String? titulo, String? pie) {
        if (uri.scheme == esquemaImagen) {
          return ImagenGuardada(id: uri.path, pie: pie ?? '');
        }
        // AeriS no descarga imágenes de internet: funciona sin conexión
        return Text('[Imagen externa: $uri]');
      },
    );
  }
}
