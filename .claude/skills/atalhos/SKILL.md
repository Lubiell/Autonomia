---
name: atalhos
description: Use em tarefas rápidas de texto, decisão e trabalho do dia a dia — resumir, revisar, humanizar, mudar o tom, enxugar, e-mail, resposta, pauta, tarefas de reunião, ideias, prós e contras, decidir, plano, checklist, modelo, gancho, títulos, regex, mensagem de commit, quiz, comparar opções. Escolhe o atalho certo e segue as instruções dele.
---

# Roteador de atalhos

Escolha na tabela o atalho que corresponde ao pedido e siga as instruções completas dele em `${CLAUDE_SKILL_DIR}/../<atalho>/SKILL.md`, usando como entrada o texto ou o assunto do pedido. Se o arquivo não existir (ex.: no claude.ai), siga a descrição da tabela.

- Pedido que combina dois atalhos (ex.: resumir e tirar tarefas): aplique os dois, na ordem natural.
- Se uma skill mais específica cobre o pedido (`conteudo`, `projetos`, `atendimento-vendas`, `contratos`…) ou um agent (`debugger`, `tester`, `docs-writer`), ela vem primeiro; o atalho complementa.
- `grill-me`: use quando o pedido for grande e vago, antes de começar. `handoff`: use quando o usuário disser que vai continuar em outra sessão.
- Não anuncie o atalho escolhido; entregue o resultado.

## Analisar e decidir
| Pedido | Atalho |
|---|---|
| Defende o lado oposto da sua ideia ou decisão para testá-la sob pressão. | `advogado-do-diabo` |
| Conselho franco sobre a própria situação: desculpas, riscos subestimados, custo de oportunidade e plano. | `conselheiro` |
| Ataca um plano em busca de falhas e riscos antes que eles aconteçam (pre-mortem). | `critica-plano` |
| Lista prós e contras equilibrados de uma opção e recomenda. | `pros-contras` |
| Pesa as opções e escolhe uma, acabando com a paralisia de análise. | `decidir` |
| Compara opções lado a lado (ferramentas, planos, fornecedores, abordagens) e mostra a diferença de verdade. | `comparar` |
| Resume qualquer coisa em um parágrafo. | `tldr` |
| Tira só os tópicos essenciais de um texto, reunião ou documento. | `pontos-chave` |

## Escrever melhor
| Pedido | Atalho |
|---|---|
| Tira o tom robótico de IA de um texto para soar como uma pessoa real. | `humanizar` |
| Corta a enrolação: o mesmo ponto em menos palavras. | `enxugar` |
| Reescreve com palavras novas mantendo o sentido, para vencer o bloqueio. | `reescrever` |
| Reescreve um texto no tom que você escolher: formal, casual, ousado ou acolhedor. | `tom` |
| Corrige gramática, ortografia e clareza antes de enviar. | `revisar-texto` |

## Criar conteúdo
| Pedido | Atalho |
|---|---|
| Dá profundidade a um rascunho raso: transforma anotação em parágrafo. | `expandir` |
| Escreve aberturas que param a rolagem e prendem a atenção em uma linha. | `gancho` |
| Gera opções de título forte para post, vídeo, e-mail, página ou artigo. | `titulos` |
| Monta a estrutura (esqueleto) antes de escrever, para nunca encarar a página em branco. | `estrutura` |
| Transforma fatos secos numa história que prende e faz a ideia grudar. | `historia` |

## Resolver o trabalho
| Pedido | Atalho |
|---|---|
| Escreve um e-mail claro e profissional a partir de poucas informações. | `email` |
| Escreve a resposta certa para uma mensagem, acompanhando o tom da conversa. | `responder` |
| Resume documento longo, reunião ou conversa e pega a essência rápido. | `resumir` |
| Tira tarefas, responsáveis e prazos de anotações ou da ata de uma reunião. | `tarefas` |
| Monta uma pauta de reunião enxuta que mantém todos no rumo. | `pauta` |

## Planejar e organizar
| Pedido | Atalho |
|---|---|
| Brainstorm: gera muitas ideias novas sobre um tema (quantidade vence a página em branco). | `ideias` |
| Transforma uma meta num plano com próximos passos claros, em ordem. | `plano` |
| Transforma um processo num checklist para repetir sem errar. | `checklist` |
| Monta um modelo (template) reutilizável: faça uma vez, reuse para sempre. | `modelo` |

## Programar
| Pedido | Atalho |
|---|---|
| Acha e explica o bug, com causa raiz, em vez de chutar a correção. | `depurar` |
| Explica o que um código faz, passo a passo, para aprender enquanto lê. | `explicar-codigo` |
| Limpa o código sem mudar o comportamento, deixando legível e organizado. | `refatorar` |
| Deixa o código mais rápido ou mais enxuto, cortando o desperdício. | `otimizar` |
| Escreve testes automatizados para um código, para publicar com confiança. | `testes` |
| Monta uma expressão regular e explica cada parte, sem tentativa e erro. | `regex` |
| Escreve uma mensagem de commit clara a partir das mudanças, para o histórico ficar legível. | `mensagem-commit` |
| Documenta o código direitinho: README, comentários úteis ou guia de uso. | `documentar` |

## Aprender
| Pedido | Atalho |
|---|---|
| Testa o que você entendeu de um assunto e acha as lacunas rápido. | `quiz` |

## Processo
| Pedido | Atalho |
|---|---|
| Entrevista o usuário, uma pergunta por vez, até o plano ou a ideia ficar sem pontas soltas, antes de implementar. Use com /grill-me, opcionalmente seguido do assunto. | `grill-me` |
| Gera um documento de passagem para outra sessão ou agent continuar o trabalho desta conversa. Use com /handoff, opcionalmente dizendo para que será a próxima sessão. | `handoff` |
