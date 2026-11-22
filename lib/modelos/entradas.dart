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

/// Filas con las que empieza la tabla de muestras: las de los tipos con DNA
/// y cantidad fija, como el control positivo.
List<Muestra> muestrasIniciales(PasoCalculo paso) {
  final filas = <Muestra>[];
  for (final tipo in paso.tiposTubo) {
    final cantidad = tipo.cantidadFija;
    if (tipo.conDna && cantidad != null) {
      for (var i = 0; i < cantidad; i++) {
        filas.add(Muestra(
          id: '${tipo.nombre}-$i',
          tipo: tipo.nombre,
          codigo: cantidad == 1 ? tipo.nombre : '${tipo.nombre} ${i + 1}',
        ));
      }
    }
  }
  return filas;
}

/// Primer problema de la tabla de muestras, o null si está todo bien.
String? problemaMuestras(PasoCalculo paso, List<Muestra> muestras) {
  // Al menos una fila de cada tipo que añade el usuario
  for (final tipo in paso.tiposTubo) {
    if (tipo.filasLibres && !muestras.any((m) => m.tipo == tipo.nombre)) {
      return 'Añade al menos una ${tipo.nombre.toLowerCase()}.';
    }
  }

  // Códigos obligatorios y sin repetir
  final vistos = <String>{};
  for (final muestra in muestras) {
    final codigo = muestra.codigo.trim();
    if (codigo.isEmpty) return 'Todas las muestras necesitan un código.';
    if (!vistos.add(codigo)) return 'Hay códigos repetidos: $codigo.';
  }

  // Cada muestra tiene que poder pipetearse
  for (final resultado in paso.calcular(muestras).muestras) {
    if (resultado.listo) continue;
    final codigo = resultado.muestra.codigo;
    if (resultado.estado == EstadoMuestra.sinConcentracion) {
      return 'Falta la concentración de $codigo.';
    }
    return '$codigo está demasiado concentrada: diluye más de 1:100 y vuelve a medir.';
  }
  return null;
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

/// Primer motivo por el que no se puede avanzar, o null si se puede.
String? problemaCalculo(
  PasoCalculo paso,
  List<Muestra> muestras,
  Map<String, String> valores,
) {
  final problema = problemaMuestras(paso, muestras);
  if (problema != null) return problema;
  if (!parametrosCompletos(paso, valores)) return 'Rellena los datos obligatorios.';
  if (!paso.calcular(muestras).esValido) {
    return 'Los reactivos no caben en el volumen de reacción. Revisa el protocolo.';
  }
  return null;
}

/// ¿Se puede pasar al siguiente paso?
bool calculoCompleto(
  PasoCalculo paso,
  List<Muestra> muestras,
  Map<String, String> valores,
) =>
    problemaCalculo(paso, muestras, valores) == null;

/// Texto de la etiqueta de un campo: "Lote de la Taq · opcional".
String etiquetaParametro(ParametroEntrada parametro) {
  var etiqueta = parametro.nombre;
  if (parametro.unidad != null) etiqueta += ' (${parametro.unidad})';
  if (!parametro.obligatorio) etiqueta += ' · opcional';
  return etiqueta;
}
