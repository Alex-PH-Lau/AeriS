// AeriS - Laboratory protocol assistant
// Copyright (C) 2026 Alejandro Pascual Hernández and contributors
// SPDX-License-Identifier: GPL-3.0-or-later
// Additional permission for app stores: see EXCEPCION_TIENDAS.md

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:aeris/modelos/calculo.dart';
import 'package:aeris/modelos/cuenta_atras.dart';
import 'package:aeris/modelos/ejecucion.dart';
import 'package:aeris/modelos/entradas.dart';
import 'package:aeris/modelos/paso.dart';
import 'package:aeris/modelos/protocolo.dart';
import 'package:aeris/pantallas/widgets/avisos.dart';
import 'package:aeris/pantallas/widgets/vista_calculo.dart';
import 'package:aeris/pantallas/widgets/vista_temporizador.dart';
import 'package:aeris/servicios/almacen.dart';
import 'package:aeris/servicios/avisos.dart';

class PantallaEjecucion extends StatefulWidget {
  final Protocolo protocolo;
  final EntradaCuaderno? continuar; // si se reanuda una ejecución "En proceso"

  const PantallaEjecucion({super.key, required this.protocolo, this.continuar});

  @override
  State<PantallaEjecucion> createState() => _PantallaEjecucionState();
}

class _PantallaEjecucionState extends State<PantallaEjecucion> {
  int pasoActual = 0;

  // Datos introducidos durante esta ejecución. Viven aquí, y no en cada paso,
  // para no perderlos al ir atrás y adelante.
  final Map<String, String> valores = {}; // 'Lote de la Taq' → 'A123'
  List<Muestra> muestras = [];
  int _contadorMuestras = 0; // para dar un id único a cada fila nueva

  // La página del cuaderno de esta ejecución y su id en la base de datos
  late Ejecucion _ejecucion;
  late final Future<int> _idEjecucion;

  // Temporizadores y alertas
  final Map<int, CuentaAtras> cuentas = {}; // índice del paso → su cuenta atrás
  final Set<int> alertasVistas = {}; // pasos cuya alerta ya se ha confirmado
  final Set<int> finesAvisados = {}; // temporizadores cuyo fin ya se ha avisado
  Timer? _tic; // despierta la pantalla cada segundo

  @override
  void initState() {
    super.initState();
    final pasos = widget.protocolo.pasos;
    final anterior = widget.continuar;

    if (anterior != null) {
      // Reanudar: recuperar lo que se había guardado
      _ejecucion = anterior.ejecucion;
      _idEjecucion = Future.value(anterior.id);
      valores.addAll(anterior.ejecucion.valoresIntroducidos);
      muestras = List.of(anterior.ejecucion.muestras);
      pasoActual = min(anterior.ejecucion.pasoParaReanudar, pasos.length - 1);
      for (var i = 0; i < pasoActual; i++) {
        alertasVistas.add(i); // las alertas de los pasos ya hechos no se repiten
      }
    } else {
      // Empezar: crear la página del cuaderno
      _ejecucion = Ejecucion(
        protocoloId: widget.protocolo.id,
        protocoloVersion: widget.protocolo.version,
        inicio: DateTime.now(),
      );
      _idEjecucion = almacen.crearEjecucion(_ejecucion);
    }

    // La tabla de muestras empieza con los controles del primer paso de cálculo
    if (muestras.isEmpty) {
      for (final paso in pasos) {
        if (paso is PasoCalculo) {
          muestras = muestrasIniciales(paso);
          break;
        }
      }
    }

    // Una cuenta atrás por cada paso con temporizador
    for (var i = 0; i < pasos.length; i++) {
      final temporizador = pasos[i].temporizador;
      if (temporizador != null) cuentas[i] = CuentaAtras(temporizador.duracion);
    }

    _tic = Timer.periodic(const Duration(seconds: 1), (_) => _alTic());

    // La alerta del primer paso se muestra cuando la pantalla ya está dibujada
    WidgetsBinding.instance.addPostFrameCallback((_) => _alEntrarEnPaso(pasoActual));
  }

  @override
  void dispose() {
    _tic?.cancel(); // sin esto, el Timer seguiría vivo tras cerrar la pantalla

    // Si se sale del protocolo, los avisos pendientes ya no tienen sentido
    for (final entrada in cuentas.entries) {
      if (entrada.value.enMarcha && !entrada.value.terminado) {
        avisos.cancelar(entrada.key);
      }
    }

    // Guardar lo escrito aunque no se haya avanzado de paso, para poder reanudar
    if (_ejecucion.estado == EstadoEjecucion.enProceso) {
      _ejecucion = _ejecucion.conDatos(
        valoresIntroducidos: Map.of(valores),
        muestras: List.of(muestras),
      );
      _guardar();
    }
    super.dispose();
  }

  // ---------- Cuaderno ----------

  Future<void> _guardar() async {
    final id = await _idEjecucion;
    await almacen.actualizarEjecucion(id, _ejecucion);
  }

  /// Apunta en el cuaderno que el paso actual se ha completado.
  void _registrarPasoActual() {
    _ejecucion = _ejecucion
        .conDatos(valoresIntroducidos: Map.of(valores), muestras: List.of(muestras))
        .completarPaso(pasoActual);
  }

  // ---------- Temporizadores ----------

  void _alTic() {
    // Solo trabajar si hay alguna cuenta corriendo cuyo fin no se ha avisado
    final hayActivas = cuentas.entries.any(
      (entrada) => entrada.value.enMarcha && !finesAvisados.contains(entrada.key),
    );
    if (!hayActivas) return;
    setState(() {}); // redibujar la cuenta atrás

    for (final entrada in cuentas.entries) {
      final indice = entrada.key;
      final cuenta = entrada.value;
      if (cuenta.enMarcha && cuenta.terminado && !finesAvisados.contains(indice)) {
        finesAvisados.add(indice);
        _avisarFin(indice);
      }
    }
  }

  Future<void> _avisarFin(int indice) async {
    HapticFeedback.heavyImpact();
    SystemSound.play(SystemSoundType.alert);
    await mostrarFinTemporizador(context, widget.protocolo.pasos[indice].titulo);
    // Ya lo has visto en la app: quitar la notificación de la bandeja
    await avisos.cancelar(indice);
  }

  void iniciarTemporizador(int indice) {
    setState(() => cuentas[indice]?.iniciar());
    _programarAviso(indice);
  }

  void pausarTemporizador(int indice) {
    setState(() => cuentas[indice]?.pausar());
    avisos.cancelar(indice); // al reanudar se programará con la nueva hora de fin
  }

  void reiniciarTemporizador(int indice) {
    setState(() {
      cuentas[indice]?.reiniciar();
      finesAvisados.remove(indice);
    });
    avisos.cancelar(indice);
  }

  /// Programa en el sistema la notificación para la hora de fin del temporizador.
  Future<void> _programarAviso(int indice) async {
    final fin = cuentas[indice]?.fin;
    if (fin == null) return;

    final permitido = await avisos.pedirPermiso();
    if (!permitido) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Sin permiso de notificaciones: el temporizador solo avisará con AeriS abierta.',
          ),
        ),
      );
      return;
    }

    await avisos.programarFinTemporizador(
      id: indice,
      titulo: widget.protocolo.pasos[indice].titulo,
      fin: fin,
    );
  }

  /// ¿Hay un temporizador corriendo en este paso que todavía no ha terminado?
  bool _temporizadorPendiente(int indice) {
    final cuenta = cuentas[indice];
    return cuenta != null && cuenta.enMarcha && !cuenta.terminado;
  }

  // ---------- Alertas ----------

  /// Muestra la alerta del paso la primera vez que se llega a él.
  Future<void> _alEntrarEnPaso(int indice) async {
    final alerta = widget.protocolo.pasos[indice].alerta;
    if (alerta == null || alertasVistas.contains(indice)) return;
    alertasVistas.add(indice);
    if (!mounted) return;
    await mostrarAlerta(context, alerta);
  }

  // ---------- Datos del paso de cálculo ----------

  void actualizarValor(String clave, String valor) {
    setState(() {
      valores[clave] = valor;
    });
  }

  void anadirMuestra(String tipo) {
    setState(() {
      _contadorMuestras++;
      // Hora + contador: no choca con las filas de una ejecución reanudada
      final id = '${DateTime.now().microsecondsSinceEpoch}-$_contadorMuestras';
      muestras.add(Muestra(id: id, tipo: tipo));
    });
  }

  void actualizarMuestra(int indice, Muestra muestra) {
    setState(() {
      muestras[indice] = muestra;
    });
  }

  void eliminarMuestra(int indice) {
    setState(() {
      muestras.removeAt(indice);
    });
  }

  // ---------- Navegación entre pasos ----------

  /// ¿Se puede salir del paso actual? Los de cálculo necesitan datos válidos.
  bool get pasoActualCompleto {
    final paso = widget.protocolo.pasos[pasoActual];
    return switch (paso) {
      PasoInstrucciones() => true,
      PasoCalculo p => calculoCompleto(p, muestras, valores),
    };
  }

  Future<void> siguiente() async {
    // Seguros: no pasar del último paso ni avanzar con datos incompletos
    if (pasoActual >= widget.protocolo.numeroPasos - 1) return;
    if (!pasoActualCompleto) return;

    if (_temporizadorPendiente(pasoActual)) {
      final avanzar = await confirmarAvanceConTemporizador(context);
      if (!avanzar || !mounted) return;
    }

    _registrarPasoActual();
    _guardar();
    setState(() {
      pasoActual++;
    });
    await _alEntrarEnPaso(pasoActual);
  }

  void anterior() {
    // Seguro: no bajar del primer paso
    if (pasoActual <= 0) return;
    setState(() {
      pasoActual--;
    });
  }

  Future<void> terminar() async {
    if (_temporizadorPendiente(pasoActual)) {
      final avanzar = await confirmarAvanceConTemporizador(context);
      if (!avanzar || !mounted) return;
    }

    _registrarPasoActual();
    _ejecucion = _ejecucion.terminar();
    await _guardar();
    if (!mounted) return;

    await showDialog<void>(
      context: context,
      barrierDismissible: false, // no se cierra tocando fuera
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.check_circle, size: 64),
        title: const Text('¡Protocolo completado!'),
        content: Text(
          'Has terminado "${widget.protocolo.nombreCompleto}".',
          style: const TextStyle(fontSize: 18),
        ),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size(double.infinity, 72),
            ),
            onPressed: () => Navigator.pop(dialogContext), // 1er pop: cierra el diálogo
            child: const Text('Volver', style: TextStyle(fontSize: 22)),
          ),
        ],
      ),
    );

    if (!mounted) return;
    Navigator.pop(context); // 2º pop: vuelve a la lista
  }

  // ---------- Pantalla ----------

  @override
  Widget build(BuildContext context) {
    final protocolo = widget.protocolo;
    final total = protocolo.numeroPasos;
    final paso = protocolo.pasos[pasoActual];
    final alerta = paso.alerta;
    final cuenta = cuentas[pasoActual];
    final esPrimero = pasoActual == 0;
    final esUltimo = pasoActual == total - 1;
    final puedeAvanzar = pasoActualCompleto;

    return Scaffold(
      appBar: AppBar(
        title: Text(protocolo.nombreCompleto),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Paso ${pasoActual + 1} de $total',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: (pasoActual + 1) / total,
                minHeight: 12,
              ),
              const SizedBox(height: 32),
              Text(
                paso.titulo,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (alerta != null) ...[
                        RecordatorioAlerta(alerta: alerta),
                        const SizedBox(height: 16),
                      ],
                      switch (paso) {
                        PasoInstrucciones p => Text(
                            p.texto,
                            style: const TextStyle(fontSize: 26, height: 1.4),
                          ),
                        PasoCalculo p => VistaCalculo(
                            paso: p,
                            muestras: muestras,
                            valores: valores,
                            onCambioValor: actualizarValor,
                            onCambioMuestra: actualizarMuestra,
                            onAnadirMuestra: anadirMuestra,
                            onEliminarMuestra: eliminarMuestra,
                          ),
                      },
                      if (cuenta != null) ...[
                        const SizedBox(height: 24),
                        VistaTemporizador(
                          cuenta: cuenta,
                          onIniciar: () => iniciarTemporizador(pasoActual),
                          onPausar: () => pausarTemporizador(pasoActual),
                          onReiniciar: () => reiniciarTemporizador(pasoActual),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 96,
                      child: OutlinedButton.icon(
                        onPressed: esPrimero ? null : anterior,
                        icon: const Icon(Icons.arrow_back, size: 32),
                        label: const Text('Anterior', style: TextStyle(fontSize: 22)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SizedBox(
                      height: 96,
                      child: FilledButton.icon(
                        onPressed: !puedeAvanzar
                            ? null
                            : (esUltimo ? terminar : siguiente),
                        icon: Icon(esUltimo ? Icons.check : Icons.arrow_forward, size: 32),
                        label: Text(
                          esUltimo ? 'Terminar' : 'Siguiente',
                          style: const TextStyle(fontSize: 22),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
