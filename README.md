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
│   ├── reviewer.md       revisão do diff, somente leitura (opus)
│   ├── security.md       auditoria, somente leitura (sonnet)
│   └── devops.md         Git, CI/CD, deploy (sonnet)
└── skills/
    └── discover-resources/   avaliar recurso externo antes de instalar
```

## Instalação

**Num projeto:** copie `CLAUDE.md` e `.claude/` para a raiz do repositório.

**Para todos os projetos (nível do usuário):** copie `.claude/agents` e `.claude/skills` para `%USERPROFILE%\.claude\`. Não sobrescreva o `settings.json` do usuário: junte as regras de `permissions` às que já existem.

## Limites
- Regras do `CLAUDE.md` e dos agents são orientação ao modelo, não garantia.
- `settings.json` bloqueia por prefixo de comando: pega o caso comum, mas não cobre toda variação (ex.: `rm -r -f`). Não é sandbox.
- Agents com `tools:` restrito (architect, reviewer, security) não têm Edit/Write; ainda têm Bash, então a restrição de não editar via shell é por instrução.
