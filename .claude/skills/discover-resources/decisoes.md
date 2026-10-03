# Decisões sobre recursos externos

Registro único do que foi adotado, está na fila, fica opcional ou foi recusado, para não reavaliar a mesma coisa nem instalar de novo o que já foi recusado. Recusa se reverte só com motivo novo, não por "vi de novo numa lista".

Índice: adotados · instalar (fila) · complementos pontuais · opcionais · recusados · ferramentas externas · cobertos por texto · como manter

Instalar sempre um por vez, usando por uma semana antes do próximo. Auditar antes com `auditoria.md`.

## Adotados
- Sandbox nativo do Claude Code — docs oficiais (`sandbox.enabled`) — isolamento de escrita e rede do shell em macOS/Linux/WSL2; no Windows nativo fica desligado — 2026-10-02
- Hook `guard.sh` próprio — este repositório — bloqueia comando destrutivo, segredo em commit, `DELETE`/`UPDATE` sem `WHERE` e escrita na configuração, sem dependência nova — 2026-10-02
- Passos de teste primeiro e hipótese com evidência (agents `tester` e `debugger`) — ideia de `obra/superpowers` (MIT), sem instalar — 2026-10-02
- Checklist de auditoria, registro de decisões e regra de evidência — adaptados da skill `protocolo-dev` — 2026-10-02
- Regra contra concordar por insistência (`CLAUDE.md`) e causa raiz por categorias, pontos cegos e 5 porquês (agent `debugger`) — ideias do material "Agente de Diagnóstico" (ExStart), adaptadas sem copiar — 2026-10-03
- Perguntas em aberto no agent `architect` (cada ramo de decisão que o código não responde vira pergunta fechada com recomendação) — ideia da skill `grill-me` de `mattpocock/skills` (MIT), sem instalar — 2026-10-03

## Instalar — fila, em ordem de valor
| Ferramenta | O que resolve | Onde |
|---|---|---|
| `NVIDIA/SkillSpector` | audita skill antes de instalar. Vem **primeiro**: é ele que checa o resto | GitHub |
| `pyright-lsp` | erro de tipo no mesmo turno em vez de dez turnos depois. Exige o binário `pyright-langserver` no PATH | marketplace oficial |
| `claude-security` | varredura de segurança do repositório ou do diff, sob demanda, com cada achado verificado antes do relatório; não aplica nada sozinho. Substitui o `security-guidance` na fila (2026-10-03) | marketplace oficial |
| `claude-code-setup` | lê o projeto e recomenda hooks, skills, MCP e subagents; somente leitura, uma vez por projeto (2026-10-03) | marketplace oficial |
| `session-report` | mostra tokens, cache e quais skills dispararam. Único jeito de medir se as regras funcionam | marketplace oficial |
| `context7` | documentação da versão certa; evita API inventada em biblioteca que mudou | marketplace oficial |
| `code-simplifier` | corta o que foi escrito a mais, preservando comportamento | marketplace oficial |
| `skill-eval-action` | testa se a skill dispara, rodando no GitHub — funciona pelo celular | GitHub Action |
| `Sentry` | erro em produção chega no celular. Hoje o trabalho termina no deploy e depois fica cego | MCP oficial |
| `anthropics/claude-code-action` | agente roda no GitHub e abre PR sem ele estar no PC. Fixar versão ≥ v1.0.94 (CVE 7.8) e restringir gatilho ao dono do repo | GitHub Action |
| `anthropics/claude-code-security-review` | revisão de segurança do diff em todo PR | GitHub Action |
| `trailofbits/skills` (avulsos: secrets hygiene, release prep, Semgrep) | análise estática de verdade; importa porque há dado de saúde em repo público. **Nunca o marketplace inteiro** (~60 skills, maioria blockchain). Licença CC-BY-SA-4.0 | GitHub |

## Complementos pontuais
Instalar só quando o trabalho for daquele tipo, e desinstalar depois:
`playwright` (teste de navegador), `cloudflare` (Workers/D1), `frontend-design` (UI), `canva` (peça gráfica), `marketing` (campanha e conteúdo).

## Opcionais
- Language server da linguagem do projeto (além do `pyright-lsp`) — marketplace oficial — busca por símbolo mais barata que Grep; escolher por projeto — 2026-10-02

## Recusados — não instalar
| Ferramenta | Motivo |
|---|---|
| `superpowers` | camada de workflow completa: duplica os agents e o `protocolo-dev`, e injeta texto em toda sessão via SessionStart. 988k instalações não mudam isso — seria substituição, não complemento |
| `feature-dev`, `code-review` | trazem o próprio ciclo de planejar/construir/revisar; duplicam `architect`, `developer` e `reviewer` |
| `pr-review-toolkit` | colide com o agent `reviewer` |
| `disler/claude-code-damage-control` | exige `uv` ou Bun; coberto pelo `guard.sh` (2026-10-02) |
| `karanb192/claude-code-hooks` | exige Node ≥18; coberto pelo `guard.sh` (2026-10-02) |
| `security-guidance` | trocado pelo `claude-security`: faz uma chamada de LLM ao fim de todo turno e em `git commit`/`push` e exige Python; o `claude-security` roda só quando chamado (2026-10-03) |
| `caveman` (JuliusBrussee/caveman) | o modo proxy intercepta o tráfego da API; a skill só encurta a prosa, que o `CLAUDE.md` já pede curta, e é feita para inglês. Ganho real citado no próprio repositório (estudo JetBrains): ~8,5% menos tokens de saída, não os 65% anunciados (2026-10-03) |
| `impeccable` (pbakaus/impeccable) | instala hooks no `~/.claude` e baixa um binário na primeira execução; para UI, `frontend-design` e a skill `web-design-guidelines` já cobrem. Reavaliar só se houver trabalho de interface constante (2026-10-03) |
| `last30days` (mvanhorn/last30days-skill) | pesquisa de tendências em redes sociais; fora do escopo de desenvolvimento (2026-10-03) |
| `wshobson/agents` | coleção de 199 agents, 161 skills e 90 plugins: gatilhos sobrepostos aos agents daqui (2026-10-03) |
| `ai-berkshire` (xbtlin/ai-berkshire) | análise de investimentos, fora do escopo; instala por script (`install-claude-commands.sh`) (2026-10-03) |
| Coleções de centenas de skills ("awesome" e afins) | sobreposição de gatilho em massa e custo de `description` por requisição; só como fonte de consulta |
| `OmniRoute` | proxy que roteia o tráfego para provedores externos. Instalado, mas **não ativado**. Nunca ativar na máquina do trabalho |
| `Headroom` | proxy de compressão entre o usuário e a API. Mesmo tratamento |
| `Repowise`, `Serena` | indexação semântica de repo grande; exigem servidor local e ~25 min de índice. Repos pequenos, trabalho pelo celular — custo sem ganho |
| modpack `repowise-dev` (no-ai-slop, critic, devil, deep, risk, decision) | personas de resposta; disputam gatilho com o agent `reviewer` e com `spec.md` |
| `Strix` | pentest autônomo real, mas exige Docker, chave de LLM paga e scan de 1–4h. Cobrir com `security-review.yml` no CI em vez disso |
| `Ralph loop` | repete o prompt sem gate de verificação; a regra de evidência já confere saída real |

## Ferramentas externas avaliadas
Detalhe de uso em `ferramentas-externas.md` do `protocolo-dev`.

| Ferramenta | Decisão |
|---|---|
| `browser-use` | usar só quando Playwright não der conta. Exige Python 3.11+ |
| `n8n` | vale para ligar sistemas. Lógica de negócio fica em código, não no fluxo |
| `awesome-mcp-servers` | fonte de consulta quando faltar conector. Catálogo aberto, não é aval |
| `CrewAI`, `LangGraph` | só se o projeto for construir um agente. Não instalar "para ajudar" |
| `Aider`, `OpenHands` | agentes rivais, rodam ao lado. Um agente principal só |
| `Fooocus` | exige GPU dedicada. Sem ela não roda. Canva já cobre peça gráfica |
| `claude-task-master` | recusado: colide com `spec.md` e com o agent `architect`. Licença NOASSERTION |

## Cobertos por texto — não instalar
Do repositório `addyosmani/agent-skills` (MIT, auditado: sem rede, sem `eval`, hooks não registrados automaticamente):
`spec-driven-development` → `spec.md` · `source-driven-development` e `doubt-driven-development` → regra de evidência do `CLAUDE.md` · `incremental-implementation` → agent `architect` · `browser-testing-with-devtools` → `testes.md` · `context-engineering` → seção Economia de contexto do `CLAUDE.md`

Instalá-las por cima duplicaria o gatilho. Se um desses textos se mostrar fraco na prática, vale ler a versão de lá e melhorar o daqui — não instalar as duas.

## Como manter
- Instalou, recusou ou desinstalou: registrar aqui na mesma hora, com o motivo em uma linha. Decisão que não vira linha se perde.
- Formato das linhas soltas: recurso — origem — decisão e motivo — data.
- Revisar a cada dois meses ou ao trocar de modelo: o que está na fila e não foi instalado, e o que está instalado e aparece em "Not used recently" no `/plugin`.
