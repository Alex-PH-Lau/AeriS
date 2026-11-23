// AeriS - Laboratory protocol assistant
// Copyright (C) 2026 Alejandro Pascual Hernández and contributors
// SPDX-License-Identifier: GPL-3.0-or-later
// Additional permission for app stores: see EXCEPCION_TIENDAS.md

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:aeris/modelos/formato.dart';
import 'package:aeris/modelos/imagenes.dart';
import 'package:aeris/servicios/almacen.dart';
import 'package:aeris/servicios/selector_imagenes.dart';
import 'package:aeris/pantallas/widgets/texto_formato.dart';
import 'package:aeris/tema.dart';

/// Campo de texto con botones de formato y una vista previa.
///
/// Necesita ser StatefulWidget: un TextEditingController guarda el texto y,
/// sobre todo, la SELECCIÓN, que es lo que usan los botones.
class EditorTextoFormato extends StatefulWidget {
  final String texto;
  final ValueChanged<String> onCambio;

  const EditorTextoFormato({super.key, required this.texto, required this.onCambio});

  @override
  State<EditorTextoFormato> createState() => _EditorTextoFormatoState();
}

class _EditorTextoFormatoState extends State<EditorTextoFormato> {
  late final _controlador = TextEditingController(text: widget.texto);
  final _foco = FocusNode();
  bool _vistaPrevia = false;

  @override
  void dispose() {
    // Lo que se crea en un State, se libera en dispose (como el Timer, lección 9)
    _controlador.dispose();
    _foco.dispose();
    super.dispose();
  }

  void _aplicar(TextEditingValue Function(TextEditingValue) formato) {
    _controlador.value = formato(_controlador.value);
    widget.onCambio(_controlador.text);
    _foco.requestFocus(); // seguir escribiendo sin tener que tocar el campo
  }

  /// Elegir origen → conseguir la foto → guardarla → poner su marca en el texto.
  Future<void> _anadirImagen() async {
    final origenes = selectorImagenes.origenes;
    // Con un solo origen (en el ordenador, la galería) no hace falta preguntar
    final origen = origenes.length == 1 ? origenes.single : await showModalBottomSheet<OrigenImagen>(
      context: context,
      builder: (hojaContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final origen in origenes)
              ListTile(
                leading: Icon(
                  origen == OrigenImagen.camara ? Icons.photo_camera : Icons.photo_library,
                  size: Medida.iconoGrande,
                ),
                title: Text(origen.etiqueta),
                onTap: () => Navigator.pop(hojaContext, origen),
              ),
            const SizedBox(height: Espacio.normal),
          ],
        ),
      ),
    );
    if (origen == null || !mounted) return;

    Uint8List? datos;
    try {
      datos = await selectorImagenes.elegir(origen);
    } catch (error) {
      // Sin cámara, permiso denegado…: se avisa y no pasa nada más
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo conseguir la imagen: $error')),
        );
      }
      return;
    }
    if (datos == null || !mounted) return; // cancelado

    final pie = await _pedirPie();
    if (pie == null || !mounted) return; // cancelado en el diálogo

    final id = nuevoIdImagen();
    await almacen.guardarImagen(id, datos);
    _aplicar((v) => insertarBloque(v, marcaImagen(id, pie: pie)));
  }

  /// Pide el pie de foto. Devuelve '' si se deja vacío y null si se cancela.
  Future<String?> _pedirPie() {
    var pie = '';
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Pie de foto'),
        content: TextField(
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Qué se ve (opcional)',
            hintText: 'Por ejemplo: montaje de la cubeta',
          ),
          onChanged: (texto) => pie = texto.replaceAll(RegExp(r'[\[\]]'), ''), // sin [ ]
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, pie.trim()),
            child: const Text('Añadir'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Solo, en su línea: en un móvil no cabe al lado de nada
        Align(
          alignment: Alignment.centerRight,
          child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, icon: Icon(Icons.edit), label: Text('Escribir')),
                ButtonSegment(value: true, icon: Icon(Icons.visibility), label: Text('Vista previa')),
              ],
              selected: {_vistaPrevia},
              showSelectedIcon: false,
              onSelectionChanged: (s) => setState(() => _vistaPrevia = s.first),
          ),
        ),
        const SizedBox(height: Espacio.medio),
        if (_vistaPrevia)
          _VistaPrevia(texto: _controlador.text)
        else ...[
          // TextFieldTapRegion: tocar los botones cuenta como "dentro" del campo,
          // así el teclado no se cierra al dar formato
          TextFieldTapRegion(
            child: Wrap(
              spacing: Espacio.pequeno,
              runSpacing: Espacio.pequeno,
              children: [
                _BotonFormato('Negrita', Icons.format_bold, () => _aplicar((v) => envolver(v, '**'))),
                _BotonFormato('Cursiva', Icons.format_italic, () => _aplicar((v) => envolver(v, '_'))),
                _BotonFormato('Título', Icons.title,
                    () => _aplicar((v) => formatearLineas(v, FormatoLinea.titulo))),
                _BotonFormato('Lista', Icons.format_list_bulleted,
                    () => _aplicar((v) => formatearLineas(v, FormatoLinea.lista))),
                _BotonFormato('Lista numerada', Icons.format_list_numbered,
                    () => _aplicar((v) => formatearLineas(v, FormatoLinea.numerada))),
                _BotonFormato('Importante', Icons.priority_high,
                    () => _aplicar((v) => formatearLineas(v, FormatoLinea.importante))),
                _BotonFormato('Imagen', Icons.add_photo_alternate, _anadirImagen),
              ],
            ),
          ),
          const SizedBox(height: Espacio.pequeno),
          TextField(
            controller: _controlador,
            focusNode: _foco,
            decoration: const InputDecoration(
              labelText: 'Texto del paso',
              alignLabelWithHint: true,
              hintText: 'Qué hay que hacer en este paso',
              helperText: '**negrita**  _cursiva_  ## Título  - lista  1. lista  > Importante',
              helperMaxLines: 2,
            ),
            minLines: 5,
            maxLines: null, // crece con el texto
            keyboardType: TextInputType.multiline,
            onChanged: widget.onCambio,
          ),
        ],
      ],
    );
  }
}

class _BotonFormato extends StatelessWidget {
  final String nombre;
  final IconData icono;
  final VoidCallback onPressed;

  const _BotonFormato(this.nombre, this.icono, this.onPressed);

  @override
  Widget build(BuildContext context) {
    return IconButton.outlined(
      tooltip: nombre, // también lo leen los lectores de pantalla
      onPressed: onPressed,
      icon: Icon(icono),
    );
  }
}

class _VistaPrevia extends StatelessWidget {
  final String texto;

  const _VistaPrevia({required this.texto});

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    return Container(
      constraints: const BoxConstraints(minHeight: 160),
      padding: const EdgeInsets.all(Espacio.normal),
      decoration: BoxDecoration(
        border: Border.all(color: colores.outline),
        borderRadius: BorderRadius.circular(Espacio.minimo),
      ),
      child: texto.trim().isEmpty
          ? Text('(El paso todavía no tiene texto)', style: TextStyle(color: colores.outline))
          // Mismo estilo que al ejecutar: lo que ves aquí es lo que se verá en el laboratorio
          : TextoConFormato(texto: texto, estilo: EstiloTexto.paso),
    );
  }
}
