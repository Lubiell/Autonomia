---
name: resumir
description: Resume documento longo, reunião ou conversa e pega a essência rápido.
argument-hint: "[texto, arquivo, transcrição ou link]"
disable-model-invocation: true
---

Entrada: $ARGUMENTS. Se vier vazia, use o conteúdo mais recente da conversa; se não houver, peça o texto ou o assunto em uma linha.

Estrutura: contexto em 1 linha; pontos principais (até 7); decisões; pendências com responsável e prazo; dúvidas em aberto. Nada que não esteja na fonte; cite trecho quando o ponto for sensível.

Responda em português do Brasil.
