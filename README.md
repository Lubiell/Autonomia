# Claude Code — Orquestrador

Configuração de orquestração para o Claude Code: regras permanentes, 8 agents especializados, 1 skill, permissões, sandbox e um hook de segurança.

```text
CLAUDE.md                 regras permanentes e roteamento
install.sh / install.ps1  instalação no nível do usuário (~/.claude)
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
│   └── scout.md          localiza código, somente leitura (sonnet)
└── skills/
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

## Economia de tokens
- `CLAUDE.md` entra em todo turno: mantenha-o curto. Instrução longa e rara vai para uma skill (só a `description` fica no contexto até ela ser usada).
- A `description` dos agents decide quando o Claude delega. Cada subagent começa do zero e relê contexto, então architect e reviewer só disparam em mudança não trivial.
- Modelo por custo: `haiku` para execução (tester, devops), `sonnet` onde a qualidade pesa (scout, developer, debugger, reviewer, security) e `opus` só no architect, que é raro.
- O `scout` localiza código e devolve só `arquivo:linha`, para a sessão principal ler apenas os trechos certos. Ele roda com `omitClaudeMd: true` (Claude Code v2.1.271+), sem carregar o `CLAUDE.md`.
- `settings.json` nega leitura de `node_modules`, `.venv`, `venv`, `__pycache__` e `coverage` para o Claude não carregar arquivos gerados no contexto.

## Segurança em camadas
- **Permissões (`deny`/`ask`)**: bloqueio por prefixo de comando e leitura de arquivos sensíveis.
- **Hook `guard.sh`** (PreToolUse em Bash e PowerShell): analisa o comando inteiro, separado por `;`, `|`, `&&`, `$( )` etc., e bloqueia:
  - `rm` recursivo forçado (`-rf`, `-r -f`, `-fr`, `sudo`, `xargs`, `bash -c`), `Remove-Item -Recurse`, `git push --force`/`-f`/`+ref`, `git reset --hard`, `git clean -f` sem `-n` e `curl … | sh`; `--force-with-lease` passa;
  - `git commit` (inclusive `-a`) com `.env`, `*.pem`, `*.key`, `id_rsa` ou chave conhecida (AWS, GitHub, Anthropic, OpenAI, Slack, Google, GitLab, chave privada) nas linhas adicionadas; `.env.example` passa. Com `git add` no mesmo comando, examina a árvore de trabalho inteira, inclusive arquivos novos (pode bloquear por um arquivo não rastreado que não ia entrar); segue `cd dir` e `git -C dir`;
  - `DELETE`/`UPDATE` sem `WHERE` quando o comando chama `sqlite3`, `psql`, `mysql`, `wrangler` etc.;
  - escrita pelo shell em `.claude/settings*` ou `.claude/hooks/` (`>`, `sed -i`, `cp`, `mv`, `tee`, `Set-Content`…). As ferramentas Edit/Write já são protegidas pelo Claude Code, que nunca aprova sozinho escrita em `.claude/`.
  Usa `jq` ou `python3` se houver; senão lê o JSON bruto. Teste: `bash tests/guard.test.sh`.
- **Sandbox nativo** (`sandbox.enabled`): o sistema operacional limita escrita e rede dos comandos de shell e esconde `~/.ssh`, `~/.aws/credentials` e `~/.gnupg` deles. Funciona em macOS, Linux e WSL2; no Linux/WSL2 precisa de `bubblewrap` e `socat` (ex.: `sudo apt-get install bubblewrap socat`); veja o estado com `/sandbox`. Sem eles, ou no Windows nativo, os comandos rodam fora do sandbox. `autoAllowBashIfSandboxed: false` mantém os pedidos de permissão de sempre; mude para `true` se quiser que comandos dentro do sandbox rodem sem perguntar. Repetir um comando fora do sandbox sempre pergunta (`Bash(dangerouslyDisableSandbox:true)` em `ask`).

## Plugins e referências (opcional)
Não vêm instalados; avalie com a skill `discover-resources`.
- **Language server** da sua linguagem (`/plugin` → Discover, marketplace `claude-plugins-official`): navegação de código mais barata que Grep.
- **`security-guidance@claude-plugins-official`**: avisos de padrões inseguros ao editar e revisão de segurança do diff. Custa uma chamada de LLM ao fim de cada turno e em `git commit`/`git push` e exige Python 3.8+; `ENABLE_STOP_REVIEW=0` deixa só as revisões de commit/push.
- `code-review` e `feature-dev` repetem o `reviewer` e o `architect`/`developer`; não instale junto.
- Referências: [anthropics/skills](https://github.com/anthropics/skills) (formato de skills), [obra/superpowers](https://github.com/obra/superpowers) (TDD e depuração, de onde vieram os passos do `tester` e do `debugger`), [karanb192/claude-code-hooks](https://github.com/karanb192/claude-code-hooks) e [disler/claude-code-damage-control](https://github.com/disler/claude-code-damage-control) (hooks de segurança).

## Testes
```bash
bash tests/guard.test.sh      # hook
bash tests/install.test.sh    # install.sh, em pastas temporárias
pwsh -NoProfile -File tests/install.test.ps1   # install.ps1 (Windows)
```
O CI (`.github/workflows/test.yml`) roda tudo em todo PR. Na reinstalação, `decisoes.md` é substituído pelo do repositório; a versão anterior fica no backup.

## Limites
- Regras do `CLAUDE.md` e dos agents são orientação ao modelo, não garantia.
- `settings.json` bloqueia por prefixo de comando; o hook `guard.sh` cobre as variações comuns (ex.: `rm -r -f`), mas é análise de texto: comando ofuscado (variáveis, `eval`, base64) pode passar, e texto citado, como `git commit -m "rm -rf docs"`, é bloqueado por precaução. Escrita em `.claude/` por script (ex.: Python) não é pega pelo hook; o sandbox nega essa escrita. Isolamento real só com o sandbox.
- As regras `Bash(...)` não valem para a ferramenta PowerShell (Windows); por isso o `settings.json` repete os bloqueios como `PowerShell(...)`. O hook roda com `bash`: no Windows precisa do Git Bash à frente do `bash.exe` do WSL no `PATH`; sem ele, o hook falha sem bloquear.
- `Read(**/.env)` bloqueia `.env` em qualquer subpasta do projeto; `Read(./.env)` pegaria só o da raiz.
- Agents com `tools:` restrito (architect, reviewer, security) não têm Edit/Write; ainda têm Bash, então a restrição de não editar via shell é por instrução.
