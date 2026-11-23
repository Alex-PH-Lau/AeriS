// AeriS - Laboratory protocol assistant
// Copyright (C) 2026 Alejandro Pascual Hernández and contributors
// SPDX-License-Identifier: GPL-3.0-or-later
// Additional permission for app stores: see EXCEPCION_TIENDAS.md

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:aeris/servicios/almacen.dart';
import 'package:aeris/tema.dart';

/// Una imagen del almacén, con su pie de foto. Al tocarla se abre a pantalla
/// completa, donde se puede ampliar con dos dedos.
class ImagenGuardada extends StatefulWidget {
  final String id;
  final String pie;

  const ImagenGuardada({super.key, required this.id, this.pie = ''});

  @override
  State<ImagenGuardada> createState() => _ImagenGuardadaState();
}

class _ImagenGuardadaState extends State<ImagenGuardada> {
  // En initState y no en build: si no, cada repintado volvería a leer la
  // base de datos (como con los FutureBuilder de las listas, lección 11)
  late Future<Uint8List?> _datos = almacen.imagen(widget.id);

  @override
  void didUpdateWidget(ImagenGuardada anterior) {
    super.didUpdateWidget(anterior);
    if (anterior.id != widget.id) _datos = almacen.imagen(widget.id);
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Espacio.pequeno),
      child: FutureBuilder<Uint8List?>(
        future: _datos,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator()));
          }
          final datos = snapshot.data;
          if (datos == null) return _Falta(pie: widget.pie);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                label: widget.pie.isEmpty ? 'Imagen' : widget.pie,
                button: true,
                child: InkWell(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => _PantallaImagen(datos: datos, pie: widget.pie),
                    ),
                  ),
                  child: ConstrainedBox(
                    // Que quepa en pantalla junto al texto del paso
                    constraints: const BoxConstraints(maxHeight: 420),
                    child: Image.memory(
                      datos,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, pila) => _Falta(pie: widget.pie),
                    ),
                  ),
                ),
              ),
              if (widget.pie.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: Espacio.minimo),
                  child: Text(
                    widget.pie,
                    textAlign: TextAlign.center,
                    style: tema.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

/// La imagen no está (archivo incompleto) o no se puede leer.
class _Falta extends StatelessWidget {
  final String pie;
  const _Falta({required this.pie});

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(Espacio.normal),
      color: colores.surfaceContainerHighest,
      child: Row(
        children: [
          Icon(Icons.broken_image_outlined, size: Medida.iconoGrande, color: colores.outline),
          const SizedBox(width: Espacio.medio),
          Expanded(child: Text(pie.isEmpty ? 'Imagen no disponible' : 'Imagen no disponible: $pie')),
        ],
      ),
    );
  }
}

class _PantallaImagen extends StatelessWidget {
  final Uint8List datos;
  final String pie;

  const _PantallaImagen({required this.datos, required this.pie});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(pie.isEmpty ? 'Imagen' : pie),
      ),
      body: InteractiveViewer(
        maxScale: 6, // ampliar con dos dedos (o la rueda del ratón en PC)
        child: Center(child: Image.memory(datos)),
      ),
    );
  }
}
