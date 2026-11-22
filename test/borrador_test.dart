// AeriS - Laboratory protocol assistant
// Copyright (C) 2026 Alejandro Pascual Hernández and contributors
// SPDX-License-Identifier: GPL-3.0-or-later
// Additional permission for app stores: see EXCEPCION_TIENDAS.md

import 'package:flutter_test/flutter_test.dart';
import 'package:aeris/modelos/borrador_protocolo.dart';
import 'package:aeris/modelos/ejemplos.dart';
import 'package:aeris/modelos/paso.dart';

/// Crea un borrador con pasos de instrucciones titulados A, B, C…
BorradorProtocolo borradorConPasos(List<String> titulos) {
  final borrador = BorradorProtocolo()..nombre = 'Prueba';
  for (final titulo in titulos) {
    final clave = borrador.anadirInstrucciones();
    borrador.reemplazar(clave, PasoInstrucciones(titulo: titulo, texto: 'Texto de $titulo'));
  }
  return borrador;
}

List<String> titulos(BorradorProtocolo borrador) =>
    [for (final elemento in borrador.pasos) elemento.paso.titulo];

void main() {
  group('Protocolo nuevo', () {
    test('Recién creado está vacío y sin cambios', () {
      final borrador = BorradorProtocolo();

      expect(borrador.esNuevo, isTrue);
      expect(borrador.modificado, isFalse);
      expect(borrador.pasos, isEmpty);
    });

    test('Vacío no se puede guardar: falta nombre y pasos', () {
      final problemas = BorradorProtocolo().problemas();

      expect(problemas, contains('El protocolo necesita un nombre.'));
      expect(problemas, contains('Añade al menos un paso.'));
    });

    test('Un paso recién añadido necesita título y texto', () {
      final borrador = BorradorProtocolo()..nombre = 'Prueba';
      borrador.anadirInstrucciones();

      expect(borrador.problemas(), ['Paso 1: falta el título.', 'Paso 1: falta el texto.']);
    });

    test('Completo se guarda como versión 1', () {
      final protocolo = borradorConPasos(['A']).construir();

      expect(protocolo.version, 1);
      expect(protocolo.id, startsWith('p-'));
      expect(protocolo.nombreCompleto, 'Prueba (V.1)');
      expect(protocolo.pasos.length, 1);
    });
  });

  group('Editar un protocolo existente', () {
    test('Empieza con sus pasos y sin cambios', () {
      final borrador = BorradorProtocolo(original: pcrEstandar);

      expect(borrador.esNuevo, isFalse);
      expect(borrador.modificado, isFalse);
      expect(borrador.nombre, 'PCR estándar');
      expect(borrador.pasos.length, 5);
      expect(borrador.problemas(), isEmpty);
    });

    test('Guardar crea la versión siguiente con el mismo id y no toca la original', () {
      final borrador = BorradorProtocolo(original: pcrEstandar)..nombre = 'PCR rápida';
      final v2 = borrador.construir();

      expect(v2.id, pcrEstandar.id);
      expect(v2.version, 2);
      expect(v2.nombreCompleto, 'PCR rápida (V.2)');
      expect(pcrEstandar.nombre, 'PCR estándar');
    });
  });

  group('Mover y borrar pasos', () {
    test('Mover hacia abajo (convención de ReorderableListView)', () {
      final borrador = borradorConPasos(['A', 'B', 'C']);
      borrador.mover(0, 3); // A al final: "3" cuenta el hueco que deja A

      expect(titulos(borrador), ['B', 'C', 'A']);
    });

    test('Mover hacia arriba', () {
      final borrador = borradorConPasos(['A', 'B', 'C']);
      borrador.mover(2, 0);

      expect(titulos(borrador), ['C', 'A', 'B']);
    });

    test('Borrar un paso', () {
      final borrador = borradorConPasos(['A', 'B', 'C']);
      borrador.eliminar(borrador.pasos[1].clave);

      expect(titulos(borrador), ['A', 'C']);
    });

    test('Las claves no cambian al mover', () {
      final borrador = borradorConPasos(['A', 'B']);
      final claveA = borrador.pasos[0].clave;
      borrador.mover(0, 2);

      expect(borrador.indiceDe(claveA), 1);
    });
  });

  group('Herramientas del paso', () {
    test('Un temporizador de 0 segundos no es válido', () {
      final borrador = borradorConPasos(['A']);
      final clave = borrador.pasos.first.clave;
      final paso = borrador.pasos.first.paso as PasoInstrucciones;
      borrador.reemplazar(clave, paso.copiar(temporizador: const Temporizador(Duration.zero)));

      expect(borrador.problemas(), ['Paso 1: el temporizador tiene que durar más de 0 segundos.']);
    });

    test('Una alerta sin mensaje no es válida', () {
      final borrador = borradorConPasos(['A']);
      final clave = borrador.pasos.first.clave;
      final paso = borrador.pasos.first.paso as PasoInstrucciones;
      borrador.reemplazar(clave, paso.copiar(alerta: const Alerta('  ')));

      expect(borrador.problemas(), ['Paso 1: la alerta no tiene mensaje.']);
    });

    test('copiar puede quitar el temporizador y la alerta', () {
      const paso = PasoInstrucciones(
        titulo: 'Incubar',
        texto: 'A 37 °C',
        temporizador: Temporizador(Duration(minutes: 10)),
        alerta: Alerta('Cuidado'),
      );

      final sinNada = paso.copiar(sinTemporizador: true, sinAlerta: true);
      expect(sinNada.temporizador, isNull);
      expect(sinNada.alerta, isNull);
      expect(sinNada.titulo, 'Incubar');

      final otroTitulo = paso.copiar(titulo: 'Incubar 2');
      expect(otroTitulo.temporizador, isNotNull); // lo demás se conserva
    });
  });
}
