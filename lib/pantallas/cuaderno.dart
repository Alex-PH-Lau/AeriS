// AeriS - Laboratory protocol assistant
// Copyright (C) 2026 Alejandro Pascual Hernández and contributors
// SPDX-License-Identifier: GPL-3.0-or-later
// Additional permission for app stores: see EXCEPCION_TIENDAS.md

import 'package:flutter/material.dart';
import 'package:aeris/modelos/ejecucion.dart';
import 'package:aeris/pantallas/detalle_ejecucion.dart';
import 'package:aeris/pantallas/ejecucion.dart';
import 'package:aeris/servicios/almacen.dart';
import 'package:aeris/tema.dart';

/// "22/11/2026 10:30"
String formatearFechaHora(DateTime fecha) {
  String dos(int numero) => numero.toString().padLeft(2, '0');
  return '${dos(fecha.day)}/${dos(fecha.month)}/${fecha.year} '
      '${dos(fecha.hour)}:${dos(fecha.minute)}';
}

class PantallaCuaderno extends StatefulWidget {
  const PantallaCuaderno({super.key});

  @override
  State<PantallaCuaderno> createState() => _PantallaCuadernoState();
}

class _PantallaCuadernoState extends State<PantallaCuaderno> {
  late Future<List<EntradaCuaderno>> _entradas = almacen.cuaderno();

  void _recargar() {
    setState(() {
      _entradas = almacen.cuaderno();
    });
  }

  Future<void> _abrir(EntradaCuaderno entrada) async {
    final enProceso = entrada.ejecucion.estado == EstadoEjecucion.enProceso;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => enProceso
            ? PantallaEjecucion(protocolo: entrada.protocolo, continuar: entrada)
            : PantallaDetalleEjecucion(entrada: entrada),
      ),
    );
    if (!mounted) return;
    _recargar(); // al volver puede haber cambiado (paso nuevo, terminada…)
  }

  Future<void> _descartar(EntradaCuaderno entrada) async {
    final colores = Theme.of(context).colorScheme;
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(Icons.delete_forever, size: Medida.iconoAviso, color: colores.error),
        title: const Text('¿Descartar esta ejecución?'),
        content: const Text(
          'Se borrará del cuaderno y no se podrá recuperar.',
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: colores.error,
              foregroundColor: colores.onError,
            ),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Descartar'),
          ),
        ],
      ),
    );
    if (confirmado != true) return;

    await almacen.borrarEjecucion(entrada.id);
    if (!mounted) return;
    _recargar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cuaderno de laboratorio'),
      ),
      body: FutureBuilder<List<EntradaCuaderno>>(
        future: _entradas,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('No se pudo leer el cuaderno: ${snapshot.error}'));
          }
          final entradas = snapshot.data;
          if (entradas == null) {
            return const Center(child: CircularProgressIndicator());
          }
          if (entradas.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(Espacio.extra),
                child: Text(
                  'Todavía no hay ejecuciones. Cuando ejecutes un protocolo, aparecerá aquí.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(Espacio.normal),
            itemCount: entradas.length,
            itemBuilder: (context, indice) {
              final entrada = entradas[indice];
              return _TarjetaEntrada(
                entrada: entrada,
                onAbrir: () => _abrir(entrada),
                onDescartar: () => _descartar(entrada),
              );
            },
          );
        },
      ),
    );
  }
}

class _TarjetaEntrada extends StatelessWidget {
  final EntradaCuaderno entrada;
  final VoidCallback onAbrir;
  final VoidCallback onDescartar;

  const _TarjetaEntrada({
    required this.entrada,
    required this.onAbrir,
    required this.onDescartar,
  });

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    final ejecucion = entrada.ejecucion;
    final enProceso = ejecucion.estado == EstadoEjecucion.enProceso;
    final numMuestras = ejecucion.muestras.length;

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: Espacio.grande, vertical: Espacio.medio),
        leading: Icon(
          enProceso ? Icons.pending_actions : Icons.task_alt,
          size: Medida.iconoGrande,
          color: enProceso ? Colors.orange.shade800 : colores.primary,
        ),
        title: Text(entrada.protocolo.nombreCompleto),
        subtitle: Text(
          '${formatearFechaHora(ejecucion.inicio)} · ${ejecucion.estado.etiqueta}'
          '${numMuestras > 0 ? ' · $numMuestras muestras' : ''}',
        ),
        trailing: enProceso
            ? IconButton(
                tooltip: 'Descartar',
                onPressed: onDescartar,
                icon: const Icon(Icons.delete_outline),
              )
            : const Icon(Icons.chevron_right, size: Medida.iconoGrande),
        onTap: onAbrir,
      ),
    );
  }
}
