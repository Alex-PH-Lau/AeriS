// AeriS - Laboratory protocol assistant
// Copyright (C) 2026 Alejandro Pascual Hernández and contributors
// SPDX-License-Identifier: GPL-3.0-or-later
// Additional permission for app stores: see EXCEPCION_TIENDAS.md

import 'package:aeris/modelos/imagenes.dart';
import 'package:aeris/servicios/almacen.dart';

/// Borra las imágenes que ya no usa ningún protocolo y devuelve cuántas.
///
/// Se quedan sin usar cuando se quita su marca del texto, o cuando se añade
/// una foto a un paso y luego se sale del editor sin guardar.
///
/// "En uso" significa en CUALQUIER versión, no solo en la última: las
/// versiones antiguas siguen ligadas a ejecuciones del cuaderno, y al abrir
/// una de ellas su foto tiene que seguir ahí.
///
/// OJO: solo es seguro cuando no hay ningún editor abierto. Una foto recién
/// añadida a un borrador sin guardar todavía no aparece en ningún protocolo,
/// y se borraría. Por eso se llama al arrancar la app, antes de mostrar nada.
Future<int> limpiarImagenesSinUso(Almacen almacen) async {
  final enUso = {
    for (final protocolo in await almacen.todasLasVersiones()) ...imagenesDelProtocolo(protocolo),
  };
  final sinUso = (await almacen.idsImagenes()).difference(enUso);
  if (sinUso.isNotEmpty) await almacen.borrarImagenes(sinUso);
  return sinUso.length;
}
