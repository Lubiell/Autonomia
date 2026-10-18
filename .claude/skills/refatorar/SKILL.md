---
name: refatorar
description: Limpa o código sem mudar o comportamento, deixando legível e organizado.
argument-hint: "[arquivo ou função]"
disable-model-invocation: true
---

Entrada: $ARGUMENTS. Se vier vazia, use o conteúdo mais recente da conversa; se não houver, peça o texto ou o assunto em uma linha.

Antes: rode os testes (ou crie um que fixe o comportamento atual, inclusive o estranho). Mudanças pequenas e separadas: nomes claros, funções menores, duplicação removida, código morto apagado. Rode os testes depois de cada passo. Nada de recurso novo nem dependência nova.

Refatorar e mudar comportamento nunca no mesmo passo nem no mesmo commit. Onde mexer primeiro: nome que não diz o que faz, a mesma regra em dois lugares, função longa ou com muitos parâmetros, mudança que obriga a editar muitos arquivos, função que usa mais dados de outro módulo que do próprio, parâmetros que sempre andam juntos. Nada de abstração "para o futuro": generalize só o que já se repete.

Responda em português do Brasil.
