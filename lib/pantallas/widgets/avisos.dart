// AeriS - Laboratory protocol assistant
// Copyright (C) 2026 Alejandro Pascual Hernández and contributors
// SPDX-License-Identifier: GPL-3.0-or-later
// Additional permission for app stores: see EXCEPCION_TIENDAS.md

import 'package:flutter/material.dart';
import 'package:aeris/modelos/paso.dart';
import 'package:aeris/tema.dart';

/// Alerta de un paso crítico: ventana muy visible que no se cierra
/// hasta pulsar "Entendido" (ni tocando fuera, ni con el botón atrás).
Future<void> mostrarAlerta(BuildContext context, Alerta alerta) {
  final colores = Theme.of(context).colorScheme;
  final textos = Theme.of(context).textTheme;

  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => PopScope(
      canPop: false, // el botón atrás de Android no la cierra
      child: AlertDialog(
        backgroundColor: colores.errorContainer,
        icon: Icon(Icons.warning_amber_rounded, size: Medida.iconoAlerta, color: colores.error),
        title: Text(
          '¡Atención!',
          style: textos.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colores.onErrorContainer,
          ),
        ),
        content: Text(
          alerta.mensaje,
          textAlign: TextAlign.center,
          style: textos.headlineSmall?.copyWith(color: colores.onErrorContainer),
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: colores.error,
              foregroundColor: colores.onError,
              minimumSize: const Size(double.infinity, Medida.botonGrande),
              textStyle: textos.headlineSmall,
            ),
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Entendido'),
          ),
        ],
      ),
    ),
  );
}

/// Aviso de que un temporizador ha terminado.
Future<void> mostrarFinTemporizador(BuildContext context, String tituloPaso) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => AlertDialog(
      icon: const Icon(Icons.alarm, size: Medida.iconoAlerta),
      title: const Text('¡Tiempo!'),
      content: Text(
        'Ha terminado el temporizador de "$tituloPaso".',
        textAlign: TextAlign.center,
      ),
      actions: [
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, Medida.botonPrincipal)),
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Entendido'),
        ),
      ],
    ),
  );
}

/// Pregunta si se quiere avanzar con un temporizador en marcha.
/// Devuelve true si el usuario elige avanzar.
Future<bool> confirmarAvanceConTemporizador(BuildContext context) async {
  final respuesta = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      icon: const Icon(Icons.timer, size: Medida.iconoAviso),
      title: const Text('El temporizador sigue en marcha'),
      content: const Text(
        '¿Quieres pasar al siguiente paso igualmente? '
        'El temporizador seguirá contando y te avisará al terminar.',
      ),
      actions: [
        OutlinedButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Quedarme'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Avanzar igualmente'),
        ),
      ],
    ),
  );
  return respuesta ?? false; // si se cierra tocando fuera, no avanzar
}

/// Recordatorio permanente de la alerta dentro del paso, para poder releerla.
class RecordatorioAlerta extends StatelessWidget {
  final Alerta alerta;

  const RecordatorioAlerta({super.key, required this.alerta});

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;

    return Card(
      color: colores.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(Espacio.normal),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.warning_amber_rounded, size: Medida.icono, color: colores.error),
            const SizedBox(width: Espacio.medio),
            Expanded(
              child: Text(
                alerta.mensaje,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colores.onErrorContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
