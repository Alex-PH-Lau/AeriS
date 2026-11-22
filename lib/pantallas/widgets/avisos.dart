// AeriS - Laboratory protocol assistant
// Copyright (C) 2026 Alejandro Pascual Hernández and contributors
// SPDX-License-Identifier: GPL-3.0-or-later
// Additional permission for app stores: see EXCEPCION_TIENDAS.md

import 'package:flutter/material.dart';
import 'package:aeris/modelos/paso.dart';

/// Alerta de un paso crítico: ventana muy visible que no se cierra
/// hasta pulsar "Entendido" (ni tocando fuera, ni con el botón atrás).
Future<void> mostrarAlerta(BuildContext context, Alerta alerta) {
  final colores = Theme.of(context).colorScheme;

  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => PopScope(
      canPop: false, // el botón atrás de Android no la cierra
      child: AlertDialog(
        backgroundColor: colores.errorContainer,
        icon: Icon(Icons.warning_amber_rounded, size: 72, color: colores.error),
        title: Text(
          '¡Atención!',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: colores.onErrorContainer,
          ),
        ),
        content: Text(
          alerta.mensaje,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 24, color: colores.onErrorContainer),
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: colores.error,
              foregroundColor: colores.onError,
              minimumSize: const Size(double.infinity, 80),
            ),
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Entendido', style: TextStyle(fontSize: 24)),
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
      icon: const Icon(Icons.alarm, size: 72),
      title: const Text('¡Tiempo!', style: TextStyle(fontSize: 28)),
      content: Text(
        'Ha terminado el temporizador de "$tituloPaso".',
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 22),
      ),
      actions: [
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 72)),
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Entendido', style: TextStyle(fontSize: 22)),
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
      icon: const Icon(Icons.timer, size: 56),
      title: const Text('El temporizador sigue en marcha'),
      content: const Text(
        '¿Quieres pasar al siguiente paso igualmente? '
        'El temporizador seguirá contando y te avisará al terminar.',
        style: TextStyle(fontSize: 20),
      ),
      actions: [
        OutlinedButton(
          style: OutlinedButton.styleFrom(minimumSize: const Size(140, 64)),
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text('Quedarme', style: TextStyle(fontSize: 20)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(minimumSize: const Size(140, 64)),
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text('Avanzar igualmente', style: TextStyle(fontSize: 20)),
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
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.warning_amber_rounded, size: 32, color: colores.error),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                alerta.mensaje,
                style: TextStyle(
                  fontSize: 20,
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
