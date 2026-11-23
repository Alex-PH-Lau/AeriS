// AeriS - Laboratory protocol assistant
// Copyright (C) 2026 Alejandro Pascual Hernández and contributors
// SPDX-License-Identifier: GPL-3.0-or-later
// Additional permission for app stores: see EXCEPCION_TIENDAS.md

import 'package:flutter/material.dart';
import 'package:aeris/modelos/protocolo.dart';
import 'package:aeris/pantallas/editor/pantalla_editor.dart';
import 'package:aeris/pantallas/ejecucion.dart';
import 'package:aeris/servicios/almacen.dart';
import 'package:aeris/servicios/archivos.dart';
import 'package:aeris/servicios/intercambio.dart';
import 'package:aeris/tema.dart';

class PantallaMisProtocolos extends StatefulWidget {
  const PantallaMisProtocolos({super.key});

  @override
  State<PantallaMisProtocolos> createState() => _PantallaMisProtocolosState();
}

class _PantallaMisProtocolosState extends State<PantallaMisProtocolos> {
  // La consulta se lanza al abrir la pantalla (y al volver del editor), no en cada build
  late Future<List<Protocolo>> _protocolos = almacen.ultimasVersiones();

  Future<void> _editar(Protocolo protocolo) async {
    final guardado = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (context) => PantallaEditor(original: protocolo)),
    );
    if (guardado == true && mounted) {
      _recargar(); // ver la versión nueva
    }
  }

  void _recargar() {
    // Llaves y no flecha: con => la función DEVOLVERÍA el Future asignado,
    // y setState no admite que su función devuelva un Future.
    setState(() {
      _protocolos = almacen.ultimasVersiones();
    });
  }

  /// [contextoBoton] es el del propio botón, para saber dónde está en pantalla.
  Future<void> _compartir(BuildContext contextoBoton, Protocolo protocolo) async {
    final caja = contextoBoton.findRenderObject() as RenderBox?;
    final origen = caja == null ? null : caja.localToGlobal(Offset.zero) & caja.size;
    try {
      await archivos.compartirTexto(
        nombreArchivo: nombreArchivo(protocolo),
        contenido: exportarProtocolo(
          protocolo,
          imagenes: await imagenesDe([protocolo], almacen), // las fotos viajan dentro
        ),
        origen: origen,
      );
    } catch (error) {
      if (mounted) _avisar('No se pudo compartir: $error');
    }
  }

  Future<void> _importar() async {
    try {
      final texto = await archivos.elegirTexto();
      if (texto == null) return; // cancelado: no pasa nada
      final importacion = await importarEnAlmacen(texto, almacen);
      if (!mounted) return;
      _avisar(importacion.mensaje);
      if (importacion.resultado != ResultadoImportacion.yaLoTenias) _recargar();
    } on FormatException catch (error) {
      // Mensaje pensado para el usuario: viene de importarProtocolo o de archivos
      if (mounted) await _mostrarError(error.message);
    }
  }

  void _avisar(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(mensaje)));
  }

  Future<void> _mostrarError(String mensaje) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(Icons.error_outline, size: Medida.iconoAviso, color: Theme.of(context).colorScheme.error),
        title: const Text('No se pudo importar'),
        content: Text(mensaje),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Entendido'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis protocolos'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: Espacio.pequeno),
            child: TextButton.icon(
              onPressed: _importar,
              icon: const Icon(Icons.file_open),
              label: const Text('Importar'),
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<Protocolo>>(
        future: _protocolos,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('No se pudieron leer los protocolos: ${snapshot.error}'));
          }
          final protocolos = snapshot.data;
          if (protocolos == null) {
            return const Center(child: CircularProgressIndicator()); // todavía cargando
          }
          if (protocolos.isEmpty) {
            return const Center(
              child: Text('Todavía no hay protocolos.'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(Espacio.normal),
            itemCount: protocolos.length,
            itemBuilder: (context, indice) {
              final protocolo = protocolos[indice];
              return Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: Espacio.grande, vertical: Espacio.medio),
                  leading: const Icon(Icons.science, size: Medida.iconoGrande),
                  title: Text(protocolo.nombreCompleto),
                  subtitle: Text('${protocolo.numeroPasos} pasos'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Builder: da un context propio del botón, para saber su posición
                      Builder(
                        builder: (contextoBoton) => IconButton(
                          tooltip: archivos.accionCompartir,
                          onPressed: () => _compartir(contextoBoton, protocolo),
                          icon: const Icon(Icons.share),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Editar',
                        onPressed: () => _editar(protocolo),
                        icon: const Icon(Icons.edit),
                      ),
                      const Icon(Icons.play_arrow, size: Medida.iconoGrande),
                    ],
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => PantallaEjecucion(protocolo: protocolo),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
