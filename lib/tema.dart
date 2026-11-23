// AeriS - Laboratory protocol assistant
// Copyright (C) 2026 Alejandro Pascual Hernández and contributors
// SPDX-License-Identifier: GPL-3.0-or-later
// Additional permission for app stores: see EXCEPCION_TIENDAS.md

import 'package:flutter/material.dart';

/// Todo el aspecto de AeriS sale de aquí. Para cambiar la estética de la app
/// (colores, tamaños, botones…) se toca este archivo y no las pantallas.

/// Color del que Material genera toda la paleta (claro y oscuro).
const colorSemilla = Color.fromARGB(255, 46, 0, 195);

/// Separaciones entre elementos. Usar siempre estas, no números sueltos.
abstract final class Espacio {
  static const minimo = 4.0;
  static const pequeno = 8.0;
  static const medio = 12.0;
  static const normal = 16.0;
  static const grande = 24.0;
  static const extra = 32.0;
}

/// Tamaños pensados para usar la app con guantes.
abstract final class Medida {
  /// Alto mínimo de cualquier botón con texto.
  static const boton = 64.0;

  /// Alto mínimo de una fila de lista que se puede tocar.
  static const fila = 72.0;

  /// Botón principal al pie de una pantalla ("Guardar paso", "Siguiente").
  static const botonPrincipal = 72.0;

  /// Botones de la pantalla de inicio y "Anterior"/"Siguiente" al ejecutar.
  static const botonGrande = 96.0;

  /// Lado mínimo de un botón que solo tiene icono.
  static const botonIcono = 56.0;

  static const icono = 28.0;
  static const iconoGrande = 36.0;

  /// Icono que encabeza un diálogo o una pantalla vacía.
  static const iconoAviso = 56.0;

  /// Icono de los avisos que bloquean la pantalla (alerta, fin del temporizador).
  static const iconoAlerta = 72.0;

  /// A partir de este ancho caben dos paneles (lista y detalle) uno al lado
  /// del otro: tablet en horizontal o ventana de ordenador.
  static const anchoDosPaneles = 840.0;

  /// Ancho máximo de un formulario o de una columna de texto: en una tablet
  /// o un PC, las líneas larguísimas cansan la vista.
  static const anchoLectura = 600.0;
}

/// Tamaños de letra. La app se lee a cierta distancia, con las manos ocupadas,
/// así que todo es algo más grande que en una app normal.
const _textos = TextTheme(
  headlineMedium: TextStyle(fontSize: 28),
  headlineSmall: TextStyle(fontSize: 26),
  titleLarge: TextStyle(fontSize: 22),
  titleMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
  bodyLarge: TextStyle(fontSize: 20), // lo que se escribe en los campos, filas de listas
  bodyMedium: TextStyle(fontSize: 18), // texto normal (Text sin estilo)
  bodySmall: TextStyle(fontSize: 16), // ayudas debajo de los campos
  labelLarge: TextStyle(fontSize: 20), // texto de los botones
);

/// Estilos especiales que no encajan en ningún papel del TextTheme.
abstract final class EstiloTexto {
  /// Texto de un paso durante la ejecución: se lee desde la poyata.
  static const paso = TextStyle(fontSize: 26, height: 1.4);

  /// Cuenta atrás del temporizador.
  static const reloj = TextStyle(
    fontSize: 72,
    fontWeight: FontWeight.bold,
    // Cifras del mismo ancho: el número no "baila" al cambiar
    fontFeatures: [FontFeature.tabularFigures()],
  );
}

/// Tema de la app. Se construye en dos fases: primero colores y letras,
/// después los componentes, que reutilizan los estilos de la primera fase.
ThemeData temaAeris({Brightness brillo = Brightness.light}) {
  final base = ThemeData(
    colorScheme: ColorScheme.fromSeed(seedColor: colorSemilla, brightness: brillo),
    textTheme: _textos,
  );
  final colores = base.colorScheme;
  final textos = base.textTheme;

  const tamanoBoton = Size(120, Medida.boton);
  const rellenoBoton = EdgeInsets.symmetric(horizontal: Espacio.grande);

  return base.copyWith(
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: tamanoBoton,
        padding: rellenoBoton,
        iconSize: Medida.icono,
        textStyle: textos.labelLarge,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: tamanoBoton,
        padding: rellenoBoton,
        iconSize: Medida.icono,
        textStyle: textos.labelLarge,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        minimumSize: tamanoBoton,
        iconSize: Medida.icono,
        textStyle: textos.labelLarge,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(
        iconSize: Medida.icono,
        minimumSize: const Size.square(Medida.botonIcono),
      ),
    ),
    inputDecorationTheme: const InputDecorationThemeData(
      border: OutlineInputBorder(),
    ),
    listTileTheme: ListTileThemeData(
      minTileHeight: Medida.fila,
      titleTextStyle: textos.bodyLarge, // ListTile pone el color según el estado
    ),
    dialogTheme: DialogThemeData(
      contentTextStyle: textos.bodyLarge?.copyWith(color: colores.onSurfaceVariant),
    ),
    snackBarTheme: SnackBarThemeData(
      contentTextStyle: textos.bodyLarge?.copyWith(color: colores.onInverseSurface),
    ),
  );
}
