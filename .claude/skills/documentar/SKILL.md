---
name: documentar
description: Documenta o código direitinho: README, comentários úteis ou guia de uso.
argument-hint: "[arquivo, pasta ou projeto]"
disable-model-invocation: true
---

Entrada: $ARGUMENTS. Se vier vazia, use o conteúdo mais recente da conversa; se não houver, peça o texto ou o assunto em uma linha.

Siga o agent `docs-writer`: leia o código real, rode os comandos que documentar, não invente recurso. Comentário só onde o porquê não é óbvio. Marque [NÃO VERIFICADO] o que não pôde rodar.

Responda em português do Brasil.
