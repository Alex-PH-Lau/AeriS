// AeriS - Laboratory protocol assistant
// Copyright (C) 2026 Alejandro Pascual Hernández and contributors
// SPDX-License-Identifier: GPL-3.0-or-later
// Additional permission for app stores: see EXCEPCION_TIENDAS.md

import 'package:flutter/material.dart';
import 'package:aeris/modelos/protocolo.dart';
import 'package:aeris/pantallas/editor/pantalla_editor.dart';
import 'package:aeris/pantallas/ejecucion.dart';
import 'package:aeris/servicios/almacen.dart';

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
      setState(() => _protocolos = almacen.ultimasVersiones()); // ver la versión nueva
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis protocolos'),
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
              child: Text('Todavía no hay protocolos.', style: TextStyle(fontSize: 20)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: protocolos.length,
            itemBuilder: (context, indice) {
              final protocolo = protocolos[indice];
              return Card(
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  leading: const Icon(Icons.science, size: 36),
                  title: Text(
                    protocolo.nombreCompleto,
                    style: const TextStyle(fontSize: 20),
                  ),
                  subtitle: Text('${protocolo.numeroPasos} pasos'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        iconSize: 32,
                        tooltip: 'Editar',
                        onPressed: () => _editar(protocolo),
                        icon: const Icon(Icons.edit),
                      ),
                      const Icon(Icons.play_arrow, size: 36),
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
