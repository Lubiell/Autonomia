---
name: checklist
description: Transforma um processo num checklist para repetir sem errar.
argument-hint: "[processo ou tarefa]"
disable-model-invocation: true
---

Entrada: $ARGUMENTS. Se vier vazia, use o conteúdo mais recente da conversa; se não houver, peça o texto ou o assunto em uma linha.

Checklist em ordem, um item verificável por linha (começa com verbo), agrupado em antes / durante / depois. Marque os itens críticos (que causam erro caro se esquecidos). Até 15 itens; o resto vai para anexo.

Responda em português do Brasil.
