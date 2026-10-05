---
name: produto
description: Use para decidir o que construir e por quê — entrevista com cliente, síntese de feedback e avaliações, especificação de recurso (PRD), histórias de usuário, priorização (RICE), métricas de sucesso, MVP e plano de lançamento.
---

# Produto

## Descobrir
- **Problema antes da solução:** quem sofre, com que frequência, quanto custa hoje, como resolve sem você.
- **Entrevista:** pergunte sobre o que a pessoa já fez, não sobre o que faria ("conte a última vez que..."). Nada de "você usaria?". 5–8 entrevistas já mostram padrões.
- **Feedback e avaliações:** junte de suporte, redes, loja e vendas; agrupe por tema; conte quantas pessoas citam cada um; guarde 1–2 citações literais por tema. Volume e dor pesam mais que o pedido mais barulhento.

## Especificar (PRD de uma página)
1. Problema e evidência (números, citações).
2. Objetivo e métrica de sucesso, com valor atual e meta.
3. Fora de escopo, por escrito.
4. Quem usa e histórias: "Como [pessoa], quero [ação] para [resultado]", cada uma com critério de aceite verificável.
5. Solução proposta e alternativas descartadas (com motivo).
6. Riscos e perguntas em aberto.
7. Lançamento: para quem primeiro, como medir, como voltar atrás.

## Priorizar
- **RICE** = alcance × impacto × confiança ÷ esforço. Use as mesmas escalas para todos os itens e mostre a conta.
- Corte para o **MVP**: o menor conjunto que testa a hipótese principal com cliente real.
- O que não entra agora vai para uma lista "depois", com o motivo.

## Medir
- Uma métrica principal por recurso e 1–2 de proteção (o que não pode piorar).
- Antes de lançar, defina o que conta como sucesso e o que faria desistir.
- Funil: quantos veem → experimentam → usam de novo. Use a skill `analise-dados` para os números.

## Entregar
PRD em uma página, tabela de priorização com a conta, e plano de teste com cliente. Para implementar, passe ao agent `architect` (decisão técnica) ou `developer`.
