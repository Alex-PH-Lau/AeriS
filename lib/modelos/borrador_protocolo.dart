// AeriS - Laboratory protocol assistant
// Copyright (C) 2026 Alejandro Pascual Hernández and contributors
// SPDX-License-Identifier: GPL-3.0-or-later
// Additional permission for app stores: see EXCEPCION_TIENDAS.md

import 'package:aeris/modelos/paso.dart';
import 'package:aeris/modelos/protocolo.dart';

/// Un paso dentro del editor, con una clave que no cambia aunque se edite o
/// se mueva. Las listas de Flutter la necesitan para saber qué fila es cuál.
class ElementoPaso {
  final String clave;
  final Paso paso;

  const ElementoPaso({required this.clave, required this.paso});
}

/// Protocolo en edición. Como [CuentaAtras], es un controlador que CAMBIA;
/// al guardar se convierte en un [Protocolo] normal, inmutable.
class BorradorProtocolo {
  final Protocolo? original; // null = protocolo nuevo
  final List<ElementoPaso> _pasos = [];
  String _nombre;
  bool _modificado = false;
  int _contadorClaves = 0;

  BorradorProtocolo({this.original}) : _nombre = original?.nombre ?? '' {
    final base = original;
    if (base != null) {
      for (final paso in base.pasos) {
        _pasos.add(ElementoPaso(clave: _nuevaClave(), paso: paso));
      }
    }
  }

  String _nuevaClave() => 'paso-${_contadorClaves++}';

  bool get esNuevo => original == null;

  /// ¿Hay algo sin guardar?
  bool get modificado => _modificado;

  String get nombre => _nombre;

  set nombre(String valor) {
    _nombre = valor;
    _modificado = true;
  }

  /// Lista de solo lectura: los cambios se hacen con los métodos de abajo.
  List<ElementoPaso> get pasos => List.unmodifiable(_pasos);

  int indiceDe(String clave) => _pasos.indexWhere((elemento) => elemento.clave == clave);

  /// Añade un paso de instrucciones vacío al final y devuelve su clave.
  String anadirInstrucciones() {
    final elemento = ElementoPaso(
      clave: _nuevaClave(),
      paso: const PasoInstrucciones(titulo: '', texto: ''),
    );
    _pasos.add(elemento);
    _modificado = true;
    return elemento.clave;
  }

  void reemplazar(String clave, Paso paso) {
    final indice = indiceDe(clave);
    if (indice < 0) return;
    _pasos[indice] = ElementoPaso(clave: clave, paso: paso);
    _modificado = true;
  }

  void eliminar(String clave) {
    _pasos.removeWhere((elemento) => elemento.clave == clave);
    _modificado = true;
  }

  /// Mueve un paso. Usa la misma convención que ReorderableListView: si se
  /// mueve hacia abajo, [hasta] cuenta el hueco que deja el propio paso.
  void mover(int desde, int hasta) {
    var destino = hasta;
    if (destino > desde) destino -= 1;
    if (destino == desde) return;
    final elemento = _pasos.removeAt(desde);
    _pasos.insert(destino, elemento);
    _modificado = true;
  }

  /// Lo que falta para poder guardar. Vacía si está todo bien.
  List<String> problemas() {
    final lista = <String>[];
    if (_nombre.trim().isEmpty) lista.add('El protocolo necesita un nombre.');
    if (_pasos.isEmpty) lista.add('Añade al menos un paso.');

    for (var i = 0; i < _pasos.length; i++) {
      final paso = _pasos[i].paso;
      final numero = i + 1;
      if (paso.titulo.trim().isEmpty) lista.add('Paso $numero: falta el título.');
      if (paso is PasoInstrucciones && paso.texto.trim().isEmpty) {
        lista.add('Paso $numero: falta el texto.');
      }
      final temporizador = paso.temporizador;
      if (temporizador != null && temporizador.duracion <= Duration.zero) {
        lista.add('Paso $numero: el temporizador tiene que durar más de 0 segundos.');
      }
      final alerta = paso.alerta;
      if (alerta != null && alerta.mensaje.trim().isEmpty) {
        lista.add('Paso $numero: la alerta no tiene mensaje.');
      }
    }
    return lista;
  }

  /// Crea el protocolo para guardar: V.1 si es nuevo, o la versión siguiente.
  Protocolo construir() {
    final pasos = [for (final elemento in _pasos) elemento.paso];
    final nombre = _nombre.trim();
    final base = original;

    if (base == null) {
      final ahora = DateTime.now();
      return Protocolo(
        id: 'p-${ahora.microsecondsSinceEpoch}', // único en este dispositivo
        nombre: nombre,
        version: 1,
        creado: ahora,
        pasos: pasos,
      );
    }
    return base.nuevaVersion(nombre: nombre, pasos: pasos);
  }
}
