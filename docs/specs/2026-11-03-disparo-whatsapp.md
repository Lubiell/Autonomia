# Spec — Disparo de WhatsApp (foto + texto) via OpenWA
Data: 2026-11-03

## Problema
O usuário precisa mandar foto e mensagem para 100 a 1.000 clientes que autorizaram receber. Hoje não há ferramenta para isso. Ele escolheu o OpenWA, um cliente não oficial, em vez da API oficial da Meta, sabendo do risco de ban.

## Alternativas consideradas
| | Custo | Risco |
|---|---|---|
| **A) Script próprio que envia um por vez** (`send-text` / `send-image`), com ritmo, limite diário e registro por contato | ~uma tarde | Mais código para manter |
| B) Usar o `send-bulk` do OpenWA | ~1 h | Máximo de 100 por lote, e a documentação não diz o resultado por contato: não dá para saber com certeza quem recebeu nem retomar sem repetir envio |
| C) API oficial (Cloud API) | Pago por mensagem, exige conta Business | Sem risco de ban. Descartada pelo usuário |

**Escolha: A.** É o único caminho em que o script sabe exatamente quem já recebeu, retoma sem mandar duas vezes e segura o volume para reduzir o risco de ban.

## Solução escolhida
Script `disparo.py` em Python, só com a biblioteca padrão (sem dependência nova). Roda no Termux ou no PC e conversa com um servidor OpenWA que o usuário mantém ligado.

- **Entrada:**
  - `contatos.csv`, com as colunas `telefone,nome,consentimento`. A linha sem `consentimento` preenchido é ignorada e registrada como `sem_consentimento`.
  - `campanha.json`, com `texto` (aceita `{{nome}}`), `imagem_url` (opcional) e `legenda`.
- **Telefone:** normaliza para `55DDDNÚMERO`. Antes do primeiro envio, confere o número em `GET /api/sessions/{id}/contacts/check/{numero}` e usa o `chatId` que o OpenWA devolver. Isso resolve o problema do nono dígito em números do Brasil. O formato exato da resposta será conferido no código do OpenWA antes da implementação.
- **Envio:**
  - Usa `POST /api/sessions/{id}/messages/send-image` (`chatId`, `url`, `caption`) quando há foto, ou `send-text` (`chatId`, `text`) quando não há.
  - Autentica pelo cabeçalho `X-API-Key`, lido da variável de ambiente `OPENWA_API_KEY`. A chave nunca fica em arquivo do repositório.
- **Ritmo:**
  - Espera aleatória de 20 a 60 s entre envios.
  - Limite diário configurável, padrão 50 [Chute conservador para número novo; aumentar aos poucos].
  - Para depois de 3 falhas seguidas.
  - Recomenda ligar `SEND_PACING_ENABLED=true` no servidor.
- **Registro:**
  - `envios.csv` guarda telefone, status, horário e erro.
  - Ao rodar de novo, o script pula quem já está como `enviado`, o que torna a execução repetível.
- **Descadastro:**
  - O texto termina com "Responda SAIR para não receber mais".
  - Os números listados em `descadastro.csv` nunca recebem.
- **Segurança de uso:**
  - O padrão é **simulação**: mostra o que faria e não envia nada.
  - Só envia com `--enviar`.
  - `--teste 55DDDNUMERO` manda para um único número.
- **LGPD:**
  - `contatos.csv`, `envios.csv` e `descadastro.csv` entram no `.gitignore`.
  - Só o `contatos.exemplo.csv` vai para o repositório.
- **Servidor:** o OpenWA roda no PC do usuário, em Docker, na porta 2785. O script roda no próprio PC, pelo endereço `http://localhost:2785`. Pelo celular, também roda no Termux, apontando para o IP do PC na mesma rede Wi-Fi com a opção `--url`. O painel do OpenWA não fica exposto à internet.
- **Local:** `ferramentas/disparo-whatsapp/` neste repositório, porque esta sessão não cria repositório novo. Dá para mover para um repositório próprio depois.

## Fora de escopo
- Instalar, hospedar ou manter o servidor OpenWA (Docker em PC ou VPS). Isso fica com o usuário.
- Ler respostas e processar o "SAIR" de forma automática (webhook). Por enquanto, o usuário anota no `descadastro.csv`.
- Agendar envios, enviar vídeo, documento ou áudio, e enviar para grupos.
- Lista comprada ou contatos sem consentimento.
- API oficial da Meta.

## Arquivos afetados
- `ferramentas/disparo-whatsapp/disparo.py`
- `ferramentas/disparo-whatsapp/README.md`: passo a passo, riscos e LGPD
- `ferramentas/disparo-whatsapp/contatos.exemplo.csv` e `campanha.exemplo.json`
- `tests/disparo_whatsapp_test.py`: testes com um servidor OpenWA falso, local
- `.gitignore` e `.github/workflows/test.yml`: incluir o teste em Python
- `CHANGELOG.md`

## Como saber que deu certo
- Os testes passam localmente e no CI, cobrindo:
  - a simulação não faz nenhuma chamada de envio;
  - a linha sem consentimento é pulada;
  - o número descadastrado é pulado;
  - quem já está como enviado não recebe de novo;
  - o limite diário é respeitado;
  - o envio para depois de 3 falhas seguidas;
  - o telefone é normalizado;
  - o corpo de `send-image` sai com `chatId`, `url` e `caption`.
- O usuário roda `--teste` com o próprio número e recebe a foto com a legenda.

## Risco e volta atrás
- **Ban do número:** é o maior risco, inerente ao cliente não oficial. Para mitigar:
  - usar um número que não seja o principal;
  - manter o limite diário baixo;
  - mandar só para quem autorizou;
  - manter a opção de sair.
  - Não há como desfazer um ban.
- **Mudança na API do OpenWA:** o script quebra com uma mensagem de erro clara. Os testes travam o contrato usado.
- **Para reverter:** apagar a pasta `ferramentas/disparo-whatsapp/`, que não mexe em mais nada do kit.
