---
name: modelo
description: Monta um modelo (template) reutilizável: faça uma vez, reuse para sempre.
argument-hint: "[o que o modelo vai produzir]"
disable-model-invocation: true
---

Entrada: $ARGUMENTS. Se vier vazia, use o conteúdo mais recente da conversa; se não houver, peça o texto ou o assunto em uma linha.

Modelo com campos variáveis em {{chaves}}, instruções curtas de preenchimento e um exemplo preenchido. Formato pronto para copiar (texto, Markdown ou planilha via skill `xlsx`).

Responda em português do Brasil.
