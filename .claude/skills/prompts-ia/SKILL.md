---
name: prompts-ia
description: Use para escrever prompts para outras IAs — gerar imagem (Midjourney, DALL·E/ChatGPT, Gemini, Ideogram, Firefly), vídeo, texto ou assistente/GPT personalizado — e para melhorar um prompt que não está dando o resultado esperado.
---

# Prompts para IAs

## Texto e assistentes
- **Estrutura:** papel/contexto → tarefa → dados de entrada → formato da saída → regras → exemplo.
- Seja específico: público, tom, tamanho, o que evitar. Diga o que fazer, não só o que não fazer.
- Dê 1–3 exemplos do resultado desejado quando o formato importa.
- Separe instrução de dado com marcadores (ex.: `<texto>...</texto>`) para o modelo não confundir.
- Assistente/GPT personalizado: objetivo, a quem atende, o que nunca faz, como responde quando não sabe, formato padrão, base de conhecimento anexada.
- Prompt ruim: mude uma coisa por vez e compare as saídas.

## Imagem
Ordem que funciona na maioria das ferramentas:
1. **Assunto** concreto (quem/o quê, ação, expressão).
2. **Cenário** (lugar, época, clima).
3. **Composição** (enquadramento: close, plano médio, plano aberto; ângulo; regra dos terços).
4. **Luz** (natural suave, golden hour, estúdio com contraluz).
5. **Estilo** (fotografia, ilustração vetorial, aquarela, 3D) e referência técnica (lente 50 mm, profundidade de campo rasa).
6. **Cores** (paleta da marca, tons quentes).
7. **Formato** (proporção 1:1, 4:5, 9:16, 16:9).

- Texto dentro da imagem: escreva entre aspas e curto; confira a grafia, porque muitas ferramentas erram.
- Parâmetros variam por ferramenta (ex.: no Midjourney, `--ar 9:16` define a proporção): confira a documentação da que for usar.
- Gere variações e escolha; refine o prompt pelo que deu errado.

## Vídeo
Descreva como um diretor, não como lista de tags (estrutura dos STYLE.md do lemomo-ai/lemo-opuscar, MIT):
1. **Essência e o que NÃO é:** o estilo em 1–2 frases e os vizinhos a evitar (ex.: "aquarela translúcida; não é tinta a óleo nem vetor com textura").
2. **Assunto e ação** em ordem: o que acontece primeiro, depois, por fim.
3. **Câmera como vocabulário**, um movimento por ideia: dolly lateral = jornada; tilt vertical = escala; push-in = atenção ao detalhe; plano fixo = estudo.
4. **Luz e paleta:** 3–5 cores nomeadas e um acento reservado a um só elemento recorrente.
5. **Movimento:** o que se move e como (suave, sem tremer) e o que fica parado.
6. **Som e legenda**, se a ferramenta aceitar.

## Limites
- Não use nome de artista vivo, marca ou pessoa real para imitar estilo ou rosto; não crie imagem enganosa de pessoa real.
- Imagem de produto em anúncio deve corresponder ao produto real.
- Confira os termos de uso comercial da ferramenta antes de usar em anúncio ou produto à venda.

## Entregar
O prompt pronto para copiar, uma versão curta e uma detalhada, e o que ajustar se o resultado vier errado.
