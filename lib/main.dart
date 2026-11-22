// AeriS - Laboratory protocol assistant
// Copyright (C) 2026 Alejandro Pascual Hernández and contributors
// SPDX-License-Identifier: GPL-3.0-or-later
// Additional permission for app stores: see EXCEPCION_TIENDAS.md

import 'package:flutter/material.dart';

void main() {
  runApp(const AerisApp());
}

// ---------- LA APP ----------

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

// ---------- PANTALLA DE INICIO ----------

class PantallaInicio extends StatelessWidget {
  const PantallaInicio({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AeriS'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Tu asistente de protocolos de laboratorio',
                  style: Theme.of(context).textTheme.titleMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                BotonInicio(
                  icono: Icons.add,
                  texto: 'Añadir protocolo nuevo',
                  onPressed: () => mostrarProximamente(context, 'Añadir protocolo'),
                ),
                const SizedBox(height: 24),
                BotonInicio(
                  icono: Icons.folder_open,
                  texto: 'Mis protocolos',
                  onPressed: () => mostrarProximamente(context, 'Mis protocolos'),
                ),
                const SizedBox(height: 24),
                BotonInicio(
                  icono: Icons.help_outline,
                  texto: 'Ayuda',
                  onPressed: () => mostrarProximamente(context, 'Ayuda'),
                  secundario: true,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------- WIDGETS REUTILIZABLES ----------

class BotonInicio extends StatelessWidget {
  final IconData icono;
  final String texto;
  final VoidCallback onPressed;
  final bool secundario;

  const BotonInicio({
    super.key,
    required this.icono,
    required this.texto,
    required this.onPressed,
    this.secundario = false,
  });

  @override
  Widget build(BuildContext context) {
    final icon = Icon(icono, size: 36);
    final label = Text(texto, style: const TextStyle(fontSize: 22));

    return SizedBox(
      width: double.infinity,
      height: 96,
      child: secundario
          ? OutlinedButton.icon(onPressed: onPressed, icon: icon, label: label)
          : FilledButton.icon(onPressed: onPressed, icon: icon, label: label),
    );
  }
}

// ---------- FUNCIONES AUXILIARES ----------

void mostrarProximamente(BuildContext context, String seccion) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('$seccion: próximamente')),
  );
}