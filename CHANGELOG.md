# Changelog

O que mudou no Autonomia, por data. Para atualizar uma instalação, rode o instalador de novo (`install.sh` ou `install.ps1`). O motivo de cada adoção ou recusa está em `.claude/skills/discover-resources/decisoes.md`.

## 2026-10-21
- `skills.test.sh` reprova skills ou agents com descrições parecidas demais, que disputam o mesmo gatilho, e skill com corpo vazio. Também confere que todo hook do `settings.json` existe e usa evento válido.
- `guard.sh` bloqueia também `git stash clear`, `git branch -D` e `git checkout .`/`git restore .` (sem `--staged`), que descartam trabalho sem volta.
- Hook Stop `verify-stop.sh`: antes de encerrar, o Claude roda os testes do projeto (`.claude/verify-cmd`, `npm test` ou `pytest`) se o código mudou desde a última verificação que passou. Falhou, ele continua para corrigir. Nunca bloqueia duas vezes seguidas, e `off` em `.claude/verify-cmd` desliga. Ideia do prove_it.
- Ideias do `ayghri/i-have-adhd` sem instalar: no `CLAUDE.md`, dizer em que passo a tarefa está e o próximo a cada resposta, e estimar tempo em unidade concreta; no `debugger`, três tentativas sem sucesso param a edição e apontam a suposição que pode estar errada.
- Agent `tester`: desconfiar de teste que passa sem provar nada, e quebrar a regra de propósito para ver o teste falhar.
- Ideias do Ponytail 5 enxertadas sem instalar: `reviewer` só aponta achado com caso concreto, procura todos os chamadores e julga escala pela carga esperada; `developer` lista tudo que a mudança alcança antes de editar e marca atalho com `atalho: <limite>, <quando trocar>`.
- `devops`: configurado, alcançável, funcionando e autorizado conferidos como fatos separados (ideia do Ruflo). O Ruflo em si foi recusado: framework de swarm que substituiria os agents.

## 2026-10-20
- Rotina semanal: quando o `CLAUDE.md` do próprio repositório define a política de merge, vale a dele no lugar da regra geral de tarefa de risco. Regra de projeto fica no projeto, não no Autonomia.

## 2026-10-23
- `instalar-autonomia.bat`: instala ou atualiza no Windows com dois cliques (baixa o main do GitHub e roda o `install.ps1`). Novo job do CI roda o `.bat` num Windows e confere a instalação.
- Carrosséis de plugins (@clubedasskills e outro): Playwright, Agent Skills, Graphify, Ponytail, Context7 e Strix já tinham decisão; `21st.dev MCP` registrado como opcional (exige chave; componentes React).

## 2026-10-22
- Autonomia como cérebro geral, para todas as áreas: agents `marketer`, `business-advisor` e `writer`, para o orquestrador delegar trabalho grande fora da programação; skills `financas-pessoais`, `estudo`, `escrita` e `saude-rotina`.
- Instalados, a pedido, os pacotes Ponytail (6 skills) e `addyosmani/agent-skills` (25 skills), todos só por comando, para não disputar pedido com as skills existentes nem gastar contexto (lista no README, seção Atalhos). Ponytail sem os hooks.
- Plugins oficiais `claude-md-management` (`/claude-md-improver`, `/revise-claude-md`) e `receipts` (`/receipts`), acionados pelo roteador `engenharia` ou sozinhos. Varredura de skills e plugins novos registrada em `decisoes.md`.
- Graphify (global, com hooks) e OmniRoute (só por terminal) liberados a pedido do usuário, como passo manual no PC; não entram no instalador.
- Skill roteadora `engenharia`: aciona sozinha os 31 métodos quando a etapa de programação pede, depois das skills e agents do Autonomia (uma só descrição no contexto). `skills.test.sh` confere que cada método está na tabela dela.

## 2026-10-19
- Skills `wrangler` e `workers-best-practices` atualizadas para o commit oficial `86505e4` da Cloudflare: Wrangler só em projeto que já tem `wrangler.jsonc/json/toml`; projeto novo segue o CLI `cf`. Skills do Firebase e do web-quality sem mudança relevante.

## 2026-10-18
- Regras de livros clássicos de programação nos agents: `debugger` (*Debugging*, de Agans, e *The Pragmatic Programmer*), `reviewer` e `/refatorar` (maus cheiros de *Refactoring*, de Fowler), `architect` (*A Philosophy of Software Design*, de Ousterhout, *Pragmatic Programmer* e *Working Effectively with Legacy Code*, de Feathers). Só checklists curtos; o corpo do agent carrega apenas quando ele roda, então o custo por turno não muda.
- Regras dos livros também no `developer` (ao escrever código) e no `tester` (teste de caracterização antes de mexer em código sem teste; um comportamento por teste). `skills.test.sh` limita cada agent a 600 palavras, para a rotina semanal trocar regra fraca em vez de inchar.
- Rotina semanal "Sabedoria e melhoria de programas" (quintas): pesquisa sabedoria de programação e atualiza os agents por PR com merge automático no CI verde; depois melhora um dos seus repositórios por PR pequeno com teste. Em dado de saúde, schema ou envio a órgão público, só PR em rascunho, sem merge.
- Atalho `/livros` criado e removido no mesmo dia: o usuário não vai ler os livros, e as regras deles já estão nos agents.

## 2026-10-16
- Skill de conta `protocolo-dev` incorporada ao Autonomia, para ter uma fonte só de regras: skills novas `spec` (tarefa de risco: caminhos com custo, spec curta e ok antes de codar) e `pecas-graficas` (Canva e checklist de design); `discover-resources/ferramentas-externas.md`; regras de GitHub Actions com agente na `automacao`; no `CLAUDE.md`, buscar pelos conectores antes de perguntar, gate da `spec` e confirmação para gasto de dinheiro. Depois de instalar, a `protocolo-dev` pode ser apagada da conta.
- README: a sessão na nuvem reaproveita a instalação antiga (vista em 16/10 com a de 09/10); como forçar a reinstalação.
- `CLAUDE.md`: com os testes locais e o CI do PR verdes, o Claude faz o merge sozinho e confere que chegou ao main (antes, só com pedido do usuário). CI vermelho ou ausente continua sem merge.

## 2026-10-12
- Agent `security`: investiga a origem da entrada e a proteção do framework antes de relatar, e separa falha confirmada de "precisa verificar" (método de `getsentry/skills`).
- Skills do Firebase atualizadas para o commit oficial `b5735e5` (metadado de autor e texto reformatado; auditoria sem achado novo).
- `conteudo`: mesma ideia reescrita para cada plataforma e plano de publicação (calendário) na frequência que a pessoa consegue manter.

## 2026-10-11
- `CLAUDE.md`: discordar com motivo, alternativa e risco; não ceder a insistência sem fato novo; resposta começa pelo mais útil, sem bajulação; afirmação sem prova marcada como [Provável] ou [Chute].
- `/conselheiro`: primeira frase sempre desafia a premissa e cada afirmação leva [Certeza], [Provável] ou [Chute] (prompt de @matheustilli).
- Atalho `/cliente-dificil`: o Claude faz o papel de um cliente difícil para treinar venda e atendimento, e avalia no fim (do mapa de @poderartificial).

## 2026-10-09
- `CLAUDE.md`: script Python é testado antes de entregar ou commitar, e envio a repositório só com teste passando, por branch e pull request (mesma regra do celular, agora também no PC).

## 2026-10-08
- `CLAUDE.md`: passos que rodam na máquina do usuário vêm primeiro em comandos para o Termux (celular), PC só se não houver como.
- Backup automático no Google Drive (`.github/workflows/backup-drive.yml`): de hora em hora envia todos os repositórios, cada um na sua pasta, só os que mudaram; repositório novo entra sozinho. Precisa do segredo `GDRIVE_TOKEN` (passo a passo pelo Termux no README).
- `CLAUDE.md`: não pedir licença para passo que já faz parte do pedido, dúvida pequena vira suposição declarada, mudar de abordagem após duas falhas iguais e parar ao concluir (do protocolo de autonomia enviado pelo usuário).
- Atalho `/conselheiro`: conselho franco sobre a própria situação (desculpas, risco subestimado, custo de oportunidade e plano), ideia do carrossel de @matheustilli.

## 2026-10-07
- `/skill-doctor` (nativo) no README para medir custo e uso de cada skill; substitui o plugin `session-report` da fila.
- Varredura com `NVIDIA/SkillSpector` na `auditoria.md`, como primeira triagem antes de instalar skill (com o aviso de falso positivo).
- Registro de decisões: listas de repositórios populares, carrosséis de ferramentas e skills, Clean APIs (recusado: revenda de acesso ao Claude) e `skill-eval-action` (recusado).

## 2026-10-06
- `/humanizar` ampliado com os padrões de texto de IA (ideia de `blader/humanizer`).
- Recusados: Find Skills, Deploy to Vercel e Excalidraw.

## 2026-10-05
- 35 atalhos de comando (`/resumir`, `/plano`, `/depurar`…) e a skill roteadora `atalhos`.
- Skills `produto`, `prompts-ia`, `cursos`, `mei-impostos`, `contratos`, `marca`, `rh` e `melhorar-projeto`.
- Skills oficiais: `wrangler` e `workers-best-practices` (Cloudflare), `firebase-hosting-basics`, `firebase-auth-basics` e `firebase-security-rules-auditor` (Firebase), `accessibility` e `performance` (web-quality).
- Guia de uso no PC e no celular; conectores MCP recomendados.

## 2026-10-04
- Agents `data-analyst`, `qa-web`, `docs-writer` e `researcher`.
- Skills `deploy-web`, `handoff`, `conteudo`, `seo`, `grill-me`, `banco-dados`, `api-backend`, `automacao`, `trafego-pago`, `negocios`, `projetos`, `atendimento-vendas`, `seguranca-digital`, `midia` e `lgpd`.
- `guard.sh` bloqueia `DROP`/`TRUNCATE`, exclusão irreversível na nuvem e commit de `.dev.vars`.
- `security`: checklist de falhas típicas de código gerado por IA; `qa-web`: sem evidência, o veredito é "não pronto".

## 2026-10-03
- Skills `analise-dados`, `frontend-design` e `webapp-testing`.
- `package.sh`/`package.ps1`: empacotam as skills em zip para o claude.ai.
- CI com `shellcheck`, teste do cabeçalho de skills e agents, `actions/checkout` fixado por hash e Dependabot.
- `guard.sh`: agents somente leitura não escrevem pelo shell; bloqueia pular os hooks do Git (`--no-verify`); chave Stripe no commit.
- Leitura de `~/.ssh`, `~/.aws/credentials` e `~/.gnupg` negada; pergunta antes de `pip3`, `python -m pip` e `npm publish`.
- `CLAUDE.md`: responder em português do Brasil, discordar com argumento, apresentar as duas leituras de um pedido ambíguo.

## 2026-10-02
- Hook `guard.sh` (comando destrutivo, segredo em commit, SQL sem `WHERE`, escrita na configuração) e sandbox nativo.
- `.env` bloqueado em qualquer subpasta; regras de bloqueio repetidas para o PowerShell.
- `scout` sem carregar o `CLAUDE.md` (`omitClaudeMd`) e com regras de precisão.
- Verificação semanal automática de novidades.

## 2026-10-01
- Primeira versão: `CLAUDE.md`, agents `architect`, `developer`, `debugger`, `tester`, `reviewer`, `security`, `devops` e `scout`, skill `discover-resources`, permissões e instaladores.
