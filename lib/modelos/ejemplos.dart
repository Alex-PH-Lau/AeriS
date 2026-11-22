// AeriS - Laboratory protocol assistant
// Copyright (C) 2026 Alejandro Pascual Hernández and contributors
// SPDX-License-Identifier: GPL-3.0-or-later
// Additional permission for app stores: see EXCEPCION_TIENDAS.md

// Datos de prueba hasta que tengamos base de datos.

import 'package:aeris/modelos/calculo.dart';
import 'package:aeris/modelos/paso.dart';
import 'package:aeris/modelos/protocolo.dart';

final pcrEstandar = Protocolo(
  id: 'pcr-estandar',
  nombre: 'PCR estándar',
  version: 1,
  creado: DateTime(2026, 11, 22),
  pasos: const [
    PasoInstrucciones(
      titulo: 'Preparar los reactivos',
      texto: 'Descongelar los reactivos en hielo y darles un pulso de centrífuga.',
    ),
    PasoCalculo(
      titulo: 'Preparar el mastermix',
      volumenReaccion: 25,
      volumenMolde: 5, // hueco para DNA + agua
      modo: ModoMolde.normalizado,
      ngObjetivo: 50,
      volumenMinimo: 1,
      reactivos: [
        Reactivo(nombre: 'Buffer', volPorReaccion: 2.5, concentracion: '10x'),
        Reactivo(nombre: 'dNTPs', volPorReaccion: 0.5, concentracion: '10 mM'),
        Reactivo(nombre: 'Primer F', volPorReaccion: 1.0, concentracion: '10 µM'),
        Reactivo(nombre: 'Primer R', volPorReaccion: 1.0, concentracion: '10 µM'),
        Reactivo(nombre: 'Taq polimerasa', volPorReaccion: 0.25),
        Reactivo(nombre: 'MgCl2', volPorReaccion: 1.5, concentracion: '25 mM'),
      ],
      tiposTubo: [
        TipoTubo(nombre: 'Muestra', conDna: true),
        TipoTubo(nombre: 'Control positivo', conDna: true, cantidadFija: 1),
        TipoTubo(nombre: 'Control negativo', seAnade: 'agua', cantidadFija: 1),
      ],
      parametros: [
        ParametroEntrada(
          nombre: 'Lote de la Taq',
          tipo: TipoParametro.texto,
          obligatorio: false,
        ),
      ],
      alerta: Alerta('Mantén la Taq polimerasa en hielo en todo momento.'),
    ),
    PasoInstrucciones(
      titulo: 'Repartir el mastermix',
      texto: 'Repartir 20 µL de mastermix en cada tubo.',
    ),
    PasoInstrucciones(
      titulo: 'Añadir el molde',
      texto: 'Añadir a cada tubo el DNA y el agua indicados en el paso de cálculo. '
          'Al control negativo, 5 µL de agua.',
    ),
    PasoInstrucciones(
      titulo: 'Termociclador',
      texto: 'Colocar los tubos en el termociclador e iniciar el programa.',
    ),
  ],
);

final electroforesis = Protocolo(
  id: 'electroforesis-agarosa',
  nombre: 'Electroforesis en gel de agarosa',
  version: 2,
  creado: DateTime(2026, 11, 22),
  pasos: const [
    PasoInstrucciones(
      titulo: 'Preparar el gel',
      texto: 'Preparar el gel de agarosa al 1 % en TAE 1x.',
    ),
    PasoInstrucciones(
      titulo: 'Cargar el marcador',
      texto: 'Cargar el marcador de peso molecular en el primer pocillo.',
    ),
    PasoInstrucciones(
      titulo: 'Cargar las muestras',
      texto: 'Cargar 5 µL de cada producto de PCR con tampón de carga.',
    ),
    PasoInstrucciones(
      titulo: 'Correr el gel',
      texto: 'Correr el gel a 100 V.',
      temporizador: Temporizador(Duration(seconds: 10)),
    ),
    PasoInstrucciones(
      titulo: 'Visualizar',
      texto: 'Visualizar las bandas en el transiluminador.',
    ),
  ],
);

final protocolosDeEjemplo = [pcrEstandar, electroforesis];
