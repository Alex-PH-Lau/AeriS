// AeriS - Laboratory protocol assistant
// Copyright (C) 2026 Alejandro Pascual Hernández and contributors
// SPDX-License-Identifier: GPL-3.0-or-later
// Additional permission for app stores: see EXCEPCION_TIENDAS.md

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_datos;
import 'package:timezone/timezone.dart' as tz;

/// Lo que AeriS necesita de las notificaciones, sin detalles de ninguna librería.
/// La app usa [NotificacionesSistema]; los tests, una versión falsa.
abstract class ServicioAvisos {
  Future<void> inicializar();

  /// Pide permiso para mostrar notificaciones. Devuelve true si se concede.
  Future<bool> pedirPermiso();

  /// true si el aviso NO podría llegar a la hora exacta y todavía no se ha
  /// preguntado en esta sesión. En Android 14 o posterior, el permiso de
  /// "Alarmas y recordatorios" viene desactivado y lo concede el usuario en
  /// los ajustes. Sin él, Android puede retrasar el aviso varios minutos.
  Future<bool> convienePedirAvisoExacto();

  /// Abre los ajustes del sistema donde se concede ese permiso.
  Future<void> pedirAvisoExacto();

  /// Programa en el sistema un aviso para el momento [fin].
  Future<void> programarFinTemporizador({
    required int id,
    required String titulo,
    required DateTime fin,
  });

  Future<void> cancelar(int id);
}

/// Servicio que usa toda la app. Los tests lo sustituyen antes de empezar.
ServicioAvisos avisos = NotificacionesSistema();

/// Notificaciones reales con flutter_local_notifications. Se programan en el
/// sistema operativo, así que suenan aunque el móvil esté bloqueado.
class NotificacionesSistema implements ServicioAvisos {
  final _plugin = FlutterLocalNotificationsPlugin();
  bool? _permiso; // null = todavía no se ha preguntado
  bool _exactoPreguntado = false; // solo se explica una vez por sesión

  AndroidFlutterLocalNotificationsPlugin? get _android => _plugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  static const _detalles = NotificationDetails(
    android: AndroidNotificationDetails(
      'temporizadores', // id del canal
      'Temporizadores', // nombre visible en los ajustes del móvil
      channelDescription: 'Aviso cuando termina el temporizador de un paso',
      importance: Importance.max,
      priority: Priority.high,
      category: AndroidNotificationCategory.alarm,
    ),
    iOS: DarwinNotificationDetails(presentSound: true),
  );

  @override
  Future<void> inicializar() async {
    tz_datos.initializeTimeZones();

    const ajustes = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      // En iOS no pedir permiso al arrancar: se pide al iniciar el primer temporizador
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      ),
    );
    await _plugin.initialize(settings: ajustes);
  }

  @override
  Future<bool> pedirPermiso() async {
    final yaPreguntado = _permiso;
    if (yaPreguntado != null) return yaPreguntado; // solo se pregunta una vez

    bool? concedido;
    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      concedido = await android.requestNotificationsPermission();
    }
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      concedido = await ios.requestPermissions(alert: true, sound: true);
    }

    // null = el sistema no necesita preguntar (Android 12 o anterior)
    final resultado = concedido ?? true;
    _permiso = resultado;
    return resultado;
  }

  @override
  Future<bool> convienePedirAvisoExacto() async {
    final android = _android;
    if (android == null || _exactoPreguntado) return false; // iOS no lo necesita
    final permitido = await android.canScheduleExactNotifications() ?? true;
    if (permitido) return false;
    _exactoPreguntado = true;
    return true;
  }

  @override
  Future<void> pedirAvisoExacto() async {
    await _android?.requestExactAlarmsPermission();
  }

  @override
  Future<void> programarFinTemporizador({
    required int id,
    required String titulo,
    required DateTime fin,
  }) async {
    if (!fin.isAfter(DateTime.now())) return; // no se programa nada en el pasado

    try {
      await _plugin.zonedSchedule(
        id: id,
        title: '¡Tiempo!',
        body: 'Ha terminado el temporizador de "$titulo".',
        // Es un instante concreto, así que basta con UTC (ver la lección 10)
        scheduledDate: tz.TZDateTime.from(fin, tz.UTC),
        notificationDetails: _detalles,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } on Exception {
      // Sin permiso de alarmas exactas: mejor un aviso algo impreciso que ninguno
      await _plugin.zonedSchedule(
        id: id,
        title: '¡Tiempo!',
        body: 'Ha terminado el temporizador de "$titulo".',
        scheduledDate: tz.TZDateTime.from(fin, tz.UTC),
        notificationDetails: _detalles,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  @override
  Future<void> cancelar(int id) => _plugin.cancel(id: id);
}

/// Para el ordenador (por ahora): sin notificaciones del sistema. Con la app
/// abierta, el aviso de "¡Tiempo!" de la pantalla de ejecución sigue saliendo;
/// lo que no hay es aviso con la app cerrada.
class AvisosSoloEnApp implements ServicioAvisos {
  @override
  Future<void> inicializar() async {}

  @override
  Future<bool> pedirPermiso() async => true;

  @override
  Future<bool> convienePedirAvisoExacto() async => false;

  @override
  Future<void> pedirAvisoExacto() async {}

  @override
  Future<void> programarFinTemporizador({
    required int id,
    required String titulo,
    required DateTime fin,
  }) async {}

  @override
  Future<void> cancelar(int id) async {}
}
