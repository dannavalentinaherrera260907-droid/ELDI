# EchoSpectrum

Procesador de audio con eco y analizador de espectro en la FPGA **Tang Nano 9K**.
Proyecto final de Electrónica Digital (ELDI) · Escuela Colombiana de Ingeniería Julio Garavito.

**Autores:** David Eduardo Martínez Gutiérrez · Danna Valentina Herrera

El sistema digitaliza audio con el ADC PCM1808, le aplica eco (y otros efectos ajustables), lo saca por PWM a un parlante y muestra el nivel de cuatro bandas de frecuencia en una matriz LED 8×8 (MAX7219). Cuatro perillas (MCP3008) y dos botones controlan los parámetros.

## Requisitos del proyecto

| Requisito | Cómo se cumple |
|---|---|
| Muestreo ≥ 40 kHz | fs = 27 MHz / 512 = **52 734 Hz** (bit 8 del `contador_maestro`) |
| Eco ajustable | `modulo_eco`: memoria BRAM circular de 16 384 × 12 bits (hasta 0,31 s), × k/8 con multiplexores y sumadores |
| Salida PWM | `salida_pwm`: PWM de 8 bits a 105 kHz + filtro RC + PAM8403 |
| Barras de frecuencia | `banco_filtros` → `envelope` → `barras_matriz` → `driver_matriz` |
| Lógica explicable | Solo registros, sumadores, comparadores, multiplexores y compuertas; sin PLL ni multiplicadores DSP |

## Estructura del repositorio

```
rtl/          un archivo por módulo (Echospectrum.v es el módulo principal)
tb/           banco de pruebas autoverificado
constraints/  pines (.cst) y reloj (.sdc) para Gowin
sim/          scripts para simular
docs/         informe IEEE (PDF), diagramas (draw.io y PNG)
```

## Módulos (`rtl/`)

| Archivo | Función | Entradas → salidas |
|---|---|---|
| `contador_maestro.v` | Relojes del ADC | clk → cnt[8:0], scki, bck, lrck |
| `receptor_i2s.v` | Receptor I2S | cnt[8:0], dout → left[23:0], right[23:0], tick |
| `mezcla.v` | (L + R)/2 | left, right, tick → mono[11:0], mono_valid |
| `distorsion.v` | Ganancia ×1…×8 y saturación | x[11:0], sh[1:0] → y[11:0] |
| `modulo_eco.v` | Eco con memoria BRAM | x[11:0], delay_t[13:0], k_fb[2:0], k_mix[2:0], tone_s[1:0] → y, dry[11:0], clip |
| `modo_y_volumen.v` | Modo eco/directo, efecto «robot», volumen | x_eco, x_dry[11:0], mode, crush_n[2:0], vol[3:0] → y[11:0] |
| `salida_pwm.v` | PWM de 8 bits | x[11:0], cnt8[7:0] → pwm |
| `banco_filtros.v` | 3 filtros de un polo → 4 bandas | x[11:0] → b0…b3[16:0] |
| `envelope.v` | Envolvente de una banda (se usa ×4) | b[16:0] → level[3:0] |
| `level_enc.v` | Codificador de prioridad (nivel 0…8) | v[16:0] → lvl[3:0] |
| `barras_matriz.v` | Barras 8×8 (64 comparadores) | lvl0…lvl3[3:0] → cols[63:0] |
| `driver_matriz.v` | FSM SPI del MAX7219 | cols[63:0], bright[3:0] → din, clk_o, cs_n |
| `lector_mcp3008.v` | FSM SPI del MCP3008 | dout → cs_n, sclk, din, pot0…pot3[9:0] |
| `antirrebote.v` | Antirrebote + detector de flanco (se usa ×2) | btn_n → pressed, press_pulse |
| `Echospectrum.v` | Módulo principal; incluye `control_parametros` (modo, página, registros de parámetros y LEDs) | pines de la placa |

Parámetros: `DB_N` (antirrebote, 19 → 19 ms), `REFRESH_BITS` (refresco de la matriz, 20 → 39 ms), `MAT_FLIP_X`, `MAT_FLIP_Y` (orientación de la matriz).

## Hardware y pines

Tang Nano 9K (GW1NR-LV9QN88P, reloj de 27 MHz), PCM1808 en modo esclavo I2S (MD0 = MD1 = FMT = GND), MCP3008 con 4 potenciómetros de 10 kΩ, matriz 8×8 con MAX7219, filtro RC y amplificador PAM8403.

| Señal | Pin | Señal | Pin |
|---|---|---|---|
| clk (27 MHz) | 52 | pwm_out | 25 |
| scki | 27 | mat_din / mat_clk / mat_cs | 26 / 33 / 34 |
| lrck | 28 | mcp_cs_n / mcp_clk | 31 / 32 |
| dout (ADC) | 29 | mcp_din / mcp_dout | 49 / 48 |
| bck | 30 | btn_a_n / btn_b_n | 3 / 4 |
| led_n[5:0] | 10, 11, 13, 14, 15, 16 | | |

El diagrama de conexiones está en `docs/diagramas/conexiones_externas.png`.

**Controles.** Botón A: eco / directo. Botón B: página 1 / página 2.
Página 1: RV1 retardo · RV2 realimentación · RV3 mezcla · RV4 volumen.
Página 2: RV1 tono · RV2 distorsión · RV3 «robot» · RV4 brillo.

## Cómo sintetizar (Gowin EDA 1.9.12.03)

1. Crear un proyecto nuevo para el dispositivo **GW1NR-LV9QN88PC6/I5** (Tang Nano 9K).
2. Agregar todos los archivos de `rtl/` y los de `constraints/` (`EchoSpectrum.cst` y `EchoSpectrum.sdc`).
3. *Project → Configuration → Synthesize*: módulo principal **Echospectrum**.
4. Ejecutar **Synthesize** y **Place & Route**.
5. Programar la placa con **Programmer** (SRAM o Flash).

## Cómo simular (Icarus Verilog + GTKWave)

Desde la carpeta principal del repositorio:

```sh
iverilog -g2012 -o sim/sim.vvp rtl/*.v tb/tb_Echospectrum.v
cd sim && vvp sim.vvp
gtkwave echospectrum.vcd
```

O ejecutar `sim/correr_simulacion.sh` (Linux) o `sim/correr_simulacion.bat` (Windows).

### Pruebas del banco autoverificado (`tb/tb_Echospectrum.v`)

El banco de pruebas incluye modelos del PCM1808 (envía silencio, tonos o un impulso por I2S), del MCP3008 (perillas fijas: D = 1025, k_fb = 4/8, k_mix = 7/8, volumen 15/16) y del MAX7219 (reconstruye la imagen). Cada prueba compara lo obtenido con el valor calculado y escribe PASA o FALLA.

| # | Prueba | Esperado | Obtenido |
|---|---|---|---|
| 1 | Frecuencia de muestreo | ≥ 40 kHz | 52 734 Hz (LRCK = 18 963 ns) |
| 2 | Mezcla (L + R)/2 en todas las muestras | 0 errores | 7480 muestras, 0 errores |
| 3 | PWM en silencio | duty = 128 (50 %) | 128 |
| 6 | Eco: retardo | 1025 muestras | 1025 y 1025 |
| 6 | Eco: primer eco (mezcla 7/8) | 896 | 896 |
| 6 | Eco: segundo eco (realimentación 4/8) | 448 | 448 |
| 4 | Tono de 100 Hz | barra de graves la más alta | 6 / 5 / 4 / 3 |
| 5 | Tono de 6 kHz | barra de agudos la más alta | 5 / 4 / 4 / 6 |
| 7 | Botón A | modo directo, LED0 apagado | modo = 0, LED0 = 1 |

Resultado: **9 pruebas pasan, 0 fallan.**

Casos de frontera cubiertos: silencio (PWM al 50 %), impulso aislado (respuesta del eco y decaimiento con k_fb < 1), tono grave y tono agudo (separación de bandas), botón con antirrebote (un solo cambio de modo).

Para la simulación, `DB_N = 4` y `REFRESH_BITS = 14` acortan el antirrebote y el refresco de la matriz.

## Uso de IA

Se usó **Claude (Anthropic)** como asistente:

- **Código:** los archivos de `rtl/` y `tb/tb_Echospectrum.v` fueron generados con asistencia de IA a partir de los requisitos, la arquitectura y las decisiones del grupo. Cada archivo lo indica en su primera línea. El grupo los revisó, los ajustó y los explica línea por línea.
- **Arquitectura y diagramas:** la IA ayudó a organizar la arquitectura, a dibujar los diagramas (`docs/*.drawio`) y a escribir los modelos de verificación.
- **Trabajo propio del grupo:** elección del proyecto y de los componentes, requisitos, estudio de las hojas de datos (PCM1808, MCP3008, MAX7219), montaje y depuración del prototipo, y decisiones de diseño.
- **Redacción:** la IA ayudó a estructurar y redactar el informe y este README; el contenido técnico fue revisado por el grupo.

Archivos con código generado con IA: todos los de `rtl/`, `tb/tb_Echospectrum.v` y los scripts de `sim/`.

## Documentación

- `docs/EchoSpectrum_Informe_IEEE.pdf`: informe IEEE.
- `docs/EchoSpectrum_Esquematicos.drawio`: todos los esquemáticos (18 hojas).
- `docs/EchoSpectrum_logica_completa.drawio`: los mismos diagramas con las marcas numeradas.
- `docs/diagramas/`: diagrama de bloques, máquinas de estados, diagramas de tiempo SPI y conexiones externas.
