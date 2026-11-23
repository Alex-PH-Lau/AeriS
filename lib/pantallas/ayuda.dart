// AeriS - Laboratory protocol assistant
// Copyright (C) 2026 Alejandro Pascual Hernández and contributors
// SPDX-License-Identifier: GPL-3.0-or-later
// Additional permission for app stores: see EXCEPCION_TIENDAS.md

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:aeris/pantallas/widgets/texto_formato.dart';
import 'package:aeris/tema.dart';

/// Una sección de la ayuda. Su texto está en assets/ayuda/[id].md: así se
/// puede corregir o traducir sin tocar el código, y lo puede revisar
/// alguien que no programe.
class SeccionAyuda {
  final String id;
  final String titulo;
  final IconData icono;

  const SeccionAyuda(this.id, this.titulo, this.icono);

  String get archivo => 'assets/ayuda/$id.md';
}

/// Cómo se leen los textos. Normalmente, de los assets de la app; los tests
/// lo cambian por una función que devuelve textos ya cargados (ver ayuda_test).
Future<String> Function(String archivo) leerTextoAyuda = rootBundle.loadString;

const seccionesAyuda = [
  SeccionAyuda('primeros-pasos', 'Primeros pasos', Icons.flag_outlined),
  SeccionAyuda('ejecutar', 'Ejecutar un protocolo', Icons.play_circle_outline),
  SeccionAyuda('editar', 'Crear y editar protocolos', Icons.edit_note),
  SeccionAyuda('formato', 'Texto con formato e imágenes', Icons.text_format),
  SeccionAyuda('calculo', 'El paso de cálculo', Icons.calculate_outlined),
  SeccionAyuda('cuaderno', 'Cuaderno y copias de seguridad', Icons.menu_book),
  SeccionAyuda('compartir', 'Compartir protocolos', Icons.share_outlined),
];

class PantallaAyuda extends StatefulWidget {
  const PantallaAyuda({super.key});

  @override
  State<PantallaAyuda> createState() => _PantallaAyudaState();
}

class _PantallaAyudaState extends State<PantallaAyuda> {
  // Solo se usa con dos paneles; con uno, cada sección abre su propia pantalla
  SeccionAyuda _seleccionada = seccionesAyuda.first;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Ayuda')),
      body: SafeArea(
        // El mismo patrón lista-detalle que el editor (lección 13)
        child: LayoutBuilder(
          builder: (context, restricciones) {
            final dosPaneles = restricciones.maxWidth >= Medida.anchoDosPaneles;
            final lista = _ListaSecciones(
              seleccionada: dosPaneles ? _seleccionada : null,
              onElegir: (seccion) {
                if (dosPaneles) {
                  setState(() => _seleccionada = seccion);
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => _PantallaSeccion(seccion: seccion)),
                  );
                }
              },
            );
            if (!dosPaneles) return lista;

            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(width: 380, child: lista),
                const VerticalDivider(width: 1),
                Expanded(
                  child: _ContenidoSeccion(
                    key: ValueKey(_seleccionada.id), // otra sección = cargar otro archivo
                    seccion: _seleccionada,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ListaSecciones extends StatelessWidget {
  final SeccionAyuda? seleccionada;
  final ValueChanged<SeccionAyuda> onElegir;

  const _ListaSecciones({required this.seleccionada, required this.onElegir});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.symmetric(vertical: Espacio.pequeno),
      children: [
        for (final seccion in seccionesAyuda)
          ListTile(
            leading: Icon(seccion.icono, size: Medida.icono),
            title: Text(seccion.titulo),
            selected: seccion == seleccionada,
            // Con un panel, la flecha indica que se abre otra pantalla
            trailing: seleccionada == null ? const Icon(Icons.chevron_right) : null,
            onTap: () => onElegir(seccion),
          ),
      ],
    );
  }
}

/// Una sección a pantalla completa (móvil).
class _PantallaSeccion extends StatelessWidget {
  final SeccionAyuda seccion;
  const _PantallaSeccion({required this.seccion});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(seccion.titulo)),
      body: SafeArea(child: _ContenidoSeccion(seccion: seccion)),
    );
  }
}

/// Carga el archivo de la sección y lo muestra con formato.
class _ContenidoSeccion extends StatefulWidget {
  final SeccionAyuda seccion;
  const _ContenidoSeccion({super.key, required this.seccion});

  @override
  State<_ContenidoSeccion> createState() => _ContenidoSeccionState();
}

class _ContenidoSeccionState extends State<_ContenidoSeccion> {
  // rootBundle: los archivos que van DENTRO de la app (declarados en pubspec.yaml)
  late final Future<String> _texto = leerTextoAyuda(widget.seccion.archivo);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _texto,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          // Solo pasaría con un error al empaquetar la app (archivo olvidado)
          return const Center(child: Text('No se pudo cargar esta sección de la ayuda.'));
        }
        final texto = snapshot.data;
        if (texto == null) return const Center(child: CircularProgressIndicator());

        return SingleChildScrollView(
          padding: const EdgeInsets.all(Espacio.grande),
          child: Align(
            alignment: Alignment.topLeft,
            // Líneas no demasiado largas: en una pantalla ancha cansan la vista
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: Medida.anchoLectura + 200),
              child: TextoConFormato(texto: texto),
            ),
          ),
        );
      },
    );
  }
}
