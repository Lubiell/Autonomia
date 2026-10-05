---
name: responder
description: Escreve a resposta certa para uma mensagem, acompanhando o tom da conversa.
argument-hint: "[mensagem recebida e o que quer responder]"
disable-model-invocation: true
---

Entrada: $ARGUMENTS. Se vier vazia, use o conteúdo mais recente da conversa; se não houver, peça o texto ou o assunto em uma linha.

Responda primeiro ao que foi perguntado, depois o próximo passo. Espelhe o tom e o tamanho da mensagem recebida. Para WhatsApp, frases curtas. Se faltar informação para responder, diga qual e ofereça uma versão com [PREENCHER]. Siga a skill `atendimento-vendas` quando for cliente.

Responda em português do Brasil.
