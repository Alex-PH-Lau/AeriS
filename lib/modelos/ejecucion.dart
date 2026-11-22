// AeriS - Laboratory protocol assistant
// Copyright (C) 2026 Alejandro Pascual Hernández and contributors
// SPDX-License-Identifier: GPL-3.0-or-later
// Additional permission for app stores: see EXCEPCION_TIENDAS.md

import 'package:aeris/modelos/calculo.dart';

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
}
