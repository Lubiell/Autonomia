---
name: refatorar
description: Limpa o código sem mudar o comportamento, deixando legível e organizado.
argument-hint: "[arquivo ou função]"
disable-model-invocation: true
---

Entrada: $ARGUMENTS. Se vier vazia, use o conteúdo mais recente da conversa; se não houver, peça o texto ou o assunto em uma linha.

Antes: rode os testes (ou crie um que fixe o comportamento atual). Mudanças pequenas e separadas: nomes claros, funções menores, duplicação removida, código morto apagado. Rode os testes depois de cada passo. Nada de recurso novo nem dependência nova.

Responda em português do Brasil.
