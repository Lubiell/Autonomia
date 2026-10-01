# Claude Code — Orquestrador

Configuração de orquestração para o Claude Code: regras permanentes, 7 agents especializados, 1 skill e permissões.

```text
CLAUDE.md                 regras permanentes e roteamento
.claude/
├── settings.json         bloqueios reais (deny/ask), não dependem do modelo
├── agents/
│   ├── architect.md      planeja, somente leitura (opus)
│   ├── developer.md      implementa (sonnet)
│   ├── debugger.md       causa raiz + menor correção (sonnet)
│   ├── tester.md         testes (sonnet)
│   ├── reviewer.md       revisão do diff, somente leitura (sonnet)
│   ├── security.md       auditoria, somente leitura (sonnet)
│   └── devops.md         Git, CI/CD, deploy (sonnet)
└── skills/
    └── discover-resources/   avaliar recurso externo antes de instalar
```

## Instalação

**Num projeto:** copie `CLAUDE.md` e `.claude/` para a raiz do repositório.

**Para todos os projetos e conversas (nível do usuário):** copie `CLAUDE.md`, `.claude/agents` e `.claude/skills` para `~/.claude/` (Windows: `%USERPROFILE%\.claude\`). Não sobrescreva o `settings.json` do usuário: junte as regras de `permissions` às que já existem.

Use **um** dos dois modos. Se o `CLAUDE.md` estiver no nível do usuário e também na raiz do projeto, os dois são carregados em toda conversa e as regras são pagas em dobro. No projeto, deixe só o que for específico dele.

## Economia de tokens
- `CLAUDE.md` entra em todo turno: mantenha-o curto. Instrução longa e rara vai para uma skill (só a `description` fica no contexto até ela ser usada).
- A `description` dos agents decide quando o Claude delega. Cada subagent começa do zero e relê contexto, então architect e reviewer só disparam em mudança não trivial.
- Agents em `sonnet`; só o architect, raro, fica em `opus`.
- `settings.json` nega leitura de `node_modules`, `.venv`, `venv`, `__pycache__` e `coverage` para o Claude não carregar arquivos gerados no contexto.

## Limites
- Regras do `CLAUDE.md` e dos agents são orientação ao modelo, não garantia.
- `settings.json` bloqueia por prefixo de comando: pega o caso comum, mas não cobre toda variação (ex.: `rm -r -f`). Não é sandbox.
- Agents com `tools:` restrito (architect, reviewer, security) não têm Edit/Write; ainda têm Bash, então a restrição de não editar via shell é por instrução.
