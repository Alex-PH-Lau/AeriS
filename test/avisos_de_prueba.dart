// AeriS - Laboratory protocol assistant
// Copyright (C) 2026 Alejandro Pascual Hernández and contributors
// SPDX-License-Identifier: GPL-3.0-or-later
// Additional permission for app stores: see EXCEPCION_TIENDAS.md

import 'package:aeris/servicios/avisos.dart';

/// Versión falsa del servicio de avisos para los tests: no toca el sistema,
/// solo apunta lo que la app le pide.
class AvisosDePrueba implements ServicioAvisos {
  final Map<int, DateTime> programados = {}; // id → hora del aviso
  bool permiso = true;

  @override
  Future<void> inicializar() async {}

  @override
  Future<bool> pedirPermiso() async => permiso;

  @override
  Future<void> programarFinTemporizador({
    required int id,
    required String titulo,
    required DateTime fin,
  }) async {
    programados[id] = fin;
  }

  @override
  Future<void> cancelar(int id) async {
    programados.remove(id);
  }
}
