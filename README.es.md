[English](README.md) | [Português](README.pt-BR.md) | **Español**

# REAPER Scrolling Chords

Interfaz web para [REAPER](https://www.reaper.fm) que muestra la **letra con acordes** de la canción que se está reproduciendo, desplazándose junto con la reproducción. Pensada para verse en el navegador de móviles, tabletas y pantallas grandes en la misma red local.

Basada en los scripts y la interfaz *Scrolling Lyrics / Scrolling Chords* de [X-Raym](https://github.com/X-Raym/REAPER-ReaScripts).

## Funciones

- **Letra sincronizada:** cada ítem con notas de la pista `Lyrics` se convierte en un bloque, resaltado y centrado mientras suena. Tocar un bloque lleva a REAPER hasta él.
- **Dos formatos de cifrado**, que se pueden mezclar en la misma canción:
  - **Texto con acordes encima de la letra** (el formato tradicional).
  - **[ChordPro](https://www.chordpro.org)**: `[G]Grande é o [C9]Senhor`, con soporte para `{title}`, `{key}`, `{capo}`, comentarios, estribillo/estrofa/puente y tablatura.
- **Transposición:** botones ⊖ / ⊕, lista con los 12 tonos a partir de C y las teclas `+` `-` `0`. Sostenidos o bemoles según el tono de destino.
- **Tono detectado automáticamente** a partir de todos los acordes de la canción, cuando no hay `{key}`.
- **Acordes opcionales** entre paréntesis, como `(Em)`.
- **Modo "solo letra"** para quien canta: tecla `C` o `?nochords`.
- **Se ajusta a la pantalla:** la fuente se adapta para que quepa la línea más ancha, en vertical u horizontal, sin desalinear los acordes.
- **Compartir con código QR**, con la IP de la red detectada por el script. Funciona sin internet.
- **Inglés, portugués y español**, según el idioma del navegador de cada dispositivo. El mensaje del script sigue el paquete de idioma de REAPER o el idioma del sistema.

## Archivos

| Archivo | Dónde instalarlo |
|---|---|
| `scripts/Convert Lyrics track items notes for scrolling web browser interface.lua` | Carpeta `Scripts` de REAPER |
| `web/Scrolling Chords ChordPro.html` | Carpeta `reaper_www_root` de REAPER |
| `web/qrcode.js` | Carpeta `reaper_www_root`, junto al HTML |

Las carpetas de REAPER están en el directorio de recursos (*Options › Show REAPER resource path*). En Linux es `~/.config/REAPER`.

## Instalación

1. Copia los archivos (o crea enlaces simbólicos) en las carpetas de la tabla anterior.
2. En REAPER, carga el script: *Actions › Show action list › New action › Load ReaScript…*. Si quieres, asígnale un atajo.
3. En *Options › Preferences › Control/OSC/Web*, añade una **Web browser interface** y elige `Scrolling Chords ChordPro.html` como página.

## Uso

1. Crea una pista llamada **Lyrics** (mayúsculas o minúsculas, da igual).
2. Para cada parte de la canción, crea un ítem en esa pista y escribe la letra con los acordes en las **notas del ítem**.
3. Ejecuta el script. Vuelve a ejecutarlo cada vez que edites las notas.
4. Abre la interfaz web en el navegador. Para abrirla en otro dispositivo, usa el botón de compartir (código QR).

### Ejemplo: formato tradicional

```
G9            C9                    G
Grande é o Senhor e mui digno de louvor
     C9                            Em
Na cidade do nosso Deus, Seu Santo monte
```

### Ejemplo: ChordPro

```
{title: Grande é o Senhor}
{key: G}
{soc: Refrão}
[G9]Grande é o [C9]Senhor e mui digno de lou[G]vor
Na ci[C9]dade do nosso Deus, Seu Santo [Em]monte
{eoc}
```

### Parámetros de la URL

| Parámetro | Efecto |
|---|---|
| `?transpose=2` | Abre transpuesto (en semitonos) |
| `?nochords` | Solo la letra |
| `?hidecontrols` | Oculta los controles (para proyector o TV) |
| `?maxsize=70` | Tamaño máximo de la fuente, en px (por defecto 52) |
| `?fullheight` | Un bloque por pantalla, incluidos los intervalos sin letra |
| `?vignette` | Oscurece los bordes de la pantalla |
| `?font=Nombre` | Fuente de la página |
| `?lang=en` / `pt` / `es` | Fuerza el idioma (por defecto el del navegador; otros idiomas pasan al inglés) |

### Atajos de teclado

| Tecla | Acción |
|---|---|
| `Espacio` | Play / Stop en REAPER |
| `+` / `-` | Sube / baja medio tono |
| `0` | Vuelve al tono original |
| `C` | Muestra / oculta los acordes |
| `Esc` | Cierra los menús |

## Cómo funciona

El script Lua lee las notas de los ítems de la pista `Lyrics` y las publica como JSON en el ExtState `XR_Lyrics/json`. También publica las IPs de red del equipo en `XR_Lyrics/host_ips`. La página web pide estos datos a REAPER a través de la API de la interfaz web (`main.js`, que viene con REAPER) y sigue la posición de reproducción para resaltar la parte actual.

## Créditos y licencia

- Basado en el trabajo de [X-Raym](https://www.extremraym.com) ([REAPER-ReaScripts](https://github.com/X-Raym/REAPER-ReaScripts)), con licencia **GPL v3**.
- `web/qrcode.js`: [qrcode-generator](https://github.com/kazuhikoarase/qrcode-generator) 1.4.4 de Kazuhiko Arase, licencia **MIT** (aviso de copyright en el propio archivo). "QR Code" es una marca registrada de DENSO WAVE INCORPORATED.

Este proyecto se distribuye bajo la **GNU General Public License v3.0**. Consulta el archivo [LICENSE](LICENSE).
