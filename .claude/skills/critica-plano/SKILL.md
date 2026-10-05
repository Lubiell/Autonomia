---
name: critica-plano
description: Ataca um plano em busca de falhas e riscos antes que eles aconteçam (pre-mortem).
argument-hint: "[plano]"
disable-model-invocation: true
---

Entrada: $ARGUMENTS. Se vier vazia, use o conteúdo mais recente da conversa; se não houver, peça o texto ou o assunto em uma linha.

Imagine que o plano falhou daqui a 6 meses e explique por quê.
- Falhas por categoria: premissa errada, dependência, prazo, custo, pessoas, concorrência, lei.
- Para cada uma: chance (baixa/média/alta), impacto e como prevenir agora.
- Termine com as 3 correções de maior efeito.

Responda em português do Brasil.
