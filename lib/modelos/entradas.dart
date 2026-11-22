// AeriS - Laboratory protocol assistant
// Copyright (C) 2026 Alejandro Pascual Hernández and contributors
// SPDX-License-Identifier: GPL-3.0-or-later
// Additional permission for app stores: see EXCEPCION_TIENDAS.md

// Lectura y validación de los datos que se introducen al ejecutar un paso
// de cálculo. No sabe nada de pantallas: así se puede probar con tests.

import 'package:aeris/modelos/calculo.dart';
import 'package:aeris/modelos/paso.dart';

/// Convierte un texto en número aceptando coma o punto decimal ("2,5" o "2.5").
/// Devuelve null si el texto no es un número.
double? leerNumero(String? texto) {
  if (texto == null) return null;
  return double.tryParse(texto.trim().replaceAll(',', '.'));
}

/// Convierte un texto en número entero. Devuelve null si no lo es.
int? leerEntero(String? texto) {
  if (texto == null) return null;
  return int.tryParse(texto.trim());
}

/// Cantidades de los tubos que se preguntan ('Muestra' → 12).
/// Devuelve null si falta alguna o no es un entero mayor que cero.
Map<String, int>? cantidadesIntroducidas(PasoCalculo paso, Map<String, String> valores) {
  final cantidades = <String, int>{};
  for (final tipo in paso.tubosQueSePreguntan) {
    final cantidad = leerEntero(valores[tipo.nombre]);
    if (cantidad == null || cantidad <= 0) return null;
    cantidades[tipo.nombre] = cantidad;
  }
  return cantidades;
}

/// ¿Están rellenos los parámetros obligatorios, y los numéricos son números?
bool parametrosCompletos(PasoCalculo paso, Map<String, String> valores) {
  for (final parametro in paso.parametros) {
    final texto = valores[parametro.nombre]?.trim() ?? '';
    if (parametro.obligatorio && texto.isEmpty) return false;
    if (parametro.tipo == TipoParametro.numero &&
        texto.isNotEmpty &&
        leerNumero(texto) == null) {
      return false;
    }
  }
  return true;
}

/// ¿Se puede pasar al siguiente paso? Datos completos y cálculo válido.
bool calculoCompleto(PasoCalculo paso, Map<String, String> valores) {
  final cantidades = cantidadesIntroducidas(paso, valores);
  if (cantidades == null) return false;
  if (!parametrosCompletos(paso, valores)) return false;
  return paso.calcular(cantidades).esValido;
}

/// Texto de la etiqueta de un campo: "Concentración del DNA (ng/µL)".
String etiquetaParametro(ParametroEntrada parametro) {
  var etiqueta = parametro.nombre;
  if (parametro.unidad != null) etiqueta += ' (${parametro.unidad})';
  if (!parametro.obligatorio) etiqueta += ' · opcional';
  return etiqueta;
}
