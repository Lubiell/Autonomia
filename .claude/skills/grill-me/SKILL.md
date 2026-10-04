---
name: grill-me
description: Entrevista o usuário, uma pergunta por vez, até o plano ou a ideia ficar sem pontas soltas, antes de implementar. Use com /grill-me, opcionalmente seguido do assunto.
disable-model-invocation: true
---

# Sabatina antes de implementar

Objetivo: chegar a um entendimento comum, sem lacunas, do que vai ser feito, antes de escrever código ou conteúdo.

## Como conduzir
- **Uma pergunta por vez.** Espere a resposta antes da próxima.
- **Recomende em cada pergunta:** dê sua resposta sugerida e por quê. O usuário só confirma ou corrige.
- **O que o código ou o projeto responde, não pergunte:** investigue (Grep, leitura, `git log`) e diga o que achou.
- **Percorra a árvore de decisões:** comece pelo objetivo e desça; quando uma resposta abrir outro ramo, resolva as dependências antes de seguir.
- **Desafie:** contradição com resposta anterior, requisito vago ("rápido", "bonito", "simples"), caso de borda ignorado, custo escondido. Peça número ou exemplo concreto.

## Cubra
1. Objetivo e critério de pronto (como saber que deu certo).
2. Quem usa e em que situação.
3. Escopo: o que entra e o que fica de fora agora.
4. Restrições: prazo, stack, orçamento, o que não pode mudar.
5. Dados e integrações: de onde vem, para onde vai, o que é sensível.
6. Casos de erro e de borda.
7. Como vai ser testado e publicado.

## Fim
Pare quando não restar decisão em aberto, ou quando o usuário pedir. Entregue um resumo de até 15 linhas: decisões tomadas, o que fica de fora, riscos aceitos e o primeiro passo. Não implemente nada sem o usuário pedir.
