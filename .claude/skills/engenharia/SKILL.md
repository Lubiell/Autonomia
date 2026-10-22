---
name: engenharia
description: Use em programação quando o trabalho tiver uma etapa definida — especificar, quebrar em tarefas, implementar em fatias, TDD, revisar, simplificar, depurar, endurecer segurança, desempenho, desenho de API, CI/CD, migração ou descontinuação, ADR, logs e métricas, lançamento, fluxo de Git, interface — ou quando pedirem a solução mais simples ou o código estiver inchado. Escolhe o método certo e segue as instruções dele.
---

# Roteador de métodos de engenharia

Pacotes `addyosmani/agent-skills` e `DietrichGebert/ponytail` (MIT) e plugins oficiais `claude-md-management` e `receipts` (Apache-2.0), instalados só por comando para não disputar pedido. Esta skill os aciona quando a etapa pede.

Escolha na tabela o método da etapa atual e siga as instruções completas em `${CLAUDE_SKILL_DIR}/../<método>/SKILL.md` (com as referências da pasta dele).

- **O Autonomia vem primeiro.** Se a coluna "Antes" indica uma skill ou agent daqui, use-a; o método só complementa com o que ela não cobre. Em conflito, valem o `CLAUDE.md` e a skill daqui.
- Um método por etapa. Não carregue vários "por garantia": cada um custa contexto.
- Tarefa trivial (uma linha, renomear, texto) não pede método.
- Método em inglês: responda em português.
- Não anuncie o método escolhido; entregue o resultado. Se o usuário chamar um pelo comando (`/nome`), use esse.

## Planejar
| Etapa | Método | Antes |
|---|---|---|
| Ideia ainda vaga, testar premissas antes de decidir o que fazer. | `idea-refine` | `grill-me` |
| Descobrir o que o usuário quer de fato, uma pergunta por vez. | `interview-me` | `grill-me` |
| Especificação ou requisitos de recurso novo sem spec. | `spec-driven-development` | `spec` (tarefa de risco) |
| Quebrar spec ou pedido grande em tarefas ordenadas. | `planning-and-task-breakdown` | `architect` |
| Definir a régua de qualidade do projeto por escrito. | `constraint-driven-development` | — |
| Decisão importante que merece revisão adversarial antes de seguir. | `doubt-driven-development` | `critica-plano` |

## Construir
| Etapa | Método | Antes |
|---|---|---|
| Implementar mudança em vários arquivos em fatias verificáveis. | `incremental-implementation` | `developer` |
| Lógica nova ou bug: teste vermelho primeiro, depois o código. | `test-driven-development` | `tester` |
| Conferir a abordagem na documentação oficial antes de implementar. | `source-driven-development` | — |
| Desenhar API, endpoint, contrato ou fronteira de módulo. | `api-and-interface-design` | `api-backend` |
| Interface, componente ou layout de produção. | `frontend-ui-engineering` | `frontend-design`, `accessibility` |
| Branch, commits, conflito, separar trabalho bagunçado. | `git-workflow-and-versioning` | `devops` |
| Pedido de solução mais simples, menos código, código inchado. | `ponytail` | regra "menor alteração adequada" |

## Verificar
| Etapa | Método | Antes |
|---|---|---|
| Revisão de qualidade antes do merge. | `code-review-and-quality` | `reviewer` |
| Revisão curta de um diff: lógica, segurança, carga, código sobrando. | `ponytail-review` | `reviewer` |
| Auditoria do repositório inteiro, priorizada. | `ponytail-audit` | `melhorar-projeto` |
| Simplificar código que funciona mas é difícil de ler. | `code-simplification` | `refatorar` |
| Teste, build ou comportamento quebrado. | `debugging-and-error-recovery` | `debugger` |
| Endurecer entrada, autenticação, dados ou integração. | `security-and-hardening` | `security` |
| Lentidão ou requisito de desempenho. | `performance-optimization` | `performance`, `otimizar` |
| Testar no navegador pelo DevTools (exige o MCP do Chrome DevTools). | `browser-testing-with-devtools` | `webapp-testing`, `qa-web` |

## Entregar e manter
| Etapa | Método | Antes |
|---|---|---|
| Montar ou mudar pipeline de CI/CD. | `ci-cd-and-automation` | `devops`, `automacao` |
| Checklist antes de publicar em produção. | `shipping-and-launch` | `deploy-web` |
| Logs, métricas, tracing ou alerta. | `observability-and-instrumentation` | — |
| Remover sistema antigo ou migrar usuários ou dados. | `deprecation-and-migration` | `spec`, `banco-dados` |
| Registrar decisão de arquitetura (ADR) ou documentar API. | `documentation-and-adrs` | `docs-writer` |
| Contexto ruim: sessão nova, respostas piorando, regras do projeto. | `context-engineering` | `handoff` |
| Atalhos marcados `shortcut:` deixados para depois. | `ponytail-debt` | — |
| Fim de sessão longa: propor ao `CLAUDE.md` do projeto o que se aprendeu (pede ok antes de editar). | `revise-claude-md` | `claude-md-improver` |
| Relatório do uso do Claude Code e do que foi entregue. | `receipts` | — |
| Qual método serve, quando nenhum acima encaixa. | `using-agent-skills` | — |
| Só se o usuário perguntar como usar o Ponytail. | `ponytail-help` | — |
| Só se o usuário perguntar quanto o Ponytail economiza. | `ponytail-gain` | — |
