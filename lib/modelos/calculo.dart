// AeriS - Laboratory protocol assistant
// Copyright (C) 2026 Alejandro Pascual Hernández and contributors
// SPDX-License-Identifier: GPL-3.0-or-later
// Additional permission for app stores: see EXCEPCION_TIENDAS.md

/// Muestra un volumen sin decimales sobrantes: 1.0 -> "1", 0.25 -> "0.25".
String formatearMicrolitros(double volumen) {
  if (volumen == volumen.roundToDouble()) {
    return volumen.toStringAsFixed(0);
  }
  return volumen.toString();
}

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
  final String nombre; // 'Muestra', 'Control negativo'…
  final String seAnade; // 'su DNA', 'agua'…
  final int? cantidadFija; // null = se pregunta en cada ejecución

  const TipoTubo({
    required this.nombre,
    required this.seAnade,
    this.cantidadFija,
  });

  bool get sePregunta => cantidadFija == null;

  String instruccion(double volumenMolde) =>
      '${formatearMicrolitros(volumenMolde)} µL de $seAnade';
}

enum TipoParametro { numero, texto }

class ParametroEntrada {
  final String nombre; // 'Concentración del DNA', 'Lote de la Taq'
  final TipoParametro tipo;
  final String? unidad; // 'ng/µL'
  final bool obligatorio;

  const ParametroEntrada({
    required this.nombre,
    this.tipo = TipoParametro.numero,
    this.unidad,
    this.obligatorio = true,
  });
}

class ResultadoMastermix {
  final int totalTubos;
  final double factor;
  final double aguaPorTubo;
  final Map<String, double> volumenesTotales; // reactivo → µL totales, agua incluida

  const ResultadoMastermix({
    required this.totalTubos,
    required this.factor,
    required this.aguaPorTubo,
    required this.volumenesTotales,
  });

  bool get esValido => aguaPorTubo >= 0;

  /// µL totales de mastermix que hay que preparar (suma de todo, agua incluida).
  double get volumenTotal {
    double suma = 0;
    for (final volumen in volumenesTotales.values) {
      suma += volumen;
    }
    return suma;
  }
}
