---
name: automacao
description: Use ao criar script ou rotina que roda sozinho — tarefa agendada, robô de navegador, processamento de planilhas e arquivos, integração entre sistemas, bot. Garante que rode de novo sem estragar, avise quando falhar e não exponha credencial.
---

# Automação e scripts

## Antes de escrever
- Confira se uma ferramenta pronta resolve (recurso da própria plataforma, Zapier, Make, n8n, GitHub Actions). Script é a última opção, não a primeira.
- Defina entrada, saída, frequência e o que acontece se falhar no meio.

## Robustez
- **Idempotente:** rodar duas vezes não duplica nem apaga a mais. Marque o que já foi processado.
- **Pré-condições:** confira arquivo, pasta, credencial e conexão antes de começar; falhe cedo com mensagem clara.
- **Ação destrutiva** (apagar, sobrescrever, enviar e-mail em massa): modo `--dry-run` que só mostra o que faria, e trabalhe em cópia.
- **Erro:** código de saída diferente de zero, timeout em rede, nova tentativa limitada com espera crescente.
- **Log** com data e hora em arquivo, uma linha por item e um resumo no fim (processados, ignorados, erros).

## Credenciais
Em variável de ambiente, arquivo `.env` fora do Git ou gerenciador de segredos. Nunca no script, no log ou no commit.

## Agendamento
- **Windows:** Agendador de Tarefas (`schtasks /create ...` ou a interface), com "executar mesmo sem usuário conectado" se precisar.
- **Linux/macOS:** `cron`.
- **Nuvem:** GitHub Actions com `on: schedule` (cron em UTC por padrão; `timezone: "America/Sao_Paulo"` muda o fuso) ou Cron Triggers do Cloudflare Workers.
- Avise quando falhar (e-mail, Telegram, Slack); rotina que falha calada é pior que nenhuma.

## Robô de navegador (Playwright)
- Seletores estáveis: papel e texto (`getByRole`, `getByText`) ou `data-testid`, não posição nem classe gerada.
- Espere pelo elemento ou pelo estado, nunca `sleep` fixo.
- Respeite termos de uso e `robots.txt`; não burle captcha, login ou limite de terceiros; ritmo humano, sem sobrecarregar o site.
- Prefira a API oficial do serviço quando existir.

## Planilhas e arquivos
Valide colunas e tipos antes de processar; preserve o original; nomes de saída com data; trate acentuação (UTF-8) e separador do CSV (`;` no Excel em português).

## Entregar
Como rodar, como agendar, onde fica o log, o que fazer quando falhar.
