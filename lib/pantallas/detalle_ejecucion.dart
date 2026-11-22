// AeriS - Laboratory protocol assistant
// Copyright (C) 2026 Alejandro Pascual Hernández and contributors
// SPDX-License-Identifier: GPL-3.0-or-later
// Additional permission for app stores: see EXCEPCION_TIENDAS.md

import 'package:flutter/material.dart';
import 'package:aeris/modelos/calculo.dart';
import 'package:aeris/modelos/paso.dart';
import 'package:aeris/pantallas/cuaderno.dart';
import 'package:aeris/servicios/almacen.dart';

/// Página del cuaderno de una ejecución terminada: solo lectura.
class PantallaDetalleEjecucion extends StatelessWidget {
  final EntradaCuaderno entrada;

  const PantallaDetalleEjecucion({super.key, required this.entrada});

  /// El primer paso de cálculo del protocolo, si lo hay.
  PasoCalculo? get _pasoCalculo {
    for (final paso in entrada.protocolo.pasos) {
      if (paso is PasoCalculo) return paso;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final ejecucion = entrada.ejecucion;
    final protocolo = entrada.protocolo;
    final fin = ejecucion.fin;
    final paso = _pasoCalculo;
    final valores = ejecucion.valoresIntroducidos.entries
        .where((valor) => valor.value.trim().isNotEmpty)
        .toList();
    const texto = TextStyle(fontSize: 18);

    return Scaffold(
      appBar: AppBar(
        title: Text(protocolo.nombreCompleto),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('Inicio: ${formatearFechaHora(ejecucion.inicio)}', style: texto),
          if (fin != null) Text('Fin: ${formatearFechaHora(fin)}', style: texto),
          Text('Estado: ${ejecucion.estado.etiqueta}', style: texto),

          // ---------- Muestras: se recalcula lo que se pipeteó ----------
          if (paso != null && ejecucion.muestras.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text('Muestras', style: tema.textTheme.titleLarge),
            const SizedBox(height: 8),
            for (final resultado in paso.calcular(ejecucion.muestras).muestras)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(_describirMuestra(resultado, paso), style: texto),
              ),
          ],

          // ---------- Datos de la ejecución ----------
          if (valores.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text('Datos', style: tema.textTheme.titleLarge),
            const SizedBox(height: 8),
            for (final valor in valores) Text('${valor.key}: ${valor.value}', style: texto),
          ],

          // ---------- Pasos completados ----------
          const SizedBox(height: 24),
          Text('Pasos completados', style: tema.textTheme.titleLarge),
          const SizedBox(height: 8),
          for (final registro in ejecucion.registros)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                '${formatearFechaHora(registro.completadoEn)} · '
                '${registro.indicePaso < protocolo.numeroPasos ? protocolo.pasos[registro.indicePaso].titulo : 'Paso ${registro.indicePaso + 1}'}'
                '${registro.nota != null ? '\n   Nota: ${registro.nota}' : ''}',
                style: texto,
              ),
            ),
        ],
      ),
    );
  }

  String _describirMuestra(ResultadoMuestra resultado, PasoCalculo paso) {
    final muestra = resultado.muestra;
    final concentracion = muestra.concentracion;
    final cabecera = concentracion == null
        ? '${muestra.codigo} (${muestra.tipo})'
        : '${muestra.codigo} (${muestra.tipo}, ${formatearNumero(concentracion)} ng/µL)';
    final dna = resultado.volumenDna.toStringAsFixed(2);
    final agua = resultado.volumenAgua.toStringAsFixed(2);
    final factor = resultado.factorDilucion;

    return switch (resultado.estado) {
      EstadoMuestra.correcta => '$cabecera: $dna µL de DNA + $agua µL de agua',
      EstadoMuestra.diluir => factor == null
          ? '$cabecera: demasiado concentrada'
          : '$cabecera: diluida 1:$factor; $dna µL de DNA + $agua µL de agua',
      EstadoMuestra.huecoCompleto =>
        '$cabecera: hueco completo, ${formatearNumero(resultado.ngReales ?? 0)} ng '
            'en vez de ${formatearNumero(paso.ngObjetivo ?? 0)} ng',
      EstadoMuestra.sinConcentracion => '$cabecera: sin concentración',
    };
  }
}
