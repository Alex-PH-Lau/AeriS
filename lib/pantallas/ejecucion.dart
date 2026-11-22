// AeriS - Laboratory protocol assistant
// Copyright (C) 2026 Alejandro Pascual Hernández and contributors
// SPDX-License-Identifier: GPL-3.0-or-later
// Additional permission for app stores: see EXCEPCION_TIENDAS.md

import 'package:flutter/material.dart';
import 'package:aeris/modelos/protocolo.dart';

class PantallaEjecucion extends StatefulWidget {
  final Protocolo protocolo;

  const PantallaEjecucion({super.key, required this.protocolo});

  @override
  State<PantallaEjecucion> createState() => _PantallaEjecucionState();
}

class _PantallaEjecucionState extends State<PantallaEjecucion> {
  int pasoActual = 0;

  void siguiente() {
    // Seguro: no pasar del último paso
    if (pasoActual >= widget.protocolo.numeroPasos - 1) return;
    setState(() {
      pasoActual++;
    });
  }

  void anterior() {
    // Seguro: no bajar del primer paso
    if (pasoActual <= 0) return;
    setState(() {
      pasoActual--;
    });
  }

  Future<void> terminar() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false, // no se cierra tocando fuera
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.check_circle, size: 64),
        title: const Text('¡Protocolo completado!'),
        content: Text(
          'Has terminado "${widget.protocolo.nombreCompleto}".',
          style: const TextStyle(fontSize: 18),
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 72),
            ),
            onPressed: () => Navigator.pop(dialogContext), // 1er pop: cierra el diálogo
            child: const Text('Volver', style: TextStyle(fontSize: 22)),
          ),
        ],
      ),
    );

    if (!mounted) return;
    Navigator.pop(context); // 2º pop: vuelve a la lista
  }

  @override
  Widget build(BuildContext context) {
    final protocolo = widget.protocolo;
    final total = protocolo.numeroPasos;
    final esPrimero = pasoActual == 0;
    final esUltimo = pasoActual == total - 1;

    return Scaffold(
      appBar: AppBar(
        title: Text(protocolo.nombreCompleto),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Paso ${pasoActual + 1} de $total',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: (pasoActual + 1) / total,
                minHeight: 12,
              ),
              const SizedBox(height: 32),
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    protocolo.pasos[pasoActual],
                    style: const TextStyle(fontSize: 26, height: 1.4),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 96,
                      child: OutlinedButton.icon(
                        onPressed: esPrimero ? null : anterior,
                        icon: const Icon(Icons.arrow_back, size: 32),
                        label: const Text('Anterior', style: TextStyle(fontSize: 22)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SizedBox(
                      height: 96,
                      child: FilledButton.icon(
                        onPressed: esUltimo ? terminar : siguiente,
                        icon: Icon(esUltimo ? Icons.check : Icons.arrow_forward, size: 32),
                        label: Text(
                          esUltimo ? 'Terminar' : 'Siguiente',
                          style: const TextStyle(fontSize: 22),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}