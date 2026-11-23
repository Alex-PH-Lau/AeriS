// AeriS - Laboratory protocol assistant
// Copyright (C) 2026 Alejandro Pascual Hernández and contributors
// SPDX-License-Identifier: GPL-3.0-or-later
// Additional permission for app stores: see EXCEPCION_TIENDAS.md

import 'package:flutter/material.dart';
import 'package:aeris/pantallas/inicio.dart';
import 'package:aeris/servicios/almacen.dart';
import 'package:aeris/servicios/avisos.dart';
import 'package:aeris/servicios/limpieza.dart';
import 'package:aeris/servicios/plataforma.dart';
import 'package:aeris/tema.dart';

Future<void> main() async {
  // Necesario antes de usar plugins si main() hace algo antes de runApp
  WidgetsFlutterBinding.ensureInitialized();
  await prepararPlataforma(); // antes de abrir nada: decide qué almacén usar
  await almacen.abrir();
  await _limpiar();
  await avisos.inicializar();
  runApp(const AerisApp());
}

/// Mantenimiento al arrancar: si falla, la app arranca igual.
Future<void> _limpiar() async {
  try {
    final borradas = await limpiarImagenesSinUso(almacen);
    if (borradas > 0) debugPrint('AeriS: $borradas imágenes sin usar borradas');
  } catch (error) {
    debugPrint('AeriS: no se pudo limpiar las imágenes: $error');
  }
}

class AerisApp extends StatelessWidget {
  const AerisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AeriS',
      debugShowCheckedModeBanner: false,
      theme: temaAeris(),
      darkTheme: temaAeris(brillo: Brightness.dark), // sigue el modo del sistema
      home: const PantallaInicio(),
    );
  }
}
