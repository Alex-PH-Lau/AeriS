# Cómo contribuir a AeriS

¡Gracias por tu interés! AeriS es un proyecto abierto y cualquier ayuda cuenta:
reportar errores, proponer ideas, mejorar textos o escribir código.

## Antes de empezar

1. Busca en las [issues](../../issues) por si alguien ya ha propuesto lo mismo.
2. Si no existe, abre una issue nueva y describe el problema o la idea.
3. Para cambios grandes, espera a comentarlo en la issue antes de programar.

## Flujo de trabajo

1. Haz un *fork* del repositorio.
2. Crea una rama a partir de `main` con un nombre descriptivo, por ejemplo `feature/temporizador` o `fix/calculo-mastermix`.
3. Haz commits pequeños y con mensajes claros.
4. Abre un *pull request* hacia `main` explicando qué cambia y por qué.

## Firma de tus commits (DCO)

Cada commit debe ir firmado con la línea `Signed-off-by`. Se añade sola con:

```bash
git commit -s -m "Mensaje del commit"
```

Con esa firma declaras que tienes derecho a aportar ese código y que aceptas
publicarlo bajo la **GPLv3 con el permiso adicional para tiendas de aplicaciones**
descrito en [EXCEPCION_TIENDAS.md](EXCEPCION_TIENDAS.md), según el
[Developer Certificate of Origin](https://developercertificate.org/).

## Convenciones

- Código, nombres de variables y comentarios en inglés.
- Textos de la interfaz en español, siempre en los archivos de traducción y nunca escritos directamente en el código.
- Cada archivo de código nuevo empieza con esta cabecera:

```dart
// AeriS - Laboratory protocol assistant
// Copyright (C) 2026 [TU NOMBRE COMPLETO] and contributors
// SPDX-License-Identifier: GPL-3.0-or-later
// Additional permission for app stores: see EXCEPCION_TIENDAS.md
```

## Cálculos

Cualquier cambio en la lógica de cálculo de reactivos debe incluir pruebas
automáticas con un ejemplo calculado a mano. Un error ahí puede estropear un experimento.
