// AeriS - Laboratory protocol assistant
// Copyright (C) 2026 Alejandro Pascual Hernández and contributors
// SPDX-License-Identifier: GPL-3.0-or-later
// Additional permission for app stores: see EXCEPCION_TIENDAS.md

import 'package:aeris/modelos/calculo.dart';
import 'package:aeris/modelos/json.dart';

class Temporizador {
  final Duration duracion;
  const Temporizador(this.duracion);

  Map<String, dynamic> toJson() => {'segundos': duracion.inSeconds};

  factory Temporizador.fromJson(Map<String, dynamic> json) =>
      Temporizador(Duration(seconds: json['segundos'] as int));
}

class Alerta {
  final String mensaje;
  const Alerta(this.mensaje);

  Map<String, dynamic> toJson() => {'mensaje': mensaje};

  factory Alerta.fromJson(Map<String, dynamic> json) => Alerta(json['mensaje'] as String);
}

sealed class Paso {
  final String titulo;
  final Temporizador? temporizador; // como máximo uno
  final Alerta? alerta; // como máximo una

  const Paso({required this.titulo, this.temporizador, this.alerta});

  /// Cada tipo de paso sabe convertirse en JSON. El campo 'tipo' dice cuál es.
  Map<String, dynamic> toJson();

  /// Mira el campo 'tipo' y crea el paso concreto que corresponde.
  factory Paso.fromJson(Map<String, dynamic> json) {
    final tipo = json['tipo'];
    return switch (tipo) {
      'instrucciones' => PasoInstrucciones.fromJson(json),
      'calculo' => PasoCalculo.fromJson(json),
      _ => throw FormatException('Tipo de paso desconocido: $tipo'),
    };
  }

  /// Campos comunes a todos los pasos.
  Map<String, dynamic> _comunesJson() {
    final temporizador = this.temporizador;
    final alerta = this.alerta;
    return {
      'titulo': titulo,
      if (temporizador != null) 'temporizador': temporizador.toJson(),
      if (alerta != null) 'alerta': alerta.toJson(),
    };
  }

  static Temporizador? _leerTemporizador(Map<String, dynamic> json) {
    final datos = json['temporizador'] as Map<String, dynamic>?;
    return datos == null ? null : Temporizador.fromJson(datos);
  }

  static Alerta? _leerAlerta(Map<String, dynamic> json) {
    final datos = json['alerta'] as Map<String, dynamic>?;
    return datos == null ? null : Alerta.fromJson(datos);
  }
}

class PasoInstrucciones extends Paso {
  final String texto; // más adelante: texto con formato e imágenes

  const PasoInstrucciones({
    required super.titulo,
    required this.texto,
    super.temporizador,
    super.alerta,
  });

  @override
  Map<String, dynamic> toJson() => {
        'tipo': 'instrucciones',
        ..._comunesJson(),
        'texto': texto,
      };

  /// Copia con cambios. Como `null` ya significa "no cambiar", para QUITAR
  /// el temporizador o la alerta hacen falta los parámetros sinTemporizador y sinAlerta.
  PasoInstrucciones copiar({
    String? titulo,
    String? texto,
    Temporizador? temporizador,
    Alerta? alerta,
    bool sinTemporizador = false,
    bool sinAlerta = false,
  }) {
    return PasoInstrucciones(
      titulo: titulo ?? this.titulo,
      texto: texto ?? this.texto,
      temporizador: sinTemporizador ? null : (temporizador ?? this.temporizador),
      alerta: sinAlerta ? null : (alerta ?? this.alerta),
    );
  }

  factory PasoInstrucciones.fromJson(Map<String, dynamic> json) => PasoInstrucciones(
        titulo: json['titulo'] as String,
        texto: json['texto'] as String,
        temporizador: Paso._leerTemporizador(json),
        alerta: Paso._leerAlerta(json),
      );
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

  @override
  Map<String, dynamic> toJson() => {
        'tipo': 'calculo',
        ..._comunesJson(),
        'volumenReaccion': volumenReaccion,
        'volumenMolde': volumenMolde,
        'margen': margen,
        'modo': modo.name,
        if (ngObjetivo != null) 'ngObjetivo': ngObjetivo,
        'volumenMinimo': volumenMinimo,
        'reactivos': [for (final reactivo in reactivos) reactivo.toJson()],
        'tiposTubo': [for (final tipo in tiposTubo) tipo.toJson()],
        'parametros': [for (final parametro in parametros) parametro.toJson()],
      };

  factory PasoCalculo.fromJson(Map<String, dynamic> json) => PasoCalculo(
        titulo: json['titulo'] as String,
        volumenReaccion: leerDouble(json['volumenReaccion']),
        volumenMolde: leerDouble(json['volumenMolde']),
        margen: leerDoubleOpcional(json['margen']) ?? 1.1,
        modo: ModoMolde.values.byName(json['modo'] as String? ?? 'normalizado'),
        ngObjetivo: leerDoubleOpcional(json['ngObjetivo']),
        volumenMinimo: leerDoubleOpcional(json['volumenMinimo']) ?? 1.0,
        reactivos: leerLista(json['reactivos'], Reactivo.fromJson),
        tiposTubo: leerLista(json['tiposTubo'], TipoTubo.fromJson),
        parametros: leerLista(json['parametros'], ParametroEntrada.fromJson),
        temporizador: Paso._leerTemporizador(json),
        alerta: Paso._leerAlerta(json),
      );

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
