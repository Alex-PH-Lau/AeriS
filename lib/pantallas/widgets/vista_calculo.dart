// AeriS - Laboratory protocol assistant
// Copyright (C) 2026 Alejandro Pascual Hernández and contributors
// SPDX-License-Identifier: GPL-3.0-or-later
// Additional permission for app stores: see EXCEPCION_TIENDAS.md

import 'package:flutter/material.dart';
import 'package:aeris/modelos/calculo.dart';
import 'package:aeris/modelos/entradas.dart';
import 'package:aeris/modelos/paso.dart';

/// Contenido de un paso de cálculo: tabla de muestras, datos de la ejecución
/// y resultado. No guarda nada: lo recibe de la pantalla y le avisa de cada cambio.
class VistaCalculo extends StatelessWidget {
  final PasoCalculo paso;
  final List<Muestra> muestras;
  final Map<String, String> valores;
  final void Function(String clave, String valor) onCambioValor;
  final void Function(int indice, Muestra muestra) onCambioMuestra;
  final void Function(String tipo) onAnadirMuestra;
  final void Function(int indice) onEliminarMuestra;

  const VistaCalculo({
    super.key,
    required this.paso,
    required this.muestras,
    required this.valores,
    required this.onCambioValor,
    required this.onCambioMuestra,
    required this.onAnadirMuestra,
    required this.onEliminarMuestra,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final resultado = paso.calcular(muestras);
    final problema = problemaCalculo(paso, muestras, valores);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ---------- Muestras ----------
        Text('Muestras', style: tema.textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(
          paso.modo == ModoMolde.normalizado
              ? '${formatearNumero(paso.ngObjetivo ?? 0)} ng de DNA por reacción · '
                  'hueco de ${formatearMicrolitros(paso.volumenMolde)} µL'
              : '${formatearMicrolitros(paso.volumenMolde)} µL de DNA en cada tubo',
          style: tema.textTheme.bodyLarge,
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < muestras.length; i++)
          _TarjetaMuestra(
            key: ValueKey(muestras[i].id),
            muestra: muestras[i],
            resultado: resultado.muestras[i],
            paso: paso,
            sePuedeQuitar: paso.tipoTubo(muestras[i].tipo)?.filasLibres ?? false,
            onCambio: (muestra) => onCambioMuestra(i, muestra),
            onQuitar: () => onEliminarMuestra(i),
          ),
        for (final tipo in paso.tiposTubo)
          if (tipo.filasLibres)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: SizedBox(
                height: 64,
                child: OutlinedButton.icon(
                  onPressed: () => onAnadirMuestra(tipo.nombre),
                  icon: const Icon(Icons.add, size: 28),
                  label: Text(
                    'Añadir ${tipo.nombre.toLowerCase()}',
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
            ),

        // ---------- Datos de la ejecución ----------
        if (paso.parametros.isNotEmpty) ...[
          const SizedBox(height: 32),
          Text('Datos de esta ejecución', style: tema.textTheme.titleLarge),
          const SizedBox(height: 16),
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
              onChanged: (texto) => onCambioValor(parametro.nombre, texto),
            ),
            const SizedBox(height: 16),
          ],
        ],

        // ---------- Mastermix ----------
        const SizedBox(height: 24),
        if (muestras.isNotEmpty) _VistaMastermix(paso: paso, resultado: resultado, muestras: muestras),

        // ---------- Por qué no se puede avanzar ----------
        if (problema != null) ...[
          const SizedBox(height: 16),
          Text(
            problema,
            style: tema.textTheme.titleMedium?.copyWith(color: tema.colorScheme.error),
          ),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------

class _TarjetaMuestra extends StatelessWidget {
  final Muestra muestra;
  final ResultadoMuestra resultado;
  final PasoCalculo paso;
  final bool sePuedeQuitar;
  final void Function(Muestra muestra) onCambio;
  final VoidCallback onQuitar;

  const _TarjetaMuestra({
    super.key,
    required this.muestra,
    required this.resultado,
    required this.paso,
    required this.sePuedeQuitar,
    required this.onCambio,
    required this.onQuitar,
  });

  @override
  Widget build(BuildContext context) {
    final concentracion = muestra.concentracion;
    final normalizado = paso.modo == ModoMolde.normalizado;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    key: ValueKey('codigo-${muestra.id}'),
                    initialValue: muestra.codigo,
                    decoration: InputDecoration(
                      labelText: 'Código · ${muestra.tipo}',
                      border: const OutlineInputBorder(),
                    ),
                    style: const TextStyle(fontSize: 22),
                    onChanged: (texto) => onCambio(Muestra(
                      id: muestra.id,
                      tipo: muestra.tipo,
                      codigo: texto,
                      concentracion: muestra.concentracion,
                    )),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    key: ValueKey('conc-${muestra.id}'),
                    initialValue: concentracion == null ? '' : formatearNumero(concentracion),
                    decoration: InputDecoration(
                      labelText: normalizado ? 'ng/µL' : 'ng/µL · opcional',
                      border: const OutlineInputBorder(),
                    ),
                    style: const TextStyle(fontSize: 22),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (texto) => onCambio(Muestra(
                      id: muestra.id,
                      tipo: muestra.tipo,
                      codigo: muestra.codigo,
                      concentracion: leerNumero(texto),
                    )),
                  ),
                ),
                if (sePuedeQuitar)
                  IconButton(
                    iconSize: 32,
                    tooltip: 'Quitar muestra',
                    onPressed: onQuitar,
                    icon: const Icon(Icons.delete_outline),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _lineaResultado(context),
          ],
        ),
      ),
    );
  }

  Widget _lineaResultado(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    final dna = resultado.volumenDna.toStringAsFixed(2);
    final agua = resultado.volumenAgua.toStringAsFixed(2);
    final factor = resultado.factorDilucion;
    final concentracion = muestra.concentracion ?? 0;

    return switch (resultado.estado) {
      EstadoMuestra.correcta => _linea(
          Icons.check_circle,
          colores.primary,
          resultado.volumenAgua > 0
              ? '$dna µL de DNA + $agua µL de agua'
              : '$dna µL de DNA',
        ),
      EstadoMuestra.diluir => factor == null
          ? _linea(
              Icons.error,
              colores.error,
              'Demasiado concentrada: diluye más de 1:100 y vuelve a medir.',
            )
          : _linea(
              Icons.warning_amber,
              Colors.orange.shade800,
              'Diluye 1:$factor (quedará a ${formatearNumero(concentracion / factor)} ng/µL) '
              'y pon $dna µL de DNA + $agua µL de agua',
            ),
      EstadoMuestra.huecoCompleto => _linea(
          Icons.info,
          Colors.orange.shade800,
          'Poco concentrada: pon $dna µL '
          '(${formatearNumero(resultado.ngReales ?? 0)} ng en vez de '
          '${formatearNumero(paso.ngObjetivo ?? 0)} ng). Quedará anotado.',
        ),
      EstadoMuestra.sinConcentracion => _linea(
          Icons.edit,
          colores.outline,
          'Introduce la concentración.',
        ),
    };
  }

  Widget _linea(IconData icono, Color color, String texto) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icono, color: color, size: 28),
        const SizedBox(width: 8),
        Expanded(
          child: Text(texto, style: TextStyle(fontSize: 20, color: color)),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------

class _VistaMastermix extends StatelessWidget {
  final PasoCalculo paso;
  final ResultadoMastermix resultado;
  final List<Muestra> muestras;

  const _VistaMastermix({
    required this.paso,
    required this.resultado,
    required this.muestras,
  });

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    // Primero comprobar; solo si es válido, mostrar volúmenes (lección 1)
    if (!resultado.esValido) {
      return Card(
        color: tema.colorScheme.errorContainer,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            'Los reactivos y el hueco suman más que el volumen de reacción '
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
            _fila(
              'Agua (en el mix)',
              '',
              (resultado.volumenesTotales['Agua'] ?? 0).toStringAsFixed(2),
            ),
            _fila('Total', '', resultado.volumenTotal.toStringAsFixed(2), negrita: true),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          'Reparte $mixPorTubo µL de mastermix en cada tubo y añade:',
          style: tema.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        for (final tipo in paso.tiposTubo)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              tipo.conDna
                  ? '• ${muestras.where((m) => m.tipo == tipo.nombre).length} × '
                      '${tipo.nombre}: el DNA y el agua de su tarjeta'
                  : '• ${tipo.cantidadFija ?? 0} × ${tipo.nombre}: '
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
