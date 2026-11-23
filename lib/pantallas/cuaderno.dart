// AeriS - Laboratory protocol assistant
// Copyright (C) 2026 Alejandro Pascual Hernández and contributors
// SPDX-License-Identifier: GPL-3.0-or-later
// Additional permission for app stores: see EXCEPCION_TIENDAS.md

import 'package:flutter/material.dart';
import 'package:aeris/modelos/ejecucion.dart';
import 'package:aeris/pantallas/detalle_ejecucion.dart';
import 'package:aeris/pantallas/ejecucion.dart';
import 'package:aeris/servicios/almacen.dart';
import 'package:aeris/servicios/archivos.dart';
import 'package:aeris/servicios/copia_seguridad.dart';
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

  // ---------- Copia de seguridad ----------

  Future<void> _guardarCopia(Rect? origen) async {
    try {
      final ahora = DateTime.now();
      await archivos.compartirTexto(
        nombreArchivo: nombreArchivoCopia(ahora),
        contenido: await crearCopia(almacen, ahora: ahora),
        origen: origen,
      );
    } catch (error) {
      if (mounted) _avisar('No se pudo crear la copia: $error');
    }
  }

  Future<void> _restaurar() async {
    try {
      final texto = await archivos.elegirTexto();
      if (texto == null) return; // cancelado
      final resumen = await restaurarCopia(texto, almacen);
      if (!mounted) return;
      _recargar();
      await _mostrarResumen(resumen);
    } on FormatException catch (error) {
      if (mounted) {
        await _mostrarMensaje(
          icono: Icons.error_outline,
          titulo: 'No se pudo restaurar',
          lineas: [error.message],
        );
      }
    }
  }

  Future<void> _mostrarResumen(ResumenRestauracion resumen) {
    return _mostrarMensaje(
      icono: resumen.sinCambios ? Icons.info_outline : Icons.restore,
      titulo: resumen.sinCambios ? 'No había nada nuevo' : 'Copia restaurada',
      lineas: resumen.sinCambios && resumen.lineas.isEmpty
          ? ['La copia estaba vacía.']
          : resumen.lineas,
    );
  }

  Future<void> _mostrarMensaje({
    required IconData icono,
    required String titulo,
    required List<String> lineas,
  }) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(icono, size: Medida.iconoAviso),
        title: Text(titulo),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final linea in lineas)
              Padding(
                padding: const EdgeInsets.only(bottom: Espacio.pequeno),
                child: Text(linea),
              ),
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  void _avisar(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  // ---------- Entradas ----------

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
        actions: [
          // Builder: context del botón, para que en iPad el menú apunte a él
          Builder(
            builder: (contextoBoton) => PopupMenuButton<String>(
              tooltip: 'Copia de seguridad',
              icon: const Icon(Icons.backup),
              onSelected: (opcion) {
                if (opcion == 'restaurar') {
                  _restaurar();
                } else {
                  final caja = contextoBoton.findRenderObject() as RenderBox?;
                  _guardarCopia(caja == null ? null : caja.localToGlobal(Offset.zero) & caja.size);
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'guardar',
                  height: Medida.fila,
                  child: ListTile(
                    leading: Icon(Icons.upload_file),
                    title: Text('Guardar copia de seguridad'),
                    subtitle: Text('Protocolos y cuaderno en un archivo'),
                  ),
                ),
                PopupMenuItem(
                  value: 'restaurar',
                  height: Medida.fila,
                  child: ListTile(
                    leading: Icon(Icons.settings_backup_restore),
                    title: Text('Restaurar una copia'),
                    subtitle: Text('Añade lo que falte; no borra nada'),
                  ),
                ),
              ],
            ),
          ),
        ],
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
