---
name: depurar
description: Acha e explica o bug, com causa raiz, em vez de chutar a correção.
argument-hint: "[erro, sintoma ou arquivo]"
disable-model-invocation: true
---

Entrada: $ARGUMENTS. Se vier vazia, use o conteúdo mais recente da conversa; se não houver, peça o texto ou o assunto em uma linha.

Siga o método do agent `debugger`: reproduza, localize, separe sintoma de causa, teste uma hipótese por vez com evidência. Explique a causa em linguagem simples e aplique a menor correção, com teste que falhava antes e passa depois.

Responda em português do Brasil.
