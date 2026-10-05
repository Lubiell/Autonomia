---
name: regex
description: Monta uma expressão regular e explica cada parte, sem tentativa e erro.
argument-hint: "[o que casar e exemplos]"
disable-model-invocation: true
---

Entrada: $ARGUMENTS. Se vier vazia, use o conteúdo mais recente da conversa; se não houver, peça o texto ou o assunto em uma linha.

Entregue a regex, a explicação parte a parte, 5 exemplos que devem casar e 5 que não devem, e teste de verdade (script rápido) mostrando o resultado. Diga para qual motor é (JavaScript, Python, grep -E) e as diferenças relevantes.

Responda em português do Brasil.
