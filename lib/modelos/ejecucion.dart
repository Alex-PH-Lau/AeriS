// AeriS - Laboratory protocol assistant
// Copyright (C) 2026 Alejandro Pascual Hernández and contributors
// SPDX-License-Identifier: GPL-3.0-or-later
// Additional permission for app stores: see EXCEPCION_TIENDAS.md

import 'package:aeris/modelos/calculo.dart';
import 'package:aeris/modelos/json.dart';

enum EstadoEjecucion {
  enProceso('En proceso'),
  completada('Completada');

  const EstadoEjecucion(this.etiqueta);
  final String etiqueta;
}

class RegistroPaso {
  final int indicePaso;
  final DateTime completadoEn;
  final String? nota;

  const RegistroPaso({
    required this.indicePaso,
    required this.completadoEn,
    this.nota,
  });

  Map<String, dynamic> toJson() => {
        'indicePaso': indicePaso,
        'completadoEn': completadoEn.toIso8601String(),
        if (nota != null) 'nota': nota,
      };

  factory RegistroPaso.fromJson(Map<String, dynamic> json) => RegistroPaso(
        indicePaso: json['indicePaso'] as int,
        completadoEn: DateTime.parse(json['completadoEn'] as String),
        nota: json['nota'] as String?,
      );
}

class Ejecucion {
  final String protocoloId;
  final int protocoloVersion; // la versión exacta usada
  final DateTime inicio;
  final DateTime? fin; // null mientras está en proceso
  final EstadoEjecucion estado;
  final Map<String, String> valoresIntroducidos; // 'Lote de la Taq' → 'A123'
  final List<Muestra> muestras; // código y concentración de cada muestra
  final List<RegistroPaso> registros;

  const Ejecucion({
    required this.protocoloId,
    required this.protocoloVersion,
    required this.inicio,
    this.fin,
    this.estado = EstadoEjecucion.enProceso,
    this.valoresIntroducidos = const {},
    this.muestras = const [],
    this.registros = const [],
  });

  /// Devuelve una ejecución nueva con los datos introducidos actualizados.
  Ejecucion conDatos({
    Map<String, String>? valoresIntroducidos,
    List<Muestra>? muestras,
  }) {
    return Ejecucion(
      protocoloId: protocoloId,
      protocoloVersion: protocoloVersion,
      inicio: inicio,
      fin: fin,
      estado: estado,
      valoresIntroducidos: valoresIntroducidos ?? this.valoresIntroducidos,
      muestras: muestras ?? this.muestras,
      registros: registros,
    );
  }

  /// Paso por el que seguir al reanudar: el siguiente al último completado.
  int get pasoParaReanudar {
    if (registros.isEmpty) return 0;
    var mayor = 0;
    for (final registro in registros) {
      if (registro.indicePaso > mayor) mayor = registro.indicePaso;
    }
    return mayor + 1;
  }

  /// Devuelve una ejecución nueva con un paso más registrado.
  Ejecucion completarPaso(int indicePaso, {String? nota}) {
    return Ejecucion(
      protocoloId: protocoloId,
      protocoloVersion: protocoloVersion,
      inicio: inicio,
      fin: fin,
      estado: estado,
      valoresIntroducidos: valoresIntroducidos,
      muestras: muestras,
      registros: [
        ...registros,
        RegistroPaso(
          indicePaso: indicePaso,
          completadoEn: DateTime.now(),
          nota: nota,
        ),
      ],
    );
  }

  /// Devuelve una ejecución nueva marcada como completada.
  Ejecucion terminar() {
    return Ejecucion(
      protocoloId: protocoloId,
      protocoloVersion: protocoloVersion,
      inicio: inicio,
      fin: DateTime.now(),
      estado: EstadoEjecucion.completada,
      valoresIntroducidos: valoresIntroducidos,
      muestras: muestras,
      registros: registros,
    );
  }

  Map<String, dynamic> toJson() {
    final fin = this.fin;
    return {
      'protocoloId': protocoloId,
      'protocoloVersion': protocoloVersion,
      'inicio': inicio.toIso8601String(),
      if (fin != null) 'fin': fin.toIso8601String(),
      'estado': estado.name,
      'valoresIntroducidos': valoresIntroducidos,
      'muestras': [for (final muestra in muestras) muestra.toJson()],
      'registros': [for (final registro in registros) registro.toJson()],
    };
  }

  factory Ejecucion.fromJson(Map<String, dynamic> json) {
    final fin = json['fin'] as String?;
    return Ejecucion(
      protocoloId: json['protocoloId'] as String,
      protocoloVersion: json['protocoloVersion'] as int,
      inicio: DateTime.parse(json['inicio'] as String),
      fin: fin == null ? null : DateTime.parse(fin),
      estado: EstadoEjecucion.values.byName(json['estado'] as String),
      valoresIntroducidos: Map<String, String>.from(
        json['valoresIntroducidos'] as Map? ?? const {},
      ),
      muestras: leerLista(json['muestras'], Muestra.fromJson),
      registros: leerLista(json['registros'], RegistroPaso.fromJson),
    );
  }
}
