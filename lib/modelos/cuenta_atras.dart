// AeriS - Laboratory protocol assistant
// Copyright (C) 2026 Alejandro Pascual Hernández and contributors
// SPDX-License-Identifier: GPL-3.0-or-later
// Additional permission for app stores: see EXCEPCION_TIENDAS.md

/// Formato de reloj: 90 → "01:30"; 5400 → "1:30:00".
String formatearTiempo(int segundos) {
  final horas = segundos ~/ 3600;
  final minutos = ((segundos % 3600) ~/ 60).toString().padLeft(2, '0');
  final segs = (segundos % 60).toString().padLeft(2, '0');
  if (horas > 0) return '$horas:$minutos:$segs';
  return '$minutos:$segs';
}

/// Cuenta atrás robusta: guarda la HORA DE FIN, no los segundos que quedan
/// (lección 3). Así no se retrasa aunque la app se duerma.
///
/// A diferencia de los modelos, este objeto SÍ cambia: es un "controlador"
/// que la pantalla guarda y manipula.
class CuentaAtras {
  final Duration duracion;
  final DateTime Function() _reloj; // de dónde saca la hora (los tests usan uno falso)
  DateTime? _fin; // no es null mientras está en marcha
  Duration _restantePausado; // lo que queda cuando está parada

  CuentaAtras(this.duracion, {DateTime Function()? reloj})
      : _reloj = reloj ?? DateTime.now,
        _restantePausado = duracion;

  bool get enMarcha => _fin != null;

  /// Momento en que terminará, o null si está parada. Servirá para programar
  /// la notificación del sistema.
  DateTime? get fin => _fin;

  Duration get restante {
    final fin = _fin;
    if (fin == null) return _restantePausado;
    final quedan = fin.difference(_reloj());
    return quedan.isNegative ? Duration.zero : quedan;
  }

  bool get terminado => restante == Duration.zero;

  bool get sinEmpezar => !enMarcha && _restantePausado == duracion;

  /// Segundos que se muestran, redondeados hacia arriba (lección 3).
  int get segundosMostrados => (restante.inMilliseconds / 1000).ceil();

  void iniciar() {
    if (enMarcha || terminado) return;
    _fin = _reloj().add(_restantePausado);
  }

  void pausar() {
    if (!enMarcha) return;
    _restantePausado = restante;
    _fin = null;
  }

  void reiniciar() {
    _fin = null;
    _restantePausado = duracion;
  }
}
