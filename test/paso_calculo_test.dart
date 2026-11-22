// AeriS - Laboratory protocol assistant
// Copyright (C) 2026 Alejandro Pascual Hernández and contributors
// SPDX-License-Identifier: GPL-3.0-or-later
// Additional permission for app stores: see EXCEPCION_TIENDAS.md

import 'package:flutter_test/flutter_test.dart';
import 'package:aeris/modelos/borrador_protocolo.dart';
import 'package:aeris/modelos/calculo.dart';
import 'package:aeris/modelos/ejemplos.dart';
import 'package:aeris/modelos/paso.dart';

/// El paso de cálculo de la PCR de ejemplo, que sabemos que está bien.
PasoCalculo pasoPcr() => pcrEstandar.pasos[1] as PasoCalculo;

void main() {
  group('PasoCalculo.problemas', () {
    test('La PCR de ejemplo no tiene problemas', () {
      expect(pasoPcr().problemas(), isEmpty);
    });

    test('Reactivo repetido (sin distinguir mayúsculas)', () {
      final paso = pasoPcr().copiar(reactivos: [
        const Reactivo(nombre: 'Buffer', volPorReaccion: 2.5),
        const Reactivo(nombre: 'buffer', volPorReaccion: 1),
      ]);
      expect(paso.problemas(), contains('El reactivo "buffer" está repetido.'));
    });

    test('El agua no se pone como reactivo', () {
      final paso = pasoPcr().copiar(reactivos: [
        const Reactivo(nombre: 'Agua', volPorReaccion: 10),
      ]);
      expect(paso.problemas(), contains('"Agua" no puede ser un reactivo: AeriS la calcula sola.'));
    });

    test('Los reactivos y el hueco no caben en el tubo', () {
      // 25 µL de reacción, 5 de hueco → caben 20 de reactivos; aquí hay 21
      final paso = pasoPcr().copiar(reactivos: [
        const Reactivo(nombre: 'Buffer', volPorReaccion: 21),
      ]);
      expect(
        paso.problemas(),
        contains('Los reactivos y el hueco suman más que el volumen de reacción.'),
      );
    });

    test('Justo lleno (sin agua en el mix) sí es válido', () {
      final paso = pasoPcr().copiar(reactivos: [
        const Reactivo(nombre: 'Mix 2x', volPorReaccion: 20),
      ]);
      expect(paso.problemas(), isEmpty);
    });

    test('Hace falta un tipo de tubo para las muestras', () {
      final paso = pasoPcr().copiar(tiposTubo: [
        const TipoTubo(nombre: 'Control negativo', seAnade: 'agua', cantidadFija: 1),
      ]);
      expect(
        paso.problemas(),
        contains('Falta un tipo de tubo con DNA y sin cantidad fija (las muestras).'),
      );
    });

    test('Un tubo sin DNA necesita cantidad y qué se añade', () {
      final paso = pasoPcr().copiar(tiposTubo: [
        const TipoTubo(nombre: 'Muestra', conDna: true),
        const TipoTubo(nombre: 'Blanco'),
      ]);
      final problemas = paso.problemas();
      expect(problemas, contains('"Blanco": indica cuántos tubos hay.'));
      expect(problemas, contains('"Blanco": indica qué se añade en lugar de DNA.'));
    });

    test('Con volumen fijo no se piden los ng', () {
      final paso = pasoPcr().copiar(modo: ModoMolde.volumenFijo);
      // ngObjetivo sigue guardado, pero aunque no lo estuviera no sería un problema
      final sinNg = PasoCalculo(
        titulo: paso.titulo,
        volumenReaccion: paso.volumenReaccion,
        volumenMolde: paso.volumenMolde,
        modo: ModoMolde.volumenFijo,
        reactivos: paso.reactivos,
        tiposTubo: paso.tiposTubo,
      );
      expect(paso.problemas(), isEmpty);
      expect(sinNg.problemas(), isEmpty);
    });
  });

  group('PasoCalculo.copiar', () {
    test('Cambia solo lo indicado y puede quitar la alerta', () {
      final original = pasoPcr();
      final copia = original.copiar(volumenReaccion: 50, sinAlerta: true);

      expect(copia.volumenReaccion, 50);
      expect(copia.alerta, isNull);
      expect(copia.reactivos, same(original.reactivos)); // el resto, igual
      expect(copia.parametros.single.nombre, 'Lote de la Taq');
    });
  });

  group('Borrador con paso de cálculo', () {
    test('anadirCalculo crea un paso de PCR por rellenar', () {
      final borrador = BorradorProtocolo()..nombre = 'PCR de prueba';
      final clave = borrador.anadirCalculo();

      expect(borrador.tieneCalculo, isTrue);
      final paso = borrador.pasos[borrador.indiceDe(clave)].paso as PasoCalculo;
      expect(paso.tiposTubo.map((t) => t.nombre), ['Muestra', 'Control negativo']);
      // Recién creado le faltan los reactivos, y el borrador lo dice con el número de paso
      expect(borrador.problemas(), contains('Paso 1: Añade al menos un reactivo.'));
    });

    test('Con los reactivos puestos ya se puede guardar', () {
      final borrador = BorradorProtocolo()..nombre = 'PCR de prueba';
      final clave = borrador.anadirCalculo();
      final paso = borrador.pasos.single.paso as PasoCalculo;
      borrador.reemplazar(clave, paso.copiar(reactivos: pasoPcr().reactivos));

      expect(borrador.problemas(), isEmpty);
      final protocolo = borrador.construir();
      expect(protocolo.pasos.single, isA<PasoCalculo>());
    });

    test('Solo se permite un paso de cálculo por protocolo', () {
      final borrador = BorradorProtocolo()..nombre = 'Doble';
      for (var i = 0; i < 2; i++) {
        final clave = borrador.anadirCalculo();
        final paso = borrador.pasos[borrador.indiceDe(clave)].paso as PasoCalculo;
        borrador.reemplazar(clave, paso.copiar(reactivos: pasoPcr().reactivos));
      }
      expect(
        borrador.problemas(),
        contains('Por ahora, un protocolo solo puede tener un paso de cálculo.'),
      );
    });
  });
}
