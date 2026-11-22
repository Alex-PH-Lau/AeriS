// AeriS - Laboratory protocol assistant
// Copyright (C) 2026 Alejandro Pascual Hernández and contributors
// SPDX-License-Identifier: GPL-3.0-or-later
// Additional permission for app stores: see EXCEPCION_TIENDAS.md

// Pequeñas ayudas para leer JSON. Todas las clases del modelo las usan.

/// En JSON, 25 y 25.0 son "números" sin más: al leerlos pueden llegar como
/// int o como double. Esto los convierte siempre a double.
double leerDouble(Object? valor) => (valor as num).toDouble();

/// Igual que [leerDouble], pero admite que el campo no exista.
double? leerDoubleOpcional(Object? valor) => (valor as num?)?.toDouble();

/// Lee una lista de objetos JSON y crea un objeto de Dart por cada uno.
/// Si la lista no existe, devuelve una lista vacía.
List<T> leerLista<T>(Object? valor, T Function(Map<String, dynamic> json) crear) {
  final lista = valor as List<dynamic>? ?? const [];
  return [
    for (final elemento in lista) crear(elemento as Map<String, dynamic>),
  ];
}
