// AeriS - Laboratory protocol assistant
// Copyright (C) 2026 Alejandro Pascual Hernández and contributors
// SPDX-License-Identifier: GPL-3.0-or-later
// Additional permission for app stores: see EXCEPCION_TIENDAS.md

import 'package:flutter/material.dart';
import 'package:aeris/pantallas/inicio.dart';
import 'package:aeris/servicios/avisos.dart';

Future<void> main() async {
  // Necesario antes de usar plugins si main() hace algo antes de runApp
  WidgetsFlutterBinding.ensureInitialized();
  await avisos.inicializar();
  runApp(const AerisApp());
}

class AerisApp extends StatelessWidget {
  const AerisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AeriS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 46, 0, 195),
        ),
      ),
      home: const PantallaInicio(),
    );
  }
}
