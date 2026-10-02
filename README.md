# Claude Code — Orquestrador

Configuração de orquestração para o Claude Code: regras permanentes, 8 agents especializados, 1 skill e permissões.

```text
CLAUDE.md                 regras permanentes e roteamento
install.sh / install.ps1  instalação no nível do usuário (~/.claude)
.claude/
├── settings.json         bloqueios reais (deny/ask), não dependem do modelo
├── agents/
│   ├── architect.md      planeja, somente leitura (opus)
│   ├── developer.md      implementa (sonnet)
│   ├── debugger.md       causa raiz + menor correção (sonnet)
│   ├── tester.md         testes (haiku)
│   ├── reviewer.md       revisão do diff, somente leitura (sonnet)
│   ├── security.md       auditoria, somente leitura (sonnet)
│   ├── devops.md         Git, CI/CD, deploy (haiku)
│   └── scout.md          localiza código, somente leitura (haiku)
└── skills/
    └── discover-resources/   avaliar recurso externo antes de instalar
```

## Instalação

**Num projeto:** copie `CLAUDE.md` e `.claude/` para a raiz do repositório.

**Para todos os projetos e conversas (nível do usuário):** rode o instalador na pasta do repositório.

```bash
./install.sh                                          # Linux / macOS
powershell -ExecutionPolicy Bypass -File .\install.ps1  # Windows
```

Ele copia `CLAUDE.md`, os agents e as skills para `~/.claude/` e junta as regras `deny`/`ask` às do seu `settings.json`, sem apagar as que você já tem. Os arquivos que ele substitui vão para `~/.claude/backup-orquestrador-<data>/`. Pode rodar de novo para atualizar. Para instalar em outra pasta, defina `CLAUDE_HOME`.

Use **um** dos dois modos. Se o `CLAUDE.md` estiver no nível do usuário e também na raiz do projeto, os dois são carregados em toda conversa e as regras são pagas em dobro. No projeto, deixe só o que for específico dele.

## Economia de tokens
- `CLAUDE.md` entra em todo turno: mantenha-o curto. Instrução longa e rara vai para uma skill (só a `description` fica no contexto até ela ser usada).
- A `description` dos agents decide quando o Claude delega. Cada subagent começa do zero e relê contexto, então architect e reviewer só disparam em mudança não trivial.
- Modelo por custo: `haiku` para busca e execução (scout, tester, devops), `sonnet` onde a qualidade pesa (developer, debugger, reviewer, security) e `opus` só no architect, que é raro.
- O `scout` localiza código e devolve só `arquivo:linha`, para a sessão principal ler apenas os trechos certos. Ele roda com `omitClaudeMd: true` (Claude Code v2.1.271+), sem carregar o `CLAUDE.md`.
- `settings.json` nega leitura de `node_modules`, `.venv`, `venv`, `__pycache__` e `coverage` para o Claude não carregar arquivos gerados no contexto.

## Limites
- Regras do `CLAUDE.md` e dos agents são orientação ao modelo, não garantia.
- `settings.json` bloqueia por prefixo de comando: pega o caso comum, mas não cobre toda variação (ex.: `rm -r -f`). Não é sandbox.
- As regras `Bash(...)` não valem para a ferramenta PowerShell (Windows); por isso o `settings.json` repete os bloqueios como `PowerShell(...)`.
- `Read(**/.env)` bloqueia `.env` em qualquer subpasta do projeto; `Read(./.env)` pegaria só o da raiz.
- Agents com `tools:` restrito (architect, reviewer, security) não têm Edit/Write; ainda têm Bash, então a restrição de não editar via shell é por instrução.
