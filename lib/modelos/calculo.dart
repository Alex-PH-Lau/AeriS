// AeriS - Laboratory protocol assistant
// Copyright (C) 2026 Alejandro Pascual Hernández and contributors
// SPDX-License-Identifier: GPL-3.0-or-later
// Additional permission for app stores: see EXCEPCION_TIENDAS.md

/// Muestra un número sin decimales sobrantes: 1.0 -> "1", 0.25 -> "0.25".
String formatearNumero(double numero) {
  if (numero == numero.roundToDouble()) {
    return numero.toStringAsFixed(0);
  }
  return numero.toString();
}

String formatearMicrolitros(double volumen) => formatearNumero(volumen);

class Reactivo {
  final String nombre;
  final double volPorReaccion; // µL
  final String? concentracion;

  const Reactivo({
    required this.nombre,
    required this.volPorReaccion,
    this.concentracion,
  });

  double volumenTotal(double factor) => volPorReaccion * factor;
}

class TipoTubo {
  final String nombre; // 'Muestra', 'Control positivo', 'Control negativo'
  final String seAnade; // solo tubos sin DNA: 'agua'
  final int? cantidadFija; // null = el usuario añade las filas que quiera
  final bool conDna; // sus tubos llevan DNA y aparecen en la tabla de muestras

  const TipoTubo({
    required this.nombre,
    this.seAnade = '',
    this.cantidadFija,
    this.conDna = false,
  });

  /// Tipos con DNA cuyas filas añade el usuario (las muestras).
  bool get filasLibres => conDna && cantidadFija == null;

  String instruccion(double volumen) => '${formatearMicrolitros(volumen)} µL de $seAnade';
}

enum TipoParametro { numero, texto }

class ParametroEntrada {
  final String nombre; // 'Lote de la Taq'
  final TipoParametro tipo;
  final String? unidad;
  final bool obligatorio;

  const ParametroEntrada({
    required this.nombre,
    this.tipo = TipoParametro.numero,
    this.unidad,
    this.obligatorio = true,
  });
}

enum ModoMolde {
  normalizado('Normalizar la cantidad de DNA'),
  volumenFijo('Mismo volumen de DNA en todos los tubos');

  const ModoMolde(this.etiqueta);
  final String etiqueta;
}

/// Una fila de la tabla de muestras: lo que se introduce al ejecutar.
class Muestra {
  final String id; // identificador interno, no cambia aunque edites la fila
  final String tipo; // nombre del TipoTubo: 'Muestra', 'Control positivo'
  final String codigo; // el que escribe el usuario: 'M1', 'Vid-23'
  final double? concentracion; // ng/µL

  const Muestra({
    required this.id,
    required this.tipo,
    this.codigo = '',
    this.concentracion,
  });
}

enum EstadoMuestra { correcta, diluir, huecoCompleto, sinConcentracion }

/// Lo que hay que pipetear en el tubo de una muestra.
class ResultadoMuestra {
  final Muestra muestra;
  final EstadoMuestra estado;
  final double volumenDna; // µL de DNA (ya diluido, si hace falta)
  final double volumenAgua; // µL de agua para completar el hueco
  final int? factorDilucion; // 5 = diluir 1:5; null si no hace falta o no basta con 1:100
  final double? ngReales; // solo si se usa el hueco entero

  const ResultadoMuestra({
    required this.muestra,
    required this.estado,
    required this.volumenDna,
    required this.volumenAgua,
    this.factorDilucion,
    this.ngReales,
  });

  /// ¿Se puede pipetear? Falta la concentración o haría falta diluir más de 1:100.
  bool get listo =>
      estado != EstadoMuestra.sinConcentracion &&
      !(estado == EstadoMuestra.diluir && factorDilucion == null);
}

class ResultadoMastermix {
  final int totalTubos;
  final double factor;
  final double aguaPorTubo; // agua del mastermix por tubo (sin contar el hueco)
  final Map<String, double> volumenesTotales; // reactivo → µL totales, agua incluida
  final List<ResultadoMuestra> muestras;

  const ResultadoMastermix({
    required this.totalTubos,
    required this.factor,
    required this.aguaPorTubo,
    required this.volumenesTotales,
    this.muestras = const [],
  });

  bool get esValido => aguaPorTubo >= 0;

  bool get muestrasListas => muestras.every((resultado) => resultado.listo);

  /// µL totales de mastermix que hay que preparar (suma de todo, agua incluida).
  double get volumenTotal {
    double suma = 0;
    for (final volumen in volumenesTotales.values) {
      suma += volumen;
    }
    return suma;
  }
}
