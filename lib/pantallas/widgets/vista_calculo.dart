// AeriS - Laboratory protocol assistant
// Copyright (C) 2026 Alejandro Pascual Hernández and contributors
// SPDX-License-Identifier: GPL-3.0-or-later
// Additional permission for app stores: see EXCEPCION_TIENDAS.md

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:aeris/modelos/calculo.dart';
import 'package:aeris/modelos/entradas.dart';
import 'package:aeris/modelos/paso.dart';

/// Contenido de un paso de cálculo: campos de entrada y resultado.
/// No guarda los valores: los recibe de la pantalla y le avisa de cada cambio.
class VistaCalculo extends StatelessWidget {
  final PasoCalculo paso;
  final Map<String, String> valores;
  final void Function(String clave, String valor) onCambio;

  const VistaCalculo({
    super.key,
    required this.paso,
    required this.valores,
    required this.onCambio,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final cantidades = cantidadesIntroducidas(paso, valores);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('Datos de esta ejecución', style: tema.textTheme.titleLarge),
        const SizedBox(height: 16),

        // Un campo por cada tipo de tubo cuya cantidad se pregunta
        for (final tipo in paso.tubosQueSePreguntan) ...[
          TextFormField(
            key: ValueKey('tubos-${tipo.nombre}'),
            initialValue: valores[tipo.nombre],
            decoration: InputDecoration(
              labelText: 'Número de tubos: ${tipo.nombre}',
              border: const OutlineInputBorder(),
            ),
            style: const TextStyle(fontSize: 22),
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (texto) => onCambio(tipo.nombre, texto),
          ),
          const SizedBox(height: 16),
        ],

        // Un campo por cada parámetro de entrada
        for (final parametro in paso.parametros) ...[
          TextFormField(
            key: ValueKey('param-${parametro.nombre}'),
            initialValue: valores[parametro.nombre],
            decoration: InputDecoration(
              labelText: etiquetaParametro(parametro),
              border: const OutlineInputBorder(),
            ),
            style: const TextStyle(fontSize: 22),
            keyboardType: parametro.tipo == TipoParametro.numero
                ? const TextInputType.numberWithOptions(decimal: true)
                : TextInputType.text,
            onChanged: (texto) => onCambio(parametro.nombre, texto),
          ),
          const SizedBox(height: 16),
        ],

        const SizedBox(height: 8),
        if (cantidades == null)
          Text(
            'Introduce el número de tubos para ver el cálculo.',
            style: tema.textTheme.titleMedium,
          )
        else ...[
          _ResultadoCalculo(paso: paso, cantidades: cantidades),
          if (!parametrosCompletos(paso, valores)) ...[
            const SizedBox(height: 16),
            Text(
              'Rellena los datos obligatorios para continuar.',
              style: tema.textTheme.titleMedium,
            ),
          ],
        ],
      ],
    );
  }
}

class _ResultadoCalculo extends StatelessWidget {
  final PasoCalculo paso;
  final Map<String, int> cantidades;

  const _ResultadoCalculo({required this.paso, required this.cantidades});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final resultado = paso.calcular(cantidades);

    // Primero comprobar; solo si es válido, mostrar volúmenes (lección 1)
    if (!resultado.esValido) {
      return Card(
        color: tema.colorScheme.errorContainer,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Los reactivos y el molde suman más que el volumen de reacción '
            '(${formatearMicrolitros(paso.volumenReaccion)} µL). '
            'Sobran ${(-resultado.aguaPorTubo).toStringAsFixed(2)} µL por tubo. '
            'Revisa el protocolo.',
            style: TextStyle(fontSize: 20, color: tema.colorScheme.onErrorContainer),
          ),
        ),
      );
    }

    final porcentaje = ((paso.margen - 1) * 100).toStringAsFixed(0);
    final mixPorTubo = formatearMicrolitros(paso.volumenReaccion - paso.volumenMolde);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mastermix para ${resultado.totalTubos} tubos (+$porcentaje %)',
          style: tema.textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        Table(
          columnWidths: const {
            0: FlexColumnWidth(2),
            1: FlexColumnWidth(1),
            2: IntrinsicColumnWidth(),
          },
          border: TableBorder(
            horizontalInside: BorderSide(color: tema.dividerColor),
          ),
          children: [
            _fila('Reactivo', 'Conc.', 'µL', negrita: true),
            for (final reactivo in paso.reactivos)
              _fila(
                reactivo.nombre,
                reactivo.concentracion ?? '',
                (resultado.volumenesTotales[reactivo.nombre] ?? 0).toStringAsFixed(2),
              ),
            _fila('Agua', '', (resultado.volumenesTotales['Agua'] ?? 0).toStringAsFixed(2)),
            _fila('Total', '', resultado.volumenTotal.toStringAsFixed(2), negrita: true),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'Reparte $mixPorTubo µL en cada tubo y añade:',
          style: tema.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        for (final tipo in paso.tiposTubo)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              '• ${tipo.cantidadFija ?? cantidades[tipo.nombre]} × ${tipo.nombre}: '
              '${tipo.instruccion(paso.volumenMolde)}',
              style: const TextStyle(fontSize: 20),
            ),
          ),
      ],
    );
  }

  TableRow _fila(String reactivo, String concentracion, String volumen, {bool negrita = false}) {
    final estilo = TextStyle(
      fontSize: 20,
      fontWeight: negrita ? FontWeight.bold : FontWeight.normal,
    );

    Widget celda(String texto, {TextAlign alineacion = TextAlign.left}) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        child: Text(texto, style: estilo, textAlign: alineacion),
      );
    }

    return TableRow(
      children: [
        celda(reactivo),
        celda(concentracion),
        celda(volumen, alineacion: TextAlign.right),
      ],
    );
  }
}
