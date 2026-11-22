// AeriS - Laboratory protocol assistant
// Copyright (C) 2026 Alejandro Pascual Hernández and contributors
// SPDX-License-Identifier: GPL-3.0-or-later
// Additional permission for app stores: see EXCEPCION_TIENDAS.md

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:aeris/modelos/calculo.dart';
import 'package:aeris/modelos/entradas.dart';
import 'package:aeris/modelos/paso.dart';
import 'package:aeris/pantallas/editor/editor_paso.dart';

const _estilo = TextStyle(fontSize: 20);

/// Una fila editable (reactivo, tipo de tubo o dato) con una clave estable,
/// para que al borrar una fila del medio los textos no salten a otra.
class _Fila<T> {
  final int clave;
  T valor;
  _Fila(this.clave, this.valor);
}

/// Editor del paso de cálculo de reactivos.
///
/// Las tres listas (reactivos, tubos, datos) se guardan aquí con claves
/// estables; el resto de campos se leen del paso que llega en [paso].
class EditorCalculo extends StatefulWidget {
  final PasoCalculo paso;
  final ValueChanged<Paso> onCambio;

  const EditorCalculo({super.key, required this.paso, required this.onCambio});

  @override
  State<EditorCalculo> createState() => _EditorCalculoState();
}

class _EditorCalculoState extends State<EditorCalculo> {
  int _contador = 0;
  late final List<_Fila<Reactivo>> reactivos = [
    for (final reactivo in widget.paso.reactivos) _Fila(_contador++, reactivo),
  ];
  late final List<_Fila<TipoTubo>> tubos = [
    for (final tipo in widget.paso.tiposTubo) _Fila(_contador++, tipo),
  ];
  late final List<_Fila<ParametroEntrada>> parametros = [
    for (final parametro in widget.paso.parametros) _Fila(_contador++, parametro),
  ];

  /// Avisa del paso completo: [base] con las listas actuales.
  void _emitir([PasoCalculo? base]) {
    final paso = (base ?? widget.paso).copiar(
      reactivos: [for (final fila in reactivos) fila.valor],
      tiposTubo: [for (final fila in tubos) fila.valor],
      parametros: [for (final fila in parametros) fila.valor],
    );
    widget.onCambio(paso);
  }

  void _cambiarListas(VoidCallback cambio) {
    setState(cambio);
    _emitir();
  }

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final paso = widget.paso;
    final normalizado = paso.modo == ModoMolde.normalizado;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CampoTitulo(titulo: paso.titulo, onCambio: (t) => _emitir(paso.copiar(titulo: t))),

        // ---------- Reacción ----------
        const SizedBox(height: 32),
        Text('Reacción', style: tema.textTheme.titleLarge),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: CampoNumero(
                key: const ValueKey('volumenReaccion'),
                etiqueta: 'Volumen por tubo (µL)',
                valor: paso.volumenReaccion,
                onCambio: (v) => _emitir(paso.copiar(volumenReaccion: v)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: CampoNumero(
                key: const ValueKey('margen'),
                etiqueta: 'Margen (%)',
                ayuda: 'Extra por pérdidas al pipetear',
                // Redondeo: (1.1 - 1) * 100 da 10.000000000000009 en coma flotante
                valor: ((paso.margen - 1) * 100 * 1000).round() / 1000,
                onCambio: (v) => _emitir(paso.copiar(margen: 1 + v / 100)),
              ),
            ),
          ],
        ),

        // ---------- Molde (DNA) ----------
        const SizedBox(height: 32),
        Text('DNA molde', style: tema.textTheme.titleLarge),
        const SizedBox(height: 12),
        SegmentedButton<ModoMolde>(
          segments: const [
            ButtonSegment(
              value: ModoMolde.normalizado,
              icon: Icon(Icons.balance),
              label: Text('Normalizar ng', style: TextStyle(fontSize: 18)),
            ),
            ButtonSegment(
              value: ModoMolde.volumenFijo,
              icon: Icon(Icons.straighten),
              label: Text('Volumen fijo', style: TextStyle(fontSize: 18)),
            ),
          ],
          selected: {paso.modo},
          onSelectionChanged: (seleccion) => _emitir(paso.copiar(modo: seleccion.first)),
        ),
        const SizedBox(height: 8),
        Text(paso.modo.etiqueta, style: tema.textTheme.bodyMedium),
        const SizedBox(height: 16),
        CampoNumero(
          key: const ValueKey('volumenMolde'),
          etiqueta: normalizado ? 'Hueco para DNA + agua (µL)' : 'DNA por tubo (µL)',
          ayuda: normalizado ? 'Se completa tubo a tubo con DNA y agua' : null,
          valor: paso.volumenMolde,
          onCambio: (v) => _emitir(paso.copiar(volumenMolde: v)),
        ),
        if (normalizado) ...[
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: CampoNumero(
                  key: const ValueKey('ngObjetivo'),
                  etiqueta: 'ng de DNA por reacción',
                  valor: paso.ngObjetivo,
                  onCambio: (v) => _emitir(paso.copiar(ngObjetivo: v)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: CampoNumero(
                  key: const ValueKey('volumenMinimo'),
                  etiqueta: 'Mínimo pipeteable (µL)',
                  valor: paso.volumenMinimo,
                  onCambio: (v) => _emitir(paso.copiar(volumenMinimo: v)),
                ),
              ),
            ],
          ),
        ],

        // ---------- Reactivos ----------
        const SizedBox(height: 32),
        Text('Reactivos del mastermix', style: tema.textTheme.titleLarge),
        Text('Sin el agua: AeriS la calcula sola.', style: tema.textTheme.bodyMedium),
        const SizedBox(height: 12),
        for (var i = 0; i < reactivos.length; i++)
          _FilaReactivo(
            key: ValueKey(reactivos[i].clave),
            reactivo: reactivos[i].valor,
            onCambio: (r) => _cambiarListas(() => reactivos[i].valor = r),
            onQuitar: () => _cambiarListas(() => reactivos.removeAt(i)),
          ),
        _BotonAnadir(
          texto: 'Añadir reactivo',
          onPressed: () => _cambiarListas(() {
            reactivos.add(_Fila(_contador++, const Reactivo(nombre: '', volPorReaccion: 0)));
          }),
        ),

        // ---------- Tipos de tubo ----------
        const SizedBox(height: 32),
        Text('Tipos de tubo', style: tema.textTheme.titleLarge),
        Text(
          'Con DNA y sin cantidad fija = las muestras, que se añaden al ejecutar.',
          style: tema.textTheme.bodyMedium,
        ),
        const SizedBox(height: 12),
        for (var i = 0; i < tubos.length; i++)
          _FilaTubo(
            key: ValueKey(tubos[i].clave),
            tipo: tubos[i].valor,
            onCambio: (t) => _cambiarListas(() => tubos[i].valor = t),
            onQuitar: () => _cambiarListas(() => tubos.removeAt(i)),
          ),
        _BotonAnadir(
          texto: 'Añadir tipo de tubo',
          onPressed: () => _cambiarListas(() {
            tubos.add(_Fila(_contador++, const TipoTubo(nombre: '', conDna: true, cantidadFija: 1)));
          }),
        ),

        // ---------- Datos de la ejecución ----------
        const SizedBox(height: 32),
        Text('Datos que se apuntan al ejecutar', style: tema.textTheme.titleLarge),
        Text('Por ejemplo, el lote de la polimerasa.', style: tema.textTheme.bodyMedium),
        const SizedBox(height: 12),
        for (var i = 0; i < parametros.length; i++)
          _FilaParametro(
            key: ValueKey(parametros[i].clave),
            parametro: parametros[i].valor,
            onCambio: (p) => _cambiarListas(() => parametros[i].valor = p),
            onQuitar: () => _cambiarListas(() => parametros.removeAt(i)),
          ),
        _BotonAnadir(
          texto: 'Añadir dato',
          onPressed: () => _cambiarListas(() {
            parametros.add(_Fila(_contador++, const ParametroEntrada(nombre: '')));
          }),
        ),

        // ---------- Vista previa ----------
        const SizedBox(height: 32),
        _VistaPrevia(paso: paso),

        // ---------- Herramientas ----------
        const SizedBox(height: 32),
        SeccionHerramientas(
          temporizador: paso.temporizador,
          alerta: paso.alerta,
          onTemporizador: (t) => _emitir(
            t == null ? paso.copiar(sinTemporizador: true) : paso.copiar(temporizador: t),
          ),
          onAlerta: (a) => _emitir(
            a == null ? paso.copiar(sinAlerta: true) : paso.copiar(alerta: a),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------

class _BotonAnadir extends StatelessWidget {
  final String texto;
  final VoidCallback onPressed;

  const _BotonAnadir({required this.texto, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: SizedBox(
        height: 56,
        child: OutlinedButton.icon(
          onPressed: onPressed,
          icon: const Icon(Icons.add, size: 28),
          label: Text(texto, style: const TextStyle(fontSize: 18)),
        ),
      ),
    );
  }
}

Widget _botonQuitar(String tooltip, VoidCallback onQuitar) => IconButton(
      iconSize: 28,
      tooltip: tooltip,
      onPressed: onQuitar,
      icon: const Icon(Icons.delete_outline),
    );

InputDecoration _decoracion(String etiqueta) => InputDecoration(
      labelText: etiqueta,
      border: const OutlineInputBorder(),
      isDense: true,
    );

class _FilaReactivo extends StatelessWidget {
  final Reactivo reactivo;
  final ValueChanged<Reactivo> onCambio;
  final VoidCallback onQuitar;

  const _FilaReactivo({
    super.key,
    required this.reactivo,
    required this.onCambio,
    required this.onQuitar,
  });

  @override
  Widget build(BuildContext context) {
    // Construye un reactivo nuevo cambiando solo lo indicado
    Reactivo con({String? nombre, double? volumen}) => Reactivo(
          nombre: nombre ?? reactivo.nombre,
          concentracion: reactivo.concentracion,
          volPorReaccion: volumen ?? reactivo.volPorReaccion,
        );

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: TextFormField(
              initialValue: reactivo.nombre,
              decoration: _decoracion('Reactivo'),
              style: _estilo,
              onChanged: (t) => onCambio(con(nombre: t)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: TextFormField(
              initialValue: reactivo.concentracion ?? '',
              decoration: _decoracion('Conc. (opcional)'),
              style: _estilo,
              onChanged: (t) => onCambio(Reactivo(
                nombre: reactivo.nombre,
                volPorReaccion: reactivo.volPorReaccion,
                concentracion: t.trim().isEmpty ? null : t, // vacío = sin concentración
              )),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 2,
            child: CampoNumero(
              etiqueta: 'µL / tubo',
              valor: reactivo.volPorReaccion == 0 ? null : reactivo.volPorReaccion,
              onCambio: (v) => onCambio(con(volumen: v)),
            ),
          ),
          _botonQuitar('Quitar reactivo', onQuitar),
        ],
      ),
    );
  }
}

class _FilaTubo extends StatelessWidget {
  final TipoTubo tipo;
  final ValueChanged<TipoTubo> onCambio;
  final VoidCallback onQuitar;

  const _FilaTubo({
    super.key,
    required this.tipo,
    required this.onCambio,
    required this.onQuitar,
  });

  @override
  Widget build(BuildContext context) {
    // Se construye entero cada vez: cantidadFija puede pasar a null
    TipoTubo nuevo({String? nombre, String? seAnade, int? cantidad, bool? conDna, bool quitarCantidad = false}) =>
        TipoTubo(
          nombre: nombre ?? tipo.nombre,
          seAnade: seAnade ?? tipo.seAnade,
          cantidadFija: quitarCantidad ? null : (cantidad ?? tipo.cantidadFija),
          conDna: conDna ?? tipo.conDna,
        );
    final cantidad = tipo.cantidadFija;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: tipo.nombre,
                    decoration: _decoracion('Nombre del tubo'),
                    style: _estilo,
                    onChanged: (t) => onCambio(nuevo(nombre: t)),
                  ),
                ),
                _botonQuitar('Quitar tipo de tubo', onQuitar),
              ],
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Lleva DNA', style: _estilo),
              subtitle: Text(tipo.conDna
                  ? 'Aparece en la tabla de muestras con su concentración'
                  : 'Lleva otra cosa en el hueco, por ejemplo agua'),
              value: tipo.conDna,
              onChanged: (conDna) => onCambio(nuevo(conDna: conDna)),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextFormField(
                    initialValue: cantidad == null ? '' : '$cantidad',
                    decoration: _decoracion(tipo.conDna ? 'Cantidad fija' : 'Cantidad').copyWith(
                      helperText: tipo.conDna ? 'Vacío = se añaden al ejecutar' : null,
                    ),
                    style: _estilo,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    onChanged: (t) {
                      final n = leerEntero(t);
                      onCambio(n == null ? nuevo(quitarCantidad: true) : nuevo(cantidad: n));
                    },
                  ),
                ),
                if (!tipo.conDna) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      initialValue: tipo.seAnade,
                      decoration: _decoracion('Se añade'),
                      style: _estilo,
                      onChanged: (t) => onCambio(nuevo(seAnade: t)),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FilaParametro extends StatelessWidget {
  final ParametroEntrada parametro;
  final ValueChanged<ParametroEntrada> onCambio;
  final VoidCallback onQuitar;

  const _FilaParametro({
    super.key,
    required this.parametro,
    required this.onCambio,
    required this.onQuitar,
  });

  @override
  Widget build(BuildContext context) {
    ParametroEntrada nuevo({
      String? nombre,
      TipoParametro? tipo,
      String? unidad,
      bool? obligatorio,
      bool quitarUnidad = false,
    }) =>
        ParametroEntrada(
          nombre: nombre ?? parametro.nombre,
          tipo: tipo ?? parametro.tipo,
          unidad: quitarUnidad ? null : (unidad ?? parametro.unidad),
          obligatorio: obligatorio ?? parametro.obligatorio,
        );
    final esNumero = parametro.tipo == TipoParametro.numero;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    initialValue: parametro.nombre,
                    decoration: _decoracion('Nombre del dato'),
                    style: _estilo,
                    onChanged: (t) => onCambio(nuevo(nombre: t)),
                  ),
                ),
                if (esNumero) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      initialValue: parametro.unidad ?? '',
                      decoration: _decoracion('Unidad'),
                      style: _estilo,
                      onChanged: (t) => onCambio(
                        t.trim().isEmpty ? nuevo(quitarUnidad: true) : nuevo(unidad: t),
                      ),
                    ),
                  ),
                ],
                _botonQuitar('Quitar dato', onQuitar),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SegmentedButton<TipoParametro>(
                  segments: const [
                    ButtonSegment(value: TipoParametro.numero, label: Text('Número')),
                    ButtonSegment(value: TipoParametro.texto, label: Text('Texto')),
                  ],
                  selected: {parametro.tipo},
                  onSelectionChanged: (s) => onCambio(nuevo(tipo: s.first)),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Switch(
                      value: parametro.obligatorio,
                      onChanged: (o) => onCambio(nuevo(obligatorio: o)),
                    ),
                    const SizedBox(width: 8),
                    const Text('Obligatorio', style: TextStyle(fontSize: 18)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------

/// Calcula un ejemplo mientras se configura el paso, para ver si tiene sentido.
class _VistaPrevia extends StatelessWidget {
  final PasoCalculo paso;

  static const _muestrasEjemplo = 3;
  static const _concentracionEjemplo = 50.0; // ng/µL

  const _VistaPrevia({required this.paso});

  @override
  Widget build(BuildContext context) {
    final tema = Theme.of(context);
    final problemas = paso.problemas();

    // Muestras de ejemplo: 3 de cada tipo libre y las fijas que haya
    final muestras = <Muestra>[
      for (final tipo in paso.tiposTubo)
        if (tipo.conDna)
          for (var i = 0; i < (tipo.cantidadFija ?? _muestrasEjemplo); i++)
            Muestra(
              id: '${tipo.nombre}-$i',
              tipo: tipo.nombre,
              codigo: '${tipo.nombre} ${i + 1}',
              concentracion: _concentracionEjemplo,
            ),
    ];

    return Card(
      color: tema.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.preview, size: 28),
                const SizedBox(width: 8),
                Text('Vista previa', style: tema.textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 8),
            if (problemas.isNotEmpty) ...[
              Text('Para calcular, falta:', style: tema.textTheme.titleMedium),
              for (final problema in problemas)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '• $problema',
                    style: TextStyle(fontSize: 17, color: tema.colorScheme.error),
                  ),
                ),
            ] else
              ..._calculo(tema, muestras),
          ],
        ),
      ),
    );
  }

  List<Widget> _calculo(ThemeData tema, List<Muestra> muestras) {
    final resultado = paso.calcular(muestras);
    final mixPorTubo = paso.volumenReaccion - paso.volumenMolde;
    const texto = TextStyle(fontSize: 17);

    String lineaMuestra(ResultadoMuestra r) {
      final dna = r.volumenDna.toStringAsFixed(2);
      final agua = r.volumenAgua.toStringAsFixed(2);
      return switch (r.estado) {
        EstadoMuestra.correcta => r.volumenAgua > 0 ? '$dna µL de DNA + $agua µL de agua' : '$dna µL de DNA',
        EstadoMuestra.diluir => r.factorDilucion == null
            ? 'demasiado concentrada'
            : 'diluir 1:${r.factorDilucion} y poner $dna µL + $agua µL de agua',
        EstadoMuestra.huecoCompleto => 'hueco completo ($dna µL)',
        EstadoMuestra.sinConcentracion => 'sin concentración',
      };
    }

    return [
      Text(
        'Ejemplo: $_muestrasEjemplo muestras a ${formatearNumero(_concentracionEjemplo)} ng/µL '
        '→ ${resultado.totalTubos} tubos en total.',
        style: texto,
      ),
      const SizedBox(height: 8),
      Text('Mastermix: ${formatearMicrolitros(mixPorTubo)} µL por tubo', style: tema.textTheme.titleMedium),
      for (final reactivo in paso.reactivos)
        Text(
          '• ${reactivo.nombre}: ${formatearMicrolitros(reactivo.volPorReaccion)} µL/tubo → '
          '${(resultado.volumenesTotales[reactivo.nombre] ?? 0).toStringAsFixed(2)} µL',
          style: texto,
        ),
      Text(
        '• Agua: ${resultado.aguaPorTubo.toStringAsFixed(2)} µL/tubo → '
        '${(resultado.volumenesTotales['Agua'] ?? 0).toStringAsFixed(2)} µL',
        style: texto,
      ),
      Text('Total: ${resultado.volumenTotal.toStringAsFixed(2)} µL', style: tema.textTheme.titleMedium),
      if (resultado.muestras.isNotEmpty) ...[
        const SizedBox(height: 8),
        Text('Cada tubo con DNA: ${lineaMuestra(resultado.muestras.first)}', style: texto),
      ],
    ];
  }
}
