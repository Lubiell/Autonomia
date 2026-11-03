# Disparo de WhatsApp (foto + texto) via OpenWA

Envia uma foto com legenda, ou só texto, para uma lista de clientes **que autorizaram receber**. O envio é feito pelo [OpenWA](https://github.com/rmyndharis/OpenWA), rodando no seu PC.

> ⚠️ **Risco de ban.** O OpenWA usa um cliente **não oficial** do WhatsApp. A Meta pode restringir ou banir o número, e isso não tem volta. Para reduzir o risco:
> - use um número que **não** seja o principal do negócio;
> - comece com poucos envios por dia (o padrão é 50) e aumente aos poucos;
> - mande só para quem autorizou;
> - deixe sempre a opção de sair.
>
> Se o envio for crítico ou para muita gente, prefira a API oficial (WhatsApp Business Cloud API).

## O que o script faz
- Envia para um contato por vez, com espera aleatória de 20 a 60 s entre um envio e outro.
- Para quando chega ao limite diário (`--limite-dia`, padrão 50). O limite conta também os envios de rodadas anteriores no mesmo dia.
- Para depois de 3 falhas seguidas, geralmente quando o servidor caiu ou a sessão desconectou.
- Pula:
  - quem está sem `consentimento`;
  - quem está no `descadastro.csv`;
  - telefone inválido ou repetido;
  - número que não tem WhatsApp.
- Registra cada envio em `envios.csv`. Se você rodar de novo, ele **não repete** para quem já recebeu e tenta de novo só os que deram erro antes do envio.
- Quando o envio **pode** ter saído (o servidor demorou mais de 30 s, devolveu erro 5xx ou uma resposta estranha), marca o contato como `incerto` e não reenvia, para a pessoa não receber duas vezes. Confira no WhatsApp.
- Termina toda mensagem com "Responda SAIR para não receber mais", a não ser que o seu texto já fale em SAIR.
- **Por padrão só simula.** Para enviar de verdade, acrescente `--enviar`.

## 1. Ligar o OpenWA no PC (uma vez)
Siga o README do OpenWA, que usa Docker. Em resumo:
1. Suba o servidor. A API fica em `http://localhost:2785/api`.
2. A chave de API é gerada na primeira vez que o servidor liga e fica em `data/.api-key`.
3. Crie a sessão com `POST /api/sessions`, ligue com `/start` e leia o QR em `GET /api/sessions/{id}/qr` com o WhatsApp do número que vai enviar.
4. Recomendado: ligue `SEND_PACING_ENABLED=true` na configuração do OpenWA.
5. Não exponha a porta 2785 à internet. Basta a rede de casa.

## 2. Preparar os arquivos
Dentro desta pasta:
- **`contatos.csv`:** copie de `contatos.exemplo.csv`. As colunas são `telefone,nome,consentimento`.
  - Em `consentimento`, anote quando e onde a pessoa autorizou, por exemplo `2026-10-01 balcão`. Quem fica com essa coluna vazia, ou com `não`, `nao` ou `0`, não recebe.
  - O telefone pode ter DDD, parênteses, traço ou +55.
  - O arquivo pode ser salvo pelo Excel, com `;` ou com `,`, em UTF-8 ou no formato antigo do Excel.
  - Os números são comparados com e sem o nono dígito: `11 8765-4321` e `11 98765-4321` contam como a mesma pessoa.
- **`campanha.json`:** copie de `campanha.exemplo.json`.
  - `texto`: o texto da mensagem. Use `{{nome}}` para colocar o nome da pessoa.
  - `imagem`: o arquivo da foto, na mesma pasta. Ou então `imagem_url`, um link público para a foto. Não use os dois. Sem nenhum dos dois, vai só texto.
- **`descadastro.csv`**: um telefone por linha, com quem respondeu SAIR. Atualize antes de cada rodada. Se o arquivo não existir, o script avisa.
- **`envios.csv`**: é o registro, e o próprio script o cria. **Não salve este arquivo pelo Excel.** Se as colunas mudarem, o script para em vez de arriscar reenviar.

Os arquivos de contatos, de registro, de descadastro e as fotos ficam **fora do Git** (veja o `.gitignore`), porque são dado pessoal (LGPD).

## 3. Rodar
No PC, com Python 3.8 ou mais recente. Não precisa instalar nada além do Python.

Linux ou macOS:

```bash
export OPENWA_API_KEY="cole-a-chave-aqui"
export OPENWA_SESSAO="id-da-sessao"
```

Windows (PowerShell):

```powershell
$env:OPENWA_API_KEY="cole-a-chave-aqui"; $env:OPENWA_SESSAO="id-da-sessao"
```

Depois, siga os passos na ordem:

1. Simule para ver quem receberia:

```bash
python3 disparo.py
```

2. Mande um teste para o seu próprio número e confira a foto e o texto no celular:

```bash
python3 disparo.py --teste 11987654321
```

3. Envie de verdade:

```bash
python3 disparo.py --enviar
```

No dia seguinte, rode o mesmo comando para continuar de onde parou. Opções úteis:
- `--limite-dia 80` aumenta o limite diário;
- `--intervalo 30-90` muda a espera entre envios;
- `--url http://192.168.0.10:2785` aponta para outro endereço do servidor.

**Pelo celular (Termux):** com o PC e o celular na mesma rede Wi-Fi, instale o Python uma vez:

```bash
pkg install python
```

Depois rode os mesmos comandos de cima com `--url http://IP-DO-PC:2785`. Para descobrir o IP do PC, use `ipconfig` no Windows ou `ip addr` no Linux.

## Resultado
O resumo no final mostra quantos contatos ficaram em cada situação:
- `enviado`;
- `erro`;
- `nao_existe`: o número não tem WhatsApp;
- `incerto`: o envio pode ter saído; confira no WhatsApp;
- `sem_consentimento`;
- `descadastrado`;
- `ja_feito`: já tinha recebido;
- `limite`: o limite diário foi atingido.

O detalhe de cada envio fica em `envios.csv`.

## Testes
Os testes usam um servidor OpenWA falso, sem enviar nada de verdade:

```bash
python3 tests/disparo_whatsapp_test.py
```

Rode a partir da raiz do repositório.

## Limites conhecidos
- Não lê as respostas: quem responder SAIR precisa ser anotado à mão no `descadastro.csv`.
- Não envia vídeo, documento nem áudio, não manda para grupos e não agenda envios.
- O formato do envio de foto em base64 vem do SDK do OpenWA (`base64`, `mimetype`, `filename`) e não foi testado num servidor real. Confirme com `--teste` antes da primeira campanha.
