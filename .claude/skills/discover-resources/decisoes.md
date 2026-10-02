# Decisões sobre recursos externos

Registro do que foi adotado, deixado como opcional ou recusado, para não reavaliar a mesma coisa. Recusa se reverte só com motivo novo, não por "vi de novo numa lista".

Formato: recurso — origem — decisão e motivo em uma linha — data.

## Adotados
- Sandbox nativo do Claude Code — docs oficiais (`sandbox.enabled`) — isolamento real de escrita e rede dos comandos de shell; sem dependência no macOS — 2026-10-02
- Hook `guard.sh` próprio — este repositório — bloqueio de comandos destrutivos, segredo em commit e `DELETE`/`UPDATE` sem `WHERE` sem dependência nova; inspirado nos projetos recusados abaixo — 2026-10-02
- Passos de teste primeiro e hipótese com evidência (texto nos agents `tester` e `debugger`) — `obra/superpowers` (MIT) — só a ideia, sem instalar — 2026-10-02
- Checklist de auditoria, registro de decisões e gate de verificação — skill `protocolo-dev` do usuário — adaptados como texto — 2026-10-02

## Opcionais (não instalados)
- `security-guidance@claude-plugins-official` — marketplace oficial — útil, mas faz uma chamada de LLM ao fim de cada turno e em `git commit`/`push` e exige Python 3.8+; instalar só se o custo valer — 2026-10-02
- Language server da linguagem do projeto — marketplace oficial — busca por símbolo mais barata que Grep; escolher por projeto — 2026-10-02

## Recusados
- `obra/superpowers` — GitHub — camada de workflow completa que duplica os agents e injeta texto em toda sessão via SessionStart — 2026-10-02
- `feature-dev`, `code-review`, `pr-review-toolkit` — marketplace oficial — duplicam `architect`/`developer`/`reviewer` — 2026-10-02
- `disler/claude-code-damage-control` — GitHub (MIT) — exige `uv` ou Bun; coberto pelo `guard.sh` — 2026-10-02
- `karanb192/claude-code-hooks` — GitHub (MIT) — exige Node ≥18; coberto pelo `guard.sh` — 2026-10-02
- Coleções "awesome" com centenas de agents/skills — GitHub — gatilhos sobrepostos e custo de contexto; só como fonte de consulta — 2026-10-02
