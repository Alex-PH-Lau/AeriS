// AeriS - Laboratory protocol assistant
// Copyright (C) 2026 Alejandro Pascual Hernández and contributors
// SPDX-License-Identifier: GPL-3.0-or-later
// Additional permission for app stores: see EXCEPCION_TIENDAS.md

import 'package:flutter/material.dart';
import 'package:aeris/pantallas/cuaderno.dart';
import 'package:aeris/pantallas/editor/pantalla_editor.dart';
import 'package:aeris/pantallas/mis_protocolos.dart';
import 'package:aeris/tema.dart';

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
          constraints: const BoxConstraints(maxWidth: Medida.anchoLectura),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(Espacio.grande),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Tu asistente de protocolos de laboratorio',
                    style: Theme.of(context).textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: Espacio.extra),
                  BotonInicio(
                    icono: Icons.add,
                    texto: 'Añadir protocolo nuevo',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const PantallaEditor()),
                    ),
                  ),
                  const SizedBox(height: Espacio.grande),
                  BotonInicio(
                    icono: Icons.folder_open,
                    texto: 'Mis protocolos',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PantallaMisProtocolos(),
                      ),
                    ),
                  ),
                  const SizedBox(height: Espacio.grande),
                  BotonInicio(
                    icono: Icons.menu_book,
                    texto: 'Cuaderno de laboratorio',
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const PantallaCuaderno(),
                      ),
                    ),
                  ),
                  const SizedBox(height: Espacio.grande),
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
      ),
    );
  }
}

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
    // Más grandes que un botón normal: son la puerta de entrada a la app
    final estilo = ButtonStyle(
      textStyle: WidgetStatePropertyAll(Theme.of(context).textTheme.titleLarge),
      iconSize: const WidgetStatePropertyAll(Medida.iconoGrande),
    );
    final icon = Icon(icono);
    final label = Text(texto);

    return SizedBox(
      width: double.infinity,
      height: Medida.botonGrande,
      child: secundario
          ? OutlinedButton.icon(style: estilo, onPressed: onPressed, icon: icon, label: label)
          : FilledButton.icon(style: estilo, onPressed: onPressed, icon: icon, label: label),
    );
  }
}

void mostrarProximamente(BuildContext context, String seccion) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('$seccion: próximamente')),
  );
}
