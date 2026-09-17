# 05 — Testes de downloads

## Automatizados (`tools/tests/run-unit-tests.sh` → `downloads_test.qml`)

| Caso | Esperado | Resultado |
| --- | --- | --- |
| Progresso ponderado 900 MB/1 GB + 100 MB/3 GB | 25 % (não 46,5 %) | PASS |
| Só tamanhos desconhecidos | `progress = -1`, `hasUnknownSize` | PASS |
| Híbrido conhecido + desconhecido | razão sobre os conhecidos + flag | PASS |
| Pausado conta como ativo | `active=1, paused=1` | PASS |
| A visto, B não visto, C visto | indicador visível, `attention=1` | PASS |
| Tudo visto/cancelado | indicador oculto | PASS |
| Erro não reconhecido | indicador visível | PASS |
| Lista vazia | oculto | PASS |
| Velocidade com janela < 2 s | -1 | PASS |
| Velocidade 1 MB/s em 3 s; ETA 7 s | ok | PASS |
| ETA sem total / sem velocidade | -1 | PASS |
| Janela de amostras aparada | ≤ 12 amostras, ≥ 20 s | PASS |
| Escala de bytes 512 B / 2,4 MB / 1,8 GB | unidades corretas | PASS |
| Ícone por extensão | pdf/desconhecido | PASS |

## Automatizado no widget (viewer, build de teste — ver 07)

Download de Blob via `<a download>`: item criado, indicador aparece, estado Completed, arquivo gravado na pasta
configurada, indicador permanece (não visto), `openDownload` marca `seen` e o indicador some.

## Manuais

| # | Cenário | Passos | Esperado |
| --- | --- | --- | --- |
| 1 | 1 arquivo | baixar um anexo/imagem de um chat | ↓ surge com anel; popup mostra nome, tamanho, %, velocidade, ETA; ao concluir badge ✓; Abrir marca visto; indicador some |
| 2 | 2 simultâneos | iniciar dois downloads grandes | anel = bytes somados; popup lista os dois com controles independentes |
| 3 | 5 simultâneos | cinco arquivos | lista rola; sem travar UI (throttle 250 ms) |
| 4 | Tamanho desconhecido | servidor sem Content-Length | anel indeterminado girando; popup com barra indeterminada |
| 5 | Pausar/Retomar | durante 1 | anel fica neutro ao pausar; retoma |
| 6 | Cancelar | durante 1 | estado Cancelado; Remover/Tentar de novo |
| 7 | Erro de rede | desligar rede durante 1 | Interrompido; badge !; Tentar de novo re‑solicita |
| 8 | Duplicado | baixar o mesmo nome em andamento | notificação "já está sendo baixado"; segundo cancelado |
| 9 | Popup fechar/reabrir | durante 1 | estado preservado (modelo único) |
| 10 | Minimizar o plasmoid durante download | colapsar o popup | download continua (busy impede Frozen); ao reabrir progresso correto |
| 11 | Toolbar auto‑hide | ativar auto‑hide, baixar | barra revela por 3 s ao concluir; passar o mouse mostra o indicador |
| 12 | Mostrar na pasta | concluído → Mostrar na pasta | Dolphin abre com o arquivo selecionado (FileManager1); fallback abre a pasta |
| 13 | Notificação | concluir | notificação KDE com Abrir / Mostrar na pasta; sem duplicidade |
| 14 | Histórico | indicador oculto → ⋮ › Downloads | lista continua disponível; Limpar concluídos |
| 15 | Muitos downloads consecutivos | 20 pequenos | `downloadCache` vazio ao final (sem vazamento); renderers normais |
