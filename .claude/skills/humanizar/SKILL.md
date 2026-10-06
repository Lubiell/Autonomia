---
name: humanizar
description: Tira o tom robótico de IA de um texto para soar como uma pessoa real.
argument-hint: "[texto]"
disable-model-invocation: true
---

Entrada: $ARGUMENTS. Se vier vazia, use o conteúdo mais recente da conversa; se não houver, peça o texto ou o assunto em uma linha.

Reescreva mantendo o sentido, os fatos e o tom de quem escreveu. Procure e corrija:
- **Encenação:** "não é X, é Y"; frase de efeito solta no fim do parágrafo; rodeio antes de chegar ao ponto ("a verdade é que…", "e aqui vem o detalhe"); rebater objeção que ninguém fez.
- **Ritmo de fórmula:** tudo em trios; frases começando igual; travessão como conectivo para tudo; empilhar ressalvas ("talvez", "de certa forma", "em alguns casos").
- **Inflação:** clichês ("no mundo atual", "é importante ressaltar", "em suma", "mergulhar", "jornada", "potencializar", "robusto"); importância exagerada ("revolucionário", "divisor de águas"); linguagem de venda num texto que não é anúncio; "especialistas dizem" sem fonte; "atua como", "configura-se como" no lugar de "é".
- **Formato por hábito:** negrito decorativo, título para três linhas de texto, lista onde cabia uma frase.
- **Resto de chat:** "Claro! Aqui está…", "Espero ter ajudado", aviso sobre limite de conhecimento, falar do próprio texto ("neste artigo veremos") em vez do assunto, explicar o que o leitor já sabe.

Escreva com frases de tamanhos variados, palavras do dia a dia, voz ativa e exemplo concreto quando houver.

Não mexa em: termo técnico necessário, citação, texto jurídico ou formal que precisa do registro formal, e trecho que já soa humano. Corrija só o padrão que aparece; não reescreva tudo por reescrever.

Entregue só o texto final. Se precisou mudar um fato por falta de clareza, avise em uma linha.

Responda em português do Brasil.
