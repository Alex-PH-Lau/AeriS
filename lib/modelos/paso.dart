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
  final double volumenMolde; // hueco para DNA + agua en cada tubo (µL)
  final double margen; // 1.1 = +10 %
  final ModoMolde modo;
  final double? ngObjetivo; // ng de DNA por reacción (modo normalizado)
  final double volumenMinimo; // µL mínimos que se pueden pipetear con precisión
  final List<Reactivo> reactivos;
  final List<TipoTubo> tiposTubo;
  final List<ParametroEntrada> parametros; // datos de la ejecución: lotes, equipo…

  static const factoresDilucion = [2, 5, 10, 20, 50, 100];

  // Margen para comparar decimales sin que un 0.9999999 cuente como menor que 1
  static const _tolerancia = 1e-9;

  const PasoCalculo({
    required super.titulo,
    required this.volumenReaccion,
    required this.volumenMolde,
    this.margen = 1.1,
    this.modo = ModoMolde.normalizado,
    this.ngObjetivo,
    this.volumenMinimo = 1.0,
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

  /// Busca un tipo de tubo por su nombre. Devuelve null si no existe.
  TipoTubo? tipoTubo(String nombre) {
    for (final tipo in tiposTubo) {
      if (tipo.nombre == nombre) return tipo;
    }
    return null;
  }

  ResultadoMastermix calcular(List<Muestra> muestras) {
    // Tubos con DNA: uno por fila de la tabla. Tubos sin DNA: su cantidad fija.
    int totalTubos = muestras.length;
    for (final tipo in tiposTubo) {
      if (!tipo.conDna) totalTubos += tipo.cantidadFija ?? 0;
    }

    final factor = totalTubos * margen;
    final aguaPorTubo = volumenReaccion - sumaReactivos - volumenMolde;

    final volumenes = <String, double>{};
    for (final reactivo in reactivos) {
      volumenes[reactivo.nombre] = reactivo.volumenTotal(factor);
    }
    volumenes['Agua'] = aguaPorTubo * factor;

    final resultados = <ResultadoMuestra>[];
    for (final muestra in muestras) {
      resultados.add(calcularMuestra(muestra));
    }

    return ResultadoMastermix(
      totalTubos: totalTubos,
      factor: factor,
      aguaPorTubo: aguaPorTubo,
      volumenesTotales: volumenes,
      muestras: resultados,
    );
  }

  ResultadoMuestra calcularMuestra(Muestra muestra) {
    // Mismo volumen en todos: el hueco entero es DNA
    if (modo == ModoMolde.volumenFijo) {
      return ResultadoMuestra(
        muestra: muestra,
        estado: EstadoMuestra.correcta,
        volumenDna: volumenMolde,
        volumenAgua: 0,
      );
    }

    final concentracion = muestra.concentracion;
    final objetivo = ngObjetivo;
    if (concentracion == null || concentracion <= 0 || objetivo == null) {
      return ResultadoMuestra(
        muestra: muestra,
        estado: EstadoMuestra.sinConcentracion,
        volumenDna: 0,
        volumenAgua: 0,
      );
    }

    final volumen = objetivo / concentracion;

    // Poco concentrada: no cabe en el hueco → se usa el hueco entero (opción B)
    if (volumen > volumenMolde + _tolerancia) {
      return ResultadoMuestra(
        muestra: muestra,
        estado: EstadoMuestra.huecoCompleto,
        volumenDna: volumenMolde,
        volumenAgua: 0,
        ngReales: volumenMolde * concentracion,
      );
    }

    // Muy concentrada: menos del mínimo pipeteable → buscar una dilución
    if (volumen < volumenMinimo - _tolerancia) {
      for (final factorDilucion in factoresDilucion) {
        final volumenDiluido = volumen * factorDilucion;
        if (volumenDiluido >= volumenMinimo - _tolerancia &&
            volumenDiluido <= volumenMolde + _tolerancia) {
          return ResultadoMuestra(
            muestra: muestra,
            estado: EstadoMuestra.diluir,
            volumenDna: volumenDiluido,
            volumenAgua: volumenMolde - volumenDiluido,
            factorDilucion: factorDilucion,
          );
        }
      }
      // Ni con 1:100 basta
      return ResultadoMuestra(
        muestra: muestra,
        estado: EstadoMuestra.diluir,
        volumenDna: 0,
        volumenAgua: 0,
      );
    }

    return ResultadoMuestra(
      muestra: muestra,
      estado: EstadoMuestra.correcta,
      volumenDna: volumen,
      volumenAgua: volumenMolde - volumen,
    );
  }
}
