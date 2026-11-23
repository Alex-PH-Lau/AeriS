## Para qué sirve

El paso de cálculo prepara el **mastermix**: a partir de los reactivos y del número de tubos, calcula cuánto poner de cada cosa. Si las muestras tienen concentraciones distintas, calcula también el **DNA y el agua de cada tubo**.

## Configurarlo en el editor

- **Volumen por tubo** y **margen** (un extra, normalmente un 10 %, por lo que se pierde al pipetear).
- **DNA molde**:
  - **Normalizar ng**: todos los tubos llevan los mismos *ng* de DNA. Indica los ng por reacción y el volumen mínimo que puedes pipetear.
  - **Volumen fijo**: todos los tubos llevan los mismos µL de DNA.
- **Reactivos**: nombre, concentración (opcional) y µL por tubo. **Sin el agua**: AeriS calcula la que falta.
- **Tipos de tubo**: las **muestras** (con DNA, se añaden al ejecutar) y los **controles** (por ejemplo, un control negativo con agua).
- **Datos que se apuntan al ejecutar**: por ejemplo, el lote de la polimerasa.

Abajo, la **vista previa** calcula un ejemplo con 3 muestras para comprobar que todo tiene sentido.

## Al ejecutarlo

Añade las muestras con su **código** y su **concentración** (ng/µL). AeriS te dice para cada una:

- cuánto **DNA** y cuánta **agua** poner;
- si está **demasiado concentrada**, cuánto diluirla (1:10, 1:20…);
- si está **demasiado diluida**, que llenes el hueco solo con DNA.

> Revisa siempre que los volúmenes tienen sentido antes de pipetear. AeriS calcula lo que le pides, pero no sabe si te has equivocado al escribir una concentración.
