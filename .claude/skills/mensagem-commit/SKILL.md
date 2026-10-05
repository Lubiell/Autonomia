---
name: mensagem-commit
description: Escreve uma mensagem de commit clara a partir das mudanças, para o histórico ficar legível.
argument-hint: "[contexto opcional]"
disable-model-invocation: true
---

Entrada: $ARGUMENTS. Se vier vazia, use o conteúdo mais recente da conversa; se não houver, peça o texto ou o assunto em uma linha.

Leia `git diff --staged` (ou `git diff` se nada estiver preparado). Título até ~72 caracteres no imperativo dizendo o que muda; corpo com o porquê e o que não é óbvio. Siga o padrão de mensagens que o repositório já usa (`git log --oneline -10`). Não faça o commit sem pedido.

Responda em português do Brasil.
