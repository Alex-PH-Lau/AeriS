// AeriS - Laboratory protocol assistant
// Copyright (C) 2026 Alejandro Pascual Hernández and contributors
// SPDX-License-Identifier: GPL-3.0-or-later
// Additional permission for app stores: see EXCEPCION_TIENDAS.md

import 'package:aeris/modelos/calculo.dart';

class Temporizador {
  final Duration duracion;
  const Temporizador(this.duracion);
}

class Alerta {
  final String mensaje;
  const Alerta(this.mensaje);
}

sealed class Paso {
  final String titulo;
  final Temporizador? temporizador; // como máximo uno
  final Alerta? alerta; // como máximo una

  const Paso({required this.titulo, this.temporizador, this.alerta});
}

class PasoInstrucciones extends Paso {
  final String texto; // más adelante: texto con formato e imágenes

  const PasoInstrucciones({
    required super.titulo,
    required this.texto,
    super.temporizador,
    super.alerta,
  });
}

class PasoCalculo extends Paso {
  final double volumenReaccion; // µL por tubo
  final double volumenMolde; // µL que se añaden aparte en cada tubo
  final double margen; // 1.1 = +10 %
  final List<Reactivo> reactivos;
  final List<TipoTubo> tiposTubo;
  final List<ParametroEntrada> parametros; // datos extra que se apuntan al ejecutar

  const PasoCalculo({
    required super.titulo,
    required this.volumenReaccion,
    required this.volumenMolde,
    this.margen = 1.1,
    required this.reactivos,
    required this.tiposTubo,
    this.parametros = const [],
    super.temporizador,
    super.alerta,
  });

  double get sumaReactivos {
    double suma = 0;
    for (final reactivo in reactivos) {
      suma += reactivo.volPorReaccion;
    }
    return suma;
  }

  List<TipoTubo> get tubosQueSePreguntan =>
      tiposTubo.where((tipo) => tipo.sePregunta).toList();

  ResultadoMastermix calcular(Map<String, int> cantidadesIntroducidas) {
    int totalTubos = 0;
    for (final tipo in tiposTubo) {
      totalTubos += tipo.cantidadFija ?? cantidadesIntroducidas[tipo.nombre] ?? 0;
    }

    final factor = totalTubos * margen;
    final aguaPorTubo = volumenReaccion - sumaReactivos - volumenMolde;

    final volumenes = <String, double>{};
    for (final reactivo in reactivos) {
      volumenes[reactivo.nombre] = reactivo.volumenTotal(factor);
    }
    volumenes['Agua'] = aguaPorTubo * factor;

    return ResultadoMastermix(
      totalTubos: totalTubos,
      factor: factor,
      aguaPorTubo: aguaPorTubo,
      volumenesTotales: volumenes,
    );
  }
}
