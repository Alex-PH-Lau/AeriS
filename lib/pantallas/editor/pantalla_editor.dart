// AeriS - Laboratory protocol assistant
// Copyright (C) 2026 Alejandro Pascual Hernández and contributors
// SPDX-License-Identifier: GPL-3.0-or-later
// Additional permission for app stores: see EXCEPCION_TIENDAS.md

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:aeris/modelos/borrador_protocolo.dart';
import 'package:aeris/modelos/paso.dart';
import 'package:aeris/modelos/protocolo.dart';
import 'package:aeris/pantallas/editor/editor_paso.dart';
import 'package:aeris/servicios/almacen.dart';
import 'package:aeris/tema.dart';

/// A partir de este ancho (en píxeles lógicos) se usan dos paneles.
/// Tablet en horizontal y PC: dos paneles. Móvil y tablet en vertical: uno.
const anchoDosPaneles = Medida.anchoDosPaneles; // ahora vive en el tema

class PantallaEditor extends StatefulWidget {
  final Protocolo? original; // null = protocolo nuevo

  const PantallaEditor({super.key, this.original});

  @override
  State<PantallaEditor> createState() => _PantallaEditorState();
}

class _PantallaEditorState extends State<PantallaEditor> {
  late final BorradorProtocolo borrador = BorradorProtocolo(original: widget.original);
  String? claveSeleccionada; // paso abierto en el panel derecho (modo dos paneles)

  // ---------- Acciones sobre el borrador ----------

  void _cambiarNombre(String nombre) {
    setState(() => borrador.nombre = nombre);
  }

  void _cambiarPaso(String clave, Paso paso) {
    setState(() => borrador.reemplazar(clave, paso));
  }

  void _mover(int desde, int hasta) {
    setState(() => borrador.mover(desde, hasta));
  }

  Future<void> _anadirPaso({required bool dosPaneles}) async {
    final tipo = await showModalBottomSheet<String>(
      context: context,
      builder: (hojaContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(Espacio.normal),
              child: Text('Añadir paso', style: Theme.of(hojaContext).textTheme.titleLarge),
            ),
            ListTile(
              leading: const Icon(Icons.article, size: Medida.iconoGrande),
              title: const Text('Instrucciones'),
              subtitle: const Text('Texto, con temporizador y alerta opcionales'),
              onTap: () => Navigator.pop(hojaContext, 'instrucciones'),
            ),
            ListTile(
              // Por ahora solo uno por protocolo: la ejecución guarda un único juego de muestras
              enabled: !borrador.tieneCalculo,
              leading: const Icon(Icons.calculate, size: Medida.iconoGrande),
              title: const Text('Cálculo de reactivos'),
              subtitle: Text(borrador.tieneCalculo
                  ? 'Ya hay un paso de cálculo en este protocolo'
                  : 'Mastermix, muestras y normalización del DNA'),
              onTap: () => Navigator.pop(hojaContext, 'calculo'),
            ),
            const SizedBox(height: Espacio.normal),
          ],
        ),
      ),
    );
    if (tipo == null || !mounted) return;

    final clave = switch (tipo) {
      'calculo' => borrador.anadirCalculo(),
      _ => borrador.anadirInstrucciones(),
    };
    setState(() => claveSeleccionada = clave);
    if (!dosPaneles) await _abrirPasoEnPantalla(clave, esNuevo: true);
  }

  Future<void> _borrarPaso(String clave) async {
    final indice = borrador.indiceDe(clave);
    final titulo = borrador.pasos[indice].paso.titulo;
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('¿Borrar el paso ${indice + 1}?'),
        content: Text(titulo.isEmpty ? 'Paso sin título.' : titulo),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Borrar'),
          ),
        ],
      ),
    );
    if (confirmado != true) return;
    setState(() {
      borrador.eliminar(clave);
      if (claveSeleccionada == clave) claveSeleccionada = null;
    });
  }

  /// Modo un panel: el editor del paso se abre en su propia pantalla.
  /// Devuelve el paso al pulsar "Guardar paso", o null si se cancela.
  Future<void> _abrirPasoEnPantalla(String clave, {bool esNuevo = false}) async {
    final indice = borrador.indiceDe(clave);
    final guardado = await Navigator.push<Paso>(
      context,
      MaterialPageRoute(
        builder: (context) => _PantallaPasoSuelto(
          numero: indice + 1,
          paso: borrador.pasos[indice].paso,
        ),
      ),
    );
    if (!mounted) return;
    setState(() {
      if (guardado != null) {
        borrador.reemplazar(clave, guardado);
      } else if (esNuevo) {
        borrador.eliminar(clave); // un paso nuevo cancelado no se queda vacío en la lista
      }
    });
  }

  // ---------- Guardar y salir ----------

  Future<void> _guardar() async {
    final problemas = borrador.problemas();
    if (problemas.isNotEmpty) {
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          icon: const Icon(Icons.rule, size: Medida.iconoAviso),
          title: const Text('Falta completar algunas cosas'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final problema in problemas)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: Espacio.minimo),
                  child: Text('• $problema'),
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
      return;
    }

    // Sin cambios no se crea una versión nueva idéntica a la anterior
    if (!borrador.modificado) {
      Navigator.pop(context, false);
      return;
    }

    await almacen.guardarProtocolo(borrador.construir());
    if (!mounted) return;
    Navigator.pop(context, true); // true = se ha guardado algo
  }

  Future<bool> _confirmarSalida() async {
    final salir = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.edit_off, size: Medida.iconoAviso),
        title: const Text('Hay cambios sin guardar'),
        content: const Text('Si sales ahora, se perderán.'),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Salir sin guardar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Seguir editando'),
          ),
        ],
      ),
    );
    return salir ?? false;
  }

  // ---------- Pantalla ----------

  @override
  Widget build(BuildContext context) {
    final original = widget.original;
    final titulo = original == null ? 'Nuevo protocolo' : 'Editar ${original.nombreCompleto}';

    // Ctrl+S guarda, como en cualquier programa de ordenador. CallbackShortcuts
    // escucha las teclas que se pulsan con el foco en cualquier sitio de dentro
    // (también en un campo de texto); Focus da un foco inicial por si no hay ninguno.
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.keyS, control: true): _guardar,
        const SingleActivator(LogicalKeyboardKey.keyS, meta: true): _guardar, // ⌘S en Mac
      },
      child: Focus(
        autofocus: true,
        child: PopScope<Object?>(
      // Con cambios sin guardar, la flecha atrás no sale directamente: pregunta
      canPop: !borrador.modificado,
      onPopInvokedWithResult: (didPop, resultado) async {
        if (didPop) return;
        final salir = await _confirmarSalida();
        if (salir && mounted) Navigator.pop(context, false);
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(titulo),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: Espacio.normal),
              child: FilledButton.icon(
                onPressed: _guardar,
                icon: const Icon(Icons.save),
                label: const Text('Guardar'),
              ),
            ),
          ],
        ),
        body: SafeArea(
          // La disposición depende del ANCHO disponible, no del tipo de aparato
          child: LayoutBuilder(
            builder: (context, restricciones) {
              final dosPaneles = restricciones.maxWidth >= anchoDosPaneles;
              final lista = _PanelLista(
                borrador: borrador,
                claveSeleccionada: dosPaneles ? claveSeleccionada : null,
                onNombre: _cambiarNombre,
                onSeleccionar: (clave) {
                  if (dosPaneles) {
                    setState(() => claveSeleccionada = clave);
                  } else {
                    _abrirPasoEnPantalla(clave);
                  }
                },
                onBorrar: _borrarPaso,
                onMover: _mover,
                onAnadir: () => _anadirPaso(dosPaneles: dosPaneles),
              );

              if (!dosPaneles) return lista;

              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(width: 400, child: lista),
                  const VerticalDivider(width: 1),
                  Expanded(child: _panelDerecho()),
                ],
              );
            },
          ),
        ),
      ), // Scaffold
        ), // PopScope
      ), // Focus
    );
  }

  Widget _panelDerecho() {
    final clave = claveSeleccionada;
    final indice = clave == null ? -1 : borrador.indiceDe(clave);
    if (clave == null || indice < 0) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(Espacio.extra),
          child: Text(
            'Elige un paso de la lista para editarlo, o añade uno nuevo.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(Espacio.grande),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Paso ${indice + 1}', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: Espacio.normal),
          EditorPaso(
            key: ValueKey(clave), // otro paso = formulario nuevo
            paso: borrador.pasos[indice].paso,
            onCambio: (paso) => _cambiarPaso(clave, paso),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------

/// Nombre del protocolo y lista de pasos (reordenable).
class _PanelLista extends StatelessWidget {
  final BorradorProtocolo borrador;
  final String? claveSeleccionada;
  final ValueChanged<String> onNombre;
  final ValueChanged<String> onSeleccionar;
  final ValueChanged<String> onBorrar;
  final void Function(int desde, int hasta) onMover;
  final VoidCallback onAnadir;

  const _PanelLista({
    required this.borrador,
    required this.claveSeleccionada,
    required this.onNombre,
    required this.onSeleccionar,
    required this.onBorrar,
    required this.onMover,
    required this.onAnadir,
  });

  @override
  Widget build(BuildContext context) {
    final pasos = borrador.pasos;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(Espacio.normal),
          child: TextFormField(
            initialValue: borrador.nombre,
            decoration: const InputDecoration(
              labelText: 'Nombre del protocolo',
            ),
            style: Theme.of(context).textTheme.titleLarge, // el nombre destaca sobre lo demás
            onChanged: onNombre,
          ),
        ),
        Expanded(
          child: pasos.isEmpty
              ? const Center(
                  child: Text('Todavía no hay pasos.'),
                )
              : ReorderableListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: Espacio.normal),
                  buildDefaultDragHandles: false, // usamos un asa visible
                  itemCount: pasos.length,
                  onReorder: onMover,
                  itemBuilder: (context, indice) {
                    final elemento = pasos[indice];
                    return _FilaPaso(
                      key: ValueKey(elemento.clave), // obligatorio para reordenar
                      indice: indice,
                      paso: elemento.paso,
                      seleccionado: elemento.clave == claveSeleccionada,
                      onTap: () => onSeleccionar(elemento.clave),
                      onBorrar: () => onBorrar(elemento.clave),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.all(Espacio.normal),
          child: SizedBox(
            height: Medida.boton,
            child: FilledButton.icon(
              onPressed: onAnadir,
              icon: const Icon(Icons.add),
              label: const Text('Añadir paso'),
            ),
          ),
        ),
      ],
    );
  }
}

class _FilaPaso extends StatelessWidget {
  final int indice;
  final Paso paso;
  final bool seleccionado;
  final VoidCallback onTap;
  final VoidCallback onBorrar;

  const _FilaPaso({
    super.key,
    required this.indice,
    required this.paso,
    required this.seleccionado,
    required this.onTap,
    required this.onBorrar,
  });

  @override
  Widget build(BuildContext context) {
    final tipo = switch (paso) {
      PasoInstrucciones() => 'Instrucciones',
      PasoCalculo() => 'Cálculo de reactivos',
    };
    final extras = [
      if (paso.temporizador != null) '⏱',
      if (paso.alerta != null) '⚠',
    ].join(' ');

    return Card(
      child: ListTile(
        selected: seleccionado,
        leading: ReorderableDragStartListener(
          index: indice,
          child: const Icon(Icons.drag_handle, size: Medida.icono), // arrastrar con dedo o ratón
        ),
        title: Text('${indice + 1}. ${paso.titulo.isEmpty ? '(sin título)' : paso.titulo}'),
        subtitle: Text(extras.isEmpty ? tipo : '$tipo  $extras'),
        trailing: IconButton(
          tooltip: 'Borrar paso',
          onPressed: onBorrar,
          icon: const Icon(Icons.delete_outline),
        ),
        onTap: onTap,
      ),
    );
  }
}

/// Modo un panel: pantalla completa con el editor de un paso.
/// Trabaja sobre una copia: los cambios solo cuentan al pulsar "Guardar paso".
class _PantallaPasoSuelto extends StatefulWidget {
  final int numero;
  final Paso paso;

  const _PantallaPasoSuelto({required this.numero, required this.paso});

  @override
  State<_PantallaPasoSuelto> createState() => _PantallaPasoSueltoState();
}

class _PantallaPasoSueltoState extends State<_PantallaPasoSuelto> {
  late Paso paso = widget.paso;
  bool cambiado = false;

  void _guardar() {
    Navigator.pop(context, paso); // devuelve el paso editado al editor
  }

  Future<bool> _confirmarDescartar() async {
    final descartar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.edit_off, size: Medida.iconoAviso),
        title: const Text('¿Descartar los cambios de este paso?'),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Descartar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Seguir editando'),
          ),
        ],
      ),
    );
    return descartar ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(
      // La flecha atrás es "cancelar": si hay cambios, pregunta antes de perderlos
      canPop: !cambiado,
      onPopInvokedWithResult: (didPop, resultado) async {
        if (didPop) return;
        final descartar = await _confirmarDescartar();
        if (descartar && mounted) Navigator.pop(context); // sin resultado = cancelado
      },
      child: Scaffold(
        appBar: AppBar(title: Text('Paso ${widget.numero}')),
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(Espacio.grande),
                  child: EditorPaso(
                    paso: paso,
                    onCambio: (nuevo) => setState(() {
                      paso = nuevo;
                      cambiado = true;
                    }),
                  ),
                ),
              ),
              // Abajo y grande: a mano del pulgar y cómodo con guantes
              Padding(
                padding: const EdgeInsets.all(Espacio.normal),
                child: SizedBox(
                  height: Medida.botonPrincipal,
                  child: FilledButton.icon(
                    onPressed: _guardar,
                    icon: const Icon(Icons.check),
                    label: const Text('Guardar paso'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
