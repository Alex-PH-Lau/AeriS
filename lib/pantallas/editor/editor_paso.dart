// AeriS - Laboratory protocol assistant
// Copyright (C) 2026 Alejandro Pascual Hernández and contributors
// SPDX-License-Identifier: GPL-3.0-or-later
// Additional permission for app stores: see EXCEPCION_TIENDAS.md

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:aeris/modelos/entradas.dart';
import 'package:aeris/modelos/paso.dart';

/// Formulario de un paso. No sabe si está en la mitad derecha de una tablet
/// o en una pantalla de móvil: eso lo decide quien lo contiene.
class EditorPaso extends StatelessWidget {
  final Paso paso;
  final ValueChanged<Paso> onCambio;

  const EditorPaso({super.key, required this.paso, required this.onCambio});

  @override
  Widget build(BuildContext context) {
    return switch (paso) {
      PasoInstrucciones p => _EditorInstrucciones(paso: p, onCambio: onCambio),
      PasoCalculo() => const _AvisoCalculo(),
    };
  }
}

class _EditorInstrucciones extends StatelessWidget {
  final PasoInstrucciones paso;
  final ValueChanged<Paso> onCambio;

  const _EditorInstrucciones({required this.paso, required this.onCambio});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final temporizador = paso.temporizador;
    final alerta = paso.alerta;
    const estilo = TextStyle(fontSize: 20);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextFormField(
          initialValue: paso.titulo,
          decoration: const InputDecoration(
            labelText: 'Título del paso',
            border: OutlineInputBorder(),
          ),
          style: estilo,
          onChanged: (texto) => onCambio(paso.copiar(titulo: texto)),
        ),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: paso.texto,
          decoration: const InputDecoration(
            labelText: 'Texto del paso',
            hintText: 'Qué hay que hacer en este paso',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
          style: estilo,
          minLines: 4,
          maxLines: null, // crece con el texto
          onChanged: (texto) => onCambio(paso.copiar(texto: texto)),
        ),

        // ---------- Herramientas del paso ----------
        const SizedBox(height: 32),
        Text('Herramientas del paso', style: tema.textTheme.titleLarge),
        const SizedBox(height: 8),

        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          secondary: const Icon(Icons.timer, size: 32),
          title: const Text('Temporizador', style: estilo),
          value: temporizador != null,
          onChanged: (activar) => onCambio(
            activar
                ? paso.copiar(temporizador: const Temporizador(Duration(minutes: 5)))
                : paso.copiar(sinTemporizador: true),
          ),
        ),
        if (temporizador != null) _CamposDuracion(
          duracion: temporizador.duracion,
          onCambio: (duracion) => onCambio(paso.copiar(temporizador: Temporizador(duracion))),
        ),

        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          secondary: Icon(Icons.warning_amber_rounded, size: 32, color: tema.colorScheme.error),
          title: const Text('Alerta', style: estilo),
          subtitle: const Text('Ventana que no deja seguir sin pulsar "Entendido"'),
          value: alerta != null,
          onChanged: (activar) => onCambio(
            activar ? paso.copiar(alerta: const Alerta('')) : paso.copiar(sinAlerta: true),
          ),
        ),
        if (alerta != null)
          TextFormField(
            initialValue: alerta.mensaje,
            decoration: const InputDecoration(
              labelText: 'Mensaje de la alerta',
              hintText: 'Por ejemplo: mantén la enzima en hielo',
              border: OutlineInputBorder(),
            ),
            style: estilo,
            maxLines: null,
            onChanged: (texto) => onCambio(paso.copiar(alerta: Alerta(texto))),
          ),
      ],
    );
  }
}

/// Minutos y segundos de un temporizador.
class _CamposDuracion extends StatelessWidget {
  final Duration duracion;
  final ValueChanged<Duration> onCambio;

  const _CamposDuracion({required this.duracion, required this.onCambio});

  @override
  Widget build(BuildContext context) {
    final minutos = duracion.inMinutes;
    final segundos = duracion.inSeconds % 60;

    Widget campo(String etiqueta, int valor, ValueChanged<int> alCambiar) {
      return TextFormField(
        initialValue: '$valor',
        decoration: InputDecoration(labelText: etiqueta, border: const OutlineInputBorder()),
        style: const TextStyle(fontSize: 22),
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        onChanged: (texto) => alCambiar(leerEntero(texto) ?? 0),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(left: 56, bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: campo('Minutos', minutos, (m) {
              onCambio(Duration(minutes: m, seconds: segundos));
            }),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: campo('Segundos', segundos, (s) {
              onCambio(Duration(minutes: minutos, seconds: s));
            }),
          ),
        ],
      ),
    );
  }
}

class _AvisoCalculo extends StatelessWidget {
  const _AvisoCalculo();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Row(
          children: [
            Icon(Icons.calculate, size: 40),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                'Paso de cálculo de reactivos. Su editor llegará en la próxima lección; '
                'de momento puedes moverlo o borrarlo.',
                style: TextStyle(fontSize: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
