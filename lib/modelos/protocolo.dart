// AeriS - Laboratory protocol assistant
// Copyright (C) 2026 Alejandro Pascual Hernández and contributors
// SPDX-License-Identifier: GPL-3.0-or-later
// Additional permission for app stores: see EXCEPCION_TIENDAS.md

class Protocolo {
  final String nombre;
  final int version;
  final List<String> pasos;

  const Protocolo({
    required this.nombre,
    required this.version,
    required this.pasos,
  });

  String get nombreCompleto => '$nombre (V.$version)';
  int get numeroPasos => pasos.length;
}

// Datos de prueba hasta que tengamos base de datos (fase 3)
const protocolosDeEjemplo = [
  Protocolo(
    nombre: 'PCR estándar',
    version: 1,
    pasos: [
      'Descongelar los reactivos en hielo y darles un pulso de centrífuga.',
      'Preparar el mastermix según los cálculos.',
      'Repartir 24 µL de mastermix en cada tubo.',
      'Añadir 1 µL de DNA a cada tubo de muestra y 1 µL de agua al control negativo.',
      'Colocar los tubos en el termociclador e iniciar el programa.',
    ],
  ),
  Protocolo(
    nombre: 'Electroforesis en gel de agarosa',
    version: 2,
    pasos: [
      'Preparar el gel de agarosa al 1 % en TAE 1x.',
      'Cargar el marcador de peso molecular en el primer pocillo.',
      'Cargar 5 µL de cada producto de PCR con tampón de carga.',
      'Correr el gel a 100 V durante 30 minutos.',
      'Visualizar las bandas en el transiluminador.',
    ],
  ),
  Protocolo(
    nombre: 'Chambear con células eucariotas',
    version: 1,
    pasos: [
      'Pillamos la celula',
      'Se machaca',
      'Miras a ver si se ha machacado bien',
      'Ves que no',
      'Lloras y te vas a casa',
    ],
  ),
];