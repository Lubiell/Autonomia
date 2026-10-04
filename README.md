# Claude Code — Orquestrador

Configuração de orquestração para o Claude Code: regras permanentes, 12 agents especializados, 13 skills (dados, banco de dados, API e backend, sites, SEO, teste no navegador, deploy, automação, conteúdo para redes, tráfego pago, sabatina de requisitos, passagem de sessão e avaliação de recursos), permissões, sandbox e um hook de segurança.

```text
CLAUDE.md                 regras permanentes e roteamento
install.sh / install.ps1  instalação no nível do usuário (~/.claude)
package.sh / package.ps1  empacota as skills em zip para o claude.ai
.claude/
├── settings.json         bloqueios reais (deny/ask), sandbox e hook; não dependem do modelo
├── hooks/
│   └── guard.sh          bloqueia comando destrutivo, segredo em commit, SQL sem WHERE
├── agents/
│   ├── architect.md      planeja, somente leitura (opus)
│   ├── developer.md      implementa (sonnet)
│   ├── debugger.md       causa raiz + menor correção (sonnet)
│   ├── tester.md         testes (haiku)
│   ├── reviewer.md       revisão do diff, somente leitura (sonnet)
│   ├── security.md       auditoria, somente leitura (sonnet)
│   ├── devops.md         Git, CI/CD, deploy (haiku)
│   ├── scout.md          localiza código, somente leitura (sonnet)
│   ├── data-analyst.md   processa base de dados e traz só o resultado (sonnet)
│   ├── qa-web.md         testa o site no navegador real, não edita (sonnet)
│   ├── docs-writer.md    README, guias e CHANGELOG a partir do código real (sonnet)
│   └── researcher.md     pesquisa na internet com fontes e datas, sem alterar arquivos (sonnet)
└── skills/
    ├── analise-dados/        diagnóstico de dados e dashboard, etapa por etapa
    ├── frontend-design/      direção visual de sites (oficial Anthropic, Apache-2.0)
    ├── webapp-testing/       teste de site no navegador com Playwright (oficial Anthropic, Apache-2.0)
    ├── deploy-web/           checklist de publicação: GitHub Pages, Cloudflare, Firebase
    ├── banco-dados/          modelagem, migração, query segura, índices, Firestore, backup, LGPD
    ├── api-backend/          contrato HTTP, validação, autenticação e autorização, CORS, webhooks
    ├── automacao/            scripts e rotinas agendadas idempotentes, robô de navegador, planilhas
    ├── seo/                  título, meta, headings, sitemap, dados estruturados, Core Web Vitals
    ├── conteudo/             post, legenda, carrossel, roteiro de vídeo e anúncio, no tom do usuário
    ├── trafego-pago/         Meta, Google e TikTok Ads: rastreamento, estrutura, métricas, relatório
    ├── handoff/              /handoff: documento para outra sessão continuar (só por comando)
    ├── grill-me/             /grill-me: entrevista até o plano não ter pontas soltas (só por comando)
    └── discover-resources/   avaliar recurso externo antes de instalar
        ├── auditoria.md      checklist de segurança antes de instalar
        └── decisoes.md       registro do que foi adotado ou recusado
tests/                    testes do hook e dos instaladores
.github/workflows/test.yml  CI: Linux, macOS (bash 3.2) e Windows (Git Bash, PowerShell 7 e 5.1)
```

## Instalação

**Num projeto:** copie `CLAUDE.md` e `.claude/` para a raiz do repositório.

**Para todos os projetos e conversas (nível do usuário):** rode o instalador na pasta do repositório.

```bash
./install.sh                                          # Linux / macOS
powershell -ExecutionPolicy Bypass -File .\install.ps1  # Windows
```

Ele copia `CLAUDE.md`, os agents, as skills e os hooks para `~/.claude/` e junta ao seu `settings.json` as regras `deny`/`ask`, o hook e a seção `sandbox` (esta só se você ainda não tiver uma), sem apagar o que você já tem. Os arquivos que ele substitui vão para `~/.claude/backup-orquestrador-<data>/`. Pode rodar de novo para atualizar. Para instalar em outra pasta, defina `CLAUDE_HOME`.

Use **um** dos dois modos. Se o `CLAUDE.md` estiver no nível do usuário e também na raiz do projeto, os dois são carregados em toda conversa e as regras são pagas em dobro. No projeto, deixe só o que for específico dele.

## Usar as skills no claude.ai (chat, desktop e Cowork)
As skills de `~/.claude/skills` valem só no Claude Code; no claude.ai elas entram por upload de zip. Para gerar os zips:

```bash
./package.sh                                            # Linux / macOS / Git Bash (usa zip ou python)
powershell -ExecutionPolicy Bypass -File .\package.ps1   # Windows
```

Sai um `dist/<skill>.zip` por skill, com a pasta da skill no topo, como o claude.ai exige; passe nomes para empacotar só algumas (`./package.sh analise-dados`). Envie em **Personalizar > Skills** e ative cada uma. Não há sincronização: ao mudar uma skill, gere e envie o zip de novo. A `discover-resources` fala de instalar no Claude Code; no chat ela serve só para avaliar.

## Economia de tokens
- `CLAUDE.md` entra em todo turno: mantenha-o curto. A `description` de cada skill e agent também; o teste `skills.test.sh` barra description acima de 400 caracteres. Instrução longa e rara vai para uma skill (só a `description` fica no contexto até ela ser usada).
- A `description` dos agents decide quando o Claude delega. Cada subagent começa do zero e relê contexto, então architect e reviewer só disparam em mudança não trivial.
- Modelo por custo: `haiku` para execução (tester, devops), `sonnet` onde a qualidade pesa (scout, developer, debugger, reviewer, security, data-analyst, qa-web, docs-writer, researcher) e `opus` só no architect, que é raro.
- O `scout` localiza código e devolve só `arquivo:linha`, para a sessão principal ler apenas os trechos certos. Ele roda com `omitClaudeMd: true` (Claude Code v2.1.271+), sem carregar o `CLAUDE.md`.
- `settings.json` nega leitura de `node_modules`, `.venv`, `venv`, `__pycache__` e `coverage` para o Claude não carregar arquivos gerados no contexto.

## Segurança em camadas
- **Permissões (`deny`/`ask`)**: bloqueio por prefixo de comando e leitura de arquivos sensíveis, inclusive `~/.ssh`, `~/.aws/credentials` e `~/.gnupg` pela ferramenta Read, que não passa pelo sandbox. Pergunta antes de `git push`, `curl`/`wget`, `pip install` (também `pip3` e `python -m pip`), `npm install -g` e `npm publish`.
- **Hook `guard.sh`** (PreToolUse em Bash e PowerShell): analisa o comando inteiro, separado por `;`, `|`, `&&`, `$( )` etc., e bloqueia:
  - `rm` recursivo forçado (`-rf`, `-r -f`, `-fr`, `sudo`, `xargs`, `bash -c`), `Remove-Item -Recurse`, `git push --force`/`-f`/`+ref`, `git reset --hard`, `git clean -f` sem `-n` e `curl … | sh`; `--force-with-lease` passa;
  - pular os hooks do Git: `--no-verify` (ou abreviado) em `commit`, `push`, `merge` e `rebase`, `git commit -n` e `core.hooksPath` passado ao `git` (`-c`, `--config-env`);
  - `git commit` (inclusive `-a`) com `.env`, `*.pem`, `*.key`, `id_rsa` ou chave conhecida (AWS, GitHub, Anthropic, OpenAI, Slack, Google, GitLab, Stripe, chave privada) nas linhas adicionadas; `.env.example` passa. Com `git add` no mesmo comando, examina a árvore de trabalho inteira, inclusive arquivos novos (pode bloquear por um arquivo não rastreado que não ia entrar); segue `cd dir` e `git -C dir`;
  - `DELETE`/`UPDATE` sem `WHERE` quando o comando chama `sqlite3`, `psql`, `mysql`, `wrangler` etc.;
  - escrita pelo shell em `.claude/settings*` ou `.claude/hooks/` (`>`, `sed -i`, `cp`, `mv`, `tee`, `Set-Content`…). As ferramentas Edit/Write já são protegidas pelo Claude Code, que nunca aprova sozinho escrita em `.claude/`;
  - **agents somente leitura:** quando quem chama é o `architect`, o `reviewer` ou o `security` (campo `agent_type` que o Claude Code envia ao hook), bloqueia qualquer escrita pelo shell: redirecionamento para arquivo, `rm`, `mv`, `cp`, `touch`, `sed -i`, `tee`, `find -delete`, `git add/commit/push/checkout/reset` e afins. Leitura, `git diff/log/status` e testes passam. É melhor esforço, não sandbox: script que grava por dentro (`python -c`, `node -e`) não é visto.
  Texto de mensagem de commit (`-m "..."`) não dispara os bloqueios de comando. Usa `jq` ou `python3` se houver; senão lê o JSON bruto. Teste: `bash tests/guard.test.sh`.
- **Sandbox nativo** (`sandbox.enabled`): o sistema operacional limita escrita e rede dos comandos de shell e esconde `~/.ssh`, `~/.aws/credentials` e `~/.gnupg` deles. Funciona em macOS, Linux e WSL2; no Linux/WSL2 precisa de `bubblewrap` e `socat` (ex.: `sudo apt-get install bubblewrap socat`); veja o estado com `/sandbox`. Sem eles, ou no Windows nativo, os comandos rodam fora do sandbox. `autoAllowBashIfSandboxed: false` mantém os pedidos de permissão de sempre; mude para `true` se quiser que comandos dentro do sandbox rodem sem perguntar. Repetir um comando fora do sandbox sempre pergunta (`Bash(dangerouslyDisableSandbox:true)` em `ask`).

## Plugins e referências (opcional)
Não vêm instalados; avalie com a skill `discover-resources`.
- **Language server** da sua linguagem (`/plugin` → Discover, marketplace `claude-plugins-official`): navegação de código mais barata que Grep.
- **`claude-security@claude-plugins-official`**: varredura de segurança do repositório ou só do diff, sob demanda (`/claude-security`), com cada achado verificado antes do relatório; não aplica nada sozinho. Preferido ao `security-guidance`, que faz uma chamada de LLM ao fim de todo turno.
- **`claude-code-setup@claude-plugins-official`**: lê o projeto e recomenda hooks, skills, MCP e subagents. Somente leitura; rode uma vez por projeto.
- `code-review` e `feature-dev` repetem o `reviewer` e o `architect`/`developer`; não instale junto.
- Referências: [anthropics/skills](https://github.com/anthropics/skills) (formato de skills), [obra/superpowers](https://github.com/obra/superpowers) (TDD e depuração, de onde vieram os passos do `tester` e do `debugger`), [karanb192/claude-code-hooks](https://github.com/karanb192/claude-code-hooks) e [disler/claude-code-damage-control](https://github.com/disler/claude-code-damage-control) (hooks de segurança).

## Testes
```bash
bash tests/guard.test.sh      # hook
bash tests/install.test.sh    # install.sh, em pastas temporárias
bash tests/skills.test.sh     # cabeçalho de skills e agents (name igual à pasta, description presente e até 400 caracteres)
bash tests/package.test.sh    # package.sh: um zip por skill, pasta no topo, com zip e com python
pwsh -NoProfile -File tests/install.test.ps1   # install.ps1 (Windows)
pwsh -NoProfile -File tests/package.test.ps1   # package.ps1 (Windows)
```
O CI (`.github/workflows/test.yml`) roda tudo em todo PR, mais o `shellcheck` nos scripts. O Dependabot (`.github/dependabot.yml`) abre PR quando sai versão nova das actions. Na reinstalação, `decisoes.md` é substituído pelo do repositório; a versão anterior fica no backup.

## Limites
- Regras do `CLAUDE.md` e dos agents são orientação ao modelo, não garantia.
- `settings.json` bloqueia por prefixo de comando; o hook `guard.sh` cobre as variações comuns (ex.: `rm -r -f`), mas é análise de texto: comando ofuscado (variáveis, `eval`, base64) pode passar, e texto citado fora de mensagem de commit, como `echo "rm -rf x"`, é bloqueado por precaução. Escrita em `.claude/` por script (ex.: Python) não é pega pelo hook; o sandbox nega essa escrita. Isolamento real só com o sandbox.
- As regras `Bash(...)` não valem para a ferramenta PowerShell (Windows); por isso o `settings.json` repete os bloqueios como `PowerShell(...)`. O hook roda com `bash`: no Windows precisa do Git Bash à frente do `bash.exe` do WSL no `PATH`; sem ele, o hook falha sem bloquear.
- `Read(**/.env)` bloqueia `.env` em qualquer subpasta do projeto; `Read(./.env)` pegaria só o da raiz.
- Agents com `tools:` restrito (architect, reviewer, security) não têm Edit/Write; a escrita pelo shell é barrada pelo hook no modo somente leitura. Script que grava arquivo por dentro (ex.: `python -c`) não é pego.
