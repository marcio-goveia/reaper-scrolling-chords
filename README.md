**English** | [Português](README.pt-BR.md) | [Español](README.es.md)

# REAPER Scrolling Chords

A web interface for [REAPER](https://www.reaper.fm) that shows the **lyrics with chords** of the song being played, scrolling along with playback. Made to be viewed in the browser of phones, tablets and large screens on the same local network.

Based on the *Scrolling Lyrics / Scrolling Chords* scripts and interface by [X-Raym](https://github.com/X-Raym/REAPER-ReaScripts).

## Features

- **Synced lyrics:** each item note on the `Lyrics` track becomes a block, highlighted and centered while it plays. Tapping a block moves REAPER to it.
- **Always up to date:** the script runs in the background and follows the active project tab. Switching tabs or editing the notes updates the page by itself, and it can start together with REAPER.
- **Two chord formats**, which can be mixed in the same song:
  - **Text with chords above the lyrics** (the traditional format).
  - **[ChordPro](https://www.chordpro.org)**: `[G]Grande é o [C9]Senhor`, with support for `{title}`, `{key}`, `{capo}`, comments, chorus/verse/bridge and tablature.
- **Transposition:** ⊖ / ⊕ buttons, a list of the 12 keys starting from C, and the `+` `-` `0` keys. Sharps or flats according to the target key.
- **Automatic key detection** from all the chords of the song, when there is no `{key}`.
- **Optional chords** in parentheses, like `(Em)`.
- **Lyrics-only mode** for singers: `C` key or `?nochords`.
- **Fade out on Space:** with the **Fade** button on, the Space key fades the master volume out, stops, and puts the volume back. With it off, Space stops at once, as in REAPER. The choice is saved on each device.
- **Fits the screen:** the font adapts so the widest line fits, in portrait or landscape, without misaligning the chords.
- **Share via QR code**, with the network IP detected by the script. Works without internet.
- **English, Portuguese and Spanish**, following the browser language of each device.

## Files

| File | Where to install |
|---|---|
| `scripts/Convert Lyrics track items notes for scrolling web browser interface.lua` | REAPER `Scripts` folder |
| `web/Scrolling Chords ChordPro.html` | REAPER `reaper_www_root` folder |
| `web/qrcode.js` | REAPER `reaper_www_root` folder, next to the HTML |
| `scripts/__startup.lua` | REAPER `Scripts` folder (optional: starts the script with REAPER) |

The REAPER folders are in the resource path (*Options › Show REAPER resource path*). On Linux it is `~/.config/REAPER`.

## Installation

1. Copy the files (or create symbolic links) to the folders in the table above.
2. In REAPER, load the script: *Actions › Show action list › New action › Load ReaScript…*. Assign it a shortcut if you like.
3. In *Options › Preferences › Control/OSC/Web*, add a **Web browser interface** and choose `Scrolling Chords ChordPro.html` as the page.
4. Optional: copy `scripts/__startup.lua` to the `Scripts` folder, so the script starts every time REAPER opens. If you already have a `__startup.lua`, paste its code at the end of yours.

## Usage

1. Create a track named **Lyrics** (upper or lower case, it doesn't matter).
2. For each part of the song, create an item on that track and write the lyrics with the chords in the **item notes**.
3. Run the script once (or let `__startup.lua` start it). It keeps running in the background: switching project tabs or editing the notes updates the page. Running the action again stops it. If you add the action to a toolbar (right-click a toolbar › *Customize toolbar…*), its button is lit while the script runs.
4. Open the web interface in the browser. To open it on another device, use the share button (QR code).

### Example: traditional format

```
G9            C9                    G
Grande é o Senhor e mui digno de louvor
     C9                            Em
Na cidade do nosso Deus, Seu Santo monte
```

### Example: ChordPro

```
{title: Grande é o Senhor}
{key: G}
{soc: Refrão}
[G9]Grande é o [C9]Senhor e mui digno de lou[G]vor
Na ci[C9]dade do nosso Deus, Seu Santo [Em]monte
{eoc}
```

### URL parameters

| Parameter | Effect |
|---|---|
| `?transpose=2` | Opens transposed (in semitones) |
| `?nochords` | Lyrics only |
| `?hidecontrols` | Hides the controls (for a projector or TV) |
| `?maxsize=70` | Maximum font size, in px (default 52) |
| `?fullheight` | One block per screen, including the gaps without lyrics |
| `?vignette` | Darkens the edges of the screen |
| `?font=Name` | Page font |
| `?fadeout` | Turns **Fade** on |
| `?fadetime=6` | Fade length in seconds (default 4) |
| `?lang=en` / `pt` / `es` | Forces the language (default is the browser's; other languages fall back to English) |

### Keyboard shortcuts

| Key | Action |
|---|---|
| `Space` | Play / Stop in REAPER (with **Fade** on: fade out, then stop; press again to stop at once) |
| `+` / `-` | Half step up / down |
| `0` | Back to the original key |
| `C` | Show / hide chords |
| `F` | Turns **Fade** on / off |
| `Esc` | Closes menus |

## How it works

The Lua script runs in the background. It watches the active project tab and its undo history, and re-reads everything once per second for changes the history doesn't show. It reads the notes of the items on the `Lyrics` track and publishes them as JSON in the `XR_Lyrics/json` ExtState, only when something changed. When the project changes, the page goes back to the original key. It also publishes the computer's network IPs in `XR_Lyrics/host_ips`. The web page requests this data from REAPER through the web interface API (`main.js`, which ships with REAPER) and follows the playback position to highlight the current part. For the fade, the page writes the length in the `XR_Lyrics/fade_stop` ExtState: the script fades the master track volume (even in dB, down to -60 dB), stops and restores the volume. If the script isn't running, Space just stops.

## Credits and license

- Based on the work of [X-Raym](https://www.extremraym.com) ([REAPER-ReaScripts](https://github.com/X-Raym/REAPER-ReaScripts)), licensed under **GPL v3**.
- `web/qrcode.js`: [qrcode-generator](https://github.com/kazuhikoarase/qrcode-generator) 1.4.4 by Kazuhiko Arase, **MIT** license (copyright notice in the file itself). "QR Code" is a registered trademark of DENSO WAVE INCORPORATED.

This project is distributed under the **GNU General Public License v3.0**. See the [LICENSE](LICENSE) file.
