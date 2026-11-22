// AeriS - Laboratory protocol assistant
// Copyright (C) 2026 Alejandro Pascual Hernández and contributors
// SPDX-License-Identifier: GPL-3.0-or-later
// Additional permission for app stores: see EXCEPCION_TIENDAS.md

import 'package:flutter_test/flutter_test.dart';
import 'package:aeris/modelos/cuenta_atras.dart';

void main() {
  // Reloj falso: el test decide qué hora es, sin esperar de verdad
  late DateTime ahora;
  DateTime reloj() => ahora;

  setUp(() {
    ahora = DateTime(2026, 11, 22, 10, 0, 0);
  });

  test('formatearTiempo', () {
    expect(formatearTiempo(0), '00:00');
    expect(formatearTiempo(5), '00:05');
    expect(formatearTiempo(90), '01:30');
    expect(formatearTiempo(3599), '59:59');
    expect(formatearTiempo(3600), '1:00:00');
    expect(formatearTiempo(5400), '1:30:00');
  });

  test('Recién creada está parada y sin empezar', () {
    final cuenta = CuentaAtras(const Duration(minutes: 5), reloj: reloj);

    expect(cuenta.enMarcha, isFalse);
    expect(cuenta.sinEmpezar, isTrue);
    expect(cuenta.restante, const Duration(minutes: 5));
    expect(cuenta.fin, isNull);
  });

  test('Cuenta el tiempo a partir de la hora de fin', () {
    final cuenta = CuentaAtras(const Duration(minutes: 5), reloj: reloj)..iniciar();

    expect(cuenta.fin, DateTime(2026, 11, 22, 10, 5, 0));
    ahora = ahora.add(const Duration(minutes: 2));
    expect(cuenta.restante, const Duration(minutes: 3));
  });

  test('En pausa no corre el tiempo', () {
    final cuenta = CuentaAtras(const Duration(minutes: 5), reloj: reloj)..iniciar();

    ahora = ahora.add(const Duration(minutes: 2));
    cuenta.pausar();
    ahora = ahora.add(const Duration(minutes: 10)); // 10 min de pausa
    expect(cuenta.restante, const Duration(minutes: 3));
    expect(cuenta.sinEmpezar, isFalse);

    cuenta.iniciar(); // reanudar
    ahora = ahora.add(const Duration(minutes: 3));
    expect(cuenta.terminado, isTrue);
  });

  test('Nunca da tiempo negativo', () {
    final cuenta = CuentaAtras(const Duration(seconds: 30), reloj: reloj)..iniciar();

    ahora = ahora.add(const Duration(hours: 1));
    expect(cuenta.restante, Duration.zero);
    expect(cuenta.segundosMostrados, 0);
  });

  test('Los segundos se redondean hacia arriba', () {
    final cuenta = CuentaAtras(const Duration(seconds: 5), reloj: reloj)..iniciar();

    ahora = ahora.add(const Duration(milliseconds: 300)); // quedan 4,7 s
    expect(cuenta.segundosMostrados, 5);
  });

  test('Reiniciar vuelve al principio', () {
    final cuenta = CuentaAtras(const Duration(minutes: 5), reloj: reloj)..iniciar();

    ahora = ahora.add(const Duration(minutes: 4));
    cuenta.reiniciar();
    expect(cuenta.enMarcha, isFalse);
    expect(cuenta.sinEmpezar, isTrue);
    expect(cuenta.restante, const Duration(minutes: 5));
  });
}
