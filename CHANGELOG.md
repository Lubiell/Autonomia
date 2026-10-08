# Changelog

O que mudou no Autonomia, por data. Para atualizar uma instalação, rode o instalador de novo (`install.sh` ou `install.ps1`). O motivo de cada adoção ou recusa está em `.claude/skills/discover-resources/decisoes.md`.

## 2026-10-08
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
