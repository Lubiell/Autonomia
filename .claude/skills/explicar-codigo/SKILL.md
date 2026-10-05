---
name: explicar-codigo
description: Explica o que um código faz, passo a passo, para aprender enquanto lê.
argument-hint: "[arquivo, função ou trecho]"
disable-model-invocation: true
---

Entrada: $ARGUMENTS. Se vier vazia, use o conteúdo mais recente da conversa; se não houver, peça o texto ou o assunto em uma linha.

Explique em camadas: o que faz (1 frase), como faz (passo a passo numerado), entradas e saídas, efeitos colaterais, pontos frágeis. Use os nomes do próprio código. Não altere arquivos.

Responda em português do Brasil.
