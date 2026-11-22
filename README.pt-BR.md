[English](README.md) | **Português** | [Español](README.es.md)

# REAPER Scrolling Chords

Interface web para o [REAPER](https://www.reaper.fm) que mostra a **letra com cifras** da música que está tocando, rolando junto com a reprodução. Feita para ser vista no navegador de celulares, tablets e telas grandes na mesma rede local.

Baseada nos scripts e na interface *Scrolling Lyrics / Scrolling Chords* do [X-Raym](https://github.com/X-Raym/REAPER-ReaScripts).

## Recursos

- **Letra sincronizada:** cada item de nota da track `Lyrics` vira um bloco, destacado e centralizado enquanto toca. Tocar num bloco leva o REAPER até ele.
- **Sempre atualizada:** o script roda em segundo plano e acompanha a aba de projeto ativa. Trocar de aba ou editar as notas atualiza a página sozinho, e ele pode iniciar junto com o REAPER.
- **Dois formatos de cifra**, que podem ser misturados na mesma música:
  - **Texto com acordes em cima da letra** (o formato tradicional).
  - **[ChordPro](https://www.chordpro.org)**: `[G]Grande é o [C9]Senhor`, com suporte a `{title}`, `{key}`, `{capo}`, comentários, refrão/verso/ponte e tablatura.
- **Transposição:** botões ⊖ / ⊕, lista com os 12 tons a partir do C e as teclas `+` `-` `0`. Sustenidos ou bemóis de acordo com o tom de destino.
- **Tom detectado automaticamente** a partir de todos os acordes da música, quando não há `{key}`.
- **Acordes opcionais** entre parênteses, como `(Em)`.
- **Modo "só letra"** para quem canta: tecla `C` ou `?nochords`.
- **Músicas = abas de projeto do REAPER:** o botão de músicas lista as abas abertas, e as teclas `1` a `9` trocam para a aba 1 a 9, sem precisar ir até o REAPER. Só com a reprodução parada, para uma tecla apertada sem querer não interromper uma música.
- **Fade out na barra de espaço:** com o botão **Fade** ligado, a barra de espaço faz um fade out no volume do master, para a reprodução e devolve o volume. Desligado, a barra de espaço para na hora, como no REAPER. A escolha fica salva em cada dispositivo. No celular (sem barra de espaço) o botão fica escondido.
- **Ajuste à tela:** a fonte se adapta para a linha mais larga caber, em pé ou deitado, sem desalinhar os acordes.
- **Compartilhar por QR code**, com o IP da rede detectado pelo script. Funciona sem internet.
- **Inglês, português e espanhol**, de acordo com o idioma do navegador de cada dispositivo.

## Arquivos

| Arquivo | Onde instalar |
|---|---|
| `scripts/Convert Lyrics track items notes for scrolling web browser interface.lua` | Pasta `Scripts` do REAPER |
| `web/Scrolling Chords ChordPro.html` | Pasta `reaper_www_root` do REAPER |
| `web/qrcode.js` | Pasta `reaper_www_root`, junto do HTML |
| `scripts/__startup.lua` | Pasta `Scripts` do REAPER (opcional: inicia o script junto com o REAPER) |

As pastas do REAPER ficam no diretório de recursos (*Options › Show REAPER resource path*). Em Linux é `~/.config/REAPER`.

## Instalação

1. Copie os arquivos (ou crie links simbólicos) para as pastas da tabela acima.
2. No REAPER, carregue o script: *Actions › Show action list › New action › Load ReaScript…*. Se quiser, associe um atalho.
3. Em *Options › Preferences › Control/OSC/Web*, adicione uma **Web browser interface** e escolha `Scrolling Chords ChordPro.html` como página.
4. Opcional: copie `scripts/__startup.lua` para a pasta `Scripts`, para o script iniciar sempre que o REAPER abrir. Se você já tem um `__startup.lua`, cole o código dele no final do seu.

## Uso

1. Crie uma track chamada **Lyrics** (maiúsculas ou minúsculas, tanto faz).
2. Para cada trecho da música, crie um item nessa track e escreva a letra com os acordes nas **notas do item**.
3. Rode o script uma vez (ou deixe o `__startup.lua` iniciá-lo). Ele continua em segundo plano: trocar de aba de projeto ou editar as notas atualiza a página. Rodar a action de novo para o script. Se você puser a action numa toolbar (botão direito na toolbar › *Customize toolbar…*), o botão fica aceso enquanto o script roda.
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
| `?fadeout` | Liga o **Fade** |
| `?fadetime=6` | Duração do fade em segundos (padrão 6) |
| `?lang=en` / `pt` / `es` | Força o idioma (o padrão é o do navegador; outros idiomas caem no inglês) |

### Atalhos de teclado

| Tecla | Ação |
|---|---|
| `Espaço` | Play / Stop no REAPER (com o **Fade** ligado: fade out e depois para; aperte de novo para parar na hora) |
| `+` / `-` | Sobe / desce meio tom |
| `0` | Volta ao tom original |
| `1` … `9` | Troca para a aba de projeto 1 … 9 (só com a reprodução parada) |
| `C` | Mostra / esconde os acordes |
| `F` | Liga / desliga o **Fade** |
| `Esc` | Fecha menus |

## Como funciona

O script Lua roda em segundo plano. Ele observa a aba de projeto ativa e o histórico de desfazer, e relê tudo uma vez por segundo para pegar mudanças que não aparecem no histórico. Ele lê as notas dos itens da track `Lyrics` e as publica como JSON na ExtState `XR_Lyrics/json`, só quando algo mudou. Quando o projeto muda, a página volta ao tom original. Ele também publica as abas de projeto abertas em `XR_Lyrics/tabs` e os IPs de rede do computador em `XR_Lyrics/host_ips`. Para trocar de aba, a página grava o número da aba em `XR_Lyrics/select_tab`. A página web pede esses dados ao REAPER pela API da interface web (`main.js`, que vem com o REAPER) e acompanha a posição da reprodução para destacar o trecho atual. Para o fade, a página grava a duração na ExtState `XR_Lyrics/fade_stop`: o script baixa o volume da track master (de forma uniforme em dB, até -60 dB e depois silêncio), para a reprodução, espera o áudio parar de fato e restaura o volume. Se o script não estiver rodando, a barra de espaço só para.

## Créditos e licença

- Baseado no trabalho de [X-Raym](https://www.extremraym.com) ([REAPER-ReaScripts](https://github.com/X-Raym/REAPER-ReaScripts)), licenciado sob **GPL v3**.
- `web/qrcode.js`: [qrcode-generator](https://github.com/kazuhikoarase/qrcode-generator) 1.4.4 de Kazuhiko Arase, licença **MIT** (aviso de copyright no próprio arquivo). "QR Code" é marca registrada da DENSO WAVE INCORPORATED.

Este projeto é distribuído sob a **GNU General Public License v3.0**. Veja o arquivo [LICENSE](LICENSE).
