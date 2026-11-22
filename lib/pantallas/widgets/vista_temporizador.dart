// AeriS - Laboratory protocol assistant
// Copyright (C) 2026 Alejandro Pascual Hernández and contributors
// SPDX-License-Identifier: GPL-3.0-or-later
// Additional permission for app stores: see EXCEPCION_TIENDAS.md

import 'package:flutter/material.dart';
import 'package:aeris/modelos/cuenta_atras.dart';
import 'package:aeris/tema.dart';

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
        padding: const EdgeInsets.all(Espacio.grande),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.timer, size: Medida.icono),
                const SizedBox(width: Espacio.pequeno),
                Text(
                  'Temporizador · ${formatearTiempo(cuenta.duracion.inSeconds)}',
                  style: tema.textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: Espacio.pequeno),
            Text(
              terminado ? '¡Tiempo!' : formatearTiempo(cuenta.segundosMostrados),
              textAlign: TextAlign.center,
              style: EstiloTexto.reloj.copyWith(
                color: terminado ? tema.colorScheme.error : null,
              ),
            ),
            const SizedBox(height: Espacio.pequeno),
            LinearProgressIndicator(value: progreso, minHeight: 8),
            const SizedBox(height: Espacio.normal),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: Medida.boton,
                    child: cuenta.enMarcha && !terminado
                        ? FilledButton.icon(
                            onPressed: onPausar,
                            icon: const Icon(Icons.pause),
                            label: const Text('Pausar'),
                          )
                        : FilledButton.icon(
                            onPressed: terminado ? null : onIniciar,
                            icon: const Icon(Icons.play_arrow),
                            label: Text(cuenta.sinEmpezar ? 'Iniciar' : 'Reanudar'),
                          ),
                  ),
                ),
                const SizedBox(width: Espacio.normal),
                Expanded(
                  child: SizedBox(
                    height: Medida.boton,
                    child: OutlinedButton.icon(
                      onPressed: cuenta.sinEmpezar ? null : onReiniciar,
                      icon: const Icon(Icons.replay),
                      label: const Text('Reiniciar'),
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
