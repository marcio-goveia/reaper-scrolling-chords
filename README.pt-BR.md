[English](README.md) | **Português** | [Español](README.es.md)

# REAPER Scrolling Chords

Interface web para o [REAPER](https://www.reaper.fm) que mostra a **letra com cifras** da música que está tocando, rolando junto com a reprodução. Feita para ser vista no navegador de celulares, tablets e telas grandes na mesma rede local.

Baseada nos scripts e na interface *Scrolling Lyrics / Scrolling Chords* do [X-Raym](https://github.com/X-Raym/REAPER-ReaScripts).

## Recursos

- **Letra sincronizada:** cada item de nota da track `Lyrics` vira um bloco, destacado e centralizado enquanto toca. Tocar num bloco leva o REAPER até ele.
- **Dois formatos de cifra**, que podem ser misturados na mesma música:
  - **Texto com acordes em cima da letra** (o formato tradicional).
  - **[ChordPro](https://www.chordpro.org)**: `[G]Grande é o [C9]Senhor`, com suporte a `{title}`, `{key}`, `{capo}`, comentários, refrão/verso/ponte e tablatura.
- **Transposição:** botões ⊖ / ⊕, lista com os 12 tons a partir do C e as teclas `+` `-` `0`. Sustenidos ou bemóis de acordo com o tom de destino.
- **Tom detectado automaticamente** a partir de todos os acordes da música, quando não há `{key}`.
- **Acordes opcionais** entre parênteses, como `(Em)`.
- **Modo "só letra"** para quem canta: tecla `C` ou `?nochords`.
- **Ajuste à tela:** a fonte se adapta para a linha mais larga caber, em pé ou deitado, sem desalinhar os acordes.
- **Compartilhar por QR code**, com o IP da rede detectado pelo script. Funciona sem internet.
- **Inglês, português e espanhol**, de acordo com o idioma do navegador de cada dispositivo. A mensagem do script segue o pacote de idioma do REAPER ou o idioma do sistema.

## Arquivos

| Arquivo | Onde instalar |
|---|---|
| `scripts/Convert Lyrics track items notes for scrolling web browser interface.lua` | Pasta `Scripts` do REAPER |
| `web/Scrolling Chords ChordPro.html` | Pasta `reaper_www_root` do REAPER |
| `web/qrcode.js` | Pasta `reaper_www_root`, junto do HTML |

As pastas do REAPER ficam no diretório de recursos (*Options › Show REAPER resource path*). Em Linux é `~/.config/REAPER`.

## Instalação

1. Copie os arquivos (ou crie links simbólicos) para as pastas da tabela acima.
2. No REAPER, carregue o script: *Actions › Show action list › New action › Load ReaScript…*. Se quiser, associe um atalho.
3. Em *Options › Preferences › Control/OSC/Web*, adicione uma **Web browser interface** e escolha `Scrolling Chords ChordPro.html` como página.

## Uso

1. Crie uma track chamada **Lyrics** (maiúsculas ou minúsculas, tanto faz).
2. Para cada trecho da música, crie um item nessa track e escreva a letra com os acordes nas **notas do item**.
3. Rode o script. Rode de novo sempre que editar as notas.
4. Abra a interface web no navegador. Para abrir em outro dispositivo, use o botão de compartilhar (QR code).

### Exemplo: formato tradicional

```
G9            C9                    G
Grande é o Senhor e mui digno de louvor
     C9                            Em
Na cidade do nosso Deus, Seu Santo monte
```

### Exemplo: ChordPro

```
{title: Grande é o Senhor}
{key: G}
{soc: Refrão}
[G9]Grande é o [C9]Senhor e mui digno de lou[G]vor
Na ci[C9]dade do nosso Deus, Seu Santo [Em]monte
{eoc}
```

### Parâmetros da URL

| Parâmetro | Efeito |
|---|---|
| `?transpose=2` | Abre transposto (em semitons) |
| `?nochords` | Só a letra |
| `?hidecontrols` | Esconde os controles (para telão) |
| `?maxsize=70` | Tamanho máximo da fonte, em px (padrão 52) |
| `?fullheight` | Um bloco por tela, inclusive os intervalos sem letra |
| `?vignette` | Escurece as bordas da tela |
| `?font=Nome` | Fonte da página |
| `?lang=en` / `pt` / `es` | Força o idioma (o padrão é o do navegador; outros idiomas caem no inglês) |

### Atalhos de teclado

| Tecla | Ação |
|---|---|
| `Espaço` | Play / Stop no REAPER |
| `+` / `-` | Sobe / desce meio tom |
| `0` | Volta ao tom original |
| `C` | Mostra / esconde os acordes |
| `Esc` | Fecha menus |

## Como funciona

O script Lua lê as notas dos itens da track `Lyrics` e as publica como JSON na ExtState `XR_Lyrics/json`. Ele também publica os IPs de rede do computador em `XR_Lyrics/host_ips`. A página web pede esses dados ao REAPER pela API da interface web (`main.js`, que vem com o REAPER) e acompanha a posição da reprodução para destacar o trecho atual.

## Créditos e licença

- Baseado no trabalho de [X-Raym](https://www.extremraym.com) ([REAPER-ReaScripts](https://github.com/X-Raym/REAPER-ReaScripts)), licenciado sob **GPL v3**.
- `web/qrcode.js`: [qrcode-generator](https://github.com/kazuhikoarase/qrcode-generator) 1.4.4 de Kazuhiko Arase, licença **MIT** (aviso de copyright no próprio arquivo). "QR Code" é marca registrada da DENSO WAVE INCORPORATED.

Este projeto é distribuído sob a **GNU General Public License v3.0**. Veja o arquivo [LICENSE](LICENSE).
