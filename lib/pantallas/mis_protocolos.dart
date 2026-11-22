// AeriS - Laboratory protocol assistant
// Copyright (C) 2026 Alejandro Pascual Hernández and contributors
// SPDX-License-Identifier: GPL-3.0-or-later
// Additional permission for app stores: see EXCEPCION_TIENDAS.md

import 'package:flutter/material.dart';
import 'package:aeris/modelos/protocolo.dart';
import 'package:aeris/pantallas/ejecucion.dart';

class PantallaMisProtocolos extends StatelessWidget {
  const PantallaMisProtocolos({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis protocolos'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: protocolosDeEjemplo.length,
        itemBuilder: (context, indice) {
          final protocolo = protocolosDeEjemplo[indice];
          return Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              leading: const Icon(Icons.science, size: 36),
              title: Text(
                protocolo.nombreCompleto,
                style: const TextStyle(fontSize: 20),
              ),
              subtitle: Text('${protocolo.numeroPasos} pasos'),
              trailing: const Icon(Icons.play_arrow, size: 36),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PantallaEjecucion(protocolo: protocolo),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}