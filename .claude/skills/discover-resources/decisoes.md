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
- Skill `analise-dados` (definir → validar → investigar → priorizar → entregar, checklist de dashboard) — método dos materiais "Agente de Diagnóstico", "Kit Claude Dash" e "25 prompts de dashboard" (ExStart), reescrito sem copiar — 2026-10-03
- `shellcheck` no CI (nível warning, só Linux, já vem no runner) e Dependabot para as GitHub Actions, com `actions/checkout` fixado por hash — recursos nativos do GitHub; o hash fixado segue a recomendação do `agentic-actions-auditor` (`trailofbits/skills`) — 2026-10-03
- Regra "pedido com duas leituras: apresente as duas" no `CLAUDE.md` — princípio 1 de `multica-ai/andrej-karpathy-skills` (MIT); os outros três já estavam cobertos — 2026-10-03
- Skills `frontend-design` e `webapp-testing` — `anthropics/skills` (Apache-2.0), cópia sem alteração do commit `8a1541c` com o `LICENSE.txt`; auditadas: só instruções, o script `with_server.py` sobe o servidor indicado e testa a porta em localhost. Para sites: direção visual que não parece template e teste no navegador real com Playwright (instalar `playwright` no projeto quando for usar) — 2026-10-03
- Bloqueio de `--no-verify`, `git commit -n` e `core.hooksPath` no `guard.sh`, e "corrija o código, não a configuração de lint/teste" nos agents `developer` e `tester` — ideias de `block-no-verify.js` e `config-protection.js` de `affaan-m/everything-claude-code` (MIT), reescritas em bash sem copiar código; chave Stripe (`sk_live_`/`rk_live_`) na varredura de segredo, de `rohitg00/awesome-claude-code-toolkit` — 2026-10-03
- Escada "precisa existir? já existe? biblioteca padrão? recurso nativo? dependência instalada?" no `developer` e "procure todos os chamadores e corrija no ponto comum" no `debugger` — ideias da skill `DietrichGebert/ponytail` (MIT), sem instalar: a skill pede para ficar ativa em toda resposta e o resto já está no `CLAUDE.md` ("menor alteração adequada") — 2026-10-03
- `tests/skills.test.sh` no CI: confere name igual à pasta, padrão do name e description presente e com até 1024 caracteres em skills e agents — ideia do `validate.sh` de `matheus-ft/skills` (MIT), reescrito; a ideia do `package.sh` dele virou o `package.sh`/`package.ps1` do Autonomia (zip por skill para o claude.ai), escrito do zero; o `drift.sh` (comparar com o que está na conta) não, porque exige ler a conta — 2026-10-03
- Agents `data-analyst` (base de dados processada fora da conversa principal, segue a `analise-dados`) e `qa-web` (site no navegador real, sem editar); skills `deploy-web` (checklist de publicação para GitHub Pages, Cloudflare e Firebase) e `handoff` (passagem de sessão, só por `/handoff`, sem custo de descrição por turno; ideia de `mattpocock/skills`, MIT, reescrita) — escritos para o Autonomia — 2026-10-03
- Skills `seo` (checklist de SEO técnico e de conteúdo, Core Web Vitals, Search Console) e `conteudo` (redes sociais e anúncios: briefing, gancho, formatos, limites por plataforma, sem promessa enganosa) — escritas para o Autonomia; a descrição da `conteudo` é específica de redes e anúncios para não disputar gatilho com a parte de redação da skill de conta `protocolo-dev` — 2026-10-04
- Agent `docs-writer` (documentação a partir do código real, comandos verificados ou marcados [NÃO VERIFICADO]) e skill `grill-me` (entrevista uma pergunta por vez, com resposta recomendada; só por `/grill-me` para não disputar gatilho com a skill de conta `brainstorming`; ideia de `mattpocock/skills`, MIT, reescrita) — 2026-10-04
- Skills `banco-dados`, `api-backend`, `automacao` e `trafego-pago` e agent `researcher` (pesquisa web isolada, com fonte e data) — escritos para o Autonomia para cobrir dados persistidos, backend, rotinas agendadas, anúncios e pesquisa; limite de 400 caracteres por description no `skills.test.sh` para o custo por turno não crescer sem controle — 2026-10-04
- `guard.sh` bloqueia `DROP TABLE`/`DATABASE`/`TRUNCATE` em cliente de banco e exclusão irreversível na nuvem (wrangler, firebase, gh repo delete); `.dev.vars` (segredos locais do Cloudflare) como arquivo sensível no commit e, com `*.p12`/`*.pfx`, negado ao Read — 2026-10-04
- Do carrossel "80 repositórios de segurança" (professordeti, 2026-10-04): `trufflesecurity/trufflehog` (AGPL-3.0), `github/codeql`, `zaproxy/zaproxy` e `OWASP/CheatSheetSeries` entram como **recomendação** no agent `security` (usar se instalado, nunca instalar sozinho); OWASP Cheat Sheet Series e `shieldfy/API-Security-Checklist` como referência na `api-backend`, que já cobre os itens do checklist — 2026-10-04
- Checklist "falhas típicas de código gerado por IA" no agent `security` e veredito "NÃO PRONTO sem evidência" no `qa-web` — ideias dos agents AI-Generated Code Security Auditor e Reality Checker de `msitarzewski/agency-agents` (MIT), reescritas em português, sem copiar — 2026-10-04
- Skills `negocios`, `projetos`, `atendimento-vendas`, `seguranca-digital`, `midia` e `lgpd` — escritas para o Autonomia cobrir as áreas além de desenvolvimento; afirmações legais e técnicas conferidas (ANPD Res. 15/2024, CDC art. 49, Lei 12.737/2012, winget Gyan.FFmpeg, NPS); segurança ofensiva só como estudo em laboratório próprio, sem instalar ferramenta de ataque — 2026-10-04
- Skills `produto`, `prompts-ia` e `cursos` — áreas cobertas pelo catálogo `agency-agents` (product-manager, feedback-synthesizer, image-prompt-engineer, corporate-training-designer) e ausentes no Autonomia; escritas do zero em português, sem copiar — 2026-10-05
- Perguntas em aberto no agent `architect` (cada ramo de decisão que o código não responde vira pergunta fechada com recomendação) — ideia da skill `grill-me` de `mattpocock/skills` (MIT), sem instalar — 2026-10-03

## Instalar — fila, em ordem de valor
| Ferramenta | O que resolve | Onde |
|---|---|---|
| `NVIDIA/SkillSpector` | audita skill antes de instalar. Vem **primeiro**: é ele que checa o resto | GitHub |
| `pyright-lsp` | erro de tipo no mesmo turno em vez de dez turnos depois. Exige o binário `pyright-langserver` no PATH | marketplace oficial |
| `claude-security` | varredura de segurança do repositório ou do diff, sob demanda, com cada achado verificado antes do relatório; não aplica nada sozinho. Substitui o `security-guidance` na fila (2026-10-03) | marketplace oficial |
| `claude-code-setup` | lê o projeto e recomenda hooks, skills, MCP e subagents; somente leitura, uma vez por projeto (2026-10-03) | marketplace oficial |
| `session-report` | mostra tokens, cache e quais skills dispararam. Único jeito de medir se as regras funcionam | marketplace oficial |
| `context7` | documentação da versão certa; evita API inventada em biblioteca que mudou. É servidor MCP: `npx ctx7 setup --claude` pede login e gera chave | marketplace oficial |
| `code-simplifier` | corta o que foi escrito a mais, preservando comportamento | marketplace oficial |
| `skill-eval-action` | testa se a skill dispara, rodando no GitHub — funciona pelo celular | GitHub Action |
| `Sentry` | erro em produção chega no celular. Hoje o trabalho termina no deploy e depois fica cego | MCP oficial |
| `anthropics/claude-code-action` | agente roda no GitHub e abre PR sem ele estar no PC. Fixar versão ≥ v1.0.94 (CVE 7.8) e restringir gatilho ao dono do repo | GitHub Action |
| `anthropics/claude-code-security-review` | revisão de segurança do diff em todo PR | GitHub Action |
| `trailofbits/skills` (avulsos: secrets hygiene, release prep, Semgrep) | análise estática de verdade; importa porque há dado de saúde em repo público. **Nunca o marketplace inteiro** (~60 skills, maioria blockchain). Licença CC-BY-SA-4.0 | GitHub |

## Complementos pontuais
Instalar só quando o trabalho for daquele tipo, e desinstalar depois:
`playwright` (teste de navegador; a skill `webapp-testing` já vem no Autonomia), `cloudflare` (Workers/D1), `frontend-design` (UI), `canva` (peça gráfica), `marketing` (campanha e conteúdo). Do pack `coreyhaines31/marketingskills` (MIT, ~50 skills), copiar à mão só a skill avulsa que o trabalho pedir (`social`, `copywriting`, `video`), nunca o pack inteiro.

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
| `claude-mem` (thedotmack/claude-mem) | instalador `npx` que grava as sessões e injeta resumo em toda sessão nova; a continuidade aqui é o `PROGRESS.md` versionado (`handoff.md` do `protocolo-dev`) (2026-10-03) |
| `ui-ux-pro-max` (nextlevelbuilder) | sobrepõe `frontend-design` e `web-design-guidelines`; a busca exige Python (2026-10-03) |
| `w95/awesome-claude-corporate-skills` | finanças, operações e jurídico escritos para o direito e a contabilidade dos EUA; fora do escopo de desenvolvimento, e copiar as pastas inteiras traz mais de 40 skills (2026-10-03) |
| `rampstackco/claude-skills` (launch-runbook) | o checklist de publicação já está no `deploy.md` do `protocolo-dev` (2026-10-03) |
| "Prompt de instalação" das 42 skills (@marcondes.ai) | instala tudo de uma vez, contra a regra de um recurso por vez; skills oficiais citadas (`skill-creator`, `mcp-builder`, `frontend-design`, `canvas-design`, `xlsx`, `docx`, `internal-comms` e outras) já estão disponíveis na conta (2026-10-03) |
| `shanraisshan/claude-code-best-practice` | guia de referência, não instalável; o que serve já está aplicado (CLAUDE.md curto, settings para o que é determinístico, subagent para isolar contexto) (2026-10-03) |
| `nimrodfisher/data-analytics-skills` (MIT, 31 skills) | sobrepõe a skill `analise-dados` e cobraria 31 descrições de contexto em todo turno; a ideia útil (processar por script, trazer só o resultado) entrou na `analise-dados` (2026-10-03) |
| `danielrosehill/Claude-Data-Analyst-plugin` | 12 estrelas; exige DuckDB, csvkit, Miller e `uv` no PATH (2026-10-03) |
| `vercel-labs/agent-skills` (react-best-practices) | stack é HTML/CSS/JS puro; o `web-design-guidelines` da mesma coleção já está ativo na conta (2026-10-03) |
| `affaan-m/everything-claude-code` | "sistema operacional" de agents com mais de 4 mil arquivos, hooks em Node em todo evento e injeção de contexto no início da sessão; seria substituição, não complemento (2026-10-03) |
| `rohitg00/awesome-claude-code-toolkit` | 135 agents e 20 hooks em Node que repetem os agents e o `guard.sh`; os padrões de segredo genéricos (URL de banco, JWT) dariam falso positivo em exemplo e teste (2026-10-03) |
| `yamadashy/repomix` | empacota o repositório inteiro num arquivo para colar no modelo, o oposto de ler só o trecho certo; o `scout` cobre a localização. Útil só para mandar código a um modelo fora do Claude Code (2026-10-03) |
| `ComposioHQ/awesome-claude-skills` | as skills de documento e design são cópias das da `anthropics/skills`; as `composio-skills` dependem de conta e chave no serviço Composio (2026-10-03) |
| `hesreallyhim/awesome-claude-code`, `karanb192/awesome-claude-code-mods` | catálogos, não instaláveis; fonte de consulta. O dos mods mostra o que cada mod acessa, útil para a auditoria (2026-10-03) |
| `JuliusBrussee/caveman` | resposta telegráfica para cortar tokens; prejudica a clareza em português e o `CLAUDE.md` já pede resposta curta. 28 skills, proxy e MCP próprios (2026-10-03) |
| `nextlevelbuilder/ui-ux-pro-max-skill` | 13 skills de design com CLI e base de busca em Python; sobrepõe a `frontend-design` e cobraria 13 descrições por turno (2026-10-03) |
| `anand-kamble/mcp-instagram` | entra com usuário e senha do Instagram pela API privada (`instagram-private-api`): viola os termos do Instagram, arrisca bloqueio da conta e deixa a senha no arquivo de configuração do cliente (2026-10-03) |
| `mcpware/instagram-mcp` | API oficial (Graph API), mas com escrita sem confirmação (enviar DM, publicar, apagar e responder comentário) sob o mesmo token; o `business_discovery`, única ferramenta para ler outro perfil, ignora o usuário pedido e não traz posts; dependências pesadas (redis, sqlalchemy). Reavaliar se corrigirem (2026-10-03) |
| `BilalTariq01/instagram-analytics-mcp` | candidato se for preciso analisar a **própria** conta: API oficial, só leitura, 3 dependências, MIT. Exige conta profissional ligada a página do Facebook, app na Meta e token que expira. Não lê perfis de terceiros. Não instalado: nenhuma tarefa pediu (2026-10-03) |
| Ferramentas ofensivas do carrossel de segurança: `mimikatz`, `nishang`, `TheFatRat`, `wifiphisher`, `esp8266_deauther`, `routersploit`, `gophish`, `metasploit-framework`, `sqlmap`, `thc-hydra`, `bettercap` e afins | ataque e extração de credencial; fora do escopo de desenvolvimento e risco de uso sem autorização. Teste de invasão é trabalho à parte, com escopo e autorização por escrito (2026-10-04) |
| Instaladores em massa: `Z4nzu/hackingtool`, `Manisso/fsociety`, `infosecn1nja/Red-Teaming-Toolkit` | baixam e rodam dezenas de scripts de terceiros sem auditoria: risco de cadeia de suprimentos, contra a regra do `guard.sh` e da `auditoria.md` (2026-10-04) |
| OSINT sobre pessoas: `sherlock`, `maigret`, `holehe`, `GHunt`, `phoneinfoga`, `Osintgram`, `social-analyzer`, `spiderfoot`, `theHarvester` | coleta dado pessoal de terceiros; conflita com a LGPD e com a regra de não expor dado pessoal (2026-10-04) |
| Recon e varredura: `subfinder`, `httpx`, `amass`, `nuclei`, `nmap`, `RustScan`, `dirsearch`, `fscan`, `Sn1per`, `bbot`, `OneForAll`, `Photon`, `web-check`, `xray`, `PentestGPT` | varredura de alvos é pentest, não desenvolvimento; só com autorização e fora do Autonomia. Para o próprio site, o agent `security` e o ZAP em teste bastam (2026-10-04) |
| Infra e monitoramento corporativo: `lynis`, `osquery`, `wazuh`, `prowler`, `kubescape`, `oss-fuzz`, `sigma` | servidor Linux, Kubernetes, SIEM e nuvem corporativa; o stack do usuário é site estático, Workers e Firebase no Windows (2026-10-04) |
| Mobile e engenharia reversa: `MobSF`, `mastg`, `radare2`, `cutter`, `x64dbg`, `ImHex`, `Detect-It-Easy`, `mvt`, `Ciphey` | sem app mobile nem binário nos projetos (2026-10-04) |
| Listas de estudo e laboratórios: `hacktricks`, `h4cker`, `awesome-pentest`, `Awesome-Hacking`, `awesome-security`, `awesome-web-security`, `PENTESTING-BIBLE`, `hacker101`, `90DaysOfCyberSecurity`, bug bounty, `PayloadsAllTheThings`, `SecLists`, `juice-shop`, `DVWA`, `GTFOBins`, `awesome-ctf`, `awesome-osint`, `OSINT-Framework`, `awesome-threat-intelligence`, `Reverse-Engineering` | material de estudo, não instalável; bom para aprender segurança, sem ganho dentro do Autonomia (2026-10-04) |
| `msitarzewski/agency-agents` (The Agency, MIT, ~260 agents) | catálogo: cada agent tem 700–2.600 palavras em inglês e nome com espaço (fora do padrão de `name`); os 7 do guia "agentes 2026-09-29" repetem `developer`, `frontend-design`, `qa-web`, `security`, `conteudo`/`trafego-pago` e o `CLAUDE.md`; instalar o catálogo somaria centenas de descrições por turno. Duas ideias aproveitadas (acima) (2026-10-04) |
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
