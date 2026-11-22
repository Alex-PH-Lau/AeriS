// AeriS - Laboratory protocol assistant
// Copyright (C) 2026 Alejandro Pascual Hernández and contributors
// SPDX-License-Identifier: GPL-3.0-or-later
// Additional permission for app stores: see EXCEPCION_TIENDAS.md

import 'package:flutter/material.dart';
import 'package:aeris/modelos/cuenta_atras.dart';

/// Temporizador de un paso: cuenta atrás grande y botones.
/// No guarda nada: la cuenta atrás vive en la pantalla de ejecución.
class VistaTemporizador extends StatelessWidget {
  final CuentaAtras cuenta;
  final VoidCallback onIniciar;
  final VoidCallback onPausar;
  final VoidCallback onReiniciar;

  const VistaTemporizador({
    super.key,
    required this.cuenta,
    required this.onIniciar,
    required this.onPausar,
    required this.onReiniciar,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final terminado = cuenta.terminado;
    final total = cuenta.duracion.inMilliseconds;
    final progreso = total == 0 ? 1.0 : 1 - cuenta.restante.inMilliseconds / total;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.timer, size: 28),
                const SizedBox(width: 8),
                Text(
                  'Temporizador · ${formatearTiempo(cuenta.duracion.inSeconds)}',
                  style: tema.textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              terminado ? '¡Tiempo!' : formatearTiempo(cuenta.segundosMostrados),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 72,
                fontWeight: FontWeight.bold,
                // Cifras del mismo ancho: el número no "baila" al cambiar
                fontFeatures: const [FontFeature.tabularFigures()],
                color: terminado ? tema.colorScheme.error : null,
              ),
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(value: progreso, minHeight: 8),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 64,
                    child: cuenta.enMarcha && !terminado
                        ? FilledButton.icon(
                            onPressed: onPausar,
                            icon: const Icon(Icons.pause, size: 28),
                            label: const Text('Pausar', style: TextStyle(fontSize: 20)),
                          )
                        : FilledButton.icon(
                            onPressed: terminado ? null : onIniciar,
                            icon: const Icon(Icons.play_arrow, size: 28),
                            label: Text(
                              cuenta.sinEmpezar ? 'Iniciar' : 'Reanudar',
                              style: const TextStyle(fontSize: 20),
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: SizedBox(
                    height: 64,
                    child: OutlinedButton.icon(
                      onPressed: cuenta.sinEmpezar ? null : onReiniciar,
                      icon: const Icon(Icons.replay, size: 28),
                      label: const Text('Reiniciar', style: TextStyle(fontSize: 20)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
