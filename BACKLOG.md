# Backlog

Ideias e limitações conhecidas para eventuais atualizações.

## Fade out (barra de espaço)

- **Cauda de efeitos depois de parar.** Se os efeitos continuam rodando com o REAPER parado, a cauda de um reverb ou delay pode soar no volume cheio quando o volume do master volta (hoje 0,5 s depois da parada, `FADE_RESTORE` no script). Possível solução: um tempo de espera maior ou configurável, ou esperar o nível do master ficar abaixo de um limite (`Track_GetPeakInfo`) antes de devolver o volume.
- **Microfones ao vivo.** O fade é no volume do master, então tudo o que passa pelo master abaixa junto, inclusive microfones ao vivo monitorados pelo REAPER. Possível solução: fazer o fade só nas tracks que estão tocando itens, ou numa track/bus escolhida (por exemplo, pelo nome, como a track "Lyrics").
- **Automação de volume no master.** Com automação de volume do master em modo de leitura, a automação pode passar por cima do fade. Possível solução: detectar o envelope de volume ativo e usar outro caminho (trim, ou um bus como no item anterior).

## Transposição

- **Salvar o tom escolhido por música e por dispositivo.** Guardar no `localStorage` de cada navegador, usando como chave o `project` que o script já envia no JSON (ou o `{title}` do ChordPro), e o deslocamento em semitons como valor. Ao abrir a música, aplicar o tom salvo naquele dispositivo.
