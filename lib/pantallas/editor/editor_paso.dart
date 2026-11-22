// AeriS - Laboratory protocol assistant
// Copyright (C) 2026 Alejandro Pascual Hernández and contributors
// SPDX-License-Identifier: GPL-3.0-or-later
// Additional permission for app stores: see EXCEPCION_TIENDAS.md

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:aeris/modelos/calculo.dart';
import 'package:aeris/modelos/entradas.dart';
import 'package:aeris/modelos/paso.dart';
import 'package:aeris/pantallas/editor/editor_calculo.dart';

const _estilo = TextStyle(fontSize: 20);

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
      PasoCalculo p => EditorCalculo(paso: p, onCambio: onCambio),
    };
  }
}

class _EditorInstrucciones extends StatelessWidget {
  final PasoInstrucciones paso;
  final ValueChanged<Paso> onCambio;

  const _EditorInstrucciones({required this.paso, required this.onCambio});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CampoTitulo(titulo: paso.titulo, onCambio: (t) => onCambio(paso.copiar(titulo: t))),
        const SizedBox(height: 16),
        TextFormField(
          initialValue: paso.texto,
          decoration: const InputDecoration(
            labelText: 'Texto del paso',
            hintText: 'Qué hay que hacer en este paso',
            border: OutlineInputBorder(),
            alignLabelWithHint: true,
          ),
          style: _estilo,
          minLines: 4,
          maxLines: null, // crece con el texto
          onChanged: (texto) => onCambio(paso.copiar(texto: texto)),
        ),
        const SizedBox(height: 32),
        SeccionHerramientas(
          temporizador: paso.temporizador,
          alerta: paso.alerta,
          onTemporizador: (t) => onCambio(
            t == null ? paso.copiar(sinTemporizador: true) : paso.copiar(temporizador: t),
          ),
          onAlerta: (a) => onCambio(
            a == null ? paso.copiar(sinAlerta: true) : paso.copiar(alerta: a),
          ),
        ),
      ],
    );
  }
}

/// Campo del título, igual en todos los tipos de paso.
class CampoTitulo extends StatelessWidget {
  final String titulo;
  final ValueChanged<String> onCambio;

  const CampoTitulo({super.key, required this.titulo, required this.onCambio});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: titulo,
      decoration: const InputDecoration(
        labelText: 'Título del paso',
        border: OutlineInputBorder(),
      ),
      style: _estilo,
      onChanged: onCambio,
    );
  }
}

/// Temporizador y alerta: las herramientas que puede llevar cualquier paso.
/// Avisa con null cuando se quita una herramienta.
class SeccionHerramientas extends StatelessWidget {
  final Temporizador? temporizador;
  final Alerta? alerta;
  final ValueChanged<Temporizador?> onTemporizador;
  final ValueChanged<Alerta?> onAlerta;

  const SeccionHerramientas({
    super.key,
    required this.temporizador,
    required this.alerta,
    required this.onTemporizador,
    required this.onAlerta,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final temporizador = this.temporizador;
    final alerta = this.alerta;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Herramientas del paso', style: tema.textTheme.titleLarge),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          secondary: const Icon(Icons.timer, size: 32),
          title: const Text('Temporizador', style: _estilo),
          value: temporizador != null,
          onChanged: (activar) => onTemporizador(
            activar ? const Temporizador(Duration(minutes: 5)) : null,
          ),
        ),
        if (temporizador != null)
          _CamposDuracion(
            duracion: temporizador.duracion,
            onCambio: (duracion) => onTemporizador(Temporizador(duracion)),
          ),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          secondary: Icon(Icons.warning_amber_rounded, size: 32, color: tema.colorScheme.error),
          title: const Text('Alerta', style: _estilo),
          subtitle: const Text('Ventana que no deja seguir sin pulsar "Entendido"'),
          value: alerta != null,
          onChanged: (activar) => onAlerta(activar ? const Alerta('') : null),
        ),
        if (alerta != null)
          TextFormField(
            initialValue: alerta.mensaje,
            decoration: const InputDecoration(
              labelText: 'Mensaje de la alerta',
              hintText: 'Por ejemplo: mantén la enzima en hielo',
              border: OutlineInputBorder(),
            ),
            style: _estilo,
            maxLines: null,
            onChanged: (texto) => onAlerta(Alerta(texto)),
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

/// Campo para un número con decimales (acepta coma o punto).
/// Solo avisa cuando el texto es un número válido; si no, lo marca en rojo.
class CampoNumero extends StatelessWidget {
  final String etiqueta;
  final double? valor;
  final ValueChanged<double> onCambio;
  final String? ayuda;

  const CampoNumero({
    super.key,
    required this.etiqueta,
    required this.valor,
    required this.onCambio,
    this.ayuda,
  });

  @override
  Widget build(BuildContext context) {
    final valor = this.valor;
    return TextFormField(
      initialValue: valor == null ? '' : formatearNumero(valor),
      decoration: InputDecoration(
        labelText: etiqueta,
        helperText: ayuda,
        border: const OutlineInputBorder(),
      ),
      style: _estilo,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      autovalidateMode: AutovalidateMode.onUserInteraction,
      validator: (texto) => leerNumero(texto) == null ? 'Escribe un número' : null,
      onChanged: (texto) {
        final numero = leerNumero(texto);
        if (numero != null) onCambio(numero);
      },
    );
  }
}
